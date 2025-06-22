#!/bin/bash
shopt -s expand_aliases # important for tcb-env-setup.sh
. tcb-env-setup.sh -a local # May ask you to update your dockers, so you may want to first source tcv-env-setup.sh from out of this, or use -a remote (or -t <something>...)
torizoncore-builder images serve .
