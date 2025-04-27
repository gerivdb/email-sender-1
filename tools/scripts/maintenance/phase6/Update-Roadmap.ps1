<#
.SYNOPSIS
    Met Ã  jour la roadmap avec les informations de la Phase 6.
.DESCRIPTION
    Ce script met Ã  jour le fichier roadmap.md avec les informations sur la Phase 6,
    notamment les tÃ¢ches rÃ©alisÃ©es et les prochaines Ã©tapes.
#>

[CmdletBinding()]
param (
    [string]$RoadmapPath = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) -ChildPath "roadmap.md"),
    [string]$LogFilePath = (Join-Path -Path $PSScriptRoot -ChildPath "roadmap_update.log")
)

# Fonction de journalisation simple
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    } catch { Write-Warning "Impossible d'Ã©crire dans le journal: $_" }
}

# Fonction pour mettre Ã  jour la roadmap
function Update-Roadmap {
    param ([string]$RoadmapPath)
    
    Write-Log "Mise Ã  jour de la roadmap: $RoadmapPath"
    
    # VÃ©rifier si le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
        Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "ERROR"
        return $false
    }
    
    # Lire le contenu de la roadmap
    $content = Get-Content -Path $RoadmapPath -Raw
    if ($null -eq $content) {
        Write-Log "Impossible de lire le contenu de la roadmap" -Level "ERROR"
        return $false
    }
    
    # CrÃ©er une sauvegarde
    $backupPath = "$RoadmapPath.bak"
    Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
    Write-Log "Sauvegarde de la roadmap crÃ©Ã©e: $backupPath" -Level "INFO"
    
    # Informations sur la Phase 6
    $phase6Info = @"

## Phase 6 - Correctifs prioritaires pour la gestion d'erreurs et la compatibilitÃ© (TerminÃ©)

### Objectifs
- AmÃ©liorer la gestion d'erreurs dans les scripts existants
- RÃ©soudre les problÃ¨mes de compatibilitÃ© entre environnements
- ImplÃ©menter un systÃ¨me de journalisation centralisÃ©

### TÃ¢ches rÃ©alisÃ©es
- [x] CrÃ©ation des scripts pour la Phase 6
- [x] Analyse des scripts existants pour identifier les amÃ©liorations nÃ©cessaires
- [x] ImplÃ©mentation des amÃ©liorations de gestion d'erreurs
- [x] ImplÃ©mentation des amÃ©liorations de compatibilitÃ© entre environnements
- [x] ImplÃ©mentation du systÃ¨me de journalisation centralisÃ©
- [x] Tests et validation des amÃ©liorations
- [x] Documentation des amÃ©liorations

### LeÃ§ons apprises
- Importance de vÃ©rifier les verbes approuvÃ©s PowerShell avant de crÃ©er des fonctions
- NÃ©cessitÃ© d'Ã©viter les conflits de paramÃ¨tres (ex: WhatIf dÃ©fini deux fois)
- Avantages d'une approche standardisÃ©e pour la gestion des chemins
- Valeur d'un systÃ¨me de journalisation centralisÃ© pour le diagnostic des problÃ¨mes

### Prochaines Ã©tapes
- ImplÃ©menter un systÃ¨me de dÃ©tection automatique des conflits de paramÃ¨tres
- DÃ©velopper un framework de test d'environnement pour valider les prÃ©requis
- CrÃ©er une bibliothÃ¨que standardisÃ©e pour la gestion des chemins
- AmÃ©liorer le systÃ¨me de journalisation pour capturer plus de dÃ©tails sur les erreurs

"@
    
    # VÃ©rifier si la Phase 6 est dÃ©jÃ  mentionnÃ©e dans la roadmap
    if ($content -match "## Phase 6 - Correctifs prioritaires") {
        Write-Log "La Phase 6 est dÃ©jÃ  mentionnÃ©e dans la roadmap" -Level "INFO"
        
        # Mettre Ã  jour les informations de la Phase 6
        $pattern = "## Phase 6 - Correctifs prioritaires.*?(?=\n## |$)"
        $newContent = [regex]::Replace($content, $pattern, $phase6Info.Trim(), [System.Text.RegularExpressions.RegexOptions]::Singleline)
    } else {
        Write-Log "Ajout des informations de la Phase 6 Ã  la roadmap" -Level "INFO"
        
        # Ajouter les informations de la Phase 6 Ã  la fin de la roadmap
        $newContent = $content + "`n" + $phase6Info
    }
    
    # Enregistrer le nouveau contenu
    Set-Content -Path $RoadmapPath -Value $newContent
    Write-Log "Roadmap mise Ã  jour avec succÃ¨s" -Level "SUCCESS"
    
    return $true
}

# ExÃ©cuter la fonction principale
$success = Update-Roadmap -RoadmapPath $RoadmapPath

# Afficher un rÃ©sumÃ©
if ($success) {
    Write-Host "`nLa roadmap a Ã©tÃ© mise Ã  jour avec succÃ¨s:" -ForegroundColor Green
    Write-Host "  - $RoadmapPath" -ForegroundColor White
} else {
    Write-Host "`nÃ‰chec de la mise Ã  jour de la roadmap:" -ForegroundColor Red
    Write-Host "  - $RoadmapPath" -ForegroundColor White
}

Write-Host "Journal: $LogFilePath" -ForegroundColor Cyan
