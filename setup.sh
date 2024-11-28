#!/bin/sh -e

# Define color codes for terminal output
RC='\033[0m'      # Reset color
RED='\033[31m'    # Red color
YELLOW='\033[33m' # Yellow color
GREEN='\033[32m'  # Green color

# Set Linux Toolbox directory path
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

# Create Linux Toolbox directory if it doesn't exist
if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

# Remove existing mybash directory in Linux Toolbox directory
if [ -d "$LINUXTOOLBOXDIR/mybash" ]; then
    rm -rf "$LINUXTOOLBOXDIR/mybash"
fi

# Move current mybash directory to Linux Toolbox directory
echo "${YELLOW}Copying mybash directory into: $LINUXTOOLBOXDIR/mybash${RC}"
if mv -r . "$LINUXTOOLBOXDIR/mybash"; then
    echo "${GREEN}Successfully moved mybash directory${RC}"
else
    echo "${RED}Failed to move mybash directory${RC}"
    exit 1
fi

# Define top-level variables for easy access across functions
PACKAGER="" # Package manager command
SUDO_CMD="" # Privilege escalation command
SUGROUP=""  # Superuser group name
GITPATH=""  # Path to the Git repository

# Change directory to the script's location
cd "$LINUXTOOLBOXDIR/mybash" || exit

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
    DEPENDENCIES='bash bash-completion tar bat tree multitail fastfetch wget unzip fontconfig'

    # Add Neovim to dependencies if it's not already installed
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi

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
        ${SUDO_CMD} "${PACKAGER}" -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch nixos.pkgs.starship
    elif [ "$PACKAGER" = "dnf" ]; then
        # Install dependencies using DNF package manager
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

# Install Starship if it's not already installed
install_starship() {
    # Check if Starship is already installed
    if command_exists starship; then
        echo "Starship is already installed"
        return
    fi

    # Attempt to install Starship using the official install script
    if ! curl -sS https://starship.rs/install.sh | sh; then
        # If the installation fails, print an error message and exit with a
        # non-zero status code
        echo "${RED}Error installing Starship!${RC}"
        exit 1
    fi
}

# Install Fzf if it's not already installed
install_fzf() {
    # Check if Fzf is already installed
    if command_exists fzf; then
        echo "Fzf is already installed"
    else
        # Clone the Fzf repository and install it
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install
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

# Install Neovim if it's not already installed
install_neovim() {
    # Check if Neovim is already installed
    if command_exists nvim; then
        # If Neovim is already installed, print a message and exit early
        echo "Neovim is already installed"
        return
    fi

    # Determine the package manager being used
    case "$PACKAGER" in
    *apt)
        # Install Neovim using the AppImage on Ubuntu-based systems
        echo "Installing Neovim using the AppImage on Ubuntu-based systems"
        if [ ! -d "/opt/neovim" ]; then
            # Download the Neovim AppImage
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            # Make the AppImage executable
            chmod u+x nvim.appimage
            # Extract the AppImage
            ./nvim.appimage --appimage-extract
            # Move the extracted directory to /opt/neovim
            ${SUDO_CMD} mv squashfs-root /opt/neovim
            # Create a symbolic link to AppRun
            ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim
        fi
        ;;
    *zypper)
        # Install Neovim using Zypper on OpenSUSE
        echo "Installing Neovim using Zypper on OpenSUSE"
        ${SUDO_CMD} zypper refresh
        ${SUDO_CMD} zypper -n install neovim
        ;;
    *dnf)
        # Install Neovim using DNF on Fedora-based systems
        echo "Installing Neovim using DNF on Fedora-based systems"
        ${SUDO_CMD} dnf check-update
        ${SUDO_CMD} dnf install -y neovim
        ;;
    *pacman)
        # Install Neovim using Pacman on Arch-based systems
        echo "Installing Neovim using Pacman on Arch-based systems"
        ${SUDO_CMD} pacman -Syu
        ${SUDO_CMD} pacman -S --noconfirm neovim
        ;;
    *)
        # If no supported package manager is found, print an error message and exit
        echo "No supported package manager found. Please install Neovim manually."
        exit 1
        ;;
    esac
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
# .bash_aliases, .bash_functions) and the starship configuration file
# (starship.toml) in the user's home directory.
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

    # Create a symbolic link to the starship configuration file
    echo "${YELLOW}Linking new starship config file...${RC}"
    ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
        # Handle the error case where the symbolic link creation fails
        echo "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
}

check_env
install_dependencies
install_starship
install_fzf
install_zoxide
install_neovim
configure_fastfetch

if link_config; then
    printf '%s\n' "${GREEN}Done! Restart your shell to see the changes.${RC}"
else
    printf '%s\n' "${RED}Something went wrong!${RC}"
fi
