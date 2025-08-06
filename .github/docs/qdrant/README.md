# QDrant – Documentation Modulaire Roo-Code

## Présentation

QDrant est le moteur de vectorisation documentaire central de l’écosystème Roo-Code. Il permet l’indexation, la recherche sémantique et la gestion de collections vectorielles pour tous les agents et managers Roo nécessitant des capacités de RAG, d’IA générative ou d’indexation avancée.

- **Implémentations supportées** : Go natif, Python, API HTTP, Docker.
- **Intégration Roo** : [`QdrantManager`](AGENTS.md:QdrantManager), StorageManager, MaintenanceManager, ContextualMemoryManager, etc.
- **Interopérabilité** : Compatible avec [`mem0-analysis`](../mem0-analysis/README.md), pipelines d’indexation, et outils VSIX Roo-Code ([`codebase-indexing.md`](../vsix/roo-code/guides/codebase-indexing.md)).

---

## Table des matières

- [Installation](installation.md)
- [Requirements](requirements.md)
- [Guide GitHub & CI](github-guide.md)
- [Rôles & Intégrations](roles-integration.md)
- [Cas d’usage & évolutivité](#cas-dusage--evolutivite)
- [Docker & déploiement](#docker--deploiement)
- [Versions Go & Python](#versions-go--python)
- [Indexation codebase VSIX](#indexation-codebase-vsix)
- [Liens croisés & références](#liens-croises--references)

---

## Cas d’usage & évolutivité

- **Indexation sémantique** de code, docs, logs, outputs IA.
- **Recherche vectorielle** pour RAG, assistants, analyse de similarité.
- **Interopérabilité** avec mem0-analysis, scripts Go/Python, pipelines CI/CD.
- **Évolutivité** : support multi-backends, plugins vectorisation, migration de collections, extension future vers d’autres moteurs (Milvus, Pinecone…).
- **Intégrations futures** : monitoring avancé, auto-scaling, gestion fine des droits, audit vectoriel.

---

## Docker & déploiement

- **Support Docker complet** :  
  - Démarrage rapide via `docker-compose` ou image officielle.
  - Scripts PowerShell/Go pour gestion locale et CI.
  - Variables d’environnement pour la configuration (ports, volumes, sécurité).
- **Déploiement cloud** : compatible Kubernetes, VM, bare-metal.

---

## Versions Go & Python

- **Go** :  
  - Client natif [`tools/qdrant/rag-go/pkg/client/qdrant.go`](tools/qdrant/rag-go/pkg/client/qdrant.go:12)
  - Intégration dans StorageManager, QdrantManager, scripts de migration et vectorisation.
- **Python** :  
  - Client officiel [`mem0-analysis/repo/embedchain/embedchain/vectordb/qdrant.py`](mem0-analysis/repo/embedchain/embedchain/vectordb/qdrant.py:1)
  - Utilisé pour l’indexation, les tests, la compatibilité mem0-analysis.
- **API HTTP** :  
  - Exposée par le conteneur Docker ou le binaire natif.

---

## Indexation codebase VSIX

- **Guide complet** : [codebase-indexing.md](../vsix/roo-code/guides/codebase-indexing.md)
- **Fonction** : QDrant sert de backend pour l’indexation sémantique des projets via l’extension VSIX Roo-Code.
- **Interopérabilité** :  
  - Indexation croisée avec mem0-analysis, scripts Go, pipelines CI.
  - Support des workflows d’indexation multi-langages, multi-repo.

---

## Liens croisés & références

- [AGENTS.md](../../AGENTS.md#QdrantManager)
- [mem0-analysis](../mem0-analysis/README.md)
- [codebase-indexing.md](../vsix/roo-code/guides/codebase-indexing.md)
- [requirements.md](requirements.md)
- [installation.md](installation.md)
- [github-guide.md](github-guide.md)
- [roles-integration.md](roles-integration.md)
- [QdrantManager – interfaces](../../AGENTS.md:QdrantManager)
- [Scripts Go/Python](../../tools/qdrant/)
- [Configuration YAML](../../tools/qdrant/config.yaml)
- [Tests & CI](../../src/qdrant/README_TESTING.md)

---

## Bonnes pratiques Roo-Code & extension avancée QdrantManager

### Paramètres configurables et intégration

- **Fichier de configuration** : [`tools/qdrant/config.yaml`](../../tools/qdrant/config.yaml)
  - Chemins de stockage, ports, optimisation, cluster, quantization, options Windows.
  - Activation de la sécurité : `api_key` (voir [roles-integration.md](roles-integration.md)).
- **Variables d’environnement** :
  - `QDRANT_URL`, `QDRANT_API_KEY` (sécurité, CI/CD).
- **CI/CD** : Ajout du service QDrant dans `.github/workflows/ci.yml`, gestion des secrets via GitHub Actions ([github-guide.md](github-guide.md)).

### Points d’extension et plugins

- **PluginInterface** : Ajout dynamique de stratégies de vectorisation, hooks de validation, reporting, audit.
- **Multi-backends** : Support de plusieurs moteurs (Qdrant, Milvus, Pinecone…) via StorageManager.
- **Hooks** : Possibilité d’injecter des hooks pour la validation, la sécurité, le reporting ou l’audit documentaire.
- **Interopérabilité** : Intégration avec mem0-analysis, scripts Go/Python, pipelines d’indexation VSIX.

### Recommandations Roo-Code

- **Sécurité** : Ne jamais exposer la clé API, stocker dans un coffre sécurisé, limiter les permissions.
- **Traçabilité** : Activer les logs, utiliser les rapports d’audit, documenter toute extension ou plugin.
- **Validation** : Tester chaque extension/plugin, valider la compatibilité avec StorageManager et QdrantManager.
- **Documentation** : Mettre à jour AGENTS.md et les guides croisés à chaque évolution.
- **CI/CD** : Automatiser les tests d’intégration, vérifier la santé du service et la conformité des collections.

### Liens croisés

- [AGENTS.md:QdrantManager](../../AGENTS.md:QdrantManager)
- [tools/qdrant/config.yaml](../../tools/qdrant/config.yaml)
- [roles-integration.md](roles-integration.md)
- [github-guide.md](github-guide.md)
- [rules-plugins.md](../../../.roo/rules/rules-plugins.md)
- [plan-dev-v113-autmatisation-doc-roo.md](../../../projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)

---

## Pour contribuer

- Voir [github-guide.md](github-guide.md) pour les workflows, conventions et bonnes pratiques.
- Toute évolution majeure doit être documentée dans la section [Cas d’usage & évolutivité](#cas-dusage--evolutivite) et référencée dans les guides croisés.

---

*Cette documentation modulaire est conçue pour évoluer : chaque section peut être enrichie pour détailler les implications futures, les intégrations potentielles, les dépendances, les cas d’usage anticipés et toute évolution prévue du projet.*