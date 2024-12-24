#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use sudo." 
   exit 1
fi

echo "Starting setup..."

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Install core tools
echo "Installing core tools..."
apt install -y build-essentials curl wget git vim neovim tmux zsh

# Install Docker
echo "Installing Docker..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get update
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

sudo groupadd docker

sudo usermod -aG docker $USER

newgrp docker

# Install Postman
echo "Installing Postman..."
snap install postman

# Install Visual Studio Code
echo "Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
add-apt-repository "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
apt update && apt install -y code

# Install DBeaver
echo "Installing DBeaver..."
wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor -o /usr/share/keyrings/dbeaver-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/dbeaver-archive-keyring.gpg] https://dbeaver.io/debs/dbeaver-ce $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/dbeaver.list
apt update && apt install -y dbeaver-ce

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Copy configuration files
echo "Copying configuration files..."
cp shell/.tmux.conf ~/
cp shell/.zshrc ~/

# Change default shell to Zsh
echo "Changing default shell to Zsh..."
chsh -s $(which zsh)

echo "Setup complete. Please restart your terminal or system for all changes to take effect."
