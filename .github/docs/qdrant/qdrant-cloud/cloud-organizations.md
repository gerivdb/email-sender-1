# Qdrant Cloud — Organisations, utilisateurs et clusters

## Structure hiérarchique

- **Organisation** : entité racine, regroupe les utilisateurs, clusters et paramètres globaux.
- **Cluster** : instance Qdrant isolée, associée à une organisation.
- **Utilisateur** : membre d’une ou plusieurs organisations, avec des rôles distincts.

## Gestion des organisations

- Création d’une organisation : via l’interface Qdrant Cloud.
- Ajout/suppression de membres : invitation par email, gestion des rôles (Owner, Admin, Billing, etc.).
- Gestion multi-organisations : un utilisateur peut appartenir à plusieurs organisations, avec des droits différents.

## Gestion des clusters

- Création de clusters : chaque cluster est isolé, avec ses propres collections et API keys.
- Attribution des rôles : les droits sur un cluster sont indépendants des autres clusters de l’organisation.
- Suppression ou migration : attention, la suppression d’un cluster est irréversible.

## Bonnes pratiques Roo Code

- **Isoler les environnements** : utiliser un cluster dédié par environnement (dev, test, prod).
- **Limiter les droits** : attribuer le rôle minimal nécessaire à chaque membre.
- **Traçabilité** : documenter les attributions de rôles et les changements dans la documentation Roo Code.
- **Sécurité** : révoquer les accès des membres inactifs ou ayant quitté l’organisation.

## Exemples

- Un même utilisateur peut être Owner dans une organisation A et Viewer dans une organisation B.
- Un cluster “roo-prod” peut être restreint à l’équipe de production, tandis que “roo-dev” est ouvert à tous les développeurs.

## Références

- [Documentation officielle Qdrant Cloud — Organisations (EN)](https://qdrant.tech/documentation/cloud/cloud-organizations/)
- [cloud-rbac.md](cloud-rbac.md)
- [cloud-api-keys.md](cloud-api-keys.md)
