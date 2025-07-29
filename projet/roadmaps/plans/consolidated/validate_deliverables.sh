#!/bin/bash
# Script de validation des livrables - Kilo Code
# Chemin : projet/roadmaps/plans/consolidated/validate_deliverables.sh

DIR="."
REPORT="./validation_report.txt"
MD_FILES=($(ls *.md 2>/dev/null))
CSV_FILES=($(ls *.csv 2>/dev/null))
LOG_FILES=($(ls *.txt 2>/dev/null))

echo "Rapport de validation des livrables ($DIR)" > "$REPORT"
echo "Date : $(date)" >> "$REPORT"
echo "----------------------------------------" >> "$REPORT"

# Vérification existence
echo "Fichiers Markdown (.md) :" >> "$REPORT"
if [ ${#MD_FILES[@]} -eq 0 ]; then
  echo "  Aucun fichier .md trouvé." >> "$REPORT"
else
  for f in "${MD_FILES[@]}"; do
    echo "  - $(basename "$f") [OK]" >> "$REPORT"
  done
fi

echo "" >> "$REPORT"
echo "Fichiers CSV (.csv) :" >> "$REPORT"
if [ ${#CSV_FILES[@]} -eq 0 ]; then
  echo "  Aucun fichier .csv trouvé." >> "$REPORT"
else
  for f in "${CSV_FILES[@]}"; do
    echo "  - $(basename "$f") [OK]" >> "$REPORT"
    # Vérification structure CSV
    HEADER=$(head -n 1 "$f")
    NB_LINES=$(cat "$f" | wc -l)
    if [ -z "$HEADER" ]; then
      echo "    [ERREUR] Entête manquant." >> "$REPORT"
    fi
    if [ "$NB_LINES" -lt 2 ]; then
      echo "    [ERREUR] Pas de données (seulement l’entête ou vide)." >> "$REPORT"
    fi
  done
fi

echo "" >> "$REPORT"
echo "Fichiers logs (.txt) :" >> "$REPORT"
if [ ${#LOG_FILES[@]} -eq 0 ]; then
  echo "  Aucun fichier .txt trouvé." >> "$REPORT"
else
  for f in "${LOG_FILES[@]}"; do
    echo "  - $(basename "$f") [OK]" >> "$REPORT"
  done
fi

echo "" >> "$REPORT"
echo "Validation terminée." >> "$REPORT"
echo "Consultez $REPORT pour le détail." >> "$REPORT"