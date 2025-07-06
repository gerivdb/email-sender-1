# Spécification des besoins d'intégration pour Gateway-Manager v77

Ce document détaille les exigences pour l'intégration du nouveau Gateway-Manager 100% Go natif avec les composants existants de l'écosystème.

## 1. Objectifs d'intégration

- Assurer une communication fluide et sécurisée entre Gateway-Manager et les autres managers (CacheManager, LWM, Memory Bank, RAG).
- Standardiser les interfaces de communication pour une meilleure interopérabilité.
- Mettre en place un logging unifié et des mécanismes de monitoring.

## 2. Composants à intégrer

### 2.1. CacheManager
- **Type d'intégration**: Communication via API Go interne.
- **Besoins**:
    - Le Gateway-Manager doit pouvoir invalider/mettre à jour le cache.
    - Le CacheManager doit notifier le Gateway-Manager des changements de cache pertinents.
- **Points d'attention**: Cohérence des données, latence.

### 2.2. LWM (Lightweight Workflow Manager)
- **Type d'intégration**: Appels de fonctions Go directes ou via une interface Go.
- **Besoins**:
    - Le Gateway-Manager doit pouvoir déclencher des workflows LWM.
    - Le LWM doit pouvoir retourner l'état d'exécution et les résultats au Gateway-Manager.
- **Points d'attention**: Gestion des erreurs, idempotence des opérations.

### 2.3. Memory Bank
- **Type d'intégration**: API REST (HTTP/JSON).
- **Besoins**:
    - Le Gateway-Manager doit pouvoir stocker et récupérer des données de la Memory Bank.
    - Authentification et autorisation pour les accès à la Memory Bank.
- **Endpoints exposés par Memory Bank (exemples)**:
    - `POST /memory/store`
    - `GET /memory/{id}`
    - `PUT /memory/{id}`
    - `DELETE /memory/{id}`
- **Points d'attention**: Performance des requêtes, sécurité des données.

### 2.4. RAG (Retrieval-Augmented Generation)
- **Type d'intégration**: API Go interne ou gRPC.
- **Besoins**:
    - Le Gateway-Manager doit pouvoir soumettre des requêtes au RAG pour la génération de contenu.
    - Le RAG doit retourner le contenu généré et les métadonnées associées.
- **Points d'attention**: Temps de réponse, gestion des grands volumes de texte.

## 3. Spécification des interfaces (exemples)

### 3.1. API REST (pour Memory Bank)

#### Requête de stockage (`POST /memory/store`)
```json
{
  "key": "unique_identifier",
  "data": {
    "field1": "value1",
    "field2": "value2"
  },
  "ttl": "24h"
}
```

#### Réponse de stockage
```json
{
  "status": "success",
  "id": "generated_id",
  "timestamp": "2025-07-02T10:00:00Z"
}
```

### 3.2. Interfaces Go (pour CacheManager, LWM, RAG)

```go
// CacheManagerInterface définit les opérations du CacheManager
type CacheManagerInterface interface {
    Invalidate(key string) error
    Update(key string, value interface{}) error
}

// LWMInterface définit les opérations du LWM
type LWMInterface interface {
    TriggerWorkflow(workflowID string, payload map[string]interface{}) (string, error) // retourne un ID de tâche
    GetWorkflowStatus(taskID string) (string, error)
}

// RAGInterface définit les opérations du RAG
type RAGInterface interface {
    GenerateContent(query string, context []string) (string, error) // retourne le contenu généré
}
```

## 4. Logging et Monitoring

- **Logging**: Tous les managers doivent utiliser un système de logging unifié (ex: `logrus` ou `zap` configuré globalement).
- **Monitoring**: Exposition de métriques Prometheus (ex: nombre de requêtes, latence, erreurs) pour chaque manager.

## 5. Feuille de route des adaptations

- **Phase 1**: Implémentation des clients Go pour interagir avec les APIs existantes (Memory Bank).
- **Phase 2**: Définition et implémentation des interfaces Go pour les communications inter-managers (CacheManager, LWM, RAG).
- **Phase 3**: Intégration des mécanismes de logging et monitoring.
- **Phase 4**: Tests d'intégration complets et validation des performances.

## 6. Extraction des endpoints HTTP du code

Un script Go (`internal/tools/extract_endpoints.go`) sera utilisé pour analyser le code source et extraire tous les endpoints HTTP définis, afin de garantir la complétude et la conformité avec la spécification.
