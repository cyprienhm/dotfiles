#!/bin/zsh

dir=$(printf "$HOME/papers\n$HOME/learning\n$HOME" | choose) || exit
selected_file=$(fd --extension pdf . $dir | choose) || exit

[ -z "$selected_file" ] && return

open -a /Applications/Zen.app/ "$selected_file"
