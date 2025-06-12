# Architecture du Système de Synchronisation

## Vue d'Ensemble

Le Planning Ecosystem Sync est un système distribué conçu pour maintenir la cohérence entre les plans de développement Markdown statiques et un système de gestion dynamique (TaskMaster CLI + QDrant + PostgreSQL).

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Planning Ecosystem Sync                         │
├─────────────────┬───────────────────────┬─────────────────────────┤
│   Markdown      │     Sync Engine       │    Dynamic System       │
│   Plans Layer   │     (Core)            │    Layer                │
│                 │                       │                         │
│  ┌───────────┐  │  ┌─────────────────┐  │  ┌─────────────────┐    │
│  │ Plan      │  │  │ Parser          │  │  │ QDrant Vector   │    │
│  │ Files     │◄─┼─►│ ├─ Structure     │◄─┼─►│ Database        │    │
│  │ (.md)     │  │  │ ├─ Metadata      │  │  │ └─ Semantic     │    │
│  │           │  │  │ └─ Validation    │  │  │    Search       │    │
│  └───────────┘  │  └─────────────────┘  │  └─────────────────┘    │
│                 │                       │                         │
│  ┌───────────┐  │  ┌─────────────────┐  │  ┌─────────────────┐    │
│  │ Git       │  │  │ Sync Controller │  │  │ PostgreSQL      │    │
│  │ Repository│◄─┼─►│ ├─ Bidirectional │◄─┼─►│ Database        │    │
│  │           │  │  │ ├─ Conflict Mgmt │  │  │ └─ Relational   │    │
│  │           │  │  │ └─ Change Track  │  │  │    Data         │    │
│  └───────────┘  │  └─────────────────┘  │  └─────────────────┘    │
│                 │           │           │                         │
│                 │           ▼           │  ┌─────────────────┐    │
│                 │  ┌─────────────────┐  │  │ TaskMaster CLI  │    │
│                 │  │ Validation      │  │  │ ├─ Binary       │    │
│                 │  │ Engine          │  │  │ ├─ TUI Interface│    │
│                 │  │ ├─ Schema Check  │  │  │ └─ API Layer    │    │
│                 │  │ ├─ Consistency   │  │  └─────────────────┘    │
│                 │  │ └─ Performance   │  │                         │
│                 │  └─────────────────┘  │                         │
└─────────────────┴───────────────────────┴─────────────────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │   Dashboard & API    │
                    │   ├─ Web UI (React)  │
                    │   ├─ REST API        │
                    │   ├─ WebSocket       │
                    │   ├─ Monitoring      │
                    │   └─ Real-time Alerts│
                    └──────────────────────┘
```

## Composants Principaux

### 1. Couche Plans Markdown

**Responsabilités :**
- Stockage des plans en format Markdown
- Versioning via Git
- Interface humaine pour édition

**Structure des Fichiers :**
```
roadmaps/plans/
├── consolidated/
│   ├── plan-dev-v55-planning-ecosystem-sync.md  # Plan principal
│   ├── plan-dev-v48.md                          # Plans historiques
│   └── ...
├── templates/
│   ├── plan-template-v55.md
│   └── phase-template.md
└── archived/
    └── old-plans/
```

**Format Standard :**
```markdown
# Plan de développement v55 - Titre
**Version X.Y - Date - Progression: Z%**

## Phase N: Nom de Phase
**Progression: X%**

### N.X Sous-section
- [x] Tâche complétée
- [ ] Tâche en cours
```

### 2. Moteur de Synchronisation (Sync Engine)

#### 2.1 Parser Module
```go
// Parsing des plans Markdown
type PlanParser struct {
    schemaValidator SchemaValidator
    metadataExtractor MetadataExtractor
    structureAnalyzer StructureAnalyzer
}

func (p *PlanParser) ParsePlan(filePath string) (*Plan, error) {
    // 1. Lecture fichier
    // 2. Extraction métadonnées
    // 3. Parsing structure hierarchique
    // 4. Validation schéma
    // 5. Calcul métriques
}
```

**Fonctionnalités :**
- Parsing Markdown avec extensions
- Extraction automatique métadonnées
- Détection structure hiérarchique
- Validation schéma v55
- Calcul progression automatique

#### 2.2 Sync Controller
```go
type SyncController struct {
    markdownRepo MarkdownRepository
    dynamicRepo  DynamicRepository
    conflictMgr  ConflictManager
    validator    ValidationEngine
}

