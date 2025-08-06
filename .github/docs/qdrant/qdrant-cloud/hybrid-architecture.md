# Architecture hybride Qdrant : modèles et patterns

## Modèles d’orchestration

- **Cluster principal cloud** : centralise l’indexation globale, la recherche, la scalabilité.
- **Clusters locaux** : stockent les données sensibles, assurent conformité et rapidité d’accès.
- **Routage Roo Code** : le [`QdrantManager`](../../../../AGENTS.md#qdrantmanager) orchestre les requêtes entre clusters selon la politique (sécurité, performance, coût).

## Patterns Roo Code

- **Indexation hiérarchique** : chaque cluster local indexe ses propres données ; le cloud indexe les métadonnées/globales.
- **Partitionnement** : collections séparées par sensibilité ou usage.
- **Failover** : bascule automatique en cas de panne locale/cloud.

## Sécurité & confidentialité

- **Compartimentation** : données critiques jamais envoyées au cloud.
- **Chiffrement** : en transit et au repos (via [`SecurityManager`](../../../../AGENTS.md#securitymanager)).
- **Audit** : [`MonitoringManager`](../../../../AGENTS.md#monitoringmanager), logs centralisés.

## Intégration Roo Code

- [`QdrantManager`](../../../../AGENTS.md#qdrantmanager) : gestion multi-clusters, routage, synchronisation.
- [`StorageManager`](../../../../AGENTS.md#storagemanager) : gestion des connexions locales/cloud.
- [`SecurityManager`](../../../../AGENTS.md#securitymanager) : gestion des secrets, chiffrement, audit.
- [`MonitoringManager`](../../../../AGENTS.md#monitoringmanager) : supervision, alertes, reporting.

## Schéma d’architecture

```mermaid
flowchart TD
    subgraph Local
        L1[Qdrant Local Cluster 1]
        L2[Qdrant Local Cluster 2]
    end
    subgraph Cloud
        C1[Qdrant Cloud Cluster]
    end
    User[Utilisateur/Roo Code] -->|Routage| QdrantManager
    QdrantManager --> L1
    QdrantManager --> L2
    QdrantManager --> C1