<#
.SYNOPSIS
    Script pour générer une documentation des routes API de n8n.

.DESCRIPTION
    Ce script génère une documentation complète des routes API de n8n en se basant sur les résultats de la vérification des routes.

.PARAMETER ApiRoutesReportFile
    Fichier de rapport de vérification des routes API (par défaut: n8n-api-routes-report.md).

.PARAMETER OutputFile
    Fichier de sortie pour la documentation (par défaut: n8n-api-documentation.md).

.PARAMETER IncludeExamples
    Indique si des exemples d'utilisation doivent être inclus dans la documentation (par défaut: $true).

.EXAMPLE
    .\generate-api-documentation.ps1 -ApiRoutesReportFile "api-report.md" -OutputFile "api-doc.md"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ApiRoutesReportFile = "n8n-api-routes-report.md",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "n8n-api-documentation.md",
    
    [Parameter(Mandatory=$false)]
    [bool]$IncludeExamples = $true
)

# Vérifier si le fichier de rapport existe
if (-not (Test-Path -Path $ApiRoutesReportFile)) {
    Write-Error "Le fichier de rapport n'existe pas: $ApiRoutesReportFile"
    Write-Host "Exécutez d'abord le script verify-n8n-api-routes.ps1 pour générer le rapport." -ForegroundColor Yellow
    exit 1
}

# Lire le contenu du fichier de rapport
$reportContent = Get-Content -Path $ApiRoutesReportFile -Raw

# Extraire les informations du rapport
$baseUrl = if ($reportContent -match "URL de base: (.+)") { $matches[1] } else { "http://localhost:5678" }
$totalRoutes = if ($reportContent -match "Total des routes testées: (\d+)") { [int]$matches[1] } else { 0 }
$successCount = if ($reportContent -match "Succès: (\d+)") { [int]$matches[1] } else { 0 }
$failureCount = if ($reportContent -match "Échecs: (\d+)") { [int]$matches[1] } else { 0 }
$successRate = if ($reportContent -match "Taux de réussite: ([\d\.]+)%") { [double]$matches[1] } else { 0 }

# Extraire les routes fonctionnelles
$functionalRoutes = @()
$inFunctionalRoutesSection = $false
$routePattern = "\| ([A-Z]+) \| (.+?) \| (.+?) \| (.+?) \| ([\d\.]+) \|"

foreach ($line in $reportContent -split "`n") {
    if ($line -match "### Routes fonctionnelles") {
        $inFunctionalRoutesSection = $true
        continue
    }
    
    if ($inFunctionalRoutesSection -and $line -match "### Routes non fonctionnelles") {
        $inFunctionalRoutesSection = $false
        continue
    }
    
    if ($inFunctionalRoutesSection -and $line -match $routePattern) {
        $functionalRoutes += @{
            Method = $matches[1]
            Url = $matches[2]
            Description = $matches[3]
            Category = $matches[4]
            Duration = $matches[5]
        }
    }
}

# Extraire les routes non fonctionnelles
$nonFunctionalRoutes = @()
$inNonFunctionalRoutesSection = $false
$errorRoutePattern = "\| ([A-Z]+) \| (.+?) \| (.+?) \| (.+?) \| ([\d]+) \|"

foreach ($line in $reportContent -split "`n") {
    if ($line -match "### Routes non fonctionnelles") {
        $inNonFunctionalRoutesSection = $true
        continue
    }
    
    if ($inNonFunctionalRoutesSection -and $line -match "## ") {
        $inNonFunctionalRoutesSection = $false
        continue
    }
    
    if ($inNonFunctionalRoutesSection -and $line -match $errorRoutePattern) {
        $nonFunctionalRoutes += @{
            Method = $matches[1]
            Url = $matches[2]
            Description = $matches[3]
            Category = $matches[4]
            StatusCode = $matches[5]
        }
    }
}

# Générer la documentation
$documentationContent = @"
# Documentation de l'API n8n

