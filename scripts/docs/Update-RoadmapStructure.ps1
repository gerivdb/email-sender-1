# Update-RoadmapStructure.ps1
# Script pour mettre à jour la structure de la roadmap avec des cases à cocher pour toutes les lignes

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\"Roadmap\roadmap_perso.md"",
    
    [Parameter(Mandatory = $false)]
    [string]$JournalPath = ".\journal\journal.md",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour ajouter des cases à cocher à toutes les lignes
function Add-CheckboxesToAllLines {
    param (
        [string]$Content
    )
    
    $lines = $Content -split "`n"
    $updatedLines = @()
    $inPhase = $false
    $inPlan = $false
    
    foreach ($line in $lines) {
        # Ignorer les lignes vides ou les séparateurs
        if ([string]::IsNullOrWhiteSpace($line) -or $line -match "^---") {
            $updatedLines += $line
            continue
        }
        
        # Détecter si on est dans le plan d'implémentation
        if ($line -match "^## Plan d'implementation recommande") {
            $inPlan = $true
            $updatedLines += $line
            continue
        }
        
        # Traiter les titres de section (catégories)
        if ($line -match "^## \d+\. (.+)") {
            $inPhase = $false
            $updatedLines += $line
            continue
        }
        
        # Traiter les métadonnées des catégories
        if ($line -match "^\*\*(.+)\*\*: (.+)") {
            $updatedLines += $line
            continue
        }
        
        # Traiter les notes
        if ($line -match "^\s+> \*(.+)\*") {
            $updatedLines += $line
            continue
        }
        
        # Traiter les phases dans le plan d'implémentation
        if ($inPlan -and $line -match "^\d+\. \*\*(.+)\*\*:") {
            $phaseName = $matches[1]
            $updatedLines += "- [ ] $line"
            continue
        }
        
        # Traiter les éléments du plan d'implémentation
        if ($inPlan -and $line -match "^\s+- (.+)") {
            $item = $matches[1]
            $updatedLines += "   - [ ] $item"
            continue
        }
        
        # Traiter les phases du plan d'implémentation dans les tâches
        if ($line -match "^\s+>\s+\d+\. \*\*(.+)\*\*:") {
            $inPhase = $true
            $phaseName = $matches[1]
            $updatedLines += $line.Replace("$phaseName", "[ ] $phaseName")
            continue
        }
        
        # Traiter les sous-tâches dans les phases
        if ($inPhase -and $line -match "^\s+>\s+\s+- (.+)") {
            $subTask = $matches[1]
            $updatedLines += $line.Replace("- $subTask", "- [ ] $subTask")
            continue
        }
        
        # Traiter les tâches déjà avec des cases à cocher
        if ($line -match "^- \[([ x])\] (.+)") {
            $updatedLines += $line
            continue
        }
        
        # Traiter les autres lignes
        $updatedLines += $line
    }
    
    return $updatedLines -join "`n"
}

# Fonction pour mettre à jour la roadmap
function Update-Roadmap {
    param (
        [string]$RoadmapPath,
        [switch]$WhatIf
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier roadmap '$RoadmapPath' n'existe pas."
        return $false
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $RoadmapPath -Raw
    
    # Ajouter des cases à cocher à toutes les lignes
    $updatedContent = Add-CheckboxesToAllLines -Content $content
    
    # Vérifier si des modifications ont été apportées
    if ($content -eq $updatedContent) {
        Write-Output "Aucune modification nécessaire pour la roadmap."
        return $true
    }
    
    # Sauvegarder les modifications
    if ($WhatIf) {
        Write-Output "La roadmap serait mise à jour avec des cases à cocher pour toutes les lignes."
    }
    else {
        $updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8
        Write-Output "La roadmap a été mise à jour avec des cases à cocher pour toutes les lignes."
    }
    
    return $true
}

# Fonction principale
function Main {
    # Mettre à jour la roadmap
    $success = Update-Roadmap -RoadmapPath $RoadmapPath -WhatIf:$WhatIf
    
    if (-not $success) {
        Write-Error "La mise à jour de la roadmap a échoué."
        return
    }
    
    Write-Output "La structure de la roadmap a été mise à jour avec succès."
}

# Exécuter la fonction principale
Main
