


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
# Script pour corriger l'emplacement des fichiers de configuration MCP

Write-Host "=== Correction de l'emplacement des fichiers de configuration MCP ===" -ForegroundColor Cyan

# Deplacer les fichiers de configuration MCP
$configFiles = @(
    "mcp-config.json",
    "mcp-config-fixed.json"
)

foreach ($file in $configFiles) {
    # Verifier si le fichier existe dans src/workflows
    if (Test-Path ".\src\workflows\$file") {
        # Verifier si le dossier src/mcp/config existe
        if (-not (Test-Path ".\src\mcp\config")) {
            New-Item -ItemType Directory -Path ".\src\mcp\config" -Force | Out-Null
            Write-Host "Dossier src/mcp/config cree" -ForegroundColor Green
        }
        
        # Deplacer le fichier
        Move-Item -Path ".\src\workflows\$file" -Destination ".\src\mcp\config\$file" -Force
        Write-Host "Fichier $file deplace de src/workflows vers src/mcp/config" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve dans src/workflows" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
