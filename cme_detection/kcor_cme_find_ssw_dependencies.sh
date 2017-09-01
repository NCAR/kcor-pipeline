#!/bin/sh

IDL=idl85

SSW_DIR=${PWD}/ssw
KCOR_SRC_DIR=${PWD}

FULL_SSW_DIR=/hao/contrib/ssw

KCOR_PATH=+${KCOR_SRC_DIR}:${SSW_DIR}:"<IDL_DEFAULT>"
SSW_DEP_PATH="<IDL_DEFAULT>":${KCOR_PATH}:+${FULL_SSW_DIR}

echo "Find ROUTINES..."
find . -name 'kcor_*.pro' -exec basename {} .pro \; > ROUTINES

echo "Starting IDL..."
${IDL} -IDL_STARTUP "" -IDL_PATH ${SSW_DEP_PATH} -e "kcor_cme_find_ssw_dependencies, '${FULL_SSW_DIR}'" 

# 2> /dev/null