func (s *SyncController) SyncMarkdownToDynamic(planPath string) error {
    // 1. Parse plan Markdown
    // 2. Validate structure
    // 3. Check for conflicts
    // 4. Transform to dynamic format
    // 5. Update dynamic system
    // 6. Record changes
}
```

**Algorithme de Synchronisation :**
1. **Detection des Changements**
   - Checksum MD5 des fichiers
   - Timestamp de modification
   - Git commit hash

2. **Analyse des Conflits**
   - Comparaison structurelle
   - Détection divergences contenu
   - Classification gravité

3. **Résolution Automatique**
   - Règles prédéfinies
   - ML pour patterns fréquents
   - Fallback vers résolution manuelle

#### 2.3 Conflict Manager
```go
type ConflictManager struct {
    detector     ConflictDetector
    resolver     ConflictResolver
    storage      ConflictStorage
    notifier     AlertManager
}

type Conflict struct {
    ID           string
    Type         ConflictType
    Severity     Severity
    Source       ConflictSource
    Target       ConflictTarget
    Resolution   ResolutionStrategy
    AutoResolve  bool
}
```

**Types de Conflits :**
- **Content Divergence :** Contenu modifié simultanément
- **Structure Change :** Modification structure hiérarchique
- **Metadata Mismatch :** Incohérence métadonnées
- **Progress Inconsistency :** Divergence calculs progression

### 3. Couche Système Dynamique

#### 3.1 QDrant Vector Database
```yaml
# Configuration QDrant
collections:
  plans:
    vector_size: 384        # Sentence transformers
    distance: cosine
    on_disk_payload: true
    
  tasks:
    vector_size: 384
    distance: cosine
    
  metadata:
    vector_size: 256
```

**Usage :**
- Recherche sémantique dans les plans
- Détection similarités tâches
- Clustering automatique phases
- Recommandations basées contenu

#### 3.2 PostgreSQL Database
```sql
-- Schema principal
CREATE TABLE plans (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    version VARCHAR(50),
    status plan_status,
    progress DECIMAL(5,2),
    metadata JSONB,
    created_at TIMESTAMP,
    modified_at TIMESTAMP,
    checksum VARCHAR(64)
);

CREATE TABLE phases (
    id UUID PRIMARY KEY,
    plan_id UUID REFERENCES plans(id),
    phase_number INTEGER,
    title VARCHAR(255),
    progress DECIMAL(5,2),
    metadata JSONB
);

