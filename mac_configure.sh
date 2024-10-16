#!/bin/sh

rm -rf build
mkdir build
cd build
#IDL_ROOT_DIR=/Applications/harris/idl89
IDL_ROOT_DIR=/Applications/NV5/idl90

cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=~/software/kcor-pipeline \
  -DIDL_ROOT_DIR:PATH=${IDL_ROOT_DIR} \
  -DIDLdoc_DIR:PATH=~/projects/idldoc \
  -Dmgunit_DIR:PATH=~/projects/mgunit/src \
  ..
