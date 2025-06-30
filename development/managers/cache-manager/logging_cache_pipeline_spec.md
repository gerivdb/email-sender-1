# Spécification Technique — Pipeline de Logging & CacheManager (v74)

## Objectif

Définir l’architecture, les interfaces, les flux de données et les responsabilités du pipeline de logging centralisé et du CacheManager unifié pour l’écosystème.

---

## 1. Architecture Générale

- **CacheManager** (Go) : point d’entrée unique pour la gestion des caches/logs.
- **Adapters** : LMCache (backend principal), Redis, SQLite, caches spécialisés.
- **Scripts de capture terminale** : Go, Bash, PowerShell, orchestrés pour rediriger stdout/stderr vers le pipeline.
- **Centralisation** : tous les logs transitent par CacheManager, stockage dans central-terminal.log et LMCache.
- **API** : exposition d’une API locale (REST/gRPC) pour ingestion/requêtes de logs et accès mémoire contextuelle.

---

## 2. Interfaces & API

- **CacheManager.go**
  - Méthodes : `StoreLog(entry)`, `GetLogs(query)`, `StoreContext(key, value)`, `GetContext(key)`
  - Orchestration : sélection dynamique du backend selon la politique (LMCache par défaut, fallback Redis/SQLite)
- **Adapters**
  - LMCache : interface Go, config JSON/YAML
  - Redis : client Go natif
  - SQLite : accès local, fallback
- **API**
  - REST : `/logs`, `/context`
  - gRPC : optionnel

---

## 3. Flux de Données

1. Les scripts (Go/Bash/PS1) capturent stdout/stderr.
2. Les logs sont envoyés à CacheManager via API locale ou appel direct Go.
3. CacheManager applique les règles de filtrage, quotas, formatage.
4. Les logs sont stockés dans central-terminal.log, LMCache, et éventuellement Redis/SQLite.
5. Les requêtes de récupération passent par CacheManager (API ou appel Go).

---

## 4. Sécurité & Robustesse

- Authentification locale (clé API, socket UNIX)
- Limitation de volumétrie, quotas par source
- Rollback automatique en cas d’échec backend
- Journalisation des erreurs système

---

## 5. Observabilité

- Tous les accès/écritures sont logués (audit trail)
- Génération de rapports automatisés (observability_report.md/json)
- Intégration CI/CD pour tests, reporting, alertes

---

## 6. Documentation & Tests

- README détaillé
- Docstrings Go
- Tests unitaires (>80% couverture)
- Exemples d’utilisation (Go, Bash, PS1)
- Validation croisée par l’équipe

---

*Version initiale générée automatiquement — à compléter lors de l’implémentation effective.*
