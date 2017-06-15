#!/bin/sh
# ref: http://tohka383.hatenablog.jp/entry/20111227/1324979198

if [ -z "${2}" ]; then
  default_value="no"
  message="${1} (y/N) "
else
  default_value="yes"
  message="${1} (Y/n) "
fi

while : ; do
  echo -n "${message}"
  read answer
  if [ -z "${answer}" ]; then
    answer="${default_value}"
  fi
  if [[ ${answer} =~ ^\s*[yY]([eE][sS])?\s*$ ]]; then
    exit 0
  elif [[ ${answer} =~ ^\s*[nN][oO]?\s*$ ]]; then
    exit 1
  fi
done

