﻿# Script pour supprimer les dossiers d'archive et de backup redondants
# Ces dossiers sont inutiles puisque tous les fichiers sont dÃ©jÃ  versionnÃ©s dans Git

# Configuration
$archiveFolder = "Roadmap\scripts\archive"
$backupFolder = "Roadmap\scripts\backup"

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
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# VÃ©rifier si les dossiers existent
if (Test-Path -Path $archiveFolder) {
    Write-Log "Suppression du dossier d'archive redondant: $archiveFolder" "INFO"
    Remove-Item -Path $archiveFolder -Recurse -Force
    Write-Log "Dossier d'archive supprimÃ© avec succÃ¨s" "SUCCESS"
} else {
    Write-Log "Le dossier d'archive n'existe pas: $archiveFolder" "INFO"
}

if (Test-Path -Path $backupFolder) {
    Write-Log "Suppression du dossier de backup redondant: $backupFolder" "INFO"
    Remove-Item -Path $backupFolder -Recurse -Force
    Write-Log "Dossier de backup supprimÃ© avec succÃ¨s" "SUCCESS"
} else {
    Write-Log "Le dossier de backup n'existe pas: $backupFolder" "INFO"
}

Write-Log "Nettoyage terminÃ©. Les dossiers redondants ont Ã©tÃ© supprimÃ©s." "SUCCESS"
Write-Log "Tous les fichiers restent accessibles via l'historique Git." "INFO"
