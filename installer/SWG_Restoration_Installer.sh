#!/usr/bin/env bash
#
# Display project information and license
printf '\n'
printf 'Star Wars Galaxies Restoration - Unofficial Linux Installer\n'
printf 'Copyright (c) 2026 pekas1969\n'
printf 'Licensed under the MIT License: https://github.com/pekas69/swg-restoration-linux/blob/main/LICENSE\n'

# Clickable GitHub profile link in terminals supporting OSC 8
printf 'Original author: \033]8;;https://github.com/pekas1969\033\\pekas1969\033]8;;\033\\\n'
printf 'Ingame Name(s) : Rayst Bakhar (Aline | Bridget)\n'
printf '\n'
#
# SWG Restoration Installer
# Version 0.2
#
# Automatically prepares Wine, creates a dedicated 64-bit Wine prefix,
# installs required components, downloads and launches the SWG:R installer.
#
# Supported distribution families:
#   Debian, Ubuntu, Linux Mint, Pop!_OS
#   Fedora, Nobara, RHEL-compatible distributions
#   openSUSE
#   Arch Linux, Manjaro, EndeavourOS
#
# This script does not modify the default ~/.wine prefix.

set -Eeuo pipefail

readonly SCRIPT_NAME="SWG Restoration Installer"
readonly PREFIX_PATH="${HOME}/.swgrestoration"
readonly DOWNLOAD_DIR="${HOME}/.cache/swgrestoration"
readonly INSTALLER_FILE="${DOWNLOAD_DIR}/SWG Restoration Install.exe"
readonly INSTALLER_URL="https://patch.swgr.media/patch/launcher/SWG%20Restoration%20Install.exe"
readonly REPO_RAW_BASE="raw.githubusercontent.com/pekas1969/swg-restoration-linux/master/installer/install"

# ------------------------------------------------------------
# General functions
# ------------------------------------------------------------

log() {
    printf '[INFO] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

die() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Display a useful error if an unexpected command fails.
trap 'status=$?; printf "[ERROR] Command failed at line %s (exit code %s).\n" "$LINENO" "$status" >&2; exit "$status"' ERR

# ------------------------------------------------------------
# Step 1: Detect the Linux distribution
# ------------------------------------------------------------

[[ -r /etc/os-release ]] ||
    die "Cannot identify your Linux distribution: /etc/os-release is missing."

# shellcheck disable=SC1091
source /etc/os-release

DISTRO_ID="${ID,,}"
DISTRO_LIKE="${ID_LIKE:-}"
DISTRO_LIKE="${DISTRO_LIKE,,}"

log "${SCRIPT_NAME}"
log "Detected distribution: ${PRETTY_NAME:-$DISTRO_ID}"

PKG_MANAGER=""
WINE_PACKAGES=()
WINETRICKS_PACKAGES=(winetricks)
DOWNLOAD_PACKAGES=()

# ------------------------------------------------------------
# Step 2: Select package manager and package names
# ------------------------------------------------------------

case "$DISTRO_ID" in
    debian|ubuntu|linuxmint|pop|elementary|zorin|kali|neon)
        PKG_MANAGER="apt-get"
        WINE_PACKAGES=(wine wine64)
        DOWNLOAD_PACKAGES=(curl)
        ;;

    fedora|nobara|rhel|rocky|almalinux|ol|centos)
        if command_exists dnf; then
            PKG_MANAGER="dnf"
        elif command_exists yum; then
            PKG_MANAGER="yum"
        else
            die "No supported RPM package manager was found."
        fi
        WINE_PACKAGES=(wine)
        DOWNLOAD_PACKAGES=(curl)
        ;;

    opensuse*|suse)
        PKG_MANAGER="zypper"
        WINE_PACKAGES=(wine)
        DOWNLOAD_PACKAGES=(curl)
        ;;

    arch|manjaro|endeavouros|garuda|artix)
        PKG_MANAGER="pacman"
        WINE_PACKAGES=(wine)
        DOWNLOAD_PACKAGES=(curl)
        ;;

    *)
        # Fallback for derivatives with an unfamiliar distribution ID.
        if [[ " $DISTRO_LIKE " == *" debian "* ||
              " $DISTRO_LIKE " == *" ubuntu "* ]] &&
              command_exists apt-get; then
            PKG_MANAGER="apt-get"
            WINE_PACKAGES=(wine wine64)
            DOWNLOAD_PACKAGES=(curl)

        elif [[ " $DISTRO_LIKE " == *" fedora "* ||
                " $DISTRO_LIKE " == *" rhel "* ]] &&
                command_exists dnf; then
            PKG_MANAGER="dnf"
            WINE_PACKAGES=(wine)
            DOWNLOAD_PACKAGES=(curl)

        elif [[ " $DISTRO_LIKE " == *" suse "* ]] &&
                command_exists zypper; then
            PKG_MANAGER="zypper"
            WINE_PACKAGES=(wine)
            DOWNLOAD_PACKAGES=(curl)

        elif [[ " $DISTRO_LIKE " == *" arch "* ]] &&
                command_exists pacman; then
            PKG_MANAGER="pacman"
            WINE_PACKAGES=(wine)
            DOWNLOAD_PACKAGES=(curl)

        else
            die "Your distribution is not supported automatically yet. Please install Wine with 64-bit support, Winetricks and curl manually."
        fi
        ;;
