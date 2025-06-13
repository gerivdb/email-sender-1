# Modes OpÃ©rationnels

Ce document prÃ©sente les diffÃ©rents modes opÃ©rationnels utilisÃ©s dans le projet.

## PrÃ©sentation

Les modes opÃ©rationnels sont des approches spÃ©cifiques pour rÃ©soudre diffÃ©rents types de problÃ¨mes ou accomplir diffÃ©rentes tÃ¢ches dans le projet. Chaque mode a un objectif spÃ©cifique et des fonctionnalitÃ©s adaptÃ©es Ã  cet objectif.

## Liste des modes

| Mode | Description | Objectif principal |
|------|-------------|-------------------|
| [ARCHI](mode_archi.md) | Architecture | Concevoir et valider l'architecture du systÃ¨me |
| [CHECK](mode_check.md) | VÃ©rification | VÃ©rifier l'Ã©tat d'avancement des tÃ¢ches |
| [C-BREAK](mode_c_break.md) | Cycle Breaker | DÃ©tecter et rÃ©soudre les dÃ©pendances circulaires |
| [DEBUG](mode_debug.md) | DÃ©bogage | Identifier et rÃ©soudre les problÃ¨mes |
| [DEV-R](mode_dev_r.md) | DÃ©veloppement Roadmap | ImplÃ©menter les tÃ¢ches de la roadmap |
| [GRAN](mode_gran.md) | Granularisation | DÃ©composer les tÃ¢ches complexes |
| [OPTI](mode_opti.md) | Optimisation | AmÃ©liorer les performances et la qualitÃ© du code |
| [PREDIC](mode_predic.md) | PrÃ©diction | Anticiper les performances et dÃ©tecter les anomalies |
| [REVIEW](mode_review.md) | Revue | Ã‰valuer et amÃ©liorer la qualitÃ© du code |
| [TEST](mode_test.md) | Test | CrÃ©er et exÃ©cuter des tests |

## Utilisation des modes

Chaque mode peut Ãªtre utilisÃ© indÃ©pendamment ou en combinaison avec d'autres modes. Par exemple, vous pouvez utiliser le mode GRAN pour dÃ©composer une tÃ¢che complexe, puis le mode DEV-R pour implÃ©menter les sous-tÃ¢ches, et enfin le mode CHECK pour vÃ©rifier que tout est bien implÃ©mentÃ©.

## ImplÃ©mentation

Chaque mode est implÃ©mentÃ© sous forme de script PowerShell dans le dossier `tools/scripts/roadmap/modes`. Par exemple, le mode CHECK est implÃ©mentÃ© dans le script `check-mode.ps1`.

## Bonnes pratiques

- Utiliser le mode appropriÃ© pour chaque tÃ¢che
- Combiner les modes pour rÃ©soudre des problÃ¨mes complexes
- Documenter les rÃ©sultats de chaque mode
- Automatiser l'utilisation des modes dans les pipelines CI/CD
- Maintenir les scripts de mode Ã  jour

## IntÃ©gration avec la roadmap

Les modes opÃ©rationnels sont Ã©troitement intÃ©grÃ©s avec la roadmap du projet. Ils permettent de :
- DÃ©composer les tÃ¢ches (GRAN)
- ImplÃ©menter les tÃ¢ches (DEV-R)
- Tester les implÃ©mentations (TEST)
- VÃ©rifier l'Ã©tat d'avancement (CHECK)
- Optimiser le code (OPTI)
- RÃ©soudre les problÃ¨mes (DEBUG)

## Exemple d'utilisation

```powershell
# DÃ©composer une tÃ¢che complexe

.\gran-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"

# ImplÃ©menter les sous-tÃ¢ches

.\dev-r-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3.1"
.\dev-r-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3.2"
.\dev-r-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3.3"

# VÃ©rifier l'Ã©tat d'avancement

.\check-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"
```plaintext