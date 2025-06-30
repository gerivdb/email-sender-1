#!/bin/bash
# Exemple d'intégration du wrapper de capture terminale dans un script critique

echo "Démarrage du script critique"
./capture_terminal.sh ls -l /tmp

echo "Traitement critique terminé"
./capture_terminal.sh echo "Fin du traitement critique"
