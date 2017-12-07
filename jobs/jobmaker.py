#!/usr/bin/env python



from __future__ import print_function
from datetime import datetime
from subprocess import call
from shlex import split
import shutil
import sys, os

from scripts._argparser import argparser



if __name__ == "__main__":

    parser = argparser()
    args = parser.parse_args()

    now = datetime.now()
    date = '{0}{1}{2}{3}'.format('0' if len(str(now.month))==1 else '',
                                  now.month,
                                 '0' if len(str(now.day))==1 else '',
                                  now.day)

    jobs = 'jobpackage/'
    job_filename = args.template
    job_template = jobs + '{0}.template'.format(job_filename)
    margs_filename = 'margs.cfg'
    margs_template = jobs + '{0}.template'.format(margs_filename)
    job_name = '{0}_{1}'.format(args.project_name, date)
    job_folder = 'jobs/{0}/'.format(job_name)
    job_files = [job_folder+job_filename]

    if len(args.length) > 2:
        # it will always be at least one from nargs='+'
        print("Require 1 or 2 values for length argument")
        raise ValueError

    elif len(args.length) == 2:
        _fn = job_filename.split('.')
        _fn.insert(1, '{0}')
        fn = '.'.join(_fn)
        job_template = jobs + fn.format('2lengths') + '.template'
        job_files.append(job_folder+fn.format('long'))

    print("\n\n------------------------------------------")
    print("----  Making a new Titan Job with the  ---")
    print("----  given AdaptiveMD workflow config ---")
    print("------------------------------------------\n")
    print("Reading job script template from:\n", job_template)

    stopjob = job_folder + 'stopjob'
    job_file = job_folder + job_filename
    margs_file = job_folder + margs_filename


    print("\nJob will be located in directory:\n\n        ", job_folder)
    print("\n - to submit the job:\n\n        $ qsub {0}\n".format(job_filename))
    print(" - there is an empty file called 'stopjob' in the")
    print("   folder, delete this file to have jobs resubmit")
    print("   themselves perpetually. When you want this job")
    print("   chain to halt, type a 'touch stopjob' in the")
    print("   folder to prevent the next resubmission.")
    print("   output from each round will be stored in a")
    print("   folder named 'roundXXXX', starting at 0001")
    print("\n    - the final stdout/ stderr will remain in")
    print("      the outer folder until manually moved to")
    print("      the storage folder for that round.\n\n")

    os.mkdir(job_folder)

    ## TODO args to build job script here
    job_scripts = ['startworker.sh',
                   'startdb.sh',
                   'configuration.cfg']

    with open(margs_template, 'r') as f_in, open(margs_file, 'w') as f_out:
        text = ''.join([line for line in f_in])
        f_out.write(text.format(
            project_name=args.project_name,
            clust_stride=args.clust_stride,
            tica_stride=args.tica_stride,
            tica_lag=args.tica_lag,
            tica_dim=args.tica_dim,
            msm_states=args.msm_states,
            msm_lag=args.msm_lag))

    for jobscript in job_scripts:
        shutil.copy('jobpackage/'+jobscript, job_folder+jobscript)

    os.system("touch {0}".format(stopjob))

    with open(job_template, 'r') as f_in:
        _text = ''.join([line for line in f_in])

    linekeys = ['#{regular}#', '#{long}#']
    for i, job_file in enumerate(job_files):
        text = list()

        for line in _text.split('\n'):
            if line.find(linekeys[1-i]) >= 0:
                continue

            elif line.find(linekeys[i]) >= 0:
                startpos = line.find(linekeys[i])+len(linekeys[i])-1
                text.append(line[startpos:])

            else:
                text.append(line)

        length = args.length[i]

        if i == 1:
            _total_time = 60 * args.hours + args.minutes
            long_factor = length / args.length[0]
            total_time = _total_time * long_factor
            hours, minutes = divmod(total_time, 60)

        elif i == 0:
            hours, minutes = args.hours, args.minutes

        with open(job_file, 'w') as f_out:
            f_out.write('\n'.join(text).format(
                project_name=args.project_name,
                system_name=args.system_name,
                nodes=args.nodes,
                threads=args.threads,
                n_workers=args.n_workers,
                w_threads=args.w_threads,
                longts='--longts' if args.longts else '',
                hours=hours,
                minutes=minutes,
                sampling_phase=args.sampling_function,
                strategy=args.strategy,
                platform=args.platform,
                environment=args.environment[0] if args.environment else '',
                n_rounds=args.n_rounds,
                minlength=args.minlength if args.minlength > length else length,
                n_ext=args.n_ext,
                modeller= args.modeller,
                n_traj=args.n_traj,
                prot=args.prot,
                all=args.all,
                length=length,))

