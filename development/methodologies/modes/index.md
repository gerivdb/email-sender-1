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
| [MANAGER](mode_manager.md) | Gestionnaire de modes | GÃ©rer et orchestrer les diffÃ©rents modes |
| [OPTI](mode_opti.md) | Optimisation | AmÃ©liorer les performances et la qualitÃ© du code |
| [PREDIC](mode_predic.md) | PrÃ©diction | Anticiper les performances et dÃ©tecter les anomalies |
| [REVIEW](mode_review.md) | Revue | Ã‰valuer et amÃ©liorer la qualitÃ© du code |
| [TEST](mode_test.md) | Test | CrÃ©er et exÃ©cuter des tests |

## Utilisation des modes

Chaque mode peut Ãªtre utilisÃ© indÃ©pendamment ou en combinaison avec d'autres modes. Par exemple, vous pouvez utiliser le mode GRAN pour dÃ©composer une tÃ¢che complexe, puis le mode DEV-R pour implÃ©menter les sous-tÃ¢ches, et enfin le mode CHECK pour vÃ©rifier que tout est bien implÃ©mentÃ©.

## ImplÃ©mentation

Chaque mode est implÃ©mentÃ© sous forme de script PowerShell. Les scripts se trouvent dans diffÃ©rents rÃ©pertoires selon le mode :

- Mode MANAGER : `development/scripts/manager/mode-manager.ps1`
- Mode CHECK : `development/scripts/maintenance/modes/check.ps1`
- Mode GRAN : `development/roadmap/parser/modes/gran/gran-mode.ps1`
- Mode DEV-R : `development/roadmap/parser/modes/dev-r/dev-r-mode.ps1`
- Autres modes : `development/scripts/maintenance/modes/<mode>-mode.ps1`

Le mode MANAGER permet d'accÃ©der Ã  tous les modes de maniÃ¨re cohÃ©rente, sans avoir Ã  connaÃ®tre l'emplacement exact de chaque script.

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

### Utilisation des modes individuels

```powershell
# DÃ©composer une tÃ¢che complexe
.\gran-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3"

# ImplÃ©menter les sous-tÃ¢ches
.\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.1"
.\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.2"
.\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.3"

# VÃ©rifier l'Ã©tat d'avancement
.\check-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3"
```

### Utilisation du mode MANAGER

Le mode MANAGER permet de gÃ©rer et d'orchestrer les diffÃ©rents modes de maniÃ¨re cohÃ©rente.

```powershell
# ExÃ©cuter un mode spÃ©cifique
.\development\scripts\manager\mode-manager.ps1 -Mode CHECK -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force

# ExÃ©cuter une chaÃ®ne de modes (workflow de dÃ©veloppement complet)
.\development\scripts\manager\mode-manager.ps1 -Chain "GRAN,DEV-R,TEST,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"

# Afficher la liste des modes disponibles
.\development\scripts\manager\mode-manager.ps1 -ListModes
```

Pour plus d'informations sur le mode MANAGER, consultez la [documentation du mode MANAGER](mode_manager.md).

