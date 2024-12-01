#!/data/data/com.termux/files/usr/bin/bash

# Kill open X11 processes
kill -9 $(pgrep -f "termux.x11") 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &

# Wait a bit until termux-x11 gets started.
sleep 3

# Launch Termux X11 main activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Install and initialize Wine emulator
# Download additional .deb packages
wget -O liblzma_5.6.0-1_aarch64.deb https://example.com/path/to/liblzma_5.6.0-1_aarch64.deb
wget -O termux-x11-1.02.07-0-all.deb https://example.com/path/to/termux-x11-1.02.07-0-all.deb
wget -O xz-utils_5.6.0-1_aarch64.deb https://example.com/path/to/xz-utils_5.6.0-1_aarch64.deb
wget -O liblzma-static_5.6.0-1_aarch64.deb https://example.com/path/to/liblzma-static_5.6.0-1_aarch64.deb

# Install additional .deb packages
dpkg -i liblzma_5.6.0-1_aarch64.deb
dpkg -i termux-x11-1.02.07-0-all.deb
dpkg -i xz-utils_5.6.0-1_aarch64.deb
dpkg -i liblzma-static_5.6.0-1_aarch64.deb

if [ -e $PREFIX/glibc ]; then
    echo -n "Removing previous glibc. Continue? (Y/n) "
    read i
    if [ "$i" = "Y" ] || [ "$i" = "y" ]; then
        rm -rf $PREFIX/glibc
    else
        exit 1
    fi
fi

INSTALL_WOW64=0

echo "Select an option"
echo "1) Install previous version with box86"
echo "2) Install new version with wow64"
echo ""
echo -n "Selected number: "
read i
case "$i" in
1)
    INSTALL_WOW64=0
    ;;
2)
    INSTALL_WOW64=1
    ;;
*)
    exit 1
    ;;
esac

echo "Installing wine emulator for Android"

echo "Updating package manager"
mkdir -p $PREFIX/glibc/opt/package-manager/installed

if [ "$INSTALL_WOW64" = "1" ]; then
    PROJECT_ID="54240888"
else
    PROJECT_ID="52465323"
fi

wget -q --retry-connrefused --tries=0 "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/files/package-manager/raw?ref=main" -O $PREFIX/glibc/opt/package-manager/package-manager

if [ ! -f "$PREFIX/glibc/opt/package-manager/package-manager" ]; then
    echo "Download failed"
    exit 1
fi

. $PREFIX/glibc/opt/package-manager/package-manager
sync-all

if [ "$INSTALL_WOW64" = "1" ]; then
    sync-package wine-9.3-vanilla-wow64
else
    sync-package wine-ge-custom-8-25
fi

ln -sf $PREFIX/glibc/opt/scripts/mobox $PREFIX/bin/mobox
echo "To start, type \"wine emulator for android\""

# Prepare and run the emulation framework
REPO_URL="https://raw.githubusercontent.com/steamMR1/Wine-for-android/main"
INSTALL_DIR="$HOME/emulation_framework"

# Creating installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Downloading emulation framework components
wget -q "$REPO_URL/framework_core.py" -O framework_core.py
wget -q "$REPO_URL/requirements.txt" -O requirements.txt

# Setting up Python virtual environment
python3 -m venv venv

# Activating virtual environment
source venv/bin/activate

# Installing requirements
pip install -r requirements.txt

# Running the framework
~/emulation_framework/venv/bin/python ~/emulation_framework/framework_core.py

exit 0
