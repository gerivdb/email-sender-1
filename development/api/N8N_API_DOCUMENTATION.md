# Documentation de l'API n8n (Version locale)

Cette documentation a ete generee automatiquement en testant les endpoints de l'API n8n disponibles sur votre instance locale.

URL de base: http://localhost:5678

## Table des matieres

- [Authentification](#authentification)

- [Endpoints testes](#endpoints-testes)

  - [Workflows](#workflows)

  - [Executions](#executions)

  - [Credentials](#credentials)

  - [Tags](#tags)

  - [Utilisateurs](#utilisateurs)

  - [Autres](#autres)

- [Exemples d'utilisation](#exemples-dutilisation)

## Authentification

L'API n8n utilise un jeton d'API pour l'authentification. Vous devez inclure ce jeton dans l'en-tete X-N8N-API-KEY de vos requetes.

Exemple:
`
X-N8N-API-KEY: votre-jeton-api
`

## Endpoints testes

Voici les resultats des tests effectues sur les differents endpoints de l'API n8n.

### Autres

| Methode | Endpoint | Description | Statut | Commentaire |
| ------- | -------- | ----------- | ------ | ----------- |
| GET | /api/v1/node-types | Liste tous les types de noeuds | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |
| GET | /api/v1/node-types-description | Recupere les descriptions des types de noeuds | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |
| GET | /api/v1/variables | Liste toutes les variables | âŒ Echoue | Le serveur distant a retourné une erreur : (403) Interdit. |

### Tags

| Methode | Endpoint | Description | Statut | Commentaire |
| ------- | -------- | ----------- | ------ | ----------- |
| GET | /api/v1/tags | Liste tous les tags | âœ… Fonctionne | Fonctionne correctement |
| POST | /api/v1/tags | Cree un nouveau tag | âœ… Fonctionne | Fonctionne correctement |
| DELETE | /api/v1/tags/1 | Supprime un tag | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |

### Utilisateurs

| Methode | Endpoint | Description | Statut | Commentaire |
| ------- | -------- | ----------- | ------ | ----------- |
| GET | /api/v1/users | Liste tous les utilisateurs | âœ… Fonctionne | Fonctionne correctement |
| GET | /api/v1/users/me | Recupere l'utilisateur actuel | âŒ Echoue | Le serveur distant a retourné une erreur : (400) Demande incorrecte. |

### Executions

| Methode | Endpoint | Description | Statut | Commentaire |
| ------- | -------- | ----------- | ------ | ----------- |
| GET | /api/v1/executions | Liste toutes les executions | âœ… Fonctionne | Fonctionne correctement |
| GET | /api/v1/executions/1 | Recupere une execution specifique par ID | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |
| DELETE | /api/v1/executions/1 | Supprime une execution | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |

### Credentials

| Methode | Endpoint | Description | Statut | Commentaire |
| ------- | -------- | ----------- | ------ | ----------- |
| GET | /api/v1/credentials | Liste toutes les credentials | âŒ Echoue | Le serveur distant a retourné une erreur : (405) Méthode non autorisée. |
| GET | /api/v1/credentials/1 | Recupere une credential specifique par ID | âŒ Echoue | Le serveur distant a retourné une erreur : (405) Méthode non autorisée. |
| GET | /api/v1/credentials/types | Liste tous les types de credentials | âŒ Echoue | Le serveur distant a retourné une erreur : (405) Méthode non autorisée. |

### Workflows

| Methode | Endpoint | Description | Statut | Commentaire |
| ------- | -------- | ----------- | ------ | ----------- |
| GET | /api/v1/workflows | Liste tous les workflows | âœ… Fonctionne | Fonctionne correctement |
| GET | /api/v1/workflows/1 | Recupere un workflow specifique par ID | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |
| POST | /api/v1/workflows | Cree un nouveau workflow | âŒ Echoue | Le serveur distant a retourné une erreur : (400) Demande incorrecte. |
| PUT | /api/v1/workflows/1 | Met a jour un workflow existant | âŒ Echoue | Le serveur distant a retourné une erreur : (400) Demande incorrecte. |
| DELETE | /api/v1/workflows/1 | Supprime un workflow | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |
| POST | /api/v1/workflows/1/activate | Active un workflow | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |
| POST | /api/v1/workflows/1/deactivate | Desactive un workflow | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |
| POST | /api/v1/workflows/1/execute | Execute un workflow | âŒ Echoue | Le serveur distant a retourné une erreur : (404) Introuvable. |

## Structure d'un workflow n8n

Voici la structure complète d'un workflow n8n telle que retournée par l'API :

```json
{
  "id": "2tUt1wbLX592XDdX",
  "name": "Workflow 1",
  "active": true,
  "createdAt": "2025-04-05T00:06:48.443Z",
  "updatedAt": "2025-04-05T00:06:48.443Z",
  "nodes": [
    {
      "id": "0f5532f9-36ba-4bef-86c7-30d607400b15",
      "name": "Jira",
      "webhookId": "string",
      "disabled": true,
      "notesInFlow": true,
      "notes": "string",
      "type": "n8n-nodes-base.Jira",
      "typeVersion": 1,
      "executeOnce": false,
      "alwaysOutputData": false,
      "retryOnFail": false,
      "maxTries": 0,
      "waitBetweenTries": 0,
      "onError": "stopWorkflow",
      "position": [
        -100,
        80
      ],
      "parameters": {
        "additionalProperties": {}
      },
      "credentials": {
        "jiraSoftwareCloudApi": {
          "id": "35",
          "name": "jiraApi"
        }
      },
      "createdAt": "2025-04-05T00:06:48.443Z",
      "updatedAt": "2025-04-05T00:06:48.443Z"
    }
  ],
  "connections": {
    "main": [
      {
        "node": "Jira",
        "type": "main",
        "index": 0
      }
    ]
  },
  "settings": {
    "saveExecutionProgress": true,
    "saveManualExecutions": true,
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "all",
    "executionTimeout": 3600,
    "errorWorkflow": "VzqKEW0ShTXA5vPj",
    "timezone": "America/New_York",
    "executionOrder": "v1"
  },
  "staticData": {
    "lastId": 1
  },
  "tags": [
    {
      "id": "2tUt1wbLX592XDdX",
      "name": "Production",
      "createdAt": "2025-04-05T00:06:48.443Z",
      "updatedAt": "2025-04-05T00:06:48.443Z"
    }
  ]
}
```plaintext
### Propriétés principales d'un workflow

- **id** : Identifiant unique du workflow
- **name** : Nom du workflow
- **active** : État d'activation du workflow (true/false)
- **createdAt** : Date de création
- **updatedAt** : Date de dernière mise à jour
- **nodes** : Tableau des nœuds du workflow
  - **id** : Identifiant unique du nœud
  - **name** : Nom du nœud
  - **type** : Type de nœud (ex: n8n-nodes-base.Jira)
  - **position** : Position dans l'interface
  - **parameters** : Paramètres spécifiques au nœud
  - **credentials** : Identifiants utilisés par le nœud
- **connections** : Définit comment les nœuds sont connectés entre eux
- **settings** : Paramètres du workflow (timeout, sauvegarde des exécutions, etc.)
- **staticData** : Données statiques persistantes entre les exécutions
- **tags** : Tags associés au workflow

## Exemples d'utilisation

Voici quelques exemples d'utilisation de l'API n8n avec PowerShell.

### Lister tous les workflows

```powershell
$n8nUrl = "http://localhost:5678"
$apiToken = "votre-jeton-api"

$headers = @{
    "X-N8N-API-KEY" = $apiToken
}

$response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers

# Afficher les workflows

$response.data | Format-Table -Property id, name, active
```plaintext
### Créer un nouveau workflow

```powershell
$n8nUrl = "http://localhost:5678"
$apiToken = "votre-jeton-api"

$headers = @{
    "X-N8N-API-KEY" = $apiToken
    "Content-Type" = "application/json"
}

$body = @{
    name = "Nouveau Workflow"
    nodes = @()
    connections = @{}
    settings = @{
        executionOrder = "v1"
    }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Post -Headers $headers -Body $body

# Afficher le nouveau workflow

$response | Format-Table -Property id, name
```plaintext
### Supprimer un workflow

```powershell
$n8nUrl = "http://localhost:5678"
$apiToken = "votre-jeton-api"
$workflowId = "2tUt1wbLX592XDdX" # Remplacez par l'ID de votre workflow

$headers = @{
    "X-N8N-API-KEY" = $apiToken
}

Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$workflowId" -Method Delete -Headers $headers

Write-Host "Workflow supprimé avec succès"
```plaintext
### Exécuter un workflow

```powershell
$n8nUrl = "http://localhost:5678"
$apiToken = "votre-jeton-api"
$workflowId = "2tUt1wbLX592XDdX" # Remplacez par l'ID de votre workflow

$headers = @{
    "X-N8N-API-KEY" = $apiToken
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$workflowId/execute" -Method Post -Headers $headers

# Afficher le résultat de l'exécution

$response | Format-Table -Property id, finished, status
```plaintext
## Remarques importantes

- Certains endpoints peuvent necessiter des permissions specifiques.
- Les endpoints qui echouent peuvent ne pas etre disponibles dans votre version de n8n ou necessiter des parametres supplementaires.
- Cette documentation a ete generee le 04/04/2025 22:08:53.
- Version de n8n testee: Verifiez votre version dans l'interface utilisateur de n8n.
