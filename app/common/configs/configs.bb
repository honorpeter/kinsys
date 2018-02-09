#
# This file is the configs recipe.
#

SUMMARY = "Simple configs application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
  file://etc/X11/xorg.conf \
  file://home/root/.xinitrc \
  file://home/root/.matchbox/session \
"

FILES_${PN} += "\
  home/root/.xinitrc \
  home/root/.matchbox/session \
"

S = "${WORKDIR}"

do_install() {
  install -d ${D}${sysconfdir}/X11
  install -m 0644 etc/X11/xorg.conf ${D}${sysconfdir}/X11
  install -d ${D}/home
  install -d ${D}/home/root
  install -m 0644 home/root/.xinitrc ${D}/home/root
  install -d ${D}/home/root/.matchbox
  install -m 0755 home/root/.matchbox/session ${D}/home/root/.matchbox
}
