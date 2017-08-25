#!/bin/bash
# ref:
#   https://forum.digilentinc.com/topic/2719-how-to-register-my-device-as-uio-on-petalinux/

BOARD=$1
APP_NAME=$2
TOP=`git rev-parse --show-toplevel`

PETA_NAME=linux-$BOARD
PETA_FPGA=images/linux/design_1_wrapper.bit
case $BOARD in
  zedboard | zybo )
    PETA_ARCH=zynq
    ;;
  zcu102 )
    PETA_ARCH=zynqMP
    ;;
  * )
    PETA_ARCH=microblaze
    ;;
esac

if [ ! -e $PETA_NAME ]; then
  ln -s ${BOARD}/${BOARD}.sdk/$PETA_NAME

  ### Create project for the target board
  cd ${BOARD}/${BOARD}.sdk
  petalinux-create --type project --template $PETA_ARCH --name $PETA_NAME --force

  cd $PETA_NAME
  ### System configuration
  $TOP/utils/confirm.sh \
    "[Yocto ~] -> [TMPDIR ~] -> /tmp/* to /ldisk/* & Enable debug-tweaks"
  petalinux-config --get-hw-description=..

  ### User applications
  petalinux-create --type apps --name $APP_NAME --enable
  petalinux-create --type modules --name udmabuf --enable

  rm project-spec/meta-user/recipes-apps/$APP_NAME/files/$APP_NAME.c
  cp -r $TOP/app/$APP_NAME/*      project-spec/meta-user/recipes-apps/$APP_NAME
  cp -r $TOP/app/common/$BOARD/*  project-spec/meta-user/recipes-bsp
  cp -r $TOP/app/common/modules/* project-spec/meta-user/recipes-modules

  ### Kernel configuration
  $TOP/utils/confirm.sh "[Device Drivers] -> [Userspace ~] -> uio_pdrv_genirq"
  petalinux-config --component kernel

  ### Rootfs configuration
  $TOP/utils/confirm.sh "No need to configuration"
  petalinux-config --component rootfs

  ### Build
  petalinux-build
else
  cd $PETA_NAME
  cp -r $TOP/app/$APP_NAME/*      project-spec/meta-user/recipes-apps/$APP_NAME
  cp -r $TOP/app/common/$BOARD/*  project-spec/meta-user/recipes-bsp
  cp -r $TOP/app/common/modules/* project-spec/meta-user/recipes-modules
  petalinux-build
fi

### Package images
petalinux-package --boot --fpga --u-boot --force
petalinux-package --prebuilt --fpga $PETA_FPGA --force

### Boot on QEMU
# petalinux-boot --qemu --prebuilt 3

### After boot
# petalinux-boot --jtag --prebuilt 3 --fpga
# (modprobe uio_pdrv_genirq)

