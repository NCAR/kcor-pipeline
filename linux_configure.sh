#!/bin/sh

rm -rf build
mkdir build
cd build

# on mahi
IDL_ROOT_DIR=/opt/share/idl8.7.3/idl87

# on kodiak
#IDL_ROOT_DIR=/usr/local/idl873/idl87

~mgalloy/software/bin/cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=~/software/kcor-pipeline \
  -DCONFIG_DIR:PATH=/home/mgalloy/projects/kcor-config \
  -DIDL_ROOT_DIR:PATH=${IDL_ROOT_DIR} \
  -DIDLdoc_DIR:PATH=~/projects/idldoc \
  -Dmgunit_DIR:PATH=~/projects/mgunit/src \
  ..
