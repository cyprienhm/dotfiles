eval "$(starship init zsh)"

bindkey -e
set -o emacs

autoload -U select-word-style
select-word-style bash

BREW_PREFIX="$(brew --prefix)"
fpath+=("$BREW_PREFIX/share/zsh/site-functions")

autoload -U compinit
compinit
zstyle ':completion:*' menu select

autoload edit-command-line
zle -N edit-command-line
bindkey '^Xe' edit-command-line
bindkey '^X^e' edit-command-line

export EDITOR="nvim"

source <(fzf --zsh)

source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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

export PATH="$BREW_PREFIX/opt/openjdk/bin:$PATH"

function zf() {
    if [[ -z $1 ]]; then
        search_path="$HOME"
    else
        search_path=$1
    fi
    local selected_file=$(fd --extension pdf . $search_path | fzf --reverse --height=80% --preview '
    p={}
    case "$p" in
      *.pdf) command -v pdftotext >/dev/null && pdftotext -l 1 "$p" - 2>/dev/null | sed -n "1,80p" || file -b "$p" ;;
        *) file -b "$p" ;;
    esac
    ') || return
    [ -z "$selected_file" ] && return

    nohup zathura "$selected_file" >/dev/null 2>&1 & disown || true
}

alias zp="zf ~/papers/"

eval "$(zoxide init zsh)"

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs --null bat --diff
}

alias t=tmux
alias tn="tmux new-session"
alias ta="tmux attach"
alias tl="tmux list-sessions"
alias tb="tmux capture-pane -p | $EDITOR -"
# attach to existing sessions
te() {
    tmux attach -t $(tl | fzf --reverse | cut -d: -f1)
}
# session switcher + dispenser
tt() {
    TMUX_SESSION_DIRS=("$HOME/projects/" "$HOME/sandbox/" "$HOME/notes/" "$HOME/")
    if [[ -z $1 ]]; then
        search_path=("${TMUX_SESSION_DIRS[@]}")
    else
        search_path=("$1")
    fi
    selection=$({ fd . "${search_path[@]}" --type=directory --max-depth=1; } | fzf --reverse)
    [[ -z $selection ]] && return
    session_name=$(basename "$selection" | sed 's/\.//g')
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

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=('/Users/hex/.juliaup/bin' $path)
export PATH

# <<< juliaup initialize <<<

function wep() {
    nodemon -w $1 --exec "python $1"
}

tomp3() { ffmpeg -i "$1" -b:a 64k "${1%.*}.mp3"; }

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
