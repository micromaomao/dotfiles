#!/bin/sh

stty > /dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  echo This script requires interactive input.
  echo 'Please run with `sh <(curl '\''https://dotfiles.mww.moe'\'' -sL)`.'
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo Detected debian $VERSION_ID

  set -xe
  sudo apt update
  sudo apt install -y git curl tmux fish exa htop
  set +xe

  type docker > /dev/null
  if [ $? -ne 0 ]; then
    if [ $VERSION_ID -eq 11 -o $VERSION_ID -eq 10 ]; then
      read -p "Install docker? (y/n) " -r P
      if [ $P = "y" ]; then
        set -xe
        sudo apt-get install ca-certificates gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        sudo chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo chmod a+r /etc/apt/sources.list.d/docker.list
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        set +xe
      fi
    fi
  fi

  type clang > /dev/null
  if [ $? -ne 0 ]; then
    read -p "Install clang? (y/n) " -r P
    if [ $P = "y" ]; then
      set -xe
      sudo apt install -y clang
      set +xe
    fi
  fi

  type rustup > /dev/null
  if [ $? -ne 0 ]; then
    read -p "Install Rust? (y/n) " -r P
    if [ $P = "y" ]; then
      set -xe
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
      set +xe
    fi
  fi
fi

cd ~
if [ ! -d dotfiles ]; then
  set -xe
  git clone --depth=1 https://github.com/micromaomao/dotfiles
  ln -s ~/dotfiles/.config .config
  ln -s dotfiles/.tmux.conf .tmux.conf
  set +xe
fi
set -xe
sudo chsh -s /usr/bin/fish $USER
set +xe

echo "User shell changed to fish. Run 'exec fish' to start now."
