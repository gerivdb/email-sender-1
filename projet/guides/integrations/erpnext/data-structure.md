# Structure des données ERPNext

## Mappage des données

Cette page décrit comment les données sont mappées entre ERPNext et le journal de bord.

## Tâche ERPNext → Entrée de journal

Lorsqu'une tâche ERPNext est convertie en entrée de journal, les données sont mappées comme suit:

| Champ ERPNext | Champ du journal |
|---------------|------------------|
| subject | title |
| description | content |
| status | tag: status:{status} |
| priority | tag: priority:{priority} |
| project | tag: project:{project} |
| exp_start_date | Mentionné dans le contenu |
| exp_end_date | Mentionné dans le contenu |

### Structure de l'entrée de journal

```markdown
---
title: Tâche ERPNext: {subject}
date: {date_actuelle}
tags: [erpnext, task, project:{project}, status:{status}, priority:{priority}]
---

# Tâche ERPNext: {subject}

## Détails de la tâche
- **ID**: {task_id}
- **Sujet**: {subject}
- **Projet**: {project}
- **Statut**: {status}
- **Priorité**: {priority}
- **Date de début**: {exp_start_date}
- **Date de fin**: {exp_end_date}

## Description
{description}

## Actions réalisées
- Synchronisation depuis ERPNext le {date_heure_actuelle}

## Notes
- Cette entrée a été générée automatiquement à partir d'une tâche ERPNext.
- Pour mettre à jour la tâche dans ERPNext, modifiez cette entrée et exécutez la synchronisation vers ERPNext.
```

## Entrée de journal → Note ERPNext

Lorsqu'une entrée de journal est convertie en note ERPNext, les données sont mappées comme suit:

| Champ du journal | Champ ERPNext |
|------------------|---------------|
| title | title |
| content | content |

### Structure de la note ERPNext

```
{title}

{content}
```

## Entrée de journal → Tâche ERPNext

Lorsqu'une entrée de journal est utilisée pour mettre à jour une tâche ERPNext, les données sont extraites comme suit:

| Section de l'entrée | Champ ERPNext |
|---------------------|---------------|
| ID: {task_id} | name |
| Sujet: {subject} | subject |
| Description | description |
| Statut: {status} | status |
| Priorité: {priority} | priority |

### Extraction des données

L'extraction des données utilise des expressions régulières pour trouver les informations dans l'entrée de journal:

- L'ID de la tâche est extrait avec: `ID\s*:\s*([A-Za-z0-9-]+)`
- Le sujet est extrait avec: `Sujet\s*:\s*(.+)$`
- La description est extraite avec: `Description\s*\n(.*?)(?=\n##|\Z)`
- Le statut est extrait avec: `Statut\s*:\s*(.+)$`
- La priorité est extraite avec: `Priorité\s*:\s*(.+)$`

## Tags spéciaux

Les tags suivants ont une signification particulière dans l'intégration ERPNext:

- **erpnext**: Indique que l'entrée est liée à ERPNext
- **task**: Indique que l'entrée est liée à une tâche ERPNext
- **project:{nom_du_projet}**: Indique le projet associé à la tâche
- **status:{statut}**: Indique le statut de la tâche
- **priority:{priorité}**: Indique la priorité de la tâche

## Statuts et priorités

### Statuts de tâche ERPNext

Les statuts de tâche ERPNext standard sont:

- Open
- Working
- Pending Review
- Completed
- Cancelled

### Priorités de tâche ERPNext

Les priorités de tâche ERPNext standard sont:

- Low
- Medium
- High
- Urgent

## Gestion des conflits

En cas de conflit lors de la synchronisation (par exemple, si une tâche a été modifiée à la fois dans ERPNext et dans le journal), la stratégie suivante est appliquée:

1. Pour la synchronisation ERPNext → Journal: Les données ERPNext ont priorité
2. Pour la synchronisation Journal → ERPNext: Les données du journal ont priorité

Vous pouvez modifier ce comportement en éditant le fichier de configuration de l'intégration.
