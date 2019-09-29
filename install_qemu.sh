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
    # install prerequisites
    sudo apt-get install git libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev
    sudo apt-get install git-email
    sudo apt-get install libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev
    sudo apt-get install libcap-dev libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev
    sudo apt-get install libibverbs-dev libjpeg8-dev libncurses5-dev libnuma-dev
    sudo apt-get install librbd-dev librdmacm-dev
    sudo apt-get install libsasl2-dev libsdl1.2-dev libseccomp-dev libsnappy-dev libssh2-1-dev
    sudo apt-get install libvde-dev libvdeplug-dev libvte-2.90-dev libxen-dev liblzo2-dev
    sudo apt-get install valgrind xfslibs-dev 
    sudo apt-get install libnfs-dev libiscsi-dev

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
        wget -O initrd.gz http://ftp.debian.org/debian/dists/oldoldstable/main/installer-armhf/current/images/netboot/initrd.gz
    fi
    if [ -z $1 ]; then
		KERNEL_PATH=vmlinuz
		if [ ! -f vmlinuz ]; then
			wget -O vmlinuz http://ftp.debian.org/debian/dists/stable/main/installer-armhf/current/images/netboot/vmlinuz
		fi
	else
		KERNEL_PATH=$1
	fi
    # Create an qcow2 format image with 5G of storage:
    qemu-img create -f qcow2 hda.qcow2 5G

    # Install mips debian
    qemu-system-arm -M virt \
        -m 2048 \
        -kernel $KERNEL_PATH \
        -initrd initrd.gz \
        -drive if=none,file=hda.qcow2,format=qcow2,id=hd \
        -device virtio-blk-device,drive=hd \
        -netdev user,id=mynet \
        -device virtio-net-device,netdev=mynet \
        -no-reboot -nographic
}

install_openwrt32 () {
    mkdir -p $HOME/openwrt32
    cd $HOME/openwrt32

    if [ ! -f openwrt-armvirt-32-zImage-initramfs ]; then
        wget -O openwrt-armvirt-32-zImage-initramfs https://downloads.openwrt.org/snapshots/targets/armvirt/32/openwrt-armvirt-32-zImage-initramfs 
    fi
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

run_qemu_openwrt32 () {
    cd $HOME/openwrt32	
    # Openwrt arch needs two network card to work
    qemu-system-arm -M virt -m 1024 \
	-kernel openwrt-armvirt-32-zImage-initramfs \
        -netdev user,id=id0,hostfwd=tcp::5555-:22,hostfwd=tcp::1234-:1234 \
        -device virtio-net-device,netdev=id0 \
        -netdev user,id=id1 \
        -device virtio-net-device,netdev=id1  

    # After running guest, we probably need to run following commands:
    # opkg update
    # opkg install gdb gdbserver binutils strace
}

run_qemu_arm () {
    cd $HOME/debian/arm
    echo $1
    # qemu-system-arm -M virt -m 1024 \
    #     -kernel vmlinuz-4.9.0-11-armmp-lpae \
    #     -initrd initrd.img-4.9.0-11-armmp-lpae \
    #     -append 'root=/dev/vda2' \
    #     -drive if=none,file=hda.qcow2,format=qcow2,id=hd \
    #     -device virtio-blk-device,drive=hd \
    #     -netdev user,id=mynet,hostfwd=tcp::5555-:22,hostfwd=tcp::1234-:1234 \
    #     -device virtio-net-device,netdev=mynet  

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
    # install_openwrt32
    # run_qemu_openwrt32
    KERNEL_PATH=$HOME'/kernel/linux-3.16.74/arch/arm/boot/zImage'
	install_debian_arm $KERNEL_PATH
    # run_qemu_arm $KERNEL_PATH
    # extract_bootloader_debian_mipsel hda_mipsel.img
    # run_qemu_mipsel
fi
