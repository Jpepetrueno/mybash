# .bash_functions

# Extracts one or more archives using the appropriate command based on the file extension
# Supports various archive formats, including tar, zip, rar, 7z, and more
# If the 'unp' command is not installed, this function can be used as a fallback
extract() {
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			case "$archive" in
			*.tar.bz2) tar xvjf "$archive" ;; # Extracts a tar.bz2 archive
			*.tar.gz) tar xvzf "$archive" ;;  # Extracts a tar.gz archive
			*.bz2) bunzip2 "$archive" ;;      # Extracts a bz2 archive
			*.rar) rar x "$archive" ;;        # Extracts a rar archive
			*.gz) gunzip "$archive" ;;        # Extracts a gz archive
			*.tar) tar xvf "$archive" ;;      # Extracts a tar archive
			*.tbz2) tar xvjf "$archive" ;;    # Extracts a tbz2 archive
			*.tgz) tar xvzf "$archive" ;;     # Extracts a tgz archive
			*.zip) unzip "$archive" ;;        # Extracts a zip archive
			*.Z) uncompress "$archive" ;;     # Extracts a Z archive
			*.7z) 7z x "$archive" ;;          # Extracts a 7z archive
			*) echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

# Searches for text in all files in the current folder
ftext() {
	# -i case-insensitive
	# -I ignore binary files
	# -H causes filename to be printed
	# -r recursive search
	# -n causes line number to be printed
	# optional: -F treat search term as a literal, not a regular expression
	# optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
	grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a progress bar
cpp() {
	set -e
	strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
		awk '{
	count += $NF
	if (count % 10 == 0) {
		percent = count / total_size * 100
		printf "%3d%% [", percent
		for (i=0;i<=percent;i++)
			printf "="
			printf ">"
			for (i=percent;i<100;i++)
				printf " "
				printf "]\r"
			}
		}
	END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# Copy and go to the directory
cpg() {
	if [ -d "$2" ]; then
		cp "$1" "$2" && cd "$2"
	else
		cp "$1" "$2"
	fi
}

# Move a file or directory and go to the directory if the destination is a directory,
# otherwise just move the file.
mvg() {
	if [ -d "$2" ]; then
		mv "$1" "$2" && cd "$2"
	else
		mv "$1" "$2"
	fi
}

# Create a directory and go to it.
mkdirg() {
	mkdir -p "$1"
	cd "$1"
}

# Goes up a specified number of directories
#
# Examples:
# up 4  (i.e. up 4)
up() {
	local d=""
	limit=$1
	for ((i = 1; i <= limit; i++)); do
		d=$d/..
	done
	d=$(echo $d | sed 's/^\///')
	if [ -z "$d" ]; then
		d=..
	fi
	cd "$d"
}

# Changes the current directory and lists its contents.
# If a directory is specified as an argument, it navigates to that directory and runs `ls`.
# If no argument is given, it defaults to the home directory.
cd() {
	if [ -n "$1" ]; then
		builtin cd "$@" && ls
	else
		builtin cd ~ && ls
	fi
}

# Print the last 2 fields of the working directory, joined by a slash.
# Example: If the current working directory is /a/b/c/d, this function will print "c/d".
pwdtail() {
	pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# This function inspects /etc/os-release and returns a string identifying the
# distribution type. The returned strings are one of: redhat, suse, debian,
# gentoo, arch, slackware, or unknown.
distribution() {
	local dtype="unknown" # Default to unknown

	# Use /etc/os-release for modern distro identification
	if [ -r /etc/os-release ]; then
		source /etc/os-release
		case $ID in
		fedora | rhel | centos)
			dtype="redhat"
			;;
		sles | opensuse*)
			dtype="suse"
			;;
		ubuntu | debian)
			dtype="debian"
			;;
		gentoo)
			dtype="gentoo"
			;;
		arch)
			dtype="arch"
			;;
		slackware)
			dtype="slackware"
			;;
		*)
			# If ID is not recognized, keep dtype as unknown
			;;
		esac
	fi

	echo $dtype
}

