# 📚 Documentation Technique Complète - Infrastructure Hybride N8N/Go

## 1. Architecture Générale

```
N8N Workflow → GoCliExecutor Node → Parameter Bridge → Async Queue → Go CLI/Manager
      ↓               ↓                     ↓              ↓           ↓
  User Input → Type Conversion → Validation → Job Queue → Execution → Results
      ↓               ↓                     ↓              ↓           ↓
  Trace ID → Correlation ID → Transform → Priority → Worker → Response
```

## 2. Composants Principaux

### 2.1 Node N8N Custom (`n8n-custom-nodes/GoCliExecutor.node.ts`)

- Exécution de commandes Go CLI et workflows Go
- Modes : `execute`, `workflow`, `validate`
- Supporte paramètres dynamiques, options avancées, tracing

### 2.2 Parameter Bridge (`pkg/bridge/parameter_bridge.go`)

- Conversion typée et validation des paramètres N8N → Go
- Types supportés : string, int, float64, bool, array, object
- Règles de validation : email, URL, port, custom

### 2.3 Async Queue System (`pkg/queue/async_queue_system.go`)

- Multi-queue, 4 priorités, worker pools dynamiques
- Retry logic, monitoring, event system
- Métriques temps réel, scaling horizontal

### 2.4 N8N Manager (`pkg/managers/n8n_manager_simple.go`)

- Orchestration des workflows, gestion du lifecycle, monitoring
- API REST pour exécution, status, logs, metrics

## 3. Tests & Validation

### 3.1 Tests d’Intégration (`tests/integration/n8n_go_integration_test.go`)

- End-to-end : N8N → Bridge → Queue → Go → Results
- Vérification propagation TraceID/CorrelationID
- Validation des métriques, erreurs, outputs

### 3.2 Tests Performance (`tests/performance/performance_load_test.go`)

- 1000 jobs, 50 concurrents, mesure throughput/latence
- Critères : >98% succès, <2s latence moyenne

### 3.3 Compatibilité Plateforme (`tests/compatibility/cross_platform_compat_test.sh`)

- Vérification CLI, API, N8N sur Linux/Windows/Mac
- Contrôle UI sur Chrome, Firefox, Edge, Safari

### 3.4 Sécurité (`tests/security/security_scan.sh`)

- Scan ports, headers, vulnérabilités (nmap, nikto, ZAP)
- Fuzzing endpoints, vérification headers HTTP

## 4. Déploiement & Configuration

### 4.1 Déploiement

- **Go CLI/API** : `cli.exe`, `api-server.exe`
- **N8N** : Installer le node custom, configurer endpoints
- **Queue** : Configurable via `pkg/queue/QueueConfig`
- **Manager** : Configurable via `pkg/managers/N8NManagerConfig`

### 4.2 Configuration Exemple

```yaml
n8n_manager:
  name: "prod-manager"
  version: "1.0.0"
  max_concurrency: 50
  default_timeout: 30s
  heartbeat_interval: 5s
  cli_path: "email-sender"
  cli_timeout: 30s
  cli_retries: 2
  default_queue: "main"
  queue_workers:
    main: 10
  enable_metrics: true
  enable_tracing: true
  log_level: "info"
  metrics_interval: 1s
```

## 5. Monitoring & Observabilité

- **Métriques** : `/api/v1/metrics` (Go), `/rest/metrics` (N8N)
- **Logs** : `/api/v1/logs`, `/rest/logs`
- **Events** : Système d’abonnement via channels Go

## 6. Sécurité

- **Headers HTTP** : X-Frame-Options, Content-Security-Policy, etc.
- **Authentification** : API Key, JWT (à intégrer)
- **Audit Logs** : Traçabilité complète via TraceID/CorrelationID
- **Tests** : Scripts automatisés + recommandations ZAP/Burp

## 7. Extensibilité

- **Ajout de types de jobs** : Étendre `pkg/queue/JobType`
- **Custom validation** : Ajouter dans `ParameterBridge`
- **Nouveaux nodes N8N** : Copier/adapter `GoCliExecutor.node.ts`
- **Monitoring avancé** : Brancher Prometheus/Grafana sur `/metrics`

## 8. FAQ & Dépannage

- **Problème de queue pleine** : Augmenter `queue_capacity` ou workers
- **Erreur de conversion paramètre** : Vérifier types dans N8N
- **Timeouts** : Adapter `job_timeout`, `default_timeout`
- **Logs manquants** : Vérifier niveau de logs (`log_level`)
- **Sécurité** : Scanner régulièrement avec ZAP/Nikto

---

**Contact technique** : <devops@votre-entreprise.com>  
**Dernière mise à jour** : 2025-06-19
