# Requirements — mem0-analysis

Ce document détaille l’ensemble des dépendances Python nécessaires au bon fonctionnement de **mem0-analysis**, en distinguant :
- Les dépendances principales (core)
- Les groupes optionnels (extras) : vector_stores, llms, graph, test, dev, extras
- Les usages recommandés pour chaque groupe

## Compatibilité Python

- Version requise : Python >=3.9, <4.0

## Dépendances principales

| Package                  | Version              | Rôle principal                        |
|--------------------------|---------------------|---------------------------------------|
| qdrant-client            | >=1.9.1             | Stockage/recherche vectorielle        |
| pydantic                 | >=2.7.3             | Validation de schémas, dataclasses    |
| openai                   | >=1.33.0            | API OpenAI, LLMs                      |
| posthog                  | >=3.5.0             | Analytics, tracking                   |
| pytz                     | >=2024.1            | Gestion des fuseaux horaires          |
| sqlalchemy               | >=2.0.31            | ORM, gestion base de données          |
| azure-core               | >=1.35.0,<2.0.0     | Support Azure                         |
| pymochow                | >=2.2.9,<3.0.0      | Connecteur MongoDB optimisé           |
| faiss-cpu                | >=1.11.0.post1,<2.0.0 | Vectorisation locale                  |
| python-dotenv            | >=1.1.1,<2.0.0      | Chargement de variables d’environnement|
| langchain-community      | >=0.3.27,<0.4.0     | Intégration LangChain                 |
| google-api-core          | >=2.25.1,<3.0.0     | API Google Cloud                      |
| google-cloud-aiplatform  | >=1.106.0,<2.0.0    | Vertex AI, vector search              |
| elasticsearch            | >=9.1.0,<10.0.0     | Moteur de recherche                   |
| opensearch-py            | >=3.0.0,<4.0.0      | Moteur de recherche                   |
| azure-search-documents   | ==11.5.2            | Recherche Azure                       |
| chromadb                 | >=1.0.15,<2.0.0     | Vector DB                             |
| pymongo                  | >=4.13.2,<5.0.0     | Connecteur MongoDB                    |
| vecs                     | >=0.4.5,<0.5.0      | Vectorisation                         |
| upstash-vector           | >=0.8.0,<0.9.0      | Vectorisation cloud                   |
| pinecone                 | >=7.3.0,<8.0.0      | Vectorisation cloud                   |

## Extras et groupes optionnels

### [graph]
- langchain-neo4j>=0.4.0
- langchain-aws>=0.2.23
- neo4j>=5.23.1
- rank-bm25>=0.2.2

### [vector_stores]
- vecs>=0.4.0
- chromadb>=0.4.24
- weaviate-client>=4.4.0
- pinecone<=7.3.0
- faiss-cpu>=1.7.4
- upstash-vector>=0.1.0
- azure-search-documents>=11.4.0b8
- pymongo>=4.13.2
- pymochow>=2.2.9

### [llms]
- groq>=0.3.0
- together>=0.2.10
- litellm>=0.1.0
- ollama>=0.1.0
- vertexai>=0.1.0
- google-generativeai>=0.3.0
- google-genai>=1.0.0

### [extras]
- boto3>=1.34.0
- langchain-community>=0.0.0
- sentence-transformers>=5.0.0
- elasticsearch>=8.0.0
- opensearch-py>=2.0.0
- langchain-memgraph>=0.1.0

### [test]
- pytest>=8.2.2
- pytest-mock>=3.14.0
- pytest-asyncio>=0.23.7

### [dev]
- ruff>=0.6.5
- isort>=5.13.2
- pytest>=8.2.2

### [poetry dev group]
- pytest-cov>=6.2.1

## Conseils d’installation

- Installation standard :  
  ```bash
  pip install .
  ```
- Installation avec extras (exemple vector_stores et llms) :  
  ```bash
  pip install .[vector_stores,llms]
  ```
- Installation pour développement et tests :  
  ```bash
  pip install .[dev,test]
  ```

## Notes

- Les extras permettent d’activer uniquement les connecteurs ou modules nécessaires.
- Pour la CI/CD, privilégier l’installation minimale + les extras requis par le pipeline.
- Pour la liste exhaustive et les versions : voir [`pyproject.toml`](../../mem0-analysis/repo/pyproject.toml) et [`requirements.txt`](../../mem0-analysis/repo/requirements.txt).
