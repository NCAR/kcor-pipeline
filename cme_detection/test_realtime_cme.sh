#!/bin/sh

canonicalpath() {
  if [ -d $1 ]; then
    pushd $1 > /dev/null 2>&1
    echo $PWD
  elif [ -f $1 ]; then
    pushd $(dirname $1) > /dev/null 2>&1
    echo $PWD/$(basename $1)
  else
    echo "Invalid path $1"
  fi
  popd > /dev/null 2>&1
}

IDL=/home/mgalloy/bin/idl

SCRIPT_LOC=$(canonicalpath $0)
KCOR_CME_ROOT=$(dirname $SCRIPT_LOC)
KCOR_ROOT=$(dirname $KCOR_CME_ROOT)
KCOR_CME_PATH=+${KCOR_CME_ROOT}:+${KCOR_ROOT}/lib:+${KCOR_ROOT}/src:"<IDL_DEFAULT>"
SHORT_HOSTNAME=$(hostname | sed -e 's/\..*$//')

# TODO: change to cme when put into production
FLAGS=cmetest

SCRIPT_NAME=kcor_cme_detection_job

CONFIG_FILENAME=$KCOR_ROOT/config/kcor.$(whoami).$SHORT_HOSTNAME.$FLAGS.cfg
TEST_DATE=20171122

IDL_CMD="$SCRIPT_NAME, '$TEST_DATE', config_filename='$CONFIG_FILENAME', /realtime"
${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "${IDL_CMD}"
