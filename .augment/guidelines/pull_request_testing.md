# Tests avec des pull requests réelles

Ce document définit les bonnes pratiques et les procédures pour tester efficacement les pull requests dans le projet.

## Préparation de l'environnement de test

### Configuration du dépôt de test
- Créer un dépôt Git isolé (`PR-Analysis-TestRepo`) pour les tests
- Configurer le dépôt avec la même structure que le dépôt principal
- Mettre en place des branches de test (develop, feature, hotfix)
- Configurer les hooks Git nécessaires pour l'analyse

### Configuration de GitHub Actions
- Mettre en place une instance GitHub Actions locale pour les tests
- Configurer les workflows d'analyse de code
- Définir les matrices de test pour différentes versions de PowerShell
- Configurer les notifications et rapports

### Préparation des scripts de référence
- Créer des scripts PowerShell avec des erreurs connues
- Documenter les types d'erreurs injectées
- Préparer des scripts de différentes tailles et complexités
- Inclure des cas limites et des scénarios complexes

### Configuration des webhooks
- Configurer les webhooks nécessaires pour l'intégration
- Mettre en place un serveur local pour recevoir les événements
- Configurer les filtres d'événements
- Tester la connectivité et la réception des événements

## Génération automatique de pull requests

### Script New-TestPullRequest-Fixed.ps1
- Utiliser le script pour générer des PRs de test
- Configurer les paramètres de complexité et volume
- Définir les types de modifications à inclure
- Spécifier les branches source et cible
- Utiliser la version corrigée qui évite les problèmes de syntaxe

### Modèles d'erreurs à injecter
- Erreurs de syntaxe PowerShell
- Problèmes de style (PSScriptAnalyzer)
- Violations des bonnes pratiques
- Problèmes de performance
- Erreurs de sécurité
- Problèmes de compatibilité

### Mécanisme de randomisation
- Générer des modifications aléatoires mais réalistes
- Varier le nombre et l'emplacement des erreurs
- Randomiser les types d'erreurs injectées
- Maintenir la traçabilité des erreurs injectées

### Paramètres de contrôle
- Nombre de fichiers à modifier
- Taille des modifications
- Complexité des modifications
- Distribution des types d'erreurs
- Ratio de code correct/incorrect

## Types de modifications à tester

### Ajouts de nouveaux fichiers
- Tester avec différents types de scripts PowerShell
- Inclure des modules, fonctions et scripts
- Tester avec différentes structures de code
- Vérifier la détection des problèmes dans les nouveaux fichiers

### Modifications de fichiers existants
- Modifier des fonctions existantes
- Ajouter de nouvelles fonctionnalités
- Corriger des bugs simulés
- Refactoriser du code existant

### Suppressions de fichiers ou fonctions
- Supprimer des fichiers complets
- Retirer des fonctions spécifiques
- Éliminer des sections de code
- Tester la détection des dépendances brisées

### Modifications mixtes
- Combiner ajouts, modifications et suppressions
- Simuler des refactorisations complexes
- Tester des changements d'architecture
- Vérifier la cohérence de l'analyse

### Tests avec fichiers volumineux
- Tester avec des fichiers de plus de 1000 lignes
- Vérifier les performances de l'analyse
- Tester la précision sur de grands fichiers
- Évaluer les limites du système

### Tests avec nombreux fichiers
- Tester avec des PRs contenant plus de 20 fichiers
- Évaluer les performances sur des PRs volumineuses
- Vérifier la cohérence de l'analyse
- Tester les limites de l'API GitHub

## Analyse des résultats

### Collecte de métriques
- Utiliser `Measure-PRAnalysisPerformance.ps1` pour collecter des données
- Mesurer les temps d'exécution pour chaque étape
- Évaluer la consommation de ressources
- Collecter des statistiques sur les erreurs détectées

### Mesure des temps d'exécution
- Temps total d'analyse
- Temps par fichier
- Temps par type d'analyse
- Comparaison avec les références

### Évaluation de la précision
- Calculer les taux de faux positifs
- Mesurer les taux de faux négatifs
- Évaluer la précision globale
- Comparer avec les erreurs connues injectées

### Identification des goulots d'étranglement
- Analyser les étapes les plus lentes
- Identifier les opportunités d'optimisation
- Évaluer les possibilités de parallélisation
- Mesurer l'impact des caches

### Génération de rapports
- Créer des rapports détaillés des performances
- Générer des visualisations des résultats
- Documenter les problèmes identifiés
- Proposer des améliorations basées sur les données

## Bonnes pratiques

### Isolation des tests
- Toujours utiliser un environnement isolé pour les tests
- Éviter d'interférer avec le dépôt principal
- Nettoyer l'environnement entre les tests
- Documenter les conditions de test

### Correction des erreurs de script
- Utiliser des expressions régulières correctement formatées
- Éviter d'utiliser des variables automatiques PowerShell ($error, $matches)
- Utiliser des verbes approuvés pour les fonctions PowerShell
- Tester les scripts avant de les intégrer dans le pipeline

### Reproductibilité
- Assurer que les tests sont reproductibles
- Utiliser des seeds pour la randomisation
- Documenter les paramètres utilisés
- Conserver les logs et résultats

### Automatisation
- Automatiser l'ensemble du processus de test
- Créer des scripts pour exécuter des batteries de tests
- Planifier des exécutions régulières
- Intégrer dans le pipeline CI/CD

### Documentation
- Documenter tous les scénarios de test
- Maintenir un catalogue des erreurs injectées
- Documenter les résultats attendus
- Mettre à jour la documentation après chaque amélioration
