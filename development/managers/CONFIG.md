# 🔧 Configuration de l'Écosystème des Managers
# Version: 1.0.0
# Date: 7 juin 2025

## Configuration Globale

### Structure des Répertoires
```
development/managers/
├── interfaces/                 # Interfaces communes à tous les managers
├── git-workflow-manager/       # ✅ Implémenté et testé
├── dependency-manager/         # 🚀 À développer
├── security-manager/           # 🚀 À développer
├── storage-manager/            # 🚀 À développer
├── email-manager/              # 🚀 À développer
├── notification-manager/       # 🚀 À développer
├── integration-manager/        # 🚀 À développer
├── tools/                      # Outils partagés et utilitaires
├── examples/                   # Exemples d'utilisation
├── docs/                       # Documentation détaillée
└── tests/                      # Tests d'intégration
```

### Variables d'Environnement Requises

#### Configuration Base de Données
```bash
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=email_sender_dev
POSTGRES_USER=email_sender
POSTGRES_PASSWORD=your_password

# Qdrant (Vector Database)
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_API_KEY=your_api_key

# Redis (Cache)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
```

#### Configuration APIs Externes
```bash
# GitHub API
GITHUB_TOKEN=your_github_token
GITHUB_OWNER=your_org
GITHUB_REPO=email-sender

# Email Services
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_email
SMTP_PASSWORD=your_password

# SendGrid (optionnel)
SENDGRID_API_KEY=your_sendgrid_key

# Slack Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
SLACK_CHANNEL=#dev-notifications

# Discord (optionnel)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
```

#### Configuration Logging et Monitoring
```bash
# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_FILE_PATH=./logs/managers.log

# Monitoring
METRICS_ENABLED=true
METRICS_PORT=9090
HEALTH_CHECK_INTERVAL=30s

# Tracing (optionnel)
JAEGER_ENDPOINT=http://localhost:14268/api/traces
```

### Configuration des Managers

#### Git Workflow Manager ✅
```yaml
git_workflow:
  enabled: true
  default_branch: "main"
  development_branch: "dev"
  feature_prefix: "feature/"
  hotfix_prefix: "hotfix/"
  release_prefix: "release/"
  
  branch_protection:
    enabled: true
    require_reviews: 2
    require_status_checks: true
    
  auto_merge:
    enabled: false
    require_all_checks: true
```

#### Dependency Manager 🚀
```yaml
dependency_manager:
  enabled: true
  scan_interval: "24h"
  auto_update: false
  security_scan: true
  
  vulnerability_check:
    enabled: true
    severity_threshold: "medium"
    auto_fix: false
    
  package_managers:
    - go
    - npm
    - pip
    - composer
```

#### Security Manager 🚀
```yaml
security_manager:
  enabled: true
  audit_interval: "12h"
  encryption_algorithm: "AES-256-GCM"
  
  audit_rules:
    - sensitive_data_exposure
    - weak_authentication
    - sql_injection
    - xss_vulnerabilities
    
  compliance:
    gdpr: true
    hipaa: false
    pci_dss: false
```

#### Storage Manager 🚀
```yaml
storage_manager:
  enabled: true
  
  postgresql:
    pool_size: 20
    max_connections: 100
    connection_timeout: "30s"
    
  qdrant:
    collection_name: "email_embeddings"
    vector_size: 384
    distance_metric: "cosine"
    
  redis:
    db: 0
    pool_size: 10
    idle_timeout: "240s"
    
  backup:
    enabled: true
    interval: "6h"
    retention_days: 30
```

#### Email Manager 🚀
```yaml
email_manager:
  enabled: true
  provider: "smtp"  # smtp, sendgrid, mailgun
  
  queue:
    max_retries: 3
    retry_delay: "5m"
    batch_size: 100
    
  templates:
    directory: "./templates"
    cache_enabled: true
    
  analytics:
    track_opens: true
    track_clicks: true
    bounce_handling: true
```

