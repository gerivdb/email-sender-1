# Automatisation complète et activation zéro-intervention (diff Edit Go natif)

- **Vérification hook Git** :
  - Script de vérification automatique de la présence et de l’activation de `pre-commit-diffedit.sh` dans `.git/hooks/pre-commit`.
- **Tâches VS Code bindées** :
  - Exemple de configuration dans `tasks.json` et doc pour lier à un raccourci ou à l’enregistrement de fichiers.
- **Intégration CI** :
  - Pipeline CI/CD déjà fourni (`CI_CD.md`) pour appliquer/valider les patchs à chaque push/PR.
- **Script d’installation automatique** :
  - `install_diffedit_tools.sh` : copie les hooks, configure les tâches VS Code, vérifie la présence des scripts Go, etc.
- **Check de conformité** :
  - Script Go `check_diffedit_setup.go` qui vérifie la présence et l’activation de tous les outils d’automatisation.
- **Rapport d’état** :
  - Génération d’un rapport Markdown listant les outils activés, ceux manquants, et les actions à effectuer.

## Artefacts fournis

- `hooks/pre-commit-diffedit.sh`
- `install_diffedit_tools.sh`
- `check_diffedit_setup.go`
- Doc d’intégration dans le README
