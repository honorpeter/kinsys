VERBOSE   = 0
SIMULATOR = vsim
MODULE    = mem_sp.sv
DEPENDS   =
TARGET    = test/test_$(MODULE)
SOURCES   = $(wildcard *.sv)
TESTSUITE = $(wildcard test/*.sv)
HEADERS   = $(wildcard *.svh)
INCLUDE   =
DIST      = ../../dist

include ../Makefile

dist:
	mkdir -p $(DIST)
	rsync -L -avz $(SOURCES) $(HEADERS) $(TESTSUITE) $(DIST)
	sed -i -e "s|\`undef DIST|\`define DIST|g" $(DIST)/common.svh
