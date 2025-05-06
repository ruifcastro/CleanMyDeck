#!/bin/bash

# This script cleans up various temporary and cached files on a Steam Deck
# It removes downloading game files, shader caches, library cache, logs,
# and disables/removes the swap file.

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting Steam Deck cleanup..."
echo ""

echo "Your Current Home Disk Usage..."
du -sh /home/
echo "" 

# Remove downloading game files
echo "Removing downloading game files..."
rm -rf /home/deck/.steam/steam/steamapps/downloading/
echo "-> Download files removal complete."
echo ""

# Clean unused flatpak apps
echo "Removing unused flatpak apps..."
flatpak uninstall --unused
# flatpak repair
echo ""

# Remove shader caches
echo "Removing shader caches..."
rm -rf /home/deck/.steam/steam/steamapps/shadercache/
echo "-> Shader cache removal complete."
echo ""

# Remove old banner library cache
echo "Removing old banner library cache..."
rm -rf /home/deck/.local/share/Steam/appcache/librarycache/
echo "-> Library cache removal complete."
echo ""

# Remove Steam logs
echo "Removing Steam logs..."
rm -rf /home/deck/.local/share/Steam/logs/
echo "-> Steam logs removal complete."
echo ""

# Disable and reduce swap file size
echo "Disabling and reduce swap file size..."
# Check if swapfile exists before trying to disable/remove
if [ -f /home/swapfile ]; then
    sudo swapoff /home/swapfile
    sudo rm -r /home/swapfile
    echo "-> Swap file cleanup complete."
else
    echo "-> No swap file found at /home/swapfile. Skipping swap cleanup."
fi
echo ""

# Define the base path where the userdata directories are located
STEAM_USERDATA_PATH="/home/deck/.local/share/Steam/userdata"
if [ -d "$STEAM_USERDATA_PATH" ]; then 
    # Find all directories named 'librarycache' under each user ID's config folder
    # and delete them recursively and forcefully.
    echo "Searching for and deleting librarycache folders under $STEAM_USERDATA_PATH..."

    find "$STEAM_USERDATA_PATH" -type d -path "*/config/librarycache" -print -exec rm -rf {} +

    echo "-> Steam config/librarycache removal complete."
else
    echo "Searching for and deleting librarycache folders under $STEAM_USERDATA_PATH..."
    echo "-> No Steam userdata found. Skipping config/librarycache cleanup."
fi
echo ""

read -p "Do you want to delete these empty directories? (y/N): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  echo "Deleting empty directories..."
  find /home/deck/ -maxdepth 1 -type d -empty -delete
  echo "-> Empty directories removal complete."
else
  echo "-> No directories will be deleted."
fi
echo "" 

# Remove uninstalled game compatdata 
echo "Removing uninstalled game compatdata..."
curl -sSL https://raw.githubusercontent.com/scawp/Steam-Deck.Shader-Cache-Killer/main/zShaderCacheKiller.sh | bash to run zShaderCacheKiller 
echo "-> Uninstalled game compatdata removal complete."
echo ""

echo "And now, Your Current Home Disk Usage..."
# df -h /home/
du -sh /home/
echo ""

echo "Steam Deck cleanup finished."
echo ""

# Open the common games folder in Dolphin for manual cleanup
echo "Opening the common games folder in Dolphin for manual cleanup..."
dolphin "/home/deck/.steam/steam/steamapps/common/"
echo ""

echo "Automatic cleanup steps finished."
echo "Please manually review the folders that opened in Dolphin to delete any unwanted game files."
echo ""
