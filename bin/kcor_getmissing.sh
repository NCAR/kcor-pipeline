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

if [[ $# -lt 2 ]]; then
  echo "missing arguments, syntax: kcor_getmissing.sh [LOG_FILENMAE] [LEVEL0_DIR]"
  exit 1
fi

LOG_FILENAME=${1}
LEVEL0_DIR=$(canonicalpath ${2})

DEST_DIR=$(dirname ${LEVEL0_DIR})

SERVER=kodiak.mlso.ucar.edu
SERVER_DIR=/data/kcor
DATE=$(basename ${LOG_FILENAME} | head -c 8)

TMP_FILENAME=$(mktemp)

# get a sorted list of level 0 files
LEVEL0_FILES=($(find ${LEVEL0_DIR} -name '*_kcor.fts*'))
IFS=$'\n' SORTED_LEVEL0_FILES=($(sort <<<"${LEVEL0_FILES[*]}"))
unset IFS

# create a machine log alternative of what actually arrived
for f in "${SORTED_LEVEL0_FILES[@]}"; do
  echo "$(basename $f .gz)  16782980" >> ${TMP_FILENAME}
done

# find the difference between the machine log and what actually arrived
DIFF=$(diff -b ${TMP_FILENAME} ${LOG_FILENAME})

# go through differences line by line
readarray -t diff_lines <<<"$DIFF"
for line in "${diff_lines[@]}"; do
  if echo "${line}" | grep --quiet "_kcor.fts"; then
    read -a tokens <<< "$line"
    cmd="scp ${SERVER}:${SERVER_DIR}/${DATE}/${tokens[1]} ${DEST_DIR}"
    $cmd
  fi
done

rm ${TMP_FILENAME}

