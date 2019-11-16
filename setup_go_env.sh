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
        

# Installing essentials
log "[esn] Installing ..."
yes | sudo apt-get install git tmux vim xclip curl yarn nodejs &>> $OUTPUT

# Installing Go
# log "[go 1.12.7] Installing ..."
# wget -O /tmp/go.tar.gz https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz &>> $OUTPUT
# sudo tar -C /usr/local -xzf /tmp/go.tar.gz &>> $OUTPUT
# export PATH=$PATH:/usr/local/go/bin
# echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc

cp .vimrc_go ~/.vimrc
vim +PlugInstall
vim +GoInstallBinaries
cp coc-settings.json ~/.vim/
