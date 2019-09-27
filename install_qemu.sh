#!/bin/bash
download_qemu () {
	if [ ! -d $HOME/qemu ]; then
		cd $HOME
		git clone https://git.qemu.org/git/qemu.git
		cd qemu
		git submodule init
		git submodule update --recursive
	else
		echo "Found Qemu source code in the $1"
		cd $HOME/qemu
		echo "Updating qemu"
		git pull origin master
	fi
}

install_qemu () {
	cd $HOME/qemu
	mkdir -p build
	cd $HOME/qemu/build
	../configure --target-list="$1"
	make -j 4
	sudo make install
}

install_debian_arm () {
	mkdir -p $HOME/debian/arm
	cd $HOME/debian/arm

	if [ ! -f initrd.gz ]; then
		wget -O initrd.gz http://ftp.debian.org/debian/dists/oldstable/main/installer-armhf/current/images/netboot/initrd.gz
	fi
	if [ ! -f vmlinuz ]; then
		wget -O vmlinuz http://ftp.debian.org/debian/dists/oldstable/main/installer-armhf/current/images/netboot/vmlinuz
	fi

	# Create an qcow2 format image with 5G of storage:
	qemu-img create -f qcow2 hda.qcow2 5G

	# Install mips debian
	qemu-system-arm -M virt \
		-m 2048 \
		-kernel vmlinuz \
		-initrd initrd.gz \
		-drive if=none,file=hda.qcow2,format=qcow2,id=hd \
		-device virtio-blk-device,drive=hd \
		-netdev user,id=mynet \
		-device virtio-net-device,netdev=mynet \
		-no-reboot
}

install_debian_arm64 () {
	if [ ! -f initrd.gz ]; then
		wget -O initrd.gz http://ftp.debian.org/debian/dists/oldstable/main/installer-arm64/current/images/netboot/debian-installer/arm64/initrd.gz
	fi
	if [ ! -f linux ]; then
		wget -O linux http://ftp.debian.org/debian/dists/oldstable/main/installer-arm64/current/images/netboot/debian-installer/arm64/linux
	fi

	mkdir -p $HOME/debian/aarch64
	cd $HOME/debian/aarch64

	# Create an qcow2 format image with 2G of storage:
	qemu-img create -f qcow2 hda.img 2G

	# Install mips debian
	qemu-system-aarch64 -M virt \
		-m 2048 -hda hda.img \
		-kernel linux \
		-initrd initrd.gz \
		-append "console=ttyS0 nokaslr" \
		-nographic
}

install_debian_mipsel () {
	if [ ! -f initrd.gz ]; then
		wget -O initrd.gz http://ftp.debian.org/debian/dists/oldstable/main/installer-mipsel/current/images/malta/netboot/initrd.gz
	fi
	if [ ! -f vmlinux-4.9.0-9-4kc-malta ]; then
		wget -O vmlinux-4.9.0-9-4kc-malta http://ftp.debian.org/debian/dists/oldstable/main/installer-mipsel/current/images/malta/netboot/vmlinux-4.9.0-9-4kc-malta
	fi

	mkdir -p $HOME/debian/mipsel
	cd $HOME/debian/mipsel

	# Create an qcow2 format image with 2G of storage:
	qemu-img create -f qcow2 hda.img 2G

	# Install mips debian
	qemu-system-mipsel -M malta \
		-m 2048 -hda hda.img \
		-kernel vmlinux-4.9.0-9-4kc-malta \
		-initrd initrd.gz \
		-append "console=ttyS0 nokaslr" \
		-nographic
}

extract_bootloader_debian_mipsel () {
	cd $HOME/debian/mipsel
	HDA=hda.img
	if [ -f $HDA ]; then
		# mounting the mipsel disk
		sudo modprobe nbd max_port=63
		sudo qemu-nbd -c /dev/nbd0 $HDA
		sudo mkdir -p /mnt/tmp
		sudo mount /dev/nbd0p1 /mnt/tmp

		# Copying the bootloader
		cp -r /mnt/tmp/boot/initrd.img-4.9.0-9-4kc-malta .

		# Unmounting the disk
		sudo umount /mnt/tmp
		sudo qemu-nbd -d /dev/nbd0
	fi
}

run_qemu_arm () {
	cd $HOME/debian/arm
	qemu-system-arm -M virt -m 1024 \
		-kernel vmlinuz-4.9.0-11-armmp-lpae \
		-initrd initrd.img-4.9.0-11-armmp-lpae \
		-append 'root=/dev/vda2' \
		-drive if=none,file=hda.qcow2,format=qcow2,id=hd \
		-device virtio-blk-device,drive=hd \
		-netdev user,id=mynet,hostfwd=tcp::5555-:22,hostfwd=tcp::1234-:1234 \
		-device virtio-net-device,netdev=mynet  

	# Important note:
	# After running guest, we probably need to run following commands:
	# ifconfig enp0s19 down
	# ifconfig enp0s19 10.0.2.15 netmask 255.255.255.0
	# ifconfig enp0s19 up
	# route add default gw 10.0.2.2

	# vi /etc/ssh/sshd_config
	# change PasswordAuthentication yes
	# change PermitRootLogin yes
	# service ssh restart

	# HOW TO CONNECT FROM HOST:
	# ssh root@localhost -p5555

	# RUNNING GDBSERVER
	# apt install gdb gdbserver
	# gdbserver localhost:1234 {filename}
	
}

run_qemu_mipsel () {
	cd $HOME/debian/mipsel
	qemu-system-mipsel -M malta \
		-m 1024 -hda hda.img \
		-kernel vmlinux-4.9.0-9-4kc-malta \
		-initrd initrd.img-4.9.0-9-4kc-malta \
		-append "root=/dev/sda1 console=ttyS0 nokaslr" \
		-nographic \
		-netdev user,id=u1,hostfwd=tcp::5555-:22 \
		-device e1000-82545em,netdev=u1

	# Important note:
	# After running guest, we probably need to run following commands:
	# ifconfig enp0s19 down
	# ifconfig enp0s19 10.0.2.15 netmask 255.255.255.0
	# ifconfig enp0s19 up
	# route add default gw 10.0.2.2
}

if [ -z "$1" ]; then
	echo "enter the architecture..."
	echo "eg: ./install_qemu 'mips-softmmu mipsel-softmmu'"
	echo "eg: ./install_qemu 'aarch64-softmmu'"
	echo "eg: ./install_qemu 'arm-softmmu'"
else
	echo "instaling $1"
	# download_qemu
	# install_qemu "$1"
	# install_debian_arm
	run_qemu_arm
	# extract_bootloader_debian_mipsel hda_mipsel.img
	# run_qemu_mipsel
fi