# Show the current version of the operating system.
# This function attempts to display the current version of the operating system,
# depending on the distribution type. The method used is distribution-dependent:
#
# - Red Hat/Fedora: /etc/redhat-release or /etc/issue
# - SuSE/OpenSuSE: /etc/SuSE-release
# - Debian: lsb_release -a
# - Gentoo: /etc/gentoo-release
# - Arch: /etc/os-release
# - Slackware: /etc/slackware-version
#
# If the distribution type is not recognized, it will display the contents of
# /etc/issue if available, and exit with an error code otherwise.
ver() {
	local dtype
	dtype=$(distribution)

	case $dtype in
	"redhat")
		if [ -s /etc/redhat-release ]; then
			cat /etc/redhat-release
		else
			cat /etc/issue
		fi
		uname -a
		;;
	"suse")
		cat /etc/SuSE-release
		;;
	"debian")
		lsb_release -a
		;;
	"gentoo")
		cat /etc/gentoo-release
		;;
	"arch")
		cat /etc/os-release
		;;
	"slackware")
		cat /etc/slackware-version
		;;
	*)
		if [ -s /etc/issue ]; then
			cat /etc/issue
		else
			echo "Error: Unknown distribution"
			exit 1
		fi
		;;
	esac
}

# Automatically install the needed support files for this .bashrc file based on the
# Linux distribution type.
#
# Supported distributions:
#
# - Red Hat/CentOS/Fedora
# - SuSE/OpenSuSE
# - Debian/Ubuntu
# - Arch Linux
# - Slackware
#
# Note: On Arch Linux, this function will install the needed packages using paru, which
# is a popular AUR helper. If you don't have paru installed, you'll need to install it
# first.
install_bashrc_support() {
	local dtype
	dtype=$(distribution)

	case $dtype in
	"redhat")
		sudo dnf install multitail tree zoxide trash-cli fzf bash-completion fastfetch
		;;
	"suse")
		sudo zypper install multitail tree zoxide trash-cli fzf bash-completion fastfetch
		;;
	"debian")
		sudo apt-get install multitail tree zoxide trash-cli fzf bash-completion
		# Fetch the latest fastfetch release URL for linux-amd64 deb file
		FASTFETCH_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url.*linux-amd64.deb" | cut -d '"' -f 4)

		# Download the latest fastfetch deb file
		curl -sL "$FASTFETCH_URL" -o /tmp/fastfetch_latest_amd64.deb

		# Install the downloaded deb file using apt-get
		sudo apt-get install /tmp/fastfetch_latest_amd64.deb
		;;
	"arch")
		sudo paru multitail tree zoxide trash-cli fzf bash-completion fastfetch
		;;
	"slackware")
		echo "No install support for Slackware"
		;;
	*)
		echo "Unknown distribution"
		;;
	esac
}

# Print your internal and external IP addresses.
#
# This function will print your internal IP address using the ip or ifconfig
# command, depending on the system, and your external IP address as reported
# by ifconfig.me.
function whatsmyip() {
	# Internal IP Lookup.
	if [ -e /sbin/ip ]; then
		echo -n "Internal IP: "
		/sbin/ip addr show wlan0 | grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
	else
		echo -n "Internal IP: "
		/sbin/ifconfig wlan0 | grep "inet " | awk -F: '{print $1} |' | awk '{print $2}'
	fi

	# External IP Lookup
	echo -n "External IP: "
	curl -s ifconfig.me
}

# View Apache logs
# This function will navigate to the Apache log directory
# appropriate for your system (httpd or apache2), list all
# files in reverse chronological order, and then use multitail
# to view the last two of them.
apachelog() {
	if [ -f /etc/httpd/conf/httpd.conf ]; then
		cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
	else
		cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
	fi
}

