#!/bin/sh

REMOTE_SERVER=$1
REMOTE_PATH=/export/data1/Data/KCor/raw
if [[ $# -lt 2 ]]; then
  DATE=$(date +"%Y%m%d")
else
  DATE=$2
fi

LOCAL_PATH=/export/data1/Data/KCor/cme-alerts

# copy the following files to LOCAL_PATH:
#   raw/YYYYMMDD/p/YYYYMMDD.HHMMSS.cme.profile.png
#   raw/YYYYMMDD/p/YYYYMMDD.HHMMSS.cme.plot.png
#   raw/YYYYMMDD/p/YYYYMMDD.HHMMSS.cme.plot.csv

# create directory to copy to and copy into it
mkdir -p ${LOCAL_PATH}/${DATE}
scp -rq ${REMOTE_SERVER}.mlso.ucar.edu:${REMOTE_PATH}/${DATE}/p/*cme* ${LOCAL_PATH}/${DATE}

# remove directory if nothing was copied
find ${LOCAL_PATH} -maxdepth 1 -empty -exec rmdir {} \;
