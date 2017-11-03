#!/bin/bash

BOARD=$1
PETA_NAME=linux-$BOARD

echo $BOARD

cd $PETA_NAME

case $BOARD in
  zedboard )
    xsct -eval " \
        connect; \
        targets -set -nocase -filter {name =~ \"ARM*#0\"}; \
        rst -system; \
    "
    petalinux-boot --jtag --prebuilt 3 --xsdb-conn "connect; targets 16;"
    # petalinux-boot --jtag --prebuilt 3 --xsdb-conn " \
    #   connect; \
    #   targets -set -nocase -filter {name =~ \"xc7z020\"}; \
    # "
    ;;
  zcu102 )
    XSDB_CONN="
      connect;
      targets -set -nocase -filter {name =~ \"PSU\"};
      rst -system;
      targets -set -nocase -filter {name =~ \"PS\ TAP\"};
    "
    ;;
  * )
    XSDB_CONN="
      connect;
    "
    ;;
esac

# cd $PETA_NAME
# petalinux-boot --jtag --prebuilt 3 --xsdb-conn "$XSDB_CONN"

exit 0

