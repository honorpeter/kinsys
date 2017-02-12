VERBOSE   = 0
SIMULATOR = vsim
MODULE    = gobou/gobou.sv
DEPENDS   =
PACKAGE   = $(shell echo $(MODULE) | cut -d/ -f1)
TESTBENCH = test_$(shell echo $(MODULE) | cut -d/ -f2)
TARGET    = ../tests/$(PACKAGE)/$(TESTBENCH)
SOURCES   = \
	$(wildcard gobou/*.sv)  \
	$(wildcard renkon/*.sv) \
	$(wildcard ninjin/*.sv) \
	$(wildcard common/*.sv)
TESTSUITE = \
	$(wildcard ../tests/gobou/*.sv)  \
	$(wildcard ../tests/renkon/*.sv) \
	$(wildcard ../tests/ninjin/*.sv) \
	$(wildcard ../tests/common/*.sv)
INCLUDE   = $(shell git rev-parse --show-toplevel)/rtl/common

.PHONY: test test-all clean
.SUFFIXES: .com .v .sv .log .vh .svh .sim .dot .png

############################################################
# Major Rules
############################################################

all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.com)

test: $(DEPENDS:.sv=.com) $(MODULE:.sv=.com) $(TARGET:.sv=.log)
test-all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.log)

log:
	@vim $(TARGET:.sv=.log)

edit:
	@vim -O $(TARGET) $(MODULE)

diff:
	@vimdiff $(shell echo $(TARGET) | cut -d/ -f2 | cut -d. -f1).dat \
           $(shell echo $(TARGET) | cut -d/ -f2 | cut -d. -f1)_true.dat

clean:
	rm -f $(SOURCES:.sv=.com)
	rm -f $(SOURCES:.sv=.log)
	rm -f $(TESTSUITE:.sv=.com)
	rm -f $(TESTSUITE:.sv=.log)
	### vsim
	rm -rf work csrc
	rm -f vsim.wlf transcript
	rm -f vish_stacktrace.vstf
	### xsim
	rm -rf xsim.dir
	rm -f xvlog.log xvlog.pb
	rm -f xelab.log xsim*.log
	rm -f webtalk*.log
	rm -f *.jou *.pb *.wdb
	### vcs
	rm -rf $(SOURCES:.sv=.com.daidir)
	rm -rf $(TESTSUITE:.sv=.com.daidir)
	rm -f default.cfg vcdplus.vpd vcs.key
	### iverilog
	rm -f $(SOURCES:.sv=.out)

############################################################
# Attributes Definition
############################################################

ifeq ($(VERBOSE),1)
  E = @true
  Q =
else
  E = @
  Q = @
endif

V_TARGET    = $(shell echo $* | tac -s/ | head -1)
ifeq ($(SIMULATOR),xsim)
  XVLOG_OPT = --sv -i $(INCLUDE) --verbose 2
  COMPILE   = xvlog $(XVLOG_OPT) $<
  XELAB_OPT = -relax -debug typical
  ELABORATE = xelab $(XELAB_OPT) $(V_TARGET) -s $(V_TARGET)_sim
  XSIM_OPT  = -R #$(XVLOG_OPT)
  SIMULATE  = xsim $(V_TARGET)_sim $(XSIM_OPT)
else
ifeq ($(SIMULATOR),vsim)
  VLOG_OPT  = -sv12compat +incdir+$(INCLUDE) -lint
  COMPILE   = (test -d work || vlib work) \
           && vlog $(VLOG_OPT) $<
  VSIM_OPT  = -c -do 'run -all; quit' # $(VLOG_OPT)
  SIMULATE  = vsim $(V_TARGET) $(VSIM_OPT) | sed 's/^\# //'
else
ifeq ($(SIMULATOR),vcs)
  VCS_OPT   = -full64 -sverilog +incdir+$(INCLUDE) -R
  COMPILE   = true $<
  SIMULATE  = vcs $(VCS_OPT) -o $(V_TARGET).out $*.sv $(SOURCES)
else
ifeq ($(SIMULATOR),iverilog)
  IVER_OPT  = -g2012 -I $(INCLUDE)
  COMPILE   = iverilog $(IVER_OPT) -t null $<
  SIMULATE  = iverilog $(IVER_OPT) -o $(V_TARGET).out $(SOURCES) \
           && time ./$(V_TARGET).out
endif
endif
endif
endif

############################################################
# General Rules
############################################################

.v.com:
	$(E) echo "  COMPILE (.v)      $<"
ifeq ($(VERBOSE),1)
	$(Q) $(COMPILE) 2>&1 | tee $@
else
	$(Q) $(COMPILE) > $@ 2>&1
endif

.sv.com:
	$(E) echo "  COMPILE (.sv)     $<"
ifeq ($(VERBOSE),1)
	$(Q) $(COMPILE) 2>&1 | tee $@
else
	$(Q) $(COMPILE) > $@ 2>&1
endif

.com.log:
ifeq ($(SIMULATOR),xsim)
	$(E) echo "  ELABORATE         $(V_TARGET)"
  ifeq ($(VERBOSE),1)
		$(Q) $(ELABORATE) 2>&1 | tee $@
  else
		$(Q) $(ELABORATE) > $@ 2>&1
  endif
	$(E) echo "  SIMULATE          $(V_TARGET)"
  ifeq ($(VERBOSE),1)
		$(Q) $(SIMULATE) 2>&1 | tee -a $@
  else
		$(Q) $(SIMULATE) >> $@ 2>&1
  endif
else
	$(E) echo "  SIMULATE          $(V_TARGET)"
  ifeq ($(VERBOSE),1)
		$(Q) $(SIMULATE) 2>&1 | tee $@
  else
		$(Q) $(SIMULATE) > $@ 2>&1
  endif
endif

