#!/bin/sh
exec ssh nanopi-boot '/sbin/cryptsetup open /dev/mmcblk0p2 rootfs && ((sleep 1; /bin/killall -9 sh) &) && echo done' < ~/git/nanopi-install/keyfile
