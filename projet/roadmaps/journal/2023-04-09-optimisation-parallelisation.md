# Journal de développement - 09/04/2023

## Optimisation de la parallélisation en PowerShell 5.1

### Contexte

Besoin d'améliorer les performances des scripts qui traitent de nombreux fichiers en parallèle, tout en restant compatible avec PowerShell 5.1.

### Actions réalisées

#### 1. Analyse des approches de parallélisation

- Comparaison des différentes méthodes de parallélisation disponibles en PowerShell 5.1
  - Jobs PowerShell traditionnels (Start-Job)
  - Runspace Pools
  - Approche par lots (batch processing)

#### 2. Implémentation d'une fonction optimisée

- Création de la fonction `Invoke-OptimizedParallel` utilisant des Runspace Pools
- Implémentation d'une version simplifiée compatible avec PowerShell 5.1
- Gestion robuste des erreurs et nettoyage des ressources

#### 3. Tests de performance

- Création d'un script de test `Test-ParallelPerformance.ps1`
- Comparaison des performances entre traitement séquentiel, Jobs PowerShell et Runspace Pools
- Résultats : Runspace Pools environ 10 fois plus rapides que les Jobs PowerShell

#### 4. Intégration au module de gestion des erreurs

- Ajout de la capacité à traiter les erreurs en parallèle
- Collecte des résultats et des erreurs dans un format standardisé

### Leçons apprises

1. **Limitations de PowerShell 5.1** : Certaines fonctionnalités comme `WaitHandle.WaitAny` et `UseDefaultThreadOptions` ne fonctionnent pas correctement dans PowerShell 5.1.

2. **Gestion des variables dans les Runspaces** : Les variables de préférence (`$VerbosePreference`, etc.) ne sont pas directement accessibles via `$using:` dans PowerShell 5.1.

3. **Performances** : Les Runspace Pools sont significativement plus performants que les Jobs PowerShell traditionnels car ils utilisent des threads dans le même processus au lieu de créer de nouveaux processus.

4. **Gestion des ressources** : Il est crucial de nettoyer correctement les ressources (Dispose des instances PowerShell et fermeture du RunspacePool) pour éviter les fuites de mémoire.

5. **Approche simplifiée** : Une implémentation plus simple et robuste est souvent préférable à une solution plus complexe avec des fonctionnalités avancées qui peuvent ne pas être compatibles.

### Améliorations futures

- Implémenter un mécanisme de limitation dynamique basé sur l'utilisation des ressources système
- Ajouter la possibilité de traiter les fichiers par lots pour réduire encore plus les frais généraux
- Créer des fonctions spécialisées pour des cas d'utilisation spécifiques (analyse de code, correction de code, etc.)
