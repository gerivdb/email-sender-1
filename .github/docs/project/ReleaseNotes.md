# Notes de version - Module UnifiedParallel

## Version 1.1.0 (2025-05-20)

### Nouvelles fonctionnalités

- **Gestion d'erreurs standardisée** : Nouvelle fonction `New-UnifiedError` pour créer des objets d'erreur standardisés avec des informations détaillées
- **Fonction de version** : Nouvelle fonction `Get-UnifiedParallelVersion` pour récupérer la version du module et des informations détaillées
- **Optimisation des performances** : Amélioration des performances de `Wait-ForCompletedRunspace` avec un algorithme adaptatif
- **Gestion améliorée des runspaces** : Nettoyage automatique des runspaces après timeout pour éviter les fuites de mémoire
- **Throttling adaptatif** : Ajustement dynamique du nombre de threads en fonction de la charge système

### Améliorations

- **Documentation complète** : Ajout de commentaires based help à toutes les fonctions avec exemples d'utilisation
- **Guide d'utilisation détaillé** : Nouveau guide d'utilisation avec exemples concrets et bonnes pratiques
- **Compatibilité PS 5.1/7.x** : Amélioration de la compatibilité entre PowerShell 5.1 et PowerShell 7.x
- **Encodage UTF-8** : Meilleure gestion de l'encodage UTF-8 avec BOM pour les fichiers et la console
- **Gestion des types** : Standardisation des types et conversions pour une meilleure robustesse

### Corrections

- **Problèmes de runspaces** : Correction des problèmes de runspaces non nettoyés après timeout
- **Gestion des types** : Correction des problèmes de conversion de types entre PowerShell 5.1 et 7.x
- **Dépassement de la profondeur des appels** : Résolution du problème de dépassement de la profondeur des appels dans les tests de performance
- **Fuites de mémoire** : Correction des fuites de mémoire dans la gestion des pools de runspaces
- **Gestion des exceptions** : Amélioration de la gestion des exceptions dans les runspaces

## Changements détaillés

### Gestion d'erreurs standardisée

La nouvelle fonction `New-UnifiedError` permet de créer des objets d'erreur standardisés avec des informations détaillées, facilitant le débogage et la gestion des erreurs dans tout le module. Elle offre les fonctionnalités suivantes :

- Création d'objets d'erreur avec des informations détaillées (message, source, catégorie, etc.)
- Options pour écrire l'erreur dans le flux d'erreur ou la lancer comme exception
- Capture de la pile d'appels pour faciliter le débogage
- Génération d'un ID de corrélation pour suivre les erreurs liées
- Ajout d'informations supplémentaires personnalisées

Toutes les fonctions du module ont été mises à jour pour utiliser cette nouvelle fonction, assurant une gestion cohérente des erreurs.

### Optimisation des performances

Les performances du module ont été améliorées grâce à plusieurs optimisations :

- Algorithme adaptatif pour `Wait-ForCompletedRunspace` qui ajuste dynamiquement le délai d'attente
- Utilisation optimisée des collections pour réduire l'empreinte mémoire
- Remplacement des boucles foreach par des boucles for indexées pour les grandes collections
- Optimisation de la détection et de la conversion des types
- Réduction des allocations mémoire inutiles

### Compatibilité PS 5.1/7.x

La compatibilité entre PowerShell 5.1 et PowerShell 7.x a été améliorée :

- Détection automatique de la version de PowerShell et adaptation du comportement
- Gestion cohérente de l'encodage UTF-8 avec BOM sur les deux versions
- Utilisation de méthodes alternatives pour les fonctionnalités non disponibles dans PowerShell 5.1
- Documentation des différences de comportement entre les versions

### Documentation complète

La documentation du module a été considérablement améliorée :

- Ajout de commentaires based help à toutes les fonctions
- Documentation complète des paramètres avec types et descriptions
- Exemples concrets d'utilisation pour chaque fonction
- Guide d'utilisation détaillé avec bonnes pratiques et pièges à éviter
- Notes de version détaillées

## Prochaines étapes

Pour les prochaines versions, nous prévoyons :

- Intégration avec les métriques de performance Windows
- Support des tâches asynchrones avec async/await
- Intégration avec les jobs PowerShell
- Interface graphique pour la surveillance des tâches parallèles
- Support des conteneurs et des environnements virtuels

## Compatibilité

Cette version est compatible avec :

- PowerShell 5.1 (Windows PowerShell)
- PowerShell 7.0 et versions ultérieures (PowerShell Core)
- Windows, Linux et macOS (avec PowerShell 7.x)

## Installation

Pour installer cette version, téléchargez le module et importez-le avec :

```powershell
Import-Module -Path "chemin\vers\UnifiedParallel.psm1"
```plaintext
Pour vérifier la version installée :

```powershell
Get-UnifiedParallelVersion
```plaintext
## Remerciements

Merci à tous les contributeurs qui ont participé à cette version, notamment pour les tests, les suggestions d'amélioration et les rapports de bugs.
