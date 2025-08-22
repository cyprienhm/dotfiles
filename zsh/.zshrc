# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath+=("$(brew --prefix)/share/zsh/site-functions")

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
alias n=nvim

alias l="lazygit"
alias glog="git log --oneline --graph --decorate"

u() {
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
    venv_path="$repo_root/.venv/bin/activate"
    [ -f "$venv_path" ] && source "$venv_path"
}

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

alias zathura="/opt/homebrew/bin/zathura"

function zp() {
    local dir="${HOME}/papers"
    local oldpwd=$PWD
    cd "$dir"
    command -v fd >/dev/null || { echo "fd not found"; return 1; }
    command -v fzf >/dev/null || { echo "fzf not found"; return 1; }

    local selected_file=$(fd --type f . --strip-cwd-prefix | fzf --reverse --height=80% --preview '
    p='$dir'/{}
    case "$p" in
      *.pdf) command -v pdftotext >/dev/null && pdftotext -l 1 "$p" - 2>/dev/null | sed -n "1,80p" || file -b "$p" ;;
        *) file -b "$p" ;;
    esac
    ') || return
    [ -z "$selected_file" ] && return

    nohup zathura "$dir/$selected_file" >/dev/null 2>&1 & disown || true
    cd "$oldpwd"
}

eval "$(zoxide init zsh)"

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs --null bat --diff
}

alias t=tmux
alias ta="tmux attach"
alias tl="tmux list-sessions"

[ -f ~/.ghcup/env ] && . ~/.ghcup/env # ghcup-env
