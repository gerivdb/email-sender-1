# VectorOperationsManager

- **Rôle :** Orchestration des opérations de vectorisation documentaire : insertion, mise à jour, suppression, recherche, statistiques, gestion concurrente.
- **Interfaces :**
  - `BatchUpsertVectors(ctx context.Context, vectors []Vector) error`
  - `UpdateVector(ctx context.Context, vector Vector) error`
  - `DeleteVector(ctx context.Context, vectorID string) error`
  - `GetVector(ctx context.Context, vectorID string) (*Vector, error)`
  - `SearchVectorsParallel(ctx context.Context, queries []Vector, topK int) ([][]SearchResult, error)`
  - `BulkDelete(ctx context.Context, vectorIDs []string) error`
  - `GetStats(ctx context.Context) (map[string]interface{}, error)`
- **Utilisation :** Calcul, gestion, suivi et recherche de vecteurs, opérations concurrentes, intégration avec Qdrant ou autres backends, reporting statistique.
- **Entrée/Sortie :**
  - Entrées : vecteurs, contextes d’exécution, requêtes, identifiants, configurations.
  - Sorties : résultats de recherche, statistiques, statuts, logs, erreurs éventuelles.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
