# Démarrage Rapide - Écosystème de Synchronisation Planning

## Installation

### 1. Cloner le repository

```bash
git clone https://github.com/planning-ecosystem/sync.git
cd planning-ecosystem-sync
```plaintext
### 2. Installer les dépendances

```bash
# Dependencies Go

go mod download

# TaskMaster CLI (global)

npm install -g @taskmaster/cli

# Outils de développement

go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```plaintext
### 3. Configuration initiale

```bash
# Copier configuration par défaut

cp config/config.example.yaml config/config.yaml

# Éditer avec vos paramètres

nano config/config.yaml
```plaintext
**Configuration minimale requise :**
```yaml
# config/config.yaml

database:
  postgres:
    host: localhost
    port: 5432
    dbname: planning_sync
    user: sync_user
    password: your_password
  
  qdrant:
    host: localhost
    port: 6333
    collection: plans

sync:
  workers: 4
  timeout: 30s
  backup_enabled: true

monitoring:
  port: 8080
  metrics_enabled: true
  alerts:
    email:
      enabled: true
      smtp_server: smtp.gmail.com
      from: alerts@yourcompany.com
```plaintext
## Premier Sync

### 1. Valider un plan existant

```bash
# Validation complète

go run tools/validation-engine.go -file roadmaps/plans/plan-dev-v55-planning-ecosystem-sync.md

# Validation avec détails

go run tools/validation-engine.go -file roadmaps/plans/plan-dev-v55-planning-ecosystem-sync.md -verbose
```plaintext
**Résultat attendu :**
```plaintext
✅ Plan Structure: Valid
✅ Metadata: Complete
✅ Phases: 8/8 phases detected
✅ Tasks: 247 tasks found
✅ Progress: Consistent
📊 Validation Score: 98.5%
```plaintext
### 2. Synchroniser vers le système dynamique

```bash
# Sync test (dry-run)

go run tools/plan-synchronizer.go -sync -file roadmaps/plans/plan-dev-v55-planning-ecosystem-sync.md -dry-run

# Sync réel

go run tools/plan-synchronizer.go -sync -file roadmaps/plans/plan-dev-v55-planning-ecosystem-sync.md
```plaintext
### 3. Vérifier le dashboard

Ouvrir votre navigateur et aller à :
```plaintext
http://localhost:8080/dashboard
```plaintext
**Indicateurs de succès :**
- 🟢 Sync Status: Active
- 🟢 Last Sync: < 2 minutes ago
- 🟢 Conflicts: 0 unresolved
- 🟢 Performance: < 30s sync time

## Commandes Utiles

### Monitoring en Temps Réel

```bash
# Status général

curl http://localhost:8080/health

# Métriques

curl http://localhost:8080/metrics

# Conflicts actifs

curl http://localhost:8080/api/conflicts/active
```plaintext
### Gestion des Conflits

```bash
# Lister conflits

go run tools/conflict-resolver.go -list

# Résoudre conflit automatiquement

go run tools/conflict-resolver.go -resolve auto -id <conflict_id>

# Résoudre manuellement

go run tools/conflict-resolver.go -resolve manual -id <conflict_id> -choice source
```plaintext
### Backup et Restauration

```bash
# Backup immédiat

./scripts/backup-restore.ps1 -Action backup

# Restaurer depuis backup

./scripts/backup-restore.ps1 -Action restore -BackupPath "./backups/20250612_143022"
```plaintext
## Vérification Installation

Exécutez le script de vérification pour confirmer que tout fonctionne :

```bash
go run scripts/verify-installation.go
```plaintext
**Output attendu :**
```plaintext
🔍 Vérification Installation Planning Ecosystem Sync...
✅ Dependencies Go: OK
✅ Database PostgreSQL: Connected
✅ QDrant Vector DB: Connected  
✅ TaskMaster CLI: Available
✅ Configuration: Valid
✅ Test Sync: Successful
🎉 Installation complète et fonctionnelle !
```plaintext
## Prochaines Étapes

1. **Découvrir l'interface :** Explorez le dashboard à http://localhost:8080
2. **Migrer vos plans :** Suivez le [Guide de Migration](migration-guide.md)
3. **Configurer monitoring :** Configurez les alertes dans [config/alerts.yaml](../config/alerts.yaml)
4. **Automatiser :** Configurez les syncs automatiques avec cron

## Support

- 📚 **Documentation complète :** [docs/](../docs/)
- 🐛 **Signaler un bug :** [Issues GitHub](https://github.com/planning-ecosystem/sync/issues)
- 💬 **Communauté :** [Discord](https://discord.gg/planning-sync)
- ✉️ **Contact :** support@planning-ecosystem.com
