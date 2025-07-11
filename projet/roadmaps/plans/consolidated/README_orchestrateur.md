# README Orchestrateur & Event Bus

## Usage
- Lancer l’inventaire : `go run tools/orchestrator-scanner/main.go > manager_inventory.md`
- Générer le modèle Event Bus : `go run tools/event-bus-model-generator/main.go`
- Démarrer le service listener : `go run cmd/event-listener-service/main.go`
- Générer le schéma SQL : `go run tools/sql-schema-generator/main.go`
- Import Markdown/JSON vers SQL : `go run tools/md-to-sql-importer/main.go`
- Synchroniser artefacts/base : `go run tools/sync-manager/main.go`
- Lancer les tests d’intégration : `go test ./tools/db-integration-tests`
- Générer le dashboard : `go run tools/dashboard-generator/main.go`
- Générer les rapports d’audit : `go run tools/audit-generator/main.go`
- Feedback migration : `go run tools/feedback-migration/main.go`

## Extension
- Ajouter des plugins Go, scripts, hooks externes (YAML, JSON, Bash, Python…)
- Documentation dynamique : `auto_docs/orchestrator_events.md`

## Schémas
- Mermaid, SQL, JSON Schema

## FAQ
- Voir le plan complet pour les cas d’usage, troubleshooting, badges, CI/CD
