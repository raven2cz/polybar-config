#!/bin/bash

# The name of polybar bar which houses the main spotify module and the control modules.
PARENT_BAR="${1:-music}"
PARENT_BAR_PID=$(pgrep -a "polybar" | grep "$PARENT_BAR" | cut -d" " -f1)

urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

send_hook() {
    [ -z "$1" ] && echo "send_hook: missing arg" && exit 1
    polybar-msg hook mpris-play-pause "$1" 1>/dev/null 2>&1
}


extract_meta() {
    grep "$1\W" <<< "$meta" | awk '{$1=$2=""; print $0}' | sed 's/^ *//; s/; */;/g' | paste -s -d/ -
}

# if "icon" given, determine icon. otherwise, print metadata
get_info() {
    if [ -z "$1" ]; then
        echo "Usage: get_info PLAYER [icon]"
        exit 1
    fi

    meta=$(playerctl -p "$1" metadata)

    # get title
    title=$(extract_meta title)
    # if no title, try url e.g. vlc
    if [ -z "$title" ]; then
        title=$(extract_meta url)
        title=$(urldecode "${title##*/}")
    fi

    # if not "icon", display information and return
    if [ "$2" != "icon" ]; then
        artist=$(extract_meta artist)
        [ -z "$artist" ] && artist=$(extract_meta albumArtist)

        if [ -n "$artist" ]; then
            album=$(extract_meta album)
            [ -n "$album" ] && echo -n "  $album "

            echo -n " ﴁ $artist  "
        fi

        echo "$title"
        return 0
    fi

    # determine icon:
    # if player name is recognised, use it
    case "$1" in
        spotify* | vlc | mpv) echo "$1";;
        kdeconnect*) echo "kdeconnect";;
        chromium*)
            # if a browser, search window titles:

            # this tries to avoid title messing up the regex
            regex_title=$(echo "$title" | tr "[:punct:]" ".")
            windowname=$(xdotool search --name --class --classname "$regex_title" getwindowname 2>/dev/null)
            case $windowname in
                "") ;; # ignore if empty
                *Netflix*) echo "netflix";;
                *YouTube*) echo "youtube";;
                *"Prime Video"*) echo "prime";;
                *"Corridor Digital"*) echo "corridor";;
                *) echo "browser";;
            esac;;
        *) echo "none";;
    esac
}

# manually go through players
read -d'\n' -ra PLAYERS <<<"$(playerctl -l 2>/dev/null)"
declare -a PAUSED
for player in "${PLAYERS[@]}"; do
    [ "$player" = "playerctld" ] && continue;

    p_status=$(playerctl -p "$player" status 2>/dev/null)

    # if we have one playing, we'll use it and EXIT
    if [ "$p_status" = "Playing"  ]; then
        send_hook 1
        get_info "$player" "$2"
        exit 0;
    fi

    [ "$p_status" = "Paused" ] && PAUSED+=("$player")
done

# if we have a paused, show it otherwise assume there are no players or have all stopped
if [ -n "${PAUSED[0]}" ]; then
    send_hook 2
    get_info "${PAUSED[0]}" "$2"
else
    [ "$2" = icon ] && echo "none" || echo " 鈴 no players "
fi
