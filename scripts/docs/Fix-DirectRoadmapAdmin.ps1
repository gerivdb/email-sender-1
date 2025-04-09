# Script pour corriger directement le fichier RoadmapAdmin.ps1 original

# Chemin exact du fichier à corriger
$filePath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1/RoadmapAdmin.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    
    # Essayer de trouver le fichier
    $foundFiles = Get-ChildItem -Path "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1" -Recurse -Filter "RoadmapAdmin.ps1"
    
    if ($foundFiles.Count -gt 0) {
        Write-Host "Fichiers trouvés:" -ForegroundColor Yellow
        foreach ($file in $foundFiles) {
            Write-Host "  $($file.FullName)" -ForegroundColor Yellow
        }
    }
    
    exit 1
}

# Créer une sauvegarde du fichier original
$backupPath = "$filePath.backup"
Copy-Item -Path $filePath -Destination $backupPath -Force
Write-Host "Sauvegarde créée: $backupPath" -ForegroundColor Green

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# Appliquer les corrections
# 1. Corriger le verbe non approuvé (Parse-Roadmap -> Get-RoadmapContent)
$content = $content -replace "


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
# Script pour corriger directement le fichier RoadmapAdmin.ps1 original

# Chemin exact du fichier à corriger
$filePath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1/RoadmapAdmin.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    
    # Essayer de trouver le fichier
    $foundFiles = Get-ChildItem -Path "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1" -Recurse -Filter "RoadmapAdmin.ps1"
    
    if ($foundFiles.Count -gt 0) {
        Write-Host "Fichiers trouvés:" -ForegroundColor Yellow
        foreach ($file in $foundFiles) {
            Write-Host "  $($file.FullName)" -ForegroundColor Yellow
        }
    }
    
    exit 1
}

# Créer une sauvegarde du fichier original
$backupPath = "$filePath.backup"
Copy-Item -Path $filePath -Destination $backupPath -Force
Write-Host "Sauvegarde créée: $backupPath" -ForegroundColor Green

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# Appliquer les corrections
# 1. Corriger le verbe non approuvé (Parse-Roadmap -> Get-RoadmapContent)
$content = $content -replace "function Parse-Roadmap", "function Get-RoadmapContent"
$content = $content -replace "Parse-Roadmap -Path", "Get-RoadmapContent -Path"

# 2, 3, 4. Corriger les comparaisons avec $null
$content = $content -replace "\`$currentSection -ne \`$null", "`$null -ne `$currentSection"
$content = $content -replace "\`$currentPhase -ne \`$null -and", "`$null -ne `$currentPhase -and"
$content = $content -replace "\`$currentPhase -ne \`$null", "`$null -ne `$currentPhase"

# 5. Corriger la variable non utilisée 'allSubtasksCompleted'
$lines = $content -split "`r`n|\r|\n"
$newLines = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    # Ignorer la ligne qui contient la déclaration de allSubtasksCompleted
    if ($lines[$i] -match "\`$allSubtasksCompleted = \`$true") {
        continue
    }
    $newLines += $lines[$i]
}

$content = $newLines -join "`r`n"

# 6. Corriger le paramètre switch avec valeur par défaut
$content = $content -replace "\[switch\]\`$MarkCompleted = \`$true", "[switch]`$MarkCompleted"

# Trouver la position après le bloc param
$paramEndPos = $content.IndexOf(')', $content.IndexOf('[switch]$MarkCompleted'))
if ($paramEndPos -gt 0) {
    $insertPos = $paramEndPos + 1
    $newContent = $content.Substring(0, $insertPos) + "`r`n`r`n    # Définir la valeur par défaut pour MarkCompleted`r`n    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {`r`n        `$MarkCompleted = `$true`r`n    }" + $content.Substring($insertPos)
    $content = $newContent
}

# 7. Corriger la variable non utilisée 'backupPath'
$content = $content -replace "\`$backupPath = Backup-Roadmap", "`$null = Backup-Roadmap"

# 8, 9. Corriger les autres comparaisons avec $null
$content = $content -replace "\`$roadmap -eq \`$null", "`$null -eq `$roadmap"
$content = $content -replace "\`$nextItem -eq \`$null", "`$null -eq `$nextItem"

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8

Write-Host "Les corrections ont été appliquées avec succès au fichier: $filePath" -ForegroundColor Green
Write-Host "Vous pouvez vérifier les modifications en comparant avec la sauvegarde: $backupPath" -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
