


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
# Script pour configurer le MCP Git Ingest dans Augment

Write-Host "=== Configuration du MCP Git Ingest dans Augment ===" -ForegroundColor Cyan

# VÃ©rifier si le dossier scripts\cmd\augment existe
$augmentDir = "scripts\cmd\augment"
if (-not (Test-Path $augmentDir)) {
    Write-Host "CrÃ©ation du dossier $augmentDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $augmentDir -Force | Out-Null
    Write-Host "âœ… Dossier $augmentDir crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier $augmentDir existe dÃ©jÃ " -ForegroundColor Green
}

# VÃ©rifier si le fichier augment-mcp-git-ingest.cmd existe
$gitIngestCmdPath = "$augmentDir\augment-mcp-git-ingest.cmd"
if (-not (Test-Path $gitIngestCmdPath)) {
    Write-Host "CrÃ©ation du fichier $gitIngestCmdPath..." -ForegroundColor Yellow
    $gitIngestCmdContent = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo DÃ©marrage du MCP Git Ingest...

:: Utiliser la commande directe avec le dÃ©pÃ´t GitHub
npx -y --package=git+https://github.com/adhikasp/mcp-git-ingest mcp-git-ingest
"@
    Set-Content -Path $gitIngestCmdPath -Value $gitIngestCmdContent
    Write-Host "âœ… Fichier $gitIngestCmdPath crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "âœ… Fichier $gitIngestCmdPath existe dÃ©jÃ " -ForegroundColor Green
}

# Instructions pour configurer Augment
Write-Host "`nInstructions pour configurer le MCP Git Ingest dans Augment :" -ForegroundColor Cyan
Write-Host "1. Ouvrez Augment Settings (Ctrl+Shift+P puis 'Augment: Open Settings')"
Write-Host "2. Dans la section 'MCP Servers', cliquez sur 'Add MCP Server'"
Write-Host "3. Entrez les informations suivantes :"
Write-Host "   - Name: MCP Git Ingest"
Write-Host "   - Command: $((Resolve-Path $gitIngestCmdPath).Path)"
Write-Host "4. Cliquez sur 'Save'"

Write-Host "`n=== Configuration du MCP Git Ingest dans Augment terminÃ©e ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
