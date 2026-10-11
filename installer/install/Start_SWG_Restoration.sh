#!/bin/bash
cd "$HOME/.swgrestoration/drive_c/SWG Restoration" || exit 1

env -u LD_PRELOAD WINEPREFIX="$HOME/.swgrestoration" DXVK_LOG_LEVEL=info wine "SWG Restoration.exe"
