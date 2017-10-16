#!/bin/bash


# TODO Add a check for the python version
#      on Titan, default is super-old 2.6
#      and this will load 2.7.9 by default
module load python

CWD=`pwd`

## Paths for different installer components
INSTALL_CONDA=$PROJWORK/bip149/$USER/

# these ones saved to environment variables
INSTALL_ADAPTIVEMD=$PROJWORK/bip149/$USER/
INSTALL_ADMD_DATA=$PROJWORK/bip149/$USER/
INSTALL_ADMD_JOBS=$PROJWORK/bip149/$USER/
INSTALL_ADMD_DB=$PROJWORK/bip149/$USER/

FOLDER_ADMD_DB=mongodb
FOLDER_ADMD_DATA=admd
FOLDER_ADMD_JOBS=admd

## Options & Versions:
ADAPTIVEMD_VERSION=jrossyra/adaptivemd.git
ADAPTIVEMD_BRANCH=rp_integration

CONDA_ENV_NAME=py27
CONDA_ENV_VERSION=2.7

CONDA_VERSION=2
OPENMM_VERSION=7.0
MONGODB_VERSION=3.3.0
#PYMONGO_VERSION=3.5

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
mv mongodb-linux-x86_64-$MONGODB_VERSION/ $FOLDER_ADMD_DB
mkdir -p ${FOLDER_ADMD_DB}/data/db
rm mongodb-linux-x86_64-$MONGODB_VERSION.tgz
echo "# APPENDING PATH VARIABLE with AdaptiveMD Environment" >> ~/.bashrc
echo "export ADMD_DB=${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/" >> ~/.bashrc
echo "export PATH=${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongodb-linux-x86_64-$MONGODB_VERSION/bin/:\$PATH" >> ~/.bashrc
echo "Done installing Mongo, appended PATH with mongodb bin folder"
# Mongo should default to using /tmp/mongo-27017.sock as socket
echo -e "net:\n   unixDomainSocket:\n      pathPrefix: ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/data/\n   bindIp: 0.0.0.0" > ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongo.cfg
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
echo "Miniconda conda executable here: "
echo "export CONDAPATH=${INSTALL_CONDA}miniconda$CONDA_VERSION/bin" >> ~/.bashrc
source ~/.bashrc
PATH=$CONDAPATH:$PATH
which conda
#conda install python
conda create -n $CONDA_ENV_NAME python=$CONDA_ENV_VERSION

source activate $CONDA_ENV_NAME


rm Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh

###############################################################################
#   Install AdaptiveMD from git repo
#   - resides with python install
###############################################################################
cd $INSTALL_ADAPTIVEMD
git clone https://github.com/$ADAPTIVEMD_REPO
cd adaptivemd/
git checkout $ADAPTIVEMD_BRANCH
python setup.py $ADAPTIVEMD_INSTALLMETHOD
python -c "import adaptivemd" || echo "something wrong with adaptivemd install"
echo "export ADAPTIVEMD=${INSTALL_ADAPTIVEMD}adaptivemd/" >> ~/.bashrc


# TODO 1) this is somewhat redundant with AdaptiveMD install
#      - allow task stack to change versions 
#        but... always install default task stack
#               with specified or latest version
#
#conda install ujson pyyaml numpy pymongo=$PYMONGO_VERSION pyemma openmm=$OPENMM_VERSION mdtraj

# TODO 2) see 1) here is the default task stack with versions for Titan
#      - with [admdjobs] it is installed in same env as adaptivemd
#        for streamlined adaptivemdworker usage
conda install pyemma openmm=$OPENMM_VERSION mdtraj

## TODO 3) Update Docs and Tests with new API
### TEST AdaptiveMD
#echo "Starting database for tests"
#mongod --config ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongo.cfg --dbpath ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/data/db/ --verbose > ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/data/mongo.install.log &
#MONGO_PID=$!
#cd adaptivemd/tests/
#echo "Testing AdaptiveMD with python version: "
#which python
#python test_simple.py
#echo "Closing database after tests"
#kill $MONGO_PID

###############################################################################
#
#   Now creating the Data Directory
#
###############################################################################
cd $INSTALL_ADMD_DATA
mkdir $FOLDER_ADMD_DATA
echo "'projects' and 'workers' subfolders will be created"
echo "by AdaptiveMD inside this directory:"
echo "  `pwd`/${FOLDER_ADMD_DATA}/"
echo "export ADMD_DATA=${INSTALL_ADMD_DATA}${FOLDER_ADMD_DATA}/" >> ~/.bashrc

###############################################################################
#
#   Now creating the Jobs Directory
#
###############################################################################
cd $INSTALL_ADMD_JOBS
mkdir $FOLDER_ADMD_JOBS
cd $FOLDER_ADMD_JOBS
cp -r $CWD/jobs/ ./
echo "export ADMD_JOBS=${INSTALL_ADMD_JOBS}${FOLDER_ADMD_JOBS}/jobs/" >> ~/.bashrc
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
