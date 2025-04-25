


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
# Script pour dÃ©placer les fichiers spÃ©cifiques qui peuvent Ãªtre rangÃ©s
# Ce script dÃ©place JOURNAL_DE_BORD.md, commit-docs.cmd et commit-final-docs.cmd dans leurs dossiers respectifs

Write-Host "=== DÃ©placement des fichiers spÃ©cifiques ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Location).Path
Set-Location $projectRoot

# 1. DÃ©placement de JOURNAL_DE_BORD.md vers le dossier md
Write-Host "`n1. DÃ©placement de JOURNAL_DE_BORD.md vers le dossier md..." -ForegroundColor Yellow

$mdFile = "JOURNAL_DE_BORD.md"
$mdFolder = "md"

# VÃ©rifier si le fichier existe
if (Test-Path $mdFile) {
    # VÃ©rifier si le dossier de destination existe
    if (-not (Test-Path $mdFolder)) {
        New-Item -ItemType Directory -Path $mdFolder -Force | Out-Null
        Write-Host "  Dossier $mdFolder crÃ©Ã©" -ForegroundColor Green
    }
    
    # DÃ©placer le fichier
    $destFile = Join-Path $mdFolder $mdFile
    if (Test-Path $destFile) {
        # Le fichier existe dÃ©jÃ  dans la destination
        $sourceFile = Get-Item $mdFile
        $existingFile = Get-Item $destFile
        
        if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
            # Le fichier source est plus rÃ©cent
            Move-Item -Path $mdFile -Destination $destFile -Force
            Write-Host "  Fichier $mdFile remplacÃ© (plus rÃ©cent)" -ForegroundColor Blue
        } else {
            Write-Host "  Fichier $mdFile ignorÃ© (plus ancien ou identique)" -ForegroundColor Gray
        }
    } else {
        # Le fichier n'existe pas dans la destination
        Move-Item -Path $mdFile -Destination $destFile
        Write-Host "  Fichier $mdFile dÃ©placÃ© vers $mdFolder" -ForegroundColor Green
    }
} else {
    Write-Host "  Fichier $mdFile non trouvÃ©" -ForegroundColor Yellow
}

# 2. DÃ©placement des fichiers commit-docs.cmd et commit-final-docs.cmd vers le dossier cmd
Write-Host "`n2. DÃ©placement des fichiers commit-*.cmd vers le dossier cmd..." -ForegroundColor Yellow

$cmdFiles = @("commit-docs.cmd", "commit-final-docs.cmd")
$cmdFolder = "cmd"

# VÃ©rifier si le dossier de destination existe
if (-not (Test-Path $cmdFolder)) {
    New-Item -ItemType Directory -Path $cmdFolder -Force | Out-Null
    Write-Host "  Dossier $cmdFolder crÃ©Ã©" -ForegroundColor Green
}

foreach ($cmdFile in $cmdFiles) {
    # VÃ©rifier si le fichier existe
    if (Test-Path $cmdFile) {
        # DÃ©placer le fichier
        $destFile = Join-Path $cmdFolder $cmdFile
        if (Test-Path $destFile) {
            # Le fichier existe dÃ©jÃ  dans la destination
            $sourceFile = Get-Item $cmdFile
            $existingFile = Get-Item $destFile
            
            if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                # Le fichier source est plus rÃ©cent
                Move-Item -Path $cmdFile -Destination $destFile -Force
                Write-Host "  Fichier $cmdFile remplacÃ© (plus rÃ©cent)" -ForegroundColor Blue
            } else {
                Write-Host "  Fichier $cmdFile ignorÃ© (plus ancien ou identique)" -ForegroundColor Gray
            }
        } else {
            # Le fichier n'existe pas dans la destination
            Move-Item -Path $cmdFile -Destination $destFile
            Write-Host "  Fichier $cmdFile dÃ©placÃ© vers $cmdFolder" -ForegroundColor Green
        }
    } else {
        Write-Host "  Fichier $cmdFile non trouvÃ©" -ForegroundColor Yellow
    }
}

Write-Host "`n=== DÃ©placement terminÃ© ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
