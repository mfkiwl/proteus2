#!/bin/bash

# This script installs Proteus on Fedora,
# including a MOOSE framework build in the $HOME directory.
# Optimised to the native system architecture.
# A .proteus_profile script is added to the $HOME directory.
# This script is intended to be used from the proteus directory
#   ./scripts/install_fedora.sh
# Use the installation by typing:
#   source $HOME/.proteus_profile

export PROTEUS_DIR=`pwd`

# If MOOSE_JOBS is unset, set to 1
if [ -z $MOOSE_JOBS ]; then
  export MOOSE_JOBS=1
fi

# Install pre-requisites

sudo dnf install gcc gcc-c++ gcc-fortran cmake bison flex git
sudo dnf install python3 python3-devel
sudo dnf install openmpi openmpi-devel
sudo dnf install libtirpc-devel zlib-devel
sudo dnf install perl-File-Compare

# Make Proteus profile

echo "export CC=mpicc" > $HOME/.proteus_profile
echo "export CXX=mpicxx" >> $HOME/.proteus_profile
echo "export F90=mpif90" >> $HOME/.proteus_profile
echo "export F77=mpif77" >> $HOME/.proteus_profile
echo "export FC=mpif90" >> $HOME/.proteus_profile
echo "export MOOSE_DIR="$HOME"/moose" >> $HOME/.proteus_profile
echo "export PATH=\$PATH:"$PROTEUS_DIR >> $HOME/.proteus_profile
echo "module load mpi/openmpi" >> $HOME/.proteus_profile
source $HOME/.proteus_profile

# Clone MOOSE from git

cd $HOME
git clone https://github.com/idaholab/moose.git

# Build PETSc

cd $MOOSE_DIR
unset PETSC_DIR PETSC_ARCH
./scripts/update_and_rebuild_petsc.sh \
CC=$CC CXX=$CXX F90=$F90 F77=$F77 FC=$FC \
--CXXOPTFLAGS="-O3 -march=native" \
--COPTFLAGS="-O3 -march=native" \
--FOPTFLAGS="-O3 -march=native" \
--download-mumps=0 --download-superlu_dist=0

# Build libMesh

METHODS="opt" ./scripts/update_and_rebuild_libmesh.sh --with-mpi

# Build WASP

./scripts/update_and_rebuild_wasp.sh

# Configure AD
# Derivative size should be the total of
# 8 for each first order variable
# 27 for each second order variable

./configure --with-derivative-size=81

cd $PROTEUS_DIR
make -j $MOOSE_JOBS

echo "Installation complete."
