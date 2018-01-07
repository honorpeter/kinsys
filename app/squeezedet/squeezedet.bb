#
# This file is the squeezedet recipe.
#

SUMMARY = "Simple squeezedet application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
  file://Makefile \
  file://kinpira.h \
  file://types.h \
  file://peta.h \
  file://util.h \
  file://layer.h \
  file://peta.c \
  file://util.c \
  file://layer.c \
  file://matrix.hpp \
  file://activation.hpp \
  file://activation.cpp \
  file://arithmetic.hpp \
  file://arithmetic.cpp \
  file://bbox_utils.hpp \
  file://bbox_utils.cpp \
  file://display.hpp \
  file://display.cpp \
  file://hungarian.hpp \
  file://hungarian.cpp \
  file://squeezedet.hpp \
  file://squeezedet.cpp \
  file://tracker.hpp \
  file://tracker.cpp \
  file://transform.hpp \
  file://transform.cpp \
  file://webcam.hpp \
  file://webcam.cpp \
  file://wrapper.hpp \
  file://wrapper.cpp \
  file://main.cpp \
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
