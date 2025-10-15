```sh
xcode-select --install
```

```sh
scutil --set ComputerName 0
scutil --set LocalHostName 0
scutil --set HostName 0
```

- make windows draggable w ctrl+cmd+drag (must log out/in to apply)
```sh
defaults write -g NSWindowShouldDragOnGesture -bool true
```
- brew

- JetBrainsMono Nerd Font
- zsh
- pure & zsh-autosuggestions

```zsh
brew install pure
brew install zsh-autosuggestions
```

- on iterm2, remember in profiles settings: Keys -> Left Option key -> set as Esc+. and,
remember to Keys -> Key Mappings -> Import the preset Natural Text Editing
- on kitty, just use conf
- on ghostty, just use confg
brew install --cask ghostty
- fzf
- lazyvim
- fd
- brew install ripgrep
- pyenv
- python
- keyboard shortcuts > mission control > ^1-9 to switch spaces
- trackpad > one tap
- yabai
- skhd
- btop
- bat
- zk
- vimium for chrome
- jankyborders
```sh
brew tap FelixKratz/formulae
brew install borders
```
- zoxide
```sh
brew install zoxide
```
- p10k
```sh
brew install powerlevel10k
```
and add `source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme` in ~/.zshrc

- starship
```sh
curl -sS https://starship.rs/install.sh | sh
```
and add `eval "$(starship init zsh)"` ~/.zshrc

- tmux
```sh
brew install tmux
```

- zathura
```sh
brew install poppler
```

- eza
```sh
brew install eza
```
- zen
always show bookmarks in single toolbar mode:
`zen.view.hide-window-controls <- false` in about:config

colorschemes
- catppuccin
- rose-pine
- solarized light
- dracula

userstyles
- install stylus extension
- import `userstyles/stylus.json`

- yazi
```sh
brew install yazi
```
