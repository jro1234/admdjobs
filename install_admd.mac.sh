#!/bin/bash


# TODO Add a check for the python version
#      on Titan, default is super-old 2.6
#      and this will load 2.7.9 by default
module load python
CWD=`pwd`

## Paths for different installer components
##  - useful paths are saved to environment
INSTALL_CONDA=$HOME/ADMD/

INSTALL_ADAPTIVEMD=$HOME/ADMD/
INSTALL_ADMD_DATA=$HOME/ADMD/
INSTALL_ADMD_JOBS=$HOME/ADMD/
INSTALL_ADMD_DB=$HOME/ADMD/
FOLDER_ADMD_DB=mongodb
FOLDER_ADMD_DATA=admd
FOLDER_ADMD_JOBS=admd

## Options & Versions:
ADAPTIVEMD_VERSION=jrossyra/adaptivemd.git
ADAPTIVEMD_BRANCH=rp_integration
CONDA_VERSION=2
OPENMM_VERSION=7.0

# These versions for compatibility with
# the libraries available on Titan
MONGODB_VERSION=3.2.17
PYMONGO_VERSION=3.5

###############################################################################
#
#  Install MongoDB
#
###############################################################################
cd $INSTALL_ADMD_DB
echo "Installing Mongo in: $INSTALL_ADMD_DB"
curl -O https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-$MONGODB_VERSION.tgz
tar -zxvf mongodb-osx-x86_64-$MONGODB_VERSION.tgz
mkdir mongodb
mv mongodb-osx-x86_64-$MONGODB_VERSION/ $FOLDER_ADMD_DB
mkdir -p ${FOLDER_ADMD_DB}/data/db
rm mongodb-osx-x86_64-$MONGODB_VERSION.tgz
echo "# APPENDING PATH VARIABLE with AdaptiveMD Environment" >> ~/.bashrc
echo "export ADMD_DB=${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/" >> ~/.bashrc
echo "export PATH=${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongodb-osx-x86_64-$MONGODB_VERSION/bin/:\$PATH" >> ~/.bashrc
echo "Done installing Mongo, appended PATH with mongodb bin folder"

# Mongo should default to using /tmp/mongo-27017.sock as socket
#echo -e "net:\n   unixDomainSocket:\n      pathPrefix: ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/data/\n   bindIp: 0.0.0.0" > ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongo.cfg
source ~/.bashrc
echo "MongoDB daemon installed here: "
which mongod

###############################################################################
#
#  Install Miniconda & py27 Environment for AdaptiveMD
#
###############################################################################
cd $INSTALL_CONDA
curl -O https://repo.continuum.io/miniconda/Miniconda$CONDA_VERSION-latest-MacOSX-x86_64.sh
bash Miniconda$CONDA_VERSION-latest-MacOSX-x86_64.sh -p ${INSTALL_CONDA}miniconda$CONDA_VERSION/
echo "Miniconda conda executable here: "
echo "export CONDAPATH=${INSTALL_CONDA}miniconda$CONDA_VERSION/bin" >> ~/.bashrc
source ~/.bashrc
PATH=$CONDAPATH:$PATH
which conda
#conda install python
conda create -n py27 python=2.7

source activate py27

rm Miniconda$CONDA_VERSION-latest-MacOSX-x86_64.sh

###############################################################################
#   Install AdaptiveMD from git repo
#   - resides with python install
###############################################################################
cd $INSTALL_ADAPTIVEMD
git clone https://github.com/$ADAPTIVEMD_VERSION
cd adaptivemd/
git checkout $ADAPTIVEMD_BRANCH

# TODO this is redundant with AdaptiveMD install
#      remove after test
#
# TODO this is the current Task Stack
#      executed within the Task Mains
#conda install numpy pyemma openmm=$OPENMM_VERSION mdtraj
#
# TODO move this to setup.yaml
conda install six ujson pyyaml

#python setup.py develop
pip install .

python -c "import adaptivemd" || echo "something wrong with adaptivemd install"
echo "export ADAPTIVEMD=${INSTALL_ADAPTIVEMD}adaptivemd/" >> ~/.bashrc

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

source deactivate

###############################################################################
#
#   Now creating the Data Directory
#
###############################################################################
cd $INSTALL_ADMD_DATA
mkdir $FOLDER_ADMD_DATA
echo "projects and workers subfolders will be created"
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
