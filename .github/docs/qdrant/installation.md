# Installation QDrant

## Objectif
Fournir les étapes détaillées pour installer, configurer et démarrer QDrant dans l’écosystème Roo, en local ou CI/CD.

## Installation via Docker
- Prérequis : [Docker](https://www.docker.com/)
- Commande de base :
  ```bash
  docker run -p 6333:6333 qdrant/qdrant
  ```
- Configuration avancée : voir [`tools/qdrant/config.yaml`](tools/qdrant/config.yaml)

## Installation Go (client natif)
- Installer Go ≥ 1.20
- Ajouter le client Go : voir [`qdrant.go`](tools/qdrant/rag-go/pkg/client/qdrant.go)
- Exemple d’intégration : [README.md](README.md#exemples)

## Installation Python (client natif)
- Installer Python ≥ 3.9
- Installer le package :
  ```bash
  pip install qdrant-client
  ```
- Exemple d’intégration : [`qdrant.py`](mem0-analysis/repo/embedchain/embedchain/vectordb/qdrant.py)

## Intégration CI/CD
- Ajout d’un service QDrant dans GitHub Actions ou autres runners
- Exemple de job : voir [github-guide.md](github-guide.md)

## Liens croisés
- [Prérequis QDrant](requirements.md)
- [Guide d’intégration](roles-integration.md)
- [mem0-analysis installation](../mem0-analysis/installation.md)
- [AGENTS.md:QdrantManager](../../../../AGENTS.md:QdrantManager)