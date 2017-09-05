#!/bin/sh

export KCOR_DIR=/export/data1/Data/KCor/archive
export KCOR_HPR_DIR=/export/data1/Data/KCor/hpr
export KCOR_HPR_DIFF_DIR=/export/data1/Data/KCor/hpr_diff
export KCOR_MOVIE_DIR=/export/data1/Data/KCor/cme_movies

IDL=/usr/local/bin/idl

KCOR_CME_ROOT=$(dirname $0)
KCOR_CME_PATH=+${KCOR_CME_ROOT}:"<IDL_DEFAULT>"

export KCOR_MAILING_LIST=$KCOR_CME_ROOT/mailing-list

${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e kcor_cme_detection
