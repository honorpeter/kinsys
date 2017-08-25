#!/bin/bash

renkon_params=(
  RENKON_CORE
  RENKON_CORELOG
  RENKON_NETSIZE
  RENKON_MAXIMG
)

RENKON_CORE=8
RENKON_CORELOG=3
RENKON_NETSIZE=11
RENKON_MAXIMG=32

gobou_params=(
  GOBOU_CORE
  GOBOU_CORELOG
  GOBOU_NETSIZE
)

GOBOU_CORE=16
GOBOU_CORELOG=4
GOBOU_NETSIZE=13

function show_params {
  for name in ${renkon_params[@]}; do
    echo "$name = ${!name}"
  done

  for name in ${gobou_params[@]}; do
    echo "$name = ${!name}"
  done
}

function annotate_rtl() {
  for name in ${renkon_params[@]}; do
    sed -i -e "s/$name[ \t]*=[ \t]*_/$name = ${!name}/g" $1/renkon.svh
  done

  for name in ${gobou_params[@]}; do
    sed -i -e "s/$name[ \t]*=[ \t]*_/$name = ${!name}/g" $1/gobou.svh
  done
}

function annotate_app() {
  exit
}
