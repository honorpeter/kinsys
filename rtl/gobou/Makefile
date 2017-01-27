VERBOSE   = 0
SIMULATOR = vsim
MODULE    = serial_vec.sv
SOURCES   = $(wildcard *.sv)
TESTSUITE = $(wildcard test/*.sv)
PACKAGE   = $(shell echo $(MODULE) | cut -d/ -f1)
TESTBENCH = test_$(shell echo $(MODULE) | cut -d/ -f1)
TARGET    = test/$(TESTBENCH)

.PHONY: test clean
.SUFFIXES: .com .v .sv .log .vh .svh .sim .dot .png

############################################################
# Major Rules
############################################################

all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.com)

ifeq ($(VERBOSE),1)
test: $(MODULE:.sv=.com) $(TARGET:.sv=.log)
test-all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.log)
else
test: $(MODULE:.sv=.com) $(TARGET:.sv=.sim)
test-all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.sim)
endif

clean:
	rm -f $(SOURCES:.sv=.com)
	rm -f $(SOURCES:.sv=.com.log)
	rm -f $(SOURCES:.sv=.sim)
	rm -f $(SOURCES:.sv=.log)
	rm -f $(TESTSUITE:.sv=.com)
	rm -f $(TESTSUITE:.sv=.com.log)
	rm -f $(TESTSUITE:.sv=.sim)
	rm -f $(TESTSUITE:.sv=.log)
	### vsim
	rm -f vsim.wlf transcript
	rm -rf work csrc
	### xsim
	rm -rf xsim.dir
	rm -f xvlog.log xvlog.pb
	rm -f xelab.log xsim*.log
	rm -f *.jou *.pb *.wdb
	### vcs
	rm -f default.cfg vcdplus.vpd vcs.key
	rm -rf *.daidir
	### iverilog
	rm -f $(SOURCES:.sv=.out)

############################################################
# Attributes Definition
############################################################

ARCH = $(shell uname -m)
ifeq ($(ARCH),x86_64)
  VCS = vcs +v2k -full64
else
  VCS = vcs +v2k
endif
IVERILOG = iverilog

V_TARGET    = $(shell echo $* | tac -s/ | head -1)
ifeq ($(SIMULATOR),xsim)
  XVLOG_OPT = --verbose 2 --sv
  V_COMPILE = (xvlog $(XVLOG_OPT) $< > $@.log && touch $@) \
           && (grep "^\*\* " $@.log || true) \
           || (cat $@.log ; false)
  XSIM_OPT  = -R #$(XVLOG_OPT)
  XELAB_OPT = -relax -debug typical
  DO_ELAB   = xelab $(XELAB_OPT) $(V_TARGET) -s $(V_TARGET)_sim
  DO_SIM    = test -f $(V_TARGET)_sim && rm -f $(V_TARGET)_sim \
            ; time xsim $(V_TARGET)_sim $(XSIM_OPT) | sed 's/^\# //'
endif
ifeq ($(SIMULATOR),vsim)
  VLOG_OPT  = -sv12compat +acc=rnbp +define+FAST_FUNC # -novopt # -lint
  V_COMPILE = (test -d work || vlib work) \
           && (vlog $(VLOG_OPT) $< > $@.log && touch $@) \
           && (grep "^\*\* " $@.log || true) || (cat $@.log ; false)
  XSIM_OPT  = -c -do 'run -all; quit' # $(VLOG_OPT)
  DO_SIM    = time vsim $(V_TARGET) $(XSIM_OPT) | sed 's/^\# //'
endif
ifeq ($(SIMULATOR),vcs)
  V_COMPILE = touch $@
  DO_SIM    = make $*.out && time ./$(V_TARGET).out
endif
ifeq ($(SIMULATOR),iverilog)
  V_COMPILE = touch $@
  DO_SIM    = make $*.out && time ./$(V_TARGET).out
endif

ifeq ($(VERBOSE),1)
  E = true
  Q =
else
  E =
  Q = @
endif

############################################################
# General Rules
############################################################

.com.sim:
ifeq ($(SIMULATOR),xsim)
	@$(E) echo "  ELABORATE         $(V_TARGET)"
	$(Q)$(DO_ELAB)
	$(Q)$(DO_SIM)
else
	$(Q)$(DO_SIM)
endif

.com.log:
ifeq ($(SIMULATOR),xsim)
	@$(E) echo "  ELABORATE         $(V_TARGET)"
	$(Q)$(DO_ELAB) | tee $@
	$(DO_SIM) 2>&1 | tee -a $@
else
	$(DO_SIM) 2>&1 | tee $@
endif

.v.com:
	@echo "  COMPILE (.v)      $<"
	$(Q)$(V_COMPILE)

.sv.com:
	@echo "  COMPILE (.sv)     $<"
	$(Q)$(V_COMPILE)

