# Routes API de n8n

Ce document décrit les routes API disponibles dans n8n et comment les utiliser.

## Vue d'ensemble

n8n expose une API REST qui permet d'interagir avec les workflows, les exécutions, les credentials et d'autres ressources. Cette API est utilisée par l'interface web de n8n et peut également être utilisée par des applications tierces.

## Authentification

L'API n8n utilise une API Key pour l'authentification. Pour accéder aux routes protégées, vous devez inclure l'en-tête HTTP suivant dans vos requêtes :

```plaintext
X-N8N-API-KEY: votre-api-key
```plaintext
Vous pouvez configurer l'API Key dans le fichier `n8n/core/n8n-config.json` et dans le fichier `.env`.

## Routes API principales

### Système

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /healthz | Vérification de l'état de santé de n8n | Non |
| GET | /metrics | Métriques Prometheus | Non |

### Workflows

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /api/v1/workflows | Liste des workflows | Oui |
| GET | /api/v1/workflows/{id} | Obtenir un workflow spécifique | Oui |
| POST | /api/v1/workflows | Créer un nouveau workflow | Oui |
| PUT | /api/v1/workflows/{id} | Mettre à jour un workflow | Oui |
| DELETE | /api/v1/workflows/{id} | Supprimer un workflow | Oui |
| POST | /api/v1/workflows/{id}/activate | Activer un workflow | Oui |
| POST | /api/v1/workflows/{id}/deactivate | Désactiver un workflow | Oui |
| POST | /api/v1/workflows/{id}/execute | Exécuter un workflow | Oui |
| POST | /api/v1/workflows/import | Importer un workflow | Oui |
| GET | /api/v1/workflows/tags | Liste des tags de workflows | Oui |

### Exécutions

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /api/v1/executions | Liste des exécutions | Oui |
| GET | /api/v1/executions/{id} | Obtenir une exécution spécifique | Oui |
| DELETE | /api/v1/executions/{id} | Supprimer une exécution | Oui |
| GET | /api/v1/executions/active | Liste des exécutions actives | Oui |
| POST | /api/v1/executions/{id}/stop | Arrêter une exécution | Oui |

### Credentials

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /api/v1/credentials | Liste des credentials | Oui |
| GET | /api/v1/credentials/{id} | Obtenir un credential spécifique | Oui |
| POST | /api/v1/credentials | Créer un nouveau credential | Oui |
| PUT | /api/v1/credentials/{id} | Mettre à jour un credential | Oui |
| DELETE | /api/v1/credentials/{id} | Supprimer un credential | Oui |
| GET | /api/v1/credentials/types | Liste des types de credentials | Oui |

### Nodes

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /api/v1/nodes | Liste des nodes disponibles | Oui |
| GET | /api/v1/nodes/types | Liste des types de nodes | Oui |

### Variables

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /api/v1/variables | Liste des variables | Oui |
| GET | /api/v1/variables/{id} | Obtenir une variable spécifique | Oui |
| POST | /api/v1/variables | Créer une nouvelle variable | Oui |
| PUT | /api/v1/variables/{id} | Mettre à jour une variable | Oui |
| DELETE | /api/v1/variables/{id} | Supprimer une variable | Oui |

### Paramètres

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /api/v1/settings | Paramètres de n8n | Oui |
| PUT | /api/v1/settings | Mettre à jour les paramètres | Oui |

### Communauté

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
| GET | /api/v1/community-packages | Liste des packages communautaires installés | Oui |
| POST | /api/v1/community-packages | Installer un package communautaire | Oui |
| DELETE | /api/v1/community-packages/{name} | Désinstaller un package communautaire | Oui |

## Exemples d'utilisation

### PowerShell

```powershell
# Configuration de l'API Key

$apiKey = "votre-api-key"
$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Accept" = "application/json"
}
$baseUrl = "http://localhost:5678"

# Exemple: Liste des workflows

Invoke-RestMethod -Uri "$baseUrl/api/v1/workflows" -Method Get -Headers $headers

# Exemple: Obtenir un workflow spécifique

Invoke-RestMethod -Uri "$baseUrl/api/v1/workflows/123" -Method Get -Headers $headers

# Exemple: Créer un nouveau workflow

$workflow = @{
    name = "Nouveau workflow"
    active = $false
    nodes = @()
    connections = @{}
}
Invoke-RestMethod -Uri "$baseUrl/api/v1/workflows" -Method Post -Headers $headers -Body ($workflow | ConvertTo-Json -Depth 10) -ContentType "application/json"

# Exemple: Exécuter un workflow

Invoke-RestMethod -Uri "$baseUrl/api/v1/workflows/123/execute" -Method Post -Headers $headers
```plaintext
### curl

