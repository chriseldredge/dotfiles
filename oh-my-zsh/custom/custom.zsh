CASE_SENSITIVE="true"
ZSH_THEME="farmber"
DISABLE_UNTRACKED_FILES_DIRTY="true"

export VOLTA_HOME="$HOME/.volta"
export PATH="$HOME/bin:$VOLTA_HOME/bin:/opt/homebrew/bin:$PATH"

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code -w'
fi
