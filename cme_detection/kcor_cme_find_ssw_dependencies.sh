#!/bin/sh

IDL=idl

FULL_SSW_DIR=/hao/ssw

KCOR_CME_ROOT=${PWD}
SSW_DIR=${KCOR_CME_ROOT}/ssw
KCOR_ROOT=$(dirname $KCOR_CME_ROOT)
KCOR_CME_PATH=+${KCOR_CME_ROOT}:+${KCOR_ROOT}/gen:+${KCOR_ROOT}/lib:+${KCOR_ROOT}/src:"<IDL_DEFAULT>"
KCOR_CME_DLM_PATH=+${KCOR_ROOT}/lib:"<IDL_DEFAULT>"

SSW_DEP_PATH="<IDL_DEFAULT>":${KCOR_CME_PATH}:+${FULL_SSW_DIR}

echo "Find ROUTINES..."
find . -name 'kcor_*.pro' -exec basename {} .pro \; > ROUTINES

echo "Starting IDL..."
${IDL} -IDL_STARTUP "" -IDL_PATH ${SSW_DEP_PATH} -e "kcor_cme_find_ssw_dependencies, '${FULL_SSW_DIR}'" 

# 2> /dev/null
