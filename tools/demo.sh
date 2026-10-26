#!/bin/bash
# Records and renders the README demo, docs/demo.gif.
#   tools/demo.sh record   records the area around the PushToTalk menu bar icon and the hotkey presses, type any key here to stop
#   tools/demo.sh render   adds the keycap and the subtitles and writes docs/demo.gif, with "ru" Russian ones to docs/demo-ru.gif
# Needs ffmpeg and gifski (brew install ffmpeg gifski). Terminal needs Screen Recording, Input Monitoring and Accessibility.
# W and H set the recorded area size in points around the icon, REGION=x,y,w,h sets the whole area.
# OFFSET=seconds overrides the sync of the key presses with the video.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build docs

# Points of the recording kept from the top: just below the open menu. Subtitles may cover its last item.
HEIGHT=345
# Covers a glitch: the x,y,w,h area in points is copied from the first second and shown from the second to the third.
# Here fn switches the input source to "РУ" for a moment during the second double tap. Empty means no patch.
PATCH="120,0,35,30 6.5 6.9 7.2"
# Start and end second in the recording, then the English and the Russian text. The GIF keeps only these spans.
SUBTITLES=(
    "0.3 1.5 Lives in the menu bar, mic muted|Живет в строке меню, микрофон выключен"
    "2.3 3.8 Lives in the menu bar, mic muted|Живет в строке меню, микрофон выключен"
    "3.8 5.7 Hold the hotkey to talk (fn here)|Удерживайте клавишу, чтобы говорить (здесь fn)"
    "5.7 8.5 Double-tap to keep it on, again to mute|Двойное нажатие закрепляет, повторное снимает"
    "8.5 12.3 Input volume and its lock|Громкость входа и ее фиксация"
    "15.5 20.4 Pop and Tink sound levels|Громкость звуков Pop и Tink"
    "20.4 22.0 Disable leaves the mic alone|Disable: микрофон больше не управляется"
    "22.0 23.5 Enable mutes it again|Enable снова выключает микрофон"
)

record() {
    [ -x build/taptimer ] || swiftc -O -o build/taptimer tools/taptimer.swift
    local region=${REGION:-} icon=""
    if [ -z "$region" ]; then
        local found
        found=$(osascript -e 'tell application "System Events" to tell process "PushToTalk"
            set {{x, y}, {w, h}} to {position, size} of menu bar item 1 of last menu bar
            return (x as integer as text) & " " & (w as integer as text) & " " & (h as integer as text)
        end tell') || { echo "Give Terminal the Accessibility permission or set REGION=x,y,w,h" >&2; exit 1; }
        local ix iw ih sw w=${W:-460} h=${H:-500}
        read -r ix iw ih <<< "$found"
        sw=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); Math.round($.NSScreen.mainScreen.frame.size.width)')
        local x=$(( ix - 40 ))
        if (( x + w > sw )); then x=$(( sw - w )); fi
        if (( x < 0 )); then x=0; fi
        region="$x,0,$w,$h"
        icon="$(( ix - x )) $iw $ih"
    fi
    echo "$region $icon" > build/demo-region
    rm -f build/demo.mov
    build/taptimer > build/demo-keys.txt &
    taptimer=$!
    trap 'kill -INT "$taptimer" 2>/dev/null' EXIT
    echo "Recording $region. Go through the scenario."
    screencapture -v -C -x -R "$region" build/demo.mov
    chmod a+r build/demo.mov # screencapture writes it as 600, and render may run from another account
}

