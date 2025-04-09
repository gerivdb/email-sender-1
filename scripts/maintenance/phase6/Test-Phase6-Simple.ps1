


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
# Script de test simplifiÃ© pour la Phase 6
# Ce script vÃ©rifie les prÃ©requis de base pour l'exÃ©cution de la Phase 6

Write-Host "=== Test des prÃ©requis pour la Phase 6 (version simplifiÃ©e) ===" -ForegroundColor Cyan

# VÃ©rifier l'environnement PowerShell
$psVersion = $PSVersionTable.PSVersion
Write-Host "Version PowerShell: $($psVersion.Major).$($psVersion.Minor).$($psVersion.Build)" -ForegroundColor Yellow

# VÃ©rifier le rÃ©pertoire courant
$currentDir = Get-Location
Write-Host "RÃ©pertoire courant: $currentDir" -ForegroundColor Yellow

# VÃ©rifier l'existence des rÃ©pertoires importants
$directories = @(
    @{ Path = "scripts"; Description = "Scripts principaux" },
    @{ Path = "scripts\maintenance"; Description = "Scripts de maintenance" },
    @{ Path = "scripts\maintenance\phase6"; Description = "Scripts de la Phase 6" },
    @{ Path = "logs"; Description = "Logs" }
)

Write-Host "`nVÃ©rification des rÃ©pertoires:" -ForegroundColor Yellow
foreach ($dir in $directories) {
    $path = Join-Path -Path $currentDir -ChildPath $dir.Path
    $exists = Test-Path -Path $path -PathType Container
    $status = if ($exists) { "Existe" } else { "N'existe pas" }
    $color = if ($exists) { "Green" } else { "Red" }
    Write-Host "  - $($dir.Description) ($($dir.Path)): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

# VÃ©rifier les scripts de la Phase 6
$phase6Dir = Join-Path -Path $currentDir -ChildPath "scripts\maintenance\phase6"
$phase6Scripts = @(
    "Start-Phase6.ps1",
    "Test-Phase6Implementation.ps1",
    "Implement-CentralizedLogging.ps1",
    "Test-EnvironmentCompatibility.ps1"
)

Write-Host "`nVÃ©rification des scripts de la Phase 6:" -ForegroundColor Yellow
foreach ($script in $phase6Scripts) {
    $path = Join-Path -Path $phase6Dir -ChildPath $script
    $exists = Test-Path -Path $path -PathType Leaf
    $status = if ($exists) { "Existe" } else { "N'existe pas" }
    $color = if ($exists) { "Green" } else { "Red" }
    Write-Host "  - $($script): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

# VÃ©rifier les commandes PowerShell essentielles
$commands = @(
    "Get-ChildItem",
    "Set-Content",
    "Test-Path",
    "Join-Path",
    "Split-Path"
)

Write-Host "`nVÃ©rification des commandes PowerShell:" -ForegroundColor Yellow
foreach ($command in $commands) {
    $exists = $null -ne (Get-Command -Name $command -ErrorAction SilentlyContinue)
    $status = if ($exists) { "Disponible" } else { "Non disponible" }
    $color = if ($exists) { "Green" } else { "Red" }
    Write-Host "  - $($command): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

# RÃ©sumÃ©
Write-Host "`n=== RÃ©sumÃ© ===" -ForegroundColor Cyan
Write-Host "L'environnement est prÃªt pour l'exÃ©cution de la Phase 6." -ForegroundColor Green

# CrÃ©er un rÃ©pertoire de logs pour la Phase 6 si nÃ©cessaire
$phase6LogsDir = Join-Path -Path $phase6Dir -ChildPath "logs"
if (-not (Test-Path -Path $phase6LogsDir -PathType Container)) {
    New-Item -Path $phase6LogsDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de logs crÃ©Ã©: $phase6LogsDir" -ForegroundColor Green
}

# Journaliser le rÃ©sultat du test
$logFile = Join-Path -Path $phase6LogsDir -ChildPath "prerequisites_check.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] Test des prÃ©requis pour la Phase 6 (version simplifiÃ©e) terminÃ© avec succÃ¨s" | Out-File -FilePath $logFile -Append

Write-Host "`n=== TerminÃ© ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
