# Structure du dÃ©pÃ´t

Ce document dÃ©crit la structure standardisÃ©e du dÃ©pÃ´t.

## Structure des rÃ©pertoires

```plaintext
EMAIL_SENDER_1/
â”œâ”€â”€ development/scripts/                      # Scripts PowerShell et Python

â”‚   â”œâ”€â”€ roadmap/                  # Scripts pour la gestion des roadmaps

â”‚   â”‚   â”œâ”€â”€ core/                 # FonctionnalitÃ©s de base

â”‚   â”‚   â”œâ”€â”€ journal/              # Gestion du journal

â”‚   â”‚   â”œâ”€â”€ management/           # Gestion des tÃ¢ches

â”‚   â”‚   â”œâ”€â”€ development/testing/tests/                # Tests unitaires

â”‚   â”‚   â”œâ”€â”€ utils/                # Utilitaires

â”‚   â”‚   â””â”€â”€ docs/                 # Documentation

â”‚   â”œâ”€â”€ roadmap-parser/           # Module de parsing de roadmap

â”‚   â”‚   â”œâ”€â”€ modes/                # Modes opÃ©rationnels

â”‚   â”‚   â”‚   â”œâ”€â”€ debug/            # Mode de dÃ©bogage

â”‚   â”‚   â”‚   â”œâ”€â”€ test/             # Mode de test

â”‚   â”‚   â”‚   â”œâ”€â”€ archi/            # Mode d'architecture

â”‚   â”‚   â”‚   â”œâ”€â”€ check/            # Mode de vÃ©rification

â”‚   â”‚   â”‚   â”œâ”€â”€ gran/             # Mode de granularisation

â”‚   â”‚   â”‚   â”œâ”€â”€ dev-r/            # Mode de dÃ©veloppement roadmap

â”‚   â”‚   â”‚   â”œâ”€â”€ review/           # Mode de revue

â”‚   â”‚   â”‚   â””â”€â”€ opti/             # Mode d'optimisation

â”‚   â”‚   â”œâ”€â”€ core/                 # FonctionnalitÃ©s de base

â”‚   â”‚   â”‚   â”œâ”€â”€ parser/           # Parseurs de roadmap

â”‚   â”‚   â”‚   â”œâ”€â”€ model/            # ModÃ¨les de donnÃ©es

â”‚   â”‚   â”‚   â”œâ”€â”€ converter/        # Convertisseurs de format

â”‚   â”‚   â”‚   â””â”€â”€ structure/        # Gestion de structure

â”‚   â”‚   â”œâ”€â”€ utils/                # Utilitaires

â”‚   â”‚   â”‚   â”œâ”€â”€ encoding/         # Gestion d'encodage

â”‚   â”‚   â”‚   â”œâ”€â”€ export/           # Export vers diffÃ©rents formats

â”‚   â”‚   â”‚   â”œâ”€â”€ import/           # Import depuis diffÃ©rents formats

â”‚   â”‚   â”‚   â””â”€â”€ helpers/          # Fonctions d'aide

â”‚   â”‚   â”œâ”€â”€ analysis/             # Outils d'analyse

â”‚   â”‚   â”‚   â”œâ”€â”€ dependencies/     # Analyse de dÃ©pendances

â”‚   â”‚   â”‚   â”œâ”€â”€ performance/      # Analyse de performance

â”‚   â”‚   â”‚   â”œâ”€â”€ validation/       # Validation de roadmap

â”‚   â”‚   â”‚   â””â”€â”€ reporting/        # GÃ©nÃ©ration de rapports

â”‚   â”‚   â”œâ”€â”€ development/testing/tests/                # Tests

â”‚   â”‚   â”‚   â”œâ”€â”€ unit/             # Tests unitaires

â”‚   â”‚   â”‚   â”œâ”€â”€ integration/      # Tests d'intÃ©gration

â”‚   â”‚   â”‚   â”œâ”€â”€ performance/      # Tests de performance

â”‚   â”‚   â”‚   â””â”€â”€ validation/       # Tests de validation

â”‚   â”‚   â””â”€â”€ docs/                 # Documentation

â”‚   â”‚       â”œâ”€â”€ examples/         # Exemples d'utilisation

â”‚   â”‚       â”œâ”€â”€ guides/           # Guides d'utilisation

â”‚   â”‚       â””â”€â”€ api/              # Documentation de l'API

â”‚   â””â”€â”€ maintenance/              # Scripts de maintenance

â”‚       â”œâ”€â”€ organize/             # Scripts d'organisation

â”‚       â”œâ”€â”€ cleanup/              # Scripts de nettoyage

â”‚       â”œâ”€â”€ migrate/              # Scripts de migration

â”‚       â”œâ”€â”€ docs/                 # Documentation

â”‚       â”œâ”€â”€ backups/              # Sauvegardes

â”‚       â””â”€â”€ logs/                 # Journaux

â”œâ”€â”€ docs/                         # Documentation

â”‚   â””â”€â”€ guides/                   # Guides d'utilisation

â”‚       â”œâ”€â”€ best-practices/       # Bonnes pratiques

â”‚       â”œâ”€â”€ core/                 # Documentation du core

â”‚       â”œâ”€â”€ git/                  # Documentation Git

â”‚       â”œâ”€â”€ installation/         # Documentation d'installation

â”‚       â”œâ”€â”€ mcp/                  # Documentation MCP

â”‚       â”œâ”€â”€ methodologies/        # Documentation des mÃ©thodologies

â”‚       â”œâ”€â”€ n8n/                  # Documentation n8n

â”‚       â”œâ”€â”€ powershell/           # Documentation PowerShell

â”‚       â”œâ”€â”€ python/               # Documentation Python

â”‚       â”œâ”€â”€ development/tools/                # Documentation des outils

â”‚       â””â”€â”€ troubleshooting/      # DÃ©pannage

â”œâ”€â”€ Roadmap/                      # Roadmaps

â”‚   â””â”€â”€ mes-plans/                # Plans personnalisÃ©s

â”œâ”€â”€ templates/                    # Templates

â”‚   â””â”€â”€ reports/                  # Templates de rapports

â”œâ”€â”€ development/templates/                   # Templates Hygen

â”‚   â”œâ”€â”€ roadmap/                  # Templates pour roadmap

â”‚   â”œâ”€â”€ roadmap-parser/           # Templates pour roadmap-parser

â”‚   â””â”€â”€ maintenance/              # Templates pour maintenance

â”œâ”€â”€ n8n/                          # Workflows n8n

â”œâ”€â”€ all-workflows/                # Tous les workflows

â””â”€â”€ mcp/                          # Serveurs MCP

```plaintext
## Conventions de nommage

