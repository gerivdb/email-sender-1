# Script pour corriger les problèmes dans RoadmapAdmin.ps1 avec des méthodes simples

$filePath = "D"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier ligne par ligne
$lines = Get-Content -Path $filePath

# Créer un tableau pour stocker les lignes modifiées
$newLines = @()

# Parcourir chaque ligne et appliquer les corrections
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # 1. Corriger le verbe non approuvé (Parse-Roadmap -> Get-RoadmapContent)
    if ($line -match "function Parse-Roadmap") {
        $line = $line.Replace("function Parse-Roadmap", "function Get-RoadmapContent")
    }
    elseif ($line -match "Parse-Roadmap -Path") {
        $line = $line.Replace("Parse-Roadmap -Path", "Get-RoadmapContent -Path")
    }
    
    # 2, 3, 4. Corriger les comparaisons avec $null
    if ($line -match "\`$currentSection -ne \`$null") {
        $line = $line.Replace('$currentSection -ne $null', '$null -ne $currentSection')
    }
    elseif ($line -match "\`$currentPhase -ne \`$null -and") {
        $line = $line.Replace('$currentPhase -ne $null -and', '$null -ne $currentPhase -and')
    }
    elseif ($line -match "\`$currentPhase -ne \`$null") {
        $line = $line.Replace('$currentPhase -ne $null', '$null -ne $currentPhase')
    }
    
    # 5. Corriger la variable non utilisée 'allSubtasksCompleted'
    if ($line -match "\`$allSubtasksCompleted = \`$true") {
        # Ignorer cette ligne (ne pas l'ajouter au tableau)
        continue
    }
    elseif ($line -match "# Vérifier si toutes les sous-tâches sont terminées") {
        $line = $line.Replace("# Vérifier si toutes les sous-tâches sont terminées", "# Vérifier si au moins une sous-tâche n'est pas terminée")
    }
    
    # 6. Corriger le paramètre switch avec valeur par défaut
    if ($line -match "\[switch\]\`$MarkCompleted = \`$true") {
        $line = $line.Replace('[switch]$MarkCompleted = $true', '[switch]$MarkCompleted')
        $newLines += $line
        
        # Ajouter le code pour définir la valeur par défaut après le bloc param
        if ($lines[$i+1] -match "\)") {
            $newLines += $lines[$i+1]  # Ajouter la ligne avec la parenthèse fermante
            $newLines += ""  # Ajouter une ligne vide
            $newLines += "    # Définir la valeur par défaut pour MarkCompleted"
            $newLines += "    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {"
            $newLines += "        `$MarkCompleted = `$true"
            $newLines += "    }"
            $i++  # Sauter la ligne suivante car nous l'avons déjà ajoutée
            continue
        }
    }
    
    # 7. Corriger la variable non utilisée 'backupPath'
    if ($line -match "\`$backupPath = Backup-Roadmap") {
        $line = $line.Replace('$backupPath = Backup-Roadmap', '$null = Backup-Roadmap')
    }
    
    # 8, 9. Corriger les autres comparaisons avec $null
    if ($line -match "\`$roadmap -eq \`$null") {
        $line = $line.Replace('$roadmap -eq $null', '$null -eq $roadmap')
    }
    elseif ($line -match "\`$nextItem -eq \`$null") {
        $line = $line.Replace('$nextItem -eq $null', '$null -eq $nextItem')
    }
    
    # Ajouter la ligne (potentiellement modifiée) au tableau
    $newLines += $line
}

# Enregistrer les modifications
Set-Content -Path $filePath -Value $newLines -Encoding UTF8

Write-Host "Les corrections ont été appliquées avec succès au fichier: $filePath" -ForegroundColor Green

