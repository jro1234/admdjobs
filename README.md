# ADMD Jobs

### Running AdaptiveMD on Titan

#### Get this code from:

  http://github.com/jrossyra/admdjobs
 
`admdjobs` should be placed cloned to long-term storage such as $HOME directory. It is intended to
create files, folders, and data in working locations (PROJECTWORK or MEMBERWORK).
Check the install locations of the software components at the top of `install_admd.sh`,
and install them by running this script. To get started, type `cd $ADMD_JOBS` and use
`jobmaker.py` as described below.

## Install:

ADMD is used to refer to the working layer employed for AdaptiveMD use. The
structure of ADMD will depend on the layout of its 4 major components:
* AdaptiveMD software package
* MongoDB database
* Data directory
* Working areas

Use `sh install_admd.linux.sh` from within `admdjobs/` and specify the appropriate install
directories at the top of file (`INSTALL_MONGODB`, `INSTALL_ADAPTIVEMD`, etc).
These install directories will be converted and saved in the user's `bashrc`
for navigating later (ie `cd $ADMD_JOBS` to script or save some time).
ADMD is run in a *compact* layout on Titan; the HPC job
completely contains and executes all elements to run ADMD. So all 4
components are specified, and set to be visible to compute nodes.


## Usage:

To deploy a job, use the jobmaker to specify the configuration and
name used. WATCH THE JOBS to make sure they don't hang and waste time, or 
very carefully specify the walltime. 
The wait function is trickier because of the job layout necessary for Titan.
The name will be used for the AdaptiveMD project and
the HPC job that runs it.

```bash
python jobmaker.py [project_name] [options]
```

Type the option `--help` to see all the options available. Soon there will just be a
configuration file option along with project name that can equivalently specify
the setup since many options are going to be used at a time, every time.

When creating a workflow, the total nodes will include all workers to run trajectory
and analysis tasks, along with an additional node for the database host.

#### Example:

This example shows how to create a simple workflow.
Because the entire workflow is contained in a job, a separate project
is created for each run and the number of `adaptivemdworker` is used
in the name for convenience. The number of nodes reserved for the job
is this number plus 1, for the data server node.

Create runnable job:

```bash
python jobmaker.py test21 ntl9 -e py27 --longts -n 12 -w 11 -N 10 -M pyemma-ionic -k 100000 -l 50000 -b 2 -x 1 -S explore_microstates -p 1000 -m 5000 -P CUDA -H 0 -W 10
```
For the Demo Run:
```
python jobmaker.py demo-xm ntl9 -e py27 --longts -n 12 -w 11 -N 10 -M pyemma-ionic -l 50000 -k 100000 -b 1 -x 1  -S explore_microstates -p 10000 -m 50000 -P CUDA -H 0 -W 30
```

* P: OpenMM platorm
* S: Sampling method
* e: Task conda environment
* M: Modelling tasks on
* n: n nodes
* w: n workers
* N: n trajectories
* b: n max tasks per job
* x: n rounds (of simulation task)
* l: n steps (per simulation task)
* k: n min steps per trajectory
* p: stride for protein structure
* m: stride for all atoms

When this is run, a small message will printout ending with the
relative path to the directory for new job. Navigate to the directory:

```bash
Reading job script template from:
 jobpackage/admd_deployDBworkers_bundledevent.pbs.template
Job will be located in directory:
 jobs/SCALING10_0711/
```

```bash
cd jobs/SCALING10_0711/
```

And submit the job:

```bash
qsub admd_job.pbs
```


## ADMD Environment on Titan

The *working area* is `$ADMD_JOBS` when using the setup described for Titan, but is not clarified
without a *layout*. It may be remote to the
resource or otherwise disconnected, or have less specification depending on DB connectivity and output
mode. It is intrinsically split by input and output, which may happen in the
same location. Wherever the user is when creating or providing tasks to a
project is the input *working area*. If any AdaptiveMD, adaptivemdworker,
or Job output is saved, it is also within the *working area* just because
that is where the output went.

To run AdaptiveMD on Titan, we must always have the proper visibilities between the user, the database, and
the jobs. All software needs to be installed in a PROJECT or MEMBER directory
visible to the compute nodes, ie `$MEMBERWORK` or `$PROJECTWORK`. `$MEMBERWORK` is
the prescribed directory for compute data. Without a visible external host
for the database, one extra compute node is reserved as the data server. At
job runtime, the database is created and run, and each `adaptivemdworker`
subsequently connects. When hosted in a stable location, the database address
can be written as a configuration option.

* $ADMD_JOBS - directory described below

* $ADAPTIVEMD - location of the installed AdaptiveMD package

* $ADMD_DB/                         - outer mongo directory
    * [dbinstances.cfg]        - configuration file for each db instance
    * data/
        * [computeIP/]        - location for db instance sockets
        * [dbinstances.db/]   - database directory for each instance

* $ADMD_DATA/           - directory used by <adaptivemdworker>
    * projects/  - data storage for projects
    * workers/   - working area for generating data


## ADMD_JOBS

The $ADMD_JOBS location is where a user will typically roam while conducting work with
AdaptiveMD on an HPC resource. New run scripts may be created by the user and
saved in `scripts/`. The jobmaker will run them using the `--strategy` option
to specify a particular one. These scripts will coordinate details such as
what system are we simulating? How should Simulation and Modelling
tasks be organized (ie what is the strategy)? Using the argument
structure provided by the argparser, there should be little to no
adaptation of the job templates without major changes to the strategy
operations.

* jobmaker.py  - deploys runnable jobs from configuration given
                 by the user and templates in jobpackage

* scripts/     - deployment scripts for formatting job templates
                 & user scripts for project runtime

* jobpackage/  - template files for ADMD Jobs

* jobs/        - directory containing jobs run on the HPC system,
                          subdirectories are named with `project_name`
                          argument given to jobmaker


Again, BE SURE TO WATCH for the job completion. Typically, the workers
will work and write their logs, and after they shut down the output
file `10101010.OU` will be modified to say the job is complete. The job
script attempts to track the various processes and wait / kill them
appropriately, but the user can kill job with a `qdel JOBNUMBER` as
soon as this line is printed.


## Summary:

#### ADMD on Titan

##### ADMD: AdaptiveMD Job deployment layer
User configures Jobs to run AdaptiveMD
  - Currently template files with unformatted fields are formatted
    to create a runnable job.
  - User provides command to configure details of the job
  - Layout is fixed, but complicated
    - eventually will configure layout with options

  - AdaptiveMD Installer `install_admd.sh`
    - Installs all required software and configures ADMD Environment
    - User provides directories for AdaptiveMD package, data, and jobs,
      and the Mongo Database

  - On Titan, everything is run inside the job. Currently use trivial events
    defined by a script `run_smalltest_event.py`
    - database folder is created
    - mongod is run
    - project is created
    - workers are launched
    - event script creates tasks
    - workers run until event completed
    - BE SURE to watch the jobs! stdout will say when job
      is completed even if it hangs.

  - one compute node used as data server. ip of compute node gemini
    interconnect is saved as file hostname.txt, and read by worker
    nodes to set the mongoDB URL and connect.

  - adaptivemdworkers are run via a script `startworker.sh` that
    loads CUDA, (CUDA in) the outer job environment on service nodes does not carry to
    the compute nodes.

  - database is run with script `startdb.sh` for environment and
    'pretask' to write hostname


