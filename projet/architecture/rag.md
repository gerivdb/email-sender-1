# Système RAG - Documentation Technique

## Vue d'ensemble

Le système RAG (Retrieval-Augmented Generation) permet d'interroger le journal de bord en langage naturel. Il combine la recherche d'informations pertinentes (retrieval) avec la génération de réponses contextuelles (generation).

## Architecture

Le système RAG est composé de trois composants principaux:

1. **Indexation**: Création d'un index des entrées du journal
2. **Recherche**: Identification des entrées pertinentes pour une requête
3. **Génération**: Création d'une réponse basée sur les entrées pertinentes

```plaintext
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Indexation │ ──> │  Recherche  │ ──> │ Génération  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Index    │     │   Entrées   │     │  Réponse    │
│             │     │ pertinentes │     │ contextuelle│
└─────────────┘     └─────────────┘     └─────────────┘
```plaintext
## Implémentation

### Script principal: journal_rag_simple.py

Ce script implémente une version simplifiée du système RAG:

```python
# Interroger le système RAG

python scripts/python/journal/journal_rag_simple.py --query "Quelles sont les optimisations identifiées pour le système?"

# Reconstruire l'index

python scripts/python/journal/journal_rag_simple.py --rebuild

# Exporter l'index pour Augment Memories

python scripts/python/journal/journal_rag_simple.py --export
```plaintext
### Classe SimpleJournalRAG

La classe `SimpleJournalRAG` implémente le système RAG:

```python
class SimpleJournalRAG:
    def __init__(self):
        self.index_dir = Path("docs/journal_de_bord/rag")
        self.index_file = self.index_dir / "index.json"
        self.entries_dir = Path("docs/journal_de_bord/entries")
        self.index = self._load_index()
    
    def _load_index(self):
        # Charge l'index ou le crée s'il n'existe pas

        ...
    
    def build_index(self):
        # Construit l'index à partir des entrées du journal

        ...
    
    def query(self, query, n=5):
        # Recherche les entrées pertinentes et génère une réponse

        ...
    
    def export_for_augment(self):
        # Exporte l'index pour Augment Memories

        ...
```plaintext
## Indexation

L'indexation consiste à:

1. Parcourir toutes les entrées du journal
2. Extraire le contenu et les métadonnées de chaque entrée
3. Diviser le contenu en sections (chunks)
4. Créer un index qui associe chaque chunk à son entrée d'origine

L'index est stocké au format JSON dans `docs/journal_de_bord/rag/index.json`.

### Structure de l'index

```json
[
  {
    "source": "2025-04-05-14-30-implementation-du-systeme-rag.md",
    "title": "Implémentation du système RAG",
    "date": "2025-04-05",
    "time": "14-30",
    "tags": ["rag", "implementation", "python"],
    "content": "Contenu de la section...",
    "section": "Actions réalisées"
  },
  ...
]
```plaintext
## Recherche

La recherche utilise une approche simplifiée basée sur la correspondance de mots-clés:

1. Tokenisation de la requête en mots-clés
2. Calcul d'un score de pertinence pour chaque chunk de l'index
3. Sélection des chunks les plus pertinents

### Algorithme de scoring

Le score de pertinence est calculé en fonction de:
- La fréquence des mots-clés dans le chunk
- La présence de mots-clés dans le titre ou les tags
- La récence de l'entrée

## Génération

La génération de réponse est basée sur un template simple:

1. Les chunks pertinents sont assemblés
2. Un template de réponse est rempli avec ces informations
3. La réponse est formatée pour être lisible

### Template de réponse

```plaintext
Voici ce que j'ai trouvé dans le journal de bord concernant votre question:

[Résumé des informations trouvées]

Sources:
1. [Titre de l'entrée 1] (Date: [Date]) - Section: [Section]
   [Extrait pertinent]

2. [Titre de l'entrée 2] (Date: [Date]) - Section: [Section]
   [Extrait pertinent]

...
```plaintext
## Intégration avec Augment Memories

Le système RAG peut exporter son index pour Augment Memories:

1. L'index est converti au format attendu par Augment
2. Les données sont exportées dans `.augment/memories/journal_memories.json`
3. Augment peut alors utiliser ces données comme contexte

### Format d'export pour Augment

```json
[
  {
    "text": "[JOURNAL DE BORD] Titre: Contenu...",
    "metadata": {
      "source": "chemin/vers/fichier.md",
      "tags": ["tag1", "tag2"],
      "date": "2025-04-05T14:30:00"
    }
  },
  ...
]
```plaintext
## Intégration avec MCP

Le système RAG est exposé via MCP (Model Context Protocol) pour permettre aux modèles d'IA d'y accéder directement:

```javascript
// Configuration MCP
{
  "context_providers": [
    {
      "name": "journal_de_bord",
      "type": "custom",
      "command": "python scripts/python/journal/journal_rag_simple.py --query \"${query}\"",
      "working_directory": "${workspace_root}"
    }
  ]
}
```plaintext
## Limitations actuelles

1. **Recherche simplifiée**: Utilise une correspondance de mots-clés plutôt que des embeddings vectoriels
2. **Pas de génération avancée**: Utilise un template plutôt qu'un LLM pour la génération
3. **Pas de contexte conversationnel**: Chaque requête est traitée indépendamment

## Améliorations futures

1. **Embeddings vectoriels**: Utiliser des embeddings pour une recherche sémantique plus précise
2. **Intégration LLM**: Utiliser un LLM pour la génération de réponses plus naturelles
3. **Contexte conversationnel**: Maintenir un historique de conversation
4. **Filtrage avancé**: Permettre de filtrer par date, tag, ou section
5. **Requêtes structurées**: Supporter des requêtes plus complexes (SQL-like)
