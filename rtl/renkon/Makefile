VERBOSE   = 0
SIMULATOR = vsim
MODULE    = renkon_top.sv
DEPENDS   = \
	renkon_ctrl_linebuf_pad.sv \
	renkon_ctrl_linebuf.sv \
	renkon_ctrl_core.sv \
	renkon_ctrl_conv.sv \
	renkon_ctrl_bias.sv \
	renkon_ctrl_relu.sv \
	renkon_ctrl_pool.sv \
	renkon_ctrl.sv \
	renkon_linebuf.sv \
	renkon_linebuf_pad.sv \
	renkon_conv_tree25.sv \
	renkon_conv_wreg.sv \
	renkon_accum.sv \
	renkon_conv.sv \
	renkon_bias.sv \
	renkon_relu.sv \
	renkon_pool_max4.sv \
	renkon_pool.sv \
	renkon_core.sv \
	renkon_serial_mat.sv \
	renkon_mux_output.sv
TARGET    = test/test_$(MODULE)
SOURCES   = $(wildcard *.sv)
TESTSUITE = $(wildcard test/*.sv)
INCLUDE   = $(shell git rev-parse --show-toplevel)/rtl/common
DIST      = ../../dist
VSIM_LIB  = -L ../ninjin/work

include ../Makefile

