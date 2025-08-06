# FAQ — Architecture hybride Qdrant (Cloud + Local)

## Quelles sont les limites du free tier Qdrant Cloud ?

- 1 cluster cloud par compte, ressources limitées.
- Pas de multi-cluster natif : la gestion multi-sites repose sur l’orchestration Roo Code.

## Comment garantir la confidentialité des données sensibles ?

- Stockage local pour les collections confidentielles.
- Chiffrement côté client via [`SecurityManager`](../../../../AGENTS.md#securitymanager).
- Routage sélectif et auditabilité complète.

## Comment fonctionne la synchronisation entre clusters locaux et cloud ?

- Synchronisation orchestrée par [`QdrantManager`](../../../../AGENTS.md#qdrantmanager) : push/pull, partitionnement, gestion des conflits.
- Possibilité de synchronisation différée ou temps réel selon les besoins.

## Quels sont les risques principaux et comment les mitiger ?

- **Perte de données** : backups réguliers, monitoring, rollback via [`RollbackManager`](../../../../AGENTS.md#rollbackmanager).
- **Fuite de données** : chiffrement, RBAC, audit.
- **Conflits de synchronisation** : gestion via [`SmartMergeManager`](../../../../AGENTS.md#smartmergemanager).

## Peut-on utiliser des plugins ou extensions Roo Code ?

- Oui, via [`PluginInterface`](../../../../AGENTS.md#plugininterface) : routage, sécurité, monitoring, etc.
- Voir la documentation sur les [points d’extension](../../../../.roo/rules/rules-plugins.md).

## Où trouver des exemples et schémas ?

- [hybrid-overview.md](hybrid-overview.md)
- [hybrid-architecture.md](hybrid-architecture.md)
- [hybrid-usecases.md](hybrid-usecases.md)
- [cloud-clusters-report.md](cloud-clusters-report.md)

## Liens externes utiles

- [Documentation Qdrant Cloud](https://qdrant.tech/documentation/cloud/)
- [Guide sécurité Qdrant](https://qdrant.tech/documentation/security/)
- [API Qdrant](https://qdrant.tech/documentation/api/)