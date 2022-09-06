#!/bin/bash
outfile=$1
shift 1
echo $outfile
export PATH=$PATH:/Library/TeX/texbin
echo "pdfjoin --outfile $outfile \"$@\" 2>/dev/null"

pdfjoin --outfile $outfile "$@" 2>/dev/null
open -a Preview $outfile
