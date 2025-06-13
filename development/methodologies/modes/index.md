# Modes Opérationnels

Ce document présente les différents modes opérationnels utilisés dans le projet.

## Présentation

Les modes opérationnels sont des approches spécifiques pour résoudre différents types de problèmes ou accomplir différentes tâches dans le projet. Chaque mode a un objectif spécifique et des fonctionnalités adaptées à cet objectif.

## Liste des modes

| Mode | Description | Objectif principal |
|------|-------------|-------------------|
| [ARCHI](mode_archi.md) | Architecture | Concevoir et valider l'architecture du système |
| [CHECK](mode_check_enhanced.md) | Vérification | Vérifier l'état d'avancement des tâches |
| [C-BREAK](mode_c-break.md) | Cycle Breaker | Détecter et résoudre les dépendances circulaires |
| [DEBUG](mode_debug.md) | Débogage | Identifier et résoudre les problèmes |
| [DEV-R](mode_dev_r.md) | Développement Roadmap | Implémenter les tâches de la roadmap |
| [GRAN](mode_gran.md) | Granularisation | Décomposer les tâches complexes |
| [MANAGER](mode_manager.md) | Gestionnaire de modes | Gérer et orchestrer les différents modes |
| [OPTI](mode_opti.md) | Optimisation | Améliorer les performances et la qualité du code |
| [PREDIC](mode_predic.md) | Prédiction | Anticiper les performances et détecter les anomalies |
| [REVIEW](mode_review.md) | Revue | Évaluer et améliorer la qualité du code |
| [TEST](mode_test.md) | Test | Créer et exécuter des tests |

## Utilisation des modes

Chaque mode peut être utilisé indépendamment ou en combinaison avec d'autres modes. Par exemple, vous pouvez utiliser le mode GRAN pour décomposer une tâche complexe, puis le mode DEV-R pour implémenter les sous-tâches, et enfin le mode CHECK pour vérifier que tout est bien implémenté.

## Implémentation

Chaque mode est implémenté sous forme de script PowerShell. Les scripts se trouvent dans différents répertoires selon le mode :

- Mode MANAGER : `development/scripts/mode-manager/mode-manager.ps1`
- Mode CHECK : `development/tools/scripts/check.ps1`
- Mode GRAN : `development/tools/scripts/gran-mode.ps1`
- Mode DEV-R : `development/tools/scripts/dev-r-mode.ps1`
- Autres modes : `development/tools/scripts/<mode>-mode.ps1`

Le mode MANAGER permet d'accéder à tous les modes de manière cohérente, sans avoir à connaître l'emplacement exact de chaque script.

## Bonnes pratiques

- Utiliser le mode approprié pour chaque tâche
- Combiner les modes pour résoudre des problèmes complexes
- Documenter les résultats de chaque mode
- Automatiser l'utilisation des modes dans les pipelines CI/CD
- Maintenir les scripts de mode à jour

## Intégration avec la roadmap

Les modes opérationnels sont étroitement intégrés avec la roadmap du projet. Ils permettent de :
- Décomposer les tâches ([GRAN](mode_gran.md))
- Implémenter les tâches ([DEV-R](mode_dev_r.md))
- Tester les implémentations ([TEST](mode_test.md))
- Vérifier l'état d'avancement ([CHECK](mode_check_enhanced.md))
- Optimiser le code ([OPTI](mode_opti.md))
- Résoudre les problèmes ([DEBUG](mode_debug.md))
- Détecter et résoudre les cycles ([C-BREAK](mode_c-break.md))
- Évaluer la qualité ([REVIEW](mode_review.md))
- Prédire les anomalies ([PREDIC](mode_predic.md))

## Principes fondamentaux

- [16 bases de programmation](../programmation_16_bases.md) : Les 16 bases de programmation du projet
- [Principes SOLID](../solid_principles.md) : Les principes SOLID appliqués au projet
- [Principes DRY, KISS, YAGNI](../dry_kiss_yagni.md) : Les principes DRY, KISS et YAGNI appliqués au projet

## Processus de développement

- [Gestion de projet](../project_management.md) : Méthodologie de gestion de projet
- [Cycle de vie du développement](../development_lifecycle.md) : Cycle de vie du développement logiciel
- [Revue de code](../code_review.md) : Processus de revue de code
- [Tests et qualité](../testing_quality.md) : Stratégie de tests et qualité du code

## Exemple d'utilisation

### Utilisation des modes individuels

```powershell
# Décomposer une tâche complexe

dev\tools\scripts\gran-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3"

# Implémenter les sous-tâches

dev\tools\scripts\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.1"
dev\tools\scripts\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.2"
dev\tools\scripts\dev-r-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3.3"

# Vérifier l'état d'avancement

dev\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3"
```plaintext
### Utilisation du mode MANAGER

Le mode MANAGER permet de gérer et d'orchestrer les différents modes de manière cohérente.

```powershell
# Exécuter un mode spécifique

development\scripts\mode-manager\mode-manager.ps1 -Mode CHECK -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force

# Exécuter une chaîne de modes (workflow de développement complet)

development\scripts\mode-manager\mode-manager.ps1 -Chain "GRAN,DEV-R,TEST,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"

# Afficher la liste des modes disponibles

development\scripts\mode-manager\mode-manager.ps1 -ListModes
```plaintext
Pour plus d'informations sur le mode MANAGER, consultez la [documentation du mode MANAGER](mode_manager.md).

## Annexes et documentation technique

Pour approfondir les bases, la taxonomie des exceptions et la gestion avancée des erreurs, consultez :

- [Les 16 bases de la programmation](../programmation_16_bases.md) : Document de référence supérieur sur les principes fondamentaux du projet.
- [Structure de la taxonomie des exceptions PowerShell](../exception_taxonomy_structure.md)
- [Propriétés communes de System.Exception](../exception_properties_documentation.md)
- [Exceptions du namespace System](../system_exceptions_documentation.md)
- [Exceptions du namespace System.IO](../system_io_exceptions_documentation.md)

Ces documents sont essentiels pour comprendre la robustesse, la traçabilité et la cohérence des modes opérationnels, notamment DEBUG, CHECK, TEST, OPTI et REVIEW.


