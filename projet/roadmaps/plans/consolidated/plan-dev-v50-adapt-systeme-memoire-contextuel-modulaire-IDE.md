# Système de Mémoire Contextuelle Modulaire pour IDE - Version Adaptée

*Version 1.0 - Adaptée aux configurations locales - 2025-01-27*

## Module 1 : Introduction

**Objectif :** Concevoir un système de mémoire contextuelle pour un IDE, permettant de capturer, indexer, récupérer et intégrer des actions contextuelles (ex. : commandes, modifications de code) avec une latence < 100ms et une scalabilité pour 100 utilisateurs. Le système utilise les managers existants du dépôt, avec SQLite/PostgreSQL local au lieu de Supabase, Qdrant pour la vectorisation, et intégration avec l'écosystème MCP Gateway.

**Principes directeurs :**
- **DRY :** Réutilisation des managers existants (ErrorManager, ConfigManager, StorageManager)
- **KISS :** Interfaces simples, API REST standardisées, documentation claire
- **SOLID :** Responsabilité unique par module, interfaces ségrégées, injection de dépendances

**Technologies adaptées :**
- **Langages :** Go (managers principaux, API), Python (scripts MCP, cache embeddings), PowerShell (scripts utilitaires)
- **Bases de données :** PostgreSQL (via StorageManager existant), SQLite (via configurations MCP Gateway)
- **Cache :** SQLiteEmbeddingCache existant, Redis (optionnel)
- **Intégrations :** MCP Gateway, N8N workflows, API externes
- **Monitoring :** Structures ErrorManager existantes

## Module 2 : Architecture Adaptée

**Hiérarchie basée sur l'existant :**

```
Core Managers (Existants) :
├── ErrorManager (gestion centralisée des erreurs)
├── StorageManager (PostgreSQL, Qdrant) 
├── ConfigManager (configurations centralisées)
└── IntegratedManager (coordination)

Service Managers (Adaptés) :
├── ContextualMemoryManager (nouveau - orchestration principale)
├── IndexManager (Qdrant + SQLiteEmbeddingCache)
├── RetrievalManager (PostgreSQL + SQLite via StorageManager)
└── IntegrationManager (MCP Gateway + N8N)
```

**Tableau comparatif adapté :**

| Manager | Rôle | Base de données | État | Intégration |
|---------|------|-----------------|------|-------------|
| **ErrorManager** | Gestion centralisée des erreurs | PostgreSQL (existant) | ✅ 100% | Core Service |
| **StorageManager** | Connexions DB, migrations | PostgreSQL + Qdrant | ✅ 100% | Core Service |
| **ConfigManager** | Configurations centralisées | Fichiers YAML | ✅ 100% | Core Service |
| **ContextualMemoryManager** | Orchestration mémoire contextuelle | - | 🔄 0% | Nouveau |
| **IndexManager** | Indexation Qdrant + cache SQLite | SQLite + Qdrant | 🔄 30% | SQLiteEmbeddingCache |
| **RetrievalManager** | Récupération via PostgreSQL/SQLite | PostgreSQL + SQLite | 🔄 20% | StorageManager |
| **IntegrationManager** | MCP Gateway + workflows N8N | SQLite (MCP) | 🔄 40% | MCP Gateway |

**Flux de données adapté :**
```
[IDE/Editor] --> [ContextualMemoryManager] --> [IndexManager] --> [Qdrant + SQLiteEmbeddingCache]
                            |                        |
                            v                        v
[IntegrationManager] <-- [RetrievalManager] <-- [StorageManager] --> [PostgreSQL + SQLite]
        |                                                                     |
        v                                                                     v
[MCP Gateway + N8N] <-- [ConfigManager] <-- [ErrorManager] <-- [PostgreSQL (errors)]
```

## Module 3 : Interfaces des Managers Adaptées

**Interface générique réutilisant l'existant :**

```go
// Réutilise l'interface BaseManager existante
type ContextualMemoryManager interface {
    interfaces.BaseManager // Hérite de Initialize, HealthCheck, etc.
    CaptureAction(ctx context.Context, action Action) error
    SearchContext(ctx context.Context, query string) ([]ContextResult, error)
    AnalyzeContext(ctx context.Context, data ContextData) (Analysis, error)
}
```

### IndexManager adapté

**Rôle :** Vectorisation via Qdrant et cache local via SQLiteEmbeddingCache existant.

