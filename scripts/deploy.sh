#!/bin/sh
# myeeedistro deployment script 

echo "[myeeedistro] Deployment started..."

# --- Configuration ---
REPO="$HOME/myeeedistro"
CONFIGS="$REPO/configs"
LOCAL_SRC="$HOME/.local/src/suckless"
LOCAL_BIN="$HOME/.local/bin"

# --- Helper: Safe symlink for configs ---
link_config() {
    src="$1"
    dst="$2"
    
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  ✓ Symlink exists: $(basename "$dst")"
        return 0
    fi
    
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "${dst}.backup"
        echo "  ! Backed up: $(basename "$dst")"
    fi
    
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "  + Linked: $(basename "$dst") -> configs/"
}

# --- Helper: Build suckless tool ---
build_tool() {
    tool_dir="$1"
    if [ ! -d "$tool_dir" ]; then
        echo "  ✗ Source missing: $(basename "$tool_dir")"
        return 1
    fi
    
    cd "$tool_dir" || return 1
    
    # Создаем конфиг из стандартного, если его нет в репозитории
    tool_name=$(basename "$tool_dir")
    if [ ! -f "$CONFIGS/$tool_name/config.h" ]; then
        echo "  ! Creating default config for $tool_name"
        mkdir -p "$CONFIGS/$tool_name"
        cp "config.def.h" "$CONFIGS/$tool_name/config.h"
    fi
    
    # Копируем конфиг для сборки
    cp -f "$CONFIGS/$tool_name/config.h" "config.h"
    
    echo "  Building $tool_name..."
    if make PREFIX="$HOME/.local" clean install; then
        echo "  ✓ Built: $tool_name"
        return 0
    else
        echo "  ✗ Build failed: $tool_name"
        return 1
    fi
}

# --- Main deployment ---

# 1. Ensure source directories exist
echo ">> Checking sources..."
for tool in dwm st dmenu; do
    if [ ! -d "$LOCAL_SRC/$tool" ]; then
        echo "  ✗ Missing: $tool source in $LOCAL_SRC/$tool/"
        echo "  To fix: download sources to $LOCAL_SRC/$tool/"
    fi
done

# 2. Build suckless tools
echo ">> Building suckless tools..."
for tool in st dwm dmenu; do
    if [ -d "$LOCAL_SRC/$tool" ]; then
        build_tool "$LOCAL_SRC/$tool"
    fi
done

# 3. Deploy config files (symlinks)
echo ">> Deploying configs..."

# Neovim
link_config "$CONFIGS/nvim/init.vim" "$HOME/.config/nvim/init.vim"

# Shell
link_config "$CONFIGS/shell/.profile" "$HOME/.profile"
link_config "$CONFIGS/shell/.aliases" "$HOME/.aliases"

# 4. Final instructions
echo ""
echo ">> Deployment complete!"
echo "   • Restart dwm: Ctrl+Alt+Backspace"
echo "   • Apply shell changes: source ~/.profile"
echo "   • Check binaries in: $LOCAL_BIN"