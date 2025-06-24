#!/bin/bash
# This file replaces marketing assets
# 
# Copyright Ron Munitz, 2025
#

# $1 - folder with png images
# $2 - assets folder to replace

set -euo pipefail

src=$(readlink -f $1)
dst=$(readlink -f $2)
tmpdir=$(mktemp -d)
workdir=$tmpdir/slides_vga

mkdir $workdir
cp -a $src/*.png $workdir/
( cd $workdir && tar cf $dst/marketing.tar ../)

rm -rf $tmpdir



