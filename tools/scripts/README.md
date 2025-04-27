# Scripts du projet

Ce dossier contient tous les scripts du projet, organisÃ©s de maniÃ¨re hiÃ©rarchique selon leur fonction.

## Structure des dossiers

### api

Scripts d'interaction avec les APIs

- **external**: Autres APIs externes
- **n8n**: API N8N

### core

FonctionnalitÃ©s essentielles et modules de base

- **config**: Configuration du systÃ¨me
- **logging**: Journalisation et rapports
- **utils**: Utilitaires gÃ©nÃ©riques

### docs

Documentation

- **guides**: Guides d'utilisation
- **references**: Documentation de rÃ©fÃ©rence

### email

FonctionnalitÃ©s liÃ©es aux emails

- **processing**: Traitement d'emails
- **sending**: Envoi d'emails
- **templates**: Templates d'emails

### journal

SystÃ¨me de journal

- **analysis**: Analyse des journaux
- **integrations**: IntÃ©grations avec d'autres systÃ¨mes
- **rag**: FonctionnalitÃ©s RAG
- **web**: Interface web

### maintenance

Scripts de maintenance

- **cleanup**: Nettoyage
- **encoding**: Gestion d'encodage
- **monitoring**: Surveillance du systÃ¨me
- **repo**: Maintenance du dÃ©pÃ´t

### manager

SystÃ¨me de gestion des scripts

- **config**: Configuration
- **data**: DonnÃ©es gÃ©nÃ©rÃ©es
- **modules**: Modules du gestionnaire

### mcp

Model Context Protocol

- **config**: Configuration MCP
- **integrations**: IntÃ©grations MCP
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

- **integration**: Tests d'intÃ©gration
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

Pour gÃ©rer ces scripts, utilisez le systÃ¨me de gestion de scripts dans le dossier manager.

Exemple:
`powershell
.\manager\ScriptManager.ps1 -Action inventory
`

## Principes de dÃ©veloppement

Les scripts de ce projet suivent les principes suivants:

- **SOLID**: Chaque script a une responsabilitÃ© unique et bien dÃ©finie
- **DRY** (Don't Repeat Yourself): Ã‰vite la duplication de code
- **KISS** (Keep It Simple, Stupid): PrivilÃ©gie les solutions simples et comprÃ©hensibles
- **Clean Code**: Code lisible, bien commentÃ© et facile Ã  maintenir
