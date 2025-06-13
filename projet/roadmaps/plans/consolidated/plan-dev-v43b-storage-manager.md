# Plan de développement v43b - Gestionnaire de Stockage (StorageManager)

*Version 1.0 - 2025-06-04 - Progression globale : 0%*

## Introduction

Ce document détaille le plan de développement pour le `StorageManager` du projet `EMAIL_SENDER_1`. Ce manager sera responsable de toutes les interactions avec les bases de données persistantes, notamment PostgreSQL pour les données structurées (comme les erreurs cataloguées) et Qdrant pour la recherche vectorielle. Il abstraira la logique de connexion, de migration de schéma, et les opérations CRUD, offrant des interfaces claires (repositories ou DAO) aux autres managers.

Le `StorageManager` respectera les principes DRY (en centralisant la logique d'accès aux données), KISS (en fournissant des méthodes simples pour les opérations courantes), et SOLID (en ayant des responsabilités bien définies pour chaque type de stockage et en étant extensible pour de nouvelles bases de données si nécessaire).

Il sera situé dans `development/managers/storage-manager/`.

## Table des matières

- [1] Phase 1 : Conception et Initialisation
- [2] Phase 2 : Implémentation du support PostgreSQL
- [3] Phase 3 : Implémentation du support Qdrant
- [4] Phase 4 : Intégration, Tests Avancés et Documentation

## Phase 1 : Conception et Initialisation

*Progression : 0%*

### 1.1 Définition détaillée des responsabilités et du périmètre

*Progression : 0%*
- [ ] Micro-étape 1.1.1 : Lister les fonctionnalités exactes :
    - [ ] Gestion des connexions aux bases de données (PostgreSQL, Qdrant).
    - [ ] Configuration des pools de connexions.
    - [ ] Exécution des migrations de schéma pour PostgreSQL.
    - [ ] Fourniture d'interfaces de type Repository/DAO pour les entités (ex: `ErrorEntryRepository`).
    - [ ] Opérations CRUD pour PostgreSQL.
    - [ ] Opérations spécifiques à Qdrant (ex: `UpsertVector`, `SearchSimilar`).
    - [ ] Gestion des transactions pour PostgreSQL.
    - [ ] Abstraction des détails spécifiques aux drivers de base de données.
- [ ] Micro-étape 1.1.2 : Définir les interfaces publiques du manager et des repositories :
    - [ ] `type StorageManager interface { GetErrorEntryRepository() ErrorEntryRepository; GetQdrantClient() QdrantClientWrapper; ... }`
    - [ ] `func New(cfg ConfigManager) (StorageManager, error)`
    - [ ] `type ErrorEntryRepository interface { Create(entry *ErrorEntry) error; GetByID(id string) (*ErrorEntry, error); ... }`
    - [ ] `type QdrantClientWrapper interface { UpsertPoints(collectionName string, points []*PointStruct) error; Search(collectionName string, vector []float32, limit int) ([]*ScoredPoint, error); ... }` (Wrapper autour du client Qdrant natif pour tests et abstraction)
- [ ] Micro-étape 1.1.3 : Identifier les points d'intégration :
    - [ ] `IntegratedManager` : Pour l'initialisation.
    - [ ] `ConfigManager` : Pour obtenir les DSN, adresses des serveurs, credentials.
    - [ ] `ErrorManager` : Pour persister les `ErrorEntry` et potentiellement pour logger les erreurs internes du `StorageManager`.
    - [ ] D'autres managers qui nécessitent un accès aux données (ex: `Analyzer` dans `ErrorManager`).

### 1.2 Initialisation de la structure du module Go

*Progression : 0%*
- [ ] Micro-étape 1.2.1 : Créer le répertoire `development/managers/storage-manager/`.
- [ ] Micro-étape 1.2.2 : Créer les fichiers initiaux.
    - [ ] `storage_manager.go` (implémentation principale et interface)
    - [ ] `postgres.go` (logique spécifique à PostgreSQL: connexion, migration, repo factory)
    - [ ] `qdrant.go` (logique spécifique à Qdrant: connexion, client wrapper)
    - [ ] `repositories/error_entry_repo.go` (implémentation du repository pour ErrorEntry)
    - [ ] `migrations/postgres/` (pour les fichiers .sql de migration)
    - [ ] `types.go` (structs partagées si nécessaire, ex: options de connexion)
    - [ ] `storage_manager_test.go`
    - [ ] `postgres_test.go`
    - [ ] `qdrant_test.go`
    - [ ] `README.md`
- [ ] Micro-étape 1.2.3 : Ajouter les dépendances nécessaires dans `go.mod`.
    - [ ] `github.com/lib/pq` (driver PostgreSQL)
    - [ ] `github.com/qdrant/go-client/qdrant` (client Qdrant)
    - [ ] Une librairie de migration (ex: `github.com/golang-migrate/migrate/v4` ou `github.com/amacneil/dbmate` ou une solution custom simple).

### 1.3 Conception de la gestion des erreurs internes

*Progression : 0%*
- [ ] Micro-étape 1.3.1 : Définir des erreurs spécifiques (ex: `ErrConnectionFailed`, `ErrMigrationFailed`, `ErrRecordNotFound`, `ErrQueryFailed`).
- [ ] Micro-étape 1.3.2 : Planifier l'utilisation du `ErrorManager` centralisé pour les erreurs critiques non retournées directement à l'appelant.

### 1.4 Planification des tests unitaires et d'intégration initiaux

*Progression : 0%*
- [ ] Micro-étape 1.4.1 : Identifier les premiers composants à tester :
    - [ ] Connexion à une instance PostgreSQL de test (via Docker).
    - [ ] Exécution d'une migration SQL simple.
    - [ ] Connexion à une instance Qdrant de test (via Docker).

## Phase 2 : Implémentation du support PostgreSQL

*Progression : 0%*

### 2.1 Implémentation de la connexion et de la configuration

*Progression : 0%*
- [ ] Micro-étape 2.1.1 : Implémenter la fonction de connexion à PostgreSQL.
    - [ ] Lire le DSN depuis `ConfigManager`.
    - [ ] Configurer le pool de connexions (`sql.DB`).
    - [ ] Gérer les erreurs de connexion.
    - [ ] Scripts : `postgres.go`
- [ ] Micro-étape 2.1.2 : Tests unitaires pour la connexion (nécessite une DB de test).
    - [ ] Scripts : `postgres_test.go`

### 2.2 Implémentation du système de migration de schéma

*Progression : 0%*
- [ ] Micro-étape 2.2.1 : Choisir et intégrer une librairie de migration ou développer une solution simple.
    - [ ] Si librairie : Suivre sa documentation pour l'intégration.
    - [ ] Si custom : Logique pour lire les fichiers `.sql` d'un répertoire et les exécuter en séquence, en gardant une trace des migrations appliquées (ex: table `schema_migrations`).
- [ ] Micro-étape 2.2.2 : Créer le premier fichier de migration pour la table `project_errors` (similaire à `schema_errors.sql` de `plan-dev-v42`).
    - [ ] Scripts : `migrations/postgres/001_create_project_errors_table.sql`
- [ ] Micro-étape 2.2.3 : Implémenter la fonction pour appliquer les migrations au démarrage.
    - [ ] Scripts : `postgres.go`
- [ ] Micro-étape 2.2.4 : Tests pour le système de migration.
    - [ ] Appliquer, vérifier, potentiellement rollback (si supporté).
    - [ ] Scripts : `postgres_test.go`

### 2.3 Implémentation du `ErrorEntryRepository`

*Progression : 0%*
- [ ] Micro-étape 2.3.1 : Définir la struct `errorEntryRepositoryImpl` qui implémente `ErrorEntryRepository`.
    - [ ] Prendra un `*sql.DB` en dépendance.
- [ ] Micro-étape 2.3.2 : Implémenter la méthode `Create(entry *ErrorEntry) error`.
    - [ ] Insérer une `ErrorEntry` dans la table `project_errors`.
    - [ ] Gérer les erreurs SQL.
- [ ] Micro-étape 2.3.3 : Implémenter `GetByID(id string) (*ErrorEntry, error)`.
- [ ] Micro-étape 2.3.4 : Implémenter d'autres méthodes si nécessaires (ex: `FindByModule`, `GetRecentErrors`).
- [ ] Micro-étape 2.3.5 : Tests unitaires pour chaque méthode du repository.
    - [ ] Nécessite une DB de test avec le schéma appliqué.
    - [ ] Scripts : `repositories/error_entry_repo_test.go`

### 2.4 Implémentation de la gestion des transactions (optionnel initialement)

*Progression : 0%*
- [ ] Micro-étape 2.4.1 : Concevoir une API pour exécuter des opérations dans une transaction.
    - [ ] Ex: `ExecuteInTransaction(fn func(tx *sql.Tx) error) error`.
- [ ] Micro-étape 2.4.2 : Adapter les méthodes du repository pour accepter `*sql.Tx` ou `*sql.DB`.
- [ ] Micro-étape 2.4.3 : Tests pour les transactions (commit, rollback).

## Phase 3 : Implémentation du support Qdrant

*Progression : 0%*

### 3.1 Implémentation de la connexion et de la configuration

*Progression : 0%*
- [ ] Micro-étape 3.1.1 : Implémenter la fonction de connexion à Qdrant.
    - [ ] Lire l'adresse du serveur Qdrant depuis `ConfigManager`.
    - [ ] Utiliser `qdrant.NewClient()`.
    - [ ] Gérer les erreurs de connexion.
    - [ ] Scripts : `qdrant.go`
- [ ] Micro-étape 3.1.2 : Tests unitaires pour la connexion (nécessite une instance Qdrant de test).
    - [ ] Scripts : `qdrant_test.go`

### 3.2 Implémentation du `QdrantClientWrapper`

*Progression : 0%*
- [ ] Micro-étape 3.2.1 : Créer la struct `qdrantClientWrapperImpl`.
    - [ ] Prendra un `*qdrant.Client` en dépendance.
- [ ] Micro-étape 3.2.2 : Implémenter `UpsertPoints(collectionName string, points []*PointStruct) error`.
    - [ ] Appeler la méthode correspondante du client Qdrant.
    - [ ] Gérer les erreurs.
- [ ] Micro-étape 3.2.3 : Implémenter `Search(collectionName string, vector []float32, limit int) ([]*ScoredPoint, error)`.
- [ ] Micro-étape 3.2.4 : Implémenter la création de collection si elle n'existe pas (ex: `EnsureCollectionExists(name string, vectorSize uint64, distance string)`).
    - [ ] Récupérer la configuration de la collection (nom, taille vecteur, distance) depuis `ConfigManager` ou des constantes.
- [ ] Micro-étape 3.2.5 : Tests unitaires pour le wrapper Qdrant.
    - [ ] Nécessite une instance Qdrant de test.
    - [ ] Scripts : `qdrant_test.go`

## Phase 4 : Intégration, Tests Avancés et Documentation

*Progression : 0%*

### 4.1 Intégration avec `IntegratedManager` et `ConfigManager`

*Progression : 0%*
- [ ] Micro-étape 4.1.1 : `IntegratedManager` initialise `StorageManager` après `ConfigManager`.
    - [ ] Passe l'instance de `ConfigManager` à `StorageManager`.
- [ ] Micro-étape 4.1.2 : `StorageManager` utilise `ConfigManager` pour obtenir les DSN, adresses, etc.

### 4.2 Utilisation par `ErrorManager`

*Progression : 0%*
- [ ] Micro-étape 4.2.1 : `ErrorManager` obtient `ErrorEntryRepository` et `QdrantClientWrapper` depuis `StorageManager`.
- [ ] Micro-étape 4.2.2 : `ErrorManager` utilise ces interfaces pour persister les erreurs et leurs vecteurs.
    - [ ] Adapter `PersistErrorToSQL` et `StoreErrorVector` de `plan-dev-v42`.
    - [ ] Scripts : `development/managers/error-manager/storage/postgres.go` (sera refactorisé/supprimé), `development/managers/error-manager/storage/qdrant.go` (sera refactorisé/supprimé).

### 4.3 Développement des tests d'intégration complets

*Progression : 0%*
- [ ] Micro-étape 4.3.1 : Scénario : `ErrorManager` reçoit une erreur, la catalogue, puis la persiste via `StorageManager` dans PostgreSQL et Qdrant.
- [ ] Micro-étape 4.3.2 : Vérifier que les données sont correctement stockées dans les deux bases.
    - [ ] Scripts : `development/managers/error-manager/integration_test.go`

### 4.4 Tests de robustesse (connexions instables, erreurs DB)

*Progression : 0%*
- [ ] Micro-étape 4.4.1 : Simuler des pannes de base de données pendant les opérations.
- [ ] Micro-étape 4.4.2 : Vérifier la gestion des erreurs de connexion et des tentatives de reconnexion (si implémenté).

### 4.5 Documentation (GoDoc, README)

*Progression : 0%*
- [ ] Micro-étape 4.5.1 : Documenter toutes les interfaces et fonctions publiques.
- [ ] Micro-étape 4.5.2 : Mettre à jour le `README.md` de `StorageManager`.
    - [ ] Expliquer comment configurer les connexions.
    - [ ] Comment utiliser les repositories.
    - [ ] Comment ajouter des migrations.
- [ ] Micro-étape 4.5.3 : Documenter les schémas de base de données (peut-être dans le répertoire `migrations`).

### 4.6 Validation finale et couverture de tests

*Progression : 0%*
- [ ] Micro-étape 4.6.1 : Viser une couverture de tests > 90% pour le `StorageManager`.
- [ ] Micro-étape 4.6.2 : Revue de code et linting.

### 4.7 Scripts et Conditions

*Progression : 0%*
- [ ] Scripts principaux :
    - `development/managers/storage-manager/storage_manager.go`
    - `development/managers/storage-manager/postgres.go`
    - `development/managers/storage-manager/qdrant.go`
    - `development/managers/storage-manager/repositories/error_entry_repo.go`
    - `development/managers/storage-manager/migrations/postgres/001_create_project_errors_table.sql`
- [ ] Conditions préalables générales : Go 1.22+, `ConfigManager` (interface de base disponible), `ErrorManager` (interface de base disponible), Docker avec PostgreSQL et Qdrant pour les tests.
