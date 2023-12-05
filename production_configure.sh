#!/bin/sh

rm -rf build
mkdir build
cd build

#IDL_ROOT_DIR=/opt/share/idl8.6/idl86
IDL_ROOT_DIR=/opt/share/idl8.7.3/idl87

cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=/hao/acos/sw/pipeline/kcor-pipeline \
  -DCONFIG_DIR:PATH=/hao/acos/sw/src/kcor-config \
  -DIDL_ROOT_DIR:PATH=${IDL_ROOT_DIR} \
  -DIDLdoc_DIR:PATH=~/projects/idldoc \
  -Dmgunit_DIR:PATH=~/projects/mgunit/src \
  ..
