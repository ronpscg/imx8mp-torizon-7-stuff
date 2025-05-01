#!/bin/bash
#
# This is a quick and simple wrapper to TCB. It is absolutely not robust, not meant to be, and I will finish writing this file in 2 minutes top (in vim, and without LLM's. Heh!)
# Here goes
#
# OK it took 5. TCB asks the user to update if it is different than what is upstream, so I used a copy. The reason for modifying it in the first place is that 
# TCB cannot work from inside a script
#

if [ "$#" -lt "1" ] ; then
	echo "Please provide your output directory as a parameter"
	exit 1
fi

outdir=$1
if [ -d $outdir ] ; then
	echo "Please provide a nonexisting output directory ($outdir)"
	exit 1
fi

if grep -q "local: output_directory" tcbuild.yaml ; then
	sed -i "s|local: output_directory|local: $outdir|" tcbuild.yaml
else
	echo -e "\x1b[33mYou probably already modified the tcbuild.yaml file so we assume you know what you are doing. You are welcome to modify this script and parse the output: local: <...> section and \"sed\" it yourself\x1b[0m"
	exit 1
fi

shopt -s expand_aliases
. tcb-env-setup.sh -a local # May ask you to update your dockers, so you may want to first source tcv-env-setup.sh from out of this, or use -a remote (or -t <something>...)


echo -e "\x1b[32mStarting to build...\x1b[0m"

if torizoncore-builder build ; then
	echo -e "\x1b[32mBuild succeeded.\x1b[0m"

	echo "Updating image with assets..."
	if ! ./update-image-with-assets.sh assets $outdir ; then
		echo -e "\x1b[33mCopying failed, and that is weird. But you can live with the default assets... At least while developing...\x1b[0m"
	fi

	echo
	echo "You may copy $outdir to your relevant server or installation media"
	echo -e "You may also update  image_list.json and run \x1b[34mtorizoncore-builder images serve .\x1b[0m after sourcing tcb-env-setup.sh"

	if [ "$TCB_SERVE_IMAGE" = "true" ] ; then
		torizoncore-builder images serve .
	fi
else
	echo -e "\x1b[31mBuild Failed.\x1b[0m"
	exit 1
fi