#### Notification Manager 🚀
```yaml
notification_manager:
  enabled: true
  
  channels:
    slack:
      enabled: true
      default_channel: "#notifications"
      
    discord:
      enabled: false
      
    webhook:
      enabled: true
      timeout: "10s"
      
  rules:
    - type: "error"
      channels: ["slack", "webhook"]
      severity: "high"
      
    - type: "warning"
      channels: ["slack"]
      severity: "medium"
```

#### Integration Manager 🚀
```yaml
integration_manager:
  enabled: true
  
  api_gateway:
    port: 8080
    rate_limit: "100/m"
    timeout: "30s"
    
  external_apis:
    github:
      base_url: "https://api.github.com"
      timeout: "15s"
      
    stripe:
      enabled: false
      
  data_transformation:
    enabled: true
    max_payload_size: "10MB"
```

### Standards de Développement

#### Conventions de Code Go
```go
// Structure type standard pour tous les managers
type Manager struct {
    config     *Config
    logger     Logger
    metrics    MetricsCollector
    healthChk  HealthChecker
    ctx        context.Context
    cancel     context.CancelFunc
}

// Interface standard que tous les managers doivent implémenter
type BaseManager interface {
    Initialize(ctx context.Context) error
    Start() error
    Stop() error
    HealthCheck(ctx context.Context) error
    GetMetrics() map[string]interface{}
    Cleanup() error
}
```

#### Tests Standards
```go
// Test structure standard
func TestManager_Implementation(t *testing.T) {
    // Setup
    manager := NewManager(config)
    
    // Test interface implementation
    var _ BaseManager = manager
    
    // Test lifecycle
    require.NoError(t, manager.Initialize(context.Background()))
    require.NoError(t, manager.Start())
    require.NoError(t, manager.HealthCheck(context.Background()))
    require.NoError(t, manager.Stop())
    require.NoError(t, manager.Cleanup())
}
```

#### Documentation Standards
- Chaque manager doit avoir un README.md détaillé
- Toutes les fonctions publiques doivent avoir des commentaires GoDoc
- Les exemples d'utilisation doivent être fournis
- Les métriques et alertes doivent être documentées

### Métriques et Monitoring

#### Métriques Standard par Manager
```go
type ManagerMetrics struct {
    RequestsTotal     int64         `json:"requests_total"`
    RequestsSucceeded int64         `json:"requests_succeeded"`
    RequestsFailed    int64         `json:"requests_failed"`
    ResponseTime      time.Duration `json:"avg_response_time"`
    MemoryUsage       int64         `json:"memory_usage_bytes"`
    GoroutinesCount   int           `json:"goroutines_count"`
    
    // Métriques spécifiques par manager
    ManagerSpecific   map[string]interface{} `json:"manager_specific"`
}
```

#### Health Checks Standards
```go
type HealthStatus struct {
    Status      string            `json:"status"`      // "healthy", "degraded", "unhealthy"
    Version     string            `json:"version"`
    Uptime      time.Duration     `json:"uptime"`
    LastCheck   time.Time         `json:"last_check"`
    Components  map[string]string `json:"components"`  // Component name -> status
    Details     map[string]interface{} `json:"details,omitempty"`
}
```

### Déploiement et CI/CD

#### Pipeline de Build Standard
```yaml
# .github/workflows/manager-ci.yml
name: Manager CI/CD
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.22'
      - run: go test ./development/managers/...
      
  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - run: go build ./development/managers/...
      
  security:
    runs-on: ubuntu-latest
    steps:
      - run: gosec ./development/managers/...
```

### Scripts de Maintenance

#### Script de Backup
```bash
#!/bin/bash
# backup-managers.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/managers_$DATE"

mkdir -p $BACKUP_DIR
pg_dump $POSTGRES_DB > $BACKUP_DIR/postgres.sql
redis-cli --rdb $BACKUP_DIR/redis.rdb
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
```

#### Script de Health Check Global
```bash
#!/bin/bash
# health-check-all.sh
for manager in git-workflow dependency security storage email notification integration; do
    echo "Checking $manager..."
    curl -f http://localhost:8080/health/$manager || echo "❌ $manager unhealthy"
done
```

---

**Auteur:** Équipe Développement Email Sender Manager  
**Dernière mise à jour:** 7 juin 2025  
**Version:** 1.0.0
