


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
# Script pour corriger les problemes d'encodage dans les scripts PowerShell

Write-Host "=== Correction des problemes d'encodage dans les scripts PowerShell ===" -ForegroundColor Cyan

# Rechercher tous les scripts PowerShell
$scriptFiles = Get-ChildItem -Path "." -Recurse -Filter "*.ps1" -File

Write-Host "Traitement de $($scriptFiles.Count) scripts PowerShell..." -ForegroundColor Yellow

$modifiedCount = 0
foreach ($file in $scriptFiles) {
    # Lire le contenu du fichier
    $content = Get-Content -Path $file.FullName -Raw
    
    # Remplacer les caracteres accentues
    $newContent = $content -replace "e", "e" -replace "e", "e" -replace "e", "e" -replace "e", "e"
    $newContent = $newContent -replace "a", "a" -replace "a", "a" -replace "a", "a"
    $newContent = $newContent -replace "i", "i" -replace "i", "i"
    $newContent = $newContent -replace "o", "o" -replace "o", "o"
    $newContent = $newContent -replace "u", "u" -replace "u", "u" -replace "u", "u"
    $newContent = $newContent -replace "c", "c"
    $newContent = $newContent -replace "Ã‰", "E" -replace "Ãˆ", "E" -replace "ÃŠ", "E" -replace "Ã‹", "E"
    $newContent = $newContent -replace "Ã€", "A" -replace "Ã‚", "A" -replace "Ã„", "A"
    $newContent = $newContent -replace "ÃŽ", "I" -replace "Ã", "I"
    $newContent = $newContent -replace "Ã”", "O" -replace "Ã–", "O"
    $newContent = $newContent -replace "Ã™", "U" -replace "Ã›", "U" -replace "Ãœ", "U"
    $newContent = $newContent -replace "Ã‡", "C"
    
    # Verifier si le contenu a ete modifie
    if ($newContent -ne $content) {
        # Enregistrer le nouveau contenu
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Fichier $($file.FullName) corrige" -ForegroundColor Green
        $modifiedCount++
    }
}

Write-Host "`n$modifiedCount fichiers ont ete corriges" -ForegroundColor Green

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan
Write-Host "Les problemes d'encodage ont ete corriges dans les scripts PowerShell."
Write-Host "Desormais, tous les scripts devraient s'afficher correctement dans le terminal."


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