CREATE TABLE tasks (
    id UUID PRIMARY KEY,
    phase_id UUID REFERENCES phases(id),
    description TEXT,
    status task_status,
    priority priority_level,
    created_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE TABLE sync_operations (
    id UUID PRIMARY KEY,
    operation_type sync_type,
    plan_id UUID,
    status operation_status,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    metadata JSONB
);
```

#### 3.3 TaskMaster CLI Integration
```go
type TaskMasterConnector struct {
    binaryPath   string
    apiEndpoint  string
    authToken    string
    httpClient   *http.Client
}

func (t *TaskMasterConnector) SyncPlan(plan *Plan) error {
    // 1. Convert plan to TaskMaster format
    // 2. Call TaskMaster API
    // 3. Update local cache
    // 4. Verify synchronization
}
```

### 4. Couche Validation

#### 4.1 Validation Engine
```go
type ValidationEngine struct {
    schemaValidator   SchemaValidator
    consistencyChecker ConsistencyChecker
    performanceTester  PerformanceTester
    businessRules     BusinessRuleEngine
}

type ValidationResult struct {
    IsValid     bool
    Score       float64
    Errors      []ValidationError
    Warnings    []ValidationWarning
    Metrics     ValidationMetrics
}
```

**Niveaux de Validation :**
1. **Schema :** Structure Markdown conforme
2. **Consistency :** Cohérence interne données
3. **Business Rules :** Règles métier spécifiques
4. **Performance :** Impact sur performance système

#### 4.2 Business Rules Engine
```yaml
# config/validation-rules.yaml
rules:
  progress_calculation:
    - rule: "phase_progress <= 100"
    - rule: "plan_progress = avg(phase_progress)"
    
  task_dependencies:
    - rule: "prerequisite_tasks_completed"
    - rule: "no_circular_dependencies"
    
  metadata_requirements:
    - rule: "version_format: vXX"
    - rule: "date_format: YYYY-MM-DD"
```

### 5. Dashboard et API

#### 5.1 Architecture Web
```
Frontend (React + TypeScript)
├── Dashboard Overview
├── Plan Management
├── Conflict Resolution
├── Performance Monitoring
└── Real-time Alerts

Backend (Go + Gin)
├── REST API
├── WebSocket Server  
├── Authentication
├── Rate Limiting
└── Monitoring Endpoints
```

#### 5.2 API Layer
```go
type APIServer struct {
    syncController    *SyncController
    validationEngine  *ValidationEngine
    conflictManager   *ConflictManager
    monitoringService *MonitoringService
}

// Routes principales
func (a *APIServer) setupRoutes() {
    v1 := a.router.Group("/api/v1")
    {
        sync := v1.Group("/sync")
        {
            sync.POST("/markdown-to-dynamic", a.SyncMarkdownToDynamic)
            sync.POST("/dynamic-to-markdown", a.SyncDynamicToMarkdown)
            sync.GET("/jobs/:id", a.GetSyncJob)
        }
        
        validate := v1.Group("/validate")
        {
            validate.GET("/plan/:id", a.ValidatePlan)
            validate.POST("/batch", a.ValidateBatch)
        }
    }
}
```

## Patterns Architecturaux

### 1. Event-Driven Architecture
```go
type EventBus struct {
    subscribers map[EventType][]EventHandler
    publisher   Publisher
}

// Événements système
type Event struct {
    Type      EventType
    Timestamp time.Time
    Data      interface{}
    Source    string
}

const (
    PlanModified EventType = "plan.modified"
    SyncStarted  EventType = "sync.started"
    ConflictDetected EventType = "conflict.detected"
    ValidationFailed EventType = "validation.failed"
)
```

### 2. Repository Pattern
```go
type PlanRepository interface {
    GetByID(id string) (*Plan, error)
    Save(plan *Plan) error
    List(filters PlanFilters) ([]*Plan, error)
    Delete(id string) error
}

type MarkdownPlanRepository struct {
    basePath string
    gitRepo  GitRepository
}

type DynamicPlanRepository struct {
    postgres *sql.DB
    qdrant   QDrantClient
}
```

### 3. Strategy Pattern (Conflict Resolution)
```go
type ConflictResolutionStrategy interface {
    Resolve(conflict *Conflict) (*Resolution, error)
    CanResolve(conflict *Conflict) bool
}

type AutoMergeStrategy struct{}
type SourcePriorityStrategy struct{}
type TargetPriorityStrategy struct{}
type ManualResolutionStrategy struct{}
```

## Monitoring et Observabilité

### 1. Métriques Principales
```go
var (
    syncOperationsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "sync_operations_total",
            Help: "Total number of sync operations",
        },
        []string{"type", "status"},
    )
    
    syncDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "sync_duration_seconds",
            Help: "Sync operation duration",
        },
        []string{"type"},
    )
    
    conflictsActive = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "conflicts_active_total",
            Help: "Number of active conflicts",
        },
        []string{"severity"},
    )
)
```

### 2. Logging Structure
```go
type StructuredLogger struct {
    logger *logrus.Logger
}

func (l *StructuredLogger) LogSyncOperation(op *SyncOperation) {
    l.logger.WithFields(logrus.Fields{
        "operation_id": op.ID,
        "type":         op.Type,
        "plan_id":      op.PlanID,
        "duration":     op.Duration,
        "status":       op.Status,
    }).Info("Sync operation completed")
}
```

### 3. Health Checks
```go
type HealthChecker struct {
    postgres PostgresHealthChecker
    qdrant   QDrantHealthChecker
    gitRepo  GitHealthChecker
}

