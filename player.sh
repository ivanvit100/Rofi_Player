#!/bin/bash

# Description: Main player file,
# which starts in Rofi config file
# Using mpv-mpris for play music
# Developer: ivanvit100 @ GitHub

# Flags:
# --offset={{num}} - additional offset for numbers in menu

SCRIPT_NAME="Rofi Player"
OFFSET=${1#*=}

# If offset is not provided, set it to default value
if [ -z "$OFFSET" ]; then
    OFFSET="20"
fi

##### LOCAL READING PART #####

# Menu Composition
# INPUT:  Music directory
# OUTPUT: Playlists (folders in the ~/Music directory)
#         Function keys (like "Exit")
PLAYLISTS=$(find ~/Music -maxdepth 1 -type d -exec bash -c 'echo -e "$(basename "{}")\t$(find "{}" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \) | wc -l)"' \;)
MAX_LENGTH=$(echo -e "$PLAYLISTS" | cut -f1 | awk '{ if (length > max) max = length + '$OFFSET'} END { print max }')
PLAYLISTS+=$'\n'"Exit"
FORMATTED_PLAYLISTS=""
while IFS=$'\t' read -r name count; do
    SPACES=$((MAX_LENGTH - ${#name} + 5))
    FORMATTED_PLAYLISTS+="$name$(printf '%*s' $SPACES)$count\n"
done <<< "$PLAYLISTS"

##### USER INPUT LOGIC #####

# Display the playlist in Rofi and retrieve the selected playlist
SELECTED_PLAYLIST=$(echo -e "$FORMATTED_PLAYLISTS" | head -n -1 | rofi -dmenu -i -p "Select a playlist" | awk '{$NF=""; print substr($0, 1, length($0)-1)}')

# If "Exit" is selected, terminate the job
if [ "$SELECTED_PLAYLIST" == "Exit" ]; then
    killall mpv
    exit 0
fi

# If no playlist is selected, exit
if [ -z "$SELECTED_PLAYLIST" ]; then
    exit 0
fi

##### PLAYLIST PLAYBACK #####

# Kill previously opened playlists 
killall mpv

# Get the list of tracks in the playlist
# INPUT:  Music directory
# OUTPUT: List of tracks
if [ "$SELECTED_PLAYLIST" == "Music" ]; then
    TRACKS=$(find ~/Music -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \))
else
    TRACKS=$(find ~/Music/"$SELECTED_PLAYLIST" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \))
fi
# Create a temporary playlist file
PLAYLIST=$(mktemp)

# Record tracks into a playlist in random order
echo "$TRACKS" | shuf > "$PLAYLIST"

# Play the playlist without the application window
mpv --no-video --playlist="$PLAYLIST"

# Delete the temporary playlist file
rm "$PLAYLIST"