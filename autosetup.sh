#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Variables
NON_ROOT_USER=$(logname)
USER_HOME="/home/$NON_ROOT_USER"
ZSHRC_PATH="$USER_HOME/.zshrc"

echo "Starting environment setup..."

# Step 1: Update and Upgrade System
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Step 2: Install Core Tools
echo "Installing core tools..."
apt install -y build-essential curl wget git vim neovim tmux zsh apt-transport-https ca-certificates software-properties-common

# Step 3: Install Docker
echo "Installing Docker..."
apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add Docker group
if ! getent group docker > /dev/null; then
    groupadd docker
fi
usermod -aG docker $NON_ROOT_USER

# Step 4: Install Snap-based Applications
echo "Installing Postman, VS Code, and DBeaver..."
snap install postman
snap install code --classic
snap install dbeaver-ce

# Step 5: Install OpenVPN3
echo "Installing OpenVPN3..."
wget -qO - https://packages.openvpn.net/packages-repo.gpg | gpg --dearmor -o /usr/share/keyrings/openvpn.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openvpn.asc] https://packages.openvpn.net/openvpn3/debian $(lsb_release -cs) main" > /etc/apt/sources.list.d/openvpn3.list
apt update
apt install -y openvpn3

# Step 6: Install Oh My Zsh
echo "Installing Oh My Zsh for user $NON_ROOT_USER..."
sudo -u $NON_ROOT_USER sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Step 7: Install Zsh Plugins (zsh-syntax-highlighting)
echo "Installing Zsh plugins..."

# Install zsh-syntax-highlighting using its official instructions
sudo -u $NON_ROOT_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $USER_HOME/zsh-syntax-highlighting
sudo -u $NON_ROOT_USER bash -c "echo 'source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> $ZSHRC_PATH"

# Install zsh-autosuggestions
sudo -u $NON_ROOT_USER git clone https://github.com/zsh-users/zsh-autosuggestions.git $USER_HOME/zsh-autosuggestions
echo "source $USER_HOME/zsh-autosuggestions/zsh-autosuggestions.zsh" >> $ZSHRC_PATH

# Step 8: Configure OpenVPN Aliases
echo "Setting up OpenVPN aliases..."
read -p "Enter the path to your OpenVPN configuration file (.ovpn): " OVPN_FILE_PATH
echo "export OVPN_FILE_PATH=${OVPN_FILE_PATH}" >> $ZSHRC_PATH
echo 'alias vpn-up="vpn-down ; openvpn3 session-start --config $OVPN_FILE_PATH"' >> $ZSHRC_PATH
echo 'alias vpn-down="openvpn3 session-manage --config $OVPN_FILE_PATH --disconnect"' >> $ZSHRC_PATH
echo 'alias vpn-status="openvpn3 sessions-list"' >> $ZSHRC_PATH

# Step 9: Copy Configuration Files
echo "Copying configuration files..."
cp shell/.tmux.conf $USER_HOME/.tmux.conf
cp shell/.zshrc $USER_HOME/.zshrc
chown $NON_ROOT_USER:$NON_ROOT_USER $USER_HOME/.tmux.conf $USER_HOME/.zshrc

# Step 10: Set Zsh as Default Shell
echo "Setting Zsh as the default shell for $NON_ROOT_USER..."
chsh -s $(which zsh) $NON_ROOT_USER

echo "Setup complete. Please reboot your system for all changes to take effect."
