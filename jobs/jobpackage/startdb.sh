#!/bin/bash


RUNNAME=$1
N_WORKERS=$2


DB_HOSTNAME=`ip addr show ipogif0 | grep -Eo '(addr:)?([0-9]*\.){3}[0-9]*'`
echo "Host address: $DB_HOSTNAME"
echo "The workers will try to find MongoDB here"

echo "$DB_HOSTNAME" > $N_WORKERS.hostname

export OMP_NUM_THREADS=16

# Have to make config file specific to each database
# so each has own socket
mkdir ${ADMD_DB}data/$DB_HOSTNAME/
echo -e "net:\n   unixDomainSocket:\n      pathPrefix: ${ADMD_DB}data/$DB_HOSTNAME/\n   bindIp: 0.0.0.0" > ${ADMD_DB}mongo.$RUNNAME-$N_WORKERS-$DB_HOSTNAME.cfg 

if [ $N_WORKERS -gt 400 ]; then
  # TODO mongod decides to use default based on utime max files- fix
  maxconns=$((40+2*$N_WORKERS))
else
  # mongodb default
  maxconns=1000
fi

# Making database for each mongod
mkdir ${ADMD_DB}data/$RUNNAME.$N_WORKERS.db/
numactl --interleave=all mongod --maxConns $maxconns --config ${ADMD_DB}mongo.$RUNNAME-$N_WORKERS-$DB_HOSTNAME.cfg --dbpath ${ADMD_DB}data/$RUNNAME.$N_WORKERS.db/ --verbose &> mongo.$RUNNAME.$N_WORKERS.log

