#!/bin/bash
# move-files.sh
# Auteur : Roo (IA)
# Version : 1.0
# Date : 2025-08-01
# Description : Script Bash minimaliste pour déplacer des fichiers selon une config YAML, dry-run, log, rollback.
# Usage : ./move-files.sh [-c file-moves.yaml] [-n] [-r] [-l move-files.log]

CONFIG="file-moves.yaml"
DRYRUN=0
ROLLBACK=0
LOG="move-files.log"

while getopts "c:nrl:" opt; do
  case $opt in
    c) CONFIG="$OPTARG" ;;
    n) DRYRUN=1 ;;
    r) ROLLBACK=1 ;;
    l) LOG="$OPTARG" ;;
  esac
done

write_log() {
  echo "$(date -Iseconds) $1" | tee -a "$LOG"
}

do_move() {
  SRC="$1"
  DST="$2"
  if [ $DRYRUN -eq 1 ]; then
    write_log "DRY-RUN : $SRC => $DST"
  else
    if [ -e "$SRC" ]; then
      mv -f "$SRC" "$DST"
      write_log "MOVE : $SRC => $DST"
    else
      write_log "ERREUR : Source introuvable $SRC"
    fi
  fi
}

do_rollback() {
  grep "MOVE :" "$LOG" | while read -r line; do
    SRC=$(echo "$line" | sed -E 's/.*MOVE : (.+) => (.+)$/\2/')
    DST=$(echo "$line" | sed -E 's/.*MOVE : (.+) => (.+)$/\1/')
    if [ -e "$SRC" ]; then
      mv -f "$SRC" "$DST"
      write_log "ROLLBACK : $SRC => $DST"
    fi
  done
}

write_log "=== Début du script move-files.sh ==="
if [ $ROLLBACK -eq 1 ]; then
  do_rollback
  write_log "Rollback terminé."
  exit 0
fi

if ! command -v yq >/dev/null 2>&1; then
  write_log "ERREUR : yq est requis (https://mikefarah.gitbook.io/yq/)."
  exit 1
fi

COUNT=$(yq '.moves | length' "$CONFIG")
if [ "$COUNT" -eq 0 ]; then
  write_log "ERREUR : Section 'moves' manquante ou vide."
  exit 1
fi

for i in $(seq 0 $((COUNT-1))); do
  SRC=$(yq ".moves[$i].source" "$CONFIG")
  DST=$(yq ".moves[$i].destination" "$CONFIG")
  do_move "$SRC" "$DST"
done

write_log "=== Fin du script move-files.sh ==="