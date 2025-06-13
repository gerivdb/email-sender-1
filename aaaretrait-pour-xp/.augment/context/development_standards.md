# Standards de développement du projet EMAIL_SENDER_1

Ce document définit les standards de développement à respecter pour le projet EMAIL_SENDER_1, couvrant les aspects techniques, méthodologiques et organisationnels.

## 1. Standards techniques

### 1.1 Environnements de développement

#### 1.1.1 PowerShell

- **Version** : PowerShell 7+ (compatible avec PowerShell 5.1)
- **Style de code** :
  - Utilisation exclusive des verbs approuvés
  - Comparaison avec `$null` à gauche : `$null -eq $variable`
  - Utilisation de `ShouldProcess` avec `ShouldContinue`
  - Éviter d'assigner des valeurs aux variables automatiques
- **Modules recommandés** :
  - Pester pour les tests unitaires
  - PSScriptAnalyzer pour l'analyse statique
  - ImportExcel pour la manipulation de fichiers Excel
- **Performances** :
  - Utilisation de `ForEach-Object -Parallel` pour le traitement parallèle
  - Runspace Pools pour les opérations intensives

#### 1.1.2 Python

- **Version** : Python 3.11+
- **Structure** : Layout src avec packages
- **Style de code** :
  - Formatage avec Black
  - Tests avec pytest et pytest-cov
  - Analyse statique avec pylint
  - Typage statique avec typing
- **Frameworks** :
  - Flask avec pattern Factory pour les API
  - SQLAlchemy pour l'ORM
  - Pandas pour la manipulation de données
- **Performances** :
  - Utilisation de multiprocessing pour le traitement parallèle
  - asyncio pour les opérations I/O intensives

#### 1.1.3 TypeScript (pour n8n)

- **Version** : TypeScript 4.5+
- **Style de code** :
  - ESLint avec configuration n8n
  - Prettier pour le formatage
- **Tests** :
  - Jest pour les tests unitaires
  - Cypress pour les tests E2E

### 1.2 Encodage et taille des fichiers

- **Encodage** : UTF-8 avec BOM pour PowerShell, UTF-8 sans BOM pour les autres
- **Taille maximale** : 5KB par input (4KB recommandé)
- **Taille des fichiers** : Maximum 200 lignes par fichier
- **Taille des fonctions** : Maximum 50 lignes par fonction

### 1.3 Configuration et logging

- **Configuration** : Formats YAML ou JSON
- **Logging** : Formats Markdown, JSON, CSV
- **Stockage** : Fichiers locaux ou bases de données SQLite
- **Alertes** : Seuils configurables avec notifications

### 1.4 Gestion des erreurs

- **Correction d'erreurs** : 100% des erreurs doivent être corrigées
- **Encodage** : Résolution systématique des problèmes d'encodage
- **Try/Catch** : Utilisation systématique pour les opérations à risque
- **Logging** : Enregistrement détaillé des erreurs avec contexte

## 2. Principes de conception

### 2.1 SOLID

- **Single Responsibility** : Une classe/module ne doit avoir qu'une seule raison de changer
- **Open/Closed** : Ouvert à l'extension, fermé à la modification
- **Liskov Substitution** : Les sous-types doivent être substituables à leurs types de base
- **Interface Segregation** : Plusieurs interfaces spécifiques valent mieux qu'une interface générale
- **Dependency Inversion** : Dépendre des abstractions, pas des implémentations

### 2.2 Autres principes

