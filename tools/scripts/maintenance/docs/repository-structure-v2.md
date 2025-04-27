﻿# Structure du dÃ©pÃ´t v2

Ce document dÃ©crit la nouvelle structure hiÃ©rarchisÃ©e du dÃ©pÃ´t.

## Structure principale

```
EMAIL_SENDER_1/
â”œâ”€â”€ src/                         # Code source principal
â”œâ”€â”€ tools/                       # Outils et scripts
â”œâ”€â”€ docs/                        # Documentation
â”œâ”€â”€ tests/                       # Tests
â”œâ”€â”€ config/                      # Configuration
â”œâ”€â”€ assets/                      # Ressources statiques
â””â”€â”€ .build/                      # Fichiers de build et CI/CD
```

## Structure dÃ©taillÃ©e

### src/ - Code source principal

```
src/
â”œâ”€â”€ core/                        # FonctionnalitÃ©s de base
â”œâ”€â”€ modules/                     # Modules fonctionnels
â”œâ”€â”€ api/                         # API et interfaces
â”œâ”€â”€ services/                    # Services
â”œâ”€â”€ utils/                       # Utilitaires
â”œâ”€â”€ models/                      # ModÃ¨les de donnÃ©es
â”œâ”€â”€ n8n/                         # Workflows n8n
â””â”€â”€ frontend/                    # Interface utilisateur
```

### tools/ - Outils et scripts

```
tools/
â”œâ”€â”€ scripts/                     # Scripts divers
â”‚   â”œâ”€â”€ roadmap/                 # Scripts de roadmap
â”‚   â”‚   â””â”€â”€ parser/              # Parser de roadmap
â”‚   â”‚       â””â”€â”€ modes/           # Modes opÃ©rationnels
â”‚   â”‚           â”œâ”€â”€ debug/       # Mode de dÃ©bogage
â”‚   â”‚           â”œâ”€â”€ test/        # Mode de test
â”‚   â”‚           â”œâ”€â”€ archi/       # Mode d'architecture
â”‚   â”‚           â”œâ”€â”€ check/       # Mode de vÃ©rification
â”‚   â”‚           â”œâ”€â”€ gran/        # Mode de granularisation
â”‚   â”‚           â”œâ”€â”€ dev-r/       # Mode de dÃ©veloppement roadmap
â”‚   â”‚           â”œâ”€â”€ review/      # Mode de revue
â”‚   â”‚           â””â”€â”€ opti/        # Mode d'optimisation
â”‚   â”œâ”€â”€ maintenance/             # Scripts de maintenance
â”‚   â”‚   â”œâ”€â”€ organize/            # Scripts d'organisation
â”‚   â”‚   â”œâ”€â”€ cleanup/             # Scripts de nettoyage
â”‚   â”‚   â”œâ”€â”€ migrate/             # Scripts de migration
â”‚   â”‚   â”œâ”€â”€ docs/                # Documentation
â”‚   â”‚   â”œâ”€â”€ backups/             # Sauvegardes
â”‚   â”‚   â””â”€â”€ logs/                # Journaux
â”‚   â”œâ”€â”€ deployment/              # Scripts de dÃ©ploiement
â”‚   â””â”€â”€ automation/              # Scripts d'automatisation
â”œâ”€â”€ generators/                  # GÃ©nÃ©rateurs de code
â”œâ”€â”€ analyzers/                   # Outils d'analyse
â”œâ”€â”€ converters/                  # Outils de conversion
â”œâ”€â”€ templates/                   # Templates
â”‚   â””â”€â”€ reports/                 # Templates de rapports
â””â”€â”€ _templates/                  # Templates Hygen
    â”œâ”€â”€ roadmap/                 # Templates pour roadmap
    â”œâ”€â”€ roadmap-parser/          # Templates pour roadmap-parser
    â””â”€â”€ maintenance/             # Templates pour maintenance
```

### docs/ - Documentation

```
docs/
â”œâ”€â”€ guides/                      # Guides d'utilisation
â”‚   â”œâ”€â”€ user/                    # Guides utilisateur
â”‚   â”œâ”€â”€ developer/               # Guides dÃ©veloppeur
â”‚   â”œâ”€â”€ admin/                   # Guides administrateur
â”‚   â””â”€â”€ methodologies/           # MÃ©thodologies
â”‚       â”œâ”€â”€ modes/               # Documentation des modes
â”‚       â””â”€â”€ programming/         # Documentation de programmation
â”œâ”€â”€ api/                         # Documentation API
â”œâ”€â”€ architecture/                # Documentation architecture
â”œâ”€â”€ roadmap/                     # Roadmap du projet
â”‚   â””â”€â”€ plans/                   # Plans de roadmap
â”œâ”€â”€ examples/                    # Exemples
â””â”€â”€ references/                  # RÃ©fÃ©rences
```

### tests/ - Tests

```
tests/
â”œâ”€â”€ unit/                        # Tests unitaires
â”œâ”€â”€ integration/                 # Tests d'intÃ©gration
â”œâ”€â”€ performance/                 # Tests de performance
â”œâ”€â”€ e2e/                         # Tests end-to-end
â”œâ”€â”€ fixtures/                    # DonnÃ©es de test
â””â”€â”€ mocks/                       # Mocks et stubs
```

### config/ - Configuration

```
config/
â”œâ”€â”€ environments/                # Configurations d'environnement
â”œâ”€â”€ settings/                    # ParamÃ¨tres gÃ©nÃ©raux
â”œâ”€â”€ schemas/                     # SchÃ©mas de configuration
â””â”€â”€ templates/                   # Templates de configuration
```

### assets/ - Ressources statiques

