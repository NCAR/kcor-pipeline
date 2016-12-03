#!/bin/sh

# u=rwx,g=rwx,o=rx
umask 0002

# use today if date not passed to script
if [[ $# -eq 1 ]]; then
  DATE=$1
else
  DATE=$(date +"%Y%m%d")
fi

# find locations relative to this script
SCRIPT_LOC=$(readlink -f $0)
BIN_DIR=$(dirname ${SCRIPT_LOC})
PIPE_DIR=$(dirname ${BIN_DIR})

IDL=/opt/share/exelis/idl82/bin/idl

# setup IDL paths
SSW_DIR=${PIPE_DIR}/ssw
GEN_DIR=${PIPE_DIR}/gen
LIB_DIR=${PIPE_DIR}/lib
KCOR_SRC_DIR=${PIPE_DIR}/src
KCOR_PATH=+${KCOR_SRC_DIR}:${SSW_DIR}:${GEN_DIR}:+${LIB_DIR}:"<IDL_DEFAULT>"
KCOR_DLM_PATH={KCOR_SRCDIR}/realtime:${LIB_DIR}/mysql:"<IDL_DEFAULT>"

#CONFIG=${PIPE_DIR}/config/kcor.mgalloy.kaula.production.cfg
CONFIG=${PIPE_DIR}/config/kcor.mgalloy.mahi.latest.cfg

${IDL} -IDL_STARTUP "" -IDL_PATH ${KCOR_PATH} -IDL_DLM_PATH ${KCOR_DLM_PATH} -e "kcor_eod, '${DATE}', config_filename='${CONFIG}'"