render() {
    local lang=$1 gif=docs/demo${1:+-$1}.gif
    local dir=build/demo-images line from to text texts=() code glyph label
    rm -rf "$dir" build/demo-frames && mkdir -p "$dir" build/demo-frames
    swiftc -O -o build/demo-overlays tools/demo-overlays.swift
    for line in "${SUBTITLES[@]}"; do
        read -r _ _ text <<< "$line"
        if [ "$lang" = ru ]; then texts+=("${text#*|}"); else texts+=("${text%%|*}"); fi
    done
    code=$(awk '/^Watching key code/ { print $4 + 0; exit }' build/demo-keys.txt)
    case "$code" in
        61) glyph="⌥" label="right option" ;;
        58) glyph="⌥" label="left option" ;;
        63) glyph="fn" label="" ;;
        *) glyph="key $code" label="" ;;
    esac
    build/demo-overlays "$dir" "$glyph" "$label" "${texts[@]}"

    local w icx icw ich scale
    IFS=', ' read -r _ _ w _ icx icw ich < build/demo-region
    scale=$(( $(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 build/demo.mov) / w ))

    # Video time of a key press = taptimer time + offset. The icon changes on the first press, so the first icon change
    # from a second before that press gives the offset (the cursor can change the icon area earlier).
    local offset=${OFFSET:-} key change
    if [ -z "$offset" ]; then
        [ -n "${icx:-}" ] || { echo "Set OFFSET: the icon position is unknown for a manual REGION" >&2; exit 1; }
        key=$(awk '$2 == "s" && $3 == "DOWN" { print $1; exit }' build/demo-keys.txt)
        change=$(ffmpeg -nostats -i build/demo.mov -vf "crop=$((icw * scale)):$((ich * scale)):$((icx * scale)):0,select='gt(scene,0.02)',showinfo" -f null - 2>&1 \
            | awk -F 'pts_time:' -v k="$key" 'NF > 1 && t == "" { split($2, a, " "); if (a[1] >= k - 1) t = a[1] } END { print t }')
        [ -n "$key" ] && [ -n "$change" ] || { echo "No key press or icon change found, set OFFSET" >&2; exit 1; }
        offset=$(awk -v a="$change" -v b="$key" 'BEGIN { print a - b }')
    fi
    local pressed
    pressed=$(awk -v o="$offset" '$2 == "s" && $3 == "DOWN" { d = $1 + o }
        $2 == "s" && $3 == "UP" && d != "" { printf "+between(t,%.3f,%.3f)", d, $1 + o; d = "" }' build/demo-keys.txt)
    echo "offset $offset s"

    # shortcut: overlays are drawn at 2x, so on a non-Retina recording they come out twice as large; scale them if that ever matters.
    # screencapture writes a frame only when the screen changes, so go to a constant 20 fps before the overlays are timed.
    local inputs=(-i build/demo.mov -i "$dir/key.png") graph="[0]fps=20,crop=iw:$((HEIGHT * scale)):0:0" i=0 spans=""
    if [ -n "$PATCH" ]; then
        local area clean pfrom pto px py pw ph
        read -r area clean pfrom pto <<< "$PATCH"
        IFS=, read -r px py pw ph <<< "$area"
        ffmpeg -v error -ss "$clean" -i build/demo.mov -vf "crop=$((pw * scale)):$((ph * scale)):$((px * scale)):$((py * scale))" -frames:v 1 "$dir/patch.png"
        inputs+=(-i "$dir/patch.png")
        graph+="[c];[c][2]overlay=$((px * scale)):$((py * scale)):enable='between(t,$pfrom,$pto)'"
    fi
    # The keycap shows only while the key is down, at the right edge in the middle.
    graph+="[s];[s][1]overlay=W-w-$((16 * scale)):(H-h)/2:enable='0${pressed}'[v0]"
    for line in "${SUBTITLES[@]}"; do
        read -r from to _ <<< "$line"
        i=$(( i + 1 ))
        inputs+=(-i "$dir/sub-$i.png")
        graph+=";[v$(( i - 1 ))][$(( ${#inputs[@]} / 2 - 1 ))]overlay=(W-w)/2:H-h-$((12 * scale)):enable='gte(t,$from)*lt(t,$to)'[v$i]"
        spans+="+gte(t,$from)*lt(t,$to)"
    done
    graph+=";[v$i]select='0${spans}',setpts=N/20/TB,scale=640:-1:flags=lanczos"
    ffmpeg -v error "${inputs[@]}" -filter_complex "$graph" build/demo-frames/%04d.png
    gifski --fps 20 --quality 90 -o "$gif" build/demo-frames/*.png
    ls -lh "$gif"
}

case "${1:-}" in
    record) record ;;
    render) render "${2:-}" ;;
    *) sed -n '2,6p' "$0" >&2; exit 1 ;;
esac
