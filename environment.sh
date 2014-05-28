#!/bin/sh

rm -Rf bin
mkdir bin
./busybox --install -s bin
cp `which curl` bin
export PATH="`pwd`/bin"
./bin/sh
