#!/bin/bash
install_kernel () {
	sudo apt install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev
	sudo apt install coreutils texi2html docbook-utils python-pysqlite2 help2man make gcc g++ desktop-file-utils libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake groff curl lzop asciidoc u-boot-tools
	sudo apt install libncurses5-dev libncursesw5-dev

	git clone --depth=1 -b rpi-4.9.y https://github.com/raspberrypi/linux.git ~/.
	git clone https://github.com/raspberrypi/tools.git ~/tools

	cd ~/linux
	export PATH=~/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:$PATH
	export TOOLCHAIN=~/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/
	export CROSS_COMPILE=arm-linux-gnueabihf-
	export ARCH=arm

	make mrproper
	KERNEL=kernel7
	make ARCH=arm bcm2709_defconfig
	make ARCH=arm menuconfig

	make -j4
}

copy_kernel () {
	cd ~/linux
	sudo mkdir -p /mnt/fat32
	sudo mkdir -p /mnt/ext4
	sudo mount /dev/mmcblk0p1 /mnt/fat32
	sudo mount /dev/mmcblk0p2 /mnt/ext4
	# For more options and information see
	# http://rpf.io/configtxt
	# Some settings may impact device functionality. See link above for details

	sudo rm /mnt/fat32/config.txt

	echo "dtparam=audio=on" | sudo tee -a /mnt/fat32/config.txt
	echo "dtparam=i2c_arm=on" | sudo tee -a /mnt/fat32/config.txt
	echo "dtparam=spi=on" | sudo tee -a /mnt/fat32/config.txt
	echo "dtoverlay=spi0-cs" | sudo tee -a /mnt/fat32/config.txt
	echo "# Enable UART" | sudo tee -a /mnt/fat32/config.txt
	echo "enable_uart=1" | sudo tee -a /mnt/fat32/config.txt
	# echo "kernel=kernel7.img" | sudo tee -a /mnt/fat32/config.txt
	echo "kernel=kernel-rpi.img" | sudo tee -a /mnt/fat32/config.txt
	echo "device_tree=bcm2710-rpi-3-b.dtb" | sudo tee -a /mnt/fat32/config.txt
	echo "boot_delay=1" | sudo tee -a /mnt/fat32/config.txt

	echo "[pi4]" | sudo tee -a /mnt/fat32/config.txt
        echo "dtoverlay=vc4-fkms-v3d" | sudo tee -a /mnt/fat32/config.txt
        echo "max_framebuffers=2" | sudo tee -a /mnt/fat32/config.txt

	sudo cp arch/arm/boot/zImage /mnt/fat32/kernel-rpi.img
	sudo cp arch/arm/boot/dts/*.dtb /mnt/fat32/
	sudo cp arch/arm/boot/dts/overlays/*.dtb* /mnt/fat32/overlays/
	sudo cp arch/arm/boot/dts/overlays/README /mnt/fat32/overlays/

	sudo make ARCH=arm INSTALL_MOD_PATH=/mnt/ext4 modules_install

	sudo umount /mnt/fat32
	sudo umount /mnt/ext4

}

# First you need to install the latest version of the rasberian.


# Building Kernel
# install_kernel

# Now kernel is needed to be copied into the SD card.
copy_kernel
