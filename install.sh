#!/bin/bash

DEBUG="TRUE"

if [ "$DEBUG" = "TRUE" ]; then
	OUTPUT=/dev/stdout
else
	OUTPUT=/dev/stdnull
fi

log () {
	echo -e "\e[33m$1"
	echo $1 &>> $OUTPUT
}

install_build () {
	log "[build-essentials] Installing ..."
	yes | sudo add-apt-repository ppa:ubuntu-toolchain-r/test &>> /dev/null 
	DEPENDENCIES=$(apt-cache depends gcc-9 g++-9 gccgo-9 | grep -i suggests | cut -d' ' -f4 | xargs)
	yes | sudo apt install gcc-9 g++-9 gccgo-9 $DEPENDENCIES &>> $OUTPUT

	log "[build-essentials] Adding symlinks ..."
	sudo ln -s /usr/bin/g++-9 /usr/bin/g++
	sudo ln -s /usr/bin/gcc-9 /usr/bin/gcc
	sudo ln -s /usr/bin/gccgo-9 /usr/bin/gccgo
}

install_code () {
	if [ -z $(which code) ]; then
		log "[code] Installing Vscode ..."
		wget -O /tmp/code.deb https://go.microsoft.com/fwlink/?LinkID=760868 &>> $OUTPUT
		sudo dpkg -i /tmp/code.deb &>> $OUTPUT
	else
		log "[Code] Vscode is already installed."
	fi
}


install_git () {
	log "[git] Installing ..."
        yes | sudo apt-get install git &>> $OUTPUT
}

install_ssh_key () {
	if [ -z $(ls ~/.ssh/) ]; then
		log "[ssh-key] Generating ssh key ..."
		yes "" | ssh-keygen &>> $OUTPUT
	else
		log "[ssh-key] Exists."
	fi
}

install_ubuntu_essentials () {
	log "[update] Updating system ..."
	yes | sudo apt update &>> $OUTPUT
	yes | sudo apt upgrade &>> $OUTPUT

	log "[net-tools] Installing ..."
	yes | sudo apt install net-tools &>> $OUTPUT

	log "[tmux] Installing ..."
	yes | sudo apt install tmux &>> $OUTPUT

	log "[vim] Installing ..."
	yes | sudo apt install vim &>> $OUTPUT

	log "[xclip] Installing ..."
	yes | sudo apt install xclip &>> $OUTPUT

	log "[gnome-tweaks] Installing ..."
	yes | sudo apt install gnome-tweaks &>> $OUTPUT

	log "[cifs-utils] Installing ..."
	yes | sudo apt install cifs-utils &>> $OUTPUT

	install_git
	install_ssh_key

	log "[jre-11] Installing ..."
	yes | sudo apt install openjdk-11-jre openjdk-11-jdk-headless&>> $OUTPUT

	log "[highlight] Installing ..."
	yes | sudo apt install highlight &>> $OUTPUT
	echo "alias dog='highlight -O ansi --force'" >> ~/.bashrc

	log "[htop] Installing ..."
	yes | sudo apt install htop &>> $OUTPUT

	mkdir -p ~/Tools
}

install_ghidra () {
	log "[ghidra] Installing ..."
	wget -O /tmp/ghidra.zip https://ghidra-sre.org/ghidra_9.0.4_PUBLIC_20190516.zip &>> $OUTPUT
	unzip /tmp/ghidra.zip -d ~/Tools &>> $OUTPUT
}

install_go () {
	log "[go 1.12.7] Installing ..."
	wget -O /tmp/go.tar.gz https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz &>> $OUTPUT
	sudo tar -C /usr/local -xzf /tmp/go.tar.gz &>> $OUTPUT
	export PATH=$PATH:/usr/local/go/bin
	echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
}
install_nmap () {
	log "[nmap] Installing ..."
        yes | sudo apt install nmap &>> $OUTPUT
}

install_curl () {
	log "[curl] Installing ..."
        yes | sudo apt install curl &>> $OUTPUT
}

install_pip () {
	log "[pip] Installing ..."
        yes | sudo apt install python-pip python3-pip &>> $OUTPUT
}

install_cpuid () {
	log "[cpuid] Installing ..."
        yes | sudo apt install cpuid &>> $OUTPUT
}

install_cross_compile_arm() {
   yes | sudo apt-get install gcc-arm-linux-gnueabihf binutils-arm-linux-gnueabi 

}

_install_detection () {
	install_nmap
}

_install_development () {
	install_build
	install_curl
	install_pip
}

_install_config_files () {
	cp .vimrc ~/.vimrc
	cp .tmux.conf ~/.tmux.conf
}

# Install packages for development machine
install_development () {
	install_ubuntu_essentials
	_install_development
	_install_config_files
}

# Install packages for detection machine
install_detection () {
	install_ubuntu_essentials
	_install_detection
	install_cpuid
}

install_all () {
	install_ubuntu_essentials
	_install_development
	_install_detection
}


if [ -z $1 ]; then
	echo "./install.sh options"
	echo "OPTIONS: "
	echo "	all"
else
	case $1 in
		all)
			echo "[+] Installing All"
			install_all
			;;
		*)
			install_$1
			;;
	esac
fi
