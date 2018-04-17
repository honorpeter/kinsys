#!/bin/bash
# ref:
#   https://forum.digilentinc.com/topic/2719-how-to-register-my-device-as-uio-on-petalinux/

# TODO: scripting petalinux-config

BOARD=$1
APP_NAME=$2
TOP=`git rev-parse --show-toplevel`
export TMPDIR=/ldisk/$USER/tmp

PETA_NAME=linux-$BOARD
PETA_FPGA=design_1_wrapper.bit
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
  petalinux-util --webtalk off

  cd $PETA_NAME
  ### System configuration
  $TOP/utils/confirm.sh "
Yocto Settings ---> TMPDIR Location ---> ( /tmp/... to /ldisk/\$USER/... )
"
  petalinux-config --get-hw-description=..

  # ### User applications
  # petalinux-create --type apps --name $APP_NAME --enable
  # petalinux-create --type modules --name udmabuf --enable
  #
  # # Assert 2016.4
  # rm -rf project-spec/meta-user/recipes-apps/$APP_NAME/$APP_NAME
  # rm -rf project-spec/meta-user/recipes-modules/udmabuf/udmabuf
  #
  # cp -r $TOP/app/$APP_NAME/*      project-spec/meta-user/recipes-apps/$APP_NAME
  # cp -r $TOP/app/common/modules/* project-spec/meta-user/recipes-modules
  # cp -r $TOP/app/common/$BOARD/*  project-spec/meta-user

  ### Kernel configuration
  $TOP/utils/confirm.sh "
Device Drivers ---> Userspace I/O Drivers ---> Userspace I/O platform driver with generic IRQ handling
Device Drivers ---> Multimedia support  ---> Media USB Adapters ---> USB Video Class (UVC)
"
  petalinux-config --component kernel

  ### Rootfs configuration
#   $TOP/utils/confirm.sh "
# No need for configuration
# "
  $TOP/utils/confirm.sh "
Filesystem Packages --->
  * libs ---> libmali-xlnx
  * libs ---> libmali-xlnx-dev
  * misc ---> matchbox-config-gtk
  * misc ---> matchbox-panel-2
  * misc ---> ! packagegroup-core-ssh-dropbear
  * misc ---> packagegroup-petalinux-gstreamer
  * misc ---> packagegroup-petalinux-opencv
  * misc ---> v4l-utils
  * misc ---> x264 ---> x264
  * misc ---> x264 ---> x264-bin
  * misc ---> xauth
  * misc ---> xf86-input-evdev
  * misc ---> xf86-input-keyboard
  * misc ---> xf86-input-mouse
  * misc ---> xf86-video-armsoc
  * misc ---> xf86-video-fbdev
  * misc ---> xhost
  * misc ---> xinit
  * misc ---> xinput
  * misc ---> xkbcomp
  * misc ---> xmodmap
  * misc ---> xrandr
  * misc ---> xset
  * x11 ---> base ---> libdrm ---> libdrm
  * x11 ---> base ---> libdrm ---> libdrm-drivers
  * x11 ---> base ---> libdrm ---> libdrm-kms
  * x11 ---> base ---> libdrm ---> libdrm-tests
  * x11 ---> base ---> xcursor-transparent-theme
  * x11 ---> base ---> xserver-xorg ---> xserver-xorg
  * x11 ---> base ---> xserver-xorg ---> xserver-xorg-module-exa
  * x11 ---> base ---> xserver-xorg ---> xserver-xorg-extension-dri
  * x11 ---> base ---> xserver-xorg ---> xserver-xorg-extension-glx
  * x11 ---> base ---> xserver-xorg ---> xserver-xorg-extension-dri2
  * x11 ---> base ---> xtscal
  * x11 ---> fonts ---> liberation-fonts
  * x11 ---> libs ---> xkeyboard-config
  * x11 ---> matchbox-desktop-sato
  * x11 ---> matchbox-keyboard
  * x11 ---> matchbox-sesstion
  * x11 ---> matchbox-sesstion-sato
  * x11 ---> sato-icon-theme
  * x11 ---> settings-daemon
  * x11 ---> utils ---> matchbox-terminal
  * x11 ---> wm ---> matchbox-desktop
  * x11 ---> wm ---> matchbox-theme-sato
  * x11 ---> wm ---> matchbox-wm
"
  petalinux-config --component rootfs

  ### Build
  petalinux-build

  ### User applications
  petalinux-create --type apps --name $APP_NAME --enable
  petalinux-create --type modules --name udmabuf --enable

  # Assert 2016.4
  rm -rf project-spec/meta-user/recipes-apps/$APP_NAME/$APP_NAME
  rm -rf project-spec/meta-user/recipes-modules/udmabuf/udmabuf

  cp -r $TOP/app/$APP_NAME/*      project-spec/meta-user/recipes-apps/$APP_NAME
  cp -r $TOP/app/common/library/* project-spec/meta-user/recipes-apps/$APP_NAME
  cp -r $TOP/app/common/modules/* project-spec/meta-user/recipes-modules
  cp -r $TOP/app/common/$BOARD/*  project-spec/meta-user

  petalinux-build
else
  cd $PETA_NAME
  cp -r $TOP/app/$APP_NAME/*      project-spec/meta-user/recipes-apps/$APP_NAME
  cp -r $TOP/app/common/library/* project-spec/meta-user/recipes-apps/$APP_NAME
  cp -r $TOP/app/common/modules/* project-spec/meta-user/recipes-modules
  cp -r $TOP/app/common/$BOARD/*  project-spec/meta-user
  petalinux-build
fi

STATUS=$?
if [ $STATUS -eq 0 ]; then
  ### Package images
  TMPDIR=~/tmp petalinux-package --boot --u-boot --fpga images/linux/$PETA_FPGA --force
  (TMPDIR=~/tmp petalinux-package --prebuilt --fpga images/linux/$PETA_FPGA --force;
    mv pre-built/linux/implementation/{$PETA_FPGA,download.bit}
  )

  ### Boot
  # petalinux-boot --qemu --prebuilt 3
  # petalinux-boot --jtag --prebuilt 3
fi

