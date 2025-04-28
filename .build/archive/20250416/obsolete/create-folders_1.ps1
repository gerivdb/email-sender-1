


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
# Script pour creer la structure de dossiers

Write-Host "=== Creation de la structure de dossiers ===" -ForegroundColor Cyan

# Structure de dossiers a creer
$folders = @(
    "src",
    "src/workflows",
    "src/mcp",
    "src/mcp/batch",
    "src/mcp/config",
    "scripts",
    "development/scripts/setup",
    "development/scripts/maintenance",
    "config",
    "logs",
    "projet/documentation",
    "projet/guides",
    "development/api",
    "tests",
    "tools",
    "assets"
)

# Creer les dossiers
foreach ($folder in $folders) {
    if (-not (Test-Path ".\$folder")) {
        New-Item -ItemType Directory -Path ".\$folder" | Out-Null
        Write-Host "Dossier $folder cree" -ForegroundColor Green
    } else {
        Write-Host "Dossier $folder existe deja" -ForegroundColor Green
    }
}

Write-Host "`n=== Structure de dossiers creee ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
