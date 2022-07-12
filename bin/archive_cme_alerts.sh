#!/bin/sh

SCRIPT_DIR=$(dirname $0)

REMOTE_SERVER=$1
REMOTE_PATH=/export/data1/Data/KCor/raw
if [[ $# -lt 2 ]]; then
  DATE=$(date +"%Y%m%d")
else
  DATE=$2
fi

LOCAL_PATH=/export/data1/Data/KCor/cme-alerts
SSH_KEY=${HOME}/.ssh/id_rsa2

# copy the following files to LOCAL_PATH:
#   raw/YYYYMMDD/p/YYYYMMDD.HHMMSS.cme.profile.png
#   raw/YYYYMMDD/p/YYYYMMDD.HHMMSS.cme.plot.png
#   raw/YYYYMMDD/p/YYYYMMDD.HHMMSS.cme.plot.csv

# create directory to copy to and copy into it
mkdir -p ${LOCAL_PATH}/${DATE}
cmd="scp -rqp -i ${SSH_KEY} ${REMOTE_SERVER}.mlso.ucar.edu:${REMOTE_PATH}/${DATE}/p/*cme* ${LOCAL_PATH}/${DATE}"
$cmd


REMOTE_PATH=/export/data1/Data/KCor/cme-alerts
YEAR=${DATE:0:4}
MONTH=${DATE:4:2}
DAY=${DATE:6:2}

# copy all files of the following form to the LOCAL_PATH:
#   cme-alerts/YYYY/MM/DD/mlso_kcor.2017-10-06T172637Z.2017-10-06T173105Z.json
cmd="scp -qp -i ${SSH_KEY} ${REMOTE_SERVER}.mlso.ucar.edu:${REMOTE_PATH}/${YEAR}/${MONTH}/${DAY}/*.json ${LOCAL_PATH}/${DATE}"
$cmd

${SCRIPT_DIR}/kcor_add_events ${LOCAL_PATH}/${DATE}

# remove directory if nothing was copied
find ${LOCAL_PATH} -maxdepth 1 -empty -exec rmdir {} \;
