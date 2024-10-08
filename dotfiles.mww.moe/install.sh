#!/bin/sh

stty > /dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  echo This script requires interactive input.
  echo 'Please run with `sh <(curl '\''https://dotfiles.mww.moe'\'' -sL)`.'
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo Detected $ID $VERSION_ID

  if [ $ID = "debian" ] || [ $ID = "ubuntu" ]; then
    set -xe
    sudo apt update
    sudo apt install -y git curl tmux fish exa htop kitty-terminfo
    set +xe
  else
    echo "Unsupported OS."
    exit 1
  fi

  type docker > /dev/null
  if [ $? -ne 0 ]; then
    if [ $ID = "debian" ]; then
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
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        set +xe
      fi
    fi
    if [ $ID = "ubuntu" ]; then
      read -p "Install docker? (y/n) " -r P
      if [ $P = "y" ]; then
        set -xe
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
