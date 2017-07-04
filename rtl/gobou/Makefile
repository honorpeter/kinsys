VERBOSE   = 0
SIMULATOR = vsim
MODULE    = gobou_top.sv
DEPENDS   = \
	gobou_ctrl_core.sv \
	gobou_ctrl_bias.sv \
	gobou_ctrl_relu.sv \
	gobou_ctrl_mac.sv \
	gobou_ctrl.sv \
	gobou_mac.sv \
	gobou_bias.sv \
	gobou_relu.sv \
	gobou_core.sv \
	gobou_serial_vec.sv
TARGET    = test/test_$(MODULE)
SOURCES   = $(wildcard *.sv)
TESTSUITE = $(wildcard test/*.sv)
INCLUDE   = $(shell git rev-parse --show-toplevel)/rtl/common
DIST      = ../../dist
VSIM_LIB  = -L ../ninjin/work

include ../Makefile

