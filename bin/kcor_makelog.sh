#!/bin/sh

DATA_PATH=$1

FILES=$(find ${DATA_PATH} -name '*.fts.gz')
for f in ${FILES}; do
  s=$(gunzip -l $f)  
  read -ra arr -d '' <<< "$s"
  file=$(basename $f .gz)
  echo "$file ${arr[5]}"
done