- **DRY** (Don't Repeat Yourself) : Éviter la duplication de code
- **KISS** (Keep It Simple, Stupid) : Privilégier la simplicité
- **YAGNI** (You Aren't Gonna Need It) : Ne pas implémenter des fonctionnalités "au cas où"
- **Fail Fast** : Détecter et signaler les erreurs le plus tôt possible

## 3. Tests et qualité

### 3.1 Tests unitaires

- **Couverture** : Minimum 80% de couverture de code
- **Frameworks** :
  - PowerShell : Pester
  - Python : pytest
  - TypeScript : Jest
- **Approche** : TDD (Test-Driven Development) recommandée

### 3.2 Tests d'intégration

- **Frameworks** :
  - TestOmnibus pour les tests cross-platform
  - Postman/Newman pour les API
- **Environnements** : Tests sur environnements de développement et staging

### 3.3 Analyse de qualité

- **Outils** :
  - SonarQube pour l'analyse statique
  - Allure pour les rapports de tests
- **Métriques** :
  - Complexité cyclomatique < 10
  - Dette technique < 5%
  - Duplication < 3%

### 3.4 Détection des tests instables

- Identification des tests non déterministes
- Isolation et correction des tests flaky
- Monitoring des temps d'exécution

## 4. Documentation

### 4.1 Standards de documentation

- **Code** : Minimum 20% du code doit être documenté
- **API** : Documentation complète des endpoints et paramètres
- **Architecture** : Diagrammes et descriptions des composants
- **Workflows** : Documentation détaillée des workflows n8n

### 4.2 Formats et outils

- **Code** : Commentaires en format DocString/JSDoc
- **Architecture** : Diagrammes PlantUML ou Mermaid
- **Guides** : Markdown avec exemples de code
- **API** : OpenAPI/Swagger

## 5. Gestion de version et déploiement

### 5.1 Git

- **Branches** :
  - `main` : Code de production
  - `develop` : Développement en cours
  - `feature/*` : Nouvelles fonctionnalités
  - `bugfix/*` : Corrections de bugs
- **Commits** :
  - Format : `type(scope): description`
  - Types : feat, fix, docs, style, refactor, test, chore
- **Pull Requests** :
  - Revue de code obligatoire
  - Tests automatisés validés
  - Pas de dette technique ajoutée

### 5.2 CI/CD

- **Pre-commit hooks** : Vérification de style et tests unitaires
- **GitHub Actions** : Tests, build et déploiement automatisés
- **Environnements** :
  - Développement : Local
  - Test : Serveur de test
  - Production : Serveur de production

## 6. Méthodologie de développement

### 6.1 Modes opérationnels

- **GRAN** : Décomposition des tâches complexes
- **DEV-R** : Implémentation des tâches roadmap
- **ARCHI** : Conception et modélisation
- **DEBUG** : Résolution de bugs
- **TEST** : Tests automatisés
- **OPTI** : Optimisation des performances
- **REVIEW** : Vérification de qualité
- **PREDIC** : Analyse prédictive
- **C-BREAK** : Résolution de dépendances circulaires

### 6.2 Cycle par tâche

1. **Analyze** : Décomposition et estimation
2. **Learn** : Recherche de patterns existants
3. **Explore** : Prototypage de solutions (ToT)
4. **Reason** : Boucle ReAct (analyser→exécuter→ajuster)
5. **Code** : Implémentation fonctionnelle (≤ 5KB)
6. **Progress** : Avancement séquentiel sans confirmation
7. **Adapt** : Ajustement de la granularité selon complexité
8. **Segment** : Division des tâches complexes

### 6.3 Gestion des inputs volumineux

- Segmentation automatique si > 5KB
- Compression (suppression commentaires/espaces)
- Implémentation incrémentale fonction par fonction

## 7. Outils et stack

### 7.1 Outils principaux

- **n8n** : Plateforme d'automatisation (localhost:5678)
- **crewAI** : Framework pour agents IA collaboratifs
- **Notion** : Gestion des connaissances et collaboration
- **MCP** : Serveurs de contexte pour modèles IA
- **Hygen** : Génération de code à partir de templates
- **pre-commit** : Hooks pour validation avant commit

### 7.2 Environnement VS Code

- **Mémoire** : 4096MB
- **Lignes de défilement** : 10k
- **GPU** : Activé
- **Encodage** : UTF-8 (fr)

### 7.3 Services IA

- **OpenRouter** : Routage vers différents modèles IA
- **Qwen** : Modèle principal (qwen/qwen3-235b-a22b)

## 8. Règle d'or

> **Granularité adaptative, tests systématiques, documentation claire**.
> Pour toute question, utiliser le mode approprié et progresser par étapes incrémentielles.
