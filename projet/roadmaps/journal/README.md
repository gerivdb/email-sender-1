# Système de Journal de Bord RAG

Ce système de journal de bord RAG (Retrieval-Augmented Generation) permet de documenter, analyser et exploiter les connaissances accumulées au cours du développement de votre projet.

## Fonctionnalités

### 1. Journal de Bord

- Création d'entrées structurées avec métadonnées (date, heure, tags)
- Organisation chronologique et thématique
- Recherche par mots-clés, tags ou date
- Système RAG pour interroger le journal en langage naturel

### 2. Analyse Avancée

- Analyse de fréquence des termes
- Génération de nuages de mots
- Analyse de l'évolution des tags
- Analyse des tendances des sujets
- Clustering des entrées par similarité
- Analyse de sentiment des entrées

### 3. Intégrations Externes

- GitHub: Liaison bidirectionnelle entre entrées, commits et issues
- Notion: Synchronisation bidirectionnelle avec les pages Notion
- Jira: Synchronisation bidirectionnelle avec les issues Jira
- n8n: Automatisation des workflows et intégration avec d'autres systèmes
- ERPNext: Synchronisation des projets et tâches avec le journal

### 4. Interface Web

- Visualisation unifiée du journal, des analyses et des intégrations
- Navigation intuitive entre les différentes sources de connaissances
- Visualisations interactives des analyses
- Système de notifications pour les patterns détectés

## Installation

Pour installer le système complet, exécutez le script d'initialisation:

```bash
initialize_journal_rag.cmd
```plaintext
Ce script installera toutes les dépendances nécessaires et configurera les répertoires requis.

## Utilisation

### Création d'entrées

Pour créer une nouvelle entrée de journal:

```bash
python development/scripts/python/journal/journal_entry.py --create --title "Titre de l'entrée" --tags "tag1,tag2"
```plaintext
Ou utilisez l'interface web:

```bash
run_journal_rag.cmd
```plaintext
Et accédez à http://localhost:8080/journal/create

### Recherche dans le journal

Pour rechercher dans le journal:

```bash
python development/scripts/python/journal/journal_entry.py --search "votre recherche"
```plaintext
### Interrogation du système RAG

Pour interroger le système RAG:

```bash
python development/scripts/python/journal/journal_rag_simple.py --query "votre question"
```plaintext
### Analyse du journal

Pour exécuter toutes les analyses sémantiques:

```bash
python development/scripts/python/journal/run_semantic_analysis.py --all
```plaintext
Ou pour des analyses spécifiques:

```bash
python development/scripts/python/journal/semantic_analysis/embeddings.py --generate
python development/scripts/python/journal/semantic_analysis/sentiment_analysis.py --analyze
python development/scripts/python/journal/semantic_analysis/topic_modeling.py --model lda
```plaintext
### Intégrations

Pour exécuter toutes les intégrations:

```bash
python development/scripts/python/journal/run_integrations.py --all
```plaintext
Ou pour des intégrations spécifiques:

```bash
# Notion

python development/scripts/python/journal/run_integrations.py --notion --notion-action sync-to-journal

# Jira

python development/scripts/python/journal/run_integrations.py --jira --jira-action sync-to-journal

# n8n

python development/scripts/python/journal/run_integrations.py --n8n --n8n-action create-workflows
```plaintext
### Interface Web

Pour démarrer l'interface web:

```bash
run_journal_rag.cmd
```plaintext
L'interface sera accessible à l'adresse: http://localhost:8080

## Automatisation

Le système peut être automatisé de plusieurs façons:

### Tâches Planifiées

Pour configurer les tâches planifiées, utilisez les workflows n8n:

```bash
python development/scripts/python/journal/integrations/n8n_integration.py --create-workflows
python development/scripts/python/journal/integrations/n8n_integration.py --activate-workflows
```plaintext
### Détection de Patterns

Pour détecter automatiquement les patterns dans vos entrées:

```bash
python development/scripts/python/journal/notifications/detector.py --all
```plaintext
## Structure des Répertoires

```plaintext
projet/documentation/
├── journal_de_bord/
│   ├── entries/           # Entrées du journal

│   ├── analysis/          # Résultats des analyses

│   ├── embeddings/        # Embeddings des entrées

│   ├── rag/               # Données du système RAG

│   ├── notifications/     # Configuration et historique des notifications

│   ├── github/            # Données GitHub

│   ├── jira/              # Données Jira

│   └── notion/            # Données Notion

development/scripts/
├── python/
│   └── journal/           # Scripts Python

│       ├── journal_entry.py
│       ├── journal_rag_simple.py
│       ├── semantic_analysis/
│       │   ├── embeddings.py
│       │   ├── sentiment_analysis.py
│       │   └── topic_modeling.py
│       ├── notifications/
│       │   ├── detector.py
│       │   └── notifier.py
│       ├── integrations/
│       │   ├── notion_integration.py
│       │   ├── jira_integration.py
│       │   └── n8n_integration.py
│       ├── web_routes/
│       │   ├── journal_routes.py
│       │   ├── analysis_routes.py
│       │   ├── notifications_routes.py
│       │   └── integrations_routes.py
│       ├── run_semantic_analysis.py
│       ├── run_integrations.py
│       └── web_app.py
frontend/                  # Application Vue.js

├── public/
└── src/
    ├── components/        # Composants Vue.js

    ├── views/             # Vues principales

    ├── router/            # Configuration du routeur

    ├── store/             # Store Vuex

    └── services/          # Services API

```plaintext
## Analyse sémantique

