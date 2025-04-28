


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
# Update-Roadmap-PathUtils-2b.ps1
# Script pour mettre Ã  jour la roadmap avec les tÃ¢ches de gestion des chemins terminÃ©es (section 2.b)

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Chemin de la roadmap
$RoadmapPath = "Roadmap\roadmap_perso.md"""

# VÃ©rifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouve: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Mettre Ã  jour les tÃ¢ches de la section 2.b
$RoadmapContent = $RoadmapContent -replace "- \[ \] RÃ©soudre les problÃ¨mes d'encodage des caractÃ¨res dans les scripts PowerShell", "- [x] RÃ©soudre les problÃ¨mes d'encodage des caractÃ¨res dans les scripts PowerShell - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] AmÃ©liorer les tests pour s'assurer que toutes les fonctions fonctionnent correctement", "- [x] AmÃ©liorer les tests pour s'assurer que toutes les fonctions fonctionnent correctement - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] IntÃ©grer ces outils dans les autres scripts du projet", "- [x] IntÃ©grer ces outils dans les autres scripts du projet - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Documenter les bonnes pratiques pour l'utilisation de ces outils", "- [x] Documenter les bonnes pratiques pour l'utilisation de ces outils - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"

# Mettre Ã  jour la progression de la section 2.b
$RoadmapContent = $RoadmapContent -replace "\*\*Progression\*\*: 0% \(section 2\.b\)", "**Progression**: 100% (section 2.b)"

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
