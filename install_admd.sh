#!/bin/bash

CWD=`pwd`
## Paths for different installer components
INSTALL_CONDA=$PROJWORK/bip149/$USER/
# these ones saved to environment variables
INSTALL_ADAPTIVEMD=$PROJWORK/bip149/$USER/
INSTALL_ADMD_DATA=$MEMBERWORK/bip149/
INSTALL_ADMD_JOBS=$MEMBERWORK/bip149/
INSTALL_ADMD_DB=$PROJWORK/bip149/$USER/

## Options & Version configuration stuff:
ADAPTIVEMD_VERSION=jrossyra/adaptivemd.git
ADAPTIVEMD_BRANCH=py3_compat
GPU_ENV=cudatoolkit
CONDA_VERSION=2
OPENMM_VERSION=7.0
MONGODB_VERSION=3.3.0
PYMONGO_VERSION=3.3

## Environment preparation:
module load $GPU_ENV

###############################################################################
#
#  Install MongoDB
#
###############################################################################
cd $INSTALL_ADMD_DB
echo "Installing Mongo in: $INSTALL_ADMD_DB"
curl -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGODB_VERSION.tgz
tar -zxvf mongodb-linux-x86_64-$MONGODB_VERSION.tgz
mkdir mongodb
mv mongodb-linux-x86_64-$MONGODB_VERSION/ mongodb/
mkdir -p mongodb/data/db
rm mongodb-linux-x86_64-$MONGODB_VERSION.tgz
echo "# APPENDING PATH VARIABLE with AdaptiveMD Environment" >> ~/.bashrc
echo "export ADMD_DB=${INSTALL_ADMD_DB}mongodb/" >> ~/.bashrc
echo "export PATH=${INSTALL_ADMD_DB}mongodb/mongodb-linux-x86_64-$MONGODB_VERSION/bin/:\$PATH" >> ~/.bashrc
echo "Done installing Mongo, appended PATH with mongodb bin folder"
# Mongo should default to using /tmp/mongo-27017.sock as socket
echo -e "net:\n   unixDomainSocket:\n      pathPrefix: ${INSTALL_ADMD_DB}mongodb/data/\n   bindIp: 0.0.0.0" > ${INSTALL_ADMD_DB}mongodb/mongo.cfg
source ~/.bashrc
echo "MongoDB daemon installed here: "
which mongod

###############################################################################
#
#  Install Miniconda & packages
#
###############################################################################
cd $INSTALL_CONDA
curl -O https://repo.continuum.io/miniconda/Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh
bash Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh -p ${INSTALL_CONDA}miniconda$CONDA_VERSION/
source ~/.bashrc
echo "Miniconda conda executable here: "
which conda
conda install python
conda install ujson pyyaml numpy pymongo=$PYMONGO_VERSION pyemma openmm=$OPENMM_VERSION mdtraj
rm Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh

###############################################################################
#   Install AdaptiveMD from git repo
#   - resides with python install
###############################################################################
cd $INSTALL_ADAPTIVEMD
git clone https://github.com/$ADAPTIVEMD_VERSION
cd adaptivemd/
git checkout $ADAPTIVEMD_BRANCH
python setup.py develop
python -c "import adaptivemd" || echo "something wrong with adaptivemd install"
echo "export ADAPTIVEMD=${INSTALL_ADAPTIVEMD}adaptivemd/" >> ~/.bashrc
## TEST AdaptiveMD
echo "Starting database for tests"
mongod --config ${INSTALL_ADMD_DB}mongodb/mongo.cfg --dbpath ${INSTALL_ADMD_DB}mongodb/data/db/ --verbose > ${INSTALL_ADMD_DB}mongodb/data/mongo.install.log &
MONGO_PID=$!
cd adaptivemd/tests/
echo "Testing AdaptiveMD with python version: "
which python
python test_simple.py
echo "Closing database after tests"
kill $MONGO_PID

###############################################################################
#
#   Now creating the Data Directory
#
###############################################################################
cd $INSTALL_ADMD_DATA
mkdir admd/
echo "projects and workers subfolders will be created"
echo "by AdaptiveMD inside this directory:"
echo "  `pwd`/admd/"
echo "export ADMD_DATA=${INSTALL_ADMD_DATA}admd/" >> ~/.bashrc

###############################################################################
#
#   Now creating the Jobs Directory
#
###############################################################################
cd $INSTALL_ADMD_JOBS
mkdir admd/
cd admd
cp -r $CWD/jobs/ ./
echo "export ADMD_JOBS=${INSTALL_ADMD_JOBS}admd/jobs/" >> ~/.bashrc
source ~/.bashrc
cd $CWD
echo "if no errors then AdaptiveMD & dependencies installed"

echo "\$ADAPTIVEMD added to environment:"
echo $ADAPTIVEMD
echo "\$ADMD_DB added to environment:"
echo $ADMD_DB
echo "\$ADMD_DATA added to environment:"
echo $ADMD_DATA
echo "\$ADMD_JOBS added to environment:"
echo $ADMD_JOBS