```go
package managers

import (
    "context"
    "github.com/email-sender/development/scripts/mcp"
    "github.com/email-sender/development/managers/interfaces"
)

type IndexManager interface {
    interfaces.BaseManager
    IndexAction(ctx context.Context, action Action) error
    SearchSimilar(ctx context.Context, vector []float64, limit int) ([]SimilarResult, error)
    CacheEmbedding(ctx context.Context, text string, vector []float64) error
}

type indexManagerImpl struct {
    storageManager  interfaces.StorageManager
    errorManager    interfaces.ErrorManager
    embeddingCache  *mcp.SQLiteEmbeddingCache
    qdrantClient    interface{} // Via StorageManager.GetQdrantConnection()
}

func NewIndexManager(
    sm interfaces.StorageManager,
    em interfaces.ErrorManager,
    cachePath string,
) IndexManager {
    cache := mcp.NewSQLiteEmbeddingCache(cachePath, 10000, 86400, true, 3600)
    
    return &indexManagerImpl{
        storageManager: sm,
        errorManager:   em,
        embeddingCache: cache,
    }
}

func (im *indexManagerImpl) Initialize(ctx context.Context) error {
    // Initialiser la connexion Qdrant via StorageManager
    qdrantConn, err := im.storageManager.GetQdrantConnection()
    if err != nil {
        return im.errorManager.ProcessError(ctx, err, "IndexManager", "Initialize", nil)
    }
    im.qdrantClient = qdrantConn
    
    return nil
}

func (im *indexManagerImpl) IndexAction(ctx context.Context, action Action) error {
    // 1. Vérifier le cache SQLite
    cached, err := im.embeddingCache.Get(action.Text, "contextual-model")
    if err == nil && cached != nil {
        // Utiliser l'embedding en cache
        return im.upsertToQdrant(ctx, action.ID, cached.Vector)
    }
    
    // 2. Générer nouveau embedding si pas en cache
    vector, err := im.generateEmbedding(ctx, action.Text)
    if err != nil {
        return im.errorManager.ProcessError(ctx, err, "IndexManager", "IndexAction", nil)
    }
    
    // 3. Mettre en cache
    err = im.embeddingCache.Set(action.Text, "contextual-model", vector, nil, action.ID)
    if err != nil {
        im.errorManager.ProcessError(ctx, err, "IndexManager", "CacheEmbedding", nil)
        // Continue même si cache échoue
    }
    
    // 4. Indexer dans Qdrant
    return im.upsertToQdrant(ctx, action.ID, vector)
}
```

### RetrievalManager adapté

**Rôle :** Récupération via PostgreSQL/SQLite en utilisant StorageManager existant.

```go
type RetrievalManager interface {
    interfaces.BaseManager
    QueryContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
    GetActionHistory(ctx context.Context, filters ActionFilters) ([]Action, error)
    SearchByVector(ctx context.Context, vector []float64, threshold float64) ([]ContextResult, error)
}

type retrievalManagerImpl struct {
    storageManager interfaces.StorageManager
    errorManager   interfaces.ErrorManager
    indexManager   IndexManager
}

func NewRetrievalManager(
    sm interfaces.StorageManager,
    em interfaces.ErrorManager,
    im IndexManager,
) RetrievalManager {
    return &retrievalManagerImpl{
        storageManager: sm,
        errorManager:   em,
        indexManager:   im,
    }
}

func (rm *retrievalManagerImpl) QueryContext(ctx context.Context, query ContextQuery) ([]ContextResult, error) {
    // 1. Recherche vectorielle via IndexManager
    vector, err := rm.generateQueryEmbedding(ctx, query.Text)
    if err != nil {
        return nil, rm.errorManager.ProcessError(ctx, err, "RetrievalManager", "QueryContext", nil)
    }
    
    similarResults, err := rm.indexManager.SearchSimilar(ctx, vector, query.Limit)
    if err != nil {
        return nil, rm.errorManager.ProcessError(ctx, err, "RetrievalManager", "QueryContext", nil)
    }
    
    // 2. Enrichir avec métadonnées depuis PostgreSQL
    var results []ContextResult
    pgConn, err := rm.storageManager.GetPostgreSQLConnection()
    if err != nil {
        return nil, rm.errorManager.ProcessError(ctx, err, "RetrievalManager", "QueryContext", nil)
    }
    
    for _, similar := range similarResults {
        metadata, err := rm.getActionMetadata(ctx, pgConn, similar.ID)
        if err != nil {
            rm.errorManager.ProcessError(ctx, err, "RetrievalManager", "QueryContext", nil)
            continue
        }
        
        results = append(results, ContextResult{
            ID:         similar.ID,
            Score:      similar.Score,
            Action:     metadata.Action,
            Context:    metadata.Context,
            Timestamp:  metadata.Timestamp,
        })
    }
    
    return results, nil
}
```

### IntegrationManager adapté

**Rôle :** Intégration avec MCP Gateway et workflows N8N existants.

```go
type IntegrationManager interface {
    interfaces.BaseManager
    NotifyMCPGateway(ctx context.Context, event ContextEvent) error
    TriggerN8NWorkflow(ctx context.Context, workflowID string, data interface{}) error
    SyncToMCPDatabase(ctx context.Context, actions []Action) error
}

type integrationManagerImpl struct {
    storageManager interfaces.StorageManager
    errorManager   interfaces.ErrorManager
    configManager  interfaces.ConfigManager
    mcpGatewayURL  string
    n8nWebhookURL  string
}

func NewIntegrationManager(
    sm interfaces.StorageManager,
    em interfaces.ErrorManager,
    cm interfaces.ConfigManager,
) IntegrationManager {
    return &integrationManagerImpl{
        storageManager: sm,
        errorManager:   em,
        configManager:  cm,
        mcpGatewayURL:  cm.GetString("mcp.gateway.url"),
        n8nWebhookURL:  cm.GetString("n8n.webhook.url"),
    }
}

func (im *integrationManagerImpl) NotifyMCPGateway(ctx context.Context, event ContextEvent) error {
    // Utilise l'API MCP Gateway existante pour notifier les événements
    payload := map[string]interface{}{
        "type":      "context_event",
        "action":    event.Action,
        "context":   event.Context,
        "timestamp": event.Timestamp,
    }
    
    return im.sendHTTPRequest(ctx, im.mcpGatewayURL+"/api/events", payload)
}

func (im *integrationManagerImpl) SyncToMCPDatabase(ctx context.Context, actions []Action) error {
    // Utilise la base SQLite du MCP Gateway pour synchroniser
    // Réutilise les patterns de storage/db.go du MCP Gateway
    
    for _, action := range actions {
        err := im.storeInMCPDB(ctx, action)
        if err != nil {
            im.errorManager.ProcessError(ctx, err, "IntegrationManager", "SyncToMCPDatabase", nil)
            // Continue avec les autres actions
        }
    }
    
    return nil
}
```

