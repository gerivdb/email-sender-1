# Référence API

## Vue d'Ensemble

L'API Planning Ecosystem Sync expose un ensemble d'endpoints REST pour la synchronisation, validation et monitoring des plans de développement. L'API suit les principes RESTful et retourne des données au format JSON.

**Base URL :** `http://localhost:8080/api/v1`
**Authentication :** Bearer Token ou API Key
**Rate Limiting :** 1000 req/min par clé API

## Authentication

### Obtenir un Token
```http
POST /api/v1/auth/token
Content-Type: application/json

{
    "username": "sync_user",
    "password": "your_password"
}
```

**Response :**
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "token_type": "Bearer"
}
```

### Utilisation du Token
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Endpoints Synchronisation

### Synchroniser Markdown vers Système Dynamique
```http
POST /api/v1/sync/markdown-to-dynamic
Content-Type: application/json
Authorization: Bearer <token>

{
    "plan_path": "roadmaps/plans/plan-dev-v55-planning-ecosystem-sync.md",
    "options": {
        "validate_first": true,
        "create_backup": true,
        "force_sync": false,
        "conflict_strategy": "manual"
    }
}
```

**Response Success (202) :**
```json
{
    "job_id": "sync-job-123456",
    "status": "started",
    "estimated_duration": "45s",
    "created_at": "2025-06-12T14:30:22Z",
    "options": {
        "validate_first": true,
        "create_backup": true,
        "force_sync": false,
        "conflict_strategy": "manual"
    }
}
```

### Synchroniser Système Dynamique vers Markdown
```http
POST /api/v1/sync/dynamic-to-markdown
Content-Type: application/json

{
    "plan_id": "uuid-plan-123",
    "target_path": "roadmaps/plans/plan-dev-updated.md",
    "options": {
        "preserve_formatting": true,
        "update_metadata": true
    }
}
```

### Statut d'un Job de Synchronisation
```http
GET /api/v1/sync/jobs/{job_id}
```

**Response :**
```json
{
    "job_id": "sync-job-123456",
    "status": "completed",
    "progress": 100,
    "started_at": "2025-06-12T14:30:22Z",
    "completed_at": "2025-06-12T14:31:07Z",
    "duration": "45s",
    "result": {
        "plans_synced": 1,
        "tasks_processed": 247,
        "conflicts_detected": 0,
        "warnings": []
    }
}
```

### Synchronisation en Lot
```http
POST /api/v1/sync/batch
Content-Type: application/json

{
    "plans": [
        {
            "path": "roadmaps/plans/plan-dev-v48.md",
            "priority": "high"
        },
        {
            "path": "roadmaps/plans/plan-dev-v49.md", 
            "priority": "normal"
        }
    ],
    "options": {
        "parallel_workers": 4,
        "stop_on_error": false
    }
}
```

## Endpoints Validation

### Valider un Plan
```http
GET /api/v1/validate/plan/{plan_id}
```

**Response :**
```json
{
    "plan_id": "uuid-plan-123",
    "is_valid": true,
    "validation_score": 0.95,
    "errors": [],
    "warnings": [
        {
            "code": "MINOR_INCONSISTENCY", 
            "message": "Minor inconsistency in progress calculation",
            "location": "Phase 3.2",
            "severity": "low"
        }
    ],
    "metadata": {
        "total_tasks": 247,
        "completed_tasks": 231,
        "phases_count": 8,
        "estimated_completion": "2025-06-20"
    }
}
```

### Validation par Fichier
```http
POST /api/v1/validate/file
Content-Type: multipart/form-data

file: <plan.md>
options: {"strict_mode": true, "schema_version": "v55"}
```

### Validation en Lot
```http
POST /api/v1/validate/batch
Content-Type: application/json

