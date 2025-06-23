# StorageManager

- **Rôle :** Centralise la gestion de la persistance documentaire, du stockage objet, des connexions PostgreSQL/Qdrant et des métadonnées de dépendances.
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `GetPostgreSQLConnection() (interface{}, error)`
  - `GetQdrantConnection() (interface{}, error)`
  - `RunMigrations(ctx context.Context) error`
  - `SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error`
  - `GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error)`
  - `QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*interfaces.DependencyMetadata, error)`
  - `HealthCheck(ctx context.Context) error`
  - `Cleanup() error`
- **Utilisation :** Centralise toutes les opérations de stockage, migration et récupération documentaire. Utilisé par d’autres managers pour la persistance, la migration et la recherche vectorielle.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, métadonnées, requêtes de dépendances, objets à stocker.
  - Sorties : statuts, objets/document récupérés, erreurs, logs.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
