#!/bin/bash

# Steam Deck Cleanup Script with Zenity GUI

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
  "Manual Removal of Common Game Folders (using Dolphin)"
  "Disk Usage"
  "Execution Log File"
  "Reboot"
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
  "disk_usage"
  "execution_log_file"
  "reboot_after_cleanup"
)

# --- Cleanup Functions ---

reboot_after_cleanup() {
  zenity --question --text="Cleanup complete. Reboot now?" --width=400
  if [[ $? -eq 0 ]]; then
    # Check for nested session
    if [[ $XDG_SESSION_TYPE == "x11" && "$WAYLAND_DISPLAY" ]]; then
      zenity --info --text="Running inside a nested session.\nPlease reboot manually."
    else
      systemctl reboot
    fi
  fi
}

execution_log_file() {
  zenity --question --text="Would you like to save a log file?" --width=400
  if [[ $? -eq 0 ]]; then
    SAVE_PATH=$(zenity --file-selection --save --confirm-overwrite \
      --filename="$HOME/steamdeck-cleanup-$(date +%Y%m%d-%H%M%S).log" \
      --title="Save Cleanup Log As")
    if [[ -n "$SAVE_PATH" ]]; then
      cp "$TMP_LOG" "$SAVE_PATH"
      zenity --info --text="Log saved to:\n$SAVE_PATH"
    fi
  fi
}

disk_usage() {
  du -sh "$HOME/"
}

remove_downloading_files() {
  rm -rf "$HOME/.steam/steam/steamapps/downloading/*"
}

remove_flatpak_unused_apps() {
  flatpak uninstall --unused
}

repair_flatpak() {
  flatpak repair
}

remove_shader_cache() {
  rm -rf "$HOME/.steam/steam/steamapps/shadercache/*"
}

remove_library_cache() {
  rm -rf "$HOME/.local/share/Steam/appcache/librarycache/*"
}

remove_steam_logs() {
  rm -rf "$HOME/.local/share/Steam/logs/*"
}

remove_trash() {
  rm -rf "$HOME/.local/share/Trash/*"
}

reduce_swap() {
  if [ -f /home/swapfile ]; then
    sudo swapoff /home/swapfile
    sudo rm -r /home/swapfile
  fi
}

fix_config_library_cache() {
  STEAM_USERDATA_PATH="$HOME/.local/share/Steam/userdata"
  if [ -d "$STEAM_USERDATA_PATH" ]; then
    find "$STEAM_USERDATA_PATH" -type d -path "*/config/librarycache/*" -print -exec rm -rf {} +
  fi
}

remove_user_cache() {
  rm -rf "$HOME/.cache/"
}

remove_compatdata() {
  curl -sSL https://raw.githubusercontent.com/scawp/Steam-Deck.Shader-Cache-Killer/main/zShaderCacheKiller.sh | bash
}

open_dolphin_common() {
  dolphin "$HOME/.steam/steam/steamapps/common/"
}

# --- GUI Loop ---

while true; do
  MODE=$(zenity --list --title="Steam Deck Cleanup Menu" --radiolist \
    --text="Choose cleanup mode:" \
    --column="Select" --column="Mode" \
    TRUE "Select Cleanup Only" \
    FALSE "Manual Selection" \
    FALSE "Select All Tasks" \
    FALSE "Exit" \
    --width=400 --height=400)

  if [[ $? -ne 0 || "$MODE" == "Exit" ]]; then
    break
  fi

  SELECTED_TASKS=()

  if [[ "$MODE" == "Select All Tasks" ]]; then
    SELECTED_TASKS=("${!FUNCTIONS[@]}")
  elif [[ "$MODE" == "Select Cleanup Only" ]]; then
    SELECTED_TASKS=(0 1 3 4 5 6 7 9 10 11 12 14)
  else
    # Build checklist with properly quoted values
    CHECKLIST_ITEMS=()
    for task in "${OPTIONS[@]}"; do
      CHECKLIST_ITEMS+=("FALSE" "$task")
    done

    CHOICES=$(zenity --list --checklist \
      --title="Steam Deck Cleanup" \
      --text="Select the cleanup tasks to run:" \
      --column="Run" --column="Task" \
      "${CHECKLIST_ITEMS[@]}" \
      --width=700 --height=700)

    if [[ $? -ne 0 || -z "$CHOICES" ]]; then
      continue
    fi

    IFS="|" read -ra SELECTED_LABELS <<< "$CHOICES"
    for label in "${SELECTED_LABELS[@]}"; do
      for i in "${!OPTIONS[@]}"; do
        if [[ "${OPTIONS[$i]}" == "$label" ]]; then
          SELECTED_TASKS+=("$i")
        fi
      done
    done
  fi

  # Run all selected tasks and show a combined log
  TMP_LOG="/tmp/steamdeck_cleanup.log"
  > "$TMP_LOG"  # Clear previous run

  (
    for index in "${SELECTED_TASKS[@]}"; do
      task_name="${OPTIONS[$index]}"
      task_func="${FUNCTIONS[$index]}"

      echo "==================================="
      echo ">> Running: $task_name"
      echo "==================================="
      $task_func 2>&1
      echo ">> Completed: $task_name"
      echo ""
    done
  ) | tee "$TMP_LOG" | zenity --text-info --title="Steam Deck Cleanup - Combined Log" --width=700 --height=500
done
