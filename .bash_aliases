# $HOME/.bash_aliases

# To temporarily bypass an alias, we precede the command with a \
# EG: the ls command is aliased, but to use the normal ls command you would type \ls

# EDITOR ALIAS'S
# Aliases for common text editors
alias e='emacsclient -c -a emacs' # Open Emacs client
alias vi='nvim'                   # Open Neovim as vi
alias vim='nvim'                  # Open Neovim as vim
alias se='sudo e'                 # Open Emacs client with sudo privileges
alias svi='sudo nvim'             # Open Neovim with sudo privileges
alias vis='nvim "+set si"'        # Open Neovim with smartindent
alias ebrc='nvim ~/.bashrc'       # Edit .bashrc file using Neovim
alias hlp='less ~/.bashrc_help'   # Show help for this .bashrc file using less

# NAVIGATOR ALIAS'S
# Aliases for navigating directories
# Change directory aliases
alias home='cd ~'            # Go to home directory
alias cd..='cd ..'           # Go to parent directory
alias ..='cd ..'             # Go to parent directory (alternative)
alias ...='cd ../..'         # Go to grandparent directory
alias ....='cd ../../..'     # Go to great-grandparent directory
alias .....='cd ../../../..' # Go to great-great-grandparent directory
alias bd='cd "$OLDPWD"'      # Go to previous directory (using $OLDPWD)

# Replace batcat with cat on Fedora as batcat is not available as a RPM in any form
if command -v lsb_release >/dev/null; then
	# Get the Linux distribution name
	DISTRIBUTION=$(lsb_release -si)

	# Set alias for cat based on distribution
	if [ "$DISTRIBUTION" = "Fedora" ] || [ "$DISTRIBUTION" = "Arch" ]; then
		# Use bat on Fedora and Arch
		alias cat='bat'
	else
		# Use batcat on other distributions
		alias cat='batcat'
	fi
fi

# Add an "alert" alias for long running commands
# Usage: sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Show the current date and time
alias da='date "+%Y-%m-%d %A %T %Z"'

# Modified commands with added functionality
alias cp='cp -i'                           # Ask before overwriting when copying files
alias mv='mv -i'                           # Ask before overwriting when moving files
alias rm='trash -v'                        # Move files to trash instead of deleting
alias mkdir='mkdir -p'                     # Create parent directories if they don't exist
alias ps='ps auxf'                         # Show all processes in a tree-like format
alias ping='ping -c 10'                    # Send 10 ping requests by default
alias less='less -R'                       # Enable raw output in less
alias cls='clear'                          # Clear the terminal screen
alias apt-get='sudo apt-get'               # Run apt-get with sudo privileges
alias multitail='multitail --no-repeat -c' # Multitail with no repeat and color
alias freshclam='sudo freshclam'           # Update ClamAV database with sudo privileges

# Remove a directory and all files
alias rmd='/bin/rm  --recursive --force --verbose ' # Forcefully delete directory and contents

# Alias's for multiple directory listing commands
alias la='ls -Alh'                # List all files, including hidden files
alias ls='ls -aFh --color=always' # List files with colors and file type indicators
alias lx='ls -lXBh'               # Sort files by extension
alias lk='ls -lSrh'               # Sort files by size in reverse order
alias lc='ls -lcrh'               # Sort files by change time in reverse order
alias lu='ls -lurh'               # Sort files by access time in reverse order
alias lr='ls -lRh'                # Recursively list files and directories
alias lt='ls -ltrh'               # Sort files by date in reverse order
alias li='ls -lih'                # Sort files by inode number
alias lm='ls -alh |more'          # List files and pipe output to 'more'
alias lw='ls -xAh'                # List files in wide format
alias ll='ls -Fls'                # List files in long format with sizes
alias labc='ls -lap'              # List files in alphabetical order
alias lf="ls -l | egrep -v '^d'"  # List only files (not directories)
alias ldir="ls -l | egrep '^d'"   # List only directories

# alias chmod commands
alias mx='chmod a+x'     # Add execute permission for all users
alias 000='chmod -R 000' # Remove all permissions for all users
alias 644='chmod -R 644' # Set read and write permissions for owner, read permission for group and others
alias 666='chmod -R 666' # Set read and write permissions for all users
alias 755='chmod -R 755' # Set read, write, and execute permissions for owner, read and execute permissions for group and others
alias 777='chmod -R 777' # Set read, write, and execute permissions for all users

# Search command line history
alias h="history | grep " # Search through command history

# Search running processes
alias p="ps aux | grep " # Search for processes by keyword

# Show top CPU-consuming processes
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10" # List top 10 CPU-consuming processes

# Search files in the current folder
alias f="find . | grep " # Search for files in the current directory

# Count all files (recursively) in the current folder
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null" # Count files, links, and directories in the current directory

# To see if a command is aliased, a file, or a built-in command
alias checkcommand="type -t" # Check the type of a command (alias, file, or built-in)

# Show open ports
alias openports='netstat -nape --inet' # List open network ports

# Alias's for safe and forced reboots
alias rebootsafe='sudo shutdown -r now'     # Reboot the system safely
alias rebootforce='sudo shutdown -r -n now' # Reboot the system forcefully

# Alias's to show disk space and space used in a folder
alias diskspace="du -S | sort -n -r |more"                                          # Show disk space usage in the current directory
alias folders='du -h --max-depth=1'                                                 # Show disk space usage of subfolders
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn' # Sort subfolders by disk space usage
alias tree='tree -CAhF --dirsfirst'                                                 # Show a tree-like directory structure
alias treed='tree -CAFd'                                                            # Show a tree-like directory structure with directories only
alias mountedinfo='df -hT'                                                          # Show mounted file systems and their disk space usage

# Alias's for archives
alias mktar='tar -cvf'  # Create a tar archive
alias mkbz2='tar -cvjf' # Create a tar archive with bzip2 compression
alias mkgz='tar -cvzf'  # Create a tar archive with gzip compression
alias untar='tar -xvf'  # Extract a tar archive
alias unbz2='tar -xvjf' # Extract a tar archive with bzip2 compression
alias ungz='tar -xvzf'  # Extract a tar archive with gzip compression

# Show all logs in /var/log
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f" # Follow all log files in /var/log

# SHA1
alias sha1='openssl sha1' # Generate a SHA1 hash

alias clickpaste='sleep 3; xdotool type "$(xclip -o -selection clipboard)"' # Paste clipboard contents after 3 seconds

# KITTY - alias to be able to use kitty features when connecting to remote servers(e.g use tmux on remote server)
alias kssh="kitty +kitten ssh" # Connect to a remote server using kitty

# IP address lookup
alias whatismyip="whatsmyip" # Get the current public IP address

# alias for hugo server
alias hug="hugo server -F --bind=10.0.0.97 --baseURL=http://10.0.0.97" # Start a Hugo server on a specific IP address and port

# Alias's for SSH
# alias SERVERNAME='ssh YOURWEBSITE.com -l USERNAME -p PORTNUMBERHERE'  # Connect to a remote server via SSH (example)

# Alias's to change the directory
alias web='cd /var/www/html' # Quickly navigate to the web server directory

# Alias's to mount ISO files
# mount -o loop /home/NAMEOFISO.iso /home/ISOMOUNTDIR/  # Mount an ISO file as a loop device (requires root)
# umount /home/NAMEOFISO.iso  # Unmount an ISO file (requires root)
# (Both commands done as root only.)
