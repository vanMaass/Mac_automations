#!/bin/bash
#
# downloads-sortieren.sh
# ------------------------------------------------------------
# Raeumt den Downloads-Ordner auf:
#   1. Dateien werden nach Typ in Unterordner einsortiert
#   2. Installer (.dmg / .pkg), die aelter als X Tage sind,
#      in den Papierkorb.
#
# Es wird nichts endgueltig geloescht. Alles laesst sich
# aus dem Papierkorb zurueckholen.
#
# Testlauf:
#   ./downloads-sortieren.sh --test
# Echter Lauf:
#   ./downloads-sortieren.sh
# ------------------------------------------------------------

set -u

# --- Einstellungen -------------------------------------------
SRC="$HOME/Downloads"
TRASH="$HOME/.Trash"
INSTALLER_DAYS=7          # Ab wann Installer in den Papierkorb wandern
# -------------------------------------------------------------

TESTLAUF=0
if [ "${1:-}" = "--test" ]; then
    TESTLAUF=1
    echo "== TESTLAUF - es wird nichts bewegt =="
fi

if [ ! -d "$SRC" ]; then
    echo "Downloads-Ordner nicht gefunden: $SRC"
    exit 1
fi

mkdir -p "$TRASH"

# Zielordner anhand der Dateiendung bestimmen
dest_folder_for() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        pdf|doc|docx|txt|md|pages|epub)      echo "Dokumente" ;;
        jpg|jpeg|png|gif|heic|webp|svg)      echo "Bilder" ;;
        mp4|mov|avi|mkv)                     echo "Videos" ;;
        mp3|wav|m4a|flac|aiff)               echo "Audio" ;;
        zip|rar|7z|tar|gz)                   echo "Archive" ;;
        csv|xlsx|xls|json|sql)               echo "Daten" ;;
        py|js|sh|ipynb)                      echo "Code" ;;
        *)                                   echo "" ;;
    esac
}

push_counter=0
trash_counter=0
left_counter=0

while IFS= read -r -d '' file; do
    name=$(basename "$file")

    # Versteckte Dateien und unfertige Downloads in Ruhe lassen
    case "$name" in
        .*|*.download|*.crdownload|*.part) continue ;;
    esac

    ending="${name##*.}"
    [ "$ending" = "$name" ] && ending=""   # Datei ganz ohne Endung

    kleinendung=$(printf '%s' "$ending" | tr '[:upper:]' '[:lower:]')

    # Alte Installer aussortieren
    if [ "$kleinendung" = "dmg" ] || [ "$kleinendung" = "pkg" ]; then
        if [ -n "$(find "$file" -mtime +$INSTALLER_DAYS 2>/dev/null)" ]; then
            if [ "$TESTLAUF" -eq 1 ]; then
                echo "Papierkorb (aelter als $INSTALLER_DAYS Tage): $name"
            else
                dest="$TRASH/$name"
                zaehler=2
                while [ -e "$dest" ]; do
                    dest="$TRASH/${name%.*}_$zaehler.${name##*.}"
                    zaehler=$((zaehler + 1))
                done
                mv -n "$file" "$dest"
                echo "Papierkorb: $name"
            fi
            trash_counter=$((trash_counter + 1))
            continue
        fi
    fi

    ordner=$(dest_folder_for "$ending")

    if [ -z "$ordner" ]; then
        left_counter=$((left_counter + 1))
        continue
    fi

    dest="$SRC/$ordner/$name"
    zaehler=2
    while [ -e "$dest" ]; do
        if [ "$name" = "${name%.*}" ]; then
            dest="$SRC/$ordner/${name}_$zaehler"
        else
            dest="$SRC/$ordner/${name%.*}_$zaehler.${name##*.}"
        fi
        zaehler=$((zaehler + 1))
    done

    if [ "$TESTLAUF" -eq 1 ]; then
        echo "wuerde verschieben: $name  ->  $ordner/"
    else
        mkdir -p "$SRC/$ordner"
        mv -n "$file" "$dest"
        echo "verschoben: $name  ->  $ordner/"
    fi
    push_counter=$((push_counter + 1))

done < <(find "$SRC" -maxdepth 1 -type f -print0)

echo "---"
echo "Einsortiert:      $push_counter"
echo "In den Papierkorb: $trash_counter"
echo "Liegengelassen:   $left_counter (unbekannter Dateityp)"
