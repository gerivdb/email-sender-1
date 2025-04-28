# Script pour explorer l'API n8n et documenter les endpoints disponibles

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT
$outputFile = "docs/api/N8N_API_DOCUMENTATION.md"

# CrÃ©ation du rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Parent $outputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "RÃ©pertoire crÃ©Ã©: $outputDir" -ForegroundColor Green
}

# Fonction pour tester un endpoint API
function Test-ApiEndpoint {
    param (
        [string]$Method,
        [string]$Endpoint,
        [string]$Description,
        [hashtable]$Headers,
        [object]$Body = $null
    )
    
    try {
        $params = @{
            Method = $Method
            Uri = "$n8nUrl$Endpoint"
            Headers = $Headers
            ContentType = "application/json"
            ErrorAction = "Stop"
        }
        
        if ($Body -ne $null -and $Method -ne "GET") {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        return @{
            Status = "Success"
            Response = $response
            Description = $Description
        }
    }
    catch {
        return @{
            Status = "Error"
            Error = $_.Exception.Message
            Description = $Description
        }
    }
}

# CrÃ©ation de l'en-tÃªte du fichier de documentation
$documentation = @"
# Documentation de l'API n8n (Version locale)

Cette documentation a Ã©tÃ© gÃ©nÃ©rÃ©e automatiquement en testant les endpoints de l'API n8n disponibles sur votre instance locale.

URL de base: $n8nUrl

## Table des matiÃ¨res

- [Authentification](#authentification)
- [Endpoints testÃ©s](#endpoints-testÃ©s)
  - [Workflows](#workflows)
  - [ExÃ©cutions](#exÃ©cutions)
  - [Credentials](#credentials)
  - [Tags](#tags)
  - [Utilisateurs](#utilisateurs)
  - [Autres](#autres)
- [Exemples d'utilisation](#exemples-dutilisation)

## Authentification

L'API n8n utilise un jeton d'API pour l'authentification. Vous devez inclure ce jeton dans l'en-tÃªte `X-N8N-API-KEY` de vos requÃªtes.

Exemple:
```
X-N8N-API-KEY: votre-jeton-api
```

## Endpoints testÃ©s

Voici les rÃ©sultats des tests effectuÃ©s sur les diffÃ©rents endpoints de l'API n8n.

"@

# PrÃ©paration des en-tÃªtes pour les requÃªtes API
$headers = @{
    "X-N8N-API-KEY" = $apiToken
}

# Liste des endpoints Ã  tester
$endpoints = @(
    # Workflows
    @{ Method = "GET"; Endpoint = "/api/v1/workflows"; Description = "Liste tous les workflows" },
    @{ Method = "GET"; Endpoint = "/api/v1/workflows/1"; Description = "RÃ©cupÃ¨re un workflow spÃ©cifique par ID" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows"; Description = "CrÃ©e un nouveau workflow"; Body = @{ name = "Test Workflow"; nodes = @(); connections = @{} } },
    @{ Method = "PUT"; Endpoint = "/api/v1/workflows/1"; Description = "Met Ã  jour un workflow existant"; Body = @{ name = "Updated Workflow"; nodes = @(); connections = @{} } },
    @{ Method = "DELETE"; Endpoint = "/api/v1/workflows/1"; Description = "Supprime un workflow" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows/1/activate"; Description = "Active un workflow" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows/1/deactivate"; Description = "DÃ©sactive un workflow" },
    
    # ExÃ©cutions
    @{ Method = "GET"; Endpoint = "/api/v1/executions"; Description = "Liste toutes les exÃ©cutions" },
    @{ Method = "GET"; Endpoint = "/api/v1/executions/1"; Description = "RÃ©cupÃ¨re une exÃ©cution spÃ©cifique par ID" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows/1/execute"; Description = "ExÃ©cute un workflow" },
    @{ Method = "DELETE"; Endpoint = "/api/v1/executions/1"; Description = "Supprime une exÃ©cution" },
    
    # Credentials
    @{ Method = "GET"; Endpoint = "/api/v1/credentials"; Description = "Liste toutes les credentials" },
    @{ Method = "GET"; Endpoint = "/api/v1/credentials/1"; Description = "RÃ©cupÃ¨re une credential spÃ©cifique par ID" },
    @{ Method = "GET"; Endpoint = "/api/v1/credentials/types"; Description = "Liste tous les types de credentials" },
    
    # Tags
    @{ Method = "GET"; Endpoint = "/api/v1/tags"; Description = "Liste tous les tags" },
    @{ Method = "POST"; Endpoint = "/api/v1/tags"; Description = "CrÃ©e un nouveau tag"; Body = @{ name = "Test Tag" } },
    @{ Method = "DELETE"; Endpoint = "/api/v1/tags/1"; Description = "Supprime un tag" },
    
    # Utilisateurs
    @{ Method = "GET"; Endpoint = "/api/v1/users"; Description = "Liste tous les utilisateurs" },
    @{ Method = "GET"; Endpoint = "/api/v1/users/me"; Description = "RÃ©cupÃ¨re l'utilisateur actuel" },
    
    # Autres
    @{ Method = "GET"; Endpoint = "/api/v1/node-types"; Description = "Liste tous les types de nÅ“uds" },
    @{ Method = "GET"; Endpoint = "/api/v1/node-types-description"; Description = "RÃ©cupÃ¨re les descriptions des types de nÅ“uds" },
    @{ Method = "GET"; Endpoint = "/api/v1/variables"; Description = "Liste toutes les variables" }
)

# Test des endpoints
$results = @{}
foreach ($endpoint in $endpoints) {
    Write-Host "Test de l'endpoint: $($endpoint.Method) $($endpoint.Endpoint)" -NoNewline
    $result = Test-ApiEndpoint -Method $endpoint.Method -Endpoint $endpoint.Endpoint -Description $endpoint.Description -Headers $headers -Body $endpoint.Body
    
    $category = switch -Regex ($endpoint.Endpoint) {
        "/api/v1/workflows" { "Workflows" }
        "/api/v1/executions" { "ExÃ©cutions" }
        "/api/v1/credentials" { "Credentials" }
        "/api/v1/tags" { "Tags" }
        "/api/v1/users" { "Utilisateurs" }
        default { "Autres" }
    }
    
    if (-not $results.ContainsKey($category)) {
        $results[$category] = @()
    }
    
    $results[$category] += $result
    
    if ($result.Status -eq "Success") {
        Write-Host " - SuccÃ¨s!" -ForegroundColor Green
    }
    else {
        Write-Host " - Ã‰chec: $($result.Error)" -ForegroundColor Red
    }
}

# GÃ©nÃ©ration de la documentation pour chaque catÃ©gorie
foreach ($category in $results.Keys) {
    $documentation += "`n### $category`n`n"
    $documentation += "| MÃ©thode | Endpoint | Description | Statut | Commentaire |`n"
    $documentation += "| ------- | -------- | ----------- | ------ | ----------- |`n"
    
    foreach ($result in $results[$category]) {
        $endpoint = $endpoints | Where-Object { $_.Description -eq $result.Description } | Select-Object -First 1
        $status = if ($result.Status -eq "Success") { "âœ… Fonctionne" } else { "âŒ Ã‰choue" }
        $comment = if ($result.Status -eq "Success") { "Fonctionne correctement" } else { $result.Error }
        
        $documentation += "| $($endpoint.Method) | $($endpoint.Endpoint) | $($result.Description) | $status | $comment |`n"
    }
}

# Ajout d'exemples d'utilisation
$documentation += @"

## Exemples d'utilisation

Voici quelques exemples d'utilisation de l'API n8n avec PowerShell.

### Lister tous les workflows

```powershell
`$n8nUrl = "http://localhost:5678"
`$apiToken = "votre-jeton-api"

`$headers = @{
    "X-N8N-API-KEY" = `$apiToken
}

`$response = Invoke-RestMethod -Uri "`$n8nUrl/api/v1/workflows" -Method Get -Headers `$headers

# Afficher les workflows
`$response | Format-Table -Property id, name, active
```

### CrÃ©er un nouveau workflow

```powershell
`$n8nUrl = "http://localhost:5678"
`$apiToken = "votre-jeton-api"

`$headers = @{
    "X-N8N-API-KEY" = `$apiToken
    "Content-Type" = "application/json"
}

`$body = @{
    name = "Nouveau Workflow"
    nodes = @()
    connections = @{}
} | ConvertTo-Json -Depth 10

`$response = Invoke-RestMethod -Uri "`$n8nUrl/api/v1/workflows" -Method Post -Headers `$headers -Body `$body

# Afficher le nouveau workflow
`$response | Format-Table -Property id, name
```

### ExÃ©cuter un workflow

```powershell
`$n8nUrl = "http://localhost:5678"
`$apiToken = "votre-jeton-api"
`$workflowId = "123" # Remplacez par l'ID de votre workflow

`$headers = @{
    "X-N8N-API-KEY" = `$apiToken
    "Content-Type" = "application/json"
}

`$response = Invoke-RestMethod -Uri "`$n8nUrl/api/v1/workflows/`$workflowId/execute" -Method Post -Headers `$headers

# Afficher le rÃ©sultat de l'exÃ©cution
`$response | Format-Table -Property id, finished, status
```

## Remarques importantes

- Certains endpoints peuvent nÃ©cessiter des permissions spÃ©cifiques.
- Les endpoints qui Ã©chouent peuvent ne pas Ãªtre disponibles dans votre version de n8n ou nÃ©cessiter des paramÃ¨tres supplÃ©mentaires.
- Cette documentation a Ã©tÃ© gÃ©nÃ©rÃ©e le $(Get-Date -Format "dd/MM/yyyy HH:mm:ss").
- Version de n8n testÃ©e: VÃ©rifiez votre version dans l'interface utilisateur de n8n.
"@

# Ã‰criture de la documentation dans le fichier de sortie
$documentation | Out-File -FilePath $outputFile -Encoding utf8
Write-Host "`nDocumentation gÃ©nÃ©rÃ©e: $outputFile" -ForegroundColor Green

# Affichage d'un rÃ©sumÃ©
$successCount = ($results.Values | ForEach-Object { $_ } | Where-Object { $_.Status -eq "Success" }).Count
$totalCount = ($results.Values | ForEach-Object { $_ }).Count

Write-Host "`nRÃ©sumÃ© des tests:"
Write-Host "- Total des endpoints testÃ©s: $totalCount"
Write-Host "- Endpoints fonctionnels: $successCount"
Write-Host "- Endpoints non fonctionnels: $($totalCount - $successCount)"
Write-Host "`nConsultez la documentation gÃ©nÃ©rÃ©e pour plus de dÃ©tails."
