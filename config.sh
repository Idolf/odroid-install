HOSTNAME=nanopi
DISK=/dev/mmcblk0
# DISK=/dev/loop0
LOOPFILE=/tmp/loopfile
CRYPTO=1

PACKAGES='
build-essential
busybox
ca-certificates
console-setup
coreutils
cryptsetup
devuan-keyring
dkms
dropbear-initramfs
e2fsprogs
ethtool
gcc
git
initramfs-tools
iproute2
isc-dhcp-client
iw
kbd
less
libblkid-dev
libc6-dev
locales
make
ntpdate
openssh-server
procps
python2.7
python-yaml
rsyslog
sudo
u-boot
u-boot-tools
udhcpc
vim
wireless-tools
wpasupplicant
'
PACKAGES=$(echo $PACKAGES | tr ' ' ,)

DEBOOTSTRAP_ARGS="--arch armhf --keyring $PWD/devuan-archive-keyring.gpg --include=$PACKAGES ascii"
