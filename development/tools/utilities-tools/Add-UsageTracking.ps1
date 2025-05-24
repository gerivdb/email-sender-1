<#
.SYNOPSIS
    Ajoute le suivi d'utilisation aux scripts PowerShell existants.
.DESCRIPTION
    Ce script analyse les scripts PowerShell existants et ajoute automatiquement
    le code nÃ©cessaire pour suivre leur utilisation avec le module UsageMonitor.
.PARAMETER Path
    Chemin vers le script ou le rÃ©pertoire de scripts Ã  modifier.
.PARAMETER Recurse
    Indique si les sous-rÃ©pertoires doivent Ãªtre traitÃ©s rÃ©cursivement.
.PARAMETER CreateBackup
    Indique si une sauvegarde des scripts originaux doit Ãªtre crÃ©Ã©e.
.PARAMETER Force
    Force l'ajout du suivi d'utilisation mÃªme si le script contient dÃ©jÃ  du code de suivi.
.EXAMPLE
    .\Add-UsageTracking.ps1 -Path "C:\Scripts" -Recurse -CreateBackup
.NOTES
    Auteur: Augment Agent
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# VÃ©rifier si un script utilise dÃ©jÃ  le module UsageMonitor
function Test-UsageMonitorUsage {
    param ([string]$ScriptContent)
    
    return ($ScriptContent -match "UsageMonitor\.psm1" -or 
            $ScriptContent -match "Start-ScriptUsageTracking" -or 
            $ScriptContent -match "Stop-ScriptUsageTracking")
}

# Ajouter le code de suivi d'utilisation Ã  un script
function Add-UsageTrackingCode {
    param (
        [string]$ScriptPath,
        [string]$ScriptContent
    )
    
    # DÃ©finir le code Ã  ajouter
    $usageMonitorImport = @"
# Importer le module UsageMonitor
try {
    `$usageMonitorPath = Join-Path -Path (Split-Path -Parent `$PSScriptRoot) -ChildPath "utils\UsageMonitor\UsageMonitor.psm1"
    if (Test-Path -Path `$usageMonitorPath) {
        Import-Module `$usageMonitorPath -ErrorAction Stop
        Initialize-UsageMonitor -ErrorAction Stop
    }
}
catch {
    Write-Warning "Impossible de charger le module UsageMonitor: `$_"
}

"@
    
    $usageTrackingStart = @"
# DÃ©marrer le suivi d'utilisation
`$usageTrackingEnabled = `$false
`$executionId = `$null
try {
    if (Get-Command -Name Start-ScriptUsageTracking -ErrorAction SilentlyContinue) {
        `$executionId = Start-ScriptUsageTracking -ScriptPath `$PSCommandPath -ErrorAction Stop
        `$usageTrackingEnabled = `$true
    }
}
catch {
    Write-Warning "Impossible de dÃ©marrer le suivi d'utilisation: `$_"
}

"@
    
    $usageTrackingEnd = @"

# Terminer le suivi d'utilisation
try {
    if (`$usageTrackingEnabled -and `$executionId) {
        if (`$Error.Count -gt 0) {
            Stop-ScriptUsageTracking -ExecutionId `$executionId -Success `$false -ErrorMessage `$Error[0].Exception.Message -ErrorAction SilentlyContinue
        }
        else {
            Stop-ScriptUsageTracking -ExecutionId `$executionId -Success `$true -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Warning "Impossible de terminer le suivi d'utilisation: `$_"
}
"@
    
    # Trouver la position pour insÃ©rer le code
    $lines = $ScriptContent -split "`r`n|\r|\n"
    $insertImportAt = 0
    $insertStartAt = 0
    $insertEndAt = $lines.Count
    
    # Trouver la position pour l'import (aprÃ¨s les commentaires et les paramÃ¨tres)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Ignorer les lignes vides et les commentaires
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith("#")) {
            continue
        }
        
        # Ignorer le bloc de paramÃ¨tres
        if ($line.Trim() -eq "param (" -or $line.Trim().StartsWith("[CmdletBinding(")) {
            # Trouver la fin du bloc de paramÃ¨tres
            for ($j = $i; $j -lt $lines.Count; $j++) {
                if ($lines[$j].Trim() -eq ")") {
                    $i = $j + 1
                    break
                }
            }
            continue
        }
        
        # PremiÃ¨re ligne de code trouvÃ©e
        $insertImportAt = $i
        $insertStartAt = $i
        break
    }
    
    # Modifier le contenu du script
    $newContent = @()
    
    # Ajouter les lignes jusqu'au point d'insertion de l'import
    for ($i = 0; $i -lt $insertImportAt; $i++) {
        $newContent += $lines[$i]
    }
    
    # Ajouter le code d'import
    $newContent += $usageMonitorImport -split "`r`n|\r|\n"
    
    # Ajouter les lignes jusqu'au point d'insertion du dÃ©but du suivi
    for ($i = $insertImportAt; $i -lt $insertStartAt; $i++) {
        $newContent += $lines[$i]
    }
    
    # Ajouter le code de dÃ©but de suivi
    $newContent += $usageTrackingStart -split "`r`n|\r|\n"
    
    # Ajouter les lignes restantes jusqu'Ã  la fin
    for ($i = $insertStartAt; $i -lt $insertEndAt; $i++) {
        $newContent += $lines[$i]
    }
    
    # Ajouter le code de fin de suivi
    $newContent += $usageTrackingEnd -split "`r`n|\r|\n"
    
    return $newContent -join "`r`n"
}

