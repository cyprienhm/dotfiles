# Portable subset of zsh/.zshrc; no Homebrew or host-specific runtimes.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/opt/neovim/bin:/opt/rust-tools/bin:$PATH"
export EDITOR=nvim VISUAL=nvim
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history share_history

bindkey -e
set -o emacs
autoload -U select-word-style
select-word-style bash
autoload -U compinit
compinit
zstyle ':completion:*' menu select
autoload edit-command-line
zle -N edit-command-line
bindkey '^Xe' edit-command-line
bindkey '^X^e' edit-command-line

source <(fzf --zsh)
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(zoxide init zsh)"

alias ll='ls -lah'
alias n=nvim
alias y=yazi
alias l=lazygit
alias glog='git log --oneline --graph --decorate'
alias t=tmux
alias tn='tmux new-session'
alias ta='tmux attach'
alias tl='tmux list-sessions'
alias tb='tmux capture-pane -p | $EDITOR -'

mkcd() { mkdir -p "$1" && cd "$1"; }
u() {
    local repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
    local venv_path="${UV_PROJECT_ENVIRONMENT:-$repo_root/.venv}/bin/activate"
    [[ -f $venv_path ]] && source "$venv_path"
}
te() {
    local selection=$(tmux list-sessions -F '#S' | fzf --reverse) || return
    [[ -n $selection ]] && tmux attach -t "=$selection"
}
tt() {
    local search_path=${1:-/workspace}
    local selection=$( { printf '%s\n' "$search_path"; fd . "$search_path" --type=directory --max-depth=1; } | fzf --reverse) || return
    [[ -n $selection ]] || return
    local session_name=$(basename "$selection" | tr -d '.:')
    [[ -n $session_name ]] || session_name=workspace
    if ! tmux has-session -t "=$session_name" 2>/dev/null; then
        tmux new-session -ds "$session_name" -c "$selection"
    fi
    if [[ -n $TMUX ]]; then
        tmux switch-client -t "=$session_name"
    else
        tmux attach -t "=$session_name"
    fi
}
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
batdiff() { git diff --name-only --relative --diff-filter=d -z | xargs --null bat --diff; }

PROMPT='%n@%m:%~%# '
# Must be sourced after widgets and bindings are defined.
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
