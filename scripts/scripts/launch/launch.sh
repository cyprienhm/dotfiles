#!/bin/zsh

choices="Open pdf
Switch input
Use MacBook microphone
Toggle yabai
Toggle window float
https://github.com
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

if [[ "$selection" == "Open pdf" ]]; then
    exec "${0:A:h}/readpdf.sh"
elif [[ "$selection" == "Switch input" ]]; then
    osascript -e 'tell application "System Events" to key code 49 using {control down, option down}'
elif [[ "$selection" == "Use MacBook microphone" ]]; then
    exec /opt/homebrew/bin/SwitchAudioSource -t input -s 'MacBook Air Microphone'
elif [[ "$selection" == "Toggle yabai" ]]; then
    exec /bin/zsh "${0:A:h}/../toggleyabai.sh"
elif [[ "$selection" == "Toggle window float" ]]; then
    exec /opt/homebrew/bin/yabai -m window --toggle float
elif [[ "$selection" == /Applications/*.app/ ]]; then
    open "$selection"
else
    open "$selection"
fi
