#!/bin/sh -e

# Clone the repository from the $HOME directory
# Navigate to the $HOME/mybash directory and execute the script

# Define color codes for terminal output
RC='\033[0m'      # Reset color
RED='\033[31m'    # Red color
YELLOW='\033[33m' # Yellow color
GREEN='\033[32m'  # Green color

# Define top-level variables for easy access across functions
PACKAGER="" # Package manager command
SUDO_CMD="" # Privilege escalation command
SUGROUP=""  # Superuser group name
GITPATH=""  # Path to the Git repository

# Function to check if a command exists
command_exists() {
    # Use command -v to check if the command is available
    command -v "$1" >/dev/null 2>&1
}

# Function to check environment requirements
check_env() {
    # Define required commands and packages
    REQUIREMENTS='curl groups sudo'

    # Check if each requirement is met
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            # Print error message and exit if a requirement is not met
            echo "${RED}To run me, you need: $REQUIREMENTS${RC}"
            exit 1
        fi
    done

    # Define supported package managers
    PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'

    # Find the first available package manager
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            # Set the package manager command
            PACKAGER="$pgm"
            echo "Using $pgm"
            break
        fi
    done

    # Exit if no package manager is found
    if [ -z "$PACKAGER" ]; then
        echo "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    # Determine the privilege escalation command
    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    # Print the chosen privilege escalation command
    echo "Using $SUDO_CMD as privilege escalation software"

    # Get the path to the Git repository
    GITPATH=$(dirname "$(realpath "$0")")

    # Check if the current directory is writable
    if [ ! -w "$GITPATH" ]; then
        # Print error message and exit if the directory is not writable
        echo "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi

    # Define superuser groups
    SUPERUSERGROUP='wheel sudo root'

    # Find the first matching superuser group
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            # Set the superuser group name
            SUGROUP="$sug"
            echo "Super user group $SUGROUP"
            break
        fi
    done

    # Check if the user is a member of the sudo group
    if ! groups | grep -q "$SUGROUP"; then
        # Print error message and exit if the user is not a member
        echo "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

# Function to install dependencies
install_dependencies() {
    # Define dependencies to install
    DEPENDENCIES='bash bash-completion tar bat tree multitail fastfetch wget unzip fontconfig fzf neovim python3-neovim'

    # Print installation message
    echo "${YELLOW}Installing dependencies...${RC}"

    # Handle installation based on package manager
    if [ "$PACKAGER" = "pacman" ]; then
        # Check if AUR helper (yay or paru) is installed
        if ! command_exists yay && ! command_exists paru; then
            # Install yay as AUR helper
            echo "Installing yay as AUR helper..."
            ${SUDO_CMD} "${PACKAGER}" --noconfirm -S base-devel
            cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
            cd yay-git && makepkg --noconfirm -si
        else
            echo "AUR helper already installed"
        fi

        # Determine AUR helper to use
        if command_exists yay; then
            AUR_HELPER="yay"
        elif command_exists paru; then
            AUR_HELPER="paru"
        else
            # Exit if no AUR helper is found
            echo "No AUR helper found. Please install yay or paru."
            exit 1
        fi

        # Install dependencies using AUR helper
        ${AUR_HELPER} --noconfirm -S "${DEPENDENCIES}"
    elif [ "$PACKAGER" = "nala" ]; then
        # Install dependencies using Nala package manager
        ${SUDO_CMD} "${PACKAGER}" install -y "${DEPENDENCIES}"
    elif [ "$PACKAGER" = "emerge" ]; then
        # Install dependencies using Gentoo's emerge package manager
        ${SUDO_CMD} "${PACKAGER}" -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch
    elif [ "$PACKAGER" = "xbps-install" ]; then
        # Install dependencies using Void Linux's xbps-install package manager
        ${SUDO_CMD} "${PACKAGER}" -v "${DEPENDENCIES}"
    elif [ "$PACKAGER" = "nix-env" ]; then
        # Install dependencies using Nix package manager
        ${SUDO_CMD} "${PACKAGER}" -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch
    elif [ "$PACKAGER" = "dnf" ]; then
        # Install dependencies using DNF package manager
        ${SUDO_CMD} "${PACKAGER}" check-update
        ${SUDO_CMD} "${PACKAGER}" upgrade -y
        ${SUDO_CMD} "${PACKAGER}" install -y "${DEPENDENCIES}"
    else
        # Install dependencies using default package manager
        ${SUDO_CMD} "${PACKAGER}" install -yq "${DEPENDENCIES}"
    fi

    # Check if MesloLGS Nerd Font is installed
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Font '$FONT_NAME' is installed."
    else
        # Download and install MesloLGS Nerd Font
        echo "Installing font '$FONT_NAME'"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"

        # Check if font URL is accessible
        if wget -q --spider "$FONT_URL"; then
            # Download font and extract to temporary directory
            TEMP_DIR=$(mktemp -d)
            wget -q --show-progress $FONT_URL -O "$TEMP_DIR"/"${FONT_NAME}".zip
            unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"

            # Move font files to font directory
            mkdir -p "$FONT_DIR"/"$FONT_NAME"
            mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"

            # Update font cache
            fc-cache -fv

            # Clean up temporary directory
            rm -rf "${TEMP_DIR}"
            echo "'$FONT_NAME' installed successfully."
        else
            echo "Font '$FONT_NAME' not installed. Font URL is not accessible."
        fi
    fi
}

# Install Zoxide if it's not already installed
install_zoxide() {
    # Check if Zoxide is already installed
    if command_exists zoxide; then
        echo "Zoxide is already installed"
        return
    fi

    # Attempt to install Zoxide using the official install script
    if ! curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        # If the installation fails, print an error message and exit with a
        # non-zero status code
        echo "${RED}Error installing Zoxide!${RC}"
        exit 1
    fi
}

# Configure fastfetch by creating the necessary directories and symbolic links
# to the default configuration file
configure_fastfetch() {
    # Retrieve the correct user home directory, considering both sudo and
    # non-sudo scenarios
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

    # Create the fastfetch configuration directory if it doesn't exist
    if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
        mkdir -p "$USER_HOME/.config/fastfetch"
    fi

    # Check if the fastfetch configuration file already exists
    if [ -e "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
        # Remove the existing configuration file to ensure a clean setup
        rm -f "$USER_HOME/.config/fastfetch/config.jsonc"
    fi

    # Create a symbolic link to the default fastfetch configuration file
    ln -svf "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc" || {
        # Handle the error case where the symbolic link creation fails
        echo "${RED}Failed to create symbolic link for fastfetch config${RC}"
        exit 1
    }
}

# Creates symbolic links to the bash configuration files (.bashrc,
# .bash_aliases, .bash_functions) in the user's home directory.
# Before creating the symbolic links, checks if old configuration files exist
# and moves them to a backup location.
link_config() {
    # Retrieve the correct user home directory, considering both sudo and
    # non-sudo scenarios
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

    # Check if existing bash configuration files need to be backed up
    for file in ".bashrc" ".bash_aliases" ".bash_functions"; do
        OLD_FILE="$USER_HOME/$file"
        if [ -e "$OLD_FILE" ]; then
            # Move the existing file to a backup location
            echo "${YELLOW}Moving old $file file to $USER_HOME/${file}.bak${RC}"
            if ! mv "$OLD_FILE" "$USER_HOME/${file}.bak"; then
                # Handle the error case where the file move fails
                echo "${RED}Can't move the old $file file!${RC}"
                exit 1
            fi
        fi
    done

    # Create symbolic links to the new configuration files
    for file in ".bashrc" ".bash_aliases" ".bash_functions"; do
        echo "${YELLOW}Linking new $file file...${RC}"
        ln -svf "$GITPATH/$file" "$USER_HOME/$file" || {
            # Handle the error case where the symbolic link creation fails
            echo "${RED}Failed to create symbolic link for $file${RC}"
            exit 1
        }
    done
}

check_env
install_dependencies
install_zoxide
configure_fastfetch

if link_config; then
    printf '%s\n' "${GREEN}Done! Restart your shell to see the changes.${RC}"
else
    printf '%s\n' "${RED}Something went wrong!${RC}"
fi
