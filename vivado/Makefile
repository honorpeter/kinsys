BOARD = zedboard
IP    = kinpira_axi_lite
APP   = iotest

.PHONY: run sw hw zybo zedboard ip all clean

run:
	# cp main.c ${BOARD}/${BOARD}.sdk/${APP}/src
	xsct run.tcl ${BOARD} ${APP}

all: clean dist ip ${BOARD} hw sw run

sw:
	xsct sw.tcl ${BOARD} ${APP}

hw:
	vivado -nojournal -nolog -mode batch -source hw.tcl -tclargs ${BOARD} ${IP}

zedboard:
	vivado -nojournal -nolog -mode batch -source zedboard.tcl

zybo:
	vivado -nojournal -nolog -mode batch -source zybo.tcl

ip:
	vivado -nojournal -nolog -mode batch -source ip.tcl -tclargs ${IP}

dist:
	make -C ../rtl dist

clean:
	rm -rf ../dist ip zybo zedboard .Xil
	rm -f vivado* hs_err_pid*.log

