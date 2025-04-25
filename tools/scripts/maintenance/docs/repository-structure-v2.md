# Structure du dépôt v2

Ce document décrit la nouvelle structure hiérarchisée du dépôt.

## Structure principale

```
EMAIL_SENDER_1/
├── src/                         # Code source principal
├── tools/                       # Outils et scripts
├── docs/                        # Documentation
├── tests/                       # Tests
├── config/                      # Configuration
├── assets/                      # Ressources statiques
└── .build/                      # Fichiers de build et CI/CD
```

## Structure détaillée

### src/ - Code source principal

```
src/
├── core/                        # Fonctionnalités de base
├── modules/                     # Modules fonctionnels
├── api/                         # API et interfaces
├── services/                    # Services
├── utils/                       # Utilitaires
├── models/                      # Modèles de données
├── n8n/                         # Workflows n8n
└── frontend/                    # Interface utilisateur
```

### tools/ - Outils et scripts

```
tools/
├── scripts/                     # Scripts divers
│   ├── roadmap/                 # Scripts de roadmap
│   │   └── parser/              # Parser de roadmap
│   │       └── modes/           # Modes opérationnels
│   │           ├── debug/       # Mode de débogage
│   │           ├── test/        # Mode de test
│   │           ├── archi/       # Mode d'architecture
│   │           ├── check/       # Mode de vérification
│   │           ├── gran/        # Mode de granularisation
│   │           ├── dev-r/       # Mode de développement roadmap
│   │           ├── review/      # Mode de revue
│   │           └── opti/        # Mode d'optimisation
│   ├── maintenance/             # Scripts de maintenance
│   │   ├── organize/            # Scripts d'organisation
│   │   ├── cleanup/             # Scripts de nettoyage
│   │   ├── migrate/             # Scripts de migration
│   │   ├── docs/                # Documentation
│   │   ├── backups/             # Sauvegardes
│   │   └── logs/                # Journaux
│   ├── deployment/              # Scripts de déploiement
│   └── automation/              # Scripts d'automatisation
├── generators/                  # Générateurs de code
├── analyzers/                   # Outils d'analyse
├── converters/                  # Outils de conversion
├── templates/                   # Templates
│   └── reports/                 # Templates de rapports
└── _templates/                  # Templates Hygen
    ├── roadmap/                 # Templates pour roadmap
    ├── roadmap-parser/          # Templates pour roadmap-parser
    └── maintenance/             # Templates pour maintenance
```

### docs/ - Documentation

```
docs/
├── guides/                      # Guides d'utilisation
│   ├── user/                    # Guides utilisateur
│   ├── developer/               # Guides développeur
│   ├── admin/                   # Guides administrateur
│   └── methodologies/           # Méthodologies
│       ├── modes/               # Documentation des modes
│       └── programming/         # Documentation de programmation
├── api/                         # Documentation API
├── architecture/                # Documentation architecture
├── roadmap/                     # Roadmap du projet
│   └── plans/                   # Plans de roadmap
├── examples/                    # Exemples
└── references/                  # Références
```

### tests/ - Tests

```
tests/
├── unit/                        # Tests unitaires
├── integration/                 # Tests d'intégration
├── performance/                 # Tests de performance
├── e2e/                         # Tests end-to-end
├── fixtures/                    # Données de test
└── mocks/                       # Mocks et stubs
```

### config/ - Configuration

```
config/
├── environments/                # Configurations d'environnement
├── settings/                    # Paramètres généraux
├── schemas/                     # Schémas de configuration
└── templates/                   # Templates de configuration
```

### assets/ - Ressources statiques

```
assets/
├── images/                      # Images
├── styles/                      # Styles
├── fonts/                       # Polices
├── data/                        # Données statiques
└── media/                       # Médias
```

### .build/ - Fichiers de build et CI/CD

```
.build/
├── ci/                          # Configuration CI
│   └── git-hooks/               # Hooks Git
├── cd/                          # Configuration CD
├── pipelines/                   # Pipelines
├── scripts/                     # Scripts de build
├── artifacts/                   # Artefacts de build
├── cache/                       # Cache de build
├── logs/                        # Logs de build
├── output/                      # Sortie de build
├── backups/                     # Sauvegardes
└── archive/                     # Archives
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

## Fichiers conservés à la racine

Les fichiers suivants sont conservés à la racine du dépôt :
- README.md
- .gitignore
- .gitattributes
- LICENSE
- package.json
- package-lock.json
- requirements.txt
- setup.py
- pyproject.toml

## Dossiers conservés à la racine

Les dossiers suivants sont conservés à la racine du dépôt :
- .git/
- .github/
- .vscode/
- .idea/
- node_modules/
- __pycache__/
- .pytest_cache/
- .augment/

## Utilisation des scripts

### Réorganisation du dépôt

```powershell
# Exécuter en mode simulation (dry run)
.\organize-repository-v2.ps1 -DryRun

# Exécuter avec confirmation pour chaque action
.\organize-repository-v2.ps1

# Exécuter sans confirmation et avec journalisation
.\organize-repository-v2.ps1 -Force -LogFile "organize-v2.log"
```

### Nettoyage des fichiers originaux

```powershell
# Exécuter en mode simulation (dry run)
.\cleanup-repository-v2.ps1 -DryRun

# Exécuter avec confirmation pour chaque action
.\cleanup-repository-v2.ps1

# Exécuter sans confirmation et avec journalisation
.\cleanup-repository-v2.ps1 -Force -LogFile "cleanup-v2.log"
```

## Avantages de la nouvelle structure

1. **Réduction du nombre de dossiers à la racine** : Passage de plus de 30 dossiers à seulement 7 dossiers principaux.
2. **Organisation logique** : Les fichiers et dossiers sont organisés selon leur fonction.
3. **Facilité de navigation** : Structure hiérarchique claire et intuitive.
4. **Meilleure maintenabilité** : Séparation claire des préoccupations.
5. **Standardisation** : Structure conforme aux bonnes pratiques de l'industrie.
6. **Évolutivité** : Facilité d'ajout de nouveaux composants sans perturber la structure existante.

## Bonnes pratiques

1. Respecter la structure définie lors de l'ajout de nouveaux fichiers ou dossiers.
2. Utiliser les scripts de génération pour créer de nouveaux fichiers au bon emplacement.
3. Mettre à jour la documentation en cas de modification de la structure.
4. Exécuter régulièrement le script d'organisation pour maintenir la structure cohérente.
