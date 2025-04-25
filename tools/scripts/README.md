# Scripts du projet

Ce dossier contient tous les scripts du projet, organisés de manière hiérarchique selon leur fonction.

## Structure des dossiers

### api

Scripts d'interaction avec les APIs

- **external**: Autres APIs externes
- **n8n**: API N8N

### core

Fonctionnalités essentielles et modules de base

- **config**: Configuration du système
- **logging**: Journalisation et rapports
- **utils**: Utilitaires génériques

### docs

Documentation

- **guides**: Guides d'utilisation
- **references**: Documentation de référence

### email

Fonctionnalités liées aux emails

- **processing**: Traitement d'emails
- **sending**: Envoi d'emails
- **templates**: Templates d'emails

### journal

Système de journal

- **analysis**: Analyse des journaux
- **integrations**: Intégrations avec d'autres systèmes
- **rag**: Fonctionnalités RAG
- **web**: Interface web

### maintenance

Scripts de maintenance

- **cleanup**: Nettoyage
- **encoding**: Gestion d'encodage
- **monitoring**: Surveillance du système
- **repo**: Maintenance du dépôt

### manager

Système de gestion des scripts

- **config**: Configuration
- **data**: Données générées
- **modules**: Modules du gestionnaire

### mcp

Model Context Protocol

- **config**: Configuration MCP
- **integrations**: Intégrations MCP
- **server**: Serveurs MCP

### python

Scripts Python

- **journal**: Journal en Python
- **utils**: Utilitaires Python

### setup

Scripts d'installation et configuration

- **env**: Configuration d'environnement
- **git**: Configuration Git
- **mcp**: Configuration MCP

### testing

Tests et validation

- **integration**: Tests d'intégration
- **performance**: Tests de performance
- **unit**: Tests unitaires

### utils

Utilitaires divers

- **automation**: Automatisation
- **git**: Utilitaires Git
- **json**: Manipulation de JSON
- **markdown**: Manipulation de Markdown

### workflow

Gestion des workflows

- **export**: Export de workflows
- **import**: Import de workflows
- **monitoring**: Surveillance des workflows
- **templates**: Templates de workflows
- **validation**: Validation de workflows

## Utilisation

Pour gérer ces scripts, utilisez le système de gestion de scripts dans le dossier manager.

Exemple:
`powershell
.\manager\ScriptManager.ps1 -Action inventory
`

## Principes de développement

Les scripts de ce projet suivent les principes suivants:

- **SOLID**: Chaque script a une responsabilité unique et bien définie
- **DRY** (Don't Repeat Yourself): Évite la duplication de code
- **KISS** (Keep It Simple, Stupid): Privilégie les solutions simples et compréhensibles
- **Clean Code**: Code lisible, bien commenté et facile à maintenir
