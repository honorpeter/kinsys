BOARD = zedboard
IP    = kinpira_ddr
APP   = lenet_bare

.PHONY: run sw hw zybo zedboard ip all clean

run:
	xsct run.tcl ${BOARD} ${APP}

# avoid friendly fire
all:
	@../utils/confirm.sh "Build the project from the beginning?"
	make clean dist ip proj hw sw run

sw:
	cp ${BOARD}/${BOARD}.sdk/design_1_wrapper.hdf /tmp
	rm -rf ${BOARD}/${BOARD}.sdk/*
	rm -rf ${BOARD}/${BOARD}.sdk/.metadata
	cp /tmp/design_1_wrapper.hdf ${BOARD}/${BOARD}.sdk/
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
	rm -rf ../dist ip zybo zedboard zcu102 .Xil
	rm -f vivado* hs_err_pid*.log