esac

command_exists "$PKG_MANAGER" ||
    die "Required package manager '$PKG_MANAGER' was not found."

# ------------------------------------------------------------
# Step 3: Check installed commands
# ------------------------------------------------------------

WINE_AVAILABLE=false
WINETRICKS_AVAILABLE=false

if command_exists wine || command_exists wine64; then
    WINE_AVAILABLE=true
fi

if command_exists winetricks; then
    WINETRICKS_AVAILABLE=true
fi

if [[ "$WINE_AVAILABLE" == true ]]; then
    if command_exists wine; then
        log "Wine is installed: $(wine --version 2>/dev/null || printf 'version unavailable')"
    else
        log "A wine64 executable was found."
    fi
else
    log "Wine was not found."
fi

if [[ "$WINETRICKS_AVAILABLE" == true ]]; then
    log "Winetricks is installed."
else
    log "Winetricks was not found."
fi

# ------------------------------------------------------------
# Step 4: Determine missing packages
# ------------------------------------------------------------

PACKAGES_TO_INSTALL=()

if [[ "$WINE_AVAILABLE" == false ]]; then
    PACKAGES_TO_INSTALL+=("${WINE_PACKAGES[@]}")
fi

if [[ "$WINETRICKS_AVAILABLE" == false ]]; then
    PACKAGES_TO_INSTALL+=("${WINETRICKS_PACKAGES[@]}")
fi

# curl is the preferred downloader. Install it if neither curl
# nor wget is available.
if ! command_exists curl && ! command_exists wget; then
    PACKAGES_TO_INSTALL+=("${DOWNLOAD_PACKAGES[@]}")
fi

# Remove duplicate package names.
UNIQUE_PACKAGES=()

for package in "${PACKAGES_TO_INSTALL[@]}"; do
    found=false

    for existing in "${UNIQUE_PACKAGES[@]}"; do
        if [[ "$package" == "$existing" ]]; then
            found=true
            break
        fi
    done

    if [[ "$found" == false ]]; then
        UNIQUE_PACKAGES+=("$package")
    fi
done

# ------------------------------------------------------------
# Step 5: Install missing packages
# ------------------------------------------------------------

