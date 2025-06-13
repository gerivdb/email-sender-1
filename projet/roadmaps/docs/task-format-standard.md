# Format de tâche standardisé pour le système de roadmapping

## Introduction

Ce document définit le format de tâche standardisé pour notre système de roadmapping, inspiré par le projet claude-task-master. L'objectif est de créer un format cohérent et extensible qui peut être utilisé dans différents contextes (Markdown, JSON, base de données) tout en maintenant la compatibilité avec nos outils existants.

## Objectifs

- Définir un format de tâche **cohérent** et **complet**
- Permettre la **conversion bidirectionnelle** entre Markdown et JSON
- Supporter des **métadonnées riches** (priorité, durée, assignation, etc.)
- Faciliter l'**analyse automatique** des roadmaps
- Améliorer l'**interopérabilité** avec d'autres outils (Notion, GitHub, n8n)

## Format de base

### Représentation JSON

```json
{
  "id": "task-123",
  "title": "Implémenter la recherche sémantique",
  "description": "Ajouter la recherche sémantique avec embeddings vectoriels",
  "status": "todo",
  "metadata": {
    "priority": "high",
    "estimated_duration": "3d",
    "assigned_to": "john.doe",
    "tags": ["search", "ai", "vector-db"],
    "created_at": "2025-05-15T10:00:00Z",
    "updated_at": "2025-05-16T14:30:00Z"
  },
  "dependencies": ["task-456", "task-789"],
  "subtasks": ["subtask-001", "subtask-002"],
  "history": [
    {
      "timestamp": "2025-05-15T10:00:00Z",
      "user": "jane.doe",
      "action": "created"
    },
    {
      "timestamp": "2025-05-16T14:30:00Z",
      "user": "john.doe",
      "action": "updated",
      "changes": ["status", "metadata.priority"]
    }
  ]
}
```plaintext
### Représentation Markdown

```markdown
- [ ] **task-123** Implémenter la recherche sémantique #priority:high #duration:3d #assigned:john.doe #tags:search,ai,vector-db

  > Ajouter la recherche sémantique avec embeddings vectoriels
  > 
  > **Dépendances**: task-456, task-789
  > **Créé le**: 2025-05-15 par jane.doe
  > **Mis à jour le**: 2025-05-16 par john.doe
  
  - [ ] **subtask-001** Configurer la base de données vectorielle
  - [ ] **subtask-002** Implémenter l'API de recherche
```plaintext
## Spécification détaillée

### Champs obligatoires

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `id` | String | Identifiant unique de la tâche | `"task-123"` |
| `title` | String | Titre court de la tâche | `"Implémenter la recherche sémantique"` |
| `status` | String | État de la tâche (todo, in-progress, done) | `"todo"` |

### Champs optionnels

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `description` | String | Description détaillée de la tâche | `"Ajouter la recherche sémantique..."` |
| `metadata` | Object | Métadonnées associées à la tâche | Voir ci-dessous |
| `dependencies` | Array<String> | IDs des tâches dont celle-ci dépend | `["task-456", "task-789"]` |
| `subtasks` | Array<String> | IDs des sous-tâches | `["subtask-001", "subtask-002"]` |
| `history` | Array<Object> | Historique des modifications | Voir ci-dessous |

### Métadonnées

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `priority` | String | Priorité de la tâche (low, medium, high) | `"high"` |
| `estimated_duration` | String | Durée estimée (format: Xd, Xh, Xm) | `"3d"` |
| `assigned_to` | String | Identifiant de la personne assignée | `"john.doe"` |
| `tags` | Array<String> | Liste de tags associés à la tâche | `["search", "ai"]` |
| `created_at` | String | Date de création (ISO 8601) | `"2025-05-15T10:00:00Z"` |
| `updated_at` | String | Date de dernière mise à jour (ISO 8601) | `"2025-05-16T14:30:00Z"` |
| `due_date` | String | Date d'échéance (ISO 8601) | `"2025-06-01T00:00:00Z"` |
| `progress` | Number | Pourcentage d'avancement (0-100) | `25` |
| `complexity` | String | Complexité (simple, medium, complex) | `"medium"` |
| `effort` | String | Effort requis (low, medium, high) | `"high"` |
| `impact` | String | Impact (low, medium, high) | `"high"` |
| `risk` | String | Niveau de risque (low, medium, high) | `"medium"` |
| `category` | String | Catégorie de la tâche | `"backend"` |
| `milestone` | String | Jalon associé | `"v1.0"` |

