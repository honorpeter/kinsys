#
# This file is the squeezedet recipe.
#

SUMMARY = "Simple squeezedet application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
  file://kinpira.h \
  file://types.h \
  file://layer.h \
  file://peta.h \
  file://util.h \
  file://layer.c \
  file://peta.c \
  file://util.c \
  file://activation.cpp \
  file://activation.hpp \
  file://arithmetic.cpp \
  file://arithmetic.hpp \
  file://bbox_utils.cpp \
  file://bbox_utils.hpp \
  file://display.cpp \
  file://display.hpp \
  file://hungarian.cpp \
  file://hungarian.hpp \
  file://matrix.hpp \
  file://squeezedet.cpp \
  file://squeezedet.hpp \
  file://tracker.cpp \
  file://tracker.hpp \
  file://transform.cpp \
  file://transform.hpp \
  file://webcam.cpp \
  file://webcam.hpp \
  file://wrapper.cpp \
  file://wrapper.hpp \
  file://main.cpp \
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
