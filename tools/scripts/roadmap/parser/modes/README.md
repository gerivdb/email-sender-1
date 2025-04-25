# Modes opérationnels

Ce répertoire contient les scripts pour les différents modes opérationnels du module roadmap-parser.

## Modes disponibles

- **DEBUG** : Mode de débogage pour identifier et résoudre les problèmes
- **TEST** : Mode de test pour valider les fonctionnalités
- **ARCHI** : Mode d'architecture pour analyser et améliorer la structure
- **CHECK** : Mode de vérification pour valider l'état d'avancement
- **GRAN** : Mode de granularisation pour décomposer les tâches complexes
- **DEV-R** : Mode de développement roadmap pour implémenter les tâches
- **REVIEW** : Mode de revue pour analyser la qualité du code
- **OPTI** : Mode d'optimisation pour améliorer les performances

## Structure du répertoire

Chaque mode a son propre sous-répertoire contenant :
- Le script principal du mode
- Les fonctions spécifiques au mode
- La documentation du mode
- Les tests unitaires du mode

```
modes/
├── debug/                   # Mode de débogage
│   ├── debug-mode.ps1       # Script principal
│   └── README.md            # Documentation
├── test/                    # Mode de test
│   ├── test-mode.ps1        # Script principal
│   └── README.md            # Documentation
├── archi/                   # Mode d'architecture
│   ├── archi-mode.ps1       # Script principal
│   └── README.md            # Documentation
├── check/                   # Mode de vérification
│   ├── check-mode.ps1       # Script principal
│   └── README.md            # Documentation
├── gran/                    # Mode de granularisation
│   ├── gran-mode.ps1        # Script principal
│   └── README.md            # Documentation
├── dev-r/                   # Mode de développement roadmap
│   ├── dev-r-mode.ps1       # Script principal
│   └── README.md            # Documentation
├── review/                  # Mode de revue
│   ├── review-mode.ps1      # Script principal
│   └── README.md            # Documentation
└── opti/                    # Mode d'optimisation
    ├── opti-mode.ps1        # Script principal
    └── README.md            # Documentation
```

## Utilisation

Chaque mode peut être utilisé indépendamment ou en combinaison avec d'autres modes.

```powershell
# Exemple d'utilisation du mode DEBUG
.\debug-mode.ps1 -RoadmapPath "Roadmap/roadmap.md" -Verbose

# Exemple d'utilisation du mode GRAN
.\gran-mode.ps1 -RoadmapPath "Roadmap/roadmap.md" -TaskId "1.2.3"
```

## Développement de nouveaux modes

Pour développer un nouveau mode, utilisez Hygen pour générer la structure de base :

```bash
hygen roadmap-parser new mode
```

Suivez ensuite les conventions de nommage et de structure pour assurer la cohérence avec les autres modes.
