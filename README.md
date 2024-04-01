![preview](preview.png)
# Rofi Player

Rofi Player is a bash script that uses Rofi, a substitute for windows switch, application launcher and dmenu, to create a simple and interactive music player. 
It uses mpv to play music and mpv-mpris to support `MPRIS`.

## Features
1. Displays all folders (playlists) in the `~/Music` directory.
2. Shows the number of tracks in each playlist.
3. Allows you to select a playlist to play.
4. Plays the selected playlist in random order.
5. Allows you to stop playback and exit the player.

## Dependensies
1. `Rofi`
2. `MPV`
3. `mpv-mpris` plugin

## Flags
1. `--offset` It allows you to set the indentation size to the number of songs in the directory

## Using
1. Make sure you have `rofi`, `mpv` and `mpv-mpris` installed.
2. Copy the script to a convenient location.
3. Give the script execute permissions
```sh
chmod +x
```
4. Run the script from the terminal or bind it to a hotkey (for example, in `~/.config/hyprland/keybindings.conf`.
```sh
bind = $mainMod, Y, exec, pkill -x rofi || $scrPath/player.sh --offset=25 # open player
```
5. In the Rofi window that opens, select a playlist to play or select "Exit" to exit.
