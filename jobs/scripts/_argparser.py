#!/usr/bin/env/ python


from argparse import ArgumentParser


def argparser():

    parser = ArgumentParser(description="Create admd jobs")

    parser.add_argument("project_name",
        help="Name of project")

    parser.add_argument("system_name",
        help="Name of system")

    parser.add_argument("--init_only",
        help="Only initialize project",
        action="store_true")

    parser.add_argument("-N","--n-trajectory", dest="n_traj",
        help="Number of trajectories to create",
        type=int, default=16)

    parser.add_argument("-M","--modeller", dest="modeller",
        help="Create a model each iteration")

    parser.add_argument("-w","--n-workers", dest="n_workers",
        help="Number of workers in job",
        type=int, default=12)

    parser.add_argument("-x","--n-extension", dest="n_ext",
        help="Number of extensions to trajectories",
        type=int, default=1)

    parser.add_argument("-e","--environment", nargs='*',
        help="Environment for running tasks")

    parser.add_argument("--longts", dest="longts",
        help="Flag for 5fs timesteps",
        action='store_true')

    parser.add_argument("-l","--length", nargs='+',
        help="Length of trajectory segments in frames\n - give a 2nd length to create a longer job\n    for rounds that include a model task",
        type=int, default=100)

    parser.add_argument("-b","--n_rounds",
        help="Number of task rounds inside a single PBS job",
        type=int, default=0)

    parser.add_argument("-k","--minlength",
        help="Minimum trajectory total length in frames",
        type=int, default=300)

    parser.add_argument("-f","--fixedlength",
        help="Default uses fixed traj length, flag to randomize by fraction 0.2 of length argument",
        action='store_false')

    parser.add_argument("-p","--protein-stride", dest="prot",
        help="Stride between saved protein structure frames",
        type=int, default=5)

    parser.add_argument("-m","--master-stride", dest="all",
        help="Stride between saved frames with all atoms",
        type=int, default=20)

    parser.add_argument("-P","--platform",
        help="Simulation Platform: Reference, CPU, CUDA, or OpenCL",
        type=str, default="CPU")

    parser.add_argument("-A","--activate_prefix",
        help="Prefix for activate script",
        type=str, default="$CONDAPATH")

    parser.add_argument("-d","--dbhost",
        help="IP address of MongoDB host",
        type=str, default="localhost")

    parser.add_argument("-r","--strategy",
        help="Filename of strategy script to run for generating tasks",
        type=str, default="run_workflow.py")

    parser.add_argument("-S","--sampling_function",
        help="Name of sampling function saved in sampling_functions.py",
        type=str, default="random_restart")

    parser.add_argument("-n","--n-nodes", dest="nodes",
        help="Number of nodes for job",
        type=int, default=2)

    parser.add_argument("-s","--worker-threads", dest="w_threads",
        help="Number of threads per worker",
        type=int, default=2)

    parser.add_argument("-t","--node-threads", dest="threads",
        help="Number of threads per node",
        type=int, default=16)

    parser.add_argument("-i","--template", dest="template",
        help="Input job template file, ie admd_workers.pbs",
        type=str, default="admd_titan_job.pbs")

    parser.add_argument("-H","--hours", dest="hours",
        help="Job hours of walltime",
        type=int, default=1)

    parser.add_argument("--tica_lag",
        help="TICA lag in frames",
        type=int, default=25)

    parser.add_argument("--tica_dim",
        help="Number of TICA dimensions for clustering",
        type=int, default=3)

    parser.add_argument("--tica_stride",
        help="TICA stride in frames",
        type=int, default=5)

    parser.add_argument("--clust_stride",
        help="Clustering stride in frames",
        type=int, default=5)

    parser.add_argument("--msm_lag",
        help="MSM lag in frames",
        type=int, default=25)

    parser.add_argument("--msm_states",
        help="MISLEADING name, number of microstates for clustering",
        type=int, default=50)

    parser.add_argument("-W","--minutes", dest="minutes",
        help="Job minutes of walltime",
        type=int, default=0)

    return parser
