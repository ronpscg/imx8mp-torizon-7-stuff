#!/bin/bash
# The idea of this script is to the build the $BUILD_PRODUCT_NAME bundle, so that you don't have to build and get it from Docker-In-Docker et. al. This saves significant time in preparing the image
# As far s you are concerned, the bundle is everything related to the containers.
#
if [ -z "$CR_PAT" ] ; then
	echo "Please provide your Github token in CR_PAT environment variable"
	exit 1
fi

# Note: torizoncore-builder works ONLY within the same directory. So all paths must be relative to the BUILD_ROOT path, and the working directory must be BUILD_ROOT
: ${BUILD_ROOT=$(dirname $(readlink -f $0))/../}
: ${BUILD_VENDOR_NAME=example-vendor}
: ${BUILD_PRODUCT_NAME=exampleproduct}
: ${BUILD_CACHES_DIR=caches_dir}
: ${BUNDLE_NAME=bundle-$BUILD_PRODUCT_NAME}
: ${BUNDLE_DIR=$BUILD_CACHES_DIR/$BUNDLE_NAME}
: ${CONTAINER_REGISTRY="ghcr.io/ronpscg"}
: ${CONTAINER_REGISTRY_USERNAME=ronpscg}
: ${CONTAINER_REGISTRY_PASSWORD=$CR_PAT}
: ${DOCKER_COMPOSE_FILE=${BUILD_VENDOR_NAME}/containers/docker-compose/docker-compose.${BUILD_PRODUCT_NAME}.yml}

cd $BUILD_ROOT || { echo "Cannot cd to $BUILD_ROOT" ; exit 1 ; }

if [ ! -d "$BUILD_CACHES_DIR" ] ; then
	mkdir $BUILD_CACHES_DIR || { echo "Cannot create $BUILD_CACHES_DIR" ; exit 1; }
fi

shopt -s expand_aliases
. tcb-env-setup.sh -a local
torizoncore-builder bundle --platform linux/arm64 --bundle-directory $BUNDLE_DIR --login-to $CONTAINER_REGISTRY $CONTAINER_REGISTRY_USERNAME $CONTAINER_REGISTRY_PASSWORD $DOCKER_COMPOSE_FILE
[ $? -ne 0 ] && { echo -e "\x1b[31mBundle creation failed\x1b[0m" ; exit 1 ; }

exit 0
