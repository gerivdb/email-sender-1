# CacheManager v74 — Logging Centralisé & Mémoire Contextuelle

## Fonctionnalités principales

- Centralisation des logs (Go, Bash, PowerShell, API REST)
- Orchestration multi-backend (LMCache, Redis, SQLite)
- Mémoire contextuelle pour LLM/assistants
- Scripts de capture terminale et wrappers critiques
- Tests unitaires et intégration exhaustifs
- Reporting automatisé, backup, rollback

## Structure du dépôt

- `development/managers/cache-manager/` : modules Go, adapters, tests
- `development/scripts/` : scripts de capture, backup, intégration
- `projet/roadmaps/plans/consolidated/` : roadmap, specs, rapports, policy

## Démarrage rapide

1. Lancer l’API REST : `go run development/api/cache_manager_api.go`
2. Utiliser les scripts de capture : `bash development/scripts/capture_terminal.sh ls -l`
3. Lancer les tests : `go test ./development/managers/cache-manager/...`
4. Générer un backup : `bash development/scripts/backup.sh`

## Documentation

- Spécifications : `logging_cache_pipeline_spec.md`, `cache_manager_api.md`
- Formats : `logging_format_spec.json`, `logging_filter_rules.md`
- Politique d’orchestration : `cache_manager_policy.md`
- Observabilité : `observability_report.md`, `observability_report.json`
- Procédures rollback : `development/scripts/backup.sh`

## CI/CD

- Prêt pour intégration dans pipeline CI/CD (tests, reporting, artefacts)
- Badge de succès à générer après validation

---

## Migration Gateway-Manager v77

Le Gateway-Manager a été migré vers une implémentation 100% Go natif. Plus de détails peuvent être trouvés dans la [documentation dédiée](docs/gateway-manager.md) et dans le plan de migration détaillé [ici](projet/roadmaps/plans/consolidated/plan-dev-v77-migration-gateway-manager.md).

---

*Projet conforme aux standards .clinerules, prêt pour production et évolutions LLM.*

---
**Dernière exécution CI/CD:** 
**Pipeline:** ✅ Succès
**Modules testés:** core/scanmodules, core/gapanalyzer, core/reporting, cmd/auto-roadmap-runner

## Version Go

Ce projet requiert Go version `1.24.4`.

Pour vérifier votre version de Go :
```bash
go version
```

Pour mettre à jour Go (si nécessaire) :
```bash
go install golang.org/dl/go1.24.4@latest
go1.24.4 download
```
