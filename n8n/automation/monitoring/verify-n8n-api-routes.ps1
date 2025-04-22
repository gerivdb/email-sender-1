<#
.SYNOPSIS
    Script de vérification des routes API de n8n.

.DESCRIPTION
    Ce script cartographie et vérifie les routes API disponibles dans n8n.

.PARAMETER ApiKey
    API Key à utiliser. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Hostname
    Hôte n8n (par défaut: localhost).

.PARAMETER Port
    Port n8n (par défaut: 5678).

.PARAMETER Protocol
    Protocole (http ou https) (par défaut: http).

.PARAMETER OutputFile
    Fichier de sortie pour le rapport de vérification (par défaut: n8n-api-routes-report.md).

.PARAMETER DetailLevel
    Niveau de détail du rapport (1-3, par défaut: 2).

.EXAMPLE
    .\verify-n8n-api-routes.ps1 -DetailLevel 3 -OutputFile "api-report.md"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Hostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory=$false)]
    [string]$Protocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "n8n-api-routes-report.md",
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 3)]
    [int]$DetailLevel = 2
)

# Fonction pour récupérer l'API Key depuis les fichiers de configuration
function Get-ApiKeyFromConfig {
    # Essayer de récupérer l'API Key depuis le fichier de configuration
    $configFile = Join-Path -Path (Get-Location) -ChildPath "n8n/core/n8n-config.json"
    if (Test-Path -Path $configFile) {
        try {
            $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
            if ($config.security -and $config.security.apiKey -and $config.security.apiKey.value) {
                return $config.security.apiKey.value
            }
        } catch {
            Write-Warning "Erreur lors de la lecture du fichier de configuration: $_"
        }
    }
    
    # Essayer de récupérer l'API Key depuis le fichier .env
    $envFile = Join-Path -Path (Get-Location) -ChildPath "n8n/.env"
    if (Test-Path -Path $envFile) {
        try {
            $envContent = Get-Content -Path $envFile
            foreach ($line in $envContent) {
                if ($line -match "^N8N_API_KEY=(.+)$") {
                    return $matches[1]
                }
            }
        } catch {
            Write-Warning "Erreur lors de la lecture du fichier .env: $_"
        }
    }
    
    return ""
}

# Fonction pour tester une route API
function Test-ApiRoute {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory=$false)]
        [object]$Body = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = ""
    )
    
    try {
        $headers = @{
            "Accept" = "application/json"
        }
        
        if (-not [string]::IsNullOrEmpty($ApiKey)) {
            $headers["X-N8N-API-KEY"] = $ApiKey
        }
        
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $headers
            ErrorAction = "Stop"
        }
        
        if ($null -ne $Body) {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
            $params["ContentType"] = "application/json"
        }
        
        $startTime = Get-Date
        $response = Invoke-RestMethod @params
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            Success = $true
            StatusCode = 200
            Response = $response
            Error = $null
            Duration = $duration
            Description = $Description
        }
    } catch {
        $statusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        $errorMessage = $_.Exception.Message
        
        # Essayer de lire le corps de la réponse d'erreur
        $responseBody = $null
        if ($_.Exception.Response) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
            } catch {
                # Ignorer les erreurs lors de la lecture du corps de la réponse
            }
        }
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Response = $null
            Error = $errorMessage
            ErrorBody = $responseBody
            Duration = 0
            Description = $Description
        }
    }
}

# Définition des routes API à tester
$apiRoutes = @(
    # Routes de base
    @{
        Url = "/healthz"
        Method = "GET"
        Description = "Vérification de l'état de santé de n8n"
        Category = "Système"
        RequiresAuth = $false
    },
    @{
        Url = "/metrics"
        Method = "GET"
        Description = "Métriques Prometheus"
        Category = "Système"
        RequiresAuth = $false
    },
    
    # Routes d'authentification
    @{
        Url = "/rest/login"
        Method = "POST"
        Description = "Authentification (login)"
        Category = "Authentification"
        RequiresAuth = $false
        Body = @{
            email = "user@example.com"
            password = "password"
        }
    },
    
    # Routes de workflows
    @{
        Url = "/api/v1/workflows"
        Method = "GET"
        Description = "Liste des workflows"
        Category = "Workflows"
        RequiresAuth = $true
    },
    @{
        Url = "/api/v1/workflows/tags"
        Method = "GET"
        Description = "Liste des tags de workflows"
        Category = "Workflows"
        RequiresAuth = $true
    },
    @{
        Url = "/api/v1/workflows/new"
        Method = "GET"
        Description = "Obtenir un nouveau workflow vide"
        Category = "Workflows"
        RequiresAuth = $true
    },
    
    # Routes d'exécutions
    @{
        Url = "/api/v1/executions"
        Method = "GET"
        Description = "Liste des exécutions"
        Category = "Exécutions"
        RequiresAuth = $true
    },
    @{
        Url = "/api/v1/executions/active"
        Method = "GET"
        Description = "Liste des exécutions actives"
        Category = "Exécutions"
        RequiresAuth = $true
    },
    
    # Routes de credentials
    @{
        Url = "/api/v1/credentials"
        Method = "GET"
        Description = "Liste des credentials"
        Category = "Credentials"
        RequiresAuth = $true
    },
    @{
        Url = "/api/v1/credentials/types"
        Method = "GET"
        Description = "Liste des types de credentials"
        Category = "Credentials"
        RequiresAuth = $true
    },
    
    # Routes de nodes
    @{
        Url = "/api/v1/nodes"
        Method = "GET"
        Description = "Liste des nodes disponibles"
        Category = "Nodes"
        RequiresAuth = $true
    },
    @{
        Url = "/api/v1/nodes/types"
        Method = "GET"
        Description = "Liste des types de nodes"
        Category = "Nodes"
        RequiresAuth = $true
    },
    
    # Routes de variables
    @{
        Url = "/api/v1/variables"
        Method = "GET"
        Description = "Liste des variables"
        Category = "Variables"
        RequiresAuth = $true
    },
    
    # Routes de paramètres
    @{
        Url = "/api/v1/settings"
        Method = "GET"
        Description = "Paramètres de n8n"
        Category = "Paramètres"
        RequiresAuth = $true
    },
    
    # Routes de communauté
    @{
        Url = "/api/v1/community-packages"
        Method = "GET"
        Description = "Liste des packages communautaires installés"
        Category = "Communauté"
        RequiresAuth = $true
    }
)

# Récupérer l'API Key si non spécifiée
if ([string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = Get-ApiKeyFromConfig
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Warning "Aucune API Key trouvée. Les routes nécessitant une authentification échoueront probablement."
    } else {
        Write-Host "API Key récupérée depuis la configuration: $ApiKey" -ForegroundColor Green
    }
} else {
    Write-Host "API Key spécifiée: $ApiKey" -ForegroundColor Green
}

# Afficher les informations de test
Write-Host "`n=== Vérification des routes API n8n ===" -ForegroundColor Cyan
Write-Host "URL de base: $Protocol`://$Hostname`:$Port" -ForegroundColor Cyan
Write-Host "API Key: $(if ([string]::IsNullOrEmpty($ApiKey)) { "Non spécifiée" } else { $ApiKey })" -ForegroundColor Cyan
Write-Host "Nombre de routes à tester: $($apiRoutes.Count)" -ForegroundColor Cyan
Write-Host "Niveau de détail: $DetailLevel" -ForegroundColor Cyan
Write-Host "Fichier de sortie: $OutputFile" -ForegroundColor Cyan

# Tester chaque route API
$results = @()
$successCount = 0
$failureCount = 0
$categories = @{}

foreach ($route in $apiRoutes) {
    $url = "$Protocol`://$Hostname`:$Port$($route.Url)"
    Write-Host "`nTest de la route: $($route.Method) $url" -ForegroundColor Yellow
    Write-Host "  Description: $($route.Description)" -ForegroundColor Yellow
    Write-Host "  Catégorie: $($route.Category)" -ForegroundColor Yellow
    Write-Host "  Authentification requise: $($route.RequiresAuth)" -ForegroundColor Yellow
    
    # Tester la route
    $routeApiKey = if ($route.RequiresAuth) { $ApiKey } else { "" }
    $result = Test-ApiRoute -Url $url -Method $route.Method -ApiKey $routeApiKey -Body $route.Body -Description $route.Description
    
    # Ajouter la catégorie au résultat
    $result.Category = $route.Category
    $result.Url = $route.Url
    $result.Method = $route.Method
    $result.RequiresAuth = $route.RequiresAuth
    
    # Mettre à jour les compteurs
    if ($result.Success) {
        $successCount++
        Write-Host "  Succès! (Code: $($result.StatusCode), Durée: $($result.Duration) ms)" -ForegroundColor Green
    } else {
        $failureCount++
        Write-Host "  Échec! (Code: $($result.StatusCode))" -ForegroundColor Red
        Write-Host "  Erreur: $($result.Error)" -ForegroundColor Red
        
        if (-not [string]::IsNullOrEmpty($result.ErrorBody)) {
            Write-Host "  Corps de l'erreur: $($result.ErrorBody)" -ForegroundColor Red
        }
    }
    
    # Ajouter le résultat à la liste
    $results += $result
    
    # Mettre à jour les statistiques par catégorie
    if (-not $categories.ContainsKey($route.Category)) {
        $categories[$route.Category] = @{
            Total = 0
            Success = 0
            Failure = 0
        }
    }
    
    $categories[$route.Category].Total++
    if ($result.Success) {
        $categories[$route.Category].Success++
    } else {
        $categories[$route.Category].Failure++
    }
}

