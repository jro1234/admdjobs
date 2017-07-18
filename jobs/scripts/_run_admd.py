#!/usr/bin/env/python

'''
This file contains strategy functions for running adaptivemd simulations
and project initializing function 'init_project'.

'''

from __future__ import print_function
import random
import time


def strategy_pllMD(project, engine, n_run, n_ext, n_steps,
                   fixedlength=True, longest=5000):#, n_model):

    print("Using fixed length? ", fixedlength)

    if fixedlength:
        trajectories = project.new_trajectory(engine['pdb_file'],
                                              n_steps, engine, n_run)
    else:
        variation = 0.2
        rand = [random.random()*variation*2-variation
                for _ in range(n_run)]

        randbreak = [int(n_steps*(1+r)/longest)*longest
                     for r in rand]

        trajectories = list()
        [trajectories.append(project.new_trajectory(
            engine['pdb_file'],rb, engine))
         for rb in randbreak]

    if not isinstance(trajectories, list):
        trajectories = [trajectories]

    tasks = [t.run() for t in trajectories]
    project.queue(tasks)
    print("Number of tasks: ", len(tasks))
    print("Queued First Tasks")
    print("Trajectory lengths were: {0}"
          .format(', '.join([str(t.length) for t in trajectories])))

    yield lambda: any([ta.is_done() for ta in tasks])

    print("Starting Trajectory Extensions")
    c_ext = 0
    while c_ext < n_ext:
        c_ext += 1
        print("Extension #{0}".format(c_ext))
        extended = set()
        tasks = list()

        while len(extended) < n_run:
            for t in project.trajectories:
                if t.basename not in extended:
                    if c_ext == n_ext:
                        # undo misalignment from staggering
                        # mostly for scaling, maybe can leave 
                        # as a separate option for general use
                        n_step = n_steps*(n_ext+1)-t.length
                    else:
                        n_step = n_steps

                    task_ex = t.extend(n_step)
                    extended.add(t.basename)
                    project.queue(task_ex)
                    tasks.append(task_ex)
                    print("Queued Extension Task to {0} frames"
                          .format(t.length+n_step))

            time.sleep(1)

        yield lambda: any([ta.is_done() for ta in tasks])

    # we should not arrive here until the final round
    # of extensions are queued and at least one of them
    # is complete
    print("First Task is done")
    def all_done():
        '''
        This function scavenges project for idle workers.
        They are shut down if idle to flush the output.
        Returns function that returns True when all workers
        have been shut down.
        Many assumptions are made that will break down easily
        catastrophic ones- 
        n workers = n trajectories
        '''

        for ta in project.tasks:
            # if function used before final extensiontasks
            # this condition can be satisfied and result
            # in shutdown...
            if ta.state == 'success':
                if ta.description.find('TrajectoryExtensionTask') >= 0:
                    # offers little additional protection
                    # since there is lag between task
                    # completion and acquisition
                    if ta.worker.n_tasks == 0:
                        if ta.worker.state == 'running':
                             print("Worker shutdown at ", time.time())
                             ta.worker.execute('shutdown')

            elif ta.state == 'fail':
                # what to do?
                pass

        return all([ ta.worker.state == 'down'
                     for ta in tasks
                     if ta.state != 'dummy'])

    print("Waiting for all done")
    yield lambda: all_done()

    # redundant for simple event model here
    yield [ta.is_done for ta in tasks]
    print("Completed Simulation Length of {0} Frames"
          .format(project.trajectories.one.length))

    print("Simulation Event Finished")



def strategy_pllMD_blocks(project, engine, n_run, n_ext, n_steps):#, n_model):

    trajectories = project.new_trajectory(engine['pdb_file'],
                                        n_steps, engine, n_run)

    if not isinstance(trajectories, list):
        trajectories = [trajectories]

    tasks = [t.run() for t in trajectories]
    project.queue(tasks)
    print("Number of tasks: ", len(tasks))
    print("Queued First Tasks")
    yield [ta.is_done for ta in tasks]

    if [t for t in filter(lambda t: not t.exists, project.trajectories)]:
        print("One or More Initial Trajectory Did Not Run")
        raise Exception

    print("Starting Trajectory Extensions")

    c_ext = 0
    while c_ext < n_ext:
        c_ext += 1
        print("Extension #{0}".format(c_ext))
        tasks_ex = [t.extend(n_steps) for t in project.trajectories]
        project.queue(tasks_ex)
        print("Queued Extension Task to {0} frames"
              .format(project.trajectories.one.length+n_steps))

        yield [ta.is_done for ta in tasks_ex]

    print("Completed Simulation Length of {0} Frames"
          .format(project.trajectories.one.length))

    print("Simulation Event Finished")


def init_project(p_name, m_freq, p_freq, platform, dbhost=None, w_threads=None):
#def init_project(p_name, **freq):

    from adaptivemd import Project

    #if p_name in Project.list(): 
    #    print("Deleting existing version of this test project") 
    #    Project.delete(p_name)

    if dbhost is not None:
        Project.set_dbhost(dbhost)

    project = Project(p_name)

    if project.name in Project.list():
        print("Project {0} exists, reading it from database"
              .format(project.name))

    else:

        from adaptivemd import File, LocalResource, OpenMMEngine

        resource = LocalResource('/lustre/atlas/scratch/jrossyra/bip149/admd/')
        project.initialize(resource)

        # only works if filestructure is preserved as described in 'jro_ntl9.ipynb'
        # and something akin to job script in 'admd_workers.pbs' is used
        ntl9_base = 'file:///lustre/atlas/proj-shared/bip149/jrossyra/adaptivemd/examples/files/ntl9/'

        f_structure = File(ntl9_base + 'ntl9.pdb').load()
        f_system = File(ntl9_base + 'system.xml').load()
        f_integrator = File(ntl9_base + 'integrator.xml').load()

        sim_args = '-r -p {0}'.format(platform)

        if platform == 'CPU':
            print("Using CPU simulation platform with {0} threads per worker"
                  .format(w_threads))

            sim_args += ' --cpu-cpu-threads {0}'.format(w_threads)

        engine = OpenMMEngine(f_system, f_integrator,
                              f_structure, sim_args).named('openmm-2')

        engine.add_output_type('master', 'allatoms.dcd', stride=m_freq)
        engine.add_output_type('protein', 'protein.dcd', stride=p_freq,
                               selection='protein')

        project.generators.add(engine)
        print(project.generators.one)

    return project