## Module 4 : Tests Adaptés

### Tests unitaires utilisant les mocks existants

```go
func TestIndexManager_Initialize(t *testing.T) {
    // Utilise les mocks des managers existants
    mockStorageManager := &mocks.MockStorageManager{}
    mockErrorManager := &mocks.MockErrorManager{}
    
    // Configure les mocks
    mockStorageManager.On("GetQdrantConnection").Return(mockQdrantClient, nil)
    
    im := NewIndexManager(mockStorageManager, mockErrorManager, "./test_cache.db")
    ctx := context.Background()
    
    err := im.Initialize(ctx)
    assert.NoError(t, err)
    
    mockStorageManager.AssertExpectations(t)
}

func TestRetrievalManager_QueryContext(t *testing.T) {
    mockStorageManager := &mocks.MockStorageManager{}
    mockErrorManager := &mocks.MockErrorManager{}
    mockIndexManager := &mocks.MockIndexManager{}
    
    // Configure les retours
    mockStorageManager.On("GetPostgreSQLConnection").Return(mockPGConn, nil)
    mockIndexManager.On("SearchSimilar", mock.Anything, mock.Anything, 10).Return([]SimilarResult{
        {ID: "test-1", Score: 0.95},
    }, nil)
    
    rm := NewRetrievalManager(mockStorageManager, mockErrorManager, mockIndexManager)
    
    query := ContextQuery{Text: "test query", Limit: 10}
    results, err := rm.QueryContext(context.Background(), query)
    
    assert.NoError(t, err)
    assert.Len(t, results, 1)
    assert.Equal(t, "test-1", results[0].ID)
}
```

### Tests d'intégration avec bases de données réelles

```go
func TestIntegration_FullContextualFlow(t *testing.T) {
    // Utilise les vraies implémentations avec bases de test
    testStorageManager := setupTestStorageManager(t)
    testErrorManager := setupTestErrorManager(t)
    
    // Initialise les managers
    im := NewIndexManager(testStorageManager, testErrorManager, "./test_integration_cache.db")
    rm := NewRetrievalManager(testStorageManager, testErrorManager, im)
    igm := NewIntegrationManager(testStorageManager, testErrorManager, testConfigManager)
    
    ctx := context.Background()
    
    // Test du flux complet
    action := Action{
        ID:        "integration-test-1",
        Type:      "command",
        Text:      "git commit -m 'test'",
        Timestamp: time.Now(),
    }
    
    // 1. Index l'action
    err := im.IndexAction(ctx, action)
    assert.NoError(t, err)
    
    // 2. Recherche l'action
    query := ContextQuery{Text: "git commit", Limit: 5}
    results, err := rm.QueryContext(ctx, query)
    assert.NoError(t, err)
    assert.NotEmpty(t, results)
    
    // 3. Intègre avec MCP Gateway
    event := ContextEvent{Action: action, Context: "test"}
    err = igm.NotifyMCPGateway(ctx, event)
    assert.NoError(t, err)
}
```

## Module 5 : Exemples Concrets Adaptés

### Exemple 1 : Indexation avec SQLiteEmbeddingCache et Qdrant

**Input :** Indexer une commande utilisateur avec cache SQLite local et Qdrant.

```go
package main

import (
    "context"
    "fmt"
    "time"
    
    "github.com/email-sender/development/managers/storage-manager/development"
    "github.com/email-sender/development/managers/error-manager"
    "github.com/email-sender/development/scripts/mcp"
)

type Action struct {
    ID        string    `json:"id"`
    Type      string    `json:"type"`
    Text      string    `json:"text"`
    Timestamp time.Time `json:"timestamp"`
    Metadata  map[string]interface{} `json:"metadata"`
}

func main() {
    ctx := context.Background()
    
    // Utilise les managers existants
    storageManager := storagemanager.NewStorageManager()
    errorManager := errormanager.NewErrorManager()
    
    // Initialise le cache SQLite existant
    embeddingCache := mcp.NewSQLiteEmbeddingCache(
        "./data/embeddings/contextual_cache.db",
        10000,  // max_size
        86400,  // 24h TTL
        true,   // auto_cleanup
        3600,   // cleanup_interval
    )
    
    // Exemple d'action à indexer
    action := Action{
        ID:        "cmd_" + fmt.Sprintf("%d", time.Now().Unix()),
        Type:      "command",
        Text:      "git commit -m 'Implement contextual memory system'",
        Timestamp: time.Now(),
        Metadata: map[string]interface{
            "workspace": "/home/user/project",
            "branch":    "feature/contextual-memory",
        },
    }
    
    // Index l'action
    indexManager := NewIndexManager(storageManager, errorManager, embeddingCache)
    err := indexManager.IndexAction(ctx, action)
    if err != nil {
        fmt.Printf("Erreur indexation: %v\n", err)
        return
    }
    
    fmt.Printf("Action indexée avec succès: %s\n", action.ID)
}
```

