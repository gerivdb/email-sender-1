<#
.SYNOPSIS
    Script pour importer des workflows n8n via l'API REST.

.DESCRIPTION
    Ce script importe des workflows n8n depuis des fichiers JSON via l'API REST en utilisant l'API Key configurée.

.PARAMETER WorkflowFile
    Chemin du fichier workflow à importer. Si un dossier est spécifié, tous les fichiers JSON du dossier seront importés.

.PARAMETER ApiKey
    API Key à utiliser. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Host
    Hôte n8n (par défaut: localhost).

.PARAMETER Port
    Port n8n (par défaut: 5678).

.PARAMETER Protocol
    Protocole (http ou https) (par défaut: http).

.PARAMETER Tags
    Tags à ajouter aux workflows importés (séparés par des virgules).

.PARAMETER Active
    Indique si les workflows importés doivent être activés (par défaut: $true).

.EXAMPLE
    .\import-workflow-api.ps1 -WorkflowFile "path/to/workflow.json" -Tags "tag1,tag2" -Active $true

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$WorkflowFile,

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false)]
    [string]$Hostname = "localhost",

    [Parameter(Mandatory = $false)]
    [int]$Port = 5678,

    [Parameter(Mandatory = $false)]
    [string]$Protocol = "http",

    [Parameter(Mandatory = $false)]
    [string]$Tags = "",

    [Parameter(Mandatory = $false)]
    [bool]$Active = $true
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

# Fonction pour importer un workflow via l'API
function Import-Workflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$ApiUrl,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $false)]
        [string]$Tags = "",

        [Parameter(Mandatory = $false)]
        [bool]$Active = $true
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Le fichier n'existe pas: $FilePath"
            return $null
        }

        # Lire le contenu du fichier
        $workflowJson = Get-Content -Path $FilePath -Raw

        # Convertir le JSON en objet
        $workflow = $workflowJson | ConvertFrom-Json

        # Préparer les données pour l'importation
        $importData = @{
            workflowData = $workflow
            tags         = if ([string]::IsNullOrEmpty($Tags)) { @() } else { $Tags.Split(",") }
            active       = $Active
        }

        # Convertir les données en JSON
        $importDataJson = $importData | ConvertTo-Json -Depth 10

        # Préparer les en-têtes
        $headers = @{
            "Content-Type"  = "application/json"
            "Accept"        = "application/json"
            "X-N8N-API-KEY" = $ApiKey
        }

        # Envoyer la requête
        $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $headers -Body $importDataJson

        return $response
    } catch {
        Write-Error "Erreur lors de l'importation du workflow: $_"

        # Afficher des informations supplémentaires sur l'erreur
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Host "Code d'état HTTP: $statusCode ($statusDescription)" -ForegroundColor Red

            # Essayer de lire le corps de la réponse d'erreur
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()

                if (-not [string]::IsNullOrEmpty($responseBody)) {
                    Write-Host "Corps de la réponse:" -ForegroundColor Red
                    Write-Host $responseBody
                }
            } catch {
                # Ignorer les erreurs lors de la lecture du corps de la réponse
            }
        }

        return $null
    }
}

# Récupérer l'API Key si non spécifiée
if ([string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = Get-ApiKeyFromConfig
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Error "Aucune API Key trouvée. Exécutez le script configure-n8n-api-key.ps1 pour configurer une API Key."
        exit 1
    } else {
        Write-Host "API Key récupérée depuis la configuration: $ApiKey" -ForegroundColor Green
    }
} else {
    Write-Host "API Key spécifiée: $ApiKey" -ForegroundColor Green
}

# Construire l'URL de l'API
$apiUrl = "$Protocol`://$Hostname`:$Port/api/v1/workflows/import"
Write-Host "URL de l'API: $apiUrl" -ForegroundColor Cyan

# Vérifier si le chemin spécifié est un fichier ou un dossier
$isDirectory = (Get-Item -Path $WorkflowFile -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]

# Obtenir la liste des fichiers à importer
$filesToImport = @()
if ($isDirectory) {
    $filesToImport = Get-ChildItem -Path $WorkflowFile -Filter "*.json" -File
    Write-Host "Dossier spécifié: $WorkflowFile" -ForegroundColor Cyan
    Write-Host "Nombre de fichiers à importer: $($filesToImport.Count)" -ForegroundColor Cyan
} else {
    $filesToImport = @(Get-Item -Path $WorkflowFile -ErrorAction SilentlyContinue)
    if ($filesToImport.Count -eq 0) {
        Write-Error "Le fichier spécifié n'existe pas: $WorkflowFile"
        exit 1
    }
    Write-Host "Fichier spécifié: $WorkflowFile" -ForegroundColor Cyan
}

# Importer chaque fichier
$results = @()
$successCount = 0
$errorCount = 0

foreach ($file in $filesToImport) {
    Write-Host "`nImportation du workflow: $($file.FullName)" -ForegroundColor Yellow

    $response = Import-Workflow -FilePath $file.FullName -ApiUrl $apiUrl -ApiKey $ApiKey -Tags $Tags -Active $Active

    if ($null -ne $response) {
        Write-Host "  Succès! Workflow importé avec l'ID: $($response.id)" -ForegroundColor Green
        $successCount++

        $results += [PSCustomObject]@{
            File    = $file.Name
            Success = $true
            Id      = $response.id
            Name    = $response.name
        }
    } else {
        Write-Host "  Échec de l'importation du workflow." -ForegroundColor Red
        $errorCount++

        $results += [PSCustomObject]@{
            File    = $file.Name
            Success = $false
            Id      = $null
            Name    = $null
        }
    }
}

# Afficher le résumé
Write-Host "`n=== Résumé de l'importation ===" -ForegroundColor Cyan
Write-Host "Total des fichiers: $($filesToImport.Count)" -ForegroundColor Cyan
Write-Host "Succès: $successCount" -ForegroundColor Green
Write-Host "Échecs: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })

# Afficher les résultats détaillés
if ($results.Count -gt 0) {
    Write-Host "`n=== Détails de l'importation ===" -ForegroundColor Cyan
    $results | Format-Table -AutoSize -Property File, Success, Id, Name
}

# Retourner les résultats
return $results
