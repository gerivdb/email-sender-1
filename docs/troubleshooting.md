# Guide de Résolution des Problèmes

## Problèmes Fréquents

### 1. Conflits de Synchronisation

**Symptôme :** Alertes "conflict_detected" dans le dashboard
```
⚠️  Conflict Detected: plan-dev-v48.md
Source: Modified locally at 14:30:22
Target: Modified in system at 14:31:15
Type: Content divergence in Phase 3.2
```

**Diagnostic :**
```bash
# Analyser le conflit en détail
go run tools/conflict-analyzer.go -conflict-id <conflict_id> -detailed

# Visualiser les différences
go run tools/diff-visualizer.go -source <source_path> -target <target_id>
```

**Solutions :**

1. **Résolution Automatique (recommandée pour conflits mineurs)**
```bash
# Résoudre en favorisant la source (Markdown)
go run tools/conflict-resolver.go -resolve auto -id <conflict_id> -strategy source

# Résoudre en favorisant le système dynamique
go run tools/conflict-resolver.go -resolve auto -id <conflict_id> -strategy target

# Merge intelligent (pour contenus compatibles)
go run tools/conflict-resolver.go -resolve auto -id <conflict_id> -strategy merge
```

2. **Résolution Manuelle (pour conflits complexes)**
```bash
# Interface de résolution interactive
go run tools/conflict-resolver.go -interactive -id <conflict_id>

# Éditer manuellement puis appliquer
go run tools/conflict-resolver.go -manual -id <conflict_id> -resolution-file ./resolved.json
```

3. **Consultation du Dashboard de Résolution**
```
http://localhost:8080/dashboard/conflicts
```

### 2. Performance Lente

**Symptôme :** Synchronisation > 30s pour 50 plans

**Diagnostic :**
```bash
# Profiling détaillé
go run tools/performance-analyzer.go -profile -duration 60s

# Analyse goulots d'étranglement
go run tools/bottleneck-detector.go -sync-operation

# Métriques système
curl http://localhost:8080/metrics/performance
```

**Solutions communes :**

1. **Optimisation Workers**
```yaml
# config/config.yaml
sync:
  workers: 8              # Augmenter si CPU disponible
  batch_size: 10          # Réduire si mémoire limitée
  timeout: 45s            # Augmenter si réseau lent
```

2. **Optimisation Base de Données**
```sql
-- Analyser les requêtes lentes
SELECT query, mean_time, calls 
FROM pg_stat_statements 
WHERE mean_time > 1000 
ORDER BY mean_time DESC;

-- Optimiser les index
CREATE INDEX CONCURRENTLY idx_plans_modified ON plans(modified_at);
CREATE INDEX CONCURRENTLY idx_tasks_status ON tasks(status, plan_id);
```

3. **Optimisation QDrant**
```bash
# Vérifier la santé des collections
curl -X GET "http://localhost:6333/collections/plans"

# Optimiser les index vectoriels
curl -X POST "http://localhost:6333/collections/plans/index" \
  -H "Content-Type: application/json" \
  -d '{"wait": true}'

# Compactage si nécessaire
curl -X POST "http://localhost:6333/collections/plans/snapshots"
```

4. **Optimisation Réseau**
```yaml
# config/network.yaml
timeouts:
  connection: 10s
  read: 30s
  write: 15s

connection_pool:
  max_connections: 50
  idle_timeout: 300s
```

### 3. Erreurs de Validation

**Symptôme :** ValidationError dans les logs
```
ERROR: Validation failed for plan-dev-v49.md
- Missing required metadata: priority
- Invalid phase structure: Phase 3 missing subsections
- Inconsistent progress: Phase 2 shows 100% but has incomplete tasks
```

**Diagnostic :**
```bash
# Validation détaillée
go run tools/validation-engine.go -verbose -file <plan-file>

# Analyse structure
go run tools/structure-analyzer.go -file <plan-file> -expected-format v55

# Vérification cohérence
go run tools/coherence-checker.go -file <plan-file>
```

**Solutions :**

1. **Correction automatique des erreurs courantes**
```bash
# Auto-fix formatage
go run tools/auto-fixer.go -file <plan-file> -fix formatting

# Auto-correction métadonnées
go run tools/metadata-fixer.go -file <plan-file> -add-missing

# Recalcul progression
go run tools/progress-calculator.go -file <plan-file> -update
```

2. **Validation assistée**
```bash
# Interface de validation interactive
go run tools/validation-assistant.go -file <plan-file>

# Suggestions de correction
go run tools/correction-advisor.go -file <plan-file> -suggest
```

### 4. Problèmes de Base de Données

