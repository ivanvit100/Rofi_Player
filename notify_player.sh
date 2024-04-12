#!/bin/bash
filename=$(basename -s .mp3 "$1")
notify-send --app-name="Rofi_Player" --expire-time=1500 --icon=$HOME/Music/logo.png "Downloaded: $filename"