#!/bin/bash

# This script cleans up various temporary and cached files on a Steam Deck
# It allows you to select which cleanup options to execute, with an option for all.

echo "Starting Steam Deck cleanup..."
echo ""

echo "Your Current Home Disk Usage..."
df -h /
echo ""

OPTIONS=(
  "Remove Steam Download Cache"
  "Remove Flatpak Unused Apps"
  "Repair Flatpak"
  "Remove Steam Shader Caches"
  "Remove Steam Old Banner Library Cache"
  "Remove Steam Logs"
  "Remove Trash"
  "Reduce Swapfile Size"
  "Fix Steam Activity Tab Stuck Bug (config/librarycache)"
  "Remove User Cache"
  "Manual Removal of Uninstalled Game Compatdata (using zShaderCacheKiller.sh)"
  "Manual removal of Common Game Folders (using Dolphin)"
)

FUNCTIONS=(
  "remove_downloading_files"
  "remove_flatpak_unused_apps"
  "repair_flatpak"
  "remove_shader_cache"
  "remove_library_cache"
  "remove_steam_logs"
  "remove_trash"
  "reduce_swap"
  "fix_config_library_cache"
  "remove_user_cache"
  "remove_compatdata"
  "open_dolphin_common"
)

# Function definitions
remove_downloading_files() {
  rm -rf /home/deck/.steam/steam/steamapps/downloading/
  echo "-> Download files removal complete."
}

remove_flatpak_unused_apps() {
  flatpak uninstall --unused
}

repair_flatpak() {
  flatpak repair
}

remove_shader_cache() {
  rm -rf /home/deck/.steam/steam/steamapps/shadercache/
  echo "-> Shader cache removal complete."
}

remove_trash() {
  rm -rf /home/deck/.local/share/Trash/
  echo "-> Trash removal complete."
}

remove_library_cache() {
  rm -rf /home/deck/.local/share/Steam/appcache/librarycache/
  echo "-> Library cache removal complete."
}

remove_steam_logs() {
  rm -rf /home/deck/.local/share/Steam/logs/
  echo "-> Steam logs removal complete."
}

remove_user_cache() {
  rm -rf /home/deck/.cache/
  echo "-> User Cache removal complete."
}


reduce_swap() {
  if [ -f /home/swapfile ]; then
    sudo swapoff /home/swapfile
    sudo rm -r /home/swapfile
    echo "-> Swap file cleanup complete."
  else
    echo "-> No swap file found at /home/swapfile. Skipping swap cleanup."
  fi
}

fix_config_library_cache() {
  STEAM_USERDATA_PATH="/home/deck/.local/share/Steam/userdata"
  if [ -d "$STEAM_USERDATA_PATH" ]; then
    find "$STEAM_USERDATA_PATH" -type d -path "*/config/librarycache" -print -exec rm -rf {} +
    echo "-> Steam config/librarycache removal complete."
  else
    echo "-> No Steam userdata found. Skipping config/librarycache cleanup."
  fi
}

remove_empty_dirs() {
  read -p "Do you want to delete these empty directories? (y/N): " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    find /home/deck/.local/share/ -maxdepth 1 -type d -empty -delete
    echo "-> Empty directories removal complete."
  else
    echo "-> No directories will be deleted."
  fi
}

remove_compatdata() {
  curl -sSL https://raw.githubusercontent.com/scawp/Steam-Deck.Shader-Cache-Killer/main/zShaderCacheKiller.sh | bash
  echo "-> Uninstalled game compatdata removal complete."
}

open_dolphin_common() {
  dolphin "/home/deck/.steam/steam/steamapps/common/"
}

# Present the options
echo "Select the options you want to execute (separated by spaces or commas, or '0' for all):"
echo ""
echo "0. All options"
for i in "${!OPTIONS[@]}"; do
  echo "$((i+1)). ${OPTIONS[$i]}"
done
echo ""

read -p "Enter your choices: " choices

# Process the user's choices
if [[ "$choices" == "0" ]]; then
  echo ""
  echo "----------------------------------------"
  echo "Executing all options..."
  echo "----------------------------------------"
  for i in "${!FUNCTIONS[@]}"; do
    echo ""
    echo "----------------------------------------"
    echo "Executing: ${OPTIONS[$i]}"
    "${FUNCTIONS[$i]}"
    echo "----------------------------------------"
  done
else
  IFS=', ' read -ra SELECTED_OPTIONS <<< "$choices"

  for option_index_str in "${SELECTED_OPTIONS[@]}"; do
    if [[ "$option_index_str" =~ ^[0-9]+$ ]]; then
      option_index=$((option_index_str - 1))
      if [[ "$option_index" -ge 0 && "$option_index" -lt "${#FUNCTIONS[@]}" ]]; then
        echo ""
        echo "----------------------------------------"
        echo "Executing: ${OPTIONS[$option_index]}"
        "${FUNCTIONS[$option_index]}"
        echo "----------------------------------------"
      else
        echo "Invalid option: $option_index_str"
      fi
    else
      echo "Invalid input: $option_index_str"
    fi
  done
fi

echo ""
echo "Cleanup process completed based on your selections."
echo ""

echo "And now, Your Current Home Disk Usage..."
df -h /
echo ""