### Exemple 2 : Récupération via PostgreSQL et SQLite

**Input :** Récupérer le contexte depuis PostgreSQL avec recherche vectorielle.

```go
func ExampleRetrievalWithPostgreSQL() {
    ctx := context.Background()
    
    // Utilise StorageManager existant pour PostgreSQL
    storageManager := storagemanager.NewStorageManager()
    err := storageManager.Initialize(ctx)
    if err != nil {
        panic(err)
    }
    
    // Récupère la connexion PostgreSQL
    pgConn, err := storageManager.GetPostgreSQLConnection()
    if err != nil {
        panic(err)
    }
    
    // Requête contextuelle
    query := `
        SELECT 
            a.id,
            a.action_type,
            a.action_text,
            a.timestamp,
            a.metadata,
            e.vector_embedding
        FROM contextual_actions a
        LEFT JOIN embeddings e ON a.id = e.action_id
        WHERE a.action_text ILIKE $1
        ORDER BY a.timestamp DESC
        LIMIT $2
    `
    
    rows, err := pgConn.(*sql.DB).QueryContext(ctx, query, "%git commit%", 10)
    if err != nil {
        panic(err)
    }
    defer rows.Close()
    
    var results []ContextResult
    for rows.Next() {
        var result ContextResult
        err := rows.Scan(
            &result.ID,
            &result.ActionType,
            &result.ActionText,
            &result.Timestamp,
            &result.Metadata,
            &result.VectorEmbedding,
        )
        if err != nil {
            continue
        }
        results = append(results, result)
    }
    
    fmt.Printf("Trouvé %d résultats contextuels\n", len(results))
}
```

### Exemple 3 : Intégration MCP Gateway

**Input :** Synchroniser avec la base SQLite du MCP Gateway existant.

```go
package integration

import (
    "context"
    "database/sql"
    
    "github.com/email-sender/projet/mcp/servers/gateway/internal/mcp/storage"
    "github.com/email-sender/projet/mcp/servers/gateway/internal/common/config"
)

func SyncWithMCPGateway(ctx context.Context, actions []Action) error {
    // Utilise la configuration MCP Gateway existante
    cfg := &config.StorageConfig{
        Type: "db",
        Database: config.DatabaseConfig{
            Type:   "sqlite",
            DBName: "./data/mcp-gateway.db",
        },
    }
    
    // Utilise le store MCP existant
    store, err := storage.NewDBStore(logger, cfg)
    if err != nil {
        return fmt.Errorf("failed to create MCP store: %w", err)
    }
    
    for _, action := range actions {
        // Convertit l'action en format MCP
        mcpConfig := &storage.MCPConfig{
            Name:        action.ID,
            Description: fmt.Sprintf("Contextual action: %s", action.Text),
            Config: map[string]interface{}{
                "type":      action.Type,
                "text":      action.Text,
                "timestamp": action.Timestamp,
                "metadata":  action.Metadata,
            },
        }
        
        // Sauvegarde dans la base MCP
        err := store.SaveConfig(ctx, mcpConfig)
        if err != nil {
            return fmt.Errorf("failed to save to MCP: %w", err)
        }
    }
    
    return nil
}
```

### Exemple 4 : Configuration adaptée aux environnements

**Configuration YAML adaptée :**

```yaml
# config/environments/dev.yaml
contextual_memory:
  storage:
    postgresql:
      host: "localhost"
      port: 5432
      database: "email_sender_dev"
      user: "postgres"
      password: "postgres"
      max_connections: 10
    
    sqlite:
      embedding_cache: "./data/dev/embedding_cache.db"
      mcp_gateway: "./data/dev/mcp-gateway.db"
    
    qdrant:
      url: "http://localhost:6333"
      collection: "contextual_actions_dev"
      vector_size: 384
  
  indexing:
    batch_size: 100
    cache_ttl: 86400  # 24h
    auto_cleanup: true
    cleanup_interval: 3600  # 1h
  
  retrieval:
    max_results: 50
    similarity_threshold: 0.7
    enable_hybrid_search: true
  
  integration:
    mcp_gateway:
      url: "http://localhost:8080"
      enabled: true
    
    n8n:
      webhook_url: "http://localhost:5678/webhook/contextual-memory"
      enabled: false  # Désactivé en dev
  
  monitoring:
    metrics_enabled: true
    health_check_interval: 30s
    performance_threshold:
      latency_ms: 100
      cpu_percent: 50
      memory_mb: 512

---
# config/environments/prod.yaml
contextual_memory:
  storage:
    postgresql:
      host: "${PG_HOST}"
      port: "${PG_PORT:5432}"
      database: "${PG_DATABASE}"
      user: "${PG_USER}"
      password: "${PG_PASSWORD}"
      max_connections: 25
      ssl_mode: "require"
    
    sqlite:
      embedding_cache: "/data/prod/embedding_cache.db"
      mcp_gateway: "/data/prod/mcp-gateway.db"
    
    qdrant:
      url: "${QDRANT_URL}"
      collection: "contextual_actions_prod"
      vector_size: 384
      api_key: "${QDRANT_API_KEY}"
  
  integration:
    mcp_gateway:
      url: "${MCP_GATEWAY_URL}"
      enabled: true
      api_key: "${MCP_API_KEY}"
    
    n8n:
      webhook_url: "${N8N_WEBHOOK_URL}"
      enabled: true
      auth_token: "${N8N_AUTH_TOKEN}"
```

