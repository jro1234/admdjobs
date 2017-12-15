#!/bin/bash


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
ADAPTIVEMD_INSTALLMETHOD=install

# It would also be fine to use the root CONDA
# environment if there is no other use of it.
#CONDA_ENV_NAME=
#CONDA_ENV_PYTHON=
CONDA_ENV_NAME=py27
CONDA_ENV_PYTHON=2.7
CONDA_VERSION=2
# TODO
# AdaptiveMD imports EXTREMELY slowly in
# some versions of CONDA, will resolve
# eventually but for now this version
# works fine.
CONDA_PKG_VERSION=4.3.23

#NUMPY_VERSION=1.13
OPENMM_VERSION=7.0
MONGODB_VERSION=3.3.0
PYMONGO_VERSION=3.5

# Application Package dependencies 
#ADMD_APP_PKG="pyyaml six ujson numpy=$NUMPY_VERSION"
ADMD_APP_PKG="pyyaml six ujson numpy"
# Task Package dependencies 
ADMD_TASK_PKG="openmm=$OPENMM_VERSION mdtraj pyemma"

# CONDA tries to upgrade itself at every turn
# - must stop it if installing in the outer conda
# - inside an env, conda won't update so its ok
if [[ ! -z "$CONDA_ENV_NAME" ]]; then
  ADMD_APP_PKG+=" conda=$CONDA_PKG_VERSION"
fi

###############################################################################
#  Install MongoDB                                                            #
###############################################################################
if [ ! -x "$(command -v mongod)" ]; then
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
else
  echo "Found MongoDB already installed at: "
fi
which mongod

###############################################################################
#  Install Miniconda                                                          #
###############################################################################
if [ -z ${CONDAPATH+x} ]; then
  cd $INSTALL_CONDA
  curl -O https://repo.continuum.io/miniconda/Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh
  bash Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh -p ${INSTALL_CONDA}miniconda$CONDA_VERSION/
  echo "Miniconda conda executable here: "
  echo "export CONDAPATH=${INSTALL_CONDA}miniconda$CONDA_VERSION/bin" >> ~/.bashrc
  source ~/.bashrc
  PATH=$CONDAPATH:$PATH
  conda config --append channels conda-forge
  conda config --append channels omnia
  conda install conda=$CONDA_PKG_VERSION
  rm Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh
fi

###############################################################################
#  Install Conda Environment for AdaptiveMD                                   #
###############################################################################
which conda
if [[ ! -z "$CONDA_ENV_NAME" ]]; then
  ENVS=`$CONDAPATH/conda env list`
  if ! echo "$ENVS" | grep -q "$CONDA_ENV_NAME"; then
    echo "Creating and Activating new conda env: $CONDA_ENV_NAME"
    conda create -n $CONDA_ENV_NAME python=$CONDA_ENV_PYTHON
  fi
  source $CONDAPATH/activate $CONDA_ENV_NAME
fi

###############################################################################
#   Install AdaptiveMD from git repo                                          #
###############################################################################
if [ ! -d "$INSTALL_ADAPTIVEMD/adaptivemd" ]; then
  cd $INSTALL_ADAPTIVEMD
  git clone https://github.com/$ADAPTIVEMD_VERSION
  cd adaptivemd/
  git checkout $ADAPTIVEMD_BRANCH
  echo "Installing these Packages in AdaptiveMD Application Environment"
  echo $ADMD_APP_PKG
  conda install $ADMD_APP_PKG
  python setup.py $ADAPTIVEMD_INSTALLMETHOD
  python -W ignore -c "import adaptivemd" || echo "something wrong with adaptivemd install"
  echo "export ADAPTIVEMD=${INSTALL_ADAPTIVEMD}adaptivemd/" >> ~/.bashrc
fi

###############################################################################
#   Install AdaptiveMD Task Stack in Application Environment                  #
###############################################################################
echo "Installing these Packages in AdaptiveMD Task Layer"
echo $ADMD_TASK_PKG
conda install $ADMD_TASK_PKG

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

###############################################################################
#   Now creating the Data Directory                                           #
###############################################################################
if [ ! -d "$INSTALL_ADMD_DATA/$FOLDER_ADMD_DATA" ]; then
  cd $INSTALL_ADMD_DATA
  mkdir $FOLDER_ADMD_DATA
  echo "'projects' and 'workers' subfolders will be created"
  echo "by AdaptiveMD inside this directory:"
  echo "  `pwd`/${FOLDER_ADMD_DATA}/"
  echo "export ADMD_DATA=${INSTALL_ADMD_DATA}${FOLDER_ADMD_DATA}/" >> ~/.bashrc
fi

###############################################################################
#
#   Now creating the Jobs Directory
#
###############################################################################
if [ ! -d "$INSTALL_ADMD_JOBS/$FOLDER_ADMD_JOBS" ]; then
  cd $INSTALL_ADMD_JOBS
  mkdir $FOLDER_ADMD_JOBS
  cd $FOLDER_ADMD_JOBS
  cp -r $CWD/jobs/ ./
  echo "export ADMD_JOBS=${INSTALL_ADMD_JOBS}${FOLDER_ADMD_JOBS}/jobs/" >> ~/.bashrc
  source ~/.bashrc
  cd $CWD
  echo "if no errors then AdaptiveMD & dependencies installed"
fi

echo "\$ADAPTIVEMD added to environment:"
echo $ADAPTIVEMD
echo "\$ADMD_DB added to environment:"
echo $ADMD_DB
echo "\$ADMD_DATA added to environment:"
echo $ADMD_DATA
echo "\$ADMD_JOBS added to environment:"
echo $ADMD_JOBS

