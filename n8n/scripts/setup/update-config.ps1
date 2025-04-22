<#
.SYNOPSIS
    Script pour mettre à jour le fichier n8n-config.json après la migration.

.DESCRIPTION
    Ce script met à jour le fichier n8n-config.json pour refléter la nouvelle structure de dossiers.

.EXAMPLE
    .\update-config.ps1
#>

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$dataPath = Join-Path -Path $rootPath -ChildPath "data"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $n8nConfigPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas. Veuillez exécuter .\scripts\setup\install-n8n-local.ps1 d'abord."
    exit 1
}

# Lire la configuration
$config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

# Mettre à jour le chemin du dossier de données
$config.dataFolder = $dataPath

# Enregistrer la configuration
$configJson = $config | ConvertTo-Json
Set-Content -Path $n8nConfigPath -Value $configJson -Encoding UTF8

Write-Host "Fichier n8n-config.json mis à jour: $n8nConfigPath"