```
assets/
â”œâ”€â”€ images/                      # Images
â”œâ”€â”€ styles/                      # Styles
â”œâ”€â”€ fonts/                       # Polices
â”œâ”€â”€ data/                        # DonnÃ©es statiques
â””â”€â”€ media/                       # MÃ©dias
```

### .build/ - Fichiers de build et CI/CD

```
.build/
â”œâ”€â”€ ci/                          # Configuration CI
â”‚   â””â”€â”€ git-hooks/               # Hooks Git
â”œâ”€â”€ cd/                          # Configuration CD
â”œâ”€â”€ pipelines/                   # Pipelines
â”œâ”€â”€ scripts/                     # Scripts de build
â”œâ”€â”€ artifacts/                   # Artefacts de build
â”œâ”€â”€ cache/                       # Cache de build
â”œâ”€â”€ logs/                        # Logs de build
â”œâ”€â”€ output/                      # Sortie de build
â”œâ”€â”€ backups/                     # Sauvegardes
â””â”€â”€ archive/                     # Archives
```

## Mappages des dossiers existants

| Ancien emplacement | Nouvel emplacement |
|--------------------|-------------------|
| scripts/ | tools/scripts/ |
| scripts/roadmap/ | tools/scripts/roadmap/ |
| scripts/roadmap-parser/ | tools/scripts/roadmap/parser/ |
| scripts/maintenance/ | tools/scripts/maintenance/ |
| _templates/ | tools/_templates/ |
| templates/ | tools/templates/ |
| Roadmap/ | docs/roadmap/ |
| Roadmap/mes-plans/ | docs/roadmap/plans/ |
| docs/guides/ | docs/guides/ |
| n8n/ | src/n8n/ |
| frontend/ | src/frontend/ |
| modules/ | src/modules/ |
| tests/ | tests/ |
| config/ | config/ |
| assets/ | assets/ |
| logs/ | .build/logs/ |
| cache/ | .build/cache/ |
| dashboards/ | tools/dashboards/ |
| reports/ | tools/reports/ |
| tools/ | tools/ |
| mcp/ | src/mcp/ |
| data/ | assets/data/ |
| journal/ | docs/journal/ |
| backups/ | .build/backups/ |
| extensions/ | src/extensions/ |
| git-hooks/ | .build/ci/git-hooks/ |
| ProjectManagement/ | docs/project-management/ |
| ErrorManagement/ | src/error-management/ |
| FormatSupport/ | src/format-support/ |
| Insights/ | tools/insights/ |
| output/ | .build/output/ |
| SWE-bench/ | tools/swe-bench/ |
| cmd/ | tools/cmd/ |
| md/ | docs/md/ |
| archive/ | .build/archive/ |

## Mappages des fichiers

| Type de fichier | Nouvel emplacement |
|-----------------|-------------------|
| *.md | docs/readme/ |
| *.txt | docs/readme/ |
| *.json | config/settings/ |
| *.yaml, *.yml | config/settings/ |
| *.ps1 | tools/scripts/ |
| *.py | tools/scripts/ |
| *.js | src/scripts/ |
| *.ts | src/scripts/ |
| *.css | assets/styles/ |
| *.scss | assets/styles/ |
| *.html | src/frontend/ |

## Fichiers conservÃ©s Ã  la racine

Les fichiers suivants sont conservÃ©s Ã  la racine du dÃ©pÃ´t :
- README.md
- .gitignore
- .gitattributes
- LICENSE
- package.json
- package-lock.json
- requirements.txt
- setup.py
- pyproject.toml

## Dossiers conservÃ©s Ã  la racine

Les dossiers suivants sont conservÃ©s Ã  la racine du dÃ©pÃ´t :
- .git/
- .github/
- .vscode/
- .idea/
- node_modules/
- __pycache__/
- .pytest_cache/
- .augment/

## Utilisation des scripts

### RÃ©organisation du dÃ©pÃ´t

```powershell
# ExÃ©cuter en mode simulation (dry run)
.\organize-repository-v2.ps1 -DryRun

# ExÃ©cuter avec confirmation pour chaque action
.\organize-repository-v2.ps1

# ExÃ©cuter sans confirmation et avec journalisation
.\organize-repository-v2.ps1 -Force -LogFile "organize-v2.log"
```

### Nettoyage des fichiers originaux

```powershell
# ExÃ©cuter en mode simulation (dry run)
.\cleanup-repository-v2.ps1 -DryRun

# ExÃ©cuter avec confirmation pour chaque action
.\cleanup-repository-v2.ps1

# ExÃ©cuter sans confirmation et avec journalisation
.\cleanup-repository-v2.ps1 -Force -LogFile "cleanup-v2.log"
```

## Avantages de la nouvelle structure

1. **RÃ©duction du nombre de dossiers Ã  la racine** : Passage de plus de 30 dossiers Ã  seulement 7 dossiers principaux.
2. **Organisation logique** : Les fichiers et dossiers sont organisÃ©s selon leur fonction.
3. **FacilitÃ© de navigation** : Structure hiÃ©rarchique claire et intuitive.
4. **Meilleure maintenabilitÃ©** : SÃ©paration claire des prÃ©occupations.
5. **Standardisation** : Structure conforme aux bonnes pratiques de l'industrie.
6. **Ã‰volutivitÃ©** : FacilitÃ© d'ajout de nouveaux composants sans perturber la structure existante.

## Bonnes pratiques

1. Respecter la structure dÃ©finie lors de l'ajout de nouveaux fichiers ou dossiers.
2. Utiliser les scripts de gÃ©nÃ©ration pour crÃ©er de nouveaux fichiers au bon emplacement.
3. Mettre Ã  jour la documentation en cas de modification de la structure.
4. ExÃ©cuter rÃ©guliÃ¨rement le script d'organisation pour maintenir la structure cohÃ©rente.