{
    "paths": [
        "roadmaps/plans/",
        "specific/plan.md"
    ],
    "options": {
        "recursive": true,
        "parallel": true,
        "fail_fast": false
    }
}
```

## Endpoints Conflits

### Lister Conflits Actifs
```http
GET /api/v1/conflicts/active?page=1&limit=20&severity=high
```

**Response :**
```json
{
    "conflicts": [
        {
            "id": "conflict-789",
            "plan_path": "roadmaps/plans/plan-dev-v48.md",
            "type": "content_divergence",
            "severity": "medium",
            "detected_at": "2025-06-12T14:25:30Z",
            "source_modified": "2025-06-12T14:20:15Z",
            "target_modified": "2025-06-12T14:22:45Z",
            "affected_sections": ["Phase 3.2", "Phase 4.1"],
            "auto_resolvable": false
        }
    ],
    "pagination": {
        "total": 1,
        "page": 1,
        "per_page": 20,
        "total_pages": 1
    }
}
```

### Détails d'un Conflit
```http
GET /api/v1/conflicts/{conflict_id}
```

**Response :**
```json
{
    "id": "conflict-789",
    "plan_path": "roadmaps/plans/plan-dev-v48.md",
    "type": "content_divergence",
    "details": {
        "source_content": "## Phase 3.2: Implementation...",
        "target_content": "## Phase 3.2: Enhanced Implementation...",
        "diff": "@@ -1,3 +1,3 @@\n-Implementation\n+Enhanced Implementation"
    },
    "resolution_options": [
        {
            "strategy": "use_source",
            "description": "Keep Markdown version",
            "impact": "low"
        },
        {
            "strategy": "use_target", 
            "description": "Keep dynamic system version",
            "impact": "medium"
        },
        {
            "strategy": "merge",
            "description": "Intelligent merge",
            "impact": "low",
            "confidence": 0.85
        }
    ]
}
```

### Résoudre un Conflit
```http
POST /api/v1/conflicts/{conflict_id}/resolve
Content-Type: application/json

{
    "strategy": "merge",
    "custom_resolution": null,
    "comment": "Merging enhanced implementation details"
}
```

## Endpoints Monitoring

### État de Santé Général
```http
GET /api/v1/health
```

**Response :**
```json
{
    "status": "healthy",
    "timestamp": "2025-06-12T14:30:22Z",
    "services": {
        "database": {
            "postgres": "healthy",
            "qdrant": "healthy"
        },
        "sync_engine": "healthy",
        "validation_service": "healthy"
    },
    "metrics": {
        "active_syncs": 2,
        "pending_conflicts": 0,
        "last_sync": "2025-06-12T14:28:15Z"
    }
}
```

### Métriques Performance
```http
GET /api/v1/metrics?period=1h&granularity=5m
```

**Response :**
```json
{
    "period": "1h",
    "metrics": {
        "sync_operations": {
            "total": 24,
            "successful": 23,
            "failed": 1,
            "avg_duration": "32s"
        },
        "performance": {
            "cpu_usage": 15.2,
            "memory_usage": 68.5,
            "disk_io": 1.2
        },
        "database": {
            "postgres_connections": 8,
            "qdrant_operations": 156
        }
    },
    "time_series": [
        {
            "timestamp": "2025-06-12T13:30:00Z",
            "sync_count": 2,
            "avg_duration": 28.5
        }
    ]
}
```

### Logs Système
```http
GET /api/v1/logs?level=error&since=1h&limit=50
```

## Endpoints Plans

### Lister Plans
```http
GET /api/v1/plans?status=active&sort=modified_desc&page=1&limit=20
```

### Détails d'un Plan
```http
GET /api/v1/plans/{plan_id}
```

**Response :**
```json
{
    "id": "uuid-plan-123",
    "title": "Plan de développement v55 - Écosystème de Synchronisation",
    "version": "2.5",
    "status": "active",
    "progress": 85.2,
    "phases": [
        {
            "id": "phase-1",
            "title": "Analyse et Conception",
            "progress": 100,
            "tasks_count": 32,
            "completed_tasks": 32
        }
    ],
    "metadata": {
        "created_at": "2025-06-01T10:00:00Z",
        "modified_at": "2025-06-12T14:25:30Z",
        "author": "Planning Team",
        "priority": "critical"
    }
}
```

### Historique des Modifications
```http
GET /api/v1/plans/{plan_id}/history?limit=10
```

## SDK et Clients

### SDK Go
```go
package main

