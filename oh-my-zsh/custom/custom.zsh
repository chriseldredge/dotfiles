ZSH_THEME="farmber"
DISABLE_UNTRACKED_FILES_DIRTY="true"

if type xclip &>/dev/null; then
  alias getclip='xclip -o -selection clipboard'
  alias putclip='xclip -i -selection clipboard'
fi

unsetopt share_history
setopt inc_append_history
