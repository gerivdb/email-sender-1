# Spécification de l’API REST — CacheManager v74

## Endpoints

### POST /logs

- Description : Ingestion d’un log centralisé
- Body (JSON) : conforme à logging_format_spec.json
- Réponse : 201 Created, 400 Bad Request, 500 Internal Server Error

### GET /logs

- Description : Recherche de logs selon critères
- Query params : level, source, from, to, trace_id
- Réponse : 200 OK (liste JSON), 400 Bad Request

### POST /context

- Description : Stockage d’un contexte clé/valeur
- Body (JSON) : { "key": "...", "value": ... }
- Réponse : 201 Created, 400 Bad Request

### GET /context

- Description : Récupération d’un contexte par clé
- Query param : key
- Réponse : 200 OK, 404 Not Found

---

## Exemples

### POST /logs

```json
{
  "timestamp": "2025-06-30T04:00:00Z",
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

## Statuts HTTP utilisés

- 200 OK
- 201 Created
- 400 Bad Request
- 404 Not Found
- 500 Internal Server Error

---

*Document validé, à enrichir lors de l’implémentation réelle.*
