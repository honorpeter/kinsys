VERBOSE   = 0
SIMULATOR = vsim
MODULE    = gobou.sv
DEPENDS   = bias.sv ctrl.sv ctrl_core.sv ctrl_relu.sv \
						mac.sv serial_vec.sv core.sv ctrl_bias.sv \
						ctrl_mac.sv gobou.sv relu.sv
TARGET    = test/test_$(MODULE)
SOURCES   = $(wildcard *.sv)
TESTSUITE = $(wildcard test/*.sv)
INCLUDE   = $(shell git rev-parse --show-toplevel)/rtl

.PHONY: test test-all clean
.SUFFIXES: .com .v .sv .log .vh .svh .sim .dot .png

############################################################
# Major Rules
############################################################

all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.com)

test: $(MODULE:.sv=.com) $(DEPENDS:.sv=.com) $(TARGET:.sv=.log)
test-all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.log)

clean:
	rm -f $(SOURCES:.sv=.com)
	rm -f $(SOURCES:.sv=.com.log)
	rm -f $(SOURCES:.sv=.log)
	rm -f $(TESTSUITE:.sv=.com)
	rm -f $(TESTSUITE:.sv=.com.log)
	rm -f $(TESTSUITE:.sv=.log)
	### vsim
	rm -rf work csrc
	rm -f vsim.wlf transcript
	rm -f vish_stacktrace.vstf
	### xsim
	rm -rf xsim.dir
	rm -f xvlog.log xvlog.pb
	rm -f xelab.log xsim*.log
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
  V_COMPILE = (xvlog $(XVLOG_OPT) $< > $@.log && touch $@) \
           && (grep "^\*\* " $@.log || true) \
           || (cat $@.log ; false)
  XSIM_OPT  = -R #$(XVLOG_OPT)
  XELAB_OPT = -relax -debug typical
  DO_ELAB   = xelab $(XELAB_OPT) $(V_TARGET) -s $(V_TARGET)_sim
  DO_SIM    = test -f $(V_TARGET)_sim && rm -f $(V_TARGET)_sim \
            ; xsim $(V_TARGET)_sim $(XSIM_OPT) | sed 's/^\# //'
            # ; time xsim $(V_TARGET)_sim $(XSIM_OPT) | sed 's/^\# //'
else
ifeq ($(SIMULATOR),vsim)
  VLOG_OPT  = -sv12compat +incdir+$(INCLUDE) -lint
  V_COMPILE = (test -d work || vlib work) \
           && (vlog $(VLOG_OPT) $< > $@.log && touch $@) \
           && (grep "^\*\* " $@.log || true) || (cat $@.log ; false)
  XSIM_OPT  = -c -do 'run -all; quit' # $(VLOG_OPT)
  DO_SIM    = vsim $(V_TARGET) $(XSIM_OPT) | sed 's/^\# //'
  # DO_SIM    = time vsim $(V_TARGET) $(XSIM_OPT) | sed 's/^\# //'
else
ifeq ($(SIMULATOR),vcs)
  VSIM_OPT  = -full64 -sverilog -R
  V_COMPILE = touch $@
	DO_SIM    = vcs $(VSIM_OPT) $*.sv $(SOURCES)
else
ifeq ($(SIMULATOR),iverilog)
  V_COMPILE = touch $@
  DO_SIM    = make $*.out && time ./$(V_TARGET).out
endif
endif
endif
endif

############################################################
# General Rules
############################################################

.v.com:
	$(E) echo "  COMPILE (.v)      $<"
	$(Q) $(V_COMPILE)

.sv.com:
	$(E) echo "  COMPILE (.sv)     $<"
	$(Q) $(V_COMPILE)

.com.log:
ifeq ($(SIMULATOR),xsim)
	$(E) echo "  ELABORATE         $(V_TARGET)"
  ifeq ($(VERBOSE),1)
		$(Q) $(DO_ELAB) 2>&1 | tee $@
  else
		$(Q) $(DO_ELAB) 2>&1 > $@
  endif
	$(E) echo "  SIMULATE          $(V_TARGET)"
  ifeq ($(VERBOSE),1)
		$(Q) $(DO_SIM) 2>&1 | tee -a $@
  else
		$(Q) $(DO_SIM) 2>&1 >> $@
  endif
else
	$(E) echo "  SIMULATE          $(V_TARGET)"
  ifeq ($(VERBOSE),1)
		$(Q) $(DO_SIM) 2>&1 | tee $@
  else
		$(Q) $(DO_SIM) 2>&1 | tee $@
		@# $(Q) $(DO_SIM) 2>&1 > $@
  endif
endif

