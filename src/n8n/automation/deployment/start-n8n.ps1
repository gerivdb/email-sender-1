<#
.SYNOPSIS
    Script de démarrage de n8n avec la nouvelle structure.

.DESCRIPTION
    Ce script démarre n8n en utilisant la nouvelle structure de dossiers.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"

# Vérifier si le fichier .env existe
if (-not (Test-Path -Path $envPath)) {
    Write-Error "Le fichier .env n'existe pas. Veuillez exécuter .\n8n\automation\deployment\update-n8n-config.ps1 d'abord."
    exit 1
}

# Charger les variables d'environnement
$envContent = Get-Content -Path $envPath
foreach ($line in $envContent) {
    if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
        $key, $value = $line.Split("=", 2)
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
        Write-Host "Variable d'environnement définie: $key=$value"
    }
}

# Afficher les informations de démarrage
Write-Host "`nDémarrage de n8n..." -ForegroundColor Cyan
Write-Host "URL: $($env:N8N_PROTOCOL)://$($env:N8N_HOST):$($env:N8N_PORT)$($env:N8N_PATH)"
Write-Host "Dossier des workflows: $($env:N8N_WORKFLOW_IMPORT_PATH)"
Write-Host "Dossier des données: $($env:N8N_USER_FOLDER)"
Write-Host "`nAppuyez sur Ctrl+C pour arrêter n8n`n"

# Démarrer n8n
npx n8n start