```bash
# Configuration de l'API Key

API_KEY="votre-api-key"
BASE_URL="http://localhost:5678"

# Exemple: Liste des workflows

curl -X GET "${BASE_URL}/api/v1/workflows" -H "X-N8N-API-KEY: ${API_KEY}"

# Exemple: Obtenir un workflow spécifique

curl -X GET "${BASE_URL}/api/v1/workflows/123" -H "X-N8N-API-KEY: ${API_KEY}"

# Exemple: Créer un nouveau workflow

curl -X POST "${BASE_URL}/api/v1/workflows" -H "X-N8N-API-KEY: ${API_KEY}" -H "Content-Type: application/json" -d '{"name":"Nouveau workflow","active":false,"nodes":[],"connections":{}}'

# Exemple: Exécuter un workflow

curl -X POST "${BASE_URL}/api/v1/workflows/123/execute" -H "X-N8N-API-KEY: ${API_KEY}"
```plaintext
## Outils de vérification des routes API

Pour vérifier les routes API disponibles et leur état, vous pouvez utiliser les scripts suivants :

### verify-n8n-api-routes.ps1

Ce script teste toutes les routes API connues et génère un rapport détaillé sur leur état.

```powershell
.\verify-n8n-api-routes.ps1 -DetailLevel 3 -OutputFile "api-report.md"
```plaintext
Options disponibles :
- `-ApiKey` : API Key à utiliser
- `-Hostname` : Hôte n8n (par défaut: localhost)
- `-Port` : Port n8n (par défaut: 5678)
- `-Protocol` : Protocole (http ou https) (par défaut: http)
- `-OutputFile` : Fichier de sortie pour le rapport (par défaut: n8n-api-routes-report.md)
- `-DetailLevel` : Niveau de détail du rapport (1-3, par défaut: 2)

### test-n8n-api-route.ps1

Ce script teste une route API spécifique avec différentes méthodes et paramètres.

```powershell
.\test-n8n-api-route.ps1 -Url "/api/v1/workflows" -Method "GET"
```plaintext
Options disponibles :
- `-Url` : URL de la route à tester (sans le protocole, l'hôte et le port)
- `-Method` : Méthode HTTP à utiliser (GET, POST, PUT, DELETE, etc.)
- `-ApiKey` : API Key à utiliser
- `-Hostname` : Hôte n8n (par défaut: localhost)
- `-Port` : Port n8n (par défaut: 5678)
- `-Protocol` : Protocole (http ou https) (par défaut: http)
- `-Body` : Corps de la requête au format JSON (pour les méthodes POST, PUT, etc.)
- `-OutputFormat` : Format de sortie (json ou table, par défaut: table)

### generate-api-documentation.ps1

Ce script génère une documentation complète des routes API de n8n en se basant sur les résultats de la vérification des routes.

```powershell
.\generate-api-documentation.ps1 -ApiRoutesReportFile "api-report.md" -OutputFile "api-doc.md"
```plaintext
Options disponibles :
- `-ApiRoutesReportFile` : Fichier de rapport de vérification des routes API (par défaut: n8n-api-routes-report.md)
- `-OutputFile` : Fichier de sortie pour la documentation (par défaut: n8n-api-documentation.md)
- `-IncludeExamples` : Indique si des exemples d'utilisation doivent être inclus dans la documentation (par défaut: $true)

## Résolution des problèmes

### Erreur 401 Unauthorized

Si vous recevez une erreur 401 Unauthorized, cela signifie que l'API Key n'est pas valide ou n'est pas correctement configurée. Vérifiez les points suivants :

1. Vérifiez que vous utilisez la bonne API Key
2. Vérifiez que l'API Key est correctement configurée dans les fichiers de configuration
3. Vérifiez que l'authentification par API Key est activée dans n8n

### Erreur 404 Not Found

Si vous recevez une erreur 404 Not Found, cela signifie que l'endpoint que vous essayez d'accéder n'existe pas. Vérifiez les points suivants :

1. Vérifiez que vous utilisez la bonne URL
2. Vérifiez que n8n est en cours d'exécution
3. Vérifiez que vous utilisez la bonne version de l'API (v1)

### Erreur 500 Internal Server Error

Si vous recevez une erreur 500 Internal Server Error, cela signifie qu'une erreur s'est produite sur le serveur n8n. Vérifiez les points suivants :

1. Vérifiez les logs de n8n pour plus d'informations sur l'erreur
2. Vérifiez que n8n est correctement configuré
3. Vérifiez que vous utilisez des paramètres valides dans vos requêtes