if (("${#UNIQUE_PACKAGES[@]}" > 0)); then
    log "Package manager: $PKG_MANAGER"
    log "Packages to install: ${UNIQUE_PACKAGES[*]}"

    if [[ "$EUID" -eq 0 ]]; then
        SUDO=()
    else
        command_exists sudo ||
            die "sudo is required to install system packages."

        SUDO=(sudo)
        log "Administrator permission may be requested."
        sudo -v || die "Administrator authentication failed."
    fi

    case "$PKG_MANAGER" in
        apt-get)
            "${SUDO[@]}" apt-get update
            "${SUDO[@]}" apt-get install -y "${UNIQUE_PACKAGES[@]}"
            ;;

        dnf)
            "${SUDO[@]}" dnf install -y "${UNIQUE_PACKAGES[@]}"
            ;;

        yum)
            "${SUDO[@]}" yum install -y "${UNIQUE_PACKAGES[@]}"
            ;;

        zypper)
            "${SUDO[@]}" zypper --non-interactive install \
                "${UNIQUE_PACKAGES[@]}"
            ;;

        pacman)
            "${SUDO[@]}" pacman -S --needed "${UNIQUE_PACKAGES[@]}"
            ;;

        *)
            die "Internal error: unsupported package manager."
            ;;
    esac
else
    log "No system packages need to be installed."
fi

# Verify required commands.
if ! command_exists wine && ! command_exists wine64; then
    die "Wine was not found after package installation. Check your repositories."
fi

command_exists winetricks ||
    die "Winetricks was not found after package installation."

if ! command_exists curl && ! command_exists wget; then
    die "Neither curl nor wget is available for downloading the installer."
fi

log "Wine and Winetricks are ready."

if command_exists wine; then
    log "Wine version: $(wine --version 2>/dev/null || printf 'version unavailable')"
fi

# ------------------------------------------------------------
# Step 6: Prepare the dedicated Wine prefix
# ------------------------------------------------------------

log "Preparing the SWG Restoration Wine prefix..."

export WINEPREFIX="$PREFIX_PATH"

if [[ -e "$PREFIX_PATH" ]]; then
    [[ -f "$PREFIX_PATH/system.reg" ]] ||
        die "The prefix path exists but is not a valid Wine prefix: $PREFIX_PATH"

    # Never recreate or overwrite an existing prefix.
    if ! grep -qi '^#arch=win64' "$PREFIX_PATH/system.reg"; then
        die "The existing prefix could not be confirmed as 64-bit. It has not been modified."
    fi

    warn "An existing 64-bit prefix was found and will be reused."
else
    log "Creating a new 64-bit Wine prefix..."

    WINEARCH=win64 wineboot -i ||
        die "Failed to create the 64-bit Wine prefix."
fi

# ------------------------------------------------------------
# Step 7: Install required Windows components
# ------------------------------------------------------------

log "Installing required Windows components via Winetricks."
log "This may take several minutes."

winetricks -q \
    d3dcompiler_43 \
    d3dx9 \
    d3dx10 \
    xact \
    xact_x64 \
    vcrun2022 \
    corefonts \
    dxvk \
    win10 ||
    die "Winetricks failed while installing the required components."

log "Applying Wine configuration settings..."

winetricks -q hidewineexports=enable ||
    die "Failed to apply hidewineexports."

winetricks -q windowmanagerdecorated=n ||
    die "Failed to apply windowmanagerdecorated."

winetricks -q windowmanagermanaged=y ||
    die "Failed to apply windowmanagermanaged."

log "Wine configuration completed."

# ------------------------------------------------------------
# Step 8: Download and install necessary files
# ------------------------------------------------------------


# GitHub repository containing the additional installation files.

download_asset() {
    local url="$1"
    local destination="$2"#

    if command -v curl >/dev/null 2>&1; then
            curl --fail --location --retry 3 \
            --output "$destination" "$url" ||
            die "Failed to download: $url"
    elif command -v wget >/dev/null 2>&1; then
        wget --tries=3 \
            --output-document="$destination" "$url" ||
            die "Failed to download: $url"
    else
        die "Neither curl nor wget is available."
    fi
}


