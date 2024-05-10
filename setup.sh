#!/bin/bash

# Check if the script is ran as root
if [[ $EUID -ne 0 ]]; then
	echo "this script must be ran as a root user. please run sudo ./setup.sh" 2>&1
	exit
fi

username=$(id -u -n 1000)
builddir=/home/$username

apt update
apt upgrade -y

cd $builddir
mkdir -p $builddir/.config
mkdir -p $builddir/.fonts
mkdir -p $builddir/Pictures/Wallpapers
chown -R $username:$username $builddir

# List of packages
packages=(
    xorg 
    blueman 
    flatpak 
    nemo 
    nitrogen 
    lxappearance 
    pavucontrol 
    build-essential 
    ninja-build 
    gettext 
    cmake 
    wget 
    curl 
    zip 
    unzip 
    fonts-noto-color-emoji 
    gnome-themes-extra 
    breeze-cursor-theme 
    network-manager-gnome 
    pkg-config 
    libfreetype6-dev 
    libfontconfig1-dev 
    libxcb-xfixes0-dev 
    libxkbcommon-dev 
    python3 
)

# Install packages if they don't exist
if ! dpkg -l "${packages[@]}" 1> /dev/null 2>&1; then
    echo "Installing required packages..."
    apt install "${packages[@]}" -y
else
    echo "Packages are already installed, skipping..."
fi

# Check if JetBrainsMono exists in ~/.fonts/
if ! ls $builddir/.fonts/JetBrainsMono* 1> /dev/null 2>&1; then
	#Download and install font
	cd $builddir
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
	unzip JetBrainsMono.zip -d $builddir/.fonts
	rm ./JetBrainsMono.zip
	chown $username:$username $builddir/.fonts/*
else
	echo "JetBrainsMono font is already installed skipping..."
fi

# Reload fonts
fc-cache -vf

# Install firefox if not installed or if mozilla repository doesn't exist
if ! dpkg -l | grep firefox 1> /dev/null 2>&1 || [ ! -f /etc/apt/sources.list.d/mozilla.list ]; then
    install -d -m 0755 /etc/apt/keyrings
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
    echo '
    Package: *
    Pin: origin packages.mozilla.org
    Pin-Priority: 1000
    ' | sudo tee /etc/apt/preferences.d/mozilla

    apt update && apt install firefox -y
else
    echo "Firefox is already installed or Mozilla repository exists, skipping..."
fi


echo "-------------------------------------------------------"
echo "                   SCRIPT HAS FINISHED"
echo "-------------------------------------------------------"
