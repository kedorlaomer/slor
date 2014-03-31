#!/bin/sh

if [ "$#" -ne 1 ];  then
  echo "Usage: sh $0 <http or ftp URL>" >&2
  exit 1
fi

curl -gk -o tmp.html $1
BASE=`md5sum tmp.html | awk '{print $1}'`
rm -r $BASE 2> /dev/null
mkdir $BASE
cat tmp.html | awk -f slor.awk -v BASE=$BASE -v SOURCE=$1 > $BASE/$BASE.html
rm tmp.html