### Historique

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `timestamp` | String | Date et heure de l'action (ISO 8601) | `"2025-05-15T10:00:00Z"` |
| `user` | String | Identifiant de l'utilisateur | `"jane.doe"` |
| `action` | String | Type d'action (created, updated, deleted) | `"updated"` |
| `changes` | Array<String> | Champs modifiés | `["status", "metadata.priority"]` |
| `comment` | String | Commentaire optionnel | `"Augmenté la priorité"` |

## Conversion Markdown ↔ JSON

### Règles de conversion Markdown → JSON

1. **Identification de la tâche**:
   - Format: `- [ ] **task-id** Titre de la tâche #tags`

   - Extraction de l'ID entre `**` et `**`
   - Extraction du titre après l'ID jusqu'au premier tag ou fin de ligne
   - Statut: `[ ]` = todo, `[x]` = done, `[~]` = in-progress

2. **Extraction des tags**:
   - Format: `#key:value` ou `#tag`

   - Tags spéciaux:
     - `#priority:X` → `metadata.priority`

     - `#duration:X` → `metadata.estimated_duration`

     - `#assigned:X` → `metadata.assigned_to`

     - `#tags:X,Y,Z` → `metadata.tags`

     - `#due:YYYY-MM-DD` → `metadata.due_date`

     - Autres tags → `metadata.tags`

3. **Extraction de la description**:
   - Lignes commençant par `>` après la ligne de titre
   - Concaténation avec préservation des sauts de ligne

4. **Extraction des métadonnées structurées**:
   - Format: `> **Clé**: Valeur`
   - Métadonnées spéciales:
     - `**Dépendances**` → `dependencies`
     - `**Créé le**` → `metadata.created_at` + `history`
     - `**Mis à jour le**` → `metadata.updated_at` + `history`

5. **Extraction des sous-tâches**:
   - Tâches indentées sous la tâche principale
   - Application récursive des règles 1-4

### Règles de conversion JSON → Markdown

1. **Génération de la ligne de titre**:
   - Format: `- [ ] **id** title #tags`

   - Statut: todo = `[ ]`, done = `[x]`, in-progress = `[~]`
   - Ajout des tags principaux: priority, duration, assigned_to

2. **Génération de la description**:
   - Préfixage de chaque ligne avec `> `
   - Préservation des sauts de ligne

3. **Génération des métadonnées structurées**:
   - Format: `> **Clé**: Valeur`
   - Inclusion des dépendances, dates de création/modification

4. **Génération des sous-tâches**:
   - Indentation des sous-tâches sous la tâche principale
   - Application récursive des règles 1-3

## Extensions spécifiques

### Extensions LWM (Large Workflow Models)

Pour supporter les concepts de Large Workflow Models, les extensions suivantes sont ajoutées:

```json
{
  "workflow": {
    "type": "sequential|parallel|conditional",
    "next_steps": ["task-234", "task-345"],
    "conditions": [
      {
        "condition": "status == 'done'",
        "next": "task-234"
      },
      {
        "condition": "status == 'failed'",
        "next": "task-345"
      }
    ],
    "triggers": [
      {
        "event": "task-completed",
        "source": "task-456",
        "action": "start"
      }
    ]
  }
}
```plaintext
### Extensions LCM (Large Concept Models)

Pour supporter les concepts de Large Concept Models, les extensions suivantes sont ajoutées:

