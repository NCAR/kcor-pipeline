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

#IDL=/home/mgalloy/bin/idl
IDL=/usr/local/idl873/idl87/bin/idl

SCRIPT_LOC=$(canonicalpath $0)
KCOR_CME_ROOT=$(dirname $SCRIPT_LOC)
KCOR_ROOT=$(dirname $KCOR_CME_ROOT)
KCOR_CME_PATH=+${KCOR_CME_ROOT}:+${KCOR_ROOT}/lib:+${KCOR_ROOT}/src:"<IDL_DEFAULT>"
KCOR_CME_DLM_PATH=+${KCOR_CME_ROOT}/lib:"<IDL_DEFAULT>"

FLAGS=cme

SCRIPT_NAME=kcor_cme_detection_job

CONFIG_FILENAME=$KCOR_ROOT/config/kcor.$FLAGS.cfg

IDL_CMD="$SCRIPT_NAME, config_filename='$CONFIG_FILENAME', /realtime"

${IDL} -IDL_PATH ${KCOR_CME_PATH} \
       -IDL_DLM_PATH ${KCOR_CME_DLM_PATH} \
       -IDL_STARTUP '' \
       -e "${IDL_CMD}"
