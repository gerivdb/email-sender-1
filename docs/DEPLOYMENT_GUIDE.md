# Guide de Déploiement EMAIL_SENDER_1 Go Native

## 🚀 Guide Complet de Déploiement

Ce guide détaille le processus complet de déploiement de l'écosystème EMAIL_SENDER_1 Go Native, de l'environnement de développement à la production.

## 📋 Prérequis

### Système Requis

```yaml
Système d'exploitation:
  - Windows 10/11 ou Linux Ubuntu 20.04+
  - macOS 12+ (non testé mais compatible)

Logiciels requis:
  - Docker Desktop 4.0+
  - Docker Compose 2.0+
  - Go 1.21+
  - Git 2.30+
  - PowerShell 7+ (Windows) ou Bash (Linux/macOS)

Ressources minimales:
  - RAM: 8GB minimum, 16GB recommandé
  - CPU: 4 cœurs minimum, 8 cœurs recommandé
  - Stockage: 50GB espace libre minimum
  - Réseau: Connexion Internet stable
```

### Services Externes

```yaml
Bases de données:
  - Qdrant 1.7+ (fourni via Docker)
  - PostgreSQL 15+ (fourni via Docker)

APIs externes:
  - OpenAI API (clé requise pour vectorisation)
  - Optionnel: Services de notification

Monitoring:
  - Prometheus (fourni via Docker)
  - Grafana (fourni via Docker)
```

## 🏗️ Architecture de Déploiement

### Environnements Disponibles

```yaml
Development:
  - Local uniquement
  - Services en mode debug
  - Hot reload activé
  - Données de test

Staging:
  - Environnement de test
  - Configuration proche production
  - Tests automatisés
  - Données de validation

Production:
  - Environnement live
  - Haute disponibilité
  - Monitoring complet
  - Données réelles
```

## 🚀 Déploiement Pas à Pas

### Étape 1: Préparation de l'Environnement

#### 1.1 Clonage du Repository

```bash
# Cloner le projet
git clone <repository-url> email-sender-1
cd email-sender-1

# Vérifier la branche
git checkout consolidation-v57

# Vérifier l'état
git status
```

#### 1.2 Configuration des Variables d'Environnement

```bash
# Copier le template de configuration
cp .env.template .env

# Éditer les variables
nano .env
```

Variables principales :

```bash
# Configuration Go
GO_ENV=production
DEBUG=false
LOG_LEVEL=info

# Base de données
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=email_sender
POSTGRES_USER=email_user
POSTGRES_PASSWORD=secure_password_2024

# Qdrant
QDRANT_HOST=qdrant
QDRANT_PORT=6333
QDRANT_COLLECTION=task_vectors

# OpenAI
OPENAI_API_KEY=your_openai_api_key_here

# Monitoring
PROMETHEUS_ENABLED=true
GRAFANA_ADMIN_PASSWORD=admin_password_2024

# Sécurité
JWT_SECRET=your_jwt_secret_here
API_RATE_LIMIT=1000
```

#### 1.3 Validation de l'Environnement

```bash
# Vérifier Docker
docker --version
docker-compose --version

# Vérifier Go
go version

# Test de connectivité
ping google.com
```

### Étape 2: Déploiement Staging

#### 2.1 Lancement du Déploiement Staging

```bash
# Exécuter le script de déploiement staging
./deployment/staging/staging-deploy.ps1 -Validate

# Ou en mode manuel :
docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml up -d
```

#### 2.2 Vérification du Déploiement

```bash
# Health check automatique
./deployment/staging/health-check.ps1 -Detailed

# Vérification manuelle
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/status
```

#### 2.3 Tests de Validation

```bash
# Tests d'intégration complets
go run development/managers/integration_tests/complete_ecosystem_integration.go

# Tests de performance
go run development/managers/phase_4_performance_validation.go

# Validation finale
go run development/managers/phase_8_final_validation.go
```

### Étape 3: Migration des Données

#### 3.1 Préparation de la Migration

```bash
# Backup des données existantes (si applicable)
./deployment/production/migrate-data.ps1 -DryRun -BackupFirst

# Vérification de l'intégrité
./deployment/production/validate-data-integrity.ps1
```

#### 3.2 Exécution de la Migration

```bash
# Migration automatisée
./deployment/production/migrate-data.ps1 -Environment staging -BackupFirst -ValidateIntegrity

# Surveillance du progrès
tail -f logs/migration-*.log
```

#### 3.3 Validation Post-Migration

```bash
# Vérifier les données migrées
curl -X POST http://localhost:8080/api/v1/vectors/search \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "limit": 5}'

# Comparer les métriques
curl http://localhost:8081/metrics | grep vector_operations
```

### Étape 4: Déploiement Production

#### 4.1 Préparation Production

```bash
# Vérification finale staging
./deployment/staging/health-check.ps1 -ContinuousMonitoring

# Backup production actuel
./deployment/production/backup-production.ps1

# Notification équipe
./scripts/notifications/notify-deployment-start.ps1
```

#### 4.2 Déploiement Blue-Green

```bash
# Déploiement avec Blue-Green
./deployment/production/production-deploy.ps1 -Version v1.0.0 -BlueGreen -AutoMigrate

# Surveillance des métriques
watch curl -s http://localhost:8081/metrics | grep -E "(http_requests|vector_operations)"
```

#### 4.3 Bascule du Trafic

