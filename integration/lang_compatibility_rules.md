# Règles de Compatibilité Multi-langages et Multi-dossiers

## 1. Introduction
Ce document spécifie les règles de compatibilité pour les différents langages et structures de dossiers au sein du projet. L'objectif est d'assurer la cohérence, la maintenabilité et l'interopérabilité entre les composants développés dans des langages variés (Go, Python, Node.js, PowerShell).

## 2. Conventions Générales

### 2.1. Encodage des Fichiers
- Tous les fichiers de code et de documentation doivent être encodés en **UTF-8 (avec BOM pour PowerShell)**.

### 2.2. Conventions de Nommage
- **Go:** `PascalCase` pour les types et les fonctions exportées, `camelCase` pour les variables et fonctions non exportées.
- **Python:** `snake_case` pour les fonctions et variables, `PascalCase` pour les classes.
- **JavaScript/TypeScript:** `camelCase` pour les variables et fonctions, `PascalCase` pour les classes/interfaces.
- **PowerShell:** `PascalCase` pour les fonctions (`Verbe-Nom`), `camelCase` pour les variables.
- **Fichiers de script (génériques):** `kebab-case` (ex: `my-script.ps1`, `build-project.sh`).

### 2.3. Gestion des Dépendances
- Les dépendances doivent être explicitement déclarées (ex: `go.mod`, `requirements.txt`, `package.json`).
- Utiliser des versions figées ou des plages de versions claires pour éviter les problèmes de compatibilité.
- Les dépendances circulaires entre modules de langages différents sont **strictement interdites**.

## 3. Règles Spécifiques par Langage

### 3.1. Go (Module: `github.com/gerivdb/email-sender-1`)
- **Version Go:** `go1.24.4` (ou la dernière version stable supportée par la CI/CD).
- **Structure des modules:** Chaque module Go doit être autonome avec son propre `go.mod` si c'est une librairie réutilisable, sinon, faire partie du module racine.
- **Tests:** Couverture de test minimale de 80% pour les fonctions métier.
- **Linting:** `golangci-lint` doit passer sans avertissement.

### 3.2. Python
- **Version Python:** `Python 3.11` (ou la dernière version stable supportée par la CI/CD).
- **Gestionnaire de paquets:** `pip` avec `requirements.txt` pour les dépendances.
- **Environnements virtuels:** L'utilisation d'environnements virtuels (`venv`) est fortement recommandée.
- **Linting:** `flake8` ou `pylint` doit passer sans avertissement.

### 3.3. Node.js / TypeScript
- **Version Node.js:** `Node.js 18.x LTS` (ou la dernière version stable supportée par la CI/CD).
- **Gestionnaire de paquets:** `npm` ou `yarn`.
- **Linting:** `ESLint` et `Prettier` configurés pour le projet.

### 3.4. PowerShell
- **Version PowerShell:** `PowerShell 7` (ou la dernière version stable supportée par la CI/CD).
- **Encodage:** Fichiers `.ps1` doivent être encodés en **UTF-8 avec BOM**.
- **Modules:** Les fonctions réutilisables doivent être organisées en modules PowerShell.
- **Tests:** Utilisation de `Pester` pour les tests unitaires et d'intégration.

## 4. Règles d'Interopérabilité et de Communication

### 4.1. Appels entre Langages
- **Préférence:** Utiliser des API REST/gRPC pour les communications inter-processus et inter-langages.
- **Alternative (pour scripts/CLI):** Appels de sous-processus avec des interfaces bien définies (arguments CLI, sortie JSON/YAML).
- **Erreurs:** Les erreurs doivent être propagées de manière standardisée (codes de retour, messages d'erreur structurés).

### 4.2. Partage de Données
- Utiliser des formats de données standards comme JSON, YAML ou Protocol Buffers pour le partage de données complexes.
- Éviter le partage direct de structures de données en mémoire entre processus de langages différents.

## 5. Intégration CI/CD
- Le pipeline CI/CD doit inclure des étapes de vérification de compatibilité (versions, linting, tests) pour chaque langage.
- Les outils de scan de projet (`lang_scanner.go`) seront utilisés pour valider la structure et les types de projets.

## 6. Exceptions et Dérogations
Toute dérogation à ces règles doit être documentée, justifiée et approuvée par l'équipe d'architecture.
