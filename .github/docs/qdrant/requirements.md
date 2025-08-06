# Prérequis QDrant

## Objectif
Lister les dépendances, versions, outils et environnements nécessaires à l’utilisation et au développement autour de QDrant dans l’écosystème Roo.

## Dépendances principales
- QDrant (Docker, Go, Python)
- Clients Go : [`qdrant.go`](tools/qdrant/rag-go/pkg/client/qdrant.go)
- Client Python : [`qdrant.py`](mem0-analysis/repo/embedchain/embedchain/vectordb/qdrant.py)
- API HTTP QDrant (voir [documentation officielle](https://qdrant.tech/documentation/))
- Docker (pour l’exécution locale ou CI)
- Scripts de migration/configuration : [`tools/qdrant/config.yaml`](tools/qdrant/config.yaml)

## Versions recommandées
- QDrant : ≥ 1.7.x
- Go : ≥ 1.20
- Python : ≥ 3.9
- Docker : ≥ 20.x

## Liens croisés
- [README QDrant](README.md)
- [Installation QDrant](installation.md)
- [mem0-analysis requirements](../mem0-analysis/requirements.md)
- [AGENTS.md:QdrantManager](../../../../AGENTS.md:QdrantManager)