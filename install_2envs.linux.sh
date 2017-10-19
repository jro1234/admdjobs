#!/bin/bash


module load python
CWD=`pwd`

## Paths for different installer components
INSTALL_CONDA=$PROJWORK/bip149/$USER/
INSTALL_ADMD_ENV=$PROJWORK/bip149/$USER/

# these ones saved to environment variables
INSTALL_ADAPTIVEMD=$PROJWORK/bip149/$USER/
INSTALL_ADMD_DATA=$PROJWORK/bip149/$USER/
INSTALL_ADMD_JOBS=$PROJWORK/bip149/$USER/
INSTALL_ADMD_DB=$PROJWORK/bip149/$USER/

FOLDER_ADMD_DB=mongodb
FOLDER_ADMD_DATA=admd
FOLDER_ADMD_JOBS=admd
FOLDER_ADMD_ENV=admd

## Options & Versions:
ADAPTIVEMD_VERSION=jrossyra/adaptivemd.git
ADAPTIVEMD_BRANCH=rp_integration
#ADAPTIVEMD_INSTALLMETHOD=install

# This has given trouble !to only me! when loading
# inside of a job on Titan, so currently
# we have everything install under the
# *root* conda
#CONDA_ENV_NAME=
#CONDA_ENV_VERSION=
CONDA_ENV_NAME=py27
CONDA_ENV_VERSION=2.7
CONDA_VERSION=2
ADMD_ENV_NAME=admdenv
ADMD_ENV_PYTHON=2.7

OPENMM_VERSION=7.0
MONGODB_VERSION=3.3.0
PYMONGO_VERSION=3.3

###############################################################################
#  Install MongoDB                                                            #
###############################################################################
cd $INSTALL_ADMD_DB
echo "Installing Mongo in: $INSTALL_ADMD_DB"
curl -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGODB_VERSION.tgz
tar -zxvf mongodb-linux-x86_64-$MONGODB_VERSION.tgz
mkdir $FOLDER_ADMD_DB
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
#  Install VirtualEnv for AdaptveMD Application                               #
###############################################################################
cd $INSTALL_ADMD_ENV
mkdir $FOLDER_ADMD_ENV
cd $FOLDER_ADMD_ENV
ADMD_ENV=`pwd`/
virtualenv $ADMD_ENV/$ADMD_ENV_NAME

echo "export ADMD_ENV_ACTIVATE=${ADMD_ENV}$ADMD_ENV_NAME/bin/activate" >> ~/.bashrc

source ~/.bashrc
source $ADMD_ENV_ACTIVATE

###############################################################################
#   Install AdaptiveMD from git repo                                           #
###############################################################################
cd $INSTALL_ADAPTIVEMD
# TODO 1) this is somewhat redundant with AdaptiveMD install
#      - using `python setup.py install`, there is no check
#        and installation of dependencies. installed as conda
#        packages instead.
#
git clone https://github.com/$ADAPTIVEMD_VERSION
cd adaptivemd
pip install pyyaml
pip install six
# Otherwise six doesn't get added to site-packages
pip install six --upgrade

#deactivate
#source ${ADMD_ENV}bin/activate

pip install .
python -c "import adaptivemd" || echo "something wrong with adaptivemd install"
echo "export ADAPTIVEMD=${INSTALL_ADAPTIVEMD}adaptivemd/" >> ~/.bashrc

deactivate

###############################################################################
#  Install Miniconda                                                          #
###############################################################################
cd $INSTALL_CONDA
curl -O https://repo.continuum.io/miniconda/Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh
bash Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh -p ${INSTALL_CONDA}miniconda$CONDA_VERSION/
echo "Miniconda conda executable here: "
echo "export CONDAPATH=${INSTALL_CONDA}miniconda$CONDA_VERSION/bin" >> ~/.bashrc
source ~/.bashrc
PATH=$CONDAPATH:$PATH

###############################################################################
#  Install py27 Environment for AdaptiveMD Tasks                              #
###############################################################################
which conda
conda config --append channels conda-forge
conda config --append channels omnia

if [[ ! -z "$CONDA_ENV_NAME" ]]; then
  echo "Creating and Activating new conda env: $CONDA_ENV_NAME"
  conda create -n $CONDA_ENV_NAME python=$CONDA_ENV_VERSION
  source $CONDAPATH/activate $CONDA_ENV_NAME
fi

rm Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh

###############################################################################
#   Install AdaptiveMD Task Stack                                             #
###############################################################################
# TODO 2) here is the default task stack with versions for Titan
#      - with [admdjobs] it is installed in same env as adaptivemd
#        for streamlined adaptivemdworker usage
#      - allow task stack to change versions 
#        but... always install default task stack
#               with specified or latest version
#conda install openmm=$OPENMM_VERSION mdtraj pyemma 
conda install numpy openmm=$OPENMM_VERSION mdtraj pyemma

###############################################################################
#   Test AdaptiveMD Installation                                              #
###############################################################################
## TODO 3) TEST AdaptiveMD
#echo "Starting database for tests"
#mongod --config ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongo.cfg --dbpath ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/data/db/ --verbose > ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/data/mongo.install.log &
#MONGO_PID=$!
#cd adaptivemd/tests/
#echo "Testing AdaptiveMD with python version: "
#which python
#python test_simple.py
#echo "Closing database after tests"
#kill $MONGO_PID

if [[ ! -z "$CONDA_ENV_NAME" ]]; then
  echo "Deactivating conda env: $CONDA_ENV_NAME"
  source deactivate
fi

module unload python

###############################################################################
#   Now creating the Data Directory                                           #
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
cp -r $CWD/jobs-2env/ ./jobs/
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