```json
{
  "concepts": {
    "related": ["concept-123", "concept-456"],
    "implements": ["concept-789"],
    "attributes": {
      "domain": "search",
      "technology": "vector-database",
      "pattern": "repository"
    },
    "relations": [
      {
        "type": "uses",
        "target": "concept-123",
        "strength": 0.8
      },
      {
        "type": "implements",
        "target": "concept-456",
        "strength": 0.6
      }
    ]
  }
}
```plaintext
## Exemples complets

### Exemple 1: Tâche simple

```markdown
- [ ] **task-001** Configurer l'environnement de développement #priority:medium #duration:4h

  > Installer et configurer tous les outils nécessaires pour le développement
  > 
  > **Dépendances**: aucune
  > **Créé le**: 2025-05-10 par jane.doe
```plaintext
```json
{
  "id": "task-001",
  "title": "Configurer l'environnement de développement",
  "description": "Installer et configurer tous les outils nécessaires pour le développement",
  "status": "todo",
  "metadata": {
    "priority": "medium",
    "estimated_duration": "4h",
    "created_at": "2025-05-10T00:00:00Z"
  },
  "dependencies": [],
  "history": [
    {
      "timestamp": "2025-05-10T00:00:00Z",
      "user": "jane.doe",
      "action": "created"
    }
  ]
}
```plaintext
### Exemple 2: Tâche complexe avec sous-tâches

```markdown
- [~] **task-002** Implémenter l'authentification OAuth #priority:high #duration:2d #assigned:john.doe #tags:auth,security

  > Ajouter l'authentification OAuth avec support pour Google, GitHub et Microsoft
  > 
  > **Dépendances**: task-001
  > **Créé le**: 2025-05-12 par jane.doe
  > **Mis à jour le**: 2025-05-14 par john.doe
  
  - [x] **subtask-001** Configurer les applications OAuth chez les fournisseurs #duration:2h

  - [x] **subtask-002** Implémenter le flux d'authentification pour Google #duration:4h

  - [~] **subtask-003** Implémenter le flux d'authentification pour GitHub #duration:4h

  - [ ] **subtask-004** Implémenter le flux d'authentification pour Microsoft #duration:4h

  - [ ] **subtask-005** Ajouter les tests d'intégration #duration:4h

```plaintext
## Validation

Pour garantir la cohérence des données, un schéma JSON Schema est fourni pour valider les tâches au format JSON:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",

  "type": "object",
  "required": ["id", "title", "status"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_-]+$"
    },
    "title": {
      "type": "string",
      "minLength": 1
    },
    "description": {
      "type": "string"
    },
    "status": {
      "type": "string",
      "enum": ["todo", "in-progress", "done"]
    },
    "metadata": {
      "type": "object",
      "properties": {
        "priority": {
          "type": "string",
          "enum": ["low", "medium", "high"]
        },
        "estimated_duration": {
          "type": "string",
          "pattern": "^\\d+[dhm]$"
        },
        "assigned_to": {
          "type": "string"
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "created_at": {
          "type": "string",
          "format": "date-time"
        },
        "updated_at": {
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "dependencies": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "subtasks": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "history": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["timestamp", "user", "action"],
        "properties": {
          "timestamp": {
            "type": "string",
            "format": "date-time"
          },
          "user": {
            "type": "string"
          },
          "action": {
            "type": "string",
            "enum": ["created", "updated", "deleted"]
          },
          "changes": {
            "type": "array",
            "items": {
              "type": "string"
            }
          },
          "comment": {
            "type": "string"
          }
        }
      }
    }
  }
}
```plaintext
## Conclusion

Ce format de tâche standardisé offre une base solide pour notre système de roadmapping, en s'inspirant des meilleures pratiques du projet claude-task-master tout en l'adaptant à nos besoins spécifiques. Il permet une représentation riche et flexible des tâches, facilitant l'analyse automatique et l'interopérabilité avec d'autres outils.
