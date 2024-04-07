#!/bin/bash

set -x

##### ABOUT #####

# Description: Main player file,
# which starts in Rofi config file
# Using mpv-mpris for play music
# Developer: ivanvit100 @ GitHub

##### DEPENDENSIES #####
# mpv       ^ v0.37.0
# mpv-mpris ^ 
# jq        ^ jq-1.7.1
# yt-dlp    ^ 2024.03.10
# Rofi      ^ 

##### FLAGS #####
# --offset={{num}}      - additional offset for numbers in menu
# --json_file={{way}}   - custom way to YT playlists JSON

#####       #####


##### VARIABLES #####

SCRIPT_NAME="Rofi Player"
OFFSET=${1#*=}
JSON_FILE=${2#*=}
YT_LISTS=()
FORMATTED_PLAYLISTS=""
PLAYLISTS=""

##### SETTING DEFAULT VALUES #####

if [ -z "$OFFSET" ]; then
    OFFSET="20"
fi
if [ -z "$JSON_FILE" ]; then
    JSON_FILE="$HOME/Music/youtube_playlists.json"
fi
if [ ! -f "$JSON_FILE" ] || [ ! -s "$JSON_FILE" ]; then
    echo "[  ]" > "$JSON_FILE"
fi

##### PLAYLITS FORMING #####

FORMING(){

    ##### LOCAL READING PART #####
    
    PLAYLISTS=$(find ~/Music -maxdepth 1 -type d -exec bash -c 'echo -e "$(basename "{}")\t$(find "{}" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \) | wc -l)"' \;)
    MAX_LENGTH=$(echo -e "$PLAYLISTS" | cut -f1 | awk '{ if (length > max) max = length + '$OFFSET'} END { print max }')

    ##### YT READING PART #####

    while IFS= read -r line; do
        YT_LISTS+=("$line")
    done < <(jq -c '.[]' "$JSON_FILE" | while read i; do jq -r '"\(.name)\t\(.url)"' <<< "$i"; done)

    for playlist in "${YT_LISTS[@]}"; do
        name=$(echo -e "$playlist" | cut -f1)
        PLAYLISTS+=$'\n'"$name" 
    done
}

FORMATING(){
    while IFS=$'\t' read -r name count; do
        if [ -z "$count" ] && [ "$name" != "From YouTube" ] && [ "$name" != "Exit" ] && [ "$name" != "Save YouTube" ] && [ "$name" != "Delete list" ]; then
            count="YT"
        fi
        SPACES=$((MAX_LENGTH - ${#name} + 5))
        FORMATTED_PLAYLISTS+="$name$(printf '%*s' $SPACES)$count\n"
    done <<< "$PLAYLISTS"
}

FORMING
PLAYLISTS+=$'\n'"From YouTube"
PLAYLISTS+=$'\n'"Save YouTube"
PLAYLISTS+=$'\n'"Delete list"
PLAYLISTS+=$'\n'"Exit"
FORMATING

##### USER MENU LOGIC #####

SELECTED_PLAYLIST=$(echo -e "$FORMATTED_PLAYLISTS" | head -n -1 | rofi -dmenu -i -p "Select a playlist" | awk '{$NF=""; print substr($0, 1, length($0)-1)}')

if [ -z "$SELECTED_PLAYLIST" ]; then
    pkill -f "$SCRIPT_NAME"
    exit 0
fi

##### YOUTUBE PLAYLIST ADDITION #####

YT(){
    PLAYLIST_NAME=$(yt-dlp --flat-playlist -e -j "$1" | sed -z 's/{.*//')
    URL=$(jq -r --arg name "$1" '.[] | select(.name == $name) | .url' "$JSON_FILE")
    if [ $? -eq 0 ] && [ "$PLAYLIST_NAME" != "Error" ]; then
        if [ "$URL" == "" ]; then
            head -c -1 "$JSON_FILE" > temp.json
            echo ",{\"url\": \"$1\", \"name\": \"$PLAYLIST_NAME\"}]" >> temp.json
            mv temp.json "$JSON_FILE"
        fi
        mpv --no-video --ytdl-format=bestaudio "$1" --title="$SCRIPT_NAME"
    else
        return 1
    fi
}

if [ "$SELECTED_PLAYLIST" == "From" ]; then
    YOUTUBE_PLAYLIST_URL=$(rofi -dmenu -p "Enter YouTube playlist URL")
    YT $YOUTUBE_PLAYLIST_URL
fi

##### YOUTUBE PLAYLIST DOWNLOAD #####

YT_SAVE(){
    PLAYLIST_NAME=$(yt-dlp --flat-playlist -e -j "$1" | sed -z 's/{.*//')
    dir=$HOME/Music/$(echo $PLAYLIST_NAME | cut -d' ' -f1)
    mkdir -p $dir
    cd $dir
    yt-dlp -x --audio-format mp3 $1
    SELECTED_PLAYLIST="Save"
}

if [ "$SELECTED_PLAYLIST" == "Save" ]; then
    YOUTUBE_PLAYLIST_URL=$(rofi -dmenu -p "Enter YouTube playlist URL")
    YT_SAVE $YOUTUBE_PLAYLIST_URL
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
    echo "$TRACKS" | shuf > "$PLAYLIST"
    mpv --no-video --playlist="$PLAYLIST" --title="$SCRIPT_NAME"
    rm "$PLAYLIST"
}

##### FIND IN JSON #####

get_url_by_name() {
    if [[ "$1" =~ ^https://www\.youtube\.com/.*$ ]]; then
        echo $URL
    fi
}

##### DELETE PLAYLIST #####

DELETE() {
    if [ -z "$1" ]; then
        exit 0
    fi
    dir=~/Music/$1
    if [ -d "$dir" ]; then
        rm -rf "$dir"
    else
        jq -c "map(select(.name != \"$1\"))" $JSON_FILE > temp.json && mv temp.json $JSON_FILE
    fi
}

if [ "$SELECTED_PLAYLIST" == "Delete" ]; then
    FORMING
    FORMATTED_PLAYLISTS=""
    PLAYLISTS+=$'\n'"Exit"
    FORMATING
    SELECTED_PLAYLIST=$(echo -e "$FORMATTED_PLAYLISTS" | head -n -1 | rofi -dmenu -i -p "Select a playlist" | awk '{$NF=""; print substr($0, 1, length($0)-1)}')
    DELETE $SELECTED_PLAYLIST
fi

##### USAGE #####

url=$(get_url_by_name $SELECTED_PLAYLIST)
if [ -z "$url" ]; then
    playlist
else
    YT "$url"
fi