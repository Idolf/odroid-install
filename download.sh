#!/bin/bash

set -eu

. config.sh

if [[ -f debs.tar ]]; then
  debootstrap --unpack-tarball=$PWD/debs.tar --make-tarball=$PWD/debs.tar $DEBOOTSTRAP_ARGS /tmp/target http://auto.mirror.devuan.org/merged
else
  debootstrap --make-tarball=$PWD/debs.tar $DEBOOTSTRAP_ARGS /tmp/target http://auto.mirror.devuan.org/merged
fi
