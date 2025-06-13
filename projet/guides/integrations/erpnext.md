# Intégration ERPNext

## Introduction

L'intégration ERPNext permet de synchroniser les données entre votre journal de bord et votre instance ERPNext. Cette intégration facilite le suivi des projets et des tâches, et permet de créer des entrées de journal à partir des tâches ERPNext.

## Fonctionnalités

- Synchronisation bidirectionnelle entre ERPNext et le journal de bord
- Création d'entrées de journal à partir de tâches ERPNext
- Conversion d'entrées de journal en notes ERPNext
- Interface utilisateur intuitive pour gérer l'intégration

## Configuration

### Prérequis

- Une instance ERPNext fonctionnelle
- Une clé API et un secret API ERPNext
- Les permissions nécessaires pour accéder aux projets et aux tâches

### Configuration de l'intégration

1. Accédez à la page d'intégration ERPNext dans l'interface du journal de bord
2. Cliquez sur le bouton "Configuration"
3. Remplissez les champs suivants:
   - URL de l'API: l'URL de votre instance ERPNext (ex: https://votre-instance.erpnext.com)
   - Clé API: votre clé API ERPNext
   - Secret API: votre secret API ERPNext
4. Cochez la case "Activer l'intégration"
5. Cliquez sur "Enregistrer"
6. Cliquez sur "Tester la connexion" pour vérifier que la configuration est correcte

## Utilisation

### Synchronisation ERPNext → Journal

Pour synchroniser les tâches ERPNext vers le journal:

1. Accédez à la page d'intégration ERPNext
2. Cliquez sur le bouton "Synchroniser ERPNext → Journal"
3. Attendez que la synchronisation soit terminée
4. Les tâches ERPNext seront converties en entrées de journal

Chaque entrée de journal créée contiendra:
- Le titre de la tâche
- La description de la tâche
- Le statut de la tâche
- La priorité de la tâche
- Les dates de début et de fin prévues
- Un lien vers la tâche ERPNext

### Synchronisation Journal → ERPNext

Pour synchroniser les entrées de journal vers ERPNext:

1. Accédez à la page d'intégration ERPNext
2. Cliquez sur le bouton "Synchroniser Journal → ERPNext"
3. Attendez que la synchronisation soit terminée
4. Les entrées de journal avec le tag "erpnext" seront converties en notes ERPNext

Si une entrée de journal contient également le tag "task", elle sera utilisée pour mettre à jour la tâche ERPNext correspondante.

### Création d'une entrée de journal à partir d'une tâche

Pour créer une entrée de journal à partir d'une tâche ERPNext:

1. Accédez à la page d'intégration ERPNext
2. Cliquez sur un projet dans la liste des projets
3. Sélectionnez une tâche dans la liste des tâches du projet
4. Cliquez sur le bouton "Créer une entrée" à côté de la tâche
5. Une nouvelle entrée de journal sera créée avec les informations de la tâche

## Structure des données

### Tâche ERPNext → Entrée de journal

Lorsqu'une tâche ERPNext est convertie en entrée de journal, les données sont mappées comme suit:

| Champ ERPNext | Champ du journal |
|---------------|------------------|
| subject | title |
| description | content |
| status | tag: status:{status} |
| priority | tag: priority:{priority} |
| project | tag: project:{project} |

### Entrée de journal → Note ERPNext

Lorsqu'une entrée de journal est convertie en note ERPNext, les données sont mappées comme suit:

| Champ du journal | Champ ERPNext |
|------------------|---------------|
| title | title |
| content | content |

### Entrée de journal → Tâche ERPNext

Lorsqu'une entrée de journal est utilisée pour mettre à jour une tâche ERPNext, les données sont extraites comme suit:

- L'ID de la tâche est extrait de la section "Détails de la tâche" avec le format "ID: {task_id}"
- Le sujet est extrait de la section "Détails de la tâche" avec le format "Sujet: {subject}"
- La description est extraite de la section "Description"
- Le statut est extrait de la section "Détails de la tâche" avec le format "Statut: {status}"
- La priorité est extraite de la section "Détails de la tâche" avec le format "Priorité: {priority}"

## API

L'intégration ERPNext utilise les endpoints suivants:

### Configuration

- `GET /api/integrations/erpnext/config`: Récupère la configuration ERPNext
- `POST /api/integrations/erpnext/config`: Met à jour la configuration ERPNext
- `POST /api/integrations/erpnext/test-connection`: Teste la connexion ERPNext

### Projets et tâches

- `GET /api/integrations/erpnext/projects`: Récupère la liste des projets ERPNext
- `GET /api/integrations/erpnext/tasks`: Récupère la liste des tâches ERPNext
- `GET /api/integrations/erpnext/tasks/{task_id}`: Récupère une tâche ERPNext spécifique
- `POST /api/integrations/erpnext/tasks`: Crée une nouvelle tâche ERPNext
- `PUT /api/integrations/erpnext/tasks/{task_id}`: Met à jour une tâche ERPNext

### Synchronisation

- `POST /api/integrations/erpnext/sync-to-journal`: Synchronise les tâches ERPNext vers le journal
- `POST /api/integrations/erpnext/sync-from-journal`: Synchronise les entrées de journal vers ERPNext
- `POST /api/integrations/erpnext/create-note`: Crée une note ERPNext à partir d'une entrée de journal

## Dépannage

### Problèmes de connexion

Si vous rencontrez des problèmes de connexion:

1. Vérifiez que l'URL de l'API est correcte
2. Vérifiez que la clé API et le secret API sont corrects
3. Vérifiez que votre instance ERPNext est accessible
4. Vérifiez que vous avez les permissions nécessaires

### Problèmes de synchronisation

Si vous rencontrez des problèmes de synchronisation:

1. Vérifiez les logs pour identifier les erreurs spécifiques
2. Vérifiez que les tâches ERPNext existent toujours
3. Vérifiez que les entrées de journal ont le format attendu
4. Vérifiez que les tags "erpnext" et "task" sont présents si nécessaire

## Exemples

### Exemple d'entrée de journal créée à partir d'une tâche ERPNext

```markdown
---
title: Tâche ERPNext: Implémenter l'authentification
date: 2023-04-05
tags: [erpnext, task, project:Journal RAG, status:Open, priority:High]
---

# Tâche ERPNext: Implémenter l'authentification

## Détails de la tâche

- **ID**: TASK-001
- **Sujet**: Implémenter l'authentification
- **Projet**: Journal RAG
- **Statut**: Open
- **Priorité**: High
- **Date de début**: 2023-04-05
- **Date de fin**: 2023-04-12

## Description

Implémenter un système d'authentification pour l'application Journal RAG. Utiliser JWT pour l'authentification API et sessions pour l'interface web.

## Actions réalisées

- Synchronisation depuis ERPNext le 2023-04-05 15:30

## Notes

- Cette entrée a été générée automatiquement à partir d'une tâche ERPNext.
- Pour mettre à jour la tâche dans ERPNext, modifiez cette entrée et exécutez la synchronisation vers ERPNext.
```plaintext
### Exemple de mise à jour d'une tâche ERPNext à partir d'une entrée de journal

```markdown
---
title: Tâche ERPNext: Implémenter l'authentification
date: 2023-04-05
tags: [erpnext, task, project:Journal RAG, status:In Progress, priority:High]
---

# Tâche ERPNext: Implémenter l'authentification

## Détails de la tâche

- **ID**: TASK-001
- **Sujet**: Implémenter l'authentification
- **Projet**: Journal RAG
- **Statut**: In Progress
- **Priorité**: High
- **Date de début**: 2023-04-05
- **Date de fin**: 2023-04-12

## Description

Implémenter un système d'authentification pour l'application Journal RAG. Utiliser JWT pour l'authentification API et sessions pour l'interface web.

## Actions réalisées

- Synchronisation depuis ERPNext le 2023-04-05 15:30
- Implémentation de l'authentification JWT pour l'API
- Configuration des routes protégées

## Notes

- Cette entrée a été générée automatiquement à partir d'une tâche ERPNext.
- Pour mettre à jour la tâche dans ERPNext, modifiez cette entrée et exécutez la synchronisation vers ERPNext.
```plaintext