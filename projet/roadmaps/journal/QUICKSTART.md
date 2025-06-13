# Guide de démarrage rapide - Journal de Bord RAG

Ce guide vous aidera à démarrer rapidement avec le système de journal de bord RAG.

## Prérequis

- Python 3.8+
- Node.js 14+
- npm

## Installation

1. **Cloner le dépôt** (si ce n'est pas déjà fait)

2. **Installer les dépendances Python**

```bash
pip install -r requirements.txt
```plaintext
3. **Installer les dépendances Node.js**

```bash
cd frontend
npm install
cd ..
```plaintext
## Démarrage rapide

Pour démarrer rapidement le système complet (backend et frontend), exécutez :

```bash
run_journal_rag.cmd
```plaintext
Cela lancera :
- Le backend FastAPI sur http://localhost:8000
- Le frontend Vue.js sur http://localhost:8080
- La documentation de l'API sur http://localhost:8000/projet/documentation

## Utilisation de base

### 1. Créer une entrée de journal

Vous pouvez créer une entrée de journal de deux façons :

**Via l'interface web** :
1. Accédez à http://localhost:8080
2. Cliquez sur "Journal" dans la barre de navigation
3. Cliquez sur le bouton "Nouvelle entrée"
4. Remplissez le formulaire et cliquez sur "Enregistrer"

**Via la ligne de commande** :
```bash
python development/scripts/python/journal/journal_entry.py --create --title "Titre de l'entrée" --tags "tag1,tag2"
```plaintext
### 2. Interroger le système RAG

Vous pouvez interroger le système RAG de deux façons :

**Via l'interface web** :
1. Cliquez sur l'icône robot dans la barre de navigation
2. Saisissez votre question et cliquez sur "Interroger"

**Via la ligne de commande** :
```bash
python development/scripts/python/journal/journal_rag_simple.py --query "Comment résoudre les problèmes d'encodage?"
```plaintext
### 3. Visualiser les analyses

Pour accéder aux visualisations et analyses :
1. Accédez à http://localhost:8080
2. Cliquez sur "Analyse" dans la barre de navigation
3. Explorez les différentes visualisations disponibles

### 4. Configurer les intégrations

Pour configurer les intégrations avec Notion, Jira, GitHub et n8n :
1. Accédez à http://localhost:8080
2. Cliquez sur "Paramètres" dans la barre de navigation
3. Sélectionnez l'onglet "Intégrations"
4. Configurez chaque intégration selon vos besoins

## Structure des entrées

Les entrées du journal suivent une structure standard :

```markdown
---
title: Titre de l'entrée
date: YYYY-MM-DD
heure: HH-MM
tags: [tag1, tag2, tag3]
related: [autre-entree.md]
---

# Titre de l'entrée

## Actions réalisées

- Action 1
- Action 2

## Résolution des erreurs, déductions tirées

- Problème 1 résolu en...
- J'ai découvert que...

## Optimisations identifiées

- Pour le système: 
- Pour le code: 
- Pour la gestion des erreurs: 
- Pour les workflows: 

## Enseignements techniques

- Enseignement 1
- Enseignement 2

## Impact sur le projet musical

- Impact 1
- Impact 2

## Références et ressources

- [Lien 1](https://example.com)
- [Lien 2](https://example.com)
```plaintext
## Fonctionnalités avancées

### Détection de patterns

Le système peut détecter automatiquement des patterns dans vos entrées :

```bash
python development/scripts/python/journal/notifications/detector.py --all
```plaintext
### Synchronisation avec Notion

Pour synchroniser vos entrées avec Notion :

```bash
python development/scripts/python/journal/integrations/notion_integration.py --sync-to-journal
python development/scripts/python/journal/integrations/notion_integration.py --sync-from-journal
```plaintext
### Synchronisation avec Jira

Pour synchroniser vos entrées avec Jira :

```bash
python development/scripts/python/journal/integrations/jira_integration.py --sync-to-journal
python development/scripts/python/journal/integrations/jira_integration.py --sync-from-journal
```plaintext
## Dépannage

### Le backend ne démarre pas

Vérifiez que :
- Python 3.8+ est installé
- Les dépendances sont installées (`pip install -r requirements.txt`)
- Les répertoires nécessaires existent (`projet/roadmaps/journal/entries`, etc.)

### Le frontend ne démarre pas

Vérifiez que :
- Node.js 14+ est installé
- npm est installé
- Les dépendances sont installées (`cd frontend && npm install`)

### Les intégrations ne fonctionnent pas

Vérifiez que :
- Les API keys et tokens sont correctement configurés
- Les URLs des APIs sont correctes
- Les permissions sont suffisantes

## Ressources supplémentaires

- [Documentation complète](README.md)
- [API Documentation](http://localhost:8000/projet/documentation)
- [Exemples d'entrées](examples/)
