#!/bin/sh
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Output helpers
info() {
    echo -e "${GREEN}>>>${NC} $1"
    sleep 0.5
}

warn() {
    echo -e "${YELLOW}>>> warning:${NC} $1"
    sleep 0.5
}

error() {
    echo -e "${RED}>>> error:${NC} $1"
    exit 1
}

# --- Prerequisites -------------------------------------------------
info "Checking prerequisites..."

if [ "$(id -u)" -eq 0 ]; then
    error "Do not run as root. Use a regular user with doas privileges."
fi

if ! command -v doas >/dev/null 2>&1; then
    error "doas not found. Please install doas and configure it for your user."
fi

if ! doas -v >/dev/null 2>&1; then
    error "doas not configured or user lacks privileges. Check /etc/doas.d/doas.conf"
fi

# --- Repository setup ----------------------------------------------
info "Configuring Alpine repositories (edge + testing)..."

doas cp /etc/apk/repositories /etc/apk/repositories.bak.$(date +%Y%m%d-%H%M%S)

doas sh -c 'cat > /etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF'

info "Updating package indexes..."
doas apk update

# --- Package installation ------------------------------------------
info "Installing required packages..."

PACKAGES="
    alpine-base
    build-base
    linux-headers
    ncurses-dev
    libx11-dev
    libxft-dev
    libxinerama-dev
    neovim
    git
    xclip
    fzf
    ripgrep
    fd
    python3
    py3-pip
    python3-dev
    clang
    clang-extra-tools
    xwallpaper
    curl
    wget
    htop
    ncdu
    tmux
    ranger
    unzip
    tar
    man-pages
    mandoc
    cheat
    stow
    terminus-font
"

doas apk add $PACKAGES

doas setup-xorg-base

# --- Clone/update myeeedistro repo --------------------------------
REPO_DIR="$HOME/myeeedistro"
if [ ! -d "$REPO_DIR" ]; then
    info "Cloning myeeedistro repository..."
    git clone https://github.com/Islam-Ahmetshin/myeeedistro.git "$REPO_DIR"
else
    info "Updating myeeedistro repository..."
    cd "$REPO_DIR" && git pull
fi

# --- Link configuration files --------------------------------------
info "Creating symlinks for configuration files..."

link_file() {
    src="$1"
    dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "$dst already exists and is not a symlink. Moving to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
}

# Shell configs
link_file "$REPO_DIR/configs/shell/.xinitrc" "$HOME/.xinitrc"
link_file "$REPO_DIR/configs/shell/.profile" "$HOME/.profile"
link_file "$REPO_DIR/configs/shell/.ashrc" "$HOME/.ashrc"
link_file "$REPO_DIR/configs/shell/.aliases" "$HOME/.aliases"

# Neovim
mkdir -p "$HOME/.config/nvim"
link_file "$REPO_DIR/configs/nvim/init.vim" "$HOME/.config/nvim/init.vim"

# --- Build suckless tools -----------------------------------------
info "Building suckless software (dwm, st, dmenu)..."

SUCKLESS_DIR="$HOME/.local/src/suckless"
mkdir -p "$SUCKLESS_DIR"

build_suckless() {
    name="$1"
    repo_url="$2"
    config_dir="$REPO_DIR/configs/$name"

    cd "$SUCKLESS_DIR"
    if [ ! -d "$name" ]; then
        git clone "$repo_url" "$name"
    else
        cd "$name" && git pull
    fi

    cd "$SUCKLESS_DIR/$name"
    if [ -f "$config_dir/config.h" ]; then
        cp "$config_dir/config.h" config.h
    else
        warn "No custom config.h for $name, using default."
    fi

    make clean
    make
    doas make install
}

build_suckless "dwm"   "git://git.suckless.org/dwm"
build_suckless "st"    "git://git.suckless.org/st"
build_suckless "dmenu" "git://git.suckless.org/dmenu"

# --- Done ---------------------------------------------------------
info "Deployment complete!"
info "You can now start X with 'startx' (or 'xinit')."
