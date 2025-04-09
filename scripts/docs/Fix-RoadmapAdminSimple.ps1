# Script pour corriger les problÃ¨mes dans RoadmapAdmin.ps1 avec des mÃ©thodes simples

$filePath = "D"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier ligne par ligne
$lines = Get-Content -Path $filePath

# CrÃ©er un tableau pour stocker les lignes modifiÃ©es
$newLines = @()

# Parcourir chaque ligne et appliquer les corrections
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # 1. Corriger le verbe non approuvÃ© (Parse-Roadmap -> Get-RoadmapContent)
    if ($line -match "


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
# Script pour corriger les problÃ¨mes dans RoadmapAdmin.ps1 avec des mÃ©thodes simples

$filePath = "D"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier ligne par ligne
$lines = Get-Content -Path $filePath

# CrÃ©er un tableau pour stocker les lignes modifiÃ©es
$newLines = @()

# Parcourir chaque ligne et appliquer les corrections
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # 1. Corriger le verbe non approuvÃ© (Parse-Roadmap -> Get-RoadmapContent)
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
    
    # 5. Corriger la variable non utilisÃ©e 'allSubtasksCompleted'
    if ($line -match "\`$allSubtasksCompleted = \`$true") {
        # Ignorer cette ligne (ne pas l'ajouter au tableau)
        continue
    }
    elseif ($line -match "# VÃ©rifier si toutes les sous-tÃ¢ches sont terminÃ©es") {
        $line = $line.Replace("# VÃ©rifier si toutes les sous-tÃ¢ches sont terminÃ©es", "# VÃ©rifier si au moins une sous-tÃ¢che n'est pas terminÃ©e")
    }
    
    # 6. Corriger le paramÃ¨tre switch avec valeur par dÃ©faut
    if ($line -match "\[switch\]\`$MarkCompleted = \`$true") {
        $line = $line.Replace('[switch]$MarkCompleted = $true', '[switch]$MarkCompleted')
        $newLines += $line
        
        # Ajouter le code pour dÃ©finir la valeur par dÃ©faut aprÃ¨s le bloc param
        if ($lines[$i+1] -match "\)") {
            $newLines += $lines[$i+1]  # Ajouter la ligne avec la parenthÃ¨se fermante
            $newLines += ""  # Ajouter une ligne vide
            $newLines += "    # DÃ©finir la valeur par dÃ©faut pour MarkCompleted"
            $newLines += "    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {"
            $newLines += "        `$MarkCompleted = `$true"
            $newLines += "    }"
            $i++  # Sauter la ligne suivante car nous l'avons dÃ©jÃ  ajoutÃ©e
            continue
        }
    }
    
    # 7. Corriger la variable non utilisÃ©e 'backupPath'
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
    
    # Ajouter la ligne (potentiellement modifiÃ©e) au tableau
    $newLines += $line
}

# Enregistrer les modifications
Set-Content -Path $filePath -Value $newLines -Encoding UTF8

Write-Host "Les corrections ont Ã©tÃ© appliquÃ©es avec succÃ¨s au fichier: $filePath" -ForegroundColor Green


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
