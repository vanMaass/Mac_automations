#!/bin/bash
#
# screenshots-aufraeumen.sh
# ------------------------------------------------------------
# Verschiebt Screenshots vom Schreibtisch in einen Monatsordner
# und benennt sie dabei sauber um.
#
# Aus:  ~/Desktop/Bildschirmfoto 2026-03-14 um 15.22.13.png
# Wird: ~/Pictures/Screenshots/2026-03/Screenshot_2026-03-14_152213.png
#
# Es wird NICHTS geloescht - nur verschoben.
#
# Testlauf (zeigt nur an, was passieren wuerde):
#   ./screenshots-aufraeumen.sh --test
# Echter Lauf:
#   ./screenshots-aufraeumen.sh
# ------------------------------------------------------------

set -u

# --- Einstellungen -------------------------------------------
SRC="$HOME/Desktop"
DEST_BASIS="/Volumes/WD_BLACK/Privat/Bilder/Bildschirmfotos"
# -------------------------------------------------------------

TESTLAUF=0
if [ "${1:-}" = "--test" ]; then
    TESTLAUF=1
    echo "== TESTLAUF - es wird nichts verschoben =="
fi

# Datum einer Datei auslesen.
# macOS nutzt BSD-stat, Linux GNU-stat - die Syntax ist unterschiedlich.
if [ "$(uname)" = "Darwin" ]; then
    file_date() { stat -f "%Sm" -t "$2" "$1"; }
else
    file_date() { date -r "$1" +"$2"; }
fi

if [ ! -d "$SRC" ]; then
    echo "Quellordner nicht gefunden: $SRC"
    exit 1
fi

num=0

# Nullbyte-getrennt, damit Leerzeichen in Dateinamen kein Problem sind
while IFS= read -r -d '' file; do
    name=$(basename "$file")

    # Nur echte Screenshots (deutsche und englische Systemsprache)
    case "$name" in
        Bildschirmfoto*|Screenshot*|"Bildschirm "*) ;;
        *) continue ;;
    esac

    ending="${name##*.}"
    month=$(file_date "$file" "%Y-%m")
    timestamp=$(file_date "$file" "%Y-%m-%d_%H%M%S")

    if [ -z "$month" ] || [ -z "$timestamp" ]; then
        echo "Datum nicht lesbar, uebersprungen: $name"
        continue
    fi

    destination="$DEST_BASIS/$month"
    target="$destination/Bildschirmfoto_${timestamp}.${ending}"

    # Falls in derselben Sekunde mehrere Screenshots entstanden sind
    counter=2
    while [ -e "$target" ]; do
        target="$destination/Bildschirmfoto_${timestamp}_${counter}.${ending}"
        counter=$((counter + 1))
    done

    if [ "$TESTLAUF" -eq 1 ]; then
        echo "wuerde verschieben: $name  ->  ${target#$HOME/}"
    else
        mkdir -p "$destination"
        mv -n "$file" "$target"
        echo "verschoben: $name  ->  ${target#$HOME/}"
    fi

    num=$((num + 1))
done < <(find "$SRC" -maxdepth 1 -type f \
            \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.heic" \) \
            -print0)

echo "---"
if [ "$num" -eq 0 ]; then
    echo "Keine Screenshots auf dem Schreibtisch gefunden."
elif [ "$TESTLAUF" -eq 1 ]; then
    echo "$num Screenshot(s) wuerden verschoben."
else
    echo "$num Screenshot(s) verschoben."
fi
