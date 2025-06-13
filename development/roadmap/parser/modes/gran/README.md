# Mode GRAN

Cette section contient les scripts liés au mode GRAN (Granularisation) qui permet de décomposer les tâches complexes en sous-tâches plus petites et plus faciles à gérer.

## Emplacement actuel

Le script principal du mode GRAN a été déplacé vers development\scripts\maintenance\modes\gran-mode.ps1 pour une meilleure organisation et cohérence du dépôt.

## Utilisation

`powershell
# Utiliser le script directement

.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath  projet\roadmaps\roadmap_complete_converted.md -TaskIdentifier 1.2.3

# Utiliser le mode-manager

.\development\scripts\mode-manager\mode-manager.ps1 -Mode GRAN -FilePath projet\roadmaps\roadmap_complete_converted.md -TaskIdentifier 1.2.3
`

## Documentation

La documentation complète du mode GRAN est disponible dans projet\guides\methodologies\modes\mode_gran.md.

## Dépendances

Ce mode dépend des modules suivants :
- Module RoadmapParser - Pour l'analyse et la modification des fichiers de roadmap
- Fonction Invoke-RoadmapGranularization - Pour la décomposition des tâches
- Fonction Split-RoadmapTask - Pour la création des sous-tâches

## Tests

Les tests unitaires pour ce mode se trouvent dans le dossier development\roadmap\parser\module\Tests\Test-InvokeRoadmapGranularization.ps1.
