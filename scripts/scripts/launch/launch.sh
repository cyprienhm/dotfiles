#!/bin/zsh

choices="https://github.com
https://google.com
https://gmail.com
https://calendar.google.com
https://news.ycombinator.com
https://news.google.com
/Applications/Ghostty.app/
/Applications/Zen.app/
/Applications/sioyek.app/"

selection=$(echo "$choices" | choose)
[[ -z "$selection" ]] && exit

if [[ "$selection" == /Applications/*.app/ ]]; then
    open -n "$selection"
else
    open "$selection"
fi
