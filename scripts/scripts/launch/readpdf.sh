#!/bin/zsh

dir=$(printf "$HOME/papers\n$HOME" | choose) || exit
selected_file=$(fd --extension pdf . $dir | choose) || exit

[ -z "$selected_file" ] && return

nohup sioyek "$selected_file" >/dev/null 2>&1 & disown || true
