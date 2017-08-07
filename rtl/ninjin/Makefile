VERBOSE   = 0
SIMULATOR = vsim
MODULE    = ninjin_ddr_buf.sv
# MODULE    = kinpira_ddr.sv
# DEPENDS   = \
# 	ninjin_s_axi_params.sv \
# 	ninjin_s_axi_renkon.sv \
# 	ninjin_s_axi_gobou.sv \
# 	ninjin_m_axi_image.sv \
# 	ninjin_ddr_buf.sv
TARGET    = test/test_$(MODULE)
SOURCES   = $(wildcard *.sv)
TESTSUITE = $(wildcard test/*.sv)
INCLUDE   = $(shell git rev-parse --show-toplevel)/rtl/common
DIST      = ../../dist
VSIM_LIB  = -L ../renkon/work -L ../gobou/work

include ../Makefile

