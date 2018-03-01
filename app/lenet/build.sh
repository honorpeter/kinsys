#!/bin/bash

ROOT=`git rev-parse --show-toplevel`

source $ROOT/utils/config.sh

############################################################
# define parameters
############################################################

RENKON_CORE=8
RENKON_CORELOG=3
RENKON_NETSIZE=11
RENKON_IMGH_MAX=32
RENKON_IMGW_MAX=32
RENKON_FEAH_MAX=28
RENKON_FEAW_MAX=28
RENKON_OUTH_MAX=14
RENKON_OUTW_MAX=14

GOBOU_CORE=16
GOBOU_CORELOG=4
GOBOU_NETSIZE=13

############################################################
# building
############################################################

$ROOT/utils/confirm.sh "Build kinpira for 'lenet' on vivado"

make -C $ROOT/vivado clean

make -C $ROOT/rtl dist
annotate_rtl $ROOT/dist

make -C $ROOT/vivado ip proj build
make -C $ROOT/vivado peta APP=lenet

exit
