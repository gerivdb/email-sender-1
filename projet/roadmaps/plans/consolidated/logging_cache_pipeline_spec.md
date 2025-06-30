# Spécification technique détaillée — Pipeline Logging & CacheManager v74

## 1. Architecture cible

- CacheManager (Go) : point d’entrée unique pour logs/contextes
- Adapters : LMCache (principal), Redis, SQLite (fallback)
- API REST : endpoints `/logs`, `/context`
- Scripts de capture : Go, Bash, PowerShell (redirigent stdout/stderr)
- Centralisation : tous les logs transitent par CacheManager, stockage multi-backend

## 2. Interfaces & API

- Méthodes Go : `StoreLog(entry)`, `GetLogs(query)`, `StoreContext(key, value)`, `GetContext(key)`
- Adapters : interfaces pour LMCache, Redis, SQLite
- API REST : `/logs` (POST/GET), `/context` (POST/GET)
- Format JSON conforme à logging_format_spec.json

## 3. Flux de données

1. Scripts capturent stdout/stderr
2. Logs envoyés à CacheManager (API ou appel Go)
3. CacheManager applique filtrage, quotas, formatage
4. Logs stockés dans LMCache, Redis, SQLite selon politique
5. Récupération via API ou appel Go

## 4. Sécurité & robustesse

- Authentification locale (clé API, socket UNIX)
- Limitation volumétrie, quotas par source
- Rollback automatique en cas d’échec backend
- Journalisation des erreurs système

## 5. Observabilité

- Audit trail de tous les accès/écritures
- Génération de rapports automatisés (observability_report.md/json)
- Intégration CI/CD pour tests, reporting, alertes

## 6. Documentation & tests

- README détaillé, docstrings Go
- Tests unitaires (>80% couverture)
- Exemples d’utilisation (Go, Bash, PS1)
- Validation croisée par l’équipe

---

*Document validé, à enrichir lors de l’implémentation réelle.*
