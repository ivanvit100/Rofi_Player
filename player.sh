#!/bin/bash

# Получаем список плейлистов (папок) в директории ~/Music
PLAYLISTS=$(find ~/Music -maxdepth 1 -type d -printf '%f\n')

# Отображаем список плейлистов в Rofi и получаем выбранный плейлист
SELECTED_PLAYLIST=$(echo "$PLAYLISTS" | rofi -dmenu -i -p "Select a playlist")

# Если плейлист не выбран, выходим
if [ -z "$SELECTED_PLAYLIST" ]; then
    exit 0
fi

# Получаем список треков в плейлисте
TRACKS=$(find ~/Music/$SELECTED_PLAYLIST -maxdepth 1 -type f)

# Воспроизводим треки в случайном порядке
echo "$TRACKS" | shuf | while read -r TRACK; do
    if [ -f "$TRACK" ]; then
        mpv "$TRACK"
    else
        echo "File $TRACK does not exist, skipping..."
    fi
done