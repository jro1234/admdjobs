#!/usr/bin/env python

'''
This file contains strategy functions for running adaptivemd simulations
and project initializing function 'init_project'.

'''

from __future__ import print_function


def strategy_pllMD(project, engine, n_run, n_ext, n_steps):#, n_model):

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

