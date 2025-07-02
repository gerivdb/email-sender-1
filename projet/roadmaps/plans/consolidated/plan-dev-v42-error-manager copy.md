# Plan de développement v42 - Gestionnaire d'erreurs avancé

*Version 1.0 - 2025-06-04 - Progression globale : 43%*Plan de développement v42 - Gestionnaire d’erreurs avancé
*Version 1.0 - 2025-06-03 - Progression globale : 0%*

Ce plan de développement détaille l’implémentation d’un gestionnaire d’erreurs avancé en Go natif pour le projet EMAIL SENDER 1, avec journalisation, catalogage, analyse algorithmique des patterns d’erreurs, et persistance via une base SQL (PostgreSQL) et Qdrant, toutes deux conteneurisées avec Docker. L’objectif est d’améliorer la robustesse du dépôt en prévenant la récurrence des erreurs grâce à une mémoire persistante et une intégration avec les gestionnaires existants (dépendances, MCP, n8n, processus, roadmap, scripts, paths, conteneurs, réseau, etc.), notamment `development/managers/integrated-manager`. Le plan privilégie les outils Go natifs pour respecter DRY, KISS, et SOLID, tout en assurant une intégration fluide avec les autres gestionnaires.

## Table des matières

- [1] Phase 1 : Mise en place de la journalisation des erreurs
- [2] Phase 2 : Catalogage et structuration des erreurs
- [3] Phase 3 : Persistance des erreurs (PostgreSQL et Qdrant)
- [4] Phase 4 : Analyse algorithmique des patterns
- [5] Phase 5 : Intégration avec les gestionnaires existants
- [6] Phase 6 : Tests et validation
- [7] Phase 7 : Documentation et déploiement

## Phase 1 : Mise en place de la journalisation des erreurs

*Progression : 100%*

### 1.1 Configuration de la bibliothèque de journalisation

*Progression : 100%*

#### 1.1.1 Choix et intégration de Zap

*Progression : 100%*
- [x] Sélectionner `go.uber.org/zap` pour la journalisation structurée
  - [x] Étape 1.1 : Ajouter Zap comme dépendance dans `go.mod`
    - [x] Micro-étape 1.1.1 : Exécuter `go get go.uber.org/zap`
    - [x] Micro-étape 1.1.2 : Vérifier la version compatible (ex. v1.27.0)
  - [x] Étape 1.2 : Configurer un logger Zap en mode production
    - [x] Micro-étape 1.2.1 : Créer une configuration avec `zap.NewProduction()`
    - [x] Micro-étape 1.2.2 : Ajouter des champs par défaut (ex. `app_name="EMAIL_SENDER_1"`, `env`)
    - [x] Micro-étape 1.2.3 : Configurer la sortie JSON pour intégration avec outils d’analyse
  - [x] Étape 1.3 : Implémenter un wrapper pour les erreurs dans `development/managers/error-manager/logger.go`
    - [x] Micro-étape 1.3.1 : Créer une fonction `LogError(err error, module string, code string)`
    - [x] Micro-étape 1.3.2 : Inclure des métadonnées (timestamp, stack trace, module, `manager_context` si applicable)
    - [x] Micro-étape 1.3.3 : Tester la journalisation sur un cas d’erreur simulé
  - [x] Entrées : Dépôt Git, fichier `go.mod`
  - [x] Sorties : Module Go avec logger Zap configuré (`development/managers/error-manager/logger.go`)
  - [x] Scripts : `development/managers/error-manager/logger.go`
  - [x] Conditions préalables : Go 1.22+, dépôt Git initialisé

#### 1.1.2 Intégration avec pkg/errors

*Progression : 100%*
- [x] Ajouter `github.com/pkg/errors` pour enrichir les erreurs
  - [x] Étape 1.1 : Ajouter la dépendance dans `go.mod`
    - [x] Micro-étape 1.1.1 : Exécuter `go get github.com/pkg/errors`
    - [x] Micro-étape 1.1.2 : Vérifier la compatibilité avec Zap
  - [x] Étape 1.2 : Implémenter une fonction pour envelopper les erreurs dans `development/managers/error-manager/errors.go`
    - [x] Micro-étape 1.2.1 : Créer `WrapError(err error, message string)` avec stack trace
    - [x] Micro-étape 1.2.2 : Tester avec des erreurs simulées (ex. `errors.New("test error")`)
  - [x] Entrées : Code source Go existant
  - [x] Sorties : Erreurs enrichies avec contexte et stack traces
  - [x] Scripts : `development/managers/error-manager/errors.go`
  - [x] Conditions préalables : Go 1.22+, Zap configuré

## Phase 2 : Catalogage et structuration des erreurs

*Progression : 100%*

### 2.1 Définition du modèle d’erreur

