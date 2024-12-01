#!/bin/bash

# Eliminar archivo temporal si existe
rm ~/x

echo "Setting up storage for Termux"
termux-setup-storage &>/dev/null
sleep 4

while true; do
    if [ -d ~/storage/shared ]; then
        break
    else
        echo "Storage permission denied"
    fi
    sleep 3
done

echo "Installing essential termux packages"
pkg clean
pkg update -y
pkg upgrade -y
pkg install -y x11-repo pulseaudio xwayland wget tsu root-repo p7zip xorg-xrandr termux-x11-nightly

echo "Downloading additional .deb packages"
wget -O liblzma_5.6.0-1_aarch64.deb https://example.com/path/to/liblzma_5.6.0-1_aarch64.deb
wget -O termux-x11-1.02.07-0-all.deb https://example.com/path/to/termux-x11-1.02.07-0-all.deb
wget -O xz-utils_5.6.0-1_aarch64.deb https://example.com/path/to/xz-utils_5.6.0-1_aarch64.deb
wget -O liblzma-static_5.6.0-1_aarch64.deb https://example.com/path/to/liblzma-static_5.6.0-1_aarch64.deb

echo "Installing additional .deb packages"
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
        return 1
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
    return 1
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

curl -s "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/files/package-manager/raw?ref=main" -o $PREFIX/glibc/opt/package-manager/package-manager

if [ ! -f "$PREFIX/glibc/opt/package-manager/package-manager" ]; then
    echo "Download failed"
    return 1
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

# Instalación del marco de emulación en Termux
REPO_URL="https://raw.githubusercontent.com/steamMR1/Wine-for-android/main"
INSTALL_DIR="$HOME/emulation_framework"

# Funciones de registro y manejo de errores
log() {
    echo -e "${GREEN}[INSTALLER]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

prepare_system() {
    log "Updating Termux packages..."
    pkg update -y || error "Failed to update packages"
    
    log "Installing required dependencies..."
    pkg install -y wget curl git python rust clang make \
        libx11 libxcb xorg-xvfb xorg-server termux-x11 \
        openssl libffi zlib || error "Dependency installation failed"
}

download_components() {
    log "Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    log "Downloading emulation framework components..."
    curl -o framework_core.py "$REPO_URL/framework_core.py" || \
        error "Failed to download core framework"
    
    curl -o requirements.txt "$REPO_URL/requirements.txt" || \
        error "Failed to download requirements"
}

setup_python_environment() {
    log "Setting up Python virtual environment..."
    python3 -m venv venv || error "Failed to create virtual environment"
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install requirements
    pip install -r requirements.txt || error "Failed to install Python dependencies"
}

main() {
    log "Starting Termux Emulation Framework Installation..."
    
    # Validate Termux environment
    if [ ! -d "$PREFIX" ]; then
        error "Not running in Termux environment!"
    fi
    
    # Execute installation steps
    prepare_system
    download_components
    setup_python_environment
    
    log "Installation complete!"
    log "Run the framework with: ~/emulation_framework/venv/bin/python ~/emulation_framework/framework_core.py"
}

# Execute main installation
main
