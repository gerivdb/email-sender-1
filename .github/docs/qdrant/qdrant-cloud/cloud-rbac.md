# Qdrant Cloud — Gestion des accès et rôles (RBAC)

## Présentation

Qdrant Cloud utilise un système RBAC (Role-Based Access Control) pour contrôler précisément les droits d’accès aux ressources : organisations, clusters, collections, API, etc.  
Chaque utilisateur se voit attribuer un ou plusieurs rôles à différents niveaux hiérarchiques.

## Hiérarchie des accès

- **Organisation** : niveau racine, regroupe les utilisateurs et clusters.
- **Cluster** : instance Qdrant isolée, associée à une organisation.
- **Collection** : espace de stockage vectoriel au sein d’un cluster.

## Rôles principaux

| Rôle            | Portée         | Droits principaux                                  |
|-----------------|---------------|----------------------------------------------------|
| Owner           | Organisation  | Gestion totale, facturation, utilisateurs, clusters |
| Admin           | Organisation/Cluster | Gestion des clusters, collections, utilisateurs    |
| Editor          | Cluster       | Création, modification, suppression de collections  |
| Viewer          | Cluster       | Lecture seule sur les collections                  |
| Billing         | Organisation  | Accès à la facturation uniquement                  |

## Bonnes pratiques Roo Code

- **Séparer les rôles** : Limiter le nombre d’owners, privilégier les rôles Editor/Viewer pour l’intégration Roo Code.
- **API Keys** : Générer des clés API avec le scope minimal (ex : accès lecture seule pour l’indexation, écriture pour la synchronisation).
- **Audit** : Utiliser les logs d’accès Qdrant Cloud pour tracer les opérations sensibles.
- **Rotation** : Renouveler régulièrement les clés API et révoquer les accès inutilisés.

## Exemples d’utilisation

- **Indexer le code Roo Code** :  
  - Utiliser une clé API avec rôle Editor sur le cluster cible.
  - Limiter l’accès aux seules collections nécessaires.

- **Accès lecture seule (analyse, reporting)** :  
  - Attribuer le rôle Viewer à l’utilisateur ou à la clé API.

## Références

- [Documentation officielle RBAC Qdrant Cloud (EN)](https://qdrant.tech/documentation/cloud/cloud-rbac/)
- [cloud-api-keys.md](cloud-api-keys.md)
- [cloud-organizations.md](cloud-organizations.md)
