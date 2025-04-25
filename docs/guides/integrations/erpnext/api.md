# API ERPNext

## Introduction

L'intégration ERPNext expose plusieurs endpoints API pour interagir avec ERPNext depuis le journal de bord. Cette page documente ces endpoints et leur utilisation.

## Endpoints API

### Configuration

#### Récupérer la configuration

```
GET /api/integrations/erpnext/config
```

Récupère la configuration actuelle de l'intégration ERPNext.

**Réponse**:
```json
{
  "enabled": true,
  "api_url": "https://erpnext.example.com",
  "api_key": "votre-cle-api",
  "api_secret": "votre-secret-api"
}
```

#### Mettre à jour la configuration

```
POST /api/integrations/erpnext/config
```

Met à jour la configuration de l'intégration ERPNext.

**Corps de la requête**:
```json
{
  "enabled": true,
  "api_url": "https://erpnext.example.com",
  "api_key": "votre-cle-api",
  "api_secret": "votre-secret-api"
}
```

**Réponse**:
```json
{
  "success": true,
  "message": "Configuration updated"
}
```

#### Tester la connexion

```
POST /api/integrations/erpnext/test-connection
```

Teste la connexion à ERPNext avec la configuration actuelle.

**Réponse**:
```json
{
  "success": true,
  "message": "Connection successful"
}
```

### Projets et tâches

#### Récupérer les projets

```
GET /api/integrations/erpnext/projects
```

Récupère la liste des projets ERPNext.

**Réponse**:
```json
[
  {
    "id": "project1",
    "name": "Project 1",
    "status": "Open",
    "description": "Description du projet 1"
  },
  {
    "id": "project2",
    "name": "Project 2",
    "status": "Completed",
    "description": "Description du projet 2"
  }
]
```

#### Récupérer les tâches

```
GET /api/integrations/erpnext/tasks
```

Récupère la liste des tâches ERPNext.

**Paramètres de requête**:
- `project` (optionnel): Filtre les tâches par projet

**Réponse**:
```json
[
  {
    "id": "task1",
    "subject": "Task 1",
    "status": "Open",
    "priority": "Medium",
    "project": "project1",
    "description": "Description de la tâche 1"
  },
  {
    "id": "task2",
    "subject": "Task 2",
    "status": "Completed",
    "priority": "High",
    "project": "project1",
    "description": "Description de la tâche 2"
  }
]
```

#### Récupérer une tâche

```
GET /api/integrations/erpnext/tasks/{task_id}
```

Récupère une tâche ERPNext spécifique.

**Réponse**:
```json
{
  "id": "task1",
  "subject": "Task 1",
  "status": "Open",
  "priority": "Medium",
  "project": "project1",
  "description": "Description de la tâche 1",
  "exp_start_date": "2023-04-05",
  "exp_end_date": "2023-04-12"
}
```

#### Créer une tâche

```
POST /api/integrations/erpnext/tasks
```

Crée une nouvelle tâche ERPNext.

**Corps de la requête**:
```json
{
  "subject": "New Task",
  "description": "Description of the new task",
  "project": "project1",
  "status": "Open",
  "priority": "Medium"
}
```

**Réponse**:
```json
{
  "success": true,
  "task_id": "task3"
}
```

#### Mettre à jour une tâche

```
PUT /api/integrations/erpnext/tasks/{task_id}
```

Met à jour une tâche ERPNext existante.

**Corps de la requête**:
```json
{
  "subject": "Updated Task",
  "description": "Updated description",
  "status": "Working",
  "priority": "High"
}
```

**Réponse**:
```json
{
  "success": true,
  "message": "Task updated"
}
```

### Synchronisation

#### Synchroniser ERPNext vers le journal

```
POST /api/integrations/erpnext/sync-to-journal
```

Synchronise les tâches ERPNext vers le journal.

**Réponse**:
```json
{
  "success": true,
  "count": 5,
  "message": "5 tasks synchronized to journal"
}
```

#### Synchroniser le journal vers ERPNext

```
POST /api/integrations/erpnext/sync-from-journal
```

Synchronise les entrées de journal vers ERPNext.

**Réponse**:
```json
{
  "success": true,
  "count": 3,
  "message": "3 entries synchronized to ERPNext"
}
```

#### Créer une note à partir d'une entrée

```
POST /api/integrations/erpnext/create-note
```

Crée une note ERPNext à partir d'une entrée de journal.

**Corps de la requête**:
```json
{
  "filename": "2023-04-05-task-example.md"
}
```

**Réponse**:
```json
{
  "success": true,
  "note_id": "note1",
  "message": "Note created"
}
```

## Utilisation avec JavaScript

Exemple d'utilisation de l'API avec JavaScript:

```javascript
// Récupérer la configuration
async function getConfig() {
  const response = await fetch('/api/integrations/erpnext/config');
  return response.json();
}

// Mettre à jour la configuration
async function updateConfig(config) {
  const response = await fetch('/api/integrations/erpnext/config', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(config)
  });
  return response.json();
}

// Synchroniser ERPNext vers le journal
async function syncToJournal() {
  const response = await fetch('/api/integrations/erpnext/sync-to-journal', {
    method: 'POST'
  });
  return response.json();
}
```

## Utilisation avec Python

Exemple d'utilisation de l'API avec Python:

```python
import requests

# Récupérer la configuration
def get_config():
    response = requests.get('http://localhost:8000/api/integrations/erpnext/config')
    return response.json()

# Mettre à jour la configuration
def update_config(config):
    response = requests.post(
        'http://localhost:8000/api/integrations/erpnext/config',
        json=config
    )
    return response.json()

# Synchroniser ERPNext vers le journal
def sync_to_journal():
    response = requests.post('http://localhost:8000/api/integrations/erpnext/sync-to-journal')
    return response.json()
```