## Module 6 : Architecture de Déploiement Adaptée

### Docker Compose pour l'environnement local

```yaml
# docker-compose.contextual-memory.yml
version: '3.8'

services:
  contextual-memory:
    build:
      context: .
      dockerfile: ./development/managers/contextual-memory-manager/Dockerfile
    ports:
      - "8081:8080"
    environment:
      - ENVIRONMENT=dev
      - PG_HOST=postgres
      - PG_DATABASE=email_sender_dev
      - PG_USER=postgres
      - PG_PASSWORD=postgres
      - QDRANT_URL=http://qdrant:6333
    volumes:
      - ./data/contextual-memory:/data
      - ./config:/config
    depends_on:
      - postgres
      - qdrant
    networks:
      - email-sender-network

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: email_sender_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_contextual_data:/var/lib/postgresql/data
      - ./development/managers/contextual-memory-manager/migrations:/docker-entrypoint-initdb.d
    ports:
      - "5433:5432"
    networks:
      - email-sender-network

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage
    environment:
      QDRANT__SERVICE__HTTP_PORT: 6333
    networks:
      - email-sender-network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - email-sender-network

volumes:
  postgres_contextual_data:
  qdrant_data:
  redis_data:

networks:
  email-sender-network:
    external: true
```

### Schémas SQL adaptés

```sql
-- development/managers/contextual-memory-manager/migrations/001_create_contextual_tables.sql

-- Table des actions contextuelles
CREATE TABLE IF NOT EXISTS contextual_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type VARCHAR(100) NOT NULL,
    action_text TEXT NOT NULL,
    workspace_path TEXT,
    file_path TEXT,
    line_number INTEGER,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table des embeddings (référence aux vecteurs Qdrant)
CREATE TABLE IF NOT EXISTS contextual_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_id UUID NOT NULL REFERENCES contextual_actions(id) ON DELETE CASCADE,
    qdrant_point_id UUID NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    vector_size INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(action_id, model_name)
);

-- Table des contextes inter-actions
CREATE TABLE IF NOT EXISTS contextual_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_action_id UUID NOT NULL REFERENCES contextual_actions(id) ON DELETE CASCADE,
    target_action_id UUID NOT NULL REFERENCES contextual_actions(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL, -- 'sequence', 'similarity', 'causality'
    strength FLOAT NOT NULL DEFAULT 0.0,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(source_action_id, target_action_id, relationship_type)
);

-- Table des sessions de travail
CREATE TABLE IF NOT EXISTS contextual_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_name VARCHAR(255),
    workspace_path TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    action_count INTEGER DEFAULT 0,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lien actions <-> sessions
CREATE TABLE IF NOT EXISTS contextual_session_actions (
    session_id UUID NOT NULL REFERENCES contextual_sessions(id) ON DELETE CASCADE,
    action_id UUID NOT NULL REFERENCES contextual_actions(id) ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL,
    PRIMARY KEY (session_id, action_id)
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_contextual_actions_type_timestamp ON contextual_actions(action_type, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_workspace ON contextual_actions(workspace_path);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_text_gin ON contextual_actions USING gin(to_tsvector('english', action_text));
CREATE INDEX IF NOT EXISTS idx_contextual_embeddings_action ON contextual_embeddings(action_id);
CREATE INDEX IF NOT EXISTS idx_contextual_relationships_source ON contextual_relationships(source_action_id);
CREATE INDEX IF NOT EXISTS idx_contextual_relationships_target ON contextual_relationships(target_action_id);
CREATE INDEX IF NOT EXISTS idx_contextual_sessions_workspace ON contextual_sessions(workspace_path);
```

## Module 7 : Monitoring et Métriques Adaptées

### Intégration avec ErrorManager existant