Le système utilise plusieurs techniques d'analyse sémantique :

- **Embeddings** : Génération de représentations vectorielles des entrées avec sentence-transformers
- **Modélisation de sujets** : Extraction de sujets avec LDA et BERTopic
- **Analyse de sentiment** : Détection des tendances émotionnelles avec TextBlob et transformers
- **RAG** : Combinaison de la recherche et de la génération pour répondre aux questions
- **Visualisations interactives** :
  - Nuage de mots interactif avec analyse d'évolution
  - Graphique d'évolution des sentiments par section
  - Visualisation des tendances des sujets au fil du temps
  - Graphiques d'évolution des tags avec D3.js

## Intégrations

### Notion

L'intégration avec Notion vous permet de :
- Synchroniser les pages Notion vers le journal
- Synchroniser les entrées du journal vers Notion
- Exporter une entrée spécifique vers Notion
- Créer des bases de connaissances structurées à partir de votre journal

### Jira

L'intégration avec Jira vous permet de :
- Synchroniser les issues Jira vers le journal
- Synchroniser les entrées du journal vers Jira
- Exporter une entrée spécifique vers Jira
- Lier les entrées du journal aux tickets Jira

### n8n

L'intégration avec n8n vous permet d'automatiser des tâches comme :
- Créer une entrée lorsqu'un événement se produit
- Générer des rapports périodiques
- Synchroniser les données avec d'autres systèmes
- Déclencher des analyses sémantiques automatiques
- Exécuter des workflows personnalisés basés sur les patterns détectés

### ERPNext

L'intégration avec ERPNext vous permet de :
- Synchroniser les projets et tâches ERPNext vers le journal
- Synchroniser les entrées du journal vers ERPNext sous forme de notes
- Créer des entrées de journal à partir de tâches ERPNext
- Suivre l'avancement des projets et tâches dans le journal
- Lier les entrées du journal aux projets ERPNext

## Notifications

Le système peut détecter automatiquement des patterns dans vos entrées et vous envoyer des notifications :

- **Tendances de termes** : Détection des termes dont la fréquence augmente significativement
- **Évolution du sentiment** : Détection des changements significatifs dans le sentiment général
- **Nouveaux sujets** : Détection de l'émergence de nouveaux sujets dominants

Les notifications peuvent être envoyées via différents canaux :
- Interface web
- Notifications de bureau
- Email
- Slack

## Intégration avec d'autres systèmes

### Augment Memories

Le système s'intègre avec Augment Memories pour fournir un contexte enrichi aux modèles d'IA.

### MCP (Model Context Protocol)

Le système expose ses fonctionnalités via MCP pour permettre aux modèles d'IA d'accéder au journal et d'interagir avec lui.

## Développement

Pour contribuer au développement du système :

1. Clonez le dépôt
2. Exécutez le script d'initialisation : `initialize_journal_rag.cmd`
3. Installez les dépendances Python : `pip install -r requirements.txt`
4. Installez les dépendances Node.js : `cd frontend && npm install`
5. Lancez le système complet : `run_journal_rag.cmd`

### Scripts d'analyse sémantique

Le système inclut plusieurs scripts pour l'analyse sémantique :

```bash
# Générer les embeddings

python development/scripts/python/journal/semantic_analysis/embeddings.py --generate

# Analyser le sentiment

python development/scripts/python/journal/semantic_analysis/sentiment_analysis.py --analyze

# Modéliser les sujets

python development/scripts/python/journal/semantic_analysis/topic_modeling.py --model lda

# Exécuter toutes les analyses

python development/scripts/python/journal/run_semantic_analysis.py --all
```plaintext
### Scripts d'intégration

Le système inclut plusieurs scripts pour les intégrations :

```bash
# Synchroniser avec Notion

python development/scripts/python/journal/integrations/notion_integration.py --sync-to-journal
python development/scripts/python/journal/integrations/notion_integration.py --sync-from-journal

# Synchroniser avec Jira

python development/scripts/python/journal/integrations/jira_integration.py --sync-to-journal
python development/scripts/python/journal/integrations/jira_integration.py --sync-from-journal

# Créer des workflows n8n

python development/scripts/python/journal/integrations/n8n_integration.py --create-workflows

# Exécuter toutes les intégrations

python development/scripts/python/journal/run_integrations.py --all
```plaintext
## Licence

Ce projet est sous licence MIT.