### Scripts PowerShell

- Utiliser le format `Verbe-Nom.ps1` pour les scripts
- Utiliser le format `Nom.psm1` pour les modules
- Utiliser le format `Nom.psd1` pour les manifestes de module
- Utiliser le format `Test-Nom.ps1` pour les tests

### Documentation

- Utiliser le format `nom-du-guide.md` pour les guides
- Utiliser le format `mode_nom.md` pour la documentation des modes
- Utiliser le format `programmation_nom.md` pour la documentation de programmation

### Templates

- Utiliser le format `nom.ejs.t` pour les templates Hygen

## Organisation des modes

Les modes opÃ©rationnels sont organisÃ©s dans le dossier `development/roadmap/scripts-parser/modes`, avec un sous-dossier pour chaque mode :

- **DEBUG** : Mode de dÃ©bogage pour identifier et rÃ©soudre les problÃ¨mes
- **TEST** : Mode de test pour valider les fonctionnalitÃ©s
- **ARCHI** : Mode d'architecture pour analyser et amÃ©liorer la structure
- **CHECK** : Mode de vÃ©rification pour valider l'Ã©tat d'avancement
- **GRAN** : Mode de granularisation pour dÃ©composer les tÃ¢ches complexes
- **DEV-R** : Mode de dÃ©veloppement roadmap pour implÃ©menter les tÃ¢ches
- **REVIEW** : Mode de revue pour analyser la qualitÃ© du code
- **OPTI** : Mode d'optimisation pour amÃ©liorer les performances

Chaque mode a son propre script principal (`<mode>-mode.ps1`) et peut avoir des scripts auxiliaires et des tests.

## Maintenance

Les scripts de maintenance sont organisÃ©s dans le dossier `development/scripts/maintenance`, avec des sous-dossiers pour chaque type de maintenance :

- **organize/** : Scripts pour organiser les fichiers et dossiers
- **cleanup/** : Scripts pour nettoyer les fichiers inutiles
- **migrate/** : Scripts pour migrer des fichiers d'un rÃ©pertoire Ã  un autre
- **docs/** : Documentation sur la maintenance
- **backups/** : Sauvegardes crÃ©Ã©es avant les opÃ©rations de maintenance
- **logs/** : Journaux des opÃ©rations de maintenance

## Utilisation de Hygen

Le projet utilise [Hygen](https://www.hygen.io/) pour gÃ©nÃ©rer des scripts et des templates. Les templates Hygen sont organisÃ©s dans le dossier `development/templates`, avec des sous-dossiers pour chaque type de template :

- **roadmap/** : Templates pour roadmap
- **roadmap-parser/** : Templates pour roadmap-parser
- **maintenance/** : Templates pour maintenance

Pour gÃ©nÃ©rer un nouveau script, utilisez la commande suivante :

```bash
hygen <type> <action>
```plaintext
Par exemple :

```bash
hygen roadmap-parser new script
hygen maintenance organize
```plaintext