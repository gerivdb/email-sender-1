#!/bin/sh
# install_diffedit_tools.sh : installe tous les outils diff Edit Go natif
# À lancer depuis la racine du repo

# Copie du hook git
cp tools/diff_edit/hooks/pre-commit-diffedit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "Hook Git pre-commit activé."

echo "Vérification des scripts Go..."
ls tools/diff_edit/go/diffedit.go tools/diff_edit/go/undo.go tools/diff_edit/go/batch_diffedit.go

echo "Vérification des tâches VS Code (tasks.json)..."
ls .vscode/tasks.json

echo "Installation terminée. Pensez à lier les tâches VS Code à un raccourci si besoin."
