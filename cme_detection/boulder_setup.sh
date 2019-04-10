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
MGLIB_ROOT=/home/mgalloy/software/mglib/lib
KCOR_CME_PATH=+${KCOR_CME_ROOT}:+${KCOR_ROOT}/lib:+${KCOR_ROOT}/src:+${MGLIB_ROOT}:"<IDL_DEFAULT>"
SHORT_HOSTNAME=$(hostname | sed -e 's/\..*$//')
FLAGS=cme

CONFIG_FILENAME=$KCOR_ROOT/config/kcor.$FLAGS.cfg

#echo $KCOR_CME_PATH
#echo $CONFIG_FILENAME


# start up IDL with correct environment variables for Boulder servers
#${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP ''
#exit

# run example days interactively
#${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "kcor_cme_detection, '2017-08-20', timerange='2017-08-20 ' + ['19:15', '21:00'], config_filename='$CONFIG_FILENAME'"
#${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "kcor_cme_detection, '2017-08-17', timerange='2017-08-17 ' + ['20:30', '23:15'], config_filename='$CONFIG_FILENAME'"

#${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "kcor_cme_detection, '2017-04-02', config_filename='$CONFIG_FILENAME'"

# run example days as a job
#${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "kcor_cme_detection_job, '2017-08-20', timerange='2017-08-20 ' + ['19:15', '21:00'], config_filename='$CONFIG_FILENAME'"
#${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "kcor_cme_detection_job, '2017-08-17', timerange='2017-08-17 ' + ['20:30', '23:15'], config_filename='$CONFIG_FILENAME'"


# run a range of days as a job
date='20180907'
end_date='20180908'
while [ $date != $end_date ]; do
  echo "processing $date..."
  ${IDL} -IDL_PATH ${KCOR_CME_PATH} -IDL_STARTUP '' -e "kcor_cme_detection_job, '$date', config_filename='$CONFIG_FILENAME'"
  date=$(date +"%Y%m%d" -d "$date +1 day")
done
