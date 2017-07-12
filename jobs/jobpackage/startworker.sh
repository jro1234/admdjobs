#!/bin/bash


RUNNAME=$1
DB_HOSTNAME=$2
N_WORKERS=$3
j=$ALPS_APP_PE 

module load cudatoolkit
export OPENMM_CUDA_COMPILER=`which nvcc`
export OMP_NUM_THREADS=16
export OPENMM_CPU_THREADS=$OMP_NUM_THREADS

#echo "OPENMM_CPU_THREADS: $OPENMM_CPU_THREADS"
#which python
#which adaptivemdworker

#delay=`echo "$j*1" | bc`
#echo "Delay of $delay"
#sleep $delay
#adaptivemdworker $RUNNAME --sleep 2 --delay $delay --dbhost $DB_HOSTNAME --verbose > workers.$i.$j.log

adaptivemdworker $RUNNAME --sleep 2 --dbhost $DB_HOSTNAME --verbose > workers.$N_WORKERS.$j.log
