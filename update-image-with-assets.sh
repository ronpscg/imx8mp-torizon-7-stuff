#!/bin/bash
# $1 / src- assets dir
# $2 / dst- image dir
#
# Note the defaults
#
# Ron Munitz, Apr 30th 2025
#

case $# in
	2)
		: ${src=${1-assets}}
		: ${dst=$2}
		;;
	1)
		: ${dst=$1}
		;&
	0)
		: ${src=assets}
		;;
	*)
		echo "Please either provide 0-2 arguments and/or populate the src and dst environment variables"
		exit 1
		;;
esac

if [ ! -d "$src" ] ; then
	echo "please provide an existing src dir ($src)"
	exit 1
fi
if [ ! -d "$dst" ] ; then
	echo "please provide an existing dst dir ($dst)"
	exit 1
fi

if [ "$(readlink -f $src)" = "$(readlink -f $dst)" ] ; then
	echo "src and dst are equal. Pleae provide other directories"
	exit 1
fi


files="marketing.tar toradexlinux.png"
for file in $files ; do
	cp -v $src/$file $dst/$file
done
