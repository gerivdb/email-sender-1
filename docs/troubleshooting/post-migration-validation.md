# Guide de Troubleshooting et Validation Post-Migration

## Table des Matières

1. [Checklist de Validation Post-Migration](#checklist-de-validation-post-migration)
2. [Guide de Troubleshooting](#guide-de-troubleshooting)
3. [Procédures de Rollback](#procédures-de-rollback)
4. [Monitoring et Alertes](#monitoring-et-alertes)

## Checklist de Validation Post-Migration

### 1. Validation des Services

#### 1.1 Services Go Vectorisation

```bash
# Vérifier que les services Go sont actifs
ps aux | grep -E "(qdrant_manager|vector_processor|email_sender)"

# Vérifier les logs des services
tail -f logs/qdrant_manager.log
tail -f logs/vector_processor.log
tail -f logs/email_sender.log
```

**Critères de succès :**

- [ ] Tous les services démarrent sans erreur
- [ ] Aucun message d'erreur critique dans les logs
- [ ] Services répondent aux requêtes de health check

#### 1.2 Base de Données Qdrant

```bash
# Tester la connexion Qdrant
curl http://localhost:6333/collections
curl http://localhost:6333/cluster

# Vérifier les collections migrées
go run tests/validate_qdrant_migration.go
```

**Critères de succès :**

- [ ] Qdrant accessible et répond aux requêtes
- [ ] Toutes les collections Python ont été migrées
- [ ] Intégrité des vecteurs vérifiée (checksums)

### 2. Tests Fonctionnels

#### 2.1 Tests de Performance

```bash
# Lancer les benchmarks
go test -bench=. ./internal/vectorization/...
go test -bench=. ./internal/qdrant/...

# Test de charge
go run tests/load_test.go -concurrent=50 -duration=5m
```

**Critères de succès :**

- [ ] Performance ≥ baseline Python (mesurée)
- [ ] Temps de réponse < 100ms pour queries simples
- [ ] Throughput ≥ 1000 req/sec sous charge

#### 2.2 Tests d'Intégration

```bash
# Tests end-to-end
go test ./tests/integration/...

# Tests avec vraies données
go run tests/e2e_email_vectorization.go
```

**Critères de succès :**

- [ ] Tous les tests d'intégration passent
- [ ] Pipeline email complet fonctionne
- [ ] Aucune régression détectée

### 3. Validation des Données

#### 3.1 Intégrité des Vecteurs

```bash
# Script de validation des données
go run scripts/validate_data_integrity.go

# Comparaison Python vs Go
python scripts/compare_vectorization_outputs.py
```

**Critères de succès :**

- [ ] Tous les vecteurs ont été migrés
- [ ] Checksums correspondent entre Python et Go
- [ ] Aucune perte de données détectée

#### 3.2 Cohérence des Métadonnées

```bash
# Validation des métadonnées
go run scripts/validate_metadata.go

# Vérification des index
curl -X GET "http://localhost:6333/collections/emails/points?limit=10"
```

**Critères de succès :**

- [ ] Métadonnées préservées lors de la migration
- [ ] Index créés correctement
- [ ] Relations entre entités maintenues

## Guide de Troubleshooting

### Problèmes Courants

#### 1. Service ne démarre pas

**Symptômes :**

- Erreur au démarrage
- Process s'arrête immédiatement
- Port déjà utilisé

**Diagnostic :**

```bash
# Vérifier les ports utilisés
netstat -tulpn | grep :6333
netstat -tulpn | grep :8080

# Vérifier les logs de démarrage
journalctl -u qdrant-manager -f
tail -f logs/startup.log
```

**Solutions :**

1. **Port occupé :**

   ```bash
   # Trouver le process utilisant le port
   lsof -i :6333
   # Arrêter le service conflictuel
   sudo systemctl stop <service_name>
   ```

2. **Permissions insuffisantes :**

   ```bash
   # Vérifier les permissions des fichiers
   ls -la config/ logs/ data/
   # Corriger les permissions
   chmod 644 config/*.json
   chmod 755 logs/ data/
   ```

3. **Configuration invalide :**

   ```bash
   # Valider la configuration
   go run cmd/config_validator/main.go --config config/production.json
   ```

#### 2. Erreurs de Connexion Qdrant

**Symptômes :**

- Connection refused
- Timeout errors
- Authentication failed

**Diagnostic :**

```bash
# Tester la connectivité
telnet localhost 6333
curl -v http://localhost:6333/

# Vérifier la configuration Qdrant
cat config/qdrant.yaml
```

**Solutions :**

1. **Service Qdrant arrêté :**

   ```bash
   sudo systemctl start qdrant
   sudo systemctl enable qdrant
   ```

2. **Configuration réseau :**

   ```bash
   # Vérifier la configuration réseau
   ip addr show
   netstat -tulpn | grep qdrant
   ```

3. **Authentification :**

   ```bash
   # Vérifier les credentials
   grep -r "api_key\|token" config/
   ```

#### 3. Performance Dégradée

**Symptômes :**

- Réponses lentes
- Timeouts fréquents
- CPU/Memory élevés

**Diagnostic :**

```bash
# Monitorer les ressources
top -p $(pgrep qdrant_manager)
htop
iotop

# Analyser les logs de performance
grep "SLOW" logs/*.log
grep "ERROR" logs/*.log
```

**Solutions :**

1. **Optimisation mémoire :**

   ```bash
   # Ajuster les paramètres JVM si applicable
   export QDRANT_MEMORY_LIMIT=4g
   
   # Optimiser la configuration Go
   export GOGC=100
   export GOMEMLIMIT=2GiB
   ```

2. **Optimisation base de données :**

   ```sql
   -- Analyser les requêtes lentes
   EXPLAIN ANALYZE SELECT * FROM vectors WHERE similarity > 0.8;
   
   -- Optimiser les index
   CREATE INDEX CONCURRENTLY idx_vectors_metadata ON vectors USING gin(metadata);
   ```

#### 4. Problèmes de Migration

**Symptômes :**

- Données manquantes après migration
- Erreurs de validation
- Incohérences entre Python/Go

**Diagnostic :**

```bash
# Comparer les counts
python scripts/count_python_vectors.py
go run scripts/count_go_vectors.go

# Vérifier les logs de migration
grep "MIGRATION" logs/migration.log
```

**Solutions :**

1. **Re-migration partielle :**

   ```bash
   # Identifier les données manquantes
   go run scripts/find_missing_vectors.go
   
   # Re-migrer les données manquantes
   go run scripts/migrate_missing_data.go --batch-size 1000
   ```

2. **Validation et correction :**

   ```bash
   # Valider l'intégrité
   go run scripts/validate_migration.go --fix-errors
   ```

## Procédures de Rollback

### Rollback Automatique

Le script de déploiement inclut une procédure de rollback automatique :

```powershell
# Rollback complet
./scripts/deploy-vectorisation-v56.ps1 -Rollback -BackupPath "./backups/2024-01-15_pre-migration"

# Rollback des services seulement
./scripts/deploy-vectorisation-v56.ps1 -RollbackServices
```

### Rollback Manuel

#### 1. Arrêt des Services Go

```bash
sudo systemctl stop qdrant-manager
sudo systemctl stop vector-processor
sudo systemctl stop email-sender-go
```

#### 2. Restauration des Services Python

```bash
# Restaurer les services Python
sudo systemctl start email-sender-python
sudo systemctl start vector-processor-python

# Vérifier le statut
sudo systemctl status email-sender-python
```

#### 3. Restauration des Données

```bash
# Restaurer la base Qdrant
sudo systemctl stop qdrant
cp -r backups/qdrant_backup_20240115/* /var/lib/qdrant/
sudo systemctl start qdrant

# Vérifier la restauration
curl http://localhost:6333/collections
```

#### 4. Validation du Rollback

```bash
# Tester les fonctionnalités critiques
python tests/critical_path_test.py
curl http://localhost:8080/health

# Vérifier les logs
tail -f logs/email-sender-python.log
```

## Monitoring et Alertes

### Métriques Clés à Surveiller

#### 1. Santé des Services

```bash
# Health checks automatiques
while true; do
  curl -f http://localhost:8080/health || echo "Service DOWN at $(date)"
  sleep 30
done
```

#### 2. Performance Qdrant

```bash
# Monitoring des requêtes
curl http://localhost:6333/metrics

# Latence des requêtes
curl http://localhost:6333/collections/emails/points/search \
  -H "Content-Type: application/json" \
  -d '{"vector": [0.1, 0.2, 0.3], "limit": 10}' \
  -w "Total time: %{time_total}s\n"
```

#### 3. Utilisation des Ressources

```bash
# CPU et mémoire
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10

# Espace disque
df -h /var/lib/qdrant
du -sh logs/
```

### Configuration des Alertes

#### Prometheus/Grafana

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'qdrant'
    static_configs:
      - targets: ['localhost:6333']
  - job_name: 'email-sender-go'
    static_configs:
      - targets: ['localhost:8080']
```

#### Alertes Email

```yaml
# alertmanager.yml
route:
  receiver: 'email-alerts'
  group_by: ['alertname', 'instance']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 12h

receivers:
- name: 'email-alerts'
  email_configs:
  - to: 'admin@company.com'
    subject: 'Migration Alert: {{ .GroupLabels.alertname }}'
    body: |
      Alert: {{ .GroupLabels.alertname }}
      Instance: {{ .GroupLabels.instance }}
      Summary: {{ .CommonAnnotations.summary }}
```

### Scripts de Monitoring

#### 1. Health Check Script

```bash
#!/bin/bash
# health_check.sh

services=("qdrant-manager" "vector-processor" "email-sender-go")

for service in "${services[@]}"; do
  if systemctl is-active --quiet "$service"; then
    echo "✅ $service is running"
  else
    echo "❌ $service is down"
    # Envoyer une alerte
    curl -X POST "http://webhook.site/alert" -d "service=$service&status=down"
  fi
done
```

#### 2. Performance Monitor

```bash
#!/bin/bash
# performance_monitor.sh

# Mesurer la latence
response_time=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:8080/health)

if (( $(echo "$response_time > 1.0" | bc -l) )); then
  echo "⚠️ High response time: ${response_time}s"
  # Log l'alerte
  echo "$(date): High response time $response_time" >> logs/performance_alerts.log
fi

# Vérifier l'utilisation mémoire
memory_usage=$(ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem | grep qdrant | head -1 | awk '{print $4}')

if (( $(echo "$memory_usage > 80.0" | bc -l) )); then
  echo "⚠️ High memory usage: ${memory_usage}%"
fi
```

## Contacts et Support

### Équipe de Support

- **Lead DevOps :** <support-devops@company.com>
- **Architecture :** <architecture@company.com>
- **Urgences :** +33 1 23 45 67 89

### Documentation Additionnelle

- [Guide d'Architecture](../architecture/system-architecture-guide.md)
- [Guide de Migration](../migration/python-to-go-migration-guide.md)
- [Runbooks Opérationnels](../operations/runbooks.md)

### Outils de Support

- **Logs Centralisés :** <https://logs.company.com>
- **Monitoring :** <https://monitoring.company.com>
- **Alertes :** <https://alerts.company.com>
