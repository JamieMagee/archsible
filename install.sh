#!/usr/bin/env bash

#----------------------------------------------------------------------
# Arch Linux Installation Script
#
# This installs, with no intervention, Arch Linux
# on an encrypted btrfs partition
#----------------------------------------------------------------------

set -eu

#----------------------------------------------------------------------
# DRIVE & SCRIPT VALUES
#----------------------------------------------------------------------

DRIVE=/dev/sda

# script values
HOST=deadbeef # this will get changed later by ansible anyway
USER=jamie
MOUNT=/mnt
MOUNTOPTS=defaults,x-mount.mkdir
BTRFSOPTS=$MOUNTOPTS,ssd,noatime,nodiratime,discard,compress-force=zstd

#----------------------------------------------------------------------
# preflight cleanup
#----------------------------------------------------------------------

[ -n "${SWAP:=$(swapon --noheadings --show=NAME)}" ] && swapoff $SWAP
umount /mnt/boot || :
umount -R /mnt || :
for MAPPED in $(ls /dev/mapper); do [ "$MAPPED" != "control" ] && cryptsetup close /dev/mapper/$MAPPED || : ; done

#----------------------------------------------------------------------
# optional: secure wipe of drive (takes a while)
#----------------------------------------------------------------------

# sgdisk --zap-all /dev/device
# cryptsetup open --type plain /dev/device container --key-file /dev/random
# dd if=/dev/zero of=/dev/mapper/container status=progress
# cryptsetup close container

#----------------------------------------------------------------------
# Create Partitions
#----------------------------------------------------------------------

# NOTE: EFI partition should be at least 550MiB according to
# http://www.rodsbooks.com/efi-bootloaders/principles.html

sgdisk --zap-all $DRIVE

sgdisk --clear \
  --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:EFI \
  --new=2:0:+8GiB --typecode=2:8200 --change-name=2:cryptswap \
  --new=3:0:0 --typecode=3:8300 --change-name=3:cryptsystem \
  $DRIVE
#----------------------------------------------------------------------
#
#----------------------------------------------------------------------

# get passphrase
while ! ${MATCH:-false}; do
  echo -en "Enter Passphrase   : "
  read -rs PASS
  echo -en "\nConfirm Passphrase : "
  read -rs CONF
  [ "$PASS" = "$CONF" ] &&
    {
      MATCH=true
      echo -e "\n\nPassphrases matched.\n"
    } ||
    echo -e "\n\nPassphrases didn't match--try again.\n"
done

# encrypt cryptsystem partition with passphrase
echo $PASS | cryptsetup luksFormat --align-payload=8192 -s 256 -c aes-xts-plain64 /dev/disk/by-partlabel/cryptsystem
echo $PASS | cryptsetup open /dev/disk/by-partlabel/cryptsystem system

#----------------------------------------------------------------------
# Format & Mount Partitions
#----------------------------------------------------------------------

mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI

mkfs.btrfs --force --label system /dev/mapper/system

# mount btrfs top-level subvolume for further subvolume creation
mount -t btrfs -o $BTRFSOPTS LABEL=system $MOUNT
btrfs subvolume create $MOUNT/root
btrfs subvolume create $MOUNT/home
umount -R $MOUNT

# remount subvolumes
mount -t btrfs -o $BTRFSOPTS,subvol=root LABEL=system $MOUNT
mount -t btrfs -o $BTRFSOPTS,subvol=home LABEL=system $MOUNT/home

# mount EFI
mount -o $MOUNTOPTS LABEL=EFI $MOUNT/boot

# make and activate swap
cryptsetup open --type plain --key-file /dev/urandom /dev/disk/by-partlabel/cryptswap swap
mkswap -L swap /dev/mapper/swap
swapon -L swap

#----------------------------------------------------------------------
# Install Base System
#----------------------------------------------------------------------

# install base system
pacstrap $MOUNT base base-devel btrfs-progs terminus-font efibootmgr intel-ucode git

# generate fstab
genfstab -L -p $MOUNT >>$MOUNT/etc/fstab

# remove the subvolume ID element of the fstab statements to
# allow mounting by subvolume name only (to facilitate rollbacks)
sed -i 's/,subvolid=[[:digit:]]*//g' $MOUNT/etc/fstab

# enter swap into crypttab
echo 'swap    /dev/disk/by-partlabel/cryptswap    /dev/urandom    swap,cipher=aes-xts-plain64,size=256' >>$MOUNT/etc/crypttab

# make sure we have a crypttab.initramfs as well
echo 'swap    /dev/disk/by-partlabel/cryptswap    /dev/urandom    swap,cipher=aes-xts-plain64,size=256' >$MOUNT/etc/crypttab.initramfs

# remove LABEL identifier for swap in fstab as it may/will not have a label from crypttab
sed -i 's+LABEL=swap+/dev/mapper/swap+' $MOUNT/etc/fstab

#----------------------------------------------------------------------
# Prepare chroot script
#----------------------------------------------------------------------

cat >$MOUNT/setup.sh <<EOFSETUP
#!/usr/bin/env bash
set -eu

HOST=$HOST
USER=$USER
# get partition UUIDs (have to do this before entering chroot since lsblk won't report there)
CRYPTSWAP_UUID=$(lsblk --nodeps --noheadings -oUUID /dev/disk/by-partlabel/cryptswap)
CRYPTSYSTEM_UUID=$(lsblk --nodeps --noheadings -oUUID /dev/disk/by-partlabel/cryptsystem)

