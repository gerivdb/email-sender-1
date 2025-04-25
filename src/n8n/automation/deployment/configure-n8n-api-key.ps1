<#
.SYNOPSIS
    Script de configuration de l'API Key pour n8n.

.DESCRIPTION
    Ce script génère une API Key sécurisée pour n8n et la configure dans les fichiers de configuration.

.PARAMETER ApiKey
    API Key à utiliser. Si non spécifiée, une clé sera générée automatiquement.

.PARAMETER ConfigFile
    Chemin du fichier de configuration n8n (par défaut: n8n/core/n8n-config.json).

.PARAMETER EnvFile
    Chemin du fichier .env (par défaut: n8n/.env).

.PARAMETER Force
    Force la mise à jour de l'API Key même si elle existe déjà.

.EXAMPLE
    .\configure-n8n-api-key.ps1 -ApiKey "votre-api-key" -Force

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "n8n/core/n8n-config.json",

    [Parameter(Mandatory = $false)]
    [string]$EnvFile = "n8n/.env",

    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
)

# Fonction pour générer une API Key sécurisée
function New-ApiKey {
    $length = 32
    $bytes = New-Object byte[] $length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)

    # Convertir les bytes en hexadécimal (compatible avec PowerShell 5.1)
    $hexString = ""
    foreach ($byte in $bytes) {
        $hexString += $byte.ToString("x2")
    }

    return $hexString
}

# Fonction pour mettre à jour le fichier de configuration JSON
function Update-ConfigFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigFilePath,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $ConfigFilePath)) {
            Write-Error "Le fichier de configuration n'existe pas: $ConfigFilePath"
            return $false
        }

        # Lire le contenu du fichier
        $config = Get-Content -Path $ConfigFilePath -Raw | ConvertFrom-Json

        # Vérifier si la section security existe
        if (-not $config.security) {
            $config | Add-Member -MemberType NoteProperty -Name "security" -Value @{}
        }

        # Vérifier si la section apiKey existe
        if (-not $config.security.apiKey) {
            $config.security | Add-Member -MemberType NoteProperty -Name "apiKey" -Value @{}
        }

        # Mettre à jour l'API Key
        $config.security.apiKey.value = $ApiKey
        $config.security.apiKey.enabled = $true

        # Écrire le contenu mis à jour dans le fichier
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFilePath

        return $true
    } catch {
        Write-Error "Erreur lors de la mise à jour du fichier de configuration: $_"
        return $false
    }
}

# Fonction pour mettre à jour le fichier .env
function Update-EnvFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$EnvFilePath,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $EnvFilePath)) {
            Write-Error "Le fichier .env n'existe pas: $EnvFilePath"
            return $false
        }

        # Lire le contenu du fichier
        $envContent = Get-Content -Path $EnvFilePath

        # Vérifier si la variable N8N_API_KEY existe
        $apiKeyExists = $false
        $newEnvContent = @()

        foreach ($line in $envContent) {
            if ($line -match "^N8N_API_KEY=") {
                $apiKeyExists = $true
                if ($Force) {
                    $newEnvContent += "N8N_API_KEY=$ApiKey"
                } else {
                    $newEnvContent += $line
                }
            } else {
                $newEnvContent += $line
            }
        }

        # Ajouter la variable N8N_API_KEY si elle n'existe pas
        if (-not $apiKeyExists) {
            $newEnvContent += ""
            $newEnvContent += "# API Key pour l'accès à l'API REST"
            $newEnvContent += "N8N_API_KEY=$ApiKey"
        }

        # Écrire le contenu mis à jour dans le fichier
        $newEnvContent | Set-Content -Path $EnvFilePath

        return $true
    } catch {
        Write-Error "Erreur lors de la mise à jour du fichier .env: $_"
        return $false
    }
}

# Vérifier les chemins des fichiers
$ConfigFile = Join-Path -Path (Get-Location) -ChildPath $ConfigFile
$EnvFile = Join-Path -Path (Get-Location) -ChildPath $EnvFile

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $ConfigFile)) {
    Write-Error "Le fichier de configuration n'existe pas: $ConfigFile"
    exit 1
}

if (-not (Test-Path -Path $EnvFile)) {
    Write-Error "Le fichier .env n'existe pas: $EnvFile"
    exit 1
}

# Générer une API Key si non spécifiée
if ([string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = New-ApiKey
    Write-Host "API Key générée: $ApiKey" -ForegroundColor Green
} else {
    Write-Host "API Key spécifiée: $ApiKey" -ForegroundColor Green
}

# Mettre à jour le fichier de configuration
Write-Host "Mise à jour du fichier de configuration: $ConfigFile" -ForegroundColor Cyan
$configUpdated = Update-ConfigFile -ConfigFilePath $ConfigFile -ApiKey $ApiKey
if (-not $configUpdated) {
    Write-Error "Échec de la mise à jour du fichier de configuration."
    exit 1
}

# Mettre à jour le fichier .env
Write-Host "Mise à jour du fichier .env: $EnvFile" -ForegroundColor Cyan
$envUpdated = Update-EnvFile -EnvFilePath $EnvFile -ApiKey $ApiKey
if (-not $envUpdated) {
    Write-Error "Échec de la mise à jour du fichier .env."
    exit 1
}

Write-Host "`nConfiguration de l'API Key terminée avec succès." -ForegroundColor Green
Write-Host "API Key: $ApiKey" -ForegroundColor Green
Write-Host "`nPour utiliser cette API Key avec l'API REST, ajoutez l'en-tête suivant à vos requêtes:" -ForegroundColor Yellow
Write-Host "X-N8N-API-KEY: $ApiKey" -ForegroundColor Yellow
Write-Host "`nExemple avec curl:" -ForegroundColor Yellow
Write-Host "curl -X GET http://localhost:5678/api/v1/workflows -H `"X-N8N-API-KEY: $ApiKey`"" -ForegroundColor Yellow
Write-Host "`nExemple avec PowerShell:" -ForegroundColor Yellow
Write-Host "Invoke-RestMethod -Uri 'http://localhost:5678/api/v1/workflows' -Method Get -Headers @{`"X-N8N-API-KEY`" = `"$ApiKey`"}" -ForegroundColor Yellow

# Retourner l'API Key
return $ApiKey
