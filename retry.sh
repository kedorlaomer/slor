#!/bin/sh

if [ ! -e error.log ]; then
	exit
fi

mv error.log error.old

for url in `cat error.old`; do
        sh wrapper.sh $url
done;

#sh listener.sh
