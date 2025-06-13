# Scripts d'organisation

Ce répertoire contient des scripts pour organiser les fichiers et dossiers du projet.

## Script principal

### Organize-MaintenanceFiles.ps1

Ce script utilise le MCP Desktop Commander pour déplacer les fichiers de la racine du répertoire de maintenance vers des sous-dossiers thématiques selon leur fonction. Il crée également de nouveaux sous-dossiers si nécessaire.

#### Prérequis

- Node.js et npm installés
- MCP Desktop Commander installé (`npm install -g @wonderwhy-er/desktop-commander`)

#### Utilisation

```powershell
# Exécuter en mode simulation (dry run)

.\Organize-MaintenanceFiles.ps1 -DryRun

# Exécuter avec confirmation pour chaque action

.\Organize-MaintenanceFiles.ps1

# Exécuter sans confirmation

.\Organize-MaintenanceFiles.ps1 -Force
```plaintext
## Structure organisée

Le script organise les fichiers selon la structure suivante :

```plaintext
development/scripts/maintenance/
├── api/                  # Fichiers liés à OpenRouter/Qwen3

├── cleanup/              # Fichiers liés à la maintenance du code

├── docs/                 # Documentation

├── encoding/             # Fichiers liés à l'encodage

├── environment-compatibility/ # Fichiers liés à l'environnement

├── modules/              # Fichiers liés aux managers

├── roadmap/              # Fichiers liés à la roadmap

└── ... (autres dossiers existants)
```plaintext
## Utilisation avec Hygen

```bash
hygen maintenance organize
```plaintext
## Bonnes pratiques

1. Toujours exécuter les scripts en mode simulation (`-DryRun`) avant de les exécuter réellement
2. Créer des sauvegardes avant d'effectuer des opérations potentiellement destructives
3. Journaliser toutes les actions effectuées

## Intégration avec Hygen

Ce script est compatible avec la structure de templates Hygen du projet. Il respecte les conventions de nommage et d'organisation des fichiers définies dans les templates Hygen.
