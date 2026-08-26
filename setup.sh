#!/usr/bin/env bash
set -e
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for dir in hypr waybar; do
    target="$HOME/.config/$dir"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Backing up existing $target to $target.bak"
        mv "$target" "$target.bak"
    fi
    ln -sfn "$DOTFILES/$dir" "$target"
    echo "Linked $target -> $DOTFILES/$dir"
done

ln -sfn nvim ~/.config/nvim
echo "Linked ~/.config/nvim -> nvim"
