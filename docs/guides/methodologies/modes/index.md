# Modes Opérationnels

Ce document présente les différents modes opérationnels utilisés dans le projet.

## Présentation

Les modes opérationnels sont des approches spécifiques pour résoudre différents types de problèmes ou accomplir différentes tâches dans le projet. Chaque mode a un objectif spécifique et des fonctionnalités adaptées à cet objectif.

## Liste des modes

| Mode | Description | Objectif principal |
|------|-------------|-------------------|
| [ARCHI](mode_archi.md) | Architecture | Concevoir et valider l'architecture du système |
| [CHECK](mode_check.md) | Vérification | Vérifier l'état d'avancement des tâches |
| [C-BREAK](mode_c_break.md) | Cycle Breaker | Détecter et résoudre les dépendances circulaires |
| [DEBUG](mode_debug.md) | Débogage | Identifier et résoudre les problèmes |
| [DEV-R](mode_dev_r.md) | Développement Roadmap | Implémenter les tâches de la roadmap |
| [GRAN](mode_gran.md) | Granularisation | Décomposer les tâches complexes |
| [OPTI](mode_opti.md) | Optimisation | Améliorer les performances et la qualité du code |
| [PREDIC](mode_predic.md) | Prédiction | Anticiper les performances et détecter les anomalies |
| [REVIEW](mode_review.md) | Revue | Évaluer et améliorer la qualité du code |
| [TEST](mode_test.md) | Test | Créer et exécuter des tests |

## Utilisation des modes

Chaque mode peut être utilisé indépendamment ou en combinaison avec d'autres modes. Par exemple, vous pouvez utiliser le mode GRAN pour décomposer une tâche complexe, puis le mode DEV-R pour implémenter les sous-tâches, et enfin le mode CHECK pour vérifier que tout est bien implémenté.

## Implémentation

Chaque mode est implémenté sous forme de script PowerShell dans le dossier `tools/scripts/roadmap/modes`. Par exemple, le mode CHECK est implémenté dans le script `check-mode.ps1`.

## Bonnes pratiques

- Utiliser le mode approprié pour chaque tâche
- Combiner les modes pour résoudre des problèmes complexes
- Documenter les résultats de chaque mode
- Automatiser l'utilisation des modes dans les pipelines CI/CD
- Maintenir les scripts de mode à jour

## Intégration avec la roadmap

Les modes opérationnels sont étroitement intégrés avec la roadmap du projet. Ils permettent de :
- Décomposer les tâches (GRAN)
- Implémenter les tâches (DEV-R)
- Tester les implémentations (TEST)
- Vérifier l'état d'avancement (CHECK)
- Optimiser le code (OPTI)
- Résoudre les problèmes (DEBUG)

## Exemple d'utilisation

```powershell
# Décomposer une tâche complexe
.\gran-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"

# Implémenter les sous-tâches
.\dev-r-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3.1"
.\dev-r-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3.2"
.\dev-r-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3.3"

# Vérifier l'état d'avancement
.\check-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"
```
