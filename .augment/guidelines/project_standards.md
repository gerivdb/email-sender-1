# Standards de code globaux

Ce document définit les standards et bonnes pratiques générales pour tout le code du projet.

## Principes fondamentaux

### SOLID
- **S**ingle Responsibility Principle : Une classe ne doit avoir qu'une seule raison de changer
- **O**pen/Closed Principle : Les entités doivent être ouvertes à l'extension mais fermées à la modification
- **L**iskov Substitution Principle : Les objets d'une classe dérivée doivent pouvoir remplacer les objets de la classe de base
- **I**nterface Segregation Principle : Plusieurs interfaces spécifiques valent mieux qu'une interface générale
- **D**ependency Inversion Principle : Dépendre des abstractions, pas des implémentations

### Autres principes
- **DRY** (Don't Repeat Yourself) : Éviter la duplication de code
- **KISS** (Keep It Simple, Stupid) : Privilégier les solutions simples
- **YAGNI** (You Aren't Gonna Need It) : N'implémenter que ce qui est nécessaire

## Conventions de nommage

### Général
- Noms descriptifs et significatifs
- Éviter les abréviations sauf si elles sont standard
- Utiliser l'anglais pour le code et les commentaires techniques

### Par langage
- **PowerShell** : 
  - Verbes-Noms pour les fonctions (ex: `Get-User`)
  - PascalCase pour les variables publiques
  - camelCase pour les variables locales
- **Python** : 
  - snake_case pour les fonctions et variables
  - PascalCase pour les classes
  - MAJUSCULES pour les constantes
- **JavaScript** : 
  - camelCase pour les variables et fonctions
  - PascalCase pour les classes et composants React

## Structure des fichiers

- Limiter la taille des fichiers (max 500 lignes recommandé)
- Un fichier = une responsabilité
- Organiser les fichiers par fonctionnalité plutôt que par type
- Maintenir une hiérarchie cohérente des dossiers

## Gestion des erreurs

- Utiliser des exceptions/erreurs spécifiques
- Gérer les erreurs au niveau approprié
- Logger les erreurs avec suffisamment de contexte
- Fournir des messages d'erreur clairs et utiles

## Documentation

- Documenter l'intention et le "pourquoi", pas seulement le "comment"
- Maintenir des README à jour pour chaque module
- Utiliser des commentaires de documentation (docstrings) pour les fonctions/méthodes
- Documenter les décisions d'architecture importantes (ADRs)

## Tests

- Écrire des tests unitaires pour toute nouvelle fonctionnalité
- Maintenir une couverture de code d'au moins 80%
- Implémenter des tests d'intégration pour les flux critiques
- Exécuter les tests avant chaque commit

## Revue de code

- Toutes les modifications doivent être revues par au moins un autre développeur
- Utiliser des listes de contrôle pour les revues de code
- Automatiser les vérifications de style et de qualité
- Donner des retours constructifs et spécifiques

## Sécurité

- Ne jamais stocker de secrets dans le code source
- Valider toutes les entrées utilisateur
- Suivre le principe du moindre privilège
- Maintenir les dépendances à jour pour éviter les vulnérabilités

## Performance

- Optimiser les parties critiques du code
- Mesurer avant d'optimiser
- Utiliser des techniques de mise en cache appropriées
- Éviter les opérations bloquantes dans les threads principaux
