#!/bin/sh

if [ "$#" -ne 2 ];  then
  echo "Usage: sh $0 SOURCE BASE" >&2
  exit 1
fi

wget $1 -q -O tmp.html
BASE=`md5sum tmp.html | awk '{print $1}'`
cat tmp.html | sh escape-nonascii.sh | awk -f slor.awk -v BASE=$BASE -v SOURCE=$1 | sh unescape-nonascii.sh
rm tmp.html
