# Structure du dépôt

Ce document décrit la structure standardisée du dépôt.

## Structure des répertoires

```
EMAIL_SENDER_1/
├── scripts/                      # Scripts PowerShell et Python
│   ├── roadmap/                  # Scripts pour la gestion des roadmaps
│   │   ├── core/                 # Fonctionnalités de base
│   │   ├── journal/              # Gestion du journal
│   │   ├── management/           # Gestion des tâches
│   │   ├── tests/                # Tests unitaires
│   │   ├── utils/                # Utilitaires
│   │   └── docs/                 # Documentation
│   ├── roadmap-parser/           # Module de parsing de roadmap
│   │   ├── modes/                # Modes opérationnels
│   │   │   ├── debug/            # Mode de débogage
│   │   │   ├── test/             # Mode de test
│   │   │   ├── archi/            # Mode d'architecture
│   │   │   ├── check/            # Mode de vérification
│   │   │   ├── gran/             # Mode de granularisation
│   │   │   ├── dev-r/            # Mode de développement roadmap
│   │   │   ├── review/           # Mode de revue
│   │   │   └── opti/             # Mode d'optimisation
│   │   ├── core/                 # Fonctionnalités de base
│   │   │   ├── parser/           # Parseurs de roadmap
│   │   │   ├── model/            # Modèles de données
│   │   │   ├── converter/        # Convertisseurs de format
│   │   │   └── structure/        # Gestion de structure
│   │   ├── utils/                # Utilitaires
│   │   │   ├── encoding/         # Gestion d'encodage
│   │   │   ├── export/           # Export vers différents formats
│   │   │   ├── import/           # Import depuis différents formats
│   │   │   └── helpers/          # Fonctions d'aide
│   │   ├── analysis/             # Outils d'analyse
│   │   │   ├── dependencies/     # Analyse de dépendances
│   │   │   ├── performance/      # Analyse de performance
│   │   │   ├── validation/       # Validation de roadmap
│   │   │   └── reporting/        # Génération de rapports
│   │   ├── tests/                # Tests
│   │   │   ├── unit/             # Tests unitaires
│   │   │   ├── integration/      # Tests d'intégration
│   │   │   ├── performance/      # Tests de performance
│   │   │   └── validation/       # Tests de validation
│   │   └── docs/                 # Documentation
│   │       ├── examples/         # Exemples d'utilisation
│   │       ├── guides/           # Guides d'utilisation
│   │       └── api/              # Documentation de l'API
│   └── maintenance/              # Scripts de maintenance
│       ├── organize/             # Scripts d'organisation
│       ├── cleanup/              # Scripts de nettoyage
│       ├── migrate/              # Scripts de migration
│       ├── docs/                 # Documentation
│       ├── backups/              # Sauvegardes
│       └── logs/                 # Journaux
├── docs/                         # Documentation
│   └── guides/                   # Guides d'utilisation
│       ├── best-practices/       # Bonnes pratiques
│       ├── core/                 # Documentation du core
│       ├── git/                  # Documentation Git
│       ├── installation/         # Documentation d'installation
│       ├── mcp/                  # Documentation MCP
│       ├── methodologies/        # Documentation des méthodologies
│       ├── n8n/                  # Documentation n8n
│       ├── powershell/           # Documentation PowerShell
│       ├── python/               # Documentation Python
│       ├── tools/                # Documentation des outils
│       └── troubleshooting/      # Dépannage
├── Roadmap/                      # Roadmaps
│   └── mes-plans/                # Plans personnalisés
├── templates/                    # Templates
│   └── reports/                  # Templates de rapports
├── _templates/                   # Templates Hygen
│   ├── roadmap/                  # Templates pour roadmap
│   ├── roadmap-parser/           # Templates pour roadmap-parser
│   └── maintenance/              # Templates pour maintenance
├── n8n/                          # Workflows n8n
├── all-workflows/                # Tous les workflows
└── mcp/                          # Serveurs MCP
```

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

Les modes opérationnels sont organisés dans le dossier `scripts/roadmap-parser/modes`, avec un sous-dossier pour chaque mode :

- **DEBUG** : Mode de débogage pour identifier et résoudre les problèmes
- **TEST** : Mode de test pour valider les fonctionnalités
- **ARCHI** : Mode d'architecture pour analyser et améliorer la structure
- **CHECK** : Mode de vérification pour valider l'état d'avancement
- **GRAN** : Mode de granularisation pour décomposer les tâches complexes
- **DEV-R** : Mode de développement roadmap pour implémenter les tâches
- **REVIEW** : Mode de revue pour analyser la qualité du code
- **OPTI** : Mode d'optimisation pour améliorer les performances

Chaque mode a son propre script principal (`<mode>-mode.ps1`) et peut avoir des scripts auxiliaires et des tests.

## Maintenance

Les scripts de maintenance sont organisés dans le dossier `scripts/maintenance`, avec des sous-dossiers pour chaque type de maintenance :

- **organize/** : Scripts pour organiser les fichiers et dossiers
- **cleanup/** : Scripts pour nettoyer les fichiers inutiles
- **migrate/** : Scripts pour migrer des fichiers d'un répertoire à un autre
- **docs/** : Documentation sur la maintenance
- **backups/** : Sauvegardes créées avant les opérations de maintenance
- **logs/** : Journaux des opérations de maintenance

## Utilisation de Hygen

Le projet utilise [Hygen](https://www.hygen.io/) pour générer des scripts et des templates. Les templates Hygen sont organisés dans le dossier `_templates`, avec des sous-dossiers pour chaque type de template :

- **roadmap/** : Templates pour roadmap
- **roadmap-parser/** : Templates pour roadmap-parser
- **maintenance/** : Templates pour maintenance

Pour générer un nouveau script, utilisez la commande suivante :

```bash
hygen <type> <action>
```

Par exemple :

```bash
hygen roadmap-parser new script
hygen maintenance organize
```
