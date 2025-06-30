# Spécification de l’API — CacheManager v74

## Endpoints REST

### 1. POST /logs

- **Description** : Ingestion d’un log centralisé.
- **Body (JSON)** : conforme à logging_format_spec.json
- **Réponse** : 
  - 201 Created : log accepté
  - 400 Bad Request : format invalide
  - 500 Internal Server Error : erreur serveur

### 2. GET /logs

- **Description** : Recherche de logs selon critères.
- **Query params** :
  - `level` (optionnel) : filtre par niveau
  - `source` (optionnel) : filtre par module/script
  - `from`, `to` (optionnel) : période ISO8601
  - `trace_id` (optionnel) : corrélation
- **Réponse** : 
  - 200 OK : liste de logs (JSON array)
  - 400 Bad Request

### 3. POST /context

- **Description** : Stockage d’un contexte clé/valeur (LLM, session, etc.)
- **Body (JSON)** : `{ "key": "...", "value": ... }`
- **Réponse** : 
  - 201 Created
  - 400 Bad Request

### 4. GET /context

- **Description** : Récupération d’un contexte par clé.
- **Query param** : `key`
- **Réponse** : 
  - 200 OK : `{ "key": "...", "value": ... }`
  - 404 Not Found

---

## Statuts HTTP utilisés

- 200 OK
- 201 Created
- 400 Bad Request
- 404 Not Found
- 500 Internal Server Error

---

## Exemples

### POST /logs

```json
{
  "timestamp": "2025-06-30T03:32:00Z",
  "level": "INFO",
  "source": "dependency-manager",
  "message": "Scan terminé",
  "context": { "modules": 42 },
  "trace_id": "abc-123"
}
```

### GET /logs?level=ERROR&source=monitoring-manager

```json
[
  {
    "timestamp": "2025-06-30T03:30:00Z",
    "level": "ERROR",
    "source": "monitoring-manager",
    "message": "Erreur critique détectée",
    "context": { "code": 500 },
    "trace_id": "xyz-789"
  }
]
```

### POST /context

```json
{
  "key": "session-42",
  "value": { "user": "cliner", "state": "active" }
}
```

### GET /context?key=session-42

```json
{
  "key": "session-42",
  "value": { "user": "cliner", "state": "active" }
}
```

---

*À compléter lors de l’implémentation effective.*