```go
package monitoring

import (
    "context"
    "time"
    
    "github.com/email-sender/development/managers/interfaces"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    contextualActionsIndexed = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "contextual_memory_actions_indexed_total",
            Help: "Total number of actions indexed",
        },
        []string{"action_type", "workspace"},
    )
    
    contextualQueryLatency = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "contextual_memory_query_duration_seconds",
            Help:    "Query latency distribution",
            Buckets: prometheus.ExponentialBuckets(0.001, 2, 15), // 1ms to ~32s
        },
        []string{"operation", "success"},
    )
    
    contextualCacheHitRate = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "contextual_memory_cache_operations_total",
            Help: "Cache operations (hit/miss)",
        },
        []string{"type"}, // "hit" or "miss"
    )
)

type ContextualMetrics struct {
    errorManager interfaces.ErrorManager
}

func NewContextualMetrics(em interfaces.ErrorManager) *ContextualMetrics {
    return &ContextualMetrics{
        errorManager: em,
    }
}

func (cm *ContextualMetrics) RecordActionIndexed(actionType, workspace string) {
    contextualActionsIndexed.WithLabelValues(actionType, workspace).Inc()
}

func (cm *ContextualMetrics) RecordQueryLatency(operation string, duration time.Duration, success bool) {
    successLabel := "true"
    if !success {
        successLabel = "false"
    }
    contextualQueryLatency.WithLabelValues(operation, successLabel).Observe(duration.Seconds())
}

func (cm *ContextualMetrics) RecordCacheHit() {
    contextualCacheHitRate.WithLabelValues("hit").Inc()
}

func (cm *ContextualMetrics) RecordCacheMiss() {
    contextualCacheHitRate.WithLabelValues("miss").Inc()
}
```

## Module 8 : Scripts d'Installation et Configuration

### Script PowerShell d'installation

```powershell
# scripts/Install-ContextualMemorySystem.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDocker,
    
    [Parameter(Mandatory=$false)]
    [switch]$InitializeDatabase
)

Write-Host "Installation du Système de Mémoire Contextuelle - Environnement: $Environment" -ForegroundColor Green

# 1. Vérifier les prérequis
Write-Host "Vérification des prérequis..." -ForegroundColor Yellow

if (-not $SkipDocker) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker n'est pas installé ou accessible"
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        throw "Docker Compose n'est pas installé ou accessible"
    }
}

# 2. Créer les répertoires nécessaires
$dataDir = "./data/contextual-memory"
$configDir = "./config/contextual-memory"

New-Item -ItemType Directory -Force -Path $dataDir
New-Item -ItemType Directory -Force -Path "$dataDir/embeddings"
New-Item -ItemType Directory -Force -Path "$dataDir/logs"
New-Item -ItemType Directory -Force -Path $configDir

Write-Host "Répertoires créés: $dataDir, $configDir" -ForegroundColor Green

# 3. Copier les configurations
Copy-Item "./config/environments/$Environment.yaml" "$configDir/config.yaml" -Force
Write-Host "Configuration copiée pour l'environnement: $Environment" -ForegroundColor Green

# 4. Initialiser la base de données si demandé
if ($InitializeDatabase) {
    Write-Host "Initialisation de la base de données..." -ForegroundColor Yellow
    
    # Démarrer PostgreSQL si pas déjà en cours
    docker-compose -f docker-compose.contextual-memory.yml up -d postgres
    Start-Sleep -Seconds 10
    
    # Exécuter les migrations
    $migrationFiles = Get-ChildItem "./development/managers/contextual-memory-manager/migrations/*.sql" | Sort-Object Name
    
    foreach ($migrationFile in $migrationFiles) {
        Write-Host "Exécution migration: $($migrationFile.Name)" -ForegroundColor Cyan
        $sql = Get-Content $migrationFile.FullName -Raw
        
        # Exécuter via docker exec
        $sql | docker exec -i $(docker-compose -f docker-compose.contextual-memory.yml ps -q postgres) psql -U postgres -d email_sender_dev
        
        if ($LASTEXITCODE -ne 0) {
            throw "Échec migration: $($migrationFile.Name)"
        }
    }
    
    Write-Host "Migrations terminées avec succès" -ForegroundColor Green
}

# 5. Démarrer les services si Docker est disponible
if (-not $SkipDocker) {
    Write-Host "Démarrage des services Docker..." -ForegroundColor Yellow
    docker-compose -f docker-compose.contextual-memory.yml up -d
    
    # Attendre que les services soient prêts
    Write-Host "Attente du démarrage des services..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Vérifier la santé des services
    $services = @("contextual-memory", "postgres", "qdrant")
    foreach ($service in $services) {
        $status = docker-compose -f docker-compose.contextual-memory.yml ps $service
        if ($status -match "Up") {
            Write-Host "✓ Service $service démarré" -ForegroundColor Green
        } else {
            Write-Warning "⚠ Service $service non démarré"
        }
    }
}

# 6. Test de santé
Write-Host "Test de santé du système..." -ForegroundColor Yellow

try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8081/health" -Method GET -TimeoutSec 10
    if ($healthResponse.status -eq "healthy") {
        Write-Host "✓ Système de mémoire contextuelle opérationnel" -ForegroundColor Green
    } else {
        Write-Warning "⚠ Système démarré mais statut: $($healthResponse.status)"
    }
} catch {
    Write-Warning "⚠ Impossible de contacter le service de santé"
}

Write-Host "Installation terminée!" -ForegroundColor Green
Write-Host "URL du service: http://localhost:8081" -ForegroundColor Cyan
Write-Host "Monitoring: http://localhost:8081/metrics" -ForegroundColor Cyan
```

## Module 9 : Plan de Développement par Phases

