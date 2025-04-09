<#
.SYNOPSIS
    Met à jour la roadmap avec les informations de la Phase 6.
.DESCRIPTION
    Ce script met à jour le fichier roadmap.md avec les informations sur la Phase 6,
    notamment les tâches réalisées et les prochaines étapes.
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
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    } catch { Write-Warning "Impossible d'écrire dans le journal: $_" }
}

# Fonction pour mettre à jour la roadmap
function Update-Roadmap {
    param ([string]$RoadmapPath)
    
    Write-Log "Mise à jour de la roadmap: $RoadmapPath"
    
    # Vérifier si le fichier roadmap existe
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
    
    # Créer une sauvegarde
    $backupPath = "$RoadmapPath.bak"
    Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
    Write-Log "Sauvegarde de la roadmap créée: $backupPath" -Level "INFO"
    
    # Informations sur la Phase 6
    $phase6Info = @"

## Phase 6 - Correctifs prioritaires pour la gestion d'erreurs et la compatibilité (Terminé)

### Objectifs
- Améliorer la gestion d'erreurs dans les scripts existants
- Résoudre les problèmes de compatibilité entre environnements
- Implémenter un système de journalisation centralisé

### Tâches réalisées
- [x] Création des scripts pour la Phase 6
- [x] Analyse des scripts existants pour identifier les améliorations nécessaires
- [x] Implémentation des améliorations de gestion d'erreurs
- [x] Implémentation des améliorations de compatibilité entre environnements
- [x] Implémentation du système de journalisation centralisé
- [x] Tests et validation des améliorations
- [x] Documentation des améliorations

### Leçons apprises
- Importance de vérifier les verbes approuvés PowerShell avant de créer des fonctions
- Nécessité d'éviter les conflits de paramètres (ex: WhatIf défini deux fois)
- Avantages d'une approche standardisée pour la gestion des chemins
- Valeur d'un système de journalisation centralisé pour le diagnostic des problèmes

### Prochaines étapes
- Implémenter un système de détection automatique des conflits de paramètres
- Développer un framework de test d'environnement pour valider les prérequis
- Créer une bibliothèque standardisée pour la gestion des chemins
- Améliorer le système de journalisation pour capturer plus de détails sur les erreurs

"@
    
    # Vérifier si la Phase 6 est déjà mentionnée dans la roadmap
    if ($content -match "## Phase 6 - Correctifs prioritaires") {
        Write-Log "La Phase 6 est déjà mentionnée dans la roadmap" -Level "INFO"
        
        # Mettre à jour les informations de la Phase 6
        $pattern = "## Phase 6 - Correctifs prioritaires.*?(?=\n## |$)"
        $newContent = [regex]::Replace($content, $pattern, $phase6Info.Trim(), [System.Text.RegularExpressions.RegexOptions]::Singleline)
    } else {
        Write-Log "Ajout des informations de la Phase 6 à la roadmap" -Level "INFO"
        
        # Ajouter les informations de la Phase 6 à la fin de la roadmap
        $newContent = $content + "`n" + $phase6Info
    }
    
    # Enregistrer le nouveau contenu
    Set-Content -Path $RoadmapPath -Value $newContent
    Write-Log "Roadmap mise à jour avec succès" -Level "SUCCESS"
    
    return $true
}

# Exécuter la fonction principale
$success = Update-Roadmap -RoadmapPath $RoadmapPath

# Afficher un résumé
if ($success) {
    Write-Host "`nLa roadmap a été mise à jour avec succès:" -ForegroundColor Green
    Write-Host "  - $RoadmapPath" -ForegroundColor White
} else {
    Write-Host "`nÉchec de la mise à jour de la roadmap:" -ForegroundColor Red
    Write-Host "  - $RoadmapPath" -ForegroundColor White
}

Write-Host "Journal: $LogFilePath" -ForegroundColor Cyan
