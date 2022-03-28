ZSH_THEME="farmber"
DISABLE_UNTRACKED_FILES_DIRTY="true"

if type xclip &>/dev/null; then
  alias getclip='xclip -o -selection clipboard'
  alias putclip='xclip -i -selection clipboard'
fi

