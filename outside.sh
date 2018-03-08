#!/bin/bash

set -eu

. config.sh


function unmount_all_target() {
    if grep -q ' /target ' /proc/mounts; then
      umount -R /target
    fi
    cryptsetup luksClose target-rootfs || true
}

unmount_all_target

dd if=/dev/zero of=$DISK bs=1M count=5

(fdisk $DISK || true) <<EOF
n
p
1

+200M

n
p
2


t
1
83

t
2
83
w
EOF

dd if=/dev/zero of=${DISK}p1 bs=1M count=5
dd if=/dev/zero of=${DISK}p2 bs=1M count=5

mkfs.ext4 ${DISK}p1

if [[ $CRYPTO = 1 ]]; then
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 128 > keyfile
    chown idolf: keyfile
    echo YES | cryptsetup luksFormat --iter-time 100 ${DISK}p2 keyfile
    cryptsetup luksOpen ${DISK}p2 target-rootfs --key-file ./keyfile
    mkfs.ext4 /dev/mapper/target-rootfs
else
    mkfs.ext4 ${DISK}p2
fi

rm -rf /target || true
mkdir -p /target

if [[ $CRYPTO = 1 ]]; then
    mount /dev/mapper/target-rootfs /target
else
    mount ${DISK}p2 /target
fi
mkdir -p /target/boot

mount ${DISK}p1 /target/boot

qemu-debootstrap --unpack-tarball=$PWD/debs.tar $DEBOOTSTRAP_ARGS /target http://auto.mirror.devuan.org/merged

mount -t proc proc /target/proc
mount -o bind /dev /target/dev
mount -o bind /dev/pts /target/dev/pts || true
mount -o bind /dev/shm /target/dev/shm || true

cat > /target/etc/apt/apt.conf.d/01lean <<EOF
APT::Install-Suggests "0";
APT::Install-Recommends "0";
APT::AutoRemove::SuggestsImportant "false";
APT::AutoRemove::RecommendsImportant "false";
EOF

cat > /target/etc/apt/sources.list <<EOF
deb http://auto.mirror.devuan.org/merged ascii main
deb http://auto.mirror.devuan.org/merged ascii-updates main
deb http://auto.mirror.devuan.org/merged ascii-security main
EOF

cat > /target/etc/network/interfaces.d/eth0 <<EOF
allow-hotplug eth0
iface eth0 inet static
    address 192.168.8.30/24
    gateway 192.168.8.1
EOF

cat > /target/etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

sed -i "s/\blocalhost\b/localhost $HOSTNAME/g" /target/etc/hosts
sed -i 's/^\(%sudo\s.*\)ALL$/\1 NOPASSWD: ALL/' /target/etc/sudoers
sed -i 's/.*en_US.UTF-8 UTF-8.*/en_US.UTF-8 UTF-8/g' /target/etc/locale.gen
echo $HOSTNAME > /target/etc/hostname
echo UseDNS no >> /target/etc/ssh/sshd_config
sed -i 's/^exit 0$//' /target/etc/rc.local
echo ntpdate 0.dk.pool.ntp.org 1.dk.pool.ntp.org 2.dk.pool.ntp.org 3.dk.pool.ntp.org >> /target/etc/rc.local

if [[ $CRYPTO = 1 ]]; then
    UUID=$(tune2fs -l /dev/mapper/target-rootfs | awk '/^Filesystem UUID:/ { print $3 }')
else
    UUID=$(tune2fs -l ${DISK}p2 | awk '/^Filesystem UUID:/ { print $3 }')
fi
BOOT_UUID=$(tune2fs -l ${DISK}p1 | awk '/^Filesystem UUID:/ { print $3 }')
sed -e "s/{{UUID}}/$UUID/" boot.ini > /target/boot/boot.ini

cat > /target/etc/fstab <<EOF
UUID=$UUID / ext4 discard,noatime,errors=remount-ro 0 1
UUID=$BOOT_UUID /boot ext4 discard,noatime 0 2
EOF

sed -i -e 's/configure_networking/(sleep 3; configure_networking)/g' /target/usr/share/initramfs-tools/scripts/init-premount/dropbear
echo smsc95xx >> /target/etc/initramfs-tools/modules

cp -r inside.sh /target

mkdir -p /target/home/idolf-ssh
cat /home/idolf/.ssh/keys/odroid.pub > /target/home/idolf-ssh/authorized_keys
cat /home/idolf/.ssh/keys/odroid-rsa.pub > /target/etc/dropbear-initramfs/authorized_keys
echo CRYPTSETUP=y >> /target/etc/cryptsetup-initramfs/conf-hook

chroot /target /usr/bin/qemu-arm-static /bin/bash /inside.sh

unmount_all_target
