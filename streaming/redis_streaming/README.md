# Redis Streaming - Documentation

Ce dossier contient l’implémentation Go pour la synchronisation documentaire via Redis Streaming (section 4.4.3) :

- `redis_streaming_doc_sync.go` : structure principale de synchronisation
- `publish_documentation_event.go` : publication d’événements documentaires
- `intelligent_cache.go` : cache adaptatif Redis
- `advanced_cache_strategies.go` : stratégies avancées de cache

## Dépendances

- go-redis v8+ (`github.com/go-redis/redis/v8`)

## Tests

Des tests unitaires et d’intégration sont à ajouter pour valider chaque composant.
