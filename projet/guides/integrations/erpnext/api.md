# API ERPNext

## Introduction

L'intégration ERPNext expose plusieurs endpoints API pour interagir avec ERPNext depuis le journal de bord. Cette page documente ces endpoints et leur utilisation.

## Endpoints API

### Configuration

#### Récupérer la configuration

```plaintext
GET /api/integrations/erpnext/config
```plaintext
Récupère la configuration actuelle de l'intégration ERPNext.

**Réponse**:
```json
{
  "enabled": true,
  "api_url": "https://erpnext.example.com",
  "api_key": "votre-cle-api",
  "api_secret": "votre-secret-api"
}
```plaintext
#### Mettre à jour la configuration

```plaintext
POST /api/integrations/erpnext/config
```plaintext
Met à jour la configuration de l'intégration ERPNext.

**Corps de la requête**:
```json
{
  "enabled": true,
  "api_url": "https://erpnext.example.com",
  "api_key": "votre-cle-api",
  "api_secret": "votre-secret-api"
}
```plaintext
**Réponse**:
```json
{
  "success": true,
  "message": "Configuration updated"
}
```plaintext
#### Tester la connexion

```plaintext
POST /api/integrations/erpnext/test-connection
```plaintext
Teste la connexion à ERPNext avec la configuration actuelle.

**Réponse**:
```json
{
  "success": true,
  "message": "Connection successful"
}
```plaintext
### Projets et tâches

#### Récupérer les projets

```plaintext
GET /api/integrations/erpnext/projects
```plaintext
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
```plaintext
#### Récupérer les tâches

```plaintext
GET /api/integrations/erpnext/tasks
```plaintext
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
```plaintext
#### Récupérer une tâche

```plaintext
GET /api/integrations/erpnext/tasks/{task_id}
```plaintext
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
```plaintext
#### Créer une tâche

```plaintext
POST /api/integrations/erpnext/tasks
```plaintext
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
```plaintext
**Réponse**:
```json
{
  "success": true,
  "task_id": "task3"
}
```plaintext
#### Mettre à jour une tâche

```plaintext
PUT /api/integrations/erpnext/tasks/{task_id}
```plaintext
Met à jour une tâche ERPNext existante.

**Corps de la requête**:
```json
{
  "subject": "Updated Task",
  "description": "Updated description",
  "status": "Working",
  "priority": "High"
}
```plaintext
**Réponse**:
```json
{
  "success": true,
  "message": "Task updated"
}
```plaintext
### Synchronisation

#### Synchroniser ERPNext vers le journal

```plaintext
POST /api/integrations/erpnext/sync-to-journal
```plaintext
Synchronise les tâches ERPNext vers le journal.

**Réponse**:
```json
{
  "success": true,
  "count": 5,
  "message": "5 tasks synchronized to journal"
}
```plaintext
#### Synchroniser le journal vers ERPNext

```plaintext
POST /api/integrations/erpnext/sync-from-journal
```plaintext
Synchronise les entrées de journal vers ERPNext.

**Réponse**:
```json
{
  "success": true,
  "count": 3,
  "message": "3 entries synchronized to ERPNext"
}
```plaintext
#### Créer une note à partir d'une entrée

```plaintext
POST /api/integrations/erpnext/create-note
```plaintext
Crée une note ERPNext à partir d'une entrée de journal.

**Corps de la requête**:
```json
{
  "filename": "2023-04-05-task-example.md"
}
```plaintext
**Réponse**:
```json
{
  "success": true,
  "note_id": "note1",
  "message": "Note created"
}
```plaintext
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
```plaintext
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
```plaintext