configure_game_files() {
    local game_dir="${PREFIX_PATH}/drive_c/SWG Restoration"
    local options_file="${game_dir}/options.cfg"
    local user_file="${game_dir}/user.cfg"
    local desktop_template="${DOWNLOAD_DIR}/SWG_Restoration.desktop.template"
    local desktop_file="${HOME}/SWG_Restoration.desktop"
    local choice

    # First launcher startup and initial game setup
    clear
    echo
    echo "============================================================"
    echo " Initial Launcher Setup"
    echo "============================================================"
    echo
    echo "It is now time to start the launcher and download the missing game data."
    echo
    echo "If you already have an account, log in."
    echo "Otherwise, register at https://swgr.org"
    echo
    echo "Log in to the launcher and let it download and install the required updates."
    echo
    echo "Follow these steps:"
    echo
    echo "  1. Click Play once. The updater will check all required components and download any missing files."
    echo
    echo "  2. Click Play again to open the Game Settings."
    echo "     Switch to the Graphics tab and enable:"
    echo "       - Windowed Mode"
    echo "       - Borderless Window"
    echo
    echo "  3. Close the settings window, then click Save in both the launcher"
    echo "     settings and the Game Settings."
    echo
    echo "  4. Do NOT start the game yet! Exit the launcher completely."
    echo
    echo "Press any key to start the launcher"
    read -r
    echo
    echo
    echo "Starting SWG Restoration.exe..."
    echo "Please wait until the process has finished."
    echo

    # Start the launcher executable and wait for it to exit
    (
        cd "$game_dir" || exit 1
        wine "SWG Restoration.exe"
    )

    echo
    echo "Press any key to continue after the launcher has finished all updates, all game settings are set and the launcher has been closed"
    read -r

    log "Configuring SWG Restoration..."

    [[ -d "$game_dir" ]] ||
        die "Game directory not found: $game_dir"

    # Update or create user.cfg without duplicating the setting.
    ensure_multiple_instances_setting() {
        local cfg="$1"
        local tmp

        tmp=$(mktemp) ||
            die "Could not create a temporary configuration file."

        awk '
        BEGIN {
            in_section = 0
            found_section = 0
            setting_written = 0
        }

        /^\[[^]]+\][[:space:]]*$/ {
            if (in_section && !setting_written) {
                print "allowMultipleInstances=true"
                setting_written = 1
            }

            in_section = ($0 ~ /^\[SwgClient\][[:space:]]*$/)

            if (in_section)
                found_section = 1

            print
            next
        }

        in_section && /^[[:space:]]*allowMultipleInstances[[:space:]]*=/ {
            if (!setting_written) {
                print "allowMultipleInstances=true"
                setting_written = 1
            }
            next
        }

        { print }

        END {
            if (in_section && !setting_written) {
                print "allowMultipleInstances=true"
                setting_written = 1
            }

            if (!found_section) {
                print ""
                print "[SwgClient]"
                print "allowMultipleInstances=true"
            }
        }
        ' "$cfg" > "$tmp" || {
            rm -f "$tmp"
            die "Failed to update $cfg."
        }

        cat "$tmp" > "$cfg" || {
            rm -f "$tmp"
            die "Failed to write $cfg."
        }

        rm -f "$tmp"
    }

    printf '\n'
    printf '%s\n' "Multiple client instances configuration"
    printf '%s\n' "----------------------------------------"

    if [[ -f "$user_file" ]]; then
        printf '1) Replace user.cfg with options.cfg and enable multiple instances.\n'
        printf '2) Keep the existing user.cfg and update its multiple-instance setting.\n'
        printf '3) Leave user.cfg unchanged and continue.\n'
    else
        printf '1) Create user.cfg from options.cfg and enable multiple instances.\n'
        printf '2) Unavailable: no existing user.cfg was found.\n'
        printf '3) Leave user.cfg uncreated and continue.\n'
    fi

    while true; do
        printf '\n'
        read -r -n 1 -p "Choose [1-3]: " choice
        printf '\n'

        case "$choice" in
            1)
                [[ -f "$options_file" ]] ||
                    die "options.cfg not found: $options_file"

                cp "$options_file" "$user_file" ||
                    die "Failed to copy options.cfg to user.cfg."

                ensure_multiple_instances_setting "$user_file"

                log "user.cfg created from options.cfg."
                log "Multiple client instances enabled."
                break
                ;;

            2)
                if [[ ! -f "$user_file" ]]; then
                    warn "No existing user.cfg is available to modify."
                    continue
                fi

                ensure_multiple_instances_setting "$user_file"

                log "Existing user.cfg updated."
                log "Multiple client instances enabled."
                break
                ;;

            3)
                warn "user.cfg was left unchanged."

                printf '\n'
                printf '%s\n' \
                    "Multiple client instances may not work unless user.cfg contains:"
                printf '\n'
                printf '%s\n' \
                    '[SwgClient]' \
                    'allowMultipleInstances=true'
                printf '\n'

                read -r -n 1 -s -p "Press any key to continue..."
                printf '\n'
                break
                ;;

            *)
                warn "Invalid choice. Please select 1, 2 or 3."
                ;;
        esac
    done

    # Download the game icon.
    download_asset \
        "${REPO_RAW_BASE}/Resto_Icon.png" \
        "${game_dir}/Resto_Icon.png"

    # Download the launcher and make it executable.
    download_asset \
        "${REPO_RAW_BASE}/Start_SWG_Restoration.sh" \
        "${game_dir}/Start_SWG_Restoration.sh"

    chmod +x "${game_dir}/Start_SWG_Restoration.sh" ||
        die "Failed to make the launcher executable."

    log "Game icon and launcher installed."

    # Download and personalize the desktop entry.
    download_asset \
        "${REPO_RAW_BASE}/SWG_Restoration.desktop" \
        "$desktop_template"

    sed "s|/home/<username>|${HOME}|g" \
        "$desktop_template" > "$desktop_file" ||
        die "Failed to create the desktop entry."

    chmod +x "$desktop_file" ||
        die "Failed to make the desktop entry executable."

    log "Desktop entry created: $desktop_file"

    # Installation summary.
    printf '\n\033[1;36m'
    printf '%s\n' "=============================================="
    printf '%s\n' " SWG Restoration setup completed"
    printf '%s\n' "=============================================="
    printf '\033[0m'

    printf '\nGame installation directory:\n  %s\n' "$game_dir"
    printf '\nLauncher:\n  %s\n' "${game_dir}/Start_SWG_Restoration.sh"
    printf 'Start the game with the launcher above.\n'

    printf '\nDesktop entry:\n  %s\n' "$desktop_file"
    printf 'Use it to launch the game, or copy it elsewhere.\n'

    #printf '\nFor automatic splitscreen/dualbox setup, see:\n'
    #printf '%s\n' \
    #    "https://github.com/pekas1969/swg-restoration-linux/tree/main/splitscreen-setup"

    #printf '\n'
}

