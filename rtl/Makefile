VERBOSE   = 0
SIMULATOR = vsim
MODULE    = gobou/serial_vec.sv
SOURCES   = \
	$(wildcard gobou/*.sv)  \
	$(wildcard renkon/*.sv) \
	$(wildcard ninjin/*.sv) \
	$(wildcard common/*.sv)
TESTSUITE = \
	$(wildcard test/gobou/*.sv)  \
	$(wildcard test/renkon/*.sv) \
	$(wildcard test/ninjin/*.sv) \
	$(wildcard test/common/*.sv)
TESTBENCH = test_$(shell echo $(MODULE) | cut -d / -f 2)
PACKAGE   = $(shell echo $(MODULE) | cut -d / -f 1)
TARGET    = test/$(PACKAGE)/$(TESTBENCH)

.PHONY: test clean
.SUFFIXES: .com .v .sv .log .vh .svh .sim .dot .png

hoge:
	@make $(MODULE:.sv=.com)
	@make $(TARGET:.sv=.com)
	@echo $(MODULE)
	@echo $(TARGET)

ifeq ($(VERBOSE),1)
test: $(MODULE:.sv=.com) $(TARGET:.sv=.com) $(TESTBENCH:.sv=.log)
test-all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.log)
else
test: $(MODULE:.sv=.com) $(TARGET:.sv=.com) $(TESTBENCH:.sv=.sim)
test-all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.sim)
endif

all: $(SOURCES:.sv=.com) $(TESTSUITE:.sv=.com)

clean:
	rm -f *~
	rm -f $(SOURCES:.sv=.com)
	rm -f $(SOURCES:.sv=.sim)
	rm -f $(SOURCES:.sv=.log)
	rm -f $(TESTSUITE:.sv=.com)
	rm -f $(TESTSUITE:.sv=.sim)
	rm -f $(TESTSUITE:.sv=.log)
	rm -f _*
	rm -f Makefile.dep
	rm -f dep.rb dep.in

	### vsim
	rm -f vsim.wlf transcript
	rm -rf work csrc

	### xsim
	rm -rf xsim.dir
	rm -f *.jou *.pb
	rm -f *.wdb

	### vcs
	rm -f default.cfg vcdplus.vpd vcs.key
	rm -rf *.daidir

	### iverilog
	rm -f $(SOURCES:.sv=.out)

# Attributes Definition

ARCH = $(shell uname -m)
ifeq ($(ARCH),x86_64)
  VCS = vcs +v2k -full64
else
  VCS = vcs +v2k
endif
IVERILOG = iverilog

ifeq ($(SIMULATOR),xsim)
  XVLOG_OPT   = --verbose 2 \
                #-work work #+acc=rnbp +define+FAST_FUNC # -novopt # -lint
  XSIMOPTION  = -R #$(XVLOG_OPT)
  XELABOPTION = -debug typical
  ELAB_SIM    = xelab $(XELABOPTION) $* -s $*_sim
  DO_SIM      = test -f $*_sim && rm -f $*_sim \
              ; time xsim $*_sim $(XSIMOPTION) | sed 's/^\# //'
  V_COMPILE   = (xvlog $(XVLOG_OPT) $< > $@.log && touch $@) \
             && (grep "^\*\* " $@.log || true) \
             || (cat $@.log ; false)
endif
ifeq ($(SIMULATOR),vsim)
  VLOG_OPT    = -sv12compat +acc=rnbp +define+FAST_FUNC # -novopt # -lint
  VSIMOPTION  = -c -do 'run -all; quit' # $(VLOG_OPT)
  DO_SIM      = test -f $* && rm -f $* \
              ; time vsim $* $(VSIMOPTION) | sed 's/^\# //'
  V_COMPILE   = (test -d work || vlib work) \
             && (vlog $(VLOG_OPT) $< > $@.log && touch $@) \
             && (grep "^\*\* " $@.log || true) || (cat $@.log ; false)
endif
ifeq ($(SIMULATOR),vcs)
  DO_SIM      = make $* && time ./$*
  V_COMPILE   = touch $@
endif
ifeq ($(SIMULATOR),iverilog)
  DO_SIM      = make $* && time ./$*.out
  V_COMPILE   = touch $@
endif

ifeq ($(VERBOSE),1)
  E = true
  Q =
else
  E =
  Q = @
endif

# General Rules

.com.sim:
ifeq ($(SIMULATOR),xsim)
	@$(E) echo "  ELABORATE         $*"
	$(Q)$(ELAB_SIM)
	$(Q)$(DO_SIM)
else
	$(Q)$(DO_SIM)
endif

.com.log:
ifeq ($(SIMULATOR),xsim)
	@echo "  ELABORATE         $*"
	$(Q)$(ELAB_SIM) | tee $@
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

