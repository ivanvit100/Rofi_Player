#!/bin/bash

# Description: Main player file,
# which starts in Rofi config file
# Using mpv-mpris for play music
# Developer: ivanvit100 @ GitHub

# Flags:
# --offset={{num}} - additional offset for numbers in menu

SCRIPT_NAME="Rofi Player"
OFFSET=${1#*=}
JSON_FILE=${2#*=}
YT_LISTS=()

# If offset is not provided, set it to default value
if [ -z "$OFFSET" ]; then
    OFFSET="20"
fi
if [ -z "$JSON_FILE" ]; then
    JSON_FILE="$HOME/Music/youtube_playlists.json"
fi
if [ ! -f "$JSON_FILE" ] || [ ! -s "$JSON_FILE" ]; then
    echo "[  ]" > "$JSON_FILE"
fi

##### LOCAL READING PART #####

PLAYLISTS=$(find ~/Music -maxdepth 1 -type d -exec bash -c 'echo -e "$(basename "{}")\t$(find "{}" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \) | wc -l)"' \;)
MAX_LENGTH=$(echo -e "$PLAYLISTS" | cut -f1 | awk '{ if (length > max) max = length + '$OFFSET'} END { print max }')

##### YT READING PART #####

mapfile -t YT_LISTS < <(jq -r '"\(.name)\t\(.url)"' "$JSON_FILE")
for playlist in "${YT_LISTS[@]}"; do
    name=$(echo -e "$playlist" | cut -f1)
    PLAYLISTS+=$'\n'"$name" 
done

PLAYLISTS+=$'\n'"From YouTube"
PLAYLISTS+=$'\n'"Exit"
FORMATTED_PLAYLISTS=""
while IFS=$'\t' read -r name count; do
    SPACES=$((MAX_LENGTH - ${#name} + 5))
    FORMATTED_PLAYLISTS+="$name$(printf '%*s' $SPACES)$count\n"
done <<< "$PLAYLISTS"

##### USER INPUT LOGIC #####

# Display the playlist in Rofi and retrieve the selected playlist
SELECTED_PLAYLIST=$(echo -e "$FORMATTED_PLAYLISTS" | head -n -1 | rofi -dmenu -i -p "Select a playlist" | awk '{$NF=""; print substr($0, 1, length($0)-1)}')

# If no playlist is selected, exit
if [ -z "$SELECTED_PLAYLIST" ]; then
    pkill -f "$SCRIPT_NAME"
    exit 0
fi

##### YT playback #####

YT(){
    PLAYLIST_NAME=$(yt-dlp --flat-playlist -e -j "$1" | head -1)
    echo "$PLAYLIST_NAME"
    if [ $? -eq 0 ] && [ "$PLAYLIST_NAME" != "Error" ]; then
        if ! jq --arg url "$1" 'any(.[]; .url == $url)' "$JSON_FILE"; then
            jq --arg url "$1" --arg name "$PLAYLIST_NAME" 'if type=="array" then . += [{"url": $url, "name": $name}] else [{"url": $url, "name": $name}] end' "$JSON_FILE" > temp.json && mv temp.json "$JSON_FILE"
        fi
        mpv --no-video --ytdl-format=bestaudio "$1" --title="$SCRIPT_NAME"
    else
        return 1
    fi
}

##### YOUTUBE PLAYLIST ADDITION #####

if [ "$SELECTED_PLAYLIST" == "From" ]; then
    YOUTUBE_PLAYLIST_URL=$(rofi -dmenu -p "Enter YouTube playlist URL")
    if [ -z $YOUTUBE_PLAYLIST_URL ]; then
        exit 0
    fi
    YT $YOUTUBE_PLAYLIST_URL
fi

##### PLAYLIST PLAYBACK #####

playlist(){ 
    pkill -f "$SCRIPT_NAME"
    if [ "$SELECTED_PLAYLIST" == "Music" ]; then
        TRACKS=$(find ~/Music -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \))
    else
        TRACKS=$(find ~/Music/"$SELECTED_PLAYLIST" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \))
    fi
    PLAYLIST=$(mktemp)

    # Record tracks into a playlist in random order
    echo "$TRACKS" | shuf > "$PLAYLIST"

    # Play the playlist without the application window
    mpv --no-video --playlist="$PLAYLIST" --title="$SCRIPT_NAME"

    # Delete the temporary playlist file
    rm "$PLAYLIST"
}

get_url_by_name() {
    echo $(jq -r --arg name "$1" '.[] | select(.name == $name) | .url' "$JSON_FILE")
}

# Usage
url=$(get_url_by_name $SELECTED_PLAYLIST)
if [ -z "$url" ]; then
    playlist
else
    YT "$url"
fi