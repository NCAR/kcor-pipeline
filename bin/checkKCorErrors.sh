#!/bin/bash

umask 0002

# Check YESTERDAY's daily KCor log file for errors

echo "Checking KCor logs"

output="/tmp/KCor-$$"

logName=/hao/acos/sw/var/log/KCor/cidx/KCor-`date +%F --date="yesterday"`.log

echo "INVALID messages" >> $output 2>&1
fgrep INVALID  $logName >> $output 2>&1
echo "" >> $output 2>&1

echo "SEVERE messages" >> $output 2>&1
fgrep SEVERE  $logName >> $output 2>&1
echo "" >> $output 2>&1

echo "WARNING messages" >> $output 2>&1
fgrep WARNING $logName >> $output 2>&1
echo "" >> $output 2>&1

# Check for HPSS errors

logName=/hao/acos/sw/var/log/KCor/cidx/HPSSGateway-KCor-`date +%F --date="yesterday"`.log
#recipient="sitongia kolinski iguana detoma lmayer"
recipient="iguana@ucar.edu,  detoma@ucar.edu, stanger@ucar.edu"

echo "HPSS messages" >> $output 2>&1
fgrep FAILED $logName >> $output 2>&1
echo "" >> $output 2>&1

# Check for LDM errors, since KCor realtime runs from it

echo "Recent LDM messages" >> $output 2>&1
fgrep ERROR /home/ldm/logs/ldmd.log | fgrep KCor | tail -5 >> $output 2>&1
echo "" >> $output 2>&1

mail -s "KCor messages from yesterday's logs" "$recipient" < $output

rm $output

