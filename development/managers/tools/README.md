# Manager Toolkit

Ce répertoire a été réorganisé pour suivre les principes SOLID, KISS et DRY. Pour la documentation complète, veuillez consulter le fichier README principal dans le dossier `docs`.

## Structure des dossiers

```plaintext
tools/
├── cmd/manager-toolkit/     # Point d'entrée de l'application

├── core/registry/          # Registre centralisé des outils

├── core/toolkit/           # Fonctionnalités centrales partagées  

├── docs/                   # Documentation complète

├── internal/test/          # Tests et mocks internes

├── legacy/                 # Fichiers archivés/legacy

├── operations/analysis/    # Outils d'analyse statique

├── operations/correction/  # Outils de correction automatisée

├── operations/migration/   # Outils de migration de code

├── operations/validation/  # Outils de validation de structures

└── testdata/               # Données de test

```plaintext
## Documentation principale

Pour une documentation complète, veuillez consulter les fichiers suivants :
- [README principal](docs/README.md)
- [Documentation de l'écosystème v3.0.0](docs/TOOLS_ECOSYSTEM_DOCUMENTATION_V3.md)
