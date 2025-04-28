


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
# Script pour copier le fichier RoadmapAdmin.ps1 corrigé à l'emplacement original

# Chemin du fichier source (corrigé)
$sourcePath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1/Roadmap/RoadmapAdmin.ps1"

# Chemin du fichier de destination (où l'éditeur s'attend à le trouver)
$destinationPath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1/RoadmapAdmin.ps1"

# Vérifier si le fichier source existe
if (-not (Test-Path -Path $sourcePath)) {
    Write-Host "Le fichier source n'existe pas: $sourcePath" -ForegroundColor Red
    exit 1
}

# Créer le fichier de destination
Copy-Item -Path $sourcePath -Destination $destinationPath -Force
Write-Host "Fichier copié avec succès: $sourcePath -> $destinationPath" -ForegroundColor Green

# Vérifier si le fichier de destination existe
if (Test-Path -Path $destinationPath) {
    Write-Host "Le fichier de destination existe maintenant: $destinationPath" -ForegroundColor Green
}
else {
    Write-Host "Échec de la copie du fichier." -ForegroundColor Red
}

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
