CASE_SENSITIVE="true"
ZSH_THEME="farmber"
DISABLE_UNTRACKED_FILES_DIRTY="true"

export PATH=$HOME/bin:$PATH

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code -w'
fi
