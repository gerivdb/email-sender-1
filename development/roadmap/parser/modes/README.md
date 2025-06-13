# Modes opÃ©rationnels

Ce rÃ©pertoire contient les scripts pour les diffÃ©rents modes opÃ©rationnels du module roadmap-parser.

## Modes disponibles

- **DEBUG** : Mode de dÃ©bogage pour identifier et rÃ©soudre les problÃ¨mes
- **TEST** : Mode de test pour valider les fonctionnalitÃ©s
- **ARCHI** : Mode d'architecture pour analyser et amÃ©liorer la structure
- **CHECK** : Mode de vÃ©rification pour valider l'Ã©tat d'avancement
- **GRAN** : Mode de granularisation pour dÃ©composer les tÃ¢ches complexes
- **DEV-R** : Mode de dÃ©veloppement roadmap pour implÃ©menter les tÃ¢ches
- **REVIEW** : Mode de revue pour analyser la qualitÃ© du code
- **OPTI** : Mode d'optimisation pour amÃ©liorer les performances

## Structure du rÃ©pertoire

Chaque mode a son propre sous-rÃ©pertoire contenant :
- Le script principal du mode
- Les fonctions spÃ©cifiques au mode
- La documentation du mode
- Les tests unitaires du mode

```plaintext
modes/
â”œâ”€â”€ debug/                   # Mode de dÃ©bogage

â”‚   â”œâ”€â”€ debug-mode.ps1       # Script principal

â”‚   â””â”€â”€ README.md            # Documentation

â”œâ”€â”€ test/                    # Mode de test

â”‚   â”œâ”€â”€ test-mode.ps1        # Script principal

â”‚   â””â”€â”€ README.md            # Documentation

â”œâ”€â”€ archi/                   # Mode d'architecture

â”‚   â”œâ”€â”€ archi-mode.ps1       # Script principal

â”‚   â””â”€â”€ README.md            # Documentation

â”œâ”€â”€ check/                   # Mode de vÃ©rification

â”‚   â”œâ”€â”€ check-mode.ps1       # Script principal

â”‚   â””â”€â”€ README.md            # Documentation

â”œâ”€â”€ gran/                    # Mode de granularisation

â”‚   â”œâ”€â”€ gran-mode.ps1        # Script principal

â”‚   â””â”€â”€ README.md            # Documentation

â”œâ”€â”€ dev-r/                   # Mode de dÃ©veloppement roadmap

â”‚   â”œâ”€â”€ dev-r-mode.ps1       # Script principal

â”‚   â””â”€â”€ README.md            # Documentation

â”œâ”€â”€ review/                  # Mode de revue

â”‚   â”œâ”€â”€ review-mode.ps1      # Script principal

â”‚   â””â”€â”€ README.md            # Documentation

â””â”€â”€ opti/                    # Mode d'optimisation

    â”œâ”€â”€ opti-mode.ps1        # Script principal

    â””â”€â”€ README.md            # Documentation

```plaintext
## Utilisation

Chaque mode peut Ãªtre utilisÃ© indÃ©pendamment ou en combinaison avec d'autres modes.

```powershell
# Exemple d'utilisation du mode DEBUG

.\debug-mode.ps1 -RoadmapPath "Roadmap/roadmap.md" -Verbose

# Exemple d'utilisation du mode GRAN

.\gran-mode.ps1 -RoadmapPath "Roadmap/roadmap.md" -TaskId "1.2.3"
```plaintext
## DÃ©veloppement de nouveaux modes

Pour dÃ©velopper un nouveau mode, utilisez Hygen pour gÃ©nÃ©rer la structure de base :

```bash
hygen roadmap-parser new mode
```plaintext
Suivez ensuite les conventions de nommage et de structure pour assurer la cohÃ©rence avec les autres modes.
