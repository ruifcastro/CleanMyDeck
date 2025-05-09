This script cleans up various temporary and cached files on a Steam Deck.
It removes downloading game files, shader caches, unused flakpaks, library cache, logs, and disables/removes the swap file.

Don't forget to make it executable:

chmod +x CleanMyDeck.sh

chmod +x Update_CleanMyDeck.sh

Run it like this:

sudo ./CleanMyDeck.sh

And to update it:

./Update_CleanMyDeck.sh


Here are the sections in the script:
- Remove Steam Download Cache
- Remove Flatpak Unused Apps
- Repair Flatpak
- Remove Steam Shader Caches. This way only the active games you start play are the ones the the Steam Deck will download daily
- Remove Steam Old Banner Library Cache
- Remove Steam Logs
- Remove Trash
- Reduce Swapfile Size. Specialy if you used CyroUilities in the past. The default size now is 1 Gb because we now use ZRAM.
- Fix the Steam Activity Tab Bug where it gets stuck and you don't see any updates
- Remove User Cache
- Manual Removal of Uninstalled Game Compatdata (using zShaderCacheKiller.sh)
- Manual Removal of Common Game Folders (using Dolphin)
- Disk Usage (NonSteam Storage)
- Disable Decky Loader Plugins
- Enable Decky Loader Plugins
- Export Execution Log File

Added the possibility to disable and enable Decky Loader plugins. I think this is useful to help with detect why you are losing FPSs or having strange spikes.