# Traiter un script
function Invoke-Script {
    param (
        [string]$ScriptPath
    )
    
    Write-Log "Traitement du script: $ScriptPath" -Level "INFO"
    
    try {
        # Lire le contenu du script
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
        
        # VÃ©rifier si le script utilise dÃ©jÃ  le module UsageMonitor
        if (Test-UsageMonitorUsage -ScriptContent $content) {
            if (-not $Force) {
                Write-Log "Le script utilise dÃ©jÃ  le module UsageMonitor. Utilisez -Force pour remplacer." -Level "WARNING"
                return
            }
            Write-Log "Le script utilise dÃ©jÃ  le module UsageMonitor. Remplacement forcÃ©." -Level "WARNING"
        }
        
        # CrÃ©er une sauvegarde si demandÃ©
        if ($CreateBackup) {
            $backupPath = "$ScriptPath.bak"
            Copy-Item -Path $ScriptPath -Destination $backupPath -Force -ErrorAction Stop
            Write-Log "Sauvegarde crÃ©Ã©e: $backupPath" -Level "SUCCESS"
        }
        
        # Ajouter le code de suivi d'utilisation
        $newContent = Add-UsageTrackingCode -ScriptPath $ScriptPath -ScriptContent $content
        
        # Ã‰crire le nouveau contenu dans le fichier
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Ajouter le suivi d'utilisation")) {
            Set-Content -Path $ScriptPath -Value $newContent -Force -ErrorAction Stop
            Write-Log "Suivi d'utilisation ajoutÃ© avec succÃ¨s." -Level "SUCCESS"
        }
    }
    catch {
        Write-Log "Erreur lors du traitement du script $ScriptPath : $_" -Level "ERROR"
    }
}

# Point d'entrÃ©e principal
Write-Log "DÃ©marrage de l'ajout du suivi d'utilisation..." -Level "TITLE"

# VÃ©rifier si le chemin existe
if (-not (Test-Path -Path $Path)) {
    Write-Log "Le chemin spÃ©cifiÃ© n'existe pas: $Path" -Level "ERROR"
    exit 1
}

# Traiter les scripts
if (Test-Path -Path $Path -PathType Leaf) {
    # Traiter un seul fichier
    if ($Path -match "\.(ps1|psm1)$") {
        Invoke-Script -ScriptPath $Path
    }
    else {
        Write-Log "Le fichier spÃ©cifiÃ© n'est pas un script PowerShell (.ps1 ou .psm1): $Path" -Level "ERROR"
    }
}
else {
    # Traiter un rÃ©pertoire
    $searchOptions = @{
        Path = $Path
        Filter = "*.ps1"
        File = $true
    }
    
    if ($Recurse) {
        $searchOptions.Recurse = $true
    }
    
    $scripts = Get-ChildItem @searchOptions
    
    Write-Log "Nombre de scripts trouvÃ©s: $($scripts.Count)" -Level "INFO"
    
    foreach ($script in $scripts) {
        Invoke-Script -ScriptPath $script.FullName
    }
    
    # Traiter Ã©galement les fichiers .psm1
    $searchOptions.Filter = "*.psm1"
    $modules = Get-ChildItem @searchOptions
    
    Write-Log "Nombre de modules trouvÃ©s: $($modules.Count)" -Level "INFO"
    
    foreach ($module in $modules) {
        Invoke-Script -ScriptPath $module.FullName
    }
}

Write-Log "Traitement terminÃ©." -Level "TITLE"

