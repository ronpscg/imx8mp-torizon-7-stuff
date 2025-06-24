#!/bin/bash
#
# This is a quick and simple wrapper to TCB. It is absolutely not robust, not meant to be, and I will finish writing this file in 2 minutes top (in vim, and without LLM's. Heh!)
# Here goes
#
# OK it took 5. TCB asks the user to update if it is different than what is upstream, so I used a copy. The reason for modifying it in the first place is that 
# TCB cannot work from inside a script
#
# Usage:
# $1 is the output directory. 
# TCBUILD_YAML is an environment variable that should point to your respective tcbuild.yaml file. It can have any name of your choice.
# It is recommended to start from a template, copy it over, and not checkin the file you work on to source control
#
# The file is *deliberately* not too robust to keep it short and sweet, and the only real change is modifying the output directory.
# It's easiest to just keep the outputd directory as output_directory , and move out the target folders, as it lines up nicely and at this point I don't 
# want to work on further scripts. The documentation is good enough.
#

# No choice but to source it *outside* of a function, or the aliases will not be recognized
shopt -s expand_aliases
. tcb-env-setup.sh -a local # May ask you to update your dockers, so you may want to first source tcv-env-setup.sh from out of this, or use -a remote (or -t <something>...)


: ${TCBUILD_YAML=tcbuild.yaml}
: ${STATUS_UPDATE_FIFO=/tmp/tcb-status-update.fifo} # Send updates such as built|building|serving|failed so that a calling script can, e.g. start TEZI upon completion

init_fifo() {	
	if [ ! -p "$STATUS_UPDATE_FIFO" ] ; then
		if [ -e "$STATUS_UPDATE_FIFO" ] ; then
			echo "Please remove $STATUS_UPDATE_FIFO as it is not a fifo"
			exit 1
		fi
		mkfifo "$STATUS_UPDATE_FIFO" || { echo "Cannot create $STATUS_UPDATE_FIFO" ; exit 1 ; }
	fi
}

update_status() {
	if [ -p "$STATUS_UPDATE_FIFO" ] ; then
		echo "$1" > "$STATUS_UPDATE_FIFO" &
	fi
}

main() {
	if [ ! -f $TCBUILD_YAML ] ; then
		echo "Please make sure $TCBUILD_YAML exist, or provide the desired file in the TCBUILD_YAML environment variable"
		exit 1
	fi

	if [ "$#" -lt "1" ] ; then
		echo "Please provide your output directory as a parameter"
		exit 1
	fi

	outdir=$1
	if [ -d $outdir ] ; then
		echo "Please provide a nonexisting output directory ($outdir)"
		exit 1
	fi

	if grep -q "local: output_directory" $TCBUILD_YAML ; then
		sed -i "s|local: output_directory|local: $outdir|" $TCBUILD_YAML
	else
		echo -e "\x1b[33mYou probably already modified the tcbuild.yaml file at $TCBUILD_YAML so we assume you know what you are doing. You are welcome to modify this script and parse the output: local: <...> section and \"sed\" it yourself\x1b[0m"
		exit 1
	fi
	
	init_fifo
	update_status "building"

	echo -e "\x1b[32mStarting to build...\x1b[0m"

	if torizoncore-builder build --file ${TCBUILD_YAML} ; then
		echo -e "\x1b[32mBuild succeeded.\x1b[0m"

		echo "Updating image with assets..."
		if ! ./update-image-with-assets.sh assets $outdir ; then
			echo -e "\x1b[33mCopying failed, and that is weird. But you can live with the default assets... At least while developing...\x1b[0m"
		fi

		echo
		echo "You may copy $outdir to your relevant server or installation media"
		echo -e "You may also update  image_list.json and run \x1b[34mtorizoncore-builder images serve .\x1b[0m after sourcing tcb-env-setup.sh"

		update_status "built"
		if [ "$TCB_SERVE_IMAGE" = "true" ] ; then
			update_status "serving"
			torizoncore-builder images serve .
		fi
	else
		echo -e "\x1b[31mBuild Failed.\x1b[0m"
		update_status "failed"
		exit 1
	fi
}

main $@