


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Script pour configurer EMAIL_PASSWORD dans le fichier .env

# VÃ©rifier si le fichier service-account-key.json existe
$keyFilePath = "$PSScriptRoot\service-account-key.json"
if (-not (Test-Path $keyFilePath)) {
    Write-Host "Erreur : Fichier service-account-key.json non trouvÃ© dans $PSScriptRoot" -ForegroundColor Red
    Write-Host "ExÃ©cutez d'abord create-service-account.cmd pour crÃ©er le compte de service et la clÃ©" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier service-account-key.json
$keyContent = Get-Content -Raw -Path $keyFilePath

# Chemin vers le fichier .env Ã  la racine du projet
$envFilePath = "$PSScriptRoot\..\..\\.env"

# VÃ©rifier si le fichier .env existe, sinon le crÃ©er
if (-not (Test-Path $envFilePath)) {
    Write-Host "CrÃ©ation du fichier .env..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $envFilePath | Out-Null
}

# Lire le contenu actuel du fichier .env
$envContent = Get-Content -Path $envFilePath -ErrorAction SilentlyContinue

# VÃ©rifier si EMAIL_PASSWORD existe dÃ©jÃ  dans le fichier .env
$emailPasswordExists = $envContent | Where-Object { $_ -match "^EMAIL_PASSWORD=" }

if ($emailPasswordExists) {
    # Remplacer la ligne existante
    Write-Host "Mise Ã  jour de EMAIL_PASSWORD dans le fichier .env..." -ForegroundColor Yellow
    $newEnvContent = $envContent -replace "^EMAIL_PASSWORD=.*", "EMAIL_PASSWORD=$keyContent"
    Set-Content -Path $envFilePath -Value $newEnvContent
} else {
    # Ajouter la nouvelle ligne
    Write-Host "Ajout de EMAIL_PASSWORD dans le fichier .env..." -ForegroundColor Yellow
    Add-Content -Path $envFilePath -Value "`nEMAIL_PASSWORD=$keyContent"
}

Write-Host "Configuration terminÃ©e. EMAIL_PASSWORD a Ã©tÃ© configurÃ© dans le fichier .env" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser cette variable dans vos workflows GitHub Actions" -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
