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
  "Disable Decky Loader Plugins"
  "Enable Decky Loader Plugins"
  "Disk Usage"
  "Export Execution Log File"
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
  "disable_decky_plugins"
  "enable_decky_plugins"
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
  HOME_DIR="$HOME"
  SHADERCACHE="$HOME/.steam/steam/steamapps/shadercache"
  COMMON="$HOME/.steam/steam/steamapps/common"
  COMPATDATA="$HOME/.steam/steam/steamapps/compatdata"
  SWAPFILE="/home/swapfile"
  DECKY_LOADER="/home/deck/homebrew"
  DOWNLOADS="/home/deck/Downloads"
  FLATPAK="/home/deck/.var/app"
  EMULATION="/home/deck/Emulation"

  # Helper functions
  get_size() {
    [[ -e "$1" ]] && du -sh "$1" 2>/dev/null | cut -f1 || echo "Not found"
  }

  get_bytes() {
    [[ -e "$1" ]] && du -sb "$1" 2>/dev/null | cut -f1 || echo "0"
  }

  # Get sizes in bytes
  BYTES_HOME=$(get_bytes "$HOME_DIR")
  BYTES_SHADER=$(get_bytes "$SHADERCACHE")
  BYTES_COMMON=$(get_bytes "$COMMON")
  BYTES_COMPAT=$(get_bytes "$COMPATDATA")
  BYTES_SWAP=$(get_bytes "$SWAPFILE")

  BYTES_GAMES=$((BYTES_SHADER + BYTES_COMMON + BYTES_COMPAT))
  BYTES_NONSTEAM=$((BYTES_HOME - BYTES_GAMES + BYTES_SWAP))

  # Human-readable conversions
  SIZE_HOME=$(numfmt --to=iec "$BYTES_HOME")
  SIZE_SHADER=$(numfmt --to=iec "$BYTES_SHADER")
  SIZE_COMMON=$(numfmt --to=iec "$BYTES_COMMON")
  SIZE_COMPAT=$(numfmt --to=iec "$BYTES_COMPAT")
  SIZE_GAMING=$(numfmt --to=iec "$BYTES_GAMES")
  SIZE_NONSTEAM=$(numfmt --to=iec "$BYTES_NONSTEAM")

  # Other folders (already human-readable)
  SIZE_DECKY=$(get_size "$DECKY_LOADER")
  SIZE_DL=$(get_size "$DOWNLOADS")
  SIZE_FLATPAK=$(get_size "$FLATPAK")
  SIZE_EMU=$(get_size "$EMULATION")

  # Display summary
  zenity --info --title="Disk Usage Summary" --width=500 --height=450 --text="
<b>Total Deck Usage:</b>        $SIZE_HOME
<b>Games (Steam Shader/Common/Compat):</b>
        Shadercache: $SIZE_SHADER
        Common:      $SIZE_COMMON
        Compatdata:  $SIZE_COMPAT
        <b>Total Games Usage:</b> $SIZE_GAMING

<b>Non-Steam Usage:</b>         $SIZE_NONSTEAM
<b>Decky Loader:</b>            $SIZE_DECKY
<b>Downloads:</b>               $SIZE_DL
<b>Flatpak Apps:</b>            $SIZE_FLATPAK
<b>Emulation Folder:</b>        $SIZE_EMU
" --no-wrap
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

disable_decky_plugins() {
  PLUGIN_DIR="$HOME/homebrew/plugins"
  BACKUP_DIR="$HOME/homebrew/plugins_backup"

  if [ ! -d "$PLUGIN_DIR" ]; then
    zenity --error --text="Decky plugins folder not found at:\n$PLUGIN_DIR"
    return
  fi

  mkdir -p "$BACKUP_DIR"

  # Copy plugins to backup only if newer or missing
  rsync -a --update "$PLUGIN_DIR"/ "$BACKUP_DIR"/

  # Now clear the plugin directory without deleting the folder
  find "$PLUGIN_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

  zenity --info --text="Plugins disabled. New or updated plugins were backed up to:\n$BACKUP_DIR"
}

enable_decky_plugins() {
  PLUGIN_DIR="$HOME/homebrew/plugins"
  BACKUP_DIR="$HOME/homebrew/plugins_backup"

  if [ ! -d "$BACKUP_DIR" ]; then
    zenity --error --text="No plugin backup found at:\n$BACKUP_DIR"
    return
  fi

  mkdir -p "$PLUGIN_DIR"
  cp -a "$BACKUP_DIR"/. "$PLUGIN_DIR"/
  rm -rf "$BACKUP_DIR"

  zenity --info --text="Plugins restored and backup folder deleted."
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
      --width=700 --height=800)

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

	LOG_OUTPUT=$(
	  for index in "${SELECTED_TASKS[@]}"; do
		task_name="${OPTIONS[$index]}"
		task_func="${FUNCTIONS[$index]}"

		if [[ "$task_func" == "disk_usage" ]]; then
		  $task_func
		  continue
		fi

		echo "==================================="
		echo ">> Running: $task_name"
		echo "==================================="
		$task_func 2>&1
		echo ">> Completed: $task_name"
		echo ""
	  done
	)

	# Write to log only if there is content
	if [[ -n "$LOG_OUTPUT" ]]; then
	  echo "$LOG_OUTPUT" | tee "$TMP_LOG" | zenity --text-info --title="Steam Deck Cleanup - Combined Log" --width=700 --height=500
	fi
done
