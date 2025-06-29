# Documentation du Manager de Dépendances (dependency-manager)

Ce document fournit une documentation générale sur le manager de dépendances, sa structure, ses fonctionnalités et comment l'utiliser.

## Table des matières

- [Introduction](#introduction)
- [Architecture](#architecture)
- [Fonctionnalités](#fonctionnalités)
- [Utilisation](#utilisation)
- [Intégrations](#intégrations)
- [Tests](#tests)
- [CI/CD](#ci/cd)
- [Contribution](#contribution)

## Introduction

Le manager de dépendances est un composant clé de l'écosystème, responsable de la gestion des dépendances logicielles d'un projet. Il assure la détection, l'analyse, la résolution des conflits, la gestion des vulnérabilités, et la préparation des dépendances pour la conteneurisation et le déploiement.

## Architecture

Le manager de dépendances est structuré en plusieurs modules Go, chacun ayant une responsabilité spécifique :

- **`dependencymanager`** : Le cœur du manager, gère les opérations de base (ajout, suppression, mise à jour, audit des dépendances Go).
- **`interfaces`** : Définit toutes les interfaces et les types partagés (contrats) entre les différents managers et modules d'intégration.
- **`modules/security`** : Gère l'intégration avec le Security Manager pour l'analyse des vulnérabilités.
- **`modules/monitoring`** : Gère l'intégration avec le Monitoring Manager pour la surveillance des opérations.
- **`modules/storage`** : Gère l'intégration avec le Storage Manager pour la persistance des métadonnées.
- **`modules/container`** : Gère l'intégration avec le Container Manager pour la validation et l'optimisation de la conteneurisation.
- **`modules/deployment`** : Gère l'intégration avec le Deployment Manager pour la vérification de la compatibilité et la génération des artefacts de déploiement.
- **`modules/importmanager`** : Gère les opérations liées aux imports Go (validation, correction, rapports).
- **`modules/realmanager`** : Fournit des connecteurs pour les implémentations réelles des managers externes.
- **`tests`** : Contient tous les tests unitaires et d'intégration, incluant les mocks centralisés (`mocks_common_test.go`).

## Fonctionnalités

- Analyse et résolution des dépendances.
- Détection des conflits de versions.
- Analyse des vulnérabilités (via Security Manager).
- Surveillance des performances des opérations (via Monitoring Manager).
- Persistance des métadonnées des dépendances (via Storage Manager).
- Validation et optimisation pour la conteneurisation (via Container Manager).
- Vérification de la préparation au déploiement (via Deployment Manager).

## Utilisation

Le manager de dépendances peut être utilisé via son interface CLI (exécutable `dependency-manager.exe` ou `go run path/to/main.go`).

Exemples de commandes (simulées) :

```bash
go run cmd/roadmap-runner/main.go # Lance l'orchestrateur global
go run cmd/roadmap-runner/scan_inventory.go # Exécute l'inventaire
go run cmd/roadmap-runner/analyze_gaps.go # Exécute l'analyse d'écart
```

## Intégrations

Le manager est conçu pour s'intégrer avec d'autres managers de l'écosystème via des interfaces bien définies. Cette approche facilite l'extension et le remplacement des composants (y compris la migration vers des agents IA).

## Tests

Les tests sont situés dans le répertoire `tests/`. Ils couvrent les aspects unitaires et d'intégration.

Pour lancer les tests :
```bash
go test ./development/managers/dependency-manager/...
```

Pour générer le rapport de couverture :
```bash
go test ./development/managers/dependency-manager/... -coverprofile=development/managers/dependency-manager/coverage.out
go tool cover -html=development/managers/dependency-manager/coverage.out -o development/managers/dependency-manager/coverage.html
```

## CI/CD

Les procédures CI/CD sont définies pour automatiser le build, les tests, les analyses et les rapports. Référez-vous à `docs/ci_cd.md` pour plus de détails.

## Contribution

Pour contribuer au manager de dépendances, veuillez consulter le guide de contribution (à venir).
