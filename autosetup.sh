#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use sudo." 
   exit 1
fi

echo "Starting setup..."

# Get the non-root username
NON_ROOT_USER=$(logname)

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Install core tools
echo "Installing core tools..."
apt install -y build-essential curl wget git vim neovim tmux zsh

# Install Docker
echo "Installing Docker..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
  apt-get remove -y $pkg 
done

apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create the docker group if it doesn't exist
if ! getent group docker > /dev/null; then
  echo "Creating 'docker' group..."
  groupadd docker
else
  echo "'docker' group already exists. Skipping group creation."
fi

# Add the current user to the docker group
usermod -aG docker $NON_ROOT_USER

# Apply the new group membership
newgrp docker

# Install Postman
echo "Installing Postman..."
sudo snap install postman

# Install Visual Studio Code
echo "Installing Visual Studio Code..."
sudo snap install code --classic

# Install DBeaver
echo "Installing DBeaver..."
sudo snap install dbeaver-ce

# Install Oh My Zsh for the non-root user
echo "Installing Oh My Zsh..."
sudo -u $NON_ROOT_USER sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh-syntax-highlighting for the non-root user
echo "Installing zsh-syntax-highlighting..."
ZSH_CUSTOM="/home/$NON_ROOT_USER/.oh-my-zsh/custom"
sudo -u $NON_ROOT_USER mkdir -p $ZSH_CUSTOM/plugins
sudo -u $NON_ROOT_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Add the plugin to .zshrc if not already added
ZSHRC_PATH="/home/$NON_ROOT_USER/.zshrc"
if ! sudo -u $NON_ROOT_USER grep -q "zsh-syntax-highlighting" $ZSHRC_PATH; then
  sudo -u $NON_ROOT_USER sed -i '/plugins=(/ s/)/ zsh-syntax-highlighting)/' $ZSHRC_PATH
fi

# Install OpenVPN3
echo "Installing OpenVPN3..."
apt update && apt install -y apt-transport-https
wget -qO - https://packages.openvpn.net/packages-repo.gpg | gpg --dearmor -o /usr/share/keyrings/openvpn.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openvpn.asc] https://packages.openvpn.net/openvpn3/debian $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/openvpn3.list
apt update
apt install -y openvpn3

# Prompt user for OVPN_FILE_PATH
read -p "Enter the path to your OpenVPN configuration file (.ovpn): " OVPN_FILE_PATH

# Export the OVPN_FILE_PATH variable and set up aliases
echo "Setting up OpenVPN aliases..."
echo "export OVPN_FILE_PATH=${OVPN_FILE_PATH}" >> $ZSHRC_PATH
echo 'alias vpn-up="vpn-down ; openvpn3 session-start --config $OVPN_FILE_PATH"' >> $ZSHRC_PATH
echo 'alias vpn-down="openvpn3 session-manage --config $OVPN_FILE_PATH --disconnect"' >> $ZSHRC_PATH
echo 'alias vpn-status="openvpn3 sessions-list"' >> $ZSHRC_PATH

# Copy configuration files
echo "Copying configuration files..."
cp shell/.tmux.conf "/home/$NON_ROOT_USER/"
cp shell/.zshrc "/home/$NON_ROOT_USER/"

# Ensure proper ownership of files for the non-root user
chown $NON_ROOT_USER:$NON_ROOT_USER "/home/$NON_ROOT_USER/.tmux.conf" "/home/$NON_ROOT_USER/.zshrc"

# Change default shell to Zsh for the non-root user
echo "Changing default shell to Zsh..."
chsh -s $(which zsh) $NON_ROOT_USER

echo "Setup complete. Please restart your terminal or system for all changes to take effect."
