# Intégration avec Model Context Protocol (MCP)

Cette documentation détaille l'intégration entre le système de journal de bord RAG et le Model Context Protocol (MCP) développé par Anthropic.

## Vue d'ensemble

Le Model Context Protocol (MCP) est un protocole qui permet aux modèles d'IA d'interagir avec des systèmes externes comme le système de fichiers, les bases de données et les APIs. L'intégration avec le journal de bord permet aux modèles d'IA d'accéder directement au journal et d'interagir avec lui.

## Architecture

L'intégration est basée sur une architecture de provider MCP:

```plaintext
┌─────────────────┐                 ┌─────────────────┐
│                 │                 │                 │
│  Modèle d'IA    │ ◄─── Query ──── │  MCP Server     │
│  (Claude)       │                 │                 │
│                 │ ─── Response ─► │                 │
│                 │                 │                 │
└─────────────────┘                 └─────────────────┘
                                           │
                                           │
                                           ▼
                                    ┌─────────────────┐
                                    │                 │
                                    │  Journal        │
                                    │  Provider       │
                                    │                 │
                                    └─────────────────┘
                                           │
                                           │
                                           ▼
                                    ┌─────────────────┐
                                    │                 │
                                    │  Journal de     │
                                    │  Bord RAG       │
                                    │                 │
                                    └─────────────────┘
```plaintext
## Implémentation

### Script principal: journal_provider.js

Ce script implémente le provider MCP pour le journal de bord:

```javascript
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const yaml = require('js-yaml');

class JournalProvider {
  constructor() {
    this.journalDir = path.join(process.cwd(), 'projet/documentation', 'journal_de_bord');
    this.entriesDir = path.join(this.journalDir, 'entries');
    this.ragDir = path.join(this.journalDir, 'rag');
    this.pythonScriptsDir = path.join(process.cwd(), 'scripts', 'python', 'journal');
  }

  async listEntries(options = {}) {
    // Liste les entrées du journal avec filtrage optionnel
    ...
  }

  async getEntry(entryPath) {
    // Récupère le contenu d'une entrée spécifique
    ...
  }

  async searchJournal(query, limit = 5) {
    // Recherche dans le journal
    ...
  }

  async queryRag(query) {
    // Interroge le système RAG du journal
    ...
  }

  async createEntry(entryData) {
    // Crée une nouvelle entrée dans le journal
    ...
  }

  async annotateEntry(entryPath, section, annotation) {
    // Ajoute une annotation à une entrée existante
    ...
  }
}

module.exports = JournalProvider;
```plaintext
### Configuration MCP

Le fichier `development/scripts/mcp/config.js` configure le provider MCP:

```javascript
const JournalProvider = require('./journal_provider');

module.exports = {
  providers: [
    {
      name: 'journal',
      provider: new JournalProvider(),
      methods: {
        listEntries: {
          description: 'Liste les entrées du journal de bord',
          parameters: [
            {
              name: 'options',
              type: 'object',
              description: 'Options de filtrage (tag, date, limit, sortBy, sortOrder)',
              required: false
            }
          ]
        },
        getEntry: {
          description: 'Récupère le contenu d\'une entrée spécifique',
          parameters: [
            {
              name: 'entryPath',
              type: 'string',
              description: 'Chemin de l\'entrée (nom du fichier)',
              required: true
            }
          ]
        },
        searchJournal: {
          description: 'Recherche dans le journal de bord',
          parameters: [
            {
              name: 'query',
              type: 'string',
              description: 'Requête de recherche',
              required: true
            },
            {
              name: 'limit',
              type: 'number',
              description: 'Nombre maximum de résultats',
              required: false
            }
          ]
        },
        queryRag: {
          description: 'Interroge le système RAG du journal',
          parameters: [
            {
              name: 'query',
              type: 'string',
              description: 'Requête pour le RAG',
              required: true
            }
          ]
        },
        createEntry: {
          description: 'Crée une nouvelle entrée dans le journal',
          parameters: [
            {
              name: 'entryData',
              type: 'object',
              description: 'Données de l\'entrée (title, tags, content)',
              required: true
            }
          ]
        },
        annotateEntry: {
          description: 'Ajoute une annotation à une entrée existante',
          parameters: [
            {
              name: 'entryPath',
              type: 'string',
              description: 'Chemin de l\'entrée (nom du fichier)',
              required: true
            },
            {
              name: 'section',
              type: 'string',
              description: 'Section à annoter',
              required: true
            },
            {
              name: 'annotation',
              type: 'string',
              description: 'Annotation à ajouter',
              required: true
            }
          ]
        }
      }
    }
  ]
};
```plaintext
## Méthodes exposées

### listEntries

Liste les entrées du journal avec filtrage optionnel.

#### Paramètres

- `options` (objet, optionnel):
  - `tag` (string): Filtre par tag
  - `date` (string): Filtre par date (format: YYYY-MM-DD)
  - `limit` (number): Nombre maximum d'entrées à retourner
  - `sortBy` (string): Champ de tri (date, title, etc.)
  - `sortOrder` (string): Ordre de tri (asc, desc)

#### Exemple d'utilisation

