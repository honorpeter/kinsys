BOARD    = zedboard
IP       = kinpira
APP      = lenet
APP_BARE = lenet_bare

.PHONY: run_bare bare build zybo zedboard ip all clean linux

run_bare:
	xsct run.tcl ${BOARD} ${APP_BARE}

# avoid friendly fire
all:
	@../utils/confirm.sh "Build the project from the beginning?"
	make clean dist ip proj build bare run

run_peta:
	(cd linux-zedboard;                                  \
	  petalinux-boot --jtag --fpga --kernel              \
	    --xsdb-conn "connect; target 13; rst; target 16" \
	)
	# (cd linux-zcu102;                                  \
	#   petalinux-boot --jtag --fpga --kernel            \
	#     --xsdb-conn "connect; targets 5; rst; target 4; rst; target 1" \
	# )

peta:
	bash peta.sh ${BOARD} ${APP}

bare:
	# cp ${BOARD}/${BOARD}.sdk/design_1_wrapper.hdf ~/tmp
	# rm -rf ${BOARD}/${BOARD}.sdk/${APP_BARE}{,_bsp}
	# rm -rf ${BOARD}/${BOARD}.sdk/{.metadata,design_1_wrapper_hw_platform_0}
	# cp ~/tmp/design_1_wrapper.hdf ${BOARD}/${BOARD}.sdk/
	xsct bare.tcl ${BOARD} ${APP_BARE}

build:
	vivado -nojournal -nolog -mode batch -source build.tcl -tclargs ${BOARD} ${IP}

proj:
	vivado -nojournal -nolog -mode batch -source proj.tcl -tclargs ${BOARD} ${IP}

ip:
	vivado -nojournal -nolog -mode batch -source ip.tcl -tclargs ${BOARD} ${IP}

dist:
	make -C ../rtl dist

clean:
	rm -rf ../dist ip ${BOARD} .Xil linux-${BOARD}
	rm -f vivado* hs_err_pid*.log

