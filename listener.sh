#!/bin/sh

while true; do
    read url
    if [ -e multiplier.sh ]; then
        for i in `sh multiplier.sh $url`; do
            sh wrapper.sh $i
        done
    else
        sh wrapper.sh $url
    fi
done;
