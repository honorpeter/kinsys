BOARD    = zcu102
IP       = kinpira
APP      = squeezedet
# APP      = webcam
APP_BARE = lenet_bare

.PHONY: run_bare bare build zybo zedboard ip all clean linux

run_bare:
	xsct run_bare.tcl ${BOARD} ${APP_BARE}

run_peta:
	bash run_peta.sh ${BOARD}

# avoid friendly fire
all:
	@../utils/confirm.sh "Build the project from the beginning?"
	make clean dist ip proj build bare

screen:
	# screen /dev/ttyUSB0 115200,cs8,-parentb,-cstopb
	screen /dev/ttyUSB0 115200

peta:
	bash peta.sh ${BOARD} ${APP}

bare:
	cp ${BOARD}/${BOARD}.sdk/design_1_wrapper.hdf ~/tmp
	rm -rf ${BOARD}/${BOARD}.sdk/${APP_BARE}{,_bsp}
	rm -rf ${BOARD}/${BOARD}.sdk/{.metadata,design_1_wrapper_hw_platform_0}
	cp ~/tmp/design_1_wrapper.hdf ${BOARD}/${BOARD}.sdk/
	xsct bare.tcl ${BOARD} ${APP_BARE}

build:
	vivado -nojournal -nolog -mode batch -source build.tcl -tclargs ${BOARD} ${IP}

proj:
	vivado -nojournal -nolog -mode batch -source proj.tcl -tclargs ${BOARD} ${IP}

ip:
	vivado -nojournal -nolog -mode batch -source ip.tcl -tclargs ${BOARD} ${IP}

dist:
	make -C ../rtl dist
	(source ../utils/config.sh; annotate_rtl ../dist)

clean:
	rm -rf ../dist ip ${BOARD} .Xil linux-${BOARD}
	rm -f vivado* hs_err_pid*.log