```javascript
const entries = await mcp.invoke('journal', 'listEntries', {
  tag: 'rag',
  limit: 5,
  sortBy: 'date',
  sortOrder: 'desc'
});
```plaintext
### getEntry

Récupère le contenu d'une entrée spécifique.

#### Paramètres

- `entryPath` (string): Chemin de l'entrée (nom du fichier)

#### Exemple d'utilisation

```javascript
const entry = await mcp.invoke('journal', 'getEntry', '2025-04-05-14-30-implementation-du-systeme-rag.md');
```plaintext
### searchJournal

Recherche dans le journal.

#### Paramètres

- `query` (string): Requête de recherche
- `limit` (number, optionnel): Nombre maximum de résultats

#### Exemple d'utilisation

```javascript
const results = await mcp.invoke('journal', 'searchJournal', 'système rag', 5);
```plaintext
### queryRag

Interroge le système RAG du journal.

#### Paramètres

- `query` (string): Requête pour le RAG

#### Exemple d'utilisation

```javascript
const response = await mcp.invoke('journal', 'queryRag', 'Quelles sont les optimisations identifiées pour le système RAG?');
```plaintext
### createEntry

Crée une nouvelle entrée dans le journal.

#### Paramètres

- `entryData` (objet):
  - `title` (string): Titre de l'entrée
  - `tags` (array, optionnel): Liste de tags
  - `content` (objet, optionnel): Contenu de l'entrée par section

#### Exemple d'utilisation

```javascript
const result = await mcp.invoke('journal', 'createEntry', {
  title: 'Nouvelle entrée via MCP',
  tags: ['mcp', 'test', 'automation'],
  content: {
    'Actions réalisées': '- Création d\'une entrée via MCP\n- Test de l\'intégration',
    'Enseignements techniques': '- MCP permet aux modèles d\'IA d\'interagir avec le journal'
  }
});
```plaintext
### annotateEntry

Ajoute une annotation à une entrée existante.

#### Paramètres

- `entryPath` (string): Chemin de l'entrée (nom du fichier)
- `section` (string): Section à annoter
- `annotation` (string): Annotation à ajouter

#### Exemple d'utilisation

```javascript
const result = await mcp.invoke('journal', 'annotateEntry', 
  '2025-04-05-14-30-implementation-du-systeme-rag.md',
  'Enseignements techniques',
  'Cette implémentation pourrait être améliorée en utilisant des embeddings vectoriels.'
);
```plaintext
## Démarrage du serveur MCP

Le script `start-journal-mcp.ps1` permet de démarrer le serveur MCP avec le provider du journal:

```powershell
# Démarrer le serveur MCP

.\development\scripts\cmd\start-journal-mcp.ps1
```plaintext
Ce script:
1. Vérifie si le module MCP est installé
2. Installe les dépendances nécessaires
3. Démarre le serveur MCP avec la configuration du journal

## Utilisation avec Claude

Une fois le serveur MCP démarré, Claude peut interagir avec le journal:

```plaintext
Utilisateur: Peux-tu me lister les 3 entrées les plus récentes du journal de bord?

Claude: Je vais utiliser MCP pour accéder au journal de bord et lister les entrées les plus récentes.

[Claude utilise MCP pour appeler journal.listEntries avec limit=3, sortBy='date', sortOrder='desc']

Voici les 3 entrées les plus récentes du journal de bord:

1. "Optimisation du système RAG" (2025-04-10)
   Tags: rag, optimisation, performance
   
2. "Intégration avec GitHub" (2025-04-08)
   Tags: github, integration, automation
   
3. "Implémentation du système RAG" (2025-04-05)
   Tags: rag, implementation, python

Souhaitez-vous que j'affiche le contenu d'une de ces entrées?
```plaintext
## Considérations techniques

### Dépendances

Le provider MCP utilise plusieurs bibliothèques Node.js:

- **fs** et **path**: Pour l'accès au système de fichiers
- **child_process**: Pour exécuter les scripts Python
- **js-yaml**: Pour parser les métadonnées YAML

### Performance

Pour optimiser les performances:

1. Les résultats de recherche sont mis en cache pour éviter des appels répétés
2. Les opérations lourdes (comme la recherche RAG) sont déléguées aux scripts Python existants

### Sécurité

Les considérations de sécurité incluent:

1. Le serveur MCP n'est accessible que localement (localhost)
2. Les opérations d'écriture (createEntry, annotateEntry) devraient être limitées aux utilisateurs autorisés

## Limitations actuelles

1. **Pas d'authentification**: Le serveur MCP n'implémente pas d'authentification
2. **Opérations synchrones**: Les opérations sont exécutées de manière synchrone, ce qui peut bloquer le serveur
3. **Pas de validation avancée**: La validation des entrées est minimale

## Améliorations futures

1. **Authentification**: Ajouter un mécanisme d'authentification
2. **Opérations asynchrones**: Utiliser des opérations asynchrones pour éviter de bloquer le serveur
3. **Validation avancée**: Ajouter une validation plus stricte des entrées
4. **WebSockets**: Utiliser WebSockets pour les notifications en temps réel
5. **Interface d'administration**: Ajouter une interface d'administration pour gérer le serveur MCP
