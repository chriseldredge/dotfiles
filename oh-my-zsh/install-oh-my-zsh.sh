#!/bin/zsh

if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "Installing oh-my-zsh from scratch"
    env CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if ! grep ^ZSH_CUSTOM $HOME/.zshrc >/dev/null 2>&1; then
    SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    DIRP=${SCRIPTPATH:$#HOME}
    sed -i -c "1s/^/ZSH_CUSTOM=\"\$HOME${DIRP//\//\\/}\/custom\"\n\n/" $HOME/.zshrc
fi

COMMONPATH="$( cd -- "$(dirname "$0")/../common" >/dev/null 2>&1 ; pwd -P )"
COMMONPATH_REL=${COMMONPATH:$#HOME+1}

for i in "zprofile" "zshenv"; do
    if [ ! -r "$HOME/.${i}" ]; then
        echo symlink .${i} -\> ${COMMONPATH_REL}/${i}
        $(cd "$HOME" && ln -s "${COMMONPATH_REL}/${i}" ".${i}")
    fi
done
