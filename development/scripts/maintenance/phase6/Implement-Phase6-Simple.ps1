<#
.SYNOPSIS
    Version simplifiÃ©e de l'implÃ©mentation de la Phase 6.



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
<#
.SYNOPSIS
    Version simplifiÃ©e de l'implÃ©mentation de la Phase 6.
#>

# Afficher un message de dÃ©marrage
Write-Host "DÃ©marrage de la Phase 6 (version simplifiÃ©e)..."

# VÃ©rifier l'environnement
$currentDir = Get-Location
Write-Host "RÃ©pertoire courant: $currentDir"

# CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
$logDir = Join-Path -Path $PSScriptRoot -ChildPath "logs"
if (-not (Test-Path -Path $logDir -PathType Container)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de logs crÃ©Ã©: $logDir"
}

# Journaliser le dÃ©marrage
$logFile = Join-Path -Path $logDir -ChildPath "phase6_simple.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] DÃ©marrage de la Phase 6 (version simplifiÃ©e)" | Out-File -FilePath $logFile -Append

# Rechercher les scripts PowerShell
$scriptsDir = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath ""
if (Test-Path -Path $scriptsDir -PathType Container) {
    $scripts = Get-ChildItem -Path $scriptsDir -Recurse -File -Filter "*.ps1" | Where-Object { -not $_.FullName.Contains(".bak") }
    Write-Host "Nombre de scripts trouvÃ©s: $($scripts.Count)"
    "[$timestamp] Nombre de scripts trouvÃ©s: $($scripts.Count)" | Out-File -FilePath $logFile -Append

    # Afficher les 5 premiers scripts
    Write-Host "Premiers scripts trouvÃ©s:"
    foreach ($script in $scripts | Select-Object -First 5) {
        Write-Host "  - $($script.FullName)"
        "[$timestamp] Script: $($script.FullName)" | Out-File -FilePath $logFile -Append
    }
} else {
    Write-Host "RÃ©pertoire des scripts non trouvÃ©: $scriptsDir"
    "[$timestamp] RÃ©pertoire des scripts non trouvÃ©: $scriptsDir" | Out-File -FilePath $logFile -Append
}

# Afficher un message de fin
Write-Host "Phase 6 (version simplifiÃ©e) terminÃ©e."
"[$timestamp] Phase 6 (version simplifiÃ©e) terminÃ©e" | Out-File -FilePath $logFile -Append

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
