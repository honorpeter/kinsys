#!/bin/sh
# debug script for whole design with lenet_bare

TOP=`git rev-parse --show-toplevel`

cd $TOP/sim/common
make clean all
./debug_gen.py $1 $2
./debug.out $1 $2

cd $TOP/app/lenet_bare
./param.py $1 $2

cd $TOP/vivado
make run_bare

