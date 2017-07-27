#
# This file is the lenet recipe.
#

SUMMARY = "Simple lenet application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://main.c \
           file://peta.c \
           file://peta.h \
           file://kinpira.h \
           file://lenet.h \
           file://types.h \
           file://data/W_conv0.h \
           file://data/W_conv1.h \
           file://data/W_full2.h \
           file://data/W_full3.h \
           file://data/b_conv0.h \
           file://data/b_conv1.h \
           file://data/b_full2.h \
           file://data/b_full3.h \
           file://data/conv0_tru.h \
           file://data/conv1_tru.h \
           file://data/full2_tru.h \
           file://data/full3_tru.h \
           file://data/image.h \
           file://Makefile \
          "

S = "${WORKDIR}"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 lenet ${D}${bindir}
}
