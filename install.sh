#!/bin/zsh

if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "Installing oh-my-zsh from scratch"
    env CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if ! grep ^ZSH_CUSTOM $HOME/.zshrc >/dev/null 2>&1; then
    SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    DIRP=${SCRIPTPATH:$#HOME}
    sed -i -c "1s/^/DOTFILES=\"\$HOME${DIRP//\//\\/}\"\nZSH_CUSTOM=\"\$HOME${DIRP//\//\\/}\/oh-my-zsh\/custom\"\n\n/" $HOME/.zshrc
fi

COMMONPATH="$( cd -- "$(dirname "$0")/common" >/dev/null 2>&1 ; pwd -P )"
COMMONPATH_REL=${COMMONPATH:$#HOME+1}

for i in "zprofile" "zshenv"; do
    if [ ! -r "$HOME/.${i}" ]; then
        echo symlink .${i} -\> ${COMMONPATH_REL}/${i}
        $(cd "$HOME" && ln -s "${COMMONPATH_REL}/${i}" ".${i}")
    fi
done

if ! grep '^\[include\]' $HOME/.gitconfig >/dev/null 2>&1; then
    GITDIR="$( cd -- "$(dirname "$0")/git" >/dev/null 2>&1 ; pwd -P )"
    DIRP=${GITDIR:$#HOME}
    sed -i -c "1s/^/[include]\n/" $HOME/.gitconfig
    git config --global --add include.path "~$DIRP/global.gitconfig"
fi

