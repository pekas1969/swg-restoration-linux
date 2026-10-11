# Star Wars Galaxies Restoration – Linux Installer

A community-maintained installer to help Linux users install and run **Star Wars Galaxies Restoration** using Wine.

The project aims to simplify the setup process by automating the installation of required system packages, creating a dedicated 64-bit Wine prefix, configuring Windows compatibility components, and launching the official SWG Restoration installer.

The installer is designed to support multiple Linux distributions, including openSUSE, Debian-based distributions, Fedora, and Arch Linux.

## Features

- Automatic detection of supported Linux distribution families

- Installation of required system packages

- Dedicated 64-bit Wine prefix

- Automated setup of required Windows compatibility components using Winetricks

- Download and launch of the official SWG Restoration installer

- Separate game launcher script

- Desktop launcher integration

## Requirements

- A supported 64-bit Linux distribution

- A working internet connection

- A graphical desktop environment

- A working graphics driver with support for the required 3D features

- `sudo` privileges for installing system packages

- Sufficient disk space for the game client and its downloaded files

Wine, Winetricks, and other required dependencies are handled by the installation script where supported. Package availability and package names may vary between distributions.

## Supported distributions

The installer includes package-management support for the following distribution families:

| Distribution family | Examples |
| - | - |
| Debian-based | Debian, Ubuntu and derivatives |
| Fedora-based | Fedora and compatible distributions |
| openSUSE | openSUSE Tumbleweed and compatible releases |
| Arch-based | Arch Linux and compatible distributions |


**Note:** Support for a distribution family does not guarantee that every derivative or configuration has been tested. Graphics drivers, Wine versions, package availability, and desktop environments may affect compatibility.

## Installation

### 1. Download the installer

Download [`SWG_Restoration_Installer.sh`](https://raw.githubusercontent.com/pekas69/swg-restoration-linux/main/SWG_Restoration_Installer.sh) directly from GitHub.

You do not need to clone or download the entire repository. The installer automatically downloads the additional resources it needs, including the application icon and desktop launcher template, and copies them to their appropriate locations.

Alternatively, if you want to clone the repository:

```
git clone https://github.com/pekas69/swg-restoration-linux.git

cd swg-restoration-linux
```

### 2. Make the installer executable

Open a terminal in the directory where you downloaded the script and run:

```
chmod +x SWG_Restoration_Installer.sh
```

### 3. Run the installer

```
./SWG_Restoration_Installer.sh
```

The installer will guide you through the setup process. Depending on your Linux distribution, it may request your password to install the required system packages.

The script prepares the Wine environment, installs the required compatibility components, downloads the additional project resources, and starts the official SWG Restoration installer.

Follow the on-screen instructions to complete the game installation.

### 4. Start the game

Once installation is complete, use the desktop launcher created by the installer, or run the game launcher script from its installed location.

No Git checkout or manual copying of the project's additional resources is required.

## Starting the game

After installation, use the supplied game launcher script:

```
./SWG_Restoration.sh
```

If the launcher has not yet been made executable, run:

```
chmod +x SWG_Restoration.sh
```

A desktop shortcut can also be used if it has been created and configured by the installer.

## Wine prefix

The installation uses a dedicated 64-bit Wine prefix:

```
~/.swgrestoration
```

This keeps the game's Wine configuration separate from other Windows applications installed on your system.

To run Wine commands against this prefix manually, use:

```
WINEPREFIX="$HOME/.swgrestoration" winecfg
```

**Do not delete the Wine prefix if you want to preserve your installation and configuration.** Back up the prefix before making significant changes.

## Troubleshooting

### The installer cannot install a package

Make sure your system is up to date and that the required repositories are enabled. Package names and availability differ between Linux distributions.

### Wine or Winetricks reports an error

Check that Wine and Winetricks are installed correctly. Review the terminal output for the exact error before attempting to recreate or modify the Wine prefix.

### The game does not start

- Run the launcher from a terminal to see diagnostic output.

- Check that your graphics driver supports the required 3D functionality.

- Verify that the game installation completed successfully.

- Avoid changing Wine or Winetricks settings without first backing up the working configuration.

### The game runs poorly or displays graphical glitches

Performance and compatibility depend on your hardware, graphics drivers, Wine version, and configuration. Results may vary between systems

## Updating and backups

Back up your game installation, launcher scripts, and Wine prefix before performing major updates or configuration changes.

Updating this repository does not necessarily update the installed game client. Follow the official SWG Restoration update process for game updates.

## Disclaimer

This is an unofficial community project. It is not affiliated with, endorsed by, or supported by the official SWG Restoration team unless explicitly stated otherwise.

Star Wars Galaxies Restoration and its associated game assets remain the property of their respective rights holders. Users must comply with the game's official terms and requirements.

## Contributing

Contributions, bug reports, and suggestions for improvements are welcome.

For bug reports, please see [Support and Bug Reports](https://chatgpt.com/c/6acba3e9-668c-83ed-acd5-5c13d6c4ba46#support-and-bug-reports).

When contributing code, please retain the existing copyright notices and MIT License terms.

## License

This project is licensed under the [MIT License](https://chatgpt.com/c/LICENSE).

You are free to use, copy, modify, distribute, sublicense, and sell this software, provided that the original copyright notice and the license text are retained.

Original author: [pekas1969](https://github.com/pekas1969).


***May the Force be with you!***