# ------------------------------------------------------------
# Step 9: Download the official SWG Restoration installer
# ------------------------------------------------------------

mkdir -p "$DOWNLOAD_DIR" ||
    die "Could not create the download directory."

log "Downloading the official SWG Restoration installer..."

if command_exists curl; then
    curl --fail --location --retry 3 \
        --output "$INSTALLER_FILE" \
        "$INSTALLER_URL" ||
        die "Failed to download the SWG Restoration installer."
else
    wget --tries=3 \
        --output-document="$INSTALLER_FILE" \
        "$INSTALLER_URL" ||
        die "Failed to download the SWG Restoration installer."
fi

[[ -s "$INSTALLER_FILE" ]] ||
    die "The downloaded installer is missing or empty."

log "Download completed successfully."


# ------------------------------------------------------------
# Step 10: Launch the SWG Restoration installer
# ------------------------------------------------------------

log "Starting the SWG Restoration installer."
log "Follow the instructions in the installer window."

wine "$INSTALLER_FILE" ||
    #die "The SWG Restoration installer exited with an error."

    log "The SWG Restoration installer has closed."

# ------------------------------------------------------------
# Step 11: Configure a last few thing
# ------------------------------------------------------------

configure_game_files

log "Files downloaded and installed."
# ------------------------------------------------------------
# Step 11: Finish
# ------------------------------------------------------------

log "The SWG Restoration installer has closed."
log "Please verify that the game installation completed successfully."
log "Wine prefix: $PREFIX_PATH"
log "Installer download: $INSTALLER_FILE"
log "Installation preparation finished."
