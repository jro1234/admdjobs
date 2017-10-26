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
echo "$DB_HOSTNAME" > $RUNNAME.hostname

# Making config file specific to each database
# so each has own socket. Can run concurrent DB
# independently (for different jobs, etc).
mkdir ${ADMD_DB}data/$DB_HOSTNAME/
echo -e "net:\n   unixDomainSocket:\n      pathPrefix: ${ADMD_DB}data/$DB_HOSTNAME/\n   bindIp: 0.0.0.0" > ${ADMD_DB}mongo.$RUNNAME-$DB_HOSTNAME.cfg 

echo "Hopefully ulimit is 32k..."
ulimit -n
# Making database (ie directory) for this mongod instance
numactl --interleave=all mongod --config ${ADMD_DB}mongo.$RUNNAME-$DB_HOSTNAME.cfg --dbpath ${ADMD_DB}data/$RUNNAME.db/ &> mongo.$RUNNAME.$N_WORKERS.log

