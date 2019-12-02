#!/bin/sh

IDL=idl85

SSW_DIR=${PWD}/ssw
GEN_DIR=${PWD}/gen
LIB_DIR=${PWD}/lib
KCOR_SRC_DIR=${PWD}/src
KCOR_PATH=+${KCOR_SRC_DIR}:${SSW_DIR}:${GEN_DIR}:+${LIB_DIR}:"<IDL_DEFAULT>"

FULL_SSW_DIR=/hao/contrib/ssw

SSW_DEP_PATH="<IDL_DEFAULT>":${KCOR_PATH}:+${FULL_SSW_DIR}

echo "Find ROUTINES..."
find src -name '*.pro' -exec basename {} .pro \; > ROUTINES
find gen -name '*.pro' -exec basename {} .pro \; >> ROUTINES
find lib -name '*.pro' -exec basename {} .pro \; >> ROUTINES

echo "Starting IDL..."
${IDL} -IDL_STARTUP "" -IDL_PATH ${SSW_DEP_PATH} -e "kcor_find_ssw_dependencies, '${FULL_SSW_DIR}'" 2> /dev/null
