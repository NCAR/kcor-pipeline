#!/bin/sh

PROCESS_DIR=/hao/kaula1/Data/KCor/process

# start of mission
./kcor cal -f reprocess 20130930-20190612

# 20190612 had 2 valid sets of calibration data that are not compatible with
# each other -- one has NUMSUM=171, the other had the normal NUMSUM=512.
./kcor cal -f reprocess -l ${PROCESS_DIR}/20190612/cals-1.txt 20190612
./kcor cal -f reprocess -l ${PROCESS_DIR}/20190612/cals-2.txt 20190612

# TODO: adjust end date as needed
./kcor cal -f reprocess 20190613-20191201
