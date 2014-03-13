#!/bin/sh

hexdump -vC | sed 's/|.*|//' | sed 's/[a-f0-9]\+//' | \
awk 'BEGIN {FS = "";} { printf "%s", $0; }' | awk -f do-unescape.awk | hexdump -R
