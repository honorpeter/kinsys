#!/bin/sh

TOP=`git rev-parse --show-toplevel`

cd $TOP/sim/common
make clean all
./debug_gen.rb $1 $2
./debug.out $1 $2

cd $TOP/app/lenet_bare
./param.rb $1 $2
./debug.rb

cd $TOP/vivado
make sw run

