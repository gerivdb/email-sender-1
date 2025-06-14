# Guide de Troubleshooting EMAIL_SENDER_1 Go Native

## 🚨 Guide de Résolution de Problèmes

Ce guide fournit des solutions pour les problèmes courants rencontrés avec l'écosystème EMAIL_SENDER_1 Go Native.

## 📋 Diagnostic Rapide

### Scripts de Diagnostic Automatique

```bash
# Health check complet
./deployment/staging/health-check.ps1 -Detailed

# Validation écosystème
go run development/managers/ecosystem_validation.go

# Test de performance
go run development/managers/phase_4_performance_validation.go
```

## 🔧 Problèmes Courants et Solutions

### 1. Service ne Démarre Pas

#### Symptômes
- L'application ne répond pas sur le port 8080
- Erreur "connection refused" lors des health checks
- Container Docker s'arrête immédiatement

#### Diagnostic

```bash
# Vérifier les logs du service
docker logs email-sender-go

# Vérifier le statut du container
docker ps -a

# Tester la connectivité réseau
netstat -an | grep 8080
```

#### Solutions

**1. Port déjà utilisé**
```bash
# Identifier le processus utilisant le port
netstat -ano | findstr 8080

# Arrêter le processus (Windows)
taskkill /PID <PID> /F

# Redémarrer le service
docker-compose restart email-sender-go
```

**2. Configuration manquante**
```bash
# Vérifier les variables d'environnement
docker exec email-sender-go env | grep GO_ENV

# Vérifier le fichier de config
docker exec email-sender-go cat /app/config/config.yaml
```

**3. Dépendances non disponibles**
```bash
# Tester la connectivité Qdrant
curl http://localhost:6333/collections

# Tester PostgreSQL
docker exec postgres psql -U user -d email_sender -c "SELECT 1;"
```

### 2. Performance Dégradée

#### Symptômes
- Latence élevée (>100ms) sur les requêtes API
- Timeouts fréquents
- Consommation mémoire excessive

#### Diagnostic

```bash
# Vérifier les métriques Prometheus
curl http://localhost:8081/metrics | grep email_sender

# Analyser les logs de performance
grep "SLOW" logs/email-sender.log | tail -20

# Monitor les ressources
docker stats email-sender-go
```

#### Solutions

**1. Optimisation cache vectoriel**
```go
// Augmenter la taille du cache dans config.yaml
vector_cache:
  max_size: 10000  # Augmenter de 1000 à 10000
  ttl: "1h"        # Augmenter TTL
```

**2. Pool de connexions Qdrant**
```go
// Optimiser le pool dans vector_client.go
connection_pool:
  max_connections: 20    # Augmenter de 10 à 20
  idle_timeout: "5m"     # Réduire le timeout
```

**3. Garbage Collection Go**
```bash
# Ajuster les variables d'environnement Go
export GOGC=100         # Par défaut
export GODEBUG=gctrace=1  # Pour debugging
```

### 3. Erreurs de Vectorisation

#### Symptômes
- Erreurs lors de l'insertion de vecteurs
- Recherche vectorielle qui échoue
- Timeouts sur les opérations Qdrant

#### Diagnostic

```bash
# Tester la connectivité Qdrant
curl -X GET "http://localhost:6333/collections"

# Vérifier les collections existantes
curl -X GET "http://localhost:6333/collections/task_vectors"

# Tester une recherche simple
curl -X POST "http://localhost:6333/collections/task_vectors/points/search" \
  -H "Content-Type: application/json" \
  -d '{"vector": [0.1, 0.2, 0.3], "limit": 5}'
```

#### Solutions

**1. Collection manquante**
```bash
# Recréer la collection
curl -X PUT "http://localhost:6333/collections/task_vectors" \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 1536,
      "distance": "Cosine"
    }
  }'
```

**2. Problème de dimensions**
```go
// Vérifier la taille des vecteurs dans le code
func (v *VectorService) validateVectorSize(vector []float32) error {
    if len(vector) != 1536 {
        return fmt.Errorf("invalid vector size: got %d, expected 1536", len(vector))
    }
    return nil
}
```

**3. Quota OpenAI dépassé**
```bash
# Vérifier les quotas API OpenAI
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
  "https://api.openai.com/v1/usage"
```