Cette documentation décrit les routes API disponibles dans n8n et leur utilisation.

## Vue d'ensemble

- **URL de base**: $baseUrl
- **Total des routes documentées**: $totalRoutes
- **Routes fonctionnelles**: $successCount
- **Routes non fonctionnelles**: $failureCount
- **Taux de disponibilité**: $successRate%

## Authentification

L'API n8n utilise une API Key pour l'authentification. Pour accéder aux routes protégées, vous devez inclure l'en-tête HTTP suivant dans vos requêtes :

```
X-N8N-API-KEY: votre-api-key
```

Vous pouvez configurer l'API Key dans le fichier `n8n/core/n8n-config.json` et dans le fichier `.env`.

## Routes API par catégorie

"@

# Regrouper les routes par catégorie
$routesByCategory = @{}

foreach ($route in $functionalRoutes) {
    if (-not $routesByCategory.ContainsKey($route.Category)) {
        $routesByCategory[$route.Category] = @()
    }
    
    $routesByCategory[$route.Category] += $route
}

# Ajouter les routes par catégorie
foreach ($category in $routesByCategory.Keys | Sort-Object) {
    $documentationContent += @"

### $category

| Méthode | URL | Description | Authentification requise |
|---------|-----|-------------|--------------------------|
"@
    
    foreach ($route in $routesByCategory[$category] | Sort-Object -Property Url) {
        $requiresAuth = if ($route.Url -match "/api/") { "Oui" } else { "Non" }
        $documentationContent += @"
| $($route.Method) | $($route.Url) | $($route.Description) | $requiresAuth |
"@
    }
}

