Neues video · SH
#!/bin/bash
#
# neues-video.sh
# ------------------------------------------------------------
# Legt die Ordnerstruktur fuer ein neues Video an.
#
# Aufruf (mit oder ohne Anfuehrungszeichen):
#   ./neues-video.sh Mein Mac raeumt sich selbst auf
#   ./neues-video.sh "Mein Mac raeumt sich selbst auf"
#
# Ergebnis:
#   video 7 (mein mac raeumt sich selbst auf)/
#       01_ARoll/  02_BRoll/  03_Audio/  04_Thumbnail/  05_Export/
# ------------------------------------------------------------
 
set -u
 
# --- Einstellungen -------------------------------------------
#BASIS="$HOME/Videos"
BASIS="/Volumes/WD_BLACK/Privat/Youtube"
FOLDER="01_ARoll 02_BRoll 03_Audio 04_Thumbnail 05_Export"
# -------------------------------------------------------------
 
if [ $# -lt 1 ]; then
    echo "Bitte einen Videotitel angeben."
    echo "Beispiel: ./neues-video.sh Mein Mac raeumt sich selbst auf"
    exit 1
fi
 
# "$*" nimmt ALLE Argumente, also den kompletten Titel mit Leerzeichen.
# Mit "$1" waere nur das erste Wort angekommen.
TITEL="$*"
 
# Titel in einen sauberen Ordnernamen umwandeln:
# Kleinbuchstaben, Umlaute ersetzt, Sonderzeichen zu Bindestrichen.
SLUG=$(printf '%s' "$TITEL" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/ß/ss/g' \
    | sed -e 's/[^a-z0-9 ]\{1,\}/-/g' -e 's/^[ -]*//' -e 's/[ -]*$//')
 
if [ -z "$SLUG" ]; then
    echo "Aus dem Titel laesst sich kein Ordnername bilden."
    exit 1
fi
 
if [ ! -d "$BASIS" ]; then
    echo "Basis-Ordner nicht gefunden: $BASIS"
    echo "Steckt die Festplatte?"
    exit 1
fi
 
# Hoechste bisherige Nummer suchen.
# Wichtig: nur die Zahl direkt hinter "video " zaehlt. Sonst wuerde
# eine Zahl im Titel - z.B. "video 2 (top 5 mac apps)" - mitgezaehlt.
NUMBER=$(ls -d "$BASIS"/video\ * 2>/dev/null \
    | sed -e 's|.*/||' \
    | sed -n 's/^video \([0-9][0-9]*\).*/\1/p' \
    | sort -n | tail -n 1)
 
[ -z "$NUMBER" ] && NUMBER=0
NUMBER=$((NUMBER + 1))
 
PROJEKT="$BASIS/video $NUMBER ($SLUG)"
 
if [ -e "$PROJEKT" ]; then
    echo "Projekt existiert bereits: $PROJEKT"
    exit 1
fi
 
for subfolder in $FOLDER; do
    mkdir -p "$PROJEKT/$subfolder"
done
 
echo "Projekt angelegt: video $NUMBER ($SLUG)"
for subfolder in $FOLDER; do
    echo "  $subfolder"
done
 
# Ordner im Finder oeffnen (nur unter macOS)
if [ "$(uname)" = "Darwin" ]; then
    open "$PROJEKT"
fi
