#!/bin/bash
# Supprime tous les go.mod et go.work parasites (hors racine du projet)

# Détection du chemin absolu du go.mod racine
ROOT_MOD="$(realpath ./go.mod)"

find . -type f \( -name "go.mod" -o -name "go.work" \) | while read file; do
  # Ne supprime pas le go.mod racine
  if [[ "$(realpath "$file")" != "$ROOT_MOD" ]]; then
    echo "Suppression de $file"
    rm "$file"
  fi
done
