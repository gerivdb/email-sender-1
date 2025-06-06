# Initialize-ContextualMemoryManager.ps1
# Script pour initialiser la structure du Contextual Memory Manager

param(
   [Parameter(Mandatory = $false)]
   [string]$ProjectRoot = ".",
    
   [Parameter(Mandatory = $false)]
   [switch]$CreateTests,
    
   [Parameter(Mandatory = $false)]
   [switch]$DryRun
)

Write-Host "Initialisation du Contextual Memory Manager" -ForegroundColor Green
Write-Host "Répertoire racine: $ProjectRoot" -ForegroundColor Cyan

$basePath = "$ProjectRoot/development/managers/contextual-memory-manager"

# Définir la structure des répertoires
$directories = @(
   "$basePath",
   "$basePath/development",
   "$basePath/interfaces",
   "$basePath/internal",
   "$basePath/internal/indexing",
   "$basePath/internal/retrieval", 
   "$basePath/internal/integration",
   "$basePath/internal/monitoring",
   "$basePath/migrations",
   "$basePath/migrations/postgresql",
   "$basePath/config",
   "$basePath/scripts",
   "$basePath/docs",
   "$basePath/examples"
)

if ($CreateTests) {
   $directories += @(
      "$basePath/tests",
      "$basePath/tests/unit",
      "$basePath/tests/integration",
      "$basePath/tests/mocks"
   )
}

# Créer les répertoires
Write-Host "Création de la structure des répertoires..." -ForegroundColor Yellow

foreach ($dir in $directories) {
   if ($DryRun) {
      Write-Host "  [DRY-RUN] Créerait: $dir" -ForegroundColor Gray
   }
   else {
      New-Item -ItemType Directory -Force -Path $dir | Out-Null
      Write-Host "  ✓ $dir" -ForegroundColor Green
   }
}

