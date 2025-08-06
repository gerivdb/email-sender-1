# Guide GitHub Actions – QDrant

## Objectif
Décrire l’intégration de QDrant dans les workflows CI/CD GitHub Actions du projet Roo.

## Ajout d’un service QDrant dans un workflow
- Exemple de service dans `.github/workflows/ci.yml` :
  ```yaml
  services:
    qdrant:
      image: qdrant/qdrant
      ports:
        - 6333:6333
  ```

## Variables d’environnement et secrets
- `QDRANT_URL` : URL d’accès à l’API QDrant (ex : `http://localhost:6333`)
- `QDRANT_API_KEY` : clé API si activée (voir [roles-integration.md](roles-integration.md))

## Exécution de tests d’intégration
- Ajouter un job qui attend le démarrage de QDrant avant de lancer les tests
- Exemple de test Python :
  ```yaml
  - name: Run vector store tests
    run: pytest repo/tests/vector_stores/
  ```

## Liens croisés et ressources
- [Guide d’installation QDrant](installation.md)
- [Intégration des rôles et sécurité](roles-integration.md)
- [Guide VSIX codebase-indexing](../vsix/roo-code/guides/codebase-indexing.md)
- [mem0-analysis github-guide](../mem0-analysis/github-guide.md)
- [AGENTS.md:QdrantManager](../../../../AGENTS.md:QdrantManager)