EOFSETUP

cat >>$MOUNT/setup.sh <<'EOFSETUP'
setfont ter-u18n
echo "FONT=ter-u18n" > /etc/vconsole.conf
echo "KEYMAP=uk" >> /etc/vconsole.conf
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
export LANG=en_GB.UTF-8
mv /etc/localtime /etc/localtime.orig
ln -s /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime
hwclock --systohc --utc
echo $HOST > /etc/hostname
#edit /etc/hosts the same way... see beginners guide
mv /etc/hosts /etc/hosts.orig
cat > /etc/hosts <<EOF
#
# /etc/hosts: static lookup table for host names
#
#<ip-address> <hostname.domain.org> <hostname>
127.0.0.1 localhost.localdomain localhost
::1 	localhost.localdomain localhost
127.0.0.1 $HOST.localdomain $HOST
::1 	$HOST.localdomain	$HOST
# End of file
EOF
# add user, set passwords
useradd -m -G wheel $USER
while ! ${MATCH:-false}
do
	echo -en "Enter Initial Root/User Passphrase   : "
	read -rs PASS
	echo -en "\nConfirm Passphrase : "
	read -rs CONF
	[ "$PASS" = "$CONF" ] \
		&& { MATCH=true; echo -e "\n\nPassphrases matched.\n"; } \
		|| echo -e "\n\nPassphrases didn't match--try again.\n"
done
for ACCOUNT in root $USER; do
    echo "$ACCOUNT:$PASS" | chpasswd
done
# enable sudo for wheel
tmpfile=$(mktemp)
echo "%wheel ALL=(ALL) ALL" > $tmpfile
visudo -cf $tmpfile \
    && mv $tmpfile /etc/sudoers.d/wheel \
    || { echo "ERROR updating sudoers; no change made"; exit 1; }
# reconfigure and regenerate initrams
mv /etc/mkinitcpio.conf /etc/mkinitcpio.orig
cat > /etc/mkinitcpio.conf << EOF
#MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
BINARIES="/usr/bin/btrfs"
FILES=""
HOOKS="base systemd sd-vconsole modconf keyboard block filesystems btrfs sd-encrypt fsck"
EOF
mkinitcpio -p linux
# remove exiting boot entry
EXISTINGENTRY=$(efibootmgr | grep "Linux Boot Manager" | cut -d " " -f 1 | sed "s/[^[:digit:]]*//g" | head -n1)
[ -n "$EXISTINGENTRY" ] && efibootmgr -b$EXISTINGENTRY -B
# install bootloader ( || : to swallow error code... this seems to return one even on success?)
bootctl --path=/boot install || :
# configure loader defaults
cat > /boot/loader/loader.conf <<EOF
default      arch
timeout      2
console-mode max
editor       0
EOF
# configure initial entry
# TODO: try PARTLABEL in lieu of UUID
cat > /boot/loader/entries/arch.conf <<EOF
title      Arch Linux
linux      /vmlinuz-linux
initrd     /intel-ucode.img
initrd     /initramfs-linux.img
options    \
rd.luks.name=$CRYPTSYSTEM_UUID=system1 \
root=LABEL=system rootflags=subvol=/root rw x-systemd.device-timeout=0 \
apparmor=1,security=apparmor \
quiet loglevel=3 rd.systemd.show_status=auto rd.udev.log_priority=3
EOF
cat > /boot/loader/entries/arch_fallback.conf <<EOF
title      Arch Linux Fallback
linux      /vmlinuz-linux
initrd     /intel-ucode.img
initrd     /initramfs-linux-fallback.img
options    \
rd.luks.name=$CRYPTSYSTEM_UUID=system1 \
root=LABEL=system rootflags=subvol=/root rw x-systemd.device-timeout=0 \
apparmor=1,security=apparmor \
quiet loglevel=3 rd.systemd.show_status=auto rd.udev.log_priority=3
EOF
echo "use efibootmgr to ensure correct entry for systemd-boot is present, active, and in bootorder"
# add new efi boot entry
NEWENTRY=$(efibootmgr | grep "Linux Boot Manager" | cut -d " " -f 1 | sed "s/[^[:digit:]]*//g" | tail -n1)
BOOTORDER=$(efibootmgr | grep BootOrder | cut -d " " -f 2)
efibootmgr -o$NEWENTRY,$BOOTORDER

EOFSETUP

#----------------------------------------------------------------------
# Execute chroot script
#----------------------------------------------------------------------

chmod +x $MOUNT/setup.sh

arch-chroot $MOUNT sh -c '/setup.sh'

#----------------------------------------------------------------------
# Post reboot installation
#----------------------------------------------------------------------

cat > $MOUNT/install.sh <<EOFINSTALL
#!/bin/sh
set -eu

sudo rm /setup.sh

mkdir -p ~/.config/lpass
mkdir -p ~/.local/share/lpass

sudo pacman -S lastpass-cli ansible

lpass login jamie.magee@gmail.com

mkdir code
cd code
git clone https://github.com/JamieMagee/archsible.git
cd archsible

lpass show Secure\ Notes Ansible --notes > vault-pass.txt
ansible-galaxy install -r requirements.yml -p galaxy

echo "run sudo ansible-playbook playbooks/<playbook>.yml"

EOFINSTALL