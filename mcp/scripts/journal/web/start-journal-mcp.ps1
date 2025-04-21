


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
# Script PowerShell pour dÃ©marrer le serveur MCP avec le provider du journal de bord

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$McpConfigPath = Join-Path $ProjectDir "..\..\D"

# VÃ©rifier si le module MCP est installÃ©
$mcpInstalled = npm list -g @modelcontextprotocol/server | Select-String "@modelcontextprotocol/server"

if (-not $mcpInstalled) {
    Write-Host "Le module @modelcontextprotocol/server n'est pas installÃ© globalement." -ForegroundColor Yellow
    Write-Host "Installation en cours..." -ForegroundColor Yellow
    
    npm install -g @modelcontextprotocol/server
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de l'installation de @modelcontextprotocol/server." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "@modelcontextprotocol/server installÃ© avec succÃ¨s." -ForegroundColor Green
}

# Installer les dÃ©pendances nÃ©cessaires pour le provider
Write-Host "Installation des dÃ©pendances pour le provider du journal..." -ForegroundColor Cyan
npm install --prefix scripts/mcp js-yaml

# DÃ©marrer le serveur MCP
Write-Host "DÃ©marrage du serveur MCP avec le provider du journal de bord..." -ForegroundColor Cyan
Write-Host "Configuration: $McpConfigPath" -ForegroundColor Cyan

# CrÃ©er un fichier batch temporaire pour exÃ©cuter le serveur
$BatchContent = @"
@echo off
cd /d "$ProjectDir"
mcp-server --config "$McpConfigPath"
"@

$BatchPath = Join-Path $ProjectDir "scripts\cmd\temp-mcp-server.bat"
Set-Content -Path $BatchPath -Value $BatchContent -Encoding ASCII

# DÃ©marrer le serveur MCP
Start-Process -FilePath $BatchPath -NoNewWindow

Write-Host "Serveur MCP dÃ©marrÃ© avec le provider du journal de bord." -ForegroundColor Green
Write-Host "Le serveur est accessible Ã  l'adresse: http://localhost:8080" -ForegroundColor Green
Write-Host "Pour arrÃªter le serveur, fermez la fenÃªtre du terminal ou utilisez Ctrl+C." -ForegroundColor Yellow


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