# Edit the Apache configuration file appropriate for your system (httpd or apache2).
#
# This function looks for the Apache configuration file in the standard locations
# for your system, and then uses the $EDITOR set in your shell configuration to
# edit the configuration file. If a configuration file is not found, it will
# suggest possible locations of the file using the `locate` command.
apacheconfig() {
	if [ -f /etc/httpd/conf/httpd.conf ]; then
		svi /etc/httpd/conf/httpd.conf
	elif [ -f /etc/apache2/apache2.conf ]; then
		svi /etc/apache2/apache2.conf
	else
		echo "Error: Apache config file could not be found."
		echo "Searching for possible locations:"
		sudo updatedb && locate httpd.conf && locate apache2.conf
	fi
}

# Edit the PHP configuration file
# This function looks for the PHP configuration file in the standard locations
# for your system, and then uses the $EDITOR set in your shell configuration to
# edit the configuration file. If a configuration file is not found, it will
# suggest possible locations of the file using the `locate` command.
phpconfig() {
	if [ -f /etc/php.ini ]; then
		svi /etc/php.ini
	elif [ -f /etc/php/php.ini ]; then
		svi /etc/php/php.ini
	elif [ -f /etc/php5/php.ini ]; then
		svi /etc/php5/php.ini
	elif [ -f /usr/bin/php5/bin/php.ini ]; then
		svi /usr/bin/php5/bin/php.ini
	elif [ -f /etc/php5/apache2/php.ini ]; then
		svi /etc/php5/apache2/php.ini
	else
		echo "Error: php.ini file could not be found."
		echo "Searching for possible locations:"
		sudo updatedb && locate php.ini
	fi
}

# Edit the MySQL configuration file
# This function looks for the MySQL configuration file in the standard locations
# for your system, and then uses the $EDITOR set in your shell configuration to
# edit the configuration file. If a configuration file is not found, it will
# suggest possible locations of the file using the `locate` command.
mysqlconfig() {
	if [ -f /etc/my.cnf ]; then
		svi /etc/my.cnf
	elif [ -f /etc/mysql/my.cnf ]; then
		svi /etc/mysql/my.cnf
	elif [ -f /usr/local/etc/my.cnf ]; then
		svi /usr/local/etc/my.cnf
	elif [ -f /usr/bin/mysql/my.cnf ]; then
		svi /usr/bin/mysql/my.cnf
	elif [ -f ~/my.cnf ]; then
		svi ~/my.cnf
	elif [ -f ~/.my.cnf ]; then
		svi ~/.my.cnf
	else
		echo "Error: my.cnf file could not be found."
		echo "Searching for possible locations:"
		sudo updatedb && locate my.cnf
	fi
}

# Trim leading and trailing spaces from a string.
# This function takes a string as an argument, trims any leading or trailing
# whitespace characters, and prints the resulting string to stdout.
#
# This is useful for cleaning up strings that may contain trailing whitespace
# characters, such as those returned by git config --get or other commands.
trim() {
	local var=$*
	var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
	echo -n "$var"
}

# Commit all local changes with a message.
git_commit() {
	git add .
	git commit -m "$1"
}

# Commit and push changes with a message.
git_commit_push() {
	git_commit "$1"
	git push
}

# Complete babashka tasks with terminal tab-completion.
#
# This function is used by the bash complete command to generate a list of
# possible completions for the bb command when the user presses the tab key.
#
# The function takes no arguments, and returns a list of possible completions
# that are generated by running the bb tasks command and parsing the output.
# autocomplete filenames as well
_bb_tasks() {
	mapfile -t COMPREPLY < <(compgen -W "$(bb tasks | tail -n +3 | cut -f1 -d ' ')" -- "${COMP_WORDS[COMP_CWORD]}")
}
complete -f -F _bb_tasks bb

# Justfile recipes terminal tab-completion
# Generate a list of possible completions for the `just` command.
#
# This function is used by the bash complete command to provide tab-completion
# for `just` recipes. It extracts recipe names from the output of `just --list`
# and uses them as possible completions. The function takes no arguments and
# sets the COMPREPLY array with the completion options.
_just_recipes() {
	mapfile -t COMPREPLY < <(compgen -W "$(just --list | awk 'NR>=2 {print $1}' | tr -d ':')" -- "${COMP_WORDS[COMP_CWORD]}")
}
# autocomplete only recipes
complete -F _just_recipes just
