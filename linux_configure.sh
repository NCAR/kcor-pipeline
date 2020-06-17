#!/bin/sh

rm -rf build
mkdir build
cd build

IDL_ROOT_DIR=/opt/share/idl8.6/idl86
#IDL_ROOT_DIR=/opt/share/idl8.7.3/idl87

~mgalloy/software/bin/cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=~/software/kcor-pipeline \
  -DIDL_ROOT_DIR:PATH=${IDL_ROOT_DIR} \
  -DIDLdoc_DIR:PATH=~/projects/idldoc \
  -Dmgunit_DIR:PATH=~/projects/mgunit/src \
  ..
