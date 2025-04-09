# Script pour corriger les problèmes dans le fichier RoadmapAdmin.ps1 original

$filePath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1/RoadmapAdmin.ps1"

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
    
    # 1. Corriger le verbe non approuvé (ligne 65)
    if ($i -eq 64 -and $line -match "


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
# Script pour corriger les problèmes dans le fichier RoadmapAdmin.ps1 original

$filePath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1/RoadmapAdmin.ps1"

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
    
    # 1. Corriger le verbe non approuvé (ligne 65)
    if ($i -eq 64 -and $line -match "function Parse-Roadmap") {
        $line = $line.Replace("function Parse-Roadmap", "function Get-RoadmapContent")
    }
    
    # 2. Corriger la comparaison avec $null (ligne 127)
    if ($i -eq 126 -and $line -match "\$currentSection -ne \$null") {
        $line = $line.Replace('$currentSection -ne $null', '$null -ne $currentSection')
    }
    
    # 3. Corriger la comparaison avec $null (ligne 144)
    if ($i -eq 143 -and $line -match "\$currentPhase -ne \$null") {
        $line = $line.Replace('$currentPhase -ne $null', '$null -ne $currentPhase')
    }
    
    # 4. Corriger la comparaison avec $null (ligne 159)
    if ($i -eq 158 -and $line -match "\$currentPhase -ne \$null -and") {
        $line = $line.Replace('$currentPhase -ne $null -and', '$null -ne $currentPhase -and')
    }
    
    # 5. Corriger la variable non utilisée (ligne 273)
    if ($i -eq 272 -and $line -match "\$allSubtasksCompleted = \$true") {
        # Ignorer cette ligne (ne pas l'ajouter au tableau)
        continue
    }
    
    # 6. Corriger le paramètre switch avec valeur par défaut (ligne 318)
    if ($i -eq 317 -and $line -match "\[switch\]\$MarkCompleted = \$true") {
        $line = $line.Replace('[switch]$MarkCompleted = $true', '[switch]$MarkCompleted')
        $newLines += $line
        
        # Trouver la fin du bloc param
        $j = $i + 1
        while ($j < $lines.Count -and -not $lines[$j].Trim().StartsWith(')')) {
            $newLines += $lines[$j]
            $j++
        }
        
        if ($j < $lines.Count) {
            $newLines += $lines[$j]  # Ajouter la ligne avec la parenthèse fermante
            $newLines += ""  # Ajouter une ligne vide
            $newLines += "    # Définir la valeur par défaut pour MarkCompleted"
            $newLines += "    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {"
            $newLines += "        `$MarkCompleted = `$true"
            $newLines += "    }"
            $i = $j  # Sauter les lignes déjà ajoutées
            continue
        }
    }
    
    # 7. Corriger la variable non utilisée (ligne 426)
    if ($i -eq 425 -and $line -match "\$backupPath = Backup-Roadmap") {
        $line = $line.Replace('$backupPath = Backup-Roadmap', '$null = Backup-Roadmap')
    }
    
    # 8. Corriger la comparaison avec $null (ligne 431)
    if ($i -eq 430 -and $line -match "\$roadmap -eq \$null") {
        $line = $line.Replace('$roadmap -eq $null', '$null -eq $roadmap')
    }
    
    # 9. Corriger la comparaison avec $null (ligne 451)
    if ($i -eq 450 -and $line -match "\$nextItem -eq \$null") {
        $line = $line.Replace('$nextItem -eq $null', '$null -eq $nextItem')
    }
    
    # Ajouter la ligne (potentiellement modifiée) au tableau
    $newLines += $line
}

# Mettre à jour les références à Parse-Roadmap
for ($i = 0; $i -lt $newLines.Count; $i++) {
    if ($newLines[$i] -match "Parse-Roadmap -Path") {
        $newLines[$i] = $newLines[$i].Replace("Parse-Roadmap -Path", "Get-RoadmapContent -Path")
    }
}

# Enregistrer les modifications
Set-Content -Path $filePath -Value $newLines -Encoding UTF8

Write-Host "Les corrections ont été appliquées avec succès au fichier: $filePath" -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
