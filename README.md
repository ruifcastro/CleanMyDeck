This script cleans up various temporary and cached files on a Steam Deck.
It removes downloading game files, shader caches, unused flakpaks, library cache, logs, and disables/removes the swap file.

Don't forget to make it executable:
chmod +x CleanMyDeck.sh

Run it like this:
sudo ./CleanMyDeck.sh

Here are the sections in the script:

Remove the Steam download cache

Remove unused flatpak apps

Remove all shader caches. This way only the active games you start play are the ones the the Steam Deck will download daily

Remove library cache which gets full of old games you checked out

Remove Steam logs

Disabling and removing swap file. It comes back as the default 1 Gb size

Searching for and deleting librarycache folders in the Userdata folder which helps fix the Activity Bug
