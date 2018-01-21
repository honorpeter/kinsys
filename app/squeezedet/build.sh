#!/bin/bash

ROOT=`git rev-parse --show-toplevel`

source $ROOT/utils/config.sh

############################################################
# define parameters
############################################################

RENKON_CORE=8
RENKON_CORELOG=3
RENKON_NETSIZE=18
RENKON_MAXIMG=240

GOBOU_CORE=2
GOBOU_CORELOG=1
GOBOU_NETSIZE=1

############################################################
# building
############################################################

$ROOT/utils/confirm.sh "Build kinpira for 'squeezedet' on vivado"

make -C $ROOT/vivado clean

make -C $ROOT/rtl dist
annotate_rtl $ROOT/dist

make -C $ROOT/vivado ip proj build
# make -C $ROOT/vivado peta APP=squeezedet

exit
