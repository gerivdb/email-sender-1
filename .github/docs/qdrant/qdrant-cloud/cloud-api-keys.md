# Qdrant Cloud — Gestion des clés API

## Introduction

Les clés API permettent d’accéder aux clusters Qdrant Cloud via l’API REST ou les SDKs. Chaque clé est associée à un cluster et à des permissions spécifiques.

## Création et gestion des clés

- **Création** : depuis l’interface Qdrant Cloud, section “API Keys” du cluster concerné.
- **Permissions** : lecture, écriture, gestion des collections, administration.
- **Expiration** : possibilité de définir une durée de validité ou de révoquer à tout moment.
- **Rotation** : générer une nouvelle clé avant révocation de l’ancienne pour éviter toute interruption de service.

## Bonnes pratiques Roo Code

- **Principe du moindre privilège** : créer une clé par usage (ex : indexation, requêtes, admin) avec les droits strictement nécessaires.
- **Sécurité** : ne jamais stocker de clé en clair dans le code ou la documentation. Utiliser le SecurityManager Roo pour la gestion des secrets.
- **Traçabilité** : documenter l’usage de chaque clé dans la documentation technique Roo Code.
- **Révocation** : supprimer immédiatement toute clé compromise ou inutilisée.

## Exemples

- Clé “indexation-roo-dev” : droits d’écriture sur le cluster de développement uniquement.
- Clé “prod-readonly” : accès en lecture seule au cluster de production pour les scripts d’analyse.

## Références

- [Documentation officielle Qdrant Cloud — API Keys (EN)](https://qdrant.tech/documentation/cloud/cloud-api-keys/)
- [cloud-organizations.md](cloud-organizations.md)
- [cloud-rbac.md](cloud-rbac.md)
