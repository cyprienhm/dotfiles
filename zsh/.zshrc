[[ $- == *i* ]] && fastfetch

eval "$(starship init zsh)"

bindkey -e
set -o emacs

fpath+=("$(brew --prefix)/share/zsh/site-functions")

autoload -U compinit
compinit
zstyle ':completion:*' menu select

autoload edit-command-line
zle -N edit-command-line
bindkey '^Xe' edit-command-line
bindkey '^X^e' edit-command-line

export EDITOR="nvim"

source <(fzf --zsh)

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

alias ls="ls -G"
alias ll="ls -lhaG"

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
alias tn="tmux new-session"
alias ta="tmux attach"
alias tl="tmux list-sessions"
tt() {
    tmux attach -t $(tl | fzf | cut -d: -f1)
}

[ -f ~/.ghcup/env ] && . ~/.ghcup/env # ghcup-env

