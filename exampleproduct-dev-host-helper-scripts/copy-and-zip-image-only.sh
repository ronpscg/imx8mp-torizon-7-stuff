#!/bin/bash
# This is an example for copying and zipping an image, naming it based on the product
# It 
# - takes output_directory from the TCB folder and
# - copies it elsewhere (to allow continuing using it easily with the rest of the script)
# - zips it with the same file (so instructions are always the same and remain as documented in the detailed instructions I provided)
# - [uploads it to google drive] [onl

# Note: torizoncore-builder works ONLY within the same directory. So all paths must be relative to the BUILD_ROOT path, and the working directory must be BUILD_ROOT
: ${BUILD_ROOT=$(dirname $(readlink -f $0))/../}
: ${BUILD_VENDOR_NAME=example-vendor}
: ${BUILD_PRODUCT_NAME=exampleproduct}
: ${OUT_ZIPPED_ARTIFACTS_BASE_DIR=out-zipped-artifacts} # Zipped to allow easy flashing/observing in windows

cd $BUILD_ROOT || { echo "Cannot cd to $BUILD_ROOT" ; exit 1 ; }

export TCBUILD_YAML=${BUILD_VENDOR_NAME}/tcbuild-templates/${BUILD_PRODUCT_NAME}.yaml
if [ ! -f $TCBUILD_YAML ] ; then
	echo "Please make sure $TCBUILD_YAML exists"
	echo -e "\x1b[33mPlease provide set the BUILD_PRODUCT_NAME environment variable to one of the following values prior to running this script:\x1b[0m\n$(for f in $(ls -1 ${BUILD_VENDOR_NAME}/tcbuild-templates/) ; do echo ${f%.*} ; done)"
	exit 1
fi

NEWNAME=$(date "+%Y-%m-%d-%H%M-$BUILD_PRODUCT_NAME")
echo "Preparing $NEWNAME..."
DIR=$OUT_ZIPPED_ARTIFACTS_BASE_DIR/$NEWNAME
if [ -e $DIR ] ; then
	echo "$DIR exists. exitting"
	exit 1
fi
mkdir -p $DIR
zip -r $DIR/$NEWNAME.zip output_directory
if [ $? = 0 ] ; then
	echo "OK."
else
	echo "KO"
fi


