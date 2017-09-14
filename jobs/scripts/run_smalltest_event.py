#!/usr/bin/env/python

'''
    Usage:
           $ python run_smalltest.py [name]

'''

from __future__ import print_function

# Import custom adaptivemd init & strategy functions
from _argparser import argparser
from __run_admd import init_project, strategy_pllMD
from sys import exit
import time



if __name__ == '__main__':

    parser = argparser()
    args = parser.parse_args()

    print("Initializing Project named: ", args.project_name)
    # send selections and frequencies as kwargs
    #fix1#project = init_project(p_name, del_existing, **freq)
    print("Worker threads: {0}".format(args.w_threads))
    print(args)
    project = init_project(args.project_name,
                           args.system_name,
                           args.all,
                           args.prot,
                           args.platform,
                           args.dbhost,
                           args.w_threads)

    if args.init_only:
        print("Leaving project initialized without tasks")
        exit(0)

    else:
        print("Adding event to project from function:")
        print(strategy_pllMD)

        if  args.longts:
            ext = '-5'
        else:
            ext = '-2'

        nm_engine = 'openmm' + ext
        nm_modeller_1 = 'pyemma-ca' + ext
        nm_modeller_2 = 'pyemma-ionic' + ext

        engine = project.generators[nm_engine]

        if args.model:
            modellers = list()
            modellers.append(project.generators[nm_modeller_1])
            modellers.append(project.generators[nm_modeller_2])
        else:
            modellers = None

        start_time = time.time()
        print("TIMER Project add event {0:.5f}", time.time())
        project.add_event(strategy_pllMD(project, engine, args.n_traj,
                                         args.n_ext, args.length, modellers,
                                         args.fixedlength, args.all))

        #tasks#trajectories = project.new_trajectory(engine['pdb_file'],
        #tasks#                                      n_steps, engine, n_runs)
        #tasks#
        #tasks#
        #tasks#  Expand to include multiple task-generating options
        #tasks#
        #tasks#

        print("Triggering project")
        project.wait_until(project.events_done)
        print("Shutting Down Workers")
        # NOTE that all_done function in _run_admd.py should
        #      have these guys already shut down
        project.workers.all.execute('shutdown')

        end_time = time.time()
        print("TIMER Project end event {0:.5f}", time.time())
        elapsed_time = end_time - start_time
        print("Time for event completion with {0} workers is {1} seconds"
              .format(args.n_workers, elapsed_time))
        print("Start Time: {0}\nEnd Time: {1}".format(start_time, end_time))

    print("Exiting Event Script")
    project.close()

