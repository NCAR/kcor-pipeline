#!/bin/sh

rm -rf build
mkdir build
cd build

~mgalloy/software/bin/cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=~/software/kcor-pipeline \
  -DIDL_ROOT_DIR:PATH=/opt/share/idl8.5/idl85 \
  -DIDLdoc_DIR:PATH=~/projects/idldoc \
  -Dmgunit_DIR:PATH=~/projects/mgunit/src \
  ..
