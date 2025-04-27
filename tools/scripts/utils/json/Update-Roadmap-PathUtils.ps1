


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
# Update-Roadmap-PathUtils.ps1
# Script pour mettre Ã  jour la roadmap avec les tÃ¢ches de gestion des chemins terminÃ©es

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouvÃ©: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Chemin de la roadmap
$RoadmapPath = "Roadmap\roadmap_perso.md"""

# VÃ©rifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouvÃ©: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Mettre Ã  jour les tÃ¢ches de la section 2
$RoadmapContent = $RoadmapContent -replace "- \[ \] Implementer un systeme de gestion des chemins relatifs \(1-2 jours\)", "- [x] Implementer un systeme de gestion des chemins relatifs (1-2 jours) - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Creer des utilitaires pour normaliser les chemins \(1-2 jours\)", "- [x] Creer des utilitaires pour normaliser les chemins (1-2 jours) - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Developper des mecanismes de recherche de fichiers plus robustes \(1 jours\)", "- [x] Developper des mecanismes de recherche de fichiers plus robustes (1 jours) - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"

# Mettre Ã  jour la progression de la section 2
$RoadmapContent = $RoadmapContent -replace "\*\*Progression\*\*: 0%", "**Progression**: 100%"

# Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
$RoadmapContent = $RoadmapContent -replace "\*Derniere mise a jour: .*\*", "*Derniere mise a jour: $(Get-Date -Format "dd/MM/yyyy HH:mm")*"

# Ã‰crire le contenu mis Ã  jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $RoadmapContent

Write-Host "âœ… Roadmap mise Ã  jour avec succÃ¨s." -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