### Phase 1 : Fondations (Semaines 1-2)

**Objectifs :**
- Adapter les interfaces existantes
- Créer le ContextualMemoryManager de base
- Configurer l'environnement de développement

**Tâches prioritaires :**

1. **Architecture des interfaces**
   - [ ] Créer `development/managers/contextual-memory-manager/`
   - [ ] Définir les interfaces Go adaptées aux managers existants
   - [ ] Implémenter les structures de données (Action, ContextResult, etc.)
   - [ ] Tests unitaires des interfaces

2. **Configuration et environnement**
   - [ ] Créer les fichiers de configuration YAML par environnement
   - [ ] Adapter le docker-compose.yml existant
   - [ ] Créer les migrations SQL PostgreSQL
   - [ ] Script PowerShell d'installation

3. **Intégration avec managers existants**
   - [ ] Adapter l'interface StorageManager pour Qdrant
   - [ ] Utiliser ErrorManager pour la gestion d'erreurs
   - [ ] Intégrer ConfigManager pour les configurations
   - [ ] Tests d'intégration de base

### Phase 2 : Indexation et Cache (Semaines 3-4)

**Objectifs :**
- Implémenter IndexManager avec SQLiteEmbeddingCache
- Intégrer Qdrant pour la recherche vectorielle
- Optimiser les performances de cache

**Tâches prioritaires :**

1. **IndexManager**
   - [ ] Intégration SQLiteEmbeddingCache existant
   - [ ] Connexion Qdrant via StorageManager
   - [ ] Logique d'indexation avec cache-first
   - [ ] Génération d'embeddings (OpenAI/local)

2. **Optimisations cache**
   - [ ] Configuration TTL et auto-cleanup
   - [ ] Métriques de hit/miss ratio
   - [ ] Compression des vecteurs volumineux
   - [ ] Tests de performance

3. **Tests et validation**
   - [ ] Tests unitaires IndexManager
   - [ ] Tests d'intégration Qdrant
   - [ ] Benchmarks de performance
   - [ ] Validation latence < 100ms

### Phase 3 : Récupération et Analyse (Semaines 5-6)

**Objectifs :**
- Implémenter RetrievalManager avec PostgreSQL
- Recherche hybride (vectorielle + textuelle)
- Analyse de contexte avancée

**Tâches prioritaires :**

1. **RetrievalManager**
   - [ ] Requêtes PostgreSQL optimisées
   - [ ] Recherche vectorielle via IndexManager
   - [ ] Fusion des résultats (scoring hybride)
   - [ ] Gestion de la pagination

2. **Analyse contextuelle**
   - [ ] Détection de patterns d'usage
   - [ ] Relations entre actions
   - [ ] Sessions de travail
   - [ ] Recommandations contextuelles

3. **Optimisations**
   - [ ] Index PostgreSQL pour performance
   - [ ] Cache des requêtes fréquentes
   - [ ] Seuils de similarité adaptatifs
   - [ ] Tests de charge

### Phase 4 : Intégrations Externes (Semaines 7-8)

**Objectifs :**
- IntegrationManager avec MCP Gateway
- Workflows N8N
- API REST complète

**Tâches prioritaires :**

1. **IntegrationManager**
   - [ ] API MCP Gateway pour événements
   - [ ] Synchronisation base SQLite MCP
   - [ ] Webhooks N8N pour workflows
   - [ ] Gestion asynchrone des intégrations

2. **API REST**
   - [ ] Endpoints pour indexation
   - [ ] Endpoints pour recherche
   - [ ] Endpoints pour administration
   - [ ] Documentation OpenAPI

3. **Monitoring et observabilité**
   - [ ] Métriques Prometheus
   - [ ] Health checks
   - [ ] Logs structurés
   - [ ] Alertes

### Phase 5 : Production et Optimisation (Semaines 9-10)

**Objectifs :**
- Déploiement production
- Optimisations finales
- Documentation complète

**Tâches prioritaires :**

1. **Déploiement**
   - [ ] Configuration production
   - [ ] Secrets management
   - [ ] CI/CD pipeline
   - [ ] Rollback procedures

2. **Optimisations finales**
   - [ ] Profiling et optimisation mémoire
   - [ ] Optimisation requêtes SQL
   - [ ] Réglage paramètres Qdrant
   - [ ] Tests de montée en charge

3. **Documentation**
   - [ ] Guide d'installation
   - [ ] Guide d'utilisation
   - [ ] API documentation
   - [ ] Troubleshooting guide

## Module 10 : Métriques de Succès et KPIs

### Métriques de Performance

| Métrique | Objectif | Mesure |
|----------|----------|---------|
| **Latence d'indexation** | < 50ms | Temps moyen pour indexer une action |
| **Latence de recherche** | < 100ms | Temps moyen pour une requête contextuelle |
| **Précision de recherche** | > 85% | Relevance@10 des résultats |
| **Disponibilité** | > 99.5% | Uptime du service |
| **Débit** | 1000 req/s | Requêtes supportées simultanément |

### Métriques d'Utilisation

