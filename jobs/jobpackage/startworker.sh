#!/bin/bash


RUNNAME=$1
DB_HOSTNAME=$2
N_WORKERS=$3
N_THREADS_WORKER=$4
j=$ALPS_APP_PE 

module load cudatoolkit

export PYTHON_EGG_CACHE=$CONDAPATH/../../.python-eggs/
export PATH=$CONDAPATH:$PATH 
which python
which adaptivemdworker

export OPENMM_CPU_THREADS=$N_THREADS_WORKER
export OPENMM_CUDA_COMPILER=`which nvcc`

echo "OPENMM_CPU_THREADS: $OPENMM_CPU_THREADS"

mod=`echo "$N_WORKERS*0.2" | bc`
delay=`echo "$j*0.1+$j%$mod" | bc`
echo "Delay of $delay"
sleep $delay

adaptivemdworker $RUNNAME --sleep 2 --dbhost $DB_HOSTNAME --verbose > workers.$RUNNAME.$j.log

sleep 3
