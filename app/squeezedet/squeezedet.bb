#
# This file is the squeezedet recipe.
#

SUMMARY = "Simple squeezedet application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://main.c \
           file://squeezedet.c \
           file://squeezedet.h \
           file://layer.c \
           file://layer.h \
           file://peta.c \
           file://peta.h \
           file://util.c \
           file://util.h \
           file://types.h \
           file://kinpira.h \
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
           file://data/2_img4.dat \
           file://data/image.bin \
           file://Makefile \
          "

S = "${WORKDIR}"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 squeezedet ${D}${bindir}
    install -d ${D}${datadir}/squeezedet
    cp -r data ${D}${datadir}/squeezedet
}
