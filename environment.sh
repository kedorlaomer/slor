#!/bin/sh

rm -Rf bin
mkdir bin
./busybox --install -s bin
cp ~/bin/curl bin
export PATH="`pwd`/bin"
./bin/sh
