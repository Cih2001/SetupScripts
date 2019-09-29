export ARCH=arm
export CC=arm-linux-gnueabihf
export KERNEL_MAJOR=3
export KERNEL_MINOR=16.74

install_cross_compile () {
	echo "installing"
	apt-get install gcc-$CC bc
}

download_kernel () {
	mkdir -p $DIR
	cd $HOME/kernel

	FILE=linux-$KERNEL_VERSION.tar.xz
    if [ ! -f $FILE ]; then
		wget https://cdn.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR.x/linux-$KERNEL_VERSION.tar.xz
		tar -xf $FILE
	fi
}

make_kernel () {
	cd $DIR
	make mrproper
	make ARCH=$ARCH vexpress_defconfig
	make -j4
}

export KERNEL_VERSION=$KERNEL_MAJOR.$KERNEL_MINOR
export CROSS_COMPILE=$CC-
export DIR=$HOME/kernel/linux-$KERNEL_VERSION

install_cross_compile
download_kernel
make_kernel
