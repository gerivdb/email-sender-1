# CacheManager v74 — Logging Centralisé & Mémoire Contextuelle

## Présentation

CacheManager est le module Go centralisé pour la gestion des logs, de la mémoire contextuelle et de l’orchestration des caches (LMCache, Redis, SQLite, etc.) dans l’écosystème.

---

## Architecture

- **CacheManager** : point d’entrée unique (Go)
- **Adapters** : LMCache, Redis, SQLite (extensible)
- **API REST** : ingestion/requêtes de logs et contextes (`/logs`, `/context`)
- **Scripts de capture** : Go, Bash, PowerShell (redirigent stdout/stderr)
- **Centralisation** : tous les logs transitent par CacheManager

---

## Structure

- `cache_manager.go` : orchestrateur principal
- `lmc_adapter.go` : intégration LMCache
- `redis_adapter.go` : intégration Redis
- `sqlite_adapter.go` : intégration SQLite
- `cache_manager_test.go` : tests unitaires
- `logging_cache_pipeline_spec.md` : spécification pipeline
- `logging_format_spec.json` : format JSON des logs
- `cache_manager_api.md` : endpoints API
- `logging_filter_rules.md` : règles de filtrage

---

## Utilisation

### Initialisation

```go
lmc := NewLMCacheAdapter(/*config*/)
redis := NewRedisAdapter(/*config*/)
sqlite := NewSQLiteAdapter(/*config*/)
cm := NewCacheManager(lmc, redis, sqlite)
```

### Ingestion d’un log

```go
entry := LogEntry{
  Level: "INFO",
  Source: "dependency-manager",
  Message: "Scan terminé",
}
err := cm.StoreLog(entry)
```

### API REST

Voir [cache_manager_api.md](./cache_manager_api.md) pour la documentation complète.

---

## Tests

- Lancer : `go test`
- Couverture : >80% visée

---

## Intégration CI/CD

- Build/test automatisé
- Lint Markdown/JSON
- Génération de rapports d’observabilité

---

## Références

- [logging_cache_pipeline_spec.md](./logging_cache_pipeline_spec.md)
- [logging_format_spec.json](./logging_format_spec.json)
- [logging_filter_rules.md](./logging_filter_rules.md)

---

*À compléter lors de l’implémentation effective.*
