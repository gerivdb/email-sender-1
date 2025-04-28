# Script pour corriger les chemins dans les fichiers de configuration
# Ce script remplace les anciens chemins par les nouveaux chemins dans les fichiers de configuration

Write-Host "=== Correction des chemins dans les fichiers de configuration ===" -ForegroundColor Cyan

# Ancien chemin (avec espaces et accents)
$oldPathVariants = @(
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
)

# Nouveau chemin (avec underscores)
$newPath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"

# Types de fichiers Ã  corriger
$fileTypes = @("*.json", "*.cmd", "*.ps1", "*.yaml", "*.md")

# Fonction pour corriger un fichier

# Script pour corriger les chemins dans les fichiers de configuration
# Ce script remplace les anciens chemins par les nouveaux chemins dans les fichiers de configuration

Write-Host "=== Correction des chemins dans les fichiers de configuration ===" -ForegroundColor Cyan

# Ancien chemin (avec espaces et accents)
$oldPathVariants = @(
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
)

# Nouveau chemin (avec underscores)
$newPath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"

# Types de fichiers Ã  corriger
$fileTypes = @("*.json", "*.cmd", "*.ps1", "*.yaml", "*.md")

# Fonction pour corriger un fichier
function Fix-File {
    param (
        [string]$filePath
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

    
    $content = Get-Content -Path $filePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return $false
    }
    
    $modified = $false
    foreach ($variant in $oldPathVariants) {
        if ($content -match [regex]::Escape($variant)) {
            $content = $content -replace [regex]::Escape($variant), $newPath
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $filePath -Value $content -NoNewline
        return $true
    }
    
    return $false
}

# Rechercher et corriger les fichiers contenant les anciens chemins
$correctedFiles = @()

foreach ($fileType in $fileTypes) {
    $files = Get-ChildItem -Path . -Recurse -File -Filter $fileType
    foreach ($file in $files) {
        if (Fix-File -filePath $file.FullName) {
            $correctedFiles += $file.FullName
        }
    }
}

# Afficher les rÃ©sultats
if ($correctedFiles.Count -eq 0) {
    Write-Host "âœ… Aucun fichier n'a eu besoin d'Ãªtre corrigÃ©." -ForegroundColor Green
} else {
    Write-Host "âœ… Les fichiers suivants ont Ã©tÃ© corrigÃ©s :" -ForegroundColor Green
    foreach ($file in $correctedFiles) {
        Write-Host "   - $file" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan
Write-Host "Pour vÃ©rifier que tous les chemins ont Ã©tÃ© corrigÃ©s, exÃ©cutez :"
Write-Host "   .\development\scripts\maintenance\check-paths.ps1"

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
