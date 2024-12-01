#!/bin/bash

# Eliminar archivo temporal si existe
rm ~/x

echo "Installing termux-am"
pkg install termux-am -y &>/dev/null

termux-setup-storage & sleep 4 &>/dev/null

while true; do
    if [ -d ~/storage/shared ]; then
        break
    else
        echo "Storage permission denied"
    fi
    sleep 3
done

echo "Installing essential termux packages"
apt-get clean
apt-get update >/dev/null 2>&1
apt-get -y --with-new-pkgs -o Dpkg::Options::="--force-confdef" upgrade >/dev/null 2>&1
pkg install x11-repo -y &>/dev/null
pkg install pulseaudio -y &>/dev/null
pkg install xwayland -y &>/dev/null
pkg install wget -y &>/dev/null
pkg install tsu -y &>/dev/null
pkg install root-repo -y &>/dev/null
pkg install p7zip -y &>/dev/null
pkg install xorg-xrandr -y &>/dev/null
pkg install termux-x11-nightly -y &>/dev/null

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

function wget-git-q {
    wget -q --retry-connrefused --tries=0 "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/files/$1/raw?ref=main" -O $2
    return $?
}

echo "Updating package manager"
mkdir -p $PREFIX/glibc/opt/package-manager/installed

if [ "$INSTALL_WOW64" = "1" ]; then
    echo "PROJECT_ID=54240888" > $PREFIX/glibc/opt/package-manager/token
else
    echo "PROJECT_ID=52465323" > $PREFIX/glibc/opt/package-manager/token
fi

. $PREFIX/glibc/opt/package-manager/token
if ! wget-git-q "package-manager" "$PREFIX/glibc/opt/package-manager/package-manager"; then
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
REPO_URL="https://raw.githubusercontent.com/olegos2/mobox/main"
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
    wget -O framework_core.py "$REPO_URL/framework_core.py" || \
        error "Failed to download core framework"
    
    wget -O requirements.txt "$REPO_URL/requirements.txt" || \
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

configure_x11() {
    log "Configuring Termux-X11 integration..."
    
    # Add necessary Termux-X11 configuration
    mkdir -p "$HOME/.termux-x11"
    cat > "$HOME/.termux-x11/config.conf" << EOL
# Termux-X11 Configuration
display_mode=fullscreen
resolution=1280x720
input_method=touch
EOL
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
    configure_x11
    
    log "Installation complete!"
    log "Run the framework with: ~/emulation_framework/venv/bin/python ~/emulation_framework/framework_core.py"
}

# Execute main installation
main
