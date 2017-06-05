BOARD = zedboard
IP    = kinpira_axi
APP   = iotest

.PHONY: run sw hw zybo zedboard ip all clean

run:
	# cp main.c ${BOARD}/${BOARD}.sdk/${APP}/src
	xsct run.tcl ${BOARD} ${APP}

all: clean dist ip proj hw sw run

sw:
	xsct sw.tcl ${BOARD} ${APP}

hw:
	vivado -nojournal -nolog -mode batch -source hw.tcl -tclargs ${BOARD} ${IP}

proj:
	vivado -nojournal -nolog -mode batch -source proj.tcl -tclargs ${BOARD} ${IP}

ip: dist
	vivado -nojournal -nolog -mode batch -source ip.tcl -tclargs ${BOARD} ${IP}

dist:
	make -C ../rtl dist

clean:
	rm -rf ../dist ip zybo zedboard .Xil
	rm -f vivado* hs_err_pid*.log

