# QdrantManager

- **Rôle :** Gestion centralisée de la vectorisation documentaire et du stockage Qdrant (création, indexation, recherche, suppression, statistiques).
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `StoreVector(ctx context.Context, collectionName string, point VectorPoint) error`
  - `StoreBatch(ctx context.Context, collectionName string, points []VectorPoint) error`
  - `Search(ctx context.Context, collectionName string, queryVector []float32, limit int, filter map[string]interface{}) ([]SearchResult, error)`
  - `Delete(ctx context.Context, collectionName string, ids []string) error`
  - `GetStats(ctx context.Context) (*VectorStats, error)`
  - `GetCollections() map[string]*Collection`
  - `CreateCollection(ctx context.Context, name string, vectorSize int, distance string) error`
  - `GetHealth() core.HealthStatus`
  - `GetMetrics() map[string]interface{}`
- **Utilisation :** Indexation, recherche vectorielle, gestion des collections Qdrant, statistiques, intégration avec d’autres managers pour la vectorisation documentaire.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, noms de collections, vecteurs, requêtes de recherche, configurations.
  - Sorties : résultats de recherche, statuts, logs, statistiques, erreurs éventuelles.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
