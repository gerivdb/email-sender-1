# Index de la documentation du système de journal de bord RAG

## Introduction

Bienvenue dans la documentation du système de journal de bord RAG. Ce système permet de documenter, analyser et exploiter les connaissances accumulées au cours du développement de votre projet.

## Sections principales

### Vue d'ensemble

- [README](./README.md): Vue d'ensemble du système
- [Glossaire](./glossary.md): Définitions des termes utilisés

### Documentation technique

- [Journal de bord](./technique/journal.md): Structure et implémentation du journal
- [Système RAG](./technique/rag.md): Recherche et interrogation en langage naturel
- [Analyse avancée](./technique/analysis.md): Analyse des tendances et patterns
- [Intégration GitHub](./technique/github.md): Liaison avec commits et issues
- [Interface web](./technique/web_interface.md): Interface utilisateur web
- [Dépendances](./technique/dependencies.md): Liste des dépendances et leur rôle
- [Schéma des données](./technique/data_schema.md): Structure des données du journal
- [Logs](./technique/logs.md): Utilisation des logs pour le diagnostic

### Guides d'utilisation

- [Installation](./workflow/installation.md): Installation du système
- [Configuration](./workflow/configuration.md): Options de configuration
- [Création d'entrées](./workflow/creating_entries.md): Comment créer des entrées
- [Recherche et RAG](./workflow/search_and_rag.md): Comment rechercher et interroger
- [Analyse](./workflow/analysis.md): Comment analyser le journal
- [Intégration GitHub](./workflow/github_integration.md): Utilisation de l'intégration GitHub
- [Interface web](./workflow/web_interface.md): Utilisation de l'interface web
- [Automatisation](./workflow/automation.md): Tâches planifiées et hooks Git
- [Dépannage](./workflow/troubleshooting.md): Solutions aux problèmes courants

### API et intégrations

- [API Reference](./api/api_reference.md): Documentation de l'API
- [GitHub API](./api/github_api.md): Intégration avec GitHub
- [Augment Memories](./api/augment_memories.md): Intégration avec Augment Memories
- [MCP](./api/mcp.md): Intégration avec Model Context Protocol

### Insights du journal

- [Fréquence des termes](./journal_insights/term_frequency.md): Analyse de la fréquence des termes
- [Évolution des tags](./journal_insights/tag_evolution.md): Analyse de l'évolution des tags
- [Tendances des sujets](./journal_insights/topic_trends.md): Analyse des tendances des sujets
- [Clustering](./journal_insights/clustering.md): Regroupement des entrées par similarité

## Recherche

Vous pouvez rechercher dans la documentation en utilisant:

1. **Interface web**: Utilisez la barre de recherche dans l'interface web
2. **Système RAG**: Interrogez le système RAG avec des questions en langage naturel
3. **Recherche de fichiers**: Utilisez la recherche de fichiers de votre éditeur

## Contribution à la documentation

Pour contribuer à cette documentation:

1. Créez une branche pour vos modifications
2. Effectuez vos modifications en suivant les conventions de formatage
3. Soumettez une pull request avec une description claire de vos changements

## Conventions de formatage

Cette documentation suit les conventions suivantes:

- **Titres**: Utilisez # pour les titres principaux, ## pour les sous-titres, etc.

- **Code**: Utilisez des blocs de code avec la syntaxe appropriée (```python, ```javascript, etc.)
- **Liens**: Utilisez des liens relatifs pour les références internes
- **Images**: Stockez les images dans le répertoire `docs/documentation/images/`
- **Exemples**: Incluez des exemples concrets pour illustrer les concepts

## Génération de la documentation

Cette documentation est générée à partir des entrées du journal et des analyses. Pour mettre à jour la documentation:

```powershell
python scripts/python/journal/docs_integration.py extract
```plaintext
## Dernière mise à jour

Cette documentation a été générée le ${new Date().toISOString().split('T')[0]} à ${new Date().toTimeString().split(' ')[0]}.

## Licence

Cette documentation est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
