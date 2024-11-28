#!/bin/bash

#######################################################
# EXPORTS
#######################################################

# Set the GOPATH environment variable to the default location
export GOPATH="$HOME/go"

# Set system-wide PATH
export PATH=$PATH:"$HOME/.local/bin:$HOME/.cargo/bin:/var/lib/flatpak/exports/bin:/.local/share/flatpak/exports/bin:/opt/lampp/bin:$GOPATH/bin"

# Set history size
export HISTFILESIZE=10000
export HISTSIZE=500

# Ignore duplicate lines in history
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Set default editor
export EDITOR='nvim'
export VISUAL='nvim'

# Set XDG_CONFIG_HOME
export XDG_CONFIG_HOME="$HOME/.config"

# Set SDKMAN_DIR
export SDKMAN_DIR="$HOME/.sdkman"

# Colors for ls and grep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;36:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Colors for manpages in less
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Use neovim for manpages
export MANPAGER='nvim +Man!'

#######################################################
# SHELL SETTINGS
#######################################################

# Load global bash config
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Load Homebrew config
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# shellcheck source=$HOME/.bash_*
# Load custom bash configuration files from $HOME/.bash_*
for file in "$HOME/.bash_aliases" "$HOME/.bash_functions"; do
  if [ -f "$file" ]; then
    source "$file"
  fi
done

# Enable bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Check window size after each command
shopt -s checkwinsize

# Configure history settings to preserve command history
# Append new commands to the history file instead of overwriting it
shopt -s histappend
# Save the current command to the history file after each execution
PROMPT_COMMAND='history -a'

# Call the function to configure the interactive prompt
if [[ $- == *i* ]]; then
  configure_interactive_prompt
fi

#######################################################
# TOOLING
#######################################################

# Load custom ble.sh script if available
if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
  source $HOME/.local/share/blesh/ble.sh
fi

# Load SDKMAN
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Load fzf configuration
eval "$(fzf --bash)"

# Load starship configuration
eval "$(starship init bash)"

# Load zoxide configuration
eval "$(zoxide init bash)"
