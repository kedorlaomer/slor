#!/bin/sh

hexdump -vC | sed 's/|.*|//' | awk -f do-escape.awk | hexdump -R
