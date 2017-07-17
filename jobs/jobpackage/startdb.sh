#!/bin/bash


RUNNAME=$1
N_WORKERS=$2

export OMP_NUM_THREADS=16

# Parse the ip address of this node on Gemini
# high-speed interconnect.
DB_HOSTNAME=`ip addr show ipogif0 | grep -Eo '(addr:)?([0-9]*\.){3}[0-9]*'`
echo "The workers will try to find MongoDB here"
echo "Host address: $DB_HOSTNAME"


# The workers will read this file to get
# the address to this DB hosting node.
echo "$DB_HOSTNAME" > $N_WORKERS.hostname

# Making config file specific to each database
# so each has own socket. Can run concurrent DB
# independently (for different jobs, etc).
mkdir ${ADMD_DB}data/$DB_HOSTNAME/
echo -e "net:\n   unixDomainSocket:\n      pathPrefix: ${ADMD_DB}data/$DB_HOSTNAME/\n   bindIp: 0.0.0.0" > ${ADMD_DB}mongo.$RUNNAME-$N_WORKERS-$DB_HOSTNAME.cfg 

if [ $N_WORKERS -gt 400 ]; then
  # this may evaluate to higher than the system hard limit,
  # which will take effect and prevent the remaining
  # worker connections... be careful to avoid waste
  maxconns=$((40+2*$N_WORKERS))
  ulim=`echo "$maxconns*1.2" | bc`
  ulimit -n ${ulim%.*}
else
  # mongodb default for typical file ulimit of 1024
  maxconns=819
fi

# Making database (ie directory) for this mongod instance
mkdir ${ADMD_DB}data/$RUNNAME.$N_WORKERS.db/
numactl --interleave=all mongod --maxConns $maxconns --config ${ADMD_DB}mongo.$RUNNAME-$N_WORKERS-$DB_HOSTNAME.cfg --dbpath ${ADMD_DB}data/$RUNNAME.$N_WORKERS.db/ &> mongo.$RUNNAME.$N_WORKERS.log

