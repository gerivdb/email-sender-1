


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
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}
try {
    # Script principal
# Update-Roadmap-PathUtils.ps1
# Script pour mettre à jour la roadmap avec les tâches de gestion des chemins terminées

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouvé: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Chemin de la roadmap
$RoadmapPath = "Roadmap\roadmap_perso.md"""

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouvé: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Mettre à jour les tâches de la section 2
$RoadmapContent = $RoadmapContent -replace "- \[ \] Implementer un systeme de gestion des chemins relatifs \(1-2 jours\)", "- [x] Implementer un systeme de gestion des chemins relatifs (1-2 jours) - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Creer des utilitaires pour normaliser les chemins \(1-2 jours\)", "- [x] Creer des utilitaires pour normaliser les chemins (1-2 jours) - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Developper des mecanismes de recherche de fichiers plus robustes \(1 jours\)", "- [x] Developper des mecanismes de recherche de fichiers plus robustes (1 jours) - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"

# Mettre à jour la progression de la section 2
$RoadmapContent = $RoadmapContent -replace "\*\*Progression\*\*: 0%", "**Progression**: 100%"

# Mettre à jour la date de dernière mise à jour
$RoadmapContent = $RoadmapContent -replace "\*Derniere mise a jour: .*\*", "*Derniere mise a jour: $(Get-Date -Format "dd/MM/yyyy HH:mm")*"

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $RoadmapContent

Write-Host "✅ Roadmap mise à jour avec succès." -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