### 4. Problèmes de Communication Inter-Managers

#### Symptômes
- Managers qui ne se découvrent pas
- Events non reçus via l'Event Bus
- Timeouts sur les communications

#### Diagnostic

```bash
# Tester l'API des managers
curl http://localhost:8080/api/v1/managers/status

# Vérifier les logs de l'Event Bus
grep "EventBus" logs/email-sender.log

# Tester la découverte des managers
curl http://localhost:8080/api/v1/managers/discovery
```

#### Solutions

**1. Event Bus saturé**
```go
// Augmenter la taille du buffer
event_bus:
  buffer_size: 10000    # Augmenter de 1000 à 10000
  workers: 10           # Augmenter le nombre de workers
```

**2. Découverte des managers**
```bash
# Redémarrer le processus de découverte
curl -X POST http://localhost:8080/api/v1/managers/discovery/restart
```

**3. Purger les events en attente**
```bash
# Vider le buffer d'events
curl -X POST http://localhost:8080/api/v1/events/purge
```

### 5. Erreurs de Déploiement

#### Symptômes
- Échec du déploiement staging/production
- Services qui ne démarrent pas après déploiement
- Rollback automatique activé

#### Diagnostic

```bash
# Vérifier les logs de déploiement
cat logs/deployment-staging-*.log

# Vérifier l'état des services Docker
docker-compose ps

# Tester les health checks
./deployment/staging/health-check.ps1
```

#### Solutions

**1. Problème de build Docker**
```bash
# Nettoyer le cache Docker
docker system prune -f

# Rebuild l'image
docker build --no-cache -t email-sender-go:latest .
```

**2. Problème de migration de données**
```bash
# Rollback à une version stable
./deployment/staging/rollback.ps1 -Force

# Re-migration avec backup
./deployment/production/migrate-data.ps1 -BackupFirst -ValidateIntegrity
```

**3. Volumes Docker corrompus**
```bash
# Sauvegarder les données
docker run --rm -v qdrant_data:/data -v $(pwd)/backup:/backup alpine tar czf /backup/qdrant_backup.tar.gz -C /data .

# Recréer les volumes
docker volume rm qdrant_data postgres_data
docker volume create qdrant_data
docker volume create postgres_data

# Restaurer les données
docker run --rm -v qdrant_data:/data -v $(pwd)/backup:/backup alpine tar xzf /backup/qdrant_backup.tar.gz -C /data
```

### 6. Problèmes de Monitoring

#### Symptômes
- Métriques Prometheus non disponibles
- Dashboards Grafana vides
- Alertes non déclenchées

#### Diagnostic

```bash
# Tester l'endpoint des métriques
curl http://localhost:8081/metrics

# Vérifier la configuration Prometheus
curl http://localhost:9090/targets

# Tester les alertes
curl http://localhost:9090/api/v1/alerts
```

#### Solutions

**1. Endpoint métriques non accessible**
```yaml
# Vérifier la configuration dans config.yaml
metrics:
  enabled: true
  port: 8081
  path: /metrics
```

**2. Configuration Prometheus**
```yaml
# Vérifier prometheus.yml
scrape_configs:
  - job_name: 'email-sender'
    static_configs:
      - targets: ['email-sender-go:8081']
    scrape_interval: 15s
```

**3. Redémarrer les services de monitoring**
```bash
docker-compose restart prometheus grafana
```

## 🔍 Outils de Diagnostic Avancé

### 1. Profiling Performance

```bash
# Activer le profiling Go
export GO_PROFILE=true

# Profiler CPU
go tool pprof http://localhost:8081/debug/pprof/profile?seconds=30

# Profiler mémoire
go tool pprof http://localhost:8081/debug/pprof/heap

# Profiler goroutines
go tool pprof http://localhost:8081/debug/pprof/goroutine
```

### 2. Analyse des Logs

```bash
# Logs structurés avec jq
docker logs email-sender-go 2>&1 | jq 'select(.level == "ERROR")'

# Analyser les patterns d'erreurs
grep "ERROR" logs/email-sender.log | awk '{print $4}' | sort | uniq -c | sort -nr

# Surveillance en temps réel
tail -f logs/email-sender.log | grep --color=always "ERROR\|WARN"
```