*Progression : 100%*
- [x] Créer une structure Go pour cataloguer les erreurs
  - [x] Étape 2.1 : Définir la structure `ErrorEntry` dans `development/managers/error-manager/model.go`
    - [x] Micro-étape 2.1.1 : Inclure les champs `ID` (UUID), `Timestamp`, `Message`, `StackTrace`, `Module` (ex: `dependency-manager`, `gateway-manager`), `ErrorCode` (standardisé), `ManagerContext` (infos spécifiques au manager), `Severity` (INFO, WARNING, ERROR, CRITICAL)
    - [x] Micro-étape 2.1.2 : Ajouter des tags JSON pour sérialisation
    - [x] Micro-étape 2.1.3 : Valider la structure avec un exemple JSON
  - [x] Étape 2.2 : Implémenter une fonction de catalogage dans `development/managers/error-manager/catalog.go`
    - [x] Micro-étape 2.2.1 : Créer `CatalogError(entry ErrorEntry)` pour préparer l’erreur
    - [x] Micro-étape 2.2.2 : Tester avec des erreurs simulées provenant de différents managers
  - [x] Entrées : Erreurs journalisées via Zap
  - [x] Sorties : Structure `ErrorEntry` pour persistance
  - [x] Scripts : `development/managers/error-manager/model.go`, `development/managers/error-manager/catalog.go`
  - [x] Conditions préalables : Zap et `pkg/errors` configurés

### 2.2 Validation des erreurs cataloguées

*Progression : 100%*
- [x] Implémenter une validation des erreurs dans `development/managers/error-manager/validator.go`
  - [x] Étape 2.1 : Vérifier l’intégrité des champs `ErrorEntry`
    - [x] Micro-étape 2.1.1 : Valider que `Message`, `ErrorCode`, `Module`, `Severity` ne sont pas vides
    - [x] Micro-étape 2.1.2 : Vérifier la cohérence du `Timestamp`
    - [x] Micro-étape 2.1.3 : Tester avec des cas limites (ex. `Message` trop long, `ErrorCode` inconnu)
  - [x] Entrées : Instances `ErrorEntry`
  - [x] Sorties : Erreurs validées prêtes pour persistance
  - [x] Scripts : `development/managers/error-manager/validator.go`
  - [x] Conditions préalables : Modèle `ErrorEntry` défini

## Phase 3 : Persistance des erreurs (PostgreSQL et Qdrant)

*Progression : 100%*

### 3.1 Configuration de PostgreSQL

