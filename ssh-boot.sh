#!/bin/sh
exec ssh odroid-boot '/sbin/cryptsetup open /dev/mmcblk*p2 rootfs && ((sleep 1; /bin/killall -9 sh) &) && echo done' < ~/git/odroid-install/keyfile
