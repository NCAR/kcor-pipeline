#!/bin/sh

rm -rf build
mkdir build
cd build

cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=~/software/kcor-pipeline \
  -DIDLdoc_DIR:PATH=~/projects/idldoc/src \
  -Dmgunit_DIR:PATH=~/projects/mgunit/src \
  ..