# Afficher le résumé
Write-Host "`n=== Résumé de la vérification ===" -ForegroundColor Cyan
Write-Host "Total des routes testées: $($apiRoutes.Count)" -ForegroundColor Cyan
Write-Host "Succès: $successCount" -ForegroundColor Green
Write-Host "Échecs: $failureCount" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Afficher les statistiques par catégorie
Write-Host "`n=== Statistiques par catégorie ===" -ForegroundColor Cyan
foreach ($category in $categories.Keys | Sort-Object) {
    $stats = $categories[$category]
    $successRate = [Math]::Round(($stats.Success / $stats.Total) * 100, 2)
    Write-Host "$category`: $($stats.Success)/$($stats.Total) ($successRate%)" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -gt 50) { "Yellow" } else { "Red" })
}

# Générer le rapport
$reportContent = @"
# Rapport de vérification des routes API n8n

## Informations générales

- **Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **URL de base**: $Protocol`://$Hostname`:$Port
- **Total des routes testées**: $($apiRoutes.Count)
- **Succès**: $successCount
- **Échecs**: $failureCount
- **Taux de réussite**: $([Math]::Round(($successCount / $apiRoutes.Count) * 100, 2))%

## Statistiques par catégorie

| Catégorie | Succès | Total | Taux de réussite |
|-----------|--------|-------|-----------------|
$(foreach ($category in $categories.Keys | Sort-Object) {
    $stats = $categories[$category]
    $successRate = [Math]::Round(($stats.Success / $stats.Total) * 100, 2)
    "| $category | $($stats.Success) | $($stats.Total) | $successRate% |"
})

## Détails des routes testées

"@

# Ajouter les détails des routes en fonction du niveau de détail
if ($DetailLevel -ge 2) {
    $reportContent += @"

### Routes fonctionnelles

| Méthode | URL | Description | Catégorie | Durée (ms) |
|---------|-----|-------------|-----------|------------|
$(foreach ($result in $results | Where-Object { $_.Success } | Sort-Object -Property Category, Url) {
    "| $($result.Method) | $($result.Url) | $($result.Description) | $($result.Category) | $($result.Duration) |"
})

### Routes non fonctionnelles

| Méthode | URL | Description | Catégorie | Code d'erreur |
|---------|-----|-------------|-----------|---------------|
$(foreach ($result in $results | Where-Object { -not $_.Success } | Sort-Object -Property Category, Url) {
    "| $($result.Method) | $($result.Url) | $($result.Description) | $($result.Category) | $($result.StatusCode) |"
})
"@
}

# Ajouter les exemples d'utilisation si le niveau de détail est élevé
if ($DetailLevel -ge 3) {
    $reportContent += @"

## Exemples d'utilisation

### PowerShell

```powershell
# Exemple de liste des workflows
Invoke-RestMethod -Uri "$Protocol`://$Hostname`:$Port/api/v1/workflows" -Method Get -Headers @{"X-N8N-API-KEY" = "votre-api-key"}

# Exemple d'exécution d'un workflow
Invoke-RestMethod -Uri "$Protocol`://$Hostname`:$Port/api/v1/workflows/123/execute" -Method Post -Headers @{"X-N8N-API-KEY" = "votre-api-key"}

# Exemple de création d'un workflow
$workflow = @{
    name = "Nouveau workflow"
    active = $false
    nodes = @()
    connections = @{}
}
Invoke-RestMethod -Uri "$Protocol`://$Hostname`:$Port/api/v1/workflows" -Method Post -Headers @{"X-N8N-API-KEY" = "votre-api-key"} -Body ($workflow | ConvertTo-Json -Depth 10) -ContentType "application/json"
```

### curl

```bash
# Exemple de liste des workflows
curl -X GET "$Protocol`://$Hostname`:$Port/api/v1/workflows" -H "X-N8N-API-KEY: votre-api-key"

# Exemple d'exécution d'un workflow
curl -X POST "$Protocol`://$Hostname`:$Port/api/v1/workflows/123/execute" -H "X-N8N-API-KEY: votre-api-key"

# Exemple de création d'un workflow
curl -X POST "$Protocol`://$Hostname`:$Port/api/v1/workflows" -H "X-N8N-API-KEY: votre-api-key" -H "Content-Type: application/json" -d '{"name":"Nouveau workflow","active":false,"nodes":[],"connections":{}}'
```
"@
}

# Écrire le rapport dans un fichier
$reportContent | Out-File -FilePath $OutputFile -Encoding utf8
Write-Host "`nRapport généré: $OutputFile" -ForegroundColor Green

# Retourner les résultats
return @{
    Results = $results
    Summary = @{
        Total = $apiRoutes.Count
        Success = $successCount
        Failure = $failureCount
        SuccessRate = [Math]::Round(($successCount / $apiRoutes.Count) * 100, 2)
    }
    Categories = $categories
}
