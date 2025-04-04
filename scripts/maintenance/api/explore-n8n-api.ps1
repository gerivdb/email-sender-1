# Script pour explorer l'API n8n et documenter les endpoints disponibles

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT
$outputFile = "docs/api/N8N_API_DOCUMENTATION.md"

# Création du répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Parent $outputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Répertoire créé: $outputDir" -ForegroundColor Green
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

# Création de l'en-tête du fichier de documentation
$documentation = @"
# Documentation de l'API n8n (Version locale)

Cette documentation a été générée automatiquement en testant les endpoints de l'API n8n disponibles sur votre instance locale.

URL de base: $n8nUrl

## Table des matières

- [Authentification](#authentification)
- [Endpoints testés](#endpoints-testés)
  - [Workflows](#workflows)
  - [Exécutions](#exécutions)
  - [Credentials](#credentials)
  - [Tags](#tags)
  - [Utilisateurs](#utilisateurs)
  - [Autres](#autres)
- [Exemples d'utilisation](#exemples-dutilisation)

## Authentification

L'API n8n utilise un jeton d'API pour l'authentification. Vous devez inclure ce jeton dans l'en-tête `X-N8N-API-KEY` de vos requêtes.

Exemple:
```
X-N8N-API-KEY: votre-jeton-api
```

## Endpoints testés

Voici les résultats des tests effectués sur les différents endpoints de l'API n8n.

"@

# Préparation des en-têtes pour les requêtes API
$headers = @{
    "X-N8N-API-KEY" = $apiToken
}

# Liste des endpoints à tester
$endpoints = @(
    # Workflows
    @{ Method = "GET"; Endpoint = "/api/v1/workflows"; Description = "Liste tous les workflows" },
    @{ Method = "GET"; Endpoint = "/api/v1/workflows/1"; Description = "Récupère un workflow spécifique par ID" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows"; Description = "Crée un nouveau workflow"; Body = @{ name = "Test Workflow"; nodes = @(); connections = @{} } },
    @{ Method = "PUT"; Endpoint = "/api/v1/workflows/1"; Description = "Met à jour un workflow existant"; Body = @{ name = "Updated Workflow"; nodes = @(); connections = @{} } },
    @{ Method = "DELETE"; Endpoint = "/api/v1/workflows/1"; Description = "Supprime un workflow" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows/1/activate"; Description = "Active un workflow" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows/1/deactivate"; Description = "Désactive un workflow" },
    
    # Exécutions
    @{ Method = "GET"; Endpoint = "/api/v1/executions"; Description = "Liste toutes les exécutions" },
    @{ Method = "GET"; Endpoint = "/api/v1/executions/1"; Description = "Récupère une exécution spécifique par ID" },
    @{ Method = "POST"; Endpoint = "/api/v1/workflows/1/execute"; Description = "Exécute un workflow" },
    @{ Method = "DELETE"; Endpoint = "/api/v1/executions/1"; Description = "Supprime une exécution" },
    
    # Credentials
    @{ Method = "GET"; Endpoint = "/api/v1/credentials"; Description = "Liste toutes les credentials" },
    @{ Method = "GET"; Endpoint = "/api/v1/credentials/1"; Description = "Récupère une credential spécifique par ID" },
    @{ Method = "GET"; Endpoint = "/api/v1/credentials/types"; Description = "Liste tous les types de credentials" },
    
    # Tags
    @{ Method = "GET"; Endpoint = "/api/v1/tags"; Description = "Liste tous les tags" },
    @{ Method = "POST"; Endpoint = "/api/v1/tags"; Description = "Crée un nouveau tag"; Body = @{ name = "Test Tag" } },
    @{ Method = "DELETE"; Endpoint = "/api/v1/tags/1"; Description = "Supprime un tag" },
    
    # Utilisateurs
    @{ Method = "GET"; Endpoint = "/api/v1/users"; Description = "Liste tous les utilisateurs" },
    @{ Method = "GET"; Endpoint = "/api/v1/users/me"; Description = "Récupère l'utilisateur actuel" },
    
    # Autres
    @{ Method = "GET"; Endpoint = "/api/v1/node-types"; Description = "Liste tous les types de nœuds" },
    @{ Method = "GET"; Endpoint = "/api/v1/node-types-description"; Description = "Récupère les descriptions des types de nœuds" },
    @{ Method = "GET"; Endpoint = "/api/v1/variables"; Description = "Liste toutes les variables" }
)

# Test des endpoints
$results = @{}
foreach ($endpoint in $endpoints) {
    Write-Host "Test de l'endpoint: $($endpoint.Method) $($endpoint.Endpoint)" -NoNewline
    $result = Test-ApiEndpoint -Method $endpoint.Method -Endpoint $endpoint.Endpoint -Description $endpoint.Description -Headers $headers -Body $endpoint.Body
    
    $category = switch -Regex ($endpoint.Endpoint) {
        "/api/v1/workflows" { "Workflows" }
        "/api/v1/executions" { "Exécutions" }
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
        Write-Host " - Succès!" -ForegroundColor Green
    }
    else {
        Write-Host " - Échec: $($result.Error)" -ForegroundColor Red
    }
}

# Génération de la documentation pour chaque catégorie
foreach ($category in $results.Keys) {
    $documentation += "`n### $category`n`n"
    $documentation += "| Méthode | Endpoint | Description | Statut | Commentaire |`n"
    $documentation += "| ------- | -------- | ----------- | ------ | ----------- |`n"
    
    foreach ($result in $results[$category]) {
        $endpoint = $endpoints | Where-Object { $_.Description -eq $result.Description } | Select-Object -First 1
        $status = if ($result.Status -eq "Success") { "✅ Fonctionne" } else { "❌ Échoue" }
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

### Créer un nouveau workflow

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

### Exécuter un workflow

```powershell
`$n8nUrl = "http://localhost:5678"
`$apiToken = "votre-jeton-api"
`$workflowId = "123" # Remplacez par l'ID de votre workflow

`$headers = @{
    "X-N8N-API-KEY" = `$apiToken
    "Content-Type" = "application/json"
}

`$response = Invoke-RestMethod -Uri "`$n8nUrl/api/v1/workflows/`$workflowId/execute" -Method Post -Headers `$headers

# Afficher le résultat de l'exécution
`$response | Format-Table -Property id, finished, status
```

## Remarques importantes

- Certains endpoints peuvent nécessiter des permissions spécifiques.
- Les endpoints qui échouent peuvent ne pas être disponibles dans votre version de n8n ou nécessiter des paramètres supplémentaires.
- Cette documentation a été générée le $(Get-Date -Format "dd/MM/yyyy HH:mm:ss").
- Version de n8n testée: Vérifiez votre version dans l'interface utilisateur de n8n.
"@

# Écriture de la documentation dans le fichier de sortie
$documentation | Out-File -FilePath $outputFile -Encoding utf8
Write-Host "`nDocumentation générée: $outputFile" -ForegroundColor Green

# Affichage d'un résumé
$successCount = ($results.Values | ForEach-Object { $_ } | Where-Object { $_.Status -eq "Success" }).Count
$totalCount = ($results.Values | ForEach-Object { $_ }).Count

Write-Host "`nRésumé des tests:"
Write-Host "- Total des endpoints testés: $totalCount"
Write-Host "- Endpoints fonctionnels: $successCount"
Write-Host "- Endpoints non fonctionnels: $($totalCount - $successCount)"
Write-Host "`nConsultez la documentation générée pour plus de détails."
