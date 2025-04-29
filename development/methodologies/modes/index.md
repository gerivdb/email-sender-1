# Modes OpÃƒÂ©rationnels

Ce document prÃƒÂ©sente les diffÃƒÂ©rents modes opÃƒÂ©rationnels utilisÃƒÂ©s dans le projet.

## PrÃƒÂ©sentation

Les modes opÃƒÂ©rationnels sont des approches spÃƒÂ©cifiques pour rÃƒÂ©soudre diffÃƒÂ©rents types de problÃƒÂ¨mes ou accomplir diffÃƒÂ©rentes tÃƒÂ¢ches dans le projet. Chaque mode a un objectif spÃƒÂ©cifique et des fonctionnalitÃƒÂ©s adaptÃƒÂ©es ÃƒÂ  cet objectif.

## Liste des modes

| Mode | Description | Objectif principal |
|------|-------------|-------------------|
| [ARCHI](mode_archi.md) | Architecture | Concevoir et valider l'architecture du systÃƒÂ¨me |
| [CHECK](mode_check.md) | VÃƒÂ©rification | VÃƒÂ©rifier l'ÃƒÂ©tat d'avancement des tÃƒÂ¢ches |
| [C-BREAK](mode_c_break.md) | Cycle Breaker | DÃƒÂ©tecter et rÃƒÂ©soudre les dÃƒÂ©pendances circulaires |
| [DEBUG](mode_debug.md) | DÃƒÂ©bogage | Identifier et rÃƒÂ©soudre les problÃƒÂ¨mes |
| [DEV-R](mode_dev_r.md) | DÃƒÂ©veloppement Roadmap | ImplÃƒÂ©menter les tÃƒÂ¢ches de la roadmap |
| [GRAN](mode_gran.md) | Granularisation | DÃƒÂ©composer les tÃƒÂ¢ches complexes |
| [MANAGER](mode_manager.md) | Gestionnaire de modes | GÃƒÂ©rer et orchestrer les diffÃƒÂ©rents modes |
| [OPTI](mode_opti.md) | Optimisation | AmÃƒÂ©liorer les performances et la qualitÃƒÂ© du code |
| [PREDIC](mode_predic.md) | PrÃƒÂ©diction | Anticiper les performances et dÃƒÂ©tecter les anomalies |
| [REVIEW](mode_review.md) | Revue | Ãƒâ€°valuer et amÃƒÂ©liorer la qualitÃƒÂ© du code |
| [TEST](mode_test.md) | Test | CrÃƒÂ©er et exÃƒÂ©cuter des tests |

## Utilisation des modes

Chaque mode peut ÃƒÂªtre utilisÃƒÂ© indÃƒÂ©pendamment ou en combinaison avec d'autres modes. Par exemple, vous pouvez utiliser le mode GRAN pour dÃƒÂ©composer une tÃƒÂ¢che complexe, puis le mode DEV-R pour implÃƒÂ©menter les sous-tÃƒÂ¢ches, et enfin le mode CHECK pour vÃƒÂ©rifier que tout est bien implÃƒÂ©mentÃƒÂ©.

## ImplÃƒÂ©mentation

Chaque mode est implÃƒÂ©mentÃƒÂ© sous forme de script PowerShell. Les scripts se trouvent dans diffÃƒÂ©rents rÃƒÂ©pertoires selon le mode :

- Mode MANAGER : `development/scripts/mode-manager/mode-manager.ps1`
- Mode CHECK : `development/scripts/maintenance/modes/check.ps1`
- Mode GRAN : `development/roadmap/parser/modes/gran/gran-mode.ps1`
- Mode DEV-R : `development/roadmap/parser/modes/dev-r/dev-r-mode.ps1`
- Autres modes : `development/scripts/maintenance/modes/<mode>-mode.ps1`

Le mode MANAGER permet d'accÃƒÂ©der Ãƒ  tous les modes de maniÃƒÂ¨re cohÃƒÂ©rente, sans avoir Ãƒ  connaÃƒÂ®tre l'emplacement exact de chaque script.

## Bonnes pratiques

- Utiliser le mode appropriÃƒÂ© pour chaque tÃƒÂ¢che
- Combiner les modes pour rÃƒÂ©soudre des problÃƒÂ¨mes complexes
- Documenter les rÃƒÂ©sultats de chaque mode
- Automatiser l'utilisation des modes dans les pipelines CI/CD
- Maintenir les scripts de mode ÃƒÂ  jour

## IntÃƒÂ©gration avec la roadmap

Les modes opÃƒÂ©rationnels sont ÃƒÂ©troitement intÃƒÂ©grÃƒÂ©s avec la roadmap du projet. Ils permettent de :
- DÃƒÂ©composer les tÃƒÂ¢ches (GRAN)
- ImplÃƒÂ©menter les tÃƒÂ¢ches (DEV-R)
- Tester les implÃƒÂ©mentations (TEST)
- VÃƒÂ©rifier l'ÃƒÂ©tat d'avancement (CHECK)
- Optimiser le code (OPTI)
- RÃƒÂ©soudre les problÃƒÂ¨mes (DEBUG)

## Exemple d'utilisation

### Utilisation des modes individuels

```powershell
# DÃƒÂ©composer une tÃƒÂ¢che complexe
.\gran-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3"

# ImplÃƒÂ©menter les sous-tÃƒÂ¢ches
.\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.1"
.\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.2"
.\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.3"

# VÃƒÂ©rifier l'ÃƒÂ©tat d'avancement
.\check-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3"
```

### Utilisation du mode MANAGER

Le mode MANAGER permet de gÃƒÂ©rer et d'orchestrer les diffÃƒÂ©rents modes de maniÃƒÂ¨re cohÃƒÂ©rente.

```powershell
# ExÃƒÂ©cuter un mode spÃƒÂ©cifique
.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode CHECK -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force

# ExÃƒÂ©cuter une chaÃƒÂ®ne de modes (workflow de dÃƒÂ©veloppement complet)
.\development\\scripts\\mode-manager\mode-manager.ps1 -Chain "GRAN,DEV-R,TEST,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"

# Afficher la liste des modes disponibles
.\development\\scripts\\mode-manager\mode-manager.ps1 -ListModes
```

Pour plus d'informations sur le mode MANAGER, consultez la [documentation du mode MANAGER](mode_manager.md).


