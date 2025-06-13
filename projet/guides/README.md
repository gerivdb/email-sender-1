# Documentation du Système de Journal de Bord RAG

Cette documentation détaille l'architecture, les fonctionnalités et l'utilisation du système de journal de bord RAG (Retrieval-Augmented Generation) développé pour ce projet.

## Table des matières

1. [Vue d'ensemble](#vue-densemble)

2. [Architecture du système](#architecture-du-système)

3. [Composants principaux](#composants-principaux)

4. [Installation et configuration](#installation-et-configuration)

5. [Guide d'utilisation](#guide-dutilisation)

6. [Intégrations](#intégrations)

7. [Analyse et insights](#analyse-et-insights)

8. [Dépannage](#dépannage)

9. [Références](#références)

## Vue d'ensemble

Le système de journal de bord RAG est une solution complète pour documenter, analyser et exploiter les connaissances accumulées au cours du développement du projet. Il combine:

- Un journal de bord structuré avec métadonnées
- Un système de recherche et d'interrogation en langage naturel (RAG)
- Des analyses avancées pour identifier les tendances et patterns
- Des intégrations avec GitHub et d'autres outils
- Une interface web unifiée pour accéder à toutes ces fonctionnalités

Ce système répond au besoin de capturer et d'exploiter efficacement les connaissances techniques et métier, en particulier dans un contexte de développement logiciel pour l'industrie musicale.

## Architecture du système

Le système est organisé en plusieurs couches:

1. **Couche de stockage**: Fichiers Markdown structurés avec métadonnées YAML
2. **Couche d'accès aux données**: Scripts Python pour lire et écrire les entrées
3. **Couche de traitement**: Analyse, RAG, intégrations
4. **Couche de présentation**: API FastAPI et interface web

L'architecture est modulaire, permettant d'ajouter facilement de nouvelles fonctionnalités ou intégrations.

## Composants principaux

Le système comprend les composants principaux suivants:

- [Journal de bord](./technique/journal.md): Création et gestion des entrées
- [Système RAG](./technique/rag.md): Recherche et interrogation en langage naturel
- [Analyse avancée](./technique/analysis.md): Analyse des tendances et patterns
- [Intégration GitHub](./technique/github.md): Liaison avec commits et issues
- [Interface web](./technique/web_interface.md): Accès unifié à toutes les fonctionnalités
- [Automatisation](./workflow/automation.md): Tâches planifiées et hooks Git

## Installation et configuration

Pour installer et configurer le système, consultez:

- [Guide d'installation](./workflow/installation.md): Installation complète du système
- [Configuration](./workflow/configuration.md): Options de configuration
- [Dépendances](./technique/dependencies.md): Liste des dépendances et leur rôle

## Guide d'utilisation

Pour utiliser le système au quotidien:

- [Création d'entrées](./workflow/creating_entries.md): Comment créer des entrées de journal
- [Recherche et RAG](./workflow/search_and_rag.md): Comment rechercher et interroger le journal
- [Analyse](./workflow/analysis.md): Comment analyser le journal
- [Intégration GitHub](./workflow/github_integration.md): Comment utiliser l'intégration GitHub
- [Interface web](./workflow/web_interface.md): Comment utiliser l'interface web

## Intégrations

Le système s'intègre avec plusieurs outils externes:

- [GitHub](./api/github_api.md): Intégration avec GitHub (commits, issues)
- [Augment Memories](./api/augment_memories.md): Intégration avec Augment Memories
- [MCP](./api/mcp.md): Intégration avec Model Context Protocol

## Analyse et insights

Pour comprendre les analyses et insights générés:

- [Fréquence des termes](./journal_insights/term_frequency.md): Analyse de la fréquence des termes
- [Évolution des tags](./journal_insights/tag_evolution.md): Analyse de l'évolution des tags
- [Tendances des sujets](./journal_insights/topic_trends.md): Analyse des tendances des sujets
- [Clustering](./journal_insights/clustering.md): Regroupement des entrées par similarité

## Dépannage

En cas de problème:

- [Problèmes courants](./workflow/troubleshooting.md): Solutions aux problèmes courants
- [Logs](./technique/logs.md): Comment utiliser les logs pour diagnostiquer les problèmes

## Références

- [API Reference](./api/api_reference.md): Documentation de l'API
- [Schéma des données](./technique/data_schema.md): Schéma des données du journal
- [Glossaire](./glossary.md): Définitions des termes utilisés