```bash
# Test sur l'environnement Green
curl http://localhost:8080/health

# Bascule du load balancer (automatique dans le script)
# Ou configuration manuelle Nginx si nécessaire

# Vérification du trafic
curl http://production-url/api/v1/status
```

### Étape 5: Validation Post-Déploiement

#### 5.1 Tests de Santé

```bash
# Health check complet
./deployment/staging/health-check.ps1 -BaseUrl http://production-url -Detailed

# Tests de charge légers
k6 run tests/load/production-smoke-test.js

# Validation fonctionnelle
go run tests/production/production-validation.go
```

#### 5.2 Monitoring et Alertes

```bash
# Vérifier Prometheus
curl http://production-url:9090/targets

# Vérifier Grafana
curl http://production-url:3000/api/health

# Test des alertes
curl http://production-url:9090/api/v1/alerts
```

## 🔧 Configuration Avancée

### Load Balancer Nginx

```nginx
upstream email_sender_backend {
    server email-sender-blue:8080;
    server email-sender-green:8080 backup;
}

server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://email_sender_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /health {
        access_log off;
        proxy_pass http://email_sender_backend/health;
    }
}
```

### Configuration SSL/TLS

```bash
# Génération certificats Let's Encrypt
certbot --nginx -d your-domain.com

# Configuration automatique SSL
./scripts/security/setup-ssl.ps1 -Domain your-domain.com
```

### Backup Automatisé

```yaml
# Configuration backup dans crontab
0 2 * * * /app/deployment/production/backup-daily.sh
0 2 * * 0 /app/deployment/production/backup-weekly.sh
```

## 📊 Monitoring et Observabilité

### Dashboards Grafana

Dashboards automatiquement provisionnés :

1. **EMAIL_SENDER Overview** : Vue d'ensemble système
2. **API Performance** : Métriques des APIs
3. **Vector Operations** : Performance vectorielle
4. **Infrastructure** : Ressources système
5. **Business Metrics** : KPIs métier

### Alertes Prometheus

```yaml
# Alertes critiques configurées
groups:
  - name: email_sender_alerts
    rules:
      - alert: ServiceDown
        expr: up{job="email-sender"} == 0
        for: 2m
        annotations:
          summary: "Service EMAIL_SENDER down"
      
      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.1
        for: 5m
        annotations:
          summary: "High API latency detected"
```

## 🚨 Procédures d'Urgence

### Rollback Rapide

```bash
# Rollback automatique
./deployment/staging/rollback.ps1 -Force

# Rollback production avec notification
./deployment/production/emergency-rollback.ps1 -NotifyTeam

# Vérification post-rollback
./deployment/staging/health-check.ps1
```

### Escalade des Incidents

```yaml
Niveau 1 (Auto-résolution):
  - Redémarrage automatique des services
  - Health checks continus
  - Notification monitoring

Niveau 2 (Équipe DevOps):
  - Rollback manuel
  - Analyse logs
  - Coordination équipe

Niveau 3 (Équipe Expert):
  - Corruption données
  - Sécurité compromise
  - Défaillance infrastructure
```

## 🔄 Maintenance et Mises à Jour

### Mises à Jour Régulières

```bash
# Mise à jour mineure (patch)
./deployment/production/update-patch.ps1 -Version v1.0.1

# Mise à jour majeure (feature)
./deployment/production/update-major.ps1 -Version v1.1.0 -BlueGreen

# Mise à jour critique (hotfix)
./deployment/production/hotfix-deploy.ps1 -Version v1.0.1-hotfix
```

### Maintenance Préventive

```bash
# Nettoyage des logs anciens
./scripts/maintenance/cleanup-logs.ps1 -OlderThan 30days

# Optimisation base de données
./scripts/maintenance/optimize-database.ps1

# Vérification intégrité
./scripts/maintenance/integrity-check.ps1
```

## 📈 Optimisation Performance

### Tuning Recommandé

```yaml
Qdrant:
  segment_number: 2
  indexing_threshold: 20000
  vector_size: 1536
  distance: Cosine

PostgreSQL:
  shared_buffers: 256MB
  effective_cache_size: 1GB
  work_mem: 4MB
  max_connections: 100

Go Application:
  GOGC: 100
  GOMAXPROCS: 8
  worker_pool_size: 20
```

### Scaling Horizontal

```bash
# Ajout d'instances
docker-compose up --scale email-sender-go=3

# Configuration load balancer
./scripts/scaling/update-load-balancer.ps1 -Instances 3

# Validation du scaling
./scripts/scaling/test-scaling.ps1
```

## 📚 Ressources Supplémentaires

### Documentation

- [Architecture Go Native](./ARCHITECTURE_GO_NATIVE.md)
- [Guide de Migration](./MIGRATION_GUIDE.md)
- [Troubleshooting](./TROUBLESHOOTING_GUIDE.md)
- [API Reference](./API_REFERENCE.md)

### Outils et Scripts

- [Scripts de déploiement](../deployment/)
- [Tests d'intégration](../development/managers/integration_tests/)
- [Monitoring](../deployment/config/)

### Support

- **Documentation** : `/docs` dans le repository
- **Issues** : GitHub Issues
- **Monitoring** : Grafana dashboards
- **Logs** : `/logs` directory

---

**Version** : 1.0  
**Date** : 14 juin 2025  
**Écosystème** : EMAIL_SENDER_1 Go Native v57  
**Status** : Production Ready ✅
