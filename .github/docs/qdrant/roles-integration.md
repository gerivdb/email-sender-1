# Intégration des rôles et sécurité – QDrant

## Gestion des accès et permissions

- QDrant propose une gestion des accès via clé API (`QDRANT_API_KEY`).
- Pour activer la sécurité : configurer la variable d’environnement ou le champ `api_key` dans le fichier de configuration QDrant.
- Exemple :
  ```yaml
  api_key: "votre-cle-api"
  ```

## Bonnes pratiques de sécurité

- Ne jamais exposer la clé API dans le code ou la documentation publique.
- Stocker la clé dans les secrets GitHub Actions ou un coffre sécurisé.
- Limiter les permissions au strict nécessaire pour chaque usage.

## Intégration avec QdrantManager

- Le manager [`QdrantManager`](../../../../AGENTS.md:QdrantManager) centralise l’accès et la gestion des collections QDrant.
- Pour l’intégration : fournir la clé API et l’URL QDrant via variables d’environnement ou configuration.
- Voir la documentation croisée sur la gestion des rôles dans [AGENTS.md](../../../../AGENTS.md:QdrantManager).

## Liens croisés et ressources

- [Guide d’installation QDrant](installation.md)
- [Guide GitHub Actions](github-guide.md)
- [Guide sécurité Roo-Code](../../security/)
- [AGENTS.md:QdrantManager](../../../../AGENTS.md:QdrantManager)
- [mem0-analysis roles-integration](../mem0-analysis/roles-integration.md)