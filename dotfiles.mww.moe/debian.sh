#!/bin/bash

set -xe

sudo apt update
sudo apt install -y git curl tmux fish exa htop
cd ~
git clone --depth=1 https://github.com/micromaomao/dotfiles
ln -s ~/dotfiles/.config .config
ln -s dotfiles/.tmux.conf .tmux.conf
sudo chsh -s /usr/bin/fish $USER