**Symptôme :** Erreurs de connexion ou corruption
```
ERROR: Connection to PostgreSQL failed: connection refused
ERROR: QDrant collection corruption detected
```

**Diagnostic :**
```bash
# Test connectivité PostgreSQL
pg_isready -h localhost -p 5432 -U sync_user

# Test QDrant
curl -X GET "http://localhost:6333/health"

# Vérification intégrité
go run tools/db-health-checker.go -comprehensive
```

**Solutions :**

1. **PostgreSQL**
```bash
# Redémarrage service
sudo systemctl restart postgresql

# Réparation index corrompus
sudo -u postgres reindexdb planning_sync

# Vacuum complet
sudo -u postgres vacuumdb --analyze --verbose planning_sync
```

2. **QDrant**
```bash
# Redémarrage QDrant
sudo systemctl restart qdrant

# Reconstruction collection si corruption
curl -X DELETE "http://localhost:6333/collections/plans"
go run tools/rebuild-qdrant.go -collection plans -from-backup
```

### 5. Problèmes de Permissions

**Symptôme :** Accès refusé aux fichiers ou API
```
ERROR: Permission denied: cannot read /roadmaps/plans/
ERROR: API authentication failed: invalid token
```

**Solutions :**
```bash
# Vérifier permissions fichiers
ls -la roadmaps/plans/
chmod -R 755 roadmaps/plans/

# Renouveler tokens API
go run tools/auth-manager.go -refresh-tokens

# Vérifier configuration RBAC
go run tools/rbac-checker.go -user sync_service
```

### 6. Problèmes Mémoire

**Symptôme :** Out of Memory ou GC pressure élevée
```
ERROR: runtime: out of memory
WARN: GC pressure high: 45% CPU time in GC
```

**Solutions :**
```yaml
# config/memory.yaml
memory:
  max_heap: "4GB"
  gc_target: 70
  
processing:
  batch_size: 5           # Réduire la taille des lots
  streaming: true         # Activer streaming pour gros fichiers
```

```bash
# Monitoring mémoire en temps réel
go run tools/memory-monitor.go -alert-threshold 80

# Analyse fuites mémoire
go run tools/memory-profiler.go -duration 300s
```

## Procedures de Diagnostic

### 1. Collecte d'Informations
```bash
# Script de collecte automatique
./scripts/collect-diagnostics.sh

# Informations générées :
# - Logs des dernières 24h
# - Configuration active
# - État des services
# - Métriques performance
# - Snapshot base de données
```

### 2. Tests de Santé Système
```bash
# Test complet du système
go run tests/health-check.go -comprehensive

# Test connectivité
go run tests/connectivity-test.go -all-services

# Test performance baseline
go run tests/performance-baseline.go -compare-with-benchmark
```

### 3. Mode Debug
```bash
# Activer logging détaillé
export LOG_LEVEL=DEBUG
export TRACE_ENABLED=true

# Lancer avec profiling
go run -race tools/plan-synchronizer.go -debug -profile

# Monitoring temps réel
go run tools/real-time-monitor.go -verbose
```

## Escalade et Support

### Niveaux d'Escalade

**Niveau 1 - Auto-résolution (0-15 min)**
- Consultez ce guide
- Utilisez les outils de diagnostic automatiques
- Vérifiez les logs récents

**Niveau 2 - Support Technique (15-60 min)**
- Contactez : support@planning-ecosystem.com
- Incluez output de `./scripts/collect-diagnostics.sh`
- Précisez contexte et étapes de reproduction

**Niveau 3 - Ingénierie (1-4 heures)**
- Contactez : engineering@planning-ecosystem.com
- Problèmes architecturaux ou bugs systémiques
- Inclure traces complètes et profiling

**Niveau 4 - Urgence Critique (immédiat)**
- Contactez : emergency@planning-ecosystem.com
- Perte de données ou corruption critique
- Système indisponible en production

### Informations à Fournir

1. **Description du problème**
   - Symptômes observés
   - Heure de début
   - Impact sur les opérations

2. **Contexte technique**
   - Version du système
   - Configuration active
   - Modifications récentes

3. **Logs et diagnostics**
   - Output de diagnostic automatique
   - Logs d'erreur pertinents
   - Métriques performance

4. **Étapes de reproduction**
   - Séquence exacte
   - Données de test
   - Environnement de reproduction

## Ressources Additionnelles

- **Documentation technique :** [docs/architecture.md](architecture.md)
- **FAQ :** [docs/faq.md](faq.md)
- **Monitoring Dashboard :** http://localhost:8080/monitoring
- **Status Page :** https://status.planning-ecosystem.com
- **Community Forum :** https://forum.planning-ecosystem.com