func (h *HealthChecker) CheckHealth() HealthStatus {
    return HealthStatus{
        Status: "healthy",
        Services: map[string]ServiceHealth{
            "postgres": h.postgres.Check(),
            "qdrant":   h.qdrant.Check(),
            "git":      h.gitRepo.Check(),
        },
    }
}
```

## Sécurité

### 1. Authentication & Authorization
```go
type AuthMiddleware struct {
    tokenValidator TokenValidator
    rbac          RBACManager
}

type Permission struct {
    Resource string // "plans", "sync", "conflicts"
    Action   string // "read", "write", "admin"
}

type Role struct {
    Name        string
    Permissions []Permission
}
```

### 2. Input Validation
```go
type InputSanitizer struct {
    markdownSanitizer MarkdownSanitizer
    pathValidator     PathValidator
    schemaValidator   SchemaValidator
}

func (i *InputSanitizer) SanitizePlanContent(content string) (string, error) {
    // 1. Remove dangerous HTML
    // 2. Validate Markdown structure
    // 3. Check for injection patterns
    // 4. Normalize encoding
}
```

### 3. Audit Trail
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    user_id VARCHAR(255),
    action VARCHAR(100),
    resource_type VARCHAR(50),
    resource_id VARCHAR(255),
    timestamp TIMESTAMP,
    ip_address INET,
    details JSONB
);
```

## Performance et Scalabilité

### 1. Optimisations Base de Données
```sql
-- Index pour requêtes fréquentes
CREATE INDEX CONCURRENTLY idx_plans_status_modified 
ON plans(status, modified_at DESC);

CREATE INDEX CONCURRENTLY idx_tasks_phase_status 
ON tasks(phase_id, status);

-- Partitioning pour sync_operations
CREATE TABLE sync_operations_2025_06 PARTITION OF sync_operations
FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
```

### 2. Caching Strategy
```go
type CacheManager struct {
    redis      redis.Client
    localCache cache.Cache
}

func (c *CacheManager) GetPlan(id string) (*Plan, error) {
    // 1. Check local cache (1ms)
    // 2. Check Redis (5ms)
    // 3. Load from database (50ms)
}
```

### 3. Worker Pool Pattern
```go
type SyncWorkerPool struct {
    workers    int
    jobQueue   chan SyncJob
    resultChan chan SyncResult
    quit       chan bool
}

func (w *SyncWorkerPool) Start() {
    for i := 0; i < w.workers; i++ {
        go w.worker()
    }
}
```

## Déploiement et Infrastructure

### 1. Architecture de Déploiement
```yaml
# docker-compose.yml
version: '3.8'
services:
  sync-engine:
    image: planning-ecosystem/sync:latest
    replicas: 3
    
  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
  qdrant:
    image: qdrant/qdrant:latest
    volumes:
      - qdrant_data:/qdrant/storage
      
  redis:
    image: redis:7-alpine
    
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
```

### 2. Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: planning-sync
spec:
  replicas: 3
  selector:
    matchLabels:
      app: planning-sync
  template:
    spec:
      containers:
      - name: sync-engine
        image: planning-ecosystem/sync:v2.5.0
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

## Maintenance et Opérations

### 1. Backup Strategy
```bash
#!/bin/bash
# Backup quotidien automatisé

# PostgreSQL
pg_dump planning_sync | gzip > backup_$(date +%Y%m%d).sql.gz

# QDrant snapshots
curl -X POST "http://qdrant:6333/collections/plans/snapshots"

# Git repository
git bundle create backup_$(date +%Y%m%d).bundle --all
```

### 2. Monitoring Alerts
```yaml
# prometheus-alerts.yml
groups:
- name: planning-sync
  rules:
  - alert: SyncOperationFailed
    expr: rate(sync_operations_total{status="failed"}[5m]) > 0.1
    for: 2m
    
  - alert: HighConflictRate
    expr: conflicts_active_total > 10
    for: 5m
```

Cette architecture assure une haute disponibilité, une performance optimale et une maintenance simplifiée du système de synchronisation Planning Ecosystem.
