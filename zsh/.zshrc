fpath+=("$(brew --prefix)/share/zsh/site-functions")

autoload -U promptinit
promptinit
prompt pure

autoload -U compinit
compinit
zstyle ':completion:*' menu select

export EDITOR="nvim"

source <(fzf --zsh)

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if [[ -z "$VIRTUAL_ENV" ]]; then
  eval "$(pyenv init - zsh)"
fi

alias ls="ls -G"
alias ll="ls -lhaG"
alias vim="nvim"
alias vi="nvim"

# all permutations of vim & nvim
alias vim="nvim"
alias vmi="nvim"
alias ivm="nvim"
alias imv="nvim"
alias mvi="nvim"
alias miv="nvim"
alias nvmi="nvim"
alias nivm="nvim"
alias nimv="nvim"
alias nmvi="nvim"
alias nmiv="nvim"
alias vnim="nvim"
alias vnmi="nvim"
alias vinm="nvim"
alias vimn="nvim"
alias vmni="nvim"
alias vmin="nvim"
alias invm="nvim"
alias inmv="nvim"
alias ivnm="nvim"
alias ivmn="nvim"
alias imnv="nvim"
alias imvn="nvim"
alias mnvi="nvim"
alias mniv="nvim"
alias mvni="nvim"
alias mvin="nvim"
alias minv="nvim"
alias mivn="nvim"

alias glog="git log --oneline --graph --decorate"

alias uvactivate="source .venv/bin/activate"

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

alias zathura="/opt/homebrew/bin/zathura"

function zp() {
  local file
  file=$(fd . ~/papers | fzf) || return
  [ -n "$file" ] && zathura "$file" &
}
