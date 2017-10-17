#!/bin/bash


RUNNAME=$1
ENVIRONMENT=$2
DB_HOSTNAME=$3
N_WORKERS=$4
N_THREADS_WORKER=$5
j=$ALPS_APP_PE 


export PATH=$CONDAPATH:$PATH 
echo "Environment var: $ENVIRONMENT"

if [[ ! -z $ENVIRONMENT ]]; then
  echo "source $CONDAPATH/activate $ENVIRONMENT"
  source $CONDAPATH/activate $ENVIRONMENT
fi

export PYTHON_EGG_CACHE=$CONDAPATH/../../.python-eggs/
which python
which adaptivemdworker

module load cudatoolkit
export OPENMM_CPU_THREADS=$N_THREADS_WORKER
export OPENMM_CUDA_COMPILER=`which nvcc`
echo "OPENMM_CPU_THREADS: $OPENMM_CPU_THREADS"

mod=`echo "$N_WORKERS*0.2" | bc`
delay=`echo "$j*0.1+$j%$mod" | bc`
echo "Delay of $delay"
sleep $delay

adaptivemdworker $RUNNAME --sleep 2 --dbhost $DB_HOSTNAME --verbose > workers.$RUNNAME.$j.log

sleep 3
