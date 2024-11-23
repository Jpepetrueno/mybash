# .bash_functions

# Configures interactive shell prompt settings to enhance user experience.
# This includes disabling the system bell, binding Ctrl+F to zoxide directory navigation,
# configuring case-insensitive autocompletion and automatic option listing,
# and enabling Ctrl+S for history navigation.
configure_interactive_prompt() {
	# Check if the shell is interactive
	local is_interactive=${-%%i*}
	local iatest=$((${#is_interactive} + 1))

	# Bind Ctrl+F to "zi\n" (zoxide)
	bind '"\C-f":"zi\n"'

	# Disable bell
	# if ((iatest > 0)); then
	# 	bind "set bell-style visible"
	# fi

	# Configure autocompletion
	if ((iatest > 0)); then
		bind "set completion-ignore-case on"
		bind "set show-all-if-ambiguous On"
	fi

	# Enable Ctrl-S for history navigation
	if [[ $- == *i* ]]; then
		stty -ixon
	fi
}

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
# show_distro type. The returned strings are one of: redhat, suse, debian,
# gentoo, arch, slackware, or unknown.
show_distro() {
	local distro_type="unknown" # Default to unknown

	# Use /etc/os-release for modern distro identification
	if [ -r /etc/os-release ]; then
		source /etc/os-release
		case $ID in
		fedora | rhel | centos | redhat)
			distro_type="redhat"
			;;
		sles | opensuse* | suse)
			distro_type="suse"
			;;
		ubuntu | debian | linuxmint | kali)
			distro_type="debian"
			;;
		gentoo | void)
			distro_type="gentoo"
			;;
		arch | manjaro | artix | parabola)
			distro_type="arch"
			;;
		slackware*)
			distro_type="slackware"
			;;
		*)
			# If ID is not recognized, keep distro_type as unknown
			;;
		esac
	else
		echo "Error: unable to read the /etc/os-release file"
	fi

	echo $distro_type
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
show_os_version() {
	local distro_type
	distro_type=$(show_distro)

	case $distro_type in
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

# Automatically installs the necessary support files for this .bashrc file based on the detected Linux distribution.
# Supported distributions include Red Hat/CentOS/Fedora, SuSE/OpenSuSE, Debian/Ubuntu, Arch Linux, and Slackware.
#
# Note: On Arch Linux, this function uses paru (a popular AUR helper) to install packages. If paru is not installed, it must be installed first.
#
# Installs the following packages:
# - multitail
# - tree
# - zoxide
# - trash-cli
# - fzf
# - bash-completion
# - fastfetch (on Debian and Arch Linux, fetches the latest release from GitHub)
install_bashrc_support() {
	local distro_type
	distro_type=$(show_distro)

	case $distro_type in
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

# Displays internal and external IP addresses (IPv4 and IPv6)
show_ip_info() {
	# Internal IP Lookup
	internal_ipv4=$(ip -4 addr show wlp41s0 | awk '$1 == "inet" {print $2}' | cut -d/ -f1)
	internal_ipv6=$(ip -6 addr show wlp41s0 | awk '$1 == "inet6" {print $2}' | cut -d/ -f1)
	echo "Internal IPv4 Address: $internal_ipv4"
	echo "Internal IPv6 Address: $internal_ipv6"

	# External IP Lookup
	external_ipv4=$(curl -s ifconfig.me)
	external_ipv6=$(curl -s ifconfig.me/ip6)

	if [ -n "$external_ipv6" ]; then
		echo "External IPv6 Address: $external_ipv6"
	else
		echo "External IPv6 Address: Not available"
	fi

	echo "External IPv4 Address: $external_ipv4"
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

# Execute the exercism command with the given arguments and handle output.
#
# This function wraps the 'exercism' command, capturing its output into an array and printing it.
# If the first argument is "download" and the last line of output is a directory, it changes
# the current directory to that location. This is useful for quickly navigating to newly
# downloaded exercises. The function returns 1 if unable to change directory.
#
# Arguments:
#   $@ - Arguments passed to the exercism command.
#
# Usage:
#   exercism download <exercise> - Downloads the exercise and changes into the directory.
#   exercism submit <file> - Submits the specified file.
exercism() {
	local out
	readarray -t out < <(command exercism "$@")
	printf '%s\n' "${out[@]}"
	if [[ $1 == "download" && -d "${out[-1]}" ]]; then
		cd "${out[-1]}" || return 1
	fi
}

# Run BATS tests with skipped tests included
bats() {
	BATS_RUN_SKIPPED=true command bats ./*.bats
}
