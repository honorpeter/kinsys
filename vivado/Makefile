BOARD    = zedboard
IP       = kinpira_ddr
APP_BARE = lenet_bare
APP_PETA = lenet

.PHONY: run sw hw zybo zedboard ip all clean linux

run:
	xsct run.tcl ${BOARD} ${APP_BARE}

# avoid friendly fire
all:
	@../utils/confirm.sh "Build the project from the beginning?"
	make clean dist ip proj hw sw run

peta:
	./peta.sh ${BOARD} ${APP_PETA}

run_peta:
	(cd linux;                                           \
	  petalinux-boot --jtag --fpga --kernel              \
	    --xsdb-conn "connect; target 13; rst; target 16" \
	)

sw:
	cp ${BOARD}/${BOARD}.sdk/design_1_wrapper.hdf ~/tmp
	rm -rf ${BOARD}/${BOARD}.sdk/${APP_BARE}{,_bsp}
	rm -rf ${BOARD}/${BOARD}.sdk/{.metadata,design_1_wrapper_hw_platform_0}
	cp ~/tmp/design_1_wrapper.hdf ${BOARD}/${BOARD}.sdk/
	xsct sw.tcl ${BOARD} ${APP_BARE}

hw:
	vivado -nojournal -nolog -mode batch -source hw.tcl -tclargs ${BOARD} ${IP}

proj:
	vivado -nojournal -nolog -mode batch -source proj.tcl -tclargs ${BOARD} ${IP}

ip: dist
	vivado -nojournal -nolog -mode batch -source ip.tcl -tclargs ${BOARD} ${IP}

dist:
	make -C ../rtl dist

clean:
	rm -rf ../dist ip ${BOARD} .Xil linux
	rm -f vivado* hs_err_pid*.log

