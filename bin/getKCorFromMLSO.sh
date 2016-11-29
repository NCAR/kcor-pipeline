#!/bin/bash

umask 0002

# Extract elements of the filename
filename=$1

date=${filename:0:8}
time=${filename:9:6}
inst=${filename:16:4}

if [ $time -lt 060000 ]
then
	#date=$((date - 1))
	DOY=`date -d "$date" +%j`
	DOY=$((DOY - 1))
	year=${date:0:4}
	date=`date -d "$year-01-01 +$DOY days -1 day" "+%Y%m%d"`
fi

# Destination is the raw file directory
cd /hao/mlsodata1/Data/KCor/raw/$date

# Copy the file from ldm's account
# Requires ssh keys for unattended operation
scp ldm@mlsoserver.mlso.ucar.edu:/data/kcor/$date/$filename .