### 3. Tests de Charge

```bash
# Test de charge avec K6
k6 run tests/load/api-load-test.js

# Test de stress vectoriel
go run tests/stress/vector-stress-test.go -concurrent=100 -duration=5m

# Test de fiabilité
go run tests/reliability/reliability-test.go -duration=24h
```

## 🚨 Procédures d'Urgence

### 1. Panne Système Complète

```bash
# 1. Vérifier l'état des services
docker-compose ps

# 2. Redémarrage d'urgence
docker-compose down
docker-compose up -d

# 3. Si échec, rollback complet
./deployment/staging/rollback.ps1 -Force

# 4. Notification équipe
curl -X POST "https://hooks.slack.com/..." \
  -d '{"text": "EMAIL_SENDER_1 down - rollback activated"}'
```

### 2. Corruption de Données

```bash
# 1. Arrêt immédiat des écritures
curl -X POST http://localhost:8080/api/v1/maintenance/readonly

# 2. Backup d'urgence
./deployment/production/backup-emergency.sh

# 3. Validation intégrité
./deployment/production/validate-data-integrity.sh

# 4. Restauration si nécessaire
./deployment/production/restore-from-backup.sh <backup-timestamp>
```

### 3. Attaque de Sécurité

```bash
# 1. Activation mode maintenance
curl -X POST http://localhost:8080/api/v1/maintenance/enable

# 2. Analyse des logs de sécurité
grep "SECURITY" logs/email-sender.log | tail -100

# 3. Blocage IP suspectes
./scripts/security/block-suspicious-ips.sh

# 4. Notification sécurité
./scripts/security/notify-security-team.sh
```

## 📊 Métriques et Alertes

### Seuils d'Alerte Recommandés

```yaml
Performance:
  - Latence p95 > 100ms: WARNING
  - Latence p95 > 500ms: CRITICAL
  - Memory usage > 85%: WARNING
  - Memory usage > 95%: CRITICAL

Availability:
  - Error rate > 1%: WARNING
  - Error rate > 5%: CRITICAL
  - Uptime < 99.9%: WARNING
  - Uptime < 99%: CRITICAL

Vectorisation:
  - Vector insert errors > 0.1%: WARNING
  - Vector search latency > 50ms: WARNING
  - Qdrant connection errors > 0: CRITICAL
```

### Dashboard Recommandé

```yaml
Widgets Essentiels:
  1. Service Status (UP/DOWN)
  2. API Response Time (p50, p95, p99)
  3. Error Rate (last 1h, 24h)
  4. Memory/CPU Usage
  5. Vector Operations/sec
  6. Manager Status Grid
  7. Event Bus Throughput
  8. Database Connections
```

## 📞 Contacts et Escalade

### Niveaux d'Escalade

```yaml
Niveau 1 - Équipe Dev:
  - Redémarrage services
  - Analyse logs basique
  - Tests de connectivité

Niveau 2 - DevOps:
  - Problèmes infrastructure
  - Déploiement/rollback
  - Configuration réseau

Niveau 3 - Expertise:
  - Corruption données
  - Problèmes performance complexes
  - Sécurité
```

### Procédure de Contact

```bash
# Notification automatique
./scripts/notifications/escalate.sh \
  --level <1|2|3> \
  --issue "<description>" \
  --severity <low|medium|high|critical>
```

## 📝 Documentation et Logs

### Localisation des Logs

```bash
# Logs applicatifs
logs/email-sender.log              # Log principal
logs/email-sender-error.log        # Erreurs uniquement
logs/deployment-*.log              # Logs de déploiement
logs/migration-*.log               # Logs de migration

# Logs système
/var/log/docker/                   # Logs Docker
docker logs <container>            # Logs container spécifique
```

### Format des Logs

```json
{
  "timestamp": "2025-06-14T13:45:30Z",
  "level": "ERROR",
  "component": "vector-service",
  "message": "Failed to insert vector",
  "error": "connection timeout",
  "request_id": "req-123456",
  "user_id": "user-789",
  "duration_ms": 5000
}
```

---

**Version**: 1.0  
**Dernière mise à jour**: 14 juin 2025  
**Support**: EMAIL_SENDER_1 Go Native  
**Urgences**: Utiliser les procédures d'escalade ci-dessus
