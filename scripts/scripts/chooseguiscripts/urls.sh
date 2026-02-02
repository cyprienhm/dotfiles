urls="https://github.com
https://google.com
https://news.ycombinator.com"

echo "$urls" | choose | xargs open
