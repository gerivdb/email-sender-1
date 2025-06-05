# StorageManager API Documentation

## Overview
Le StorageManager fournit une interface unifiée pour la gestion des connexions, migrations de schéma et opérations CRUD pour tous les stores de données persistantes (PostgreSQL, Qdrant).

## Interface Principal

### StorageManager
```go
type StorageManager interface {
    Initialize(ctx context.Context) error
    GetPostgreSQLConnection() (interface{}, error)
    GetQdrantConnection() (interface{}, error)
    RunMigrations(ctx context.Context) error
    HealthCheck(ctx context.Context) error
    Cleanup() error
}
```

## Méthodes

### Initialize
**Signature:** `Initialize(ctx context.Context) error`

**Description:** Initialise le gestionnaire de stockage et établit les connexions aux bases de données.

**Paramètres:**
- `ctx`: Contexte d'annulation

**Retour:** `error` si l'initialisation échoue

### GetPostgreSQLConnection
**Signature:** `GetPostgreSQLConnection() (interface{}, error)`

**Description:** Retourne une connexion active à PostgreSQL.

**Retour:** 
- `interface{}`: Connexion PostgreSQL
- `error`: Erreur si la connexion échoue

### GetQdrantConnection
**Signature:** `GetQdrantConnection() (interface{}, error)`

**Description:** Retourne une connexion active à Qdrant.

**Retour:**
- `interface{}`: Connexion Qdrant
- `error`: Erreur si la connexion échoue

### RunMigrations
**Signature:** `RunMigrations(ctx context.Context) error`

**Description:** Exécute les migrations de schéma pour toutes les bases de données.

**Paramètres:**
- `ctx`: Contexte d'annulation

**Retour:** `error` si les migrations échouent

### HealthCheck
**Signature:** `HealthCheck(ctx context.Context) error`

**Description:** Vérifie la santé des connexions de stockage.

**Paramètres:**
- `ctx`: Contexte d'annulation

**Retour:** `error` si le health check échoue

### Cleanup
**Signature:** `Cleanup() error`

**Description:** Nettoie les ressources de stockage.

**Retour:** `error` si le cleanup échoue

## Exemple d'utilisation

```go
logger, _ := zap.NewDevelopment()
sm := NewStorageManager(logger, "postgres://...", "http://localhost:6333")

ctx := context.Background()
if err := sm.Initialize(ctx); err != nil {
    log.Fatalf("Failed to initialize: %v", err)
}

// Exécuter les migrations
if err := sm.RunMigrations(ctx); err != nil {
    log.Fatalf("Migration failed: %v", err)
}

// Vérifier la santé
if err := sm.HealthCheck(ctx); err != nil {
    log.Printf("Health check failed: %v", err)
}
```

## Intégration ErrorManager

Le StorageManager intègre l'ErrorManager pour:
- Gestion centralisée des erreurs
- Journalisation structurée
- Catalogage des erreurs avec contexte
- Hooks de traitement d'erreurs

## Configuration

Le manager utilise les fichiers de configuration suivants:
- `postgresql.yaml`: Configuration PostgreSQL
- `qdrant.yaml`: Configuration Qdrant
- `migrations.yaml`: Configuration des migrations
