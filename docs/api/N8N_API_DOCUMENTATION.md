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

## Exemples d'utilisation

Voici quelques exemples d'utilisation de l'API n8n avec PowerShell.

### Lister tous les workflows

`powershell
$n8nUrl = "http://localhost:5678"
$apiToken = "votre-jeton-api"

$headers = @{
    "X-N8N-API-KEY" = $apiToken
}

$response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers

# Afficher les workflows
$response | Format-Table -Property id, name, active
`

### Creer un nouveau workflow

`powershell
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
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Post -Headers $headers -Body $body

# Afficher le nouveau workflow
$response | Format-Table -Property id, name
`

### Executer un workflow

`powershell
$n8nUrl = "http://localhost:5678"
$apiToken = "votre-jeton-api"
$workflowId = "123" # Remplacez par l'ID de votre workflow

$headers = @{
    "X-N8N-API-KEY" = $apiToken
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$workflowId/execute" -Method Post -Headers $headers

# Afficher le resultat de l'execution
$response | Format-Table -Property id, finished, status
`

## Remarques importantes

- Certains endpoints peuvent necessiter des permissions specifiques.
- Les endpoints qui echouent peuvent ne pas etre disponibles dans votre version de n8n ou necessiter des parametres supplementaires.
- Cette documentation a ete generee le 04/04/2025 22:08:53.
- Version de n8n testee: Verifiez votre version dans l'interface utilisateur de n8n.
