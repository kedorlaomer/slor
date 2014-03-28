#!/bin/sh

if [ "$#" -ne 1 ];  then
  echo "Usage: sh $0 <http or ftp URL>" >&2
  exit 1
fi

wget $1 -O tmp.html
BASE=`md5sum tmp.html | awk '{print $1}'`
cat tmp.html | awk -f slor.awk -v BASE=$BASE -v SOURCE=$1 > $BASE.html
rm tmp.html
