# Création d'entrées dans le journal de bord

Ce guide explique comment créer et gérer des entrées dans le journal de bord.

## Création manuelle d'une entrée

### Utilisation du script journal_entry.py

Le moyen le plus simple de créer une entrée est d'utiliser le script `journal_entry.py`:

```powershell
python scripts/python/journal/journal_entry.py "Titre de l'entrée" --tags tag1 tag2 tag3
```

#### Options disponibles

- `--tags`: Liste de tags séparés par des espaces
- `--related`: Liste d'entrées liées (noms de fichiers sans le chemin)

Exemple complet:

```powershell
python scripts/python/journal/journal_entry.py "Optimisation du système RAG" --tags rag optimisation performance --related 2025-04-01-14-30-implementation-du-systeme-rag.md
```

### Structure d'une entrée

Chaque entrée créée suivra cette structure:

```markdown
---
date: AAAA-MM-JJ
heure: HH-MM
title: Titre de l'entrée
tags: [tag1, tag2, tag3]
related: [fichier1.md, fichier2.md]
---

# Titre de l'entrée

## Actions réalisées
- 

## Résolution des erreurs, déductions tirées
- 

## Optimisations identifiées
- Pour le système: 
- Pour le code: 
- Pour la gestion des erreurs: 
- Pour les workflows: 

## Enseignements techniques
- 

## Impact sur le projet musical
- 

## Code associé
```
# Exemple de code
```

## Prochaines étapes
- 

## Références et ressources
- 
```

### Bonnes pratiques pour remplir une entrée

1. **Actions réalisées**: Décrivez précisément ce que vous avez fait, les décisions prises et les raisons.

2. **Résolution des erreurs, déductions tirées**: Documentez les problèmes rencontrés, comment vous les avez résolus et ce que vous en avez appris.

3. **Optimisations identifiées**: Pour chaque catégorie, notez les améliorations possibles:
   - **Système**: Performance, architecture, infrastructure
   - **Code**: Lisibilité, maintenabilité, patterns
   - **Gestion des erreurs**: Robustesse, logging, récupération
   - **Workflows**: Processus, automatisation, intégration

4. **Enseignements techniques**: Notez les connaissances techniques acquises qui pourraient être utiles à l'avenir.

5. **Impact sur le projet musical**: Expliquez comment votre travail affecte le domaine métier (industrie musicale).

6. **Code associé**: Incluez des exemples de code pertinents, avec des commentaires explicatifs.

7. **Prochaines étapes**: Listez les actions futures à entreprendre.

8. **Références et ressources**: Incluez des liens vers des ressources utiles, des articles, des documentations, etc.

## Création automatique d'entrées

### Entrées quotidiennes et hebdomadaires

Le script `journal-daily.ps1` permet de créer automatiquement des entrées quotidiennes et hebdomadaires:

```powershell
# Créer une entrée quotidienne
.\scripts\cmd\journal-daily.ps1

# Forcer la création d'une entrée hebdomadaire (normalement créée le dimanche)
.\scripts\cmd\journal-daily.ps1 -ForceWeekly
```

### Création à partir d'issues GitHub

Si vous utilisez l'intégration GitHub, vous pouvez créer des entrées à partir d'issues:

```powershell
python scripts/python/journal/github_integration.py create-from-issue --issue 123
```

Cette commande créera une entrée avec les détails de l'issue #123, y compris son titre, sa description et ses labels.

### Création à partir de l'interface web

Si vous utilisez l'interface web, vous pouvez créer des entrées à partir de la page GitHub en cliquant sur le bouton "Créer entrée" à côté d'une issue.

## Automatisation de la création d'entrées

### Tâches planifiées

Vous pouvez configurer des tâches planifiées pour créer automatiquement des entrées:

```powershell
# Configurer les tâches planifiées
.\scripts\cmd\setup-journal-tasks.ps1
```

Ce script configurera:
- Une tâche quotidienne pour créer une entrée chaque jour à 18h
- Une tâche hebdomadaire pour créer une entrée de résumé chaque dimanche à 18h

### Intégration avec n8n

Si vous utilisez n8n, vous pouvez intégrer la création d'entrées dans vos workflows:

```powershell
# Configurer l'intégration n8n
python scripts/python/journal/n8n_journal_integration.py setup
```

Cette commande configurera un webhook que vous pourrez utiliser dans vos workflows n8n pour créer des entrées.

## Édition d'entrées existantes

### Édition manuelle

Vous pouvez éditer manuellement les entrées existantes avec votre éditeur de texte préféré. Les fichiers sont stockés dans `docs/journal_de_bord/entries/`.

### Édition via VS Code

Si vous utilisez VS Code, vous pouvez utiliser les tâches définies dans `.vscode/tasks.json`:

1. Appuyez sur `Ctrl+Shift+P` pour ouvrir la palette de commandes
2. Tapez "Tasks: Run Task"
3. Sélectionnez "Journal: Edit Recent Entries"
4. Sélectionnez l'entrée à éditer

## Organisation des entrées

### Nommage des fichiers

Les fichiers sont nommés selon le format:

```
AAAA-MM-JJ-HH-MM-slug-de-l-entree.md
```

Ne modifiez pas manuellement les noms de fichiers, car cela pourrait casser les liens entre les entrées.

### Utilisation des tags

Utilisez des tags cohérents pour faciliter la recherche et l'organisation:

- **Types d'activité**: `implementation`, `debug`, `refactoring`, `documentation`, `test`
- **Composants**: `rag`, `github`, `analysis`, `web`
- **Domaines**: `music`, `audio`, `metadata`
- **Statuts**: `todo`, `in-progress`, `completed`, `blocked`

### Entrées liées

Utilisez le champ `related` dans les métadonnées pour lier des entrées entre elles:

```yaml
related: [2025-04-01-14-30-implementation-du-systeme-rag.md, 2025-04-02-10-15-debug-du-systeme-rag.md]
```

## Recherche d'entrées

### Recherche en ligne de commande

Vous pouvez rechercher dans le journal avec le script `journal_search_simple.py`:

```powershell
# Recherche par mots-clés
python scripts/python/journal/journal_search_simple.py --query "système rag"

# Recherche par tag
python scripts/python/journal/journal_search_simple.py --tag "rag"

# Recherche par date
python scripts/python/journal/journal_search_simple.py --date "2025-04-05"
```

### Recherche via l'interface web

Si vous utilisez l'interface web, vous pouvez utiliser la barre de recherche en haut de la page Journal.

## Interrogation du système RAG

Vous pouvez interroger le journal en langage naturel avec le système RAG:

```powershell
python scripts/python/journal/journal_rag_simple.py --query "Quelles sont les optimisations identifiées pour le système RAG?"
```

## Conseils pour un journal efficace

1. **Régularité**: Créez des entrées régulièrement, idéalement à la fin de chaque session de travail
2. **Détails**: Incluez suffisamment de détails pour que l'entrée soit utile à long terme
3. **Structure**: Suivez la structure recommandée pour faciliter l'analyse automatique
4. **Tags**: Utilisez des tags cohérents pour faciliter la recherche
5. **Code**: Incluez des exemples de code pertinents avec des commentaires explicatifs
6. **Erreurs**: Documentez les erreurs rencontrées et leurs solutions
7. **Optimisations**: Notez systématiquement les optimisations possibles
8. **Liens**: Utilisez les champs `related` et `Références et ressources` pour créer des liens
9. **Impact métier**: Expliquez toujours l'impact sur le domaine métier (industrie musicale)
10. **Enseignements**: Extrayez et documentez les enseignements techniques réutilisables