*Progression : 100%*
- [x] Mettre en place une base PostgreSQL via Docker (vérifier si déjà existante pour d'autres managers)
  - [x] Étape 3.1 : Créer/Utiliser un conteneur PostgreSQL
    - [x] Micro-étape 3.1.1 : Vérifier `docker-compose.yml` pour `postgres:15` existant. Si non, ajouter.
    - [x] Micro-étape 3.1.2 : Configurer/Vérifier les variables d’environnement (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`)
    - [x] Micro-étape 3.1.3 : Créer/Utiliser un volume pour la persistance des données (ex: `pg_data_errors`)
  - [x] Étape 3.2 : Implémenter le schéma SQL dans `development/managers/error-manager/storage/sql/schema_errors.sql`
    - [x] Micro-étape 3.2.1 : Créer la table `project_errors` (colonnes: `id UUID PRIMARY KEY`, `timestamp TIMESTAMPTZ NOT NULL`, `message TEXT NOT NULL`, `stack_trace TEXT`, `module VARCHAR(255) NOT NULL`, `error_code VARCHAR(100) NOT NULL`, `manager_context JSONB`, `severity VARCHAR(50) NOT NULL`)
    - [x] Micro-étape 3.2.2 : Tester l’insertion d’un enregistrement avec un script SQL (`test_insert.sql`)
  - [x] Étape 3.3 : Connecter Go à PostgreSQL dans `development/managers/error-manager/storage/postgres.go`
    - [x] Micro-étape 3.3.1 : Ajouter `github.com/lib/pq` dans `go.mod` (si non présent)
    - [x] Micro-étape 3.3.2 : Implémenter `PersistErrorToSQL(entry ErrorEntry)` avec `database/sql`
    - [x] Micro-étape 3.3.3 : Tester la connexion et l’insertion via un script Go
- [x] Entrées : Instances `ErrorEntry`, `docker-compose.yml`
  - [x] Sorties : Erreurs persistées en base PostgreSQL
  - [x] Scripts : `development/managers/error-manager/storage/postgres.go`, `development/managers/error-manager/storage/sql/schema_errors.sql`
  - [x] Conditions préalables : PostgreSQL conteneurisé, modèle `ErrorEntry` défini

### 3.2 Configuration de Qdrant

*Progression : 100%*
- [x] Mettre en place Qdrant pour la recherche vectorielle des erreurs
  - [x] Étape 3.1 : Intégrer Qdrant avec le gestionnaire d'erreurs
    - [x] Micro-étape 3.1.1 : Corriger l'utilisation de `qdrant.NewClient` avec une configuration appropriée
    - [x] Micro-étape 3.1.2 : Remplacer `UpsertPoints` par `Upsert` et utiliser `api.PointStruct`
    - [x] Micro-étape 3.1.3 : Ajouter le contexte requis pour les appels Qdrant
  - [x] Étape 3.2 : Implémenter le stockage vectoriel dans `development/managers/error-manager/storage/qdrant.go`
    - [x] Micro-étape 3.2.1 : Créer `StoreErrorVector(collection string, vector []float32, payload map[string]interface{})`
    - [x] Micro-étape 3.2.2 : Tester l'intégration avec des vecteurs d'erreurs simulés
  - [x] Entrées : Vecteurs d'erreurs, métadonnées
  - [x] Sorties : Erreurs indexées dans Qdrant pour recherche sémantique
  - [x] Scripts : `development/managers/error-manager/storage/qdrant.go`, `development/managers/error-manager/storage/qdrant_test.go`
  - [x] Conditions préalables : Client Qdrant configuré, vecteurs d'erreurs générés

## Phase 4 : Analyse algorithmique des patterns

*Progression : 0%*

### 4.1 Détection de patterns d'erreurs

*Progression : 0%*
- [ ] Implémenter l'analyse des patterns récurrents
  - [ ] Étape 4.1 : Créer un analyseur de patterns dans `development/managers/error-manager/analyzer.go`
    - [ ] Micro-étape 4.1.1 : Implémenter `AnalyzeErrorPatterns()` pour détecter les erreurs récurrentes
    - [ ] Micro-étape 4.1.2 : Créer des métriques de fréquence par module et code d'erreur
    - [ ] Micro-étape 4.1.3 : Identifier les corrélations temporelles entre erreurs
  - [ ] Étape 4.2 : Générer des rapports d'analyse
    - [ ] Micro-étape 4.2.1 : Créer `GeneratePatternReport()` pour résumer les patterns détectés
    - [ ] Micro-étape 4.2.2 : Exporter les rapports en JSON et HTML
  - [ ] Entrées : Erreurs cataloguées en base
  - [ ] Sorties : Rapports de patterns et recommandations
  - [ ] Scripts : `development/managers/error-manager/analyzer.go`
  - [ ] Conditions préalables : Base de données d'erreurs populée

## Phase 5 : Intégration avec les gestionnaires existants

*Progression : 0%*

### 5.1 Intégration avec integrated-manager

*Progression : 0%*
- [ ] Connecter le gestionnaire d'erreurs avec les autres managers
  - [ ] Étape 5.1 : Créer des hooks dans `development/managers/integrated-manager`
    - [ ] Micro-étape 5.1.1 : Ajouter des appels au gestionnaire d'erreurs dans les points critiques
    - [ ] Micro-étape 5.1.2 : Configurer la propagation des erreurs entre managers
  - [ ] Étape 5.2 : Implémenter la centralisation des erreurs
    - [ ] Micro-étape 5.2.1 : Créer `CentralizeError()` pour collecter toutes les erreurs
    - [ ] Micro-étape 5.2.2 : Tester l'intégration avec des scénarios d'erreurs simulés
  - [ ] Entrées : Erreurs provenant de tous les managers
  - [ ] Sorties : Centralisation et traitement unifié des erreurs
  - [ ] Scripts : `development/managers/integrated-manager/error_integration.go`
  - [ ] Conditions préalables : Gestionnaire d'erreurs fonctionnel

## Phase 6 : Tests et validation

*Progression : 0%*

### 6.1 Tests unitaires et d'intégration

*Progression : 0%*
- [ ] Créer une suite de tests complète
  - [ ] Étape 6.1 : Tests unitaires pour chaque composant
    - [ ] Micro-étape 6.1.1 : Tests pour `ErrorEntry`, validation, catalogage
    - [ ] Micro-étape 6.1.2 : Tests pour persistance PostgreSQL et Qdrant
    - [ ] Micro-étape 6.1.3 : Tests pour l'analyseur de patterns
  - [ ] Étape 6.2 : Tests d'intégration
    - [ ] Micro-étape 6.2.1 : Tests end-to-end du flux complet d'erreur
    - [ ] Micro-étape 6.2.2 : Tests de performance et de charge
  - [ ] Entrées : Scénarios de test diversifiés
  - [ ] Sorties : Couverture de tests > 90%
  - [ ] Scripts : `development/managers/error-manager/*_test.go`
  - [ ] Conditions préalables : Toutes les phases précédentes terminées

## Phase 7 : Documentation et déploiement

*Progression : 0%*

### 7.1 Documentation complète

*Progression : 0%*
- [ ] Créer la documentation utilisateur et développeur
  - [ ] Étape 7.1 : Documentation API et architecture
    - [ ] Micro-étape 7.1.1 : Documenter toutes les fonctions publiques
    - [ ] Micro-étape 7.1.2 : Créer des diagrammes d'architecture
    - [ ] Micro-étape 7.1.3 : Rédiger le guide d'utilisation
  - [ ] Étape 7.2 : Scripts de déploiement
    - [ ] Micro-étape 7.2.1 : Créer des scripts d'installation automatisée
    - [ ] Micro-étape 7.2.2 : Configurer les environnements de développement et production
  - [ ] Entrées : Code source finalisé
  - [ ] Sorties : Documentation complète et scripts de déploiement
  - [ ] Scripts : `docs/`, `scripts/deploy/`
  - [ ] Conditions préalables : Système testé et validé
