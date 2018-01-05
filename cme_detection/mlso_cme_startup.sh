#!/bin/sh

IDL=/usr/local/bin/idl

KCOR_CME_ROOT=$(dirname $0)
KCOR_CME_PATH=+${KCOR_CME_ROOT}:"<IDL_DEFAULT>"

SHORT_HOSTNAME=$(hostname | sed -e 's/\..*$//')
FLAGS=cme

CONFIG_FILENAME=$KCOR_ROOT/config/kcor.$(whoami).$SHORT_HOSTNAME.$FLAGS.cfg

export KCOR_MAILING_LIST=$KCOR_CME_ROOT/mailing-list

${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "kcor_cme_detection, config_filename='$CONFIG_FILENAME'"
