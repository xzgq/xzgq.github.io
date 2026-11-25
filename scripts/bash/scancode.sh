#!/usr/bin/env bash

if ! [ -d "$1" ]; then
  echo "请指定源代码目录"
  exit
fi
scancode -clpieu --license-text --json-pp "$1.json" --spdx-tv "$1.spdx" $1