| Métrique | Objectif | Mesure |
|----------|----------|---------|
| **Actions indexées/jour** | > 10,000 | Volume d'indexation quotidien |
| **Recherches/utilisateur/jour** | > 50 | Engagement utilisateur |
| **Taux de cache hit** | > 80% | Efficacité du cache SQLite |
| **Utilisateurs actifs** | 100+ | Scalabilité utilisateur |
| **Workspaces supportés** | 500+ | Diversité des projets |

### Métriques Techniques

| Métrique | Objectif | Mesure |
|----------|----------|---------|
| **Couverture de tests** | > 85% | Pourcentage code testé |
| **Utilisation CPU** | < 50% | Consommation processeur moyenne |
| **Utilisation mémoire** | < 1GB | Consommation RAM moyenne |
| **Taille base SQLite** | < 10GB | Croissance cache embeddings |
| **Temps de démarrage** | < 30s | Initialisation complète du système |

## Module 11 : Documentation et Formation

### Guide d'Utilisation Rapide

```bash
# Installation rapide
git clone <repo>
cd EMAIL_SENDER_1
./scripts/Install-ContextualMemorySystem.ps1 -Environment dev -InitializeDatabase

# Démarrage des services
docker-compose -f docker-compose.contextual-memory.yml up -d

# Test de fonctionnement
curl http://localhost:8081/health

# Indexer une action
curl -X POST http://localhost:8081/api/v1/actions \
  -H "Content-Type: application/json" \
  -d '{
    "type": "command",
    "text": "git commit -m \"Add new feature\"",
    "workspace": "/path/to/project",
    "metadata": {
      "branch": "feature/new-feature"
    }
  }'

# Rechercher du contexte
curl -X GET "http://localhost:8081/api/v1/search?q=git%20commit&limit=10"
```

### API Reference

```yaml
# Endpoints principaux
POST /api/v1/actions           # Indexer une action
GET  /api/v1/search           # Recherche contextuelle
GET  /api/v1/actions/{id}     # Récupérer une action
GET  /api/v1/sessions         # Lister les sessions
POST /api/v1/sessions         # Créer une session
GET  /api/v1/metrics          # Métriques Prometheus
GET  /api/v1/health           # Health check

# Webhooks
POST /api/v1/webhooks/mcp     # Intégration MCP Gateway
POST /api/v1/webhooks/n8n     # Trigger N8N workflows
```

### Troubleshooting Guide

#### Problèmes fréquents

1. **Latence élevée (> 100ms)**
   - Vérifier les index PostgreSQL
   - Analyser le cache hit ratio SQLite
   - Profiler les requêtes Qdrant

2. **Erreurs de connexion Qdrant**
   - Vérifier la configuration réseau
   - Contrôler les logs Qdrant
   - Tester la connectivité : `curl http://qdrant:6333/collections`

3. **Cache SQLite corrompu**
   - Supprimer le fichier cache : `rm ./data/embeddings/contextual_cache.db`
   - Redémarrer le service
   - Le cache se reconstituera automatiquement

4. **Problèmes PostgreSQL**
   - Vérifier les migrations : `psql -U postgres -d email_sender_dev -c "\dt"`
   - Contrôler les logs : `docker logs <postgres_container>`
   - Recréer la base si nécessaire

## Module 12 : Évolutions Futures

### Roadmap à 6 mois

1. **Intelligence artificielle avancée**
   - Modèles d'embeddings personnalisés
   - Analyse prédictive des actions
   - Recommandations proactives

2. **Intégrations supplémentaires**
   - VS Code extension
   - JetBrains plugin
   - Slack bot interactif

3. **Optimisations avancées**
   - Sharding PostgreSQL
   - Clustering Qdrant
   - Cache distribué Redis

### Extensions possibles

1. **Analyse de code**
   - Indexation du code source
   - Détection de patterns
   - Suggestions de refactoring

2. **Collaboration**
   - Partage de contextes entre développeurs
   - Sessions collaboratives
   - Historique d'équipe

3. **Intégration CI/CD**
   - Contexte de build
   - Analyse d'échecs
   - Optimisation pipelines

## Conclusion

Ce plan adapte le système de mémoire contextuelle modulaire v50 à votre infrastructure existante en :

1. **Réutilisant les managers existants** : StorageManager, ErrorManager, ConfigManager
2. **Remplaçant Supabase par PostgreSQL/SQLite local** via vos configurations existantes
3. **Intégrant l'écosystème MCP Gateway** déjà présent dans votre dépôt
4. **Utilisant SQLiteEmbeddingCache** déjà implémenté
5. **Respectant l'architecture Go** et les patterns établis

**Avantages de cette approche :**
- **Réutilisation maximale** du code existant
- **Consistance** avec l'architecture actuelle
- **Maintenance simplifiée** avec un seul écosystème
- **Performance optimisée** avec les bases locales
- **Sécurité renforcée** sans dépendances externes

**Prochaines étapes immédiates :**
1. Valider l'architecture proposée avec l'équipe
2. Créer le répertoire `development/managers/contextual-memory-manager/`
3. Implémenter les interfaces de base
4. Configurer l'environnement de développement
5. Commencer la Phase 1 du plan de développement

Cette adaptation respecte vos principes DRY, KISS et SOLID tout en tirant parti de l'infrastructure solide déjà en place dans votre dépôt.
