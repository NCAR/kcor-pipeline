#!/bin/sh

# Checks the automated, real-time CME detection process and restarts it if it
# is not running.

pid=$(pgrep -u mgalloy -f 'kcor_cme_detection_job.*/realtime')
if [ $? -eq 1 ]; then
  # status=1 if automated, real-time CME detection is not running

  # restart process
  script=$(dirname $0)/kcor_realtime_cme.sh
  $script

  # send notification that process wasn't running and restarting it
  body="Restarted $script\n\nSent from $0 ($(whoami)@$(hostname))"
  addresses=mgalloy@ucar.edu
  echo -e $body | mail -s "Restarting automated, real-time CME detection process" \
                    -r $(whoami)@ucar.edu \
                    $addresses
fi
