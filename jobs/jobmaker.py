#!/usr/bin/env/ python



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

    jobs = 'jobpackage/'
    job_filename = args.template
    job_template = jobs + '{0}.template'.format(job_filename)
    margs_filename = 'margs.cfg'
    margs_template = jobs + '{0}.template'.format(margs_filename)

    print("Reading job script template from:\n", job_template)

    date = '{0}{1}{2}{3}'.format('0' if len(str(now.month))==1 else '',
                                  now.month,
                                 '0' if len(str(now.day))==1 else '',
                                  now.day)

    job_name = '{0}_{1}'.format(args.project_name, date)
    job_folder = 'jobs/{0}/'.format(job_name)

    print("Job will be located in directory:\n", job_folder)
    job_file = job_folder + job_filename
    margs_file = job_folder + margs_filename

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

    with open(job_template, 'r') as f_in, open(job_file, 'w') as f_out:
        text = ''.join([line for line in f_in])
        f_out.write(text.format(
            project_name=args.project_name,
            system_name=args.system_name,
            nodes=args.nodes,
            threads=args.threads,
            n_workers=args.n_workers,
            w_threads=args.w_threads,
            longts='--longts' if args.longts else '',
            hours=args.hours,
            minutes=args.minutes,
            sampling_phase=args.sampling_function,
            strategy=args.strategy,
            platform=args.platform,
            environment=args.environment[0] if args.environment else '',
            n_rounds=args.n_rounds,
            minlength=args.minlength if args.minlength > args.length else args.length,
            n_ext=args.n_ext,
            modeller= args.modeller,
            n_traj=args.n_traj,
            prot=args.prot if not args.longts else args.prot * 2 / 5,
            all=args.all if not args.longts else args.all * 2 / 5,
            length=args.length,))

