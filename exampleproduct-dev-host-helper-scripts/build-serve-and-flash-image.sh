#!/bin/bash
# This is an example for a complete rebuild of a particular output_directory artifacts folder wrapping build-me.sh

# Note: torizoncore-builder works ONLY within the same directory. So all paths must be relative to the BUILD_ROOT path, and the working directory must be BUILD_ROOT
: ${BUILD_ROOT=$(dirname $(readlink -f $0))/../}
: ${BUILD_VENDOR_NAME=example-vendor}
: ${BUILD_PRODUCT_NAME=exampleproduct}
: ${BUILD_CACHES_DIR=caches_dir}
: ${BUNDLE_NAME=bundle-$BUILD_PRODUCT_NAME}
: ${BUNDLE_DIR=$BUILD_CACHES_DIR/$BUNDLE_NAME}
: ${TEZI_DIR=/tmp/toradex-easy-installer}
: ${STATUS_UPDATE_FIFO=/tmp/tcb-status-update.fifo} # Send updates such as built|building|serving|failed so that a calling script can, e.g. start TEZI upon completion
: ${BUILD_BUNDLE=false} # Set to true if you want to build a bundle first, and then build-me.sh on the output_directory within the bundle

export TCB_SERVE_IMAGE=true
export TCBUILD_YAML=${BUILD_VENDOR_NAME}/tcbuild-templates/${BUILD_PRODUCT_NAME}.yaml

init_fifo() {
	sudo rm -rf $STATUS_UPDATE_FIFO # cleanup any previous remainders, this script is meant to own the fifo
	if [ ! -p "$STATUS_UPDATE_FIFO" ] ; then
		if [ -e "$STATUS_UPDATE_FIFO" ] ; then
			echo "Please remove $STATUS_UPDATE_FIFO as it is not a fifo"
			exit 1
		fi
		mkfifo "$STATUS_UPDATE_FIFO" || { echo "Cannot create $STATUS_UPDATE_FIFO" ; exit 1 ; }
	fi
}

wait_for_image_serving() {
	while read -r line < "$STATUS_UPDATE_FIFO"; do
		echo "DEBUG: line=_${line}_"
		[ "$line" = "serving" ] && break
		[ "$line" = "failed" ] && { echo -e "\x1b[41mBuild failed\x1b[0m" ; exit 1 ; }
	done	
}

flash_tezi() (
	sudo killall uuu # get rid of previous instances, which may happen since this runs on the background
	init_fifo
	# wait for the image to build before proceeding, to keep the output nicer	
	wait_for_image_serving 
		
	if [ ! -x "$TEZI_DIR/recovery-linux.sh" ] ; then
		echo "Please make sure you have $TEZI_DIR populated as necessary, and that recovery-linux.sh is executable"
		exit 1
	fi

	cd $TEZI_DIR && ./recovery-linux.sh
)

main() {
	cd $BUILD_ROOT || { echo "Cannot cd to $BUILD_ROOT" ; exit 1 ; }

	if [ -d output_directory ] ; then
		echo "Please make sure that output_directory does not exist. This is a good time for you to back it up, or simply delete it if you don't care about its previous version"
		exit 1
	fi
	
	if [ ! -f $TCBUILD_YAML ] ; then
		echo -e "\x1b[31mPlease make sure $TCBUILD_YAML exists\x1b[0m"
		echo -e "\x1b[33mPlease provide set the BUILD_PRODUCT_NAME environment variable to one of the following values prior to running this script:\x1b[0m\n$(for f in $(ls -1 ${BUILD_VENDOR_NAME}/tcbuild-templates/) ; do echo ${f%.*} ; done)"
		exit 1
	fi

	# torizoncore-builder must be run with a tty - and running it in the background makes it complain. So we run flash_tezi on the background
	# and build-me on the foreground	
	flash_tezi | tee flash_tezi.log &
	if [ "$BUILD_BUNDLE" = "true" ] ; then
		if [ -d "$BUNDLE_DIR" ] ; then
			echo -e "\x1b[31mPlease make sure that $BUNDLE_DIR does not exist. This is a good time for you to back it up, or simply delete it if you don't care about its previous version\x1b[0m"
			exit 1
		fi
		./exampleproduct-dev-host-helper-scripts/build-example-bundle.sh && ./build-me.sh output_directory  | tee build-me.log
	else
		./build-me.sh output_directory  | tee build-me.log
	fi		
}

main $@