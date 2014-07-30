#!/bin/sh

if [ "$#" -ne 1 ];  then
  echo "Usage: sh $0 <http or ftp URL>" >&2
  exit 1
fi

curl -A 'Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0' --compressed -gvLk -o tmp.html $1 || echo $1 >> error.log
BASE=`md5sum tmp.html | awk '{print $1}'`
rm -r $BASE 2> /dev/null
mkdir $BASE
echo $1 > $BASE/url.txt
cat tmp.html | awk -f slor.awk -v BASE=$BASE -v SOURCE=$1 > $BASE/$BASE.html
rm tmp.html