# Ajouter des exemples d'utilisation si demandé
if ($IncludeExamples) {
    $documentationContent += @"

## Exemples d'utilisation

### PowerShell

```powershell
# Configuration de l'API Key
$apiKey = "votre-api-key"
$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Accept" = "application/json"
}
$baseUrl = "$baseUrl"

# Exemple: Liste des workflows
Invoke-RestMethod -Uri "$($baseUrl)/api/v1/workflows" -Method Get -Headers $headers

# Exemple: Obtenir un workflow spécifique
Invoke-RestMethod -Uri "$($baseUrl)/api/v1/workflows/123" -Method Get -Headers $headers

# Exemple: Créer un nouveau workflow
$workflow = @{
    name = "Nouveau workflow"
    active = $false
    nodes = @()
    connections = @{}
}
Invoke-RestMethod -Uri "$($baseUrl)/api/v1/workflows" -Method Post -Headers $headers -Body ($workflow | ConvertTo-Json -Depth 10) -ContentType "application/json"

# Exemple: Mettre à jour un workflow
$workflow = @{
    name = "Workflow mis à jour"
    active = $true
}
Invoke-RestMethod -Uri "$($baseUrl)/api/v1/workflows/123" -Method Put -Headers $headers -Body ($workflow | ConvertTo-Json -Depth 10) -ContentType "application/json"

# Exemple: Supprimer un workflow
Invoke-RestMethod -Uri "$($baseUrl)/api/v1/workflows/123" -Method Delete -Headers $headers

# Exemple: Exécuter un workflow
Invoke-RestMethod -Uri "$($baseUrl)/api/v1/workflows/123/execute" -Method Post -Headers $headers
```

### curl

```bash
# Configuration de l'API Key
API_KEY="votre-api-key"
BASE_URL="$baseUrl"

# Exemple: Liste des workflows
curl -X GET "$\{BASE_URL}/api/v1/workflows" -H "X-N8N-API-KEY: $\{API_KEY}"

# Exemple: Obtenir un workflow spécifique
curl -X GET "$\{BASE_URL}/api/v1/workflows/123" -H "X-N8N-API-KEY: $\{API_KEY}"

# Exemple: Créer un nouveau workflow
curl -X POST "$\{BASE_URL}/api/v1/workflows" -H "X-N8N-API-KEY: $\{API_KEY}" -H "Content-Type: application/json" -d '{"name":"Nouveau workflow","active":false,"nodes":[],"connections":{}}'

# Exemple: Mettre à jour un workflow
curl -X PUT "$\{BASE_URL}/api/v1/workflows/123" -H "X-N8N-API-KEY: $\{API_KEY}" -H "Content-Type: application/json" -d '{"name":"Workflow mis à jour","active":true}'

# Exemple: Supprimer un workflow
curl -X DELETE "$\{BASE_URL}/api/v1/workflows/123" -H "X-N8N-API-KEY: $\{API_KEY}"

# Exemple: Exécuter un workflow
curl -X POST "$\{BASE_URL}/api/v1/workflows/123/execute" -H "X-N8N-API-KEY: $\{API_KEY}"
```

### JavaScript (fetch)

```javascript
// Configuration de l'API Key
const apiKey = 'votre-api-key';
const baseUrl = '$baseUrl';
const headers = {
  'X-N8N-API-KEY': apiKey,
  'Accept': 'application/json',
  'Content-Type': 'application/json'
};

// Exemple: Liste des workflows
fetch(`$\{baseUrl}/api/v1/workflows`, {
  method: 'GET',
  headers: headers
})
.then(response => response.json())
.then(data => console.log(data));

// Exemple: Créer un nouveau workflow
const workflow = {
  name: 'Nouveau workflow',
  active: false,
  nodes: [],
  connections: {}
};

fetch(`$\{baseUrl}/api/v1/workflows`, {
  method: 'POST',
  headers: headers,
  body: JSON.stringify(workflow)
})
.then(response => response.json())
.then(data => console.log(data));
```

### Python (requests)

```python
import requests
import json

# Configuration de l'API Key
api_key = "votre-api-key"
base_url = "$baseUrl"
headers = {
    "X-N8N-API-KEY": api_key,
    "Accept": "application/json",
    "Content-Type": "application/json"
}

# Exemple: Liste des workflows
response = requests.get(f"{base_url}/api/v1/workflows", headers=headers)
workflows = response.json()
print(workflows)

# Exemple: Créer un nouveau workflow
workflow = {
    "name": "Nouveau workflow",
    "active": False,
    "nodes": [],
    "connections": {}
}
response = requests.post(f"{base_url}/api/v1/workflows", headers=headers, data=json.dumps(workflow))
new_workflow = response.json()
print(new_workflow)
```
"@
}

# Ajouter des informations sur les routes non fonctionnelles
if ($nonFunctionalRoutes.Count -gt 0) {
    $documentationContent += @"

## Routes non fonctionnelles

Les routes suivantes ont été testées mais ne sont pas fonctionnelles. Cela peut être dû à des problèmes de configuration, des limitations de l'API ou des fonctionnalités non implémentées.

| Méthode | URL | Description | Catégorie | Code d'erreur |
|---------|-----|-------------|-----------|---------------|
"@
    
    foreach ($route in $nonFunctionalRoutes | Sort-Object -Property Category, Url) {
        $documentationContent += @"
| $($route.Method) | $($route.Url) | $($route.Description) | $($route.Category) | $($route.StatusCode) |
"@
    }
}

# Ajouter des informations sur la génération de la documentation
$documentationContent += @"

---

*Cette documentation a été générée automatiquement le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") à partir des résultats de la vérification des routes API.*
"@

# Écrire la documentation dans un fichier
$documentationContent | Out-File -FilePath $OutputFile -Encoding utf8
Write-Host "Documentation générée: $OutputFile" -ForegroundColor Green

# Retourner les informations
return @{
    BaseUrl = $baseUrl
    TotalRoutes = $totalRoutes
    FunctionalRoutes = $functionalRoutes
    NonFunctionalRoutes = $nonFunctionalRoutes
    SuccessRate = $successRate
}
