# Script pour mettre a jour les liens dans les fichiers de documentation

Write-Host "=== Mise a jour des liens dans les fichiers de documentation ===" -ForegroundColor Cyan

# Fonction pour mettre a jour les liens dans un fichier

# Script pour mettre a jour les liens dans les fichiers de documentation

Write-Host "=== Mise a jour des liens dans les fichiers de documentation ===" -ForegroundColor Cyan

# Fonction pour mettre a jour les liens dans un fichier
function Update-Links {
    param (
        [string]$FilePath
    )

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

    
    if (Test-Path $FilePath) {
        $content = Get-Content -Path $FilePath -Raw
        
        # Remplacer les liens vers les fichiers de documentation
        $content = $content -replace '\[([^\]]+)\]\(GUIDE_([^\)]+)\)', '[${1}](../guides/GUIDE_${2})'
        $content = $content -replace '\[([^\]]+)\]\(CONFIGURATION_([^\)]+)\)', '[${1}](../guides/CONFIGURATION_${2})'
        
        # Enregistrer le fichier
        Set-Content -Path $FilePath -Value $content
        Write-Host "Liens mis a jour dans $FilePath" -ForegroundColor Green
    } else {
        Write-Host "Fichier $FilePath non trouve" -ForegroundColor Yellow
    }
}

# Mettre a jour les liens dans les fichiers de documentation
$docFiles = Get-ChildItem -Path ".\docs\guides" -Filter "*.md" -File

foreach ($file in $docFiles) {
    Update-Links -FilePath $file.FullName
}

Write-Host "`n=== Mise a jour des liens terminee ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