import (
    "github.com/planning-ecosystem/sync-client-go"
)

func main() {
    client := sync.NewClient(&sync.Config{
        BaseURL: "http://localhost:8080/api/v1",
        Token:   "your-token-here",
    })
    
    // Synchroniser un plan
    job, err := client.SyncMarkdownToDynamic(&sync.SyncRequest{
        PlanPath: "roadmaps/plans/plan-dev-v55.md",
        Options: sync.SyncOptions{
            ValidateFirst: true,
            CreateBackup:  true,
        },
    })
    
    // Attendre completion
    result, err := client.WaitForJob(job.JobID, 60*time.Second)
}
```

### Client JavaScript/Node.js
```javascript
const { PlanningEcosystemClient } = require('@planning-ecosystem/sync-client');

const client = new PlanningEcosystemClient({
    baseURL: 'http://localhost:8080/api/v1',
    token: 'your-token-here'
});

// Synchroniser un plan
const job = await client.syncMarkdownToDynamic({
    planPath: 'roadmaps/plans/plan-dev-v55.md',
    options: {
        validateFirst: true,
        createBackup: true
    }
});

// Surveiller le progress
const result = await client.waitForJob(job.jobId, { timeout: 60000 });
```

### Client Python
```python
from planning_ecosystem import SyncClient

client = SyncClient(
    base_url="http://localhost:8080/api/v1",
    token="your-token-here"
)

# Synchroniser un plan
job = client.sync_markdown_to_dynamic(
    plan_path="roadmaps/plans/plan-dev-v55.md",
    options={
        "validate_first": True,
        "create_backup": True
    }
)

# Attendre completion
result = client.wait_for_job(job.job_id, timeout=60)
```

## Codes d'Erreur

| Code | Message | Description |
|------|---------|-------------|
| 400 | Bad Request | Paramètres invalides |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Permissions insuffisantes |
| 404 | Not Found | Ressource inexistante |
| 409 | Conflict | Conflit de synchronisation |
| 422 | Validation Error | Erreur de validation des données |
| 429 | Rate Limit Exceeded | Limite de requêtes dépassée |
| 500 | Internal Server Error | Erreur serveur interne |
| 503 | Service Unavailable | Service temporairement indisponible |

## Limites et Quotas

| Ressource | Limite |
|-----------|--------|
| Requêtes par minute | 1000 |
| Taille fichier plan | 10 MB |
| Plans par sync batch | 50 |
| Jobs simultanés | 10 |
| Retention logs | 30 jours |
| Retention métriques | 90 jours |

## Webhooks

### Configuration Webhook
```http
POST /api/v1/webhooks
Content-Type: application/json

{
    "url": "https://your-app.com/webhooks/planning-sync",
    "events": ["sync.completed", "conflict.detected", "validation.failed"],
    "secret": "webhook-secret-key"
}
```

### Événements Webhook

**sync.completed**
```json
{
    "event": "sync.completed",
    "timestamp": "2025-06-12T14:31:07Z",
    "data": {
        "job_id": "sync-job-123456",
        "plan_path": "roadmaps/plans/plan-dev-v55.md",
        "duration": "45s",
        "tasks_processed": 247
    }
}
```

**conflict.detected**
```json
{
    "event": "conflict.detected", 
    "timestamp": "2025-06-12T14:25:30Z",
    "data": {
        "conflict_id": "conflict-789",
        "plan_path": "roadmaps/plans/plan-dev-v48.md",
        "severity": "medium",
        "auto_resolvable": false
    }
}
```
