# Script pour corriger les problÃ¨mes dans RoadmapAdmin.ps1

$filePath = "D"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 1. Corriger le verbe non approuvÃ© (Parse-Roadmap -> Get-RoadmapContent)
$content = $content.Replace("
# Script pour corriger les problÃ¨mes dans RoadmapAdmin.ps1

$filePath = "D"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 1. Corriger le verbe non approuvÃ© (Parse-Roadmap -> Get-RoadmapContent)
$content = $content.Replace("function Parse-Roadmap", "function Get-RoadmapContent")
$content = $content.Replace("Parse-Roadmap -Path", "Get-RoadmapContent -Path")

# 2, 3, 4. Corriger les comparaisons avec $null
$content = $content.Replace('$currentSection -ne $null', '$null -ne $currentSection')
$content = $content.Replace('$currentPhase -ne $null', '$null -ne $currentPhase')
$content = $content.Replace('$currentPhase -ne $null -and', '$null -ne $currentPhase -and')

# 5. Corriger la variable non utilisÃ©e 'allSubtasksCompleted'
$content = $content.Replace('                        # VÃ©rifier si toutes les sous-tÃ¢ches sont terminÃ©es
                        $allSubtasksCompleted = $true', '                        # VÃ©rifier si au moins une sous-tÃ¢che n''est pas terminÃ©e')

# 6. Corriger le paramÃ¨tre switch avec valeur par dÃ©faut
$content = $content.Replace('[switch]$MarkCompleted = $true', '[switch]$MarkCompleted')

# Ajouter le code pour dÃ©finir la valeur par dÃ©faut
$paramBlock = "    param (
        [string]`$Path,
        [hashtable]`$Item,
        [switch]`$MarkCompleted
    )

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
"

$replacementBlock = "    param (
        [string]`$Path,
        [hashtable]`$Item,
        [switch]`$MarkCompleted
    )
    
    # DÃ©finir la valeur par dÃ©faut pour MarkCompleted
    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {
        `$MarkCompleted = `$true
    }"

$content = $content.Replace($paramBlock, $replacementBlock)

# 7. Corriger la variable non utilisÃ©e 'backupPath'
$content = $content.Replace('    # CrÃ©er une sauvegarde
    $backupPath = Backup-Roadmap -Path $RoadmapPath', '    # CrÃ©er une sauvegarde
    $null = Backup-Roadmap -Path $RoadmapPath')

# 8, 9. Corriger les autres comparaisons avec $null
$content = $content.Replace('    if ($roadmap -eq $null) {', '    if ($null -eq $roadmap) {')
$content = $content.Replace('    if ($nextItem -eq $null) {', '    if ($null -eq $nextItem) {')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8

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
