# Update-RoadmapStructure.ps1
# Script pour mettre Ã  jour la structure de la roadmap avec des cases Ã  cocher pour toutes les lignes

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\roadmap_perso.md",
    
    [Parameter(Mandatory = $false)]
    [string]$JournalPath = ".\journal\journal.md",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour ajouter des cases Ã  cocher Ã  toutes les lignes
function Add-CheckboxesToAllLines {
    param (
        [string]$Content
    )
    
    $lines = $Content -split "`n"
    $updatedLines = @()
    $inPhase = $false
    $inPlan = $false
    
    foreach ($line in $lines) {
        # Ignorer les lignes vides ou les sÃ©parateurs
        if ([string]::IsNullOrWhiteSpace($line) -or $line -match "^---") {
            $updatedLines += $line
            continue
        }
        
        # DÃ©tecter si on est dans le plan d'implÃ©mentation
        if ($line -match "^## Plan d'implementation recommande") {
            $inPlan = $true
            $updatedLines += $line
            continue
        }
        
        # Traiter les titres de section (catÃ©gories)
        if ($line -match "^## \d+\. (.+)") {
            $inPhase = $false
            $updatedLines += $line
            continue
        }
        
        # Traiter les mÃ©tadonnÃ©es des catÃ©gories
        if ($line -match "^\*\*(.+)\*\*: (.+)") {
            $updatedLines += $line
            continue
        }
        
        # Traiter les notes
        if ($line -match "^\s+> \*(.+)\*") {
            $updatedLines += $line
            continue
        }
        
        # Traiter les phases dans le plan d'implÃ©mentation
        if ($inPlan -and $line -match "^\d+\. \*\*(.+)\*\*:") {
            $phaseName = $matches[1]
            $updatedLines += "- [ ] $line"
            continue
        }
        
        # Traiter les Ã©lÃ©ments du plan d'implÃ©mentation
        if ($inPlan -and $line -match "^\s+- (.+)") {
            $item = $matches[1]
            $updatedLines += "   - [ ] $item"
            continue
        }
        
        # Traiter les phases du plan d'implÃ©mentation dans les tÃ¢ches
        if ($line -match "^\s+>\s+\d+\. \*\*(.+)\*\*:") {
            $inPhase = $true
            $phaseName = $matches[1]
            $updatedLines += $line.Replace("$phaseName", "[ ] $phaseName")
            continue
        }
        
        # Traiter les sous-tÃ¢ches dans les phases
        if ($inPhase -and $line -match "^\s+>\s+\s+- (.+)") {
            $subTask = $matches[1]
            $updatedLines += $line.Replace("- $subTask", "- [ ] $subTask")
            continue
        }
        
        # Traiter les tÃ¢ches dÃ©jÃ  avec des cases Ã  cocher
        if ($line -match "^- \[([ x])\] (.+)") {
            $updatedLines += $line
            continue
        }
        
        # Traiter les autres lignes
        $updatedLines += $line
    }
    
    return $updatedLines -join "`n"
}

# Fonction pour mettre Ã  jour la roadmap
function Update-Roadmap {
    param (
        [string]$RoadmapPath,
        [switch]$WhatIf
    )
    
    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier roadmap '$RoadmapPath' n'existe pas."
        return $false
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $RoadmapPath -Raw
    
    # Ajouter des cases Ã  cocher Ã  toutes les lignes
    $updatedContent = Add-CheckboxesToAllLines -Content $content
    
    # VÃ©rifier si des modifications ont Ã©tÃ© apportÃ©es
    if ($content -eq $updatedContent) {
        Write-Output "Aucune modification nÃ©cessaire pour la roadmap."
        return $true
    }
    
    # Sauvegarder les modifications
    if ($WhatIf) {
        Write-Output "La roadmap serait mise Ã  jour avec des cases Ã  cocher pour toutes les lignes."
    }
    else {
        $updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8
        Write-Output "La roadmap a Ã©tÃ© mise Ã  jour avec des cases Ã  cocher pour toutes les lignes."
    }
    
    return $true
}

# Fonction principale
function Main {
    # Mettre Ã  jour la roadmap
    $success = Update-Roadmap -RoadmapPath $RoadmapPath -WhatIf:$WhatIf
    
    if (-not $success) {
        Write-Error "La mise Ã  jour de la roadmap a Ã©chouÃ©."
        return
    }
    
    Write-Output "La structure de la roadmap a Ã©tÃ© mise Ã  jour avec succÃ¨s."
}

# ExÃ©cuter la fonction principale
Main
