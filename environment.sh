#!/bin/sh

rm -Rf bin
mkdir bin
./busybox --install -s bin
export PATH="`pwd`/bin"
./bin/sh
