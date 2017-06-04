BOARD = zybo
IP    = kinpira_axi_lite
APP   = iotest

.PHONY: run sw hw zybo zedboard ip all clean

run:
	# cp main.c ${BOARD}/${BOARD}.sdk/${APP}/src
	xsct run.tcl ${BOARD} ${APP}

all: clean ip ${BOARD} hw sw run

sw:
	xsct sw.tcl ${BOARD} ${APP}

hw:
	vivado -nojournal -nolog -mode batch -source hw.tcl -tclargs ${BOARD} ${IP}

ip:
	vivado -nojournal -nolog -mode batch -source ip.tcl -tclargs ${IP}

zedboard:
	vivado -nojournal -nolog -mode batch -source zedboard.tcl

zybo:
	vivado -nojournal -nolog -mode batch -source zybo.tcl

clean:
	rm -rf ip zybo zedboard .Xil
	rm -f vivado*
	rm -f hs_err_pid*.log

synth:
	vivado -mode batch -source synth.tcl | sed -e '/^\#/d'

impl:
	vivado -mode batch -source impl.tcl | sed -e '/^\#/d'

build:
	vivado -mode batch -source build.tcl | sed -e '/^\#/d'

clean-old:
	rm -f *.log *.jou *.str
	rm -rf top reports results
	rm -f usage_*