# Définir les fichiers à créer
$files = @{
   "$basePath/go.mod"                                                 = @"
module github.com/email-sender/development/managers/contextual-memory-manager

go 1.21

require (
    github.com/email-sender/development/managers/interfaces v0.0.0
    github.com/email-sender/development/managers/error-manager v0.0.0
    github.com/email-sender/development/managers/storage-manager v0.0.0
    github.com/email-sender/development/managers/config-manager v0.0.0
    github.com/google/uuid v1.3.0
    github.com/prometheus/client_golang v1.16.0
    github.com/stretchr/testify v1.8.4
)

replace github.com/email-sender/development/managers/interfaces => ../interfaces
replace github.com/email-sender/development/managers/error-manager => ../error-manager
replace github.com/email-sender/development/managers/storage-manager => ../storage-manager
replace github.com/email-sender/development/managers/config-manager => ../config-manager
"@

   "$basePath/interfaces/contextual_memory.go"                        = @"
package interfaces

import (
    "context"
    "time"
    
    "github.com/email-sender/development/managers/interfaces"
)

// Action représente une action utilisateur capturée
type Action struct {
    ID          string                 ``json:"id"``
    Type        string                 ``json:"type"``        // command, edit, search, etc.
    Text        string                 ``json:"text"``
    WorkspacePath string               ``json:"workspace_path"``
    FilePath    string                 ``json:"file_path,omitempty"``
    LineNumber  int                    ``json:"line_number,omitempty"``
    Timestamp   time.Time              ``json:"timestamp"``
    Metadata    map[string]interface{} ``json:"metadata,omitempty"``
}

// ContextResult représente un résultat de recherche contextuelle
type ContextResult struct {
    ID              string                 ``json:"id"``
    Action          Action                 ``json:"action"``
    Score           float64                ``json:"score"``
    SimilarityType  string                 ``json:"similarity_type"`` // vector, text, hybrid
    Context         map[string]interface{} ``json:"context,omitempty"``
}

// ContextQuery représente une requête de recherche contextuelle
type ContextQuery struct {
    Text               string    ``json:"text"``
    WorkspacePath      string    ``json:"workspace_path,omitempty"``
    ActionTypes        []string  ``json:"action_types,omitempty"``
    TimeRange          TimeRange ``json:"time_range,omitempty"``
    Limit              int       ``json:"limit,omitempty"``
    SimilarityThreshold float64  ``json:"similarity_threshold,omitempty"``
}

// TimeRange représente un intervalle de temps
type TimeRange struct {
    Start time.Time ``json:"start,omitempty"``
    End   time.Time ``json:"end,omitempty"``
}

// ContextualMemoryManager interface principale
type ContextualMemoryManager interface {
    interfaces.BaseManager
    
    // Indexation
    CaptureAction(ctx context.Context, action Action) error
    BatchCaptureActions(ctx context.Context, actions []Action) error
    
    // Recherche
    SearchContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
    GetActionHistory(ctx context.Context, workspacePath string, limit int) ([]Action, error)
    
    // Sessions
    StartSession(ctx context.Context, workspacePath string) (string, error)
    EndSession(ctx context.Context, sessionID string) error
    GetSessionActions(ctx context.Context, sessionID string) ([]Action, error)
    
    // Analyse
    AnalyzePatternsUsage(ctx context.Context, workspacePath string) (map[string]interface{}, error)
    GetSimilarActions(ctx context.Context, actionID string, limit int) ([]ContextResult, error)
}

// IndexManager interface pour l'indexation
type IndexManager interface {
    interfaces.BaseManager
    IndexAction(ctx context.Context, action Action) error
    SearchSimilar(ctx context.Context, vector []float64, limit int) ([]SimilarResult, error)
    CacheEmbedding(ctx context.Context, text string, vector []float64) error
    GetCacheStats(ctx context.Context) (map[string]interface{}, error)
}

// RetrievalManager interface pour la récupération
type RetrievalManager interface {
    interfaces.BaseManager
    QueryContext(ctx context.Context, query ContextQuery) ([]ContextResult, error)
    GetActionMetadata(ctx context.Context, actionID string) (*Action, error)
    SearchByText(ctx context.Context, text string, workspacePath string, limit int) ([]ContextResult, error)
    GetActionsBySession(ctx context.Context, sessionID string) ([]Action, error)
}

// IntegrationManager interface pour les intégrations externes
type IntegrationManager interface {
    interfaces.BaseManager
    NotifyMCPGateway(ctx context.Context, event ContextEvent) error
    TriggerN8NWorkflow(ctx context.Context, workflowID string, data interface{}) error
    SyncToMCPDatabase(ctx context.Context, actions []Action) error
    SendWebhook(ctx context.Context, url string, payload interface{}) error
}

// Types de support
type SimilarResult struct {
    ID    string  ``json:"id"``
    Score float64 ``json:"score"``
}

type ContextEvent struct {
    Action    Action                 ``json:"action"``
    Context   map[string]interface{} ``json:"context"``
    Timestamp time.Time              ``json:"timestamp"``
}
"@

   "$basePath/development/contextual_memory_manager.go"               = @"
package development

import (
    "context"
    "fmt"
    
    "github.com/email-sender/development/managers/contextual-memory-manager/interfaces"
    baseInterfaces "github.com/email-sender/development/managers/interfaces"
)

type contextualMemoryManagerImpl struct {
    indexManager       interfaces.IndexManager
    retrievalManager   interfaces.RetrievalManager
    integrationManager interfaces.IntegrationManager
    storageManager     baseInterfaces.StorageManager
    errorManager       baseInterfaces.ErrorManager
    configManager      baseInterfaces.ConfigManager
    initialized        bool
}

// NewContextualMemoryManager crée une nouvelle instance du manager
func NewContextualMemoryManager(
    sm baseInterfaces.StorageManager,
    em baseInterfaces.ErrorManager,
    cm baseInterfaces.ConfigManager,
) interfaces.ContextualMemoryManager {
    return &contextualMemoryManagerImpl{
        storageManager: sm,
        errorManager:   em,
        configManager:  cm,
        initialized:    false,
    }
}

func (cmm *contextualMemoryManagerImpl) Initialize(ctx context.Context) error {
    if cmm.initialized {
        return nil
    }
    
    // Initialiser les sous-managers
    // TODO: Implémenter l'initialisation des sous-managers
    
    cmm.initialized = true
    return nil
}

func (cmm *contextualMemoryManagerImpl) HealthCheck(ctx context.Context) error {
    if !cmm.initialized {
        return fmt.Errorf("manager not initialized")
    }
    
    // TODO: Vérifier la santé des sous-composants
    return nil
}

func (cmm *contextualMemoryManagerImpl) Cleanup() error {
    // TODO: Nettoyer les ressources
    return nil
}

func (cmm *contextualMemoryManagerImpl) CaptureAction(ctx context.Context, action interfaces.Action) error {
    if !cmm.initialized {
        return fmt.Errorf("manager not initialized")
    }
    
    // TODO: Implémenter la capture d'action
    return fmt.Errorf("not implemented")
}

func (cmm *contextualMemoryManagerImpl) SearchContext(ctx context.Context, query interfaces.ContextQuery) ([]interfaces.ContextResult, error) {
    if !cmm.initialized {
        return nil, fmt.Errorf("manager not initialized")
    }
    
    // TODO: Implémenter la recherche contextuelle
    return nil, fmt.Errorf("not implemented")
}

// TODO: Implémenter les autres méthodes de l'interface
"@

   "$basePath/README.md"                                              = @"
# Contextual Memory Manager

Gestionnaire de mémoire contextuelle pour IDE, permettant de capturer, indexer et récupérer les actions utilisateur avec recherche vectorielle.

## Description

Le Contextual Memory Manager fait partie de l'écosystème des managers du projet EMAIL_SENDER_1. Il fournit :

- **Capture d'actions** : Indexation en temps réel des actions utilisateur
- **Recherche contextuelle** : Recherche vectorielle et textuelle avec Qdrant et PostgreSQL
- **Cache intelligent** : Utilisation de SQLiteEmbeddingCache pour les performances
- **Intégrations** : MCP Gateway, N8N workflows
- **Monitoring** : Métriques Prometheus intégrées

## Architecture

```
ContextualMemoryManager
├── IndexManager (Qdrant + SQLite Cache)
├── RetrievalManager (PostgreSQL + Recherche hybride)
├── IntegrationManager (MCP Gateway + N8N)
└── MonitoringManager (Métriques + Health checks)
```

## Installation

```powershell
# Depuis la racine du projet
./scripts/Install-ContextualMemorySystem.ps1 -Environment dev -InitializeDatabase
```

## Utilisation

```go
// Initialisation
cm := NewContextualMemoryManager(storageManager, errorManager, configManager)
err := cm.Initialize(context.Background())

// Capture d'action
action := Action{
    Type: "command",
    Text: "git commit -m 'Add feature'",
    WorkspacePath: "/path/to/project",
}
err = cm.CaptureAction(context.Background(), action)

// Recherche contextuelle
query := ContextQuery{
    Text: "git commit",
    Limit: 10,
}
results, err := cm.SearchContext(context.Background(), query)
```

## Configuration

Voir `config/environments/` pour les configurations par environnement.

## Tests

```bash
go test ./... -v
go test ./... -cover
```

## Intégration

Ce manager s'intègre avec :
- **StorageManager** : Connexions PostgreSQL et Qdrant
- **ErrorManager** : Gestion centralisée des erreurs
- **ConfigManager** : Configuration centralisée
- **MCP Gateway** : Base SQLite pour synchronisation
- **SQLiteEmbeddingCache** : Cache des embeddings

## API

- `POST /api/v1/actions` - Capturer une action
- `GET /api/v1/search` - Recherche contextuelle
- `GET /api/v1/health` - Health check
- `GET /api/v1/metrics` - Métriques Prometheus

## Monitoring

- Latence d'indexation < 50ms
- Latence de recherche < 100ms
- Disponibilité > 99.5%
- Cache hit rate > 80%
"@

   "$basePath/migrations/postgresql/001_create_contextual_tables.sql" = @"
-- Migration 001: Tables de base pour le système de mémoire contextuelle

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

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_contextual_actions_type_timestamp ON contextual_actions(action_type, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_workspace ON contextual_actions(workspace_path);
CREATE INDEX IF NOT EXISTS idx_contextual_actions_text_gin ON contextual_actions USING gin(to_tsvector('english', action_text));
CREATE INDEX IF NOT EXISTS idx_contextual_embeddings_action ON contextual_embeddings(action_id);
"@

   "$basePath/Dockerfile"                                             = @"
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o contextual-memory-manager ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/contextual-memory-manager .
COPY --from=builder /app/config ./config
COPY --from=builder /app/migrations ./migrations

EXPOSE 8080
CMD ["./contextual-memory-manager"]
"@

   "$basePath/.gitignore"                                             = @"
# Binaires
contextual-memory-manager
*.exe
*.exe~
*.dll
*.so
*.dylib

# Données de test
*.db
*.sqlite
*.sqlite3

# Logs
*.log
logs/

# Cache
.cache/
cache/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Données sensibles
.env
.env.local
*.key
*.pem
"@
}

# Créer les fichiers
Write-Host "Création des fichiers de base..." -ForegroundColor Yellow

foreach ($filePath in $files.Keys) {
   if ($DryRun) {
      Write-Host "  [DRY-RUN] Créerait: $filePath" -ForegroundColor Gray
   }
   else {
      $content = $files[$filePath]
      $dir = Split-Path $filePath -Parent
      if (!(Test-Path $dir)) {
         New-Item -ItemType Directory -Force -Path $dir | Out-Null
      }
      Set-Content -Path $filePath -Value $content -Encoding UTF8
      Write-Host "  ✓ $filePath" -ForegroundColor Green
   }
}

# Créer les fichiers de test si demandé
if ($CreateTests -and !$DryRun) {
   Write-Host "Création des fichiers de test..." -ForegroundColor Yellow
    
   $testContent = @"
package tests

import (
    "context"
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    
    "github.com/email-sender/development/managers/contextual-memory-manager/development"
    "github.com/email-sender/development/managers/contextual-memory-manager/interfaces"
)

func TestContextualMemoryManager_Initialize(t *testing.T) {
    // TODO: Implémenter test d'initialisation
    t.Skip("Test à implémenter")
}

func TestContextualMemoryManager_CaptureAction(t *testing.T) {
    // TODO: Implémenter test de capture d'action
    t.Skip("Test à implémenter")
}

func TestContextualMemoryManager_SearchContext(t *testing.T) {
    // TODO: Implémenter test de recherche contextuelle
    t.Skip("Test à implémenter")
}
"@
    
   Set-Content -Path "$basePath/tests/unit/contextual_memory_manager_test.go" -Value $testContent -Encoding UTF8
   Write-Host "  ✓ Tests unitaires créés" -ForegroundColor Green
}

# Résumé
Write-Host "`nStructure du Contextual Memory Manager créée avec succès!" -ForegroundColor Green
Write-Host "Répertoire racine: $basePath" -ForegroundColor Cyan

if (!$DryRun) {
   Write-Host "`nProchaines étapes:" -ForegroundColor Yellow
   Write-Host "1. cd $basePath" -ForegroundColor White
   Write-Host "2. go mod tidy" -ForegroundColor White
   Write-Host "3. go test ./..." -ForegroundColor White
   Write-Host "4. Implémenter les interfaces dans development/" -ForegroundColor White
   Write-Host "5. Configurer l'environnement avec Install-ContextualMemorySystem.ps1" -ForegroundColor White
}
else {
   Write-Host "`nUtilisez -DryRun:`$false pour créer réellement les fichiers" -ForegroundColor Yellow
}
