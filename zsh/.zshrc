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

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if [[ -z "$VIRTUAL_ENV" ]]; then
    eval "$(pyenv init - zsh)"
fi

alias ls="ls -G"
alias ll="ls -lhaG"

mkcd() {
    mkdir -p "$1"
    cd "$1"
}

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
    local selected_file=$(fd --extension pdf . $HOME/papers | fzf --delimiter / --with-nth {-1} --reverse --height=80% --preview '
    p={}
    case "$p" in
      *.pdf) command -v pdftotext >/dev/null && pdftotext -l 1 "$p" - 2>/dev/null | sed -n "1,80p" || file -b "$p" ;;
        *) file -b "$p" ;;
    esac
    ') || return
    [ -z "$selected_file" ] && return

    nohup zathura "$selected_file" >/dev/null 2>&1 & disown || true
}

function zf() {
    local selected_file=$(fd --extension pdf . $HOME | fzf --reverse --height=80% --preview '
    p={}
    case "$p" in
      *.pdf) command -v pdftotext >/dev/null && pdftotext -l 1 "$p" - 2>/dev/null | sed -n "1,80p" || file -b "$p" ;;
        *) file -b "$p" ;;
    esac
    ') || return
    [ -z "$selected_file" ] && return

    nohup zathura "$selected_file" >/dev/null 2>&1 & disown || true
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
# attach to existing sessions
te() {
    tmux attach -t $(tl | fzf --reverse | cut -d: -f1)
}
# session switcher + dispenser
tt() {
    TMUX_SESSION_DIRS=("$HOME/projects/" "$HOME/sandbox/" "$HOME/")
    if [[ -z $1 ]]; then
        search_path=("${TMUX_SESSION_DIRS[@]}")
    else
        search_path=("$1")
    fi
    selection=$(fd . "${search_path[@]}" --type=directory --max-depth=1 | fzf --reverse)
    [[ -z $selection ]] && return
    session_name=$(basename $selection)
    if ! tmux has-session -t "$session_name"; then
        tmux new-session -ds "$session_name" -c "$selection"
    fi

    # if $TMUX is not set, we are outside of tmux
    if [[ -n $TMUX ]]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach -t "$session_name"
    fi
}

[ -f ~/.ghcup/env ] && . ~/.ghcup/env # ghcup-env


alias claude="/Users/hex/.claude/local/claude"
