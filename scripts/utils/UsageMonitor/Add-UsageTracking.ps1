<#
.SYNOPSIS
    Ajoute le suivi d'utilisation aux scripts PowerShell existants.
.DESCRIPTION
    Ce script analyse les scripts PowerShell existants et ajoute automatiquement
    le code nécessaire pour suivre leur utilisation avec le module UsageMonitor.
.PARAMETER Path
    Chemin vers le script ou le répertoire de scripts à modifier.
.PARAMETER Recurse
    Indique si les sous-répertoires doivent être traités récursivement.
.PARAMETER CreateBackup
    Indique si une sauvegarde des scripts originaux doit être créée.
.PARAMETER Force
    Force l'ajout du suivi d'utilisation même si le script contient déjà du code de suivi.
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

# Fonction pour écrire des messages de log
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

# Vérifier si un script utilise déjà le module UsageMonitor
function Test-UsageMonitorUsage {
    param ([string]$ScriptContent)
    
    return ($ScriptContent -match "UsageMonitor\.psm1" -or 
            $ScriptContent -match "Start-ScriptUsageTracking" -or 
            $ScriptContent -match "Stop-ScriptUsageTracking")
}

# Ajouter le code de suivi d'utilisation à un script
function Add-UsageTrackingCode {
    param (
        [string]$ScriptPath,
        [string]$ScriptContent
    )
    
    # Définir le code à ajouter
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
# Démarrer le suivi d'utilisation
`$usageTrackingEnabled = `$false
`$executionId = `$null
try {
    if (Get-Command -Name Start-ScriptUsageTracking -ErrorAction SilentlyContinue) {
        `$executionId = Start-ScriptUsageTracking -ScriptPath `$PSCommandPath -ErrorAction Stop
        `$usageTrackingEnabled = `$true
    }
}
catch {
    Write-Warning "Impossible de démarrer le suivi d'utilisation: `$_"
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
    
    # Trouver la position pour insérer le code
    $lines = $ScriptContent -split "`r`n|\r|\n"
    $insertImportAt = 0
    $insertStartAt = 0
    $insertEndAt = $lines.Count
    
    # Trouver la position pour l'import (après les commentaires et les paramètres)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Ignorer les lignes vides et les commentaires
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith("#")) {
            continue
        }
        
        # Ignorer le bloc de paramètres
        if ($line.Trim() -eq "param (" -or $line.Trim().StartsWith("[CmdletBinding(")) {
            # Trouver la fin du bloc de paramètres
            for ($j = $i; $j -lt $lines.Count; $j++) {
                if ($lines[$j].Trim() -eq ")") {
                    $i = $j + 1
                    break
                }
            }
            continue
        }
        
        # Première ligne de code trouvée
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
    
    # Ajouter les lignes jusqu'au point d'insertion du début du suivi
    for ($i = $insertImportAt; $i -lt $insertStartAt; $i++) {
        $newContent += $lines[$i]
    }
    
    # Ajouter le code de début de suivi
    $newContent += $usageTrackingStart -split "`r`n|\r|\n"
    
    # Ajouter les lignes restantes jusqu'à la fin
    for ($i = $insertStartAt; $i -lt $insertEndAt; $i++) {
        $newContent += $lines[$i]
    }
    
    # Ajouter le code de fin de suivi
    $newContent += $usageTrackingEnd -split "`r`n|\r|\n"
    
    return $newContent -join "`r`n"
}

# Traiter un script
function Process-Script {
    param (
        [string]$ScriptPath
    )
    
    Write-Log "Traitement du script: $ScriptPath" -Level "INFO"
    
    try {
        # Lire le contenu du script
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
        
        # Vérifier si le script utilise déjà le module UsageMonitor
        if (Test-UsageMonitorUsage -ScriptContent $content) {
            if (-not $Force) {
                Write-Log "Le script utilise déjà le module UsageMonitor. Utilisez -Force pour remplacer." -Level "WARNING"
                return
            }
            Write-Log "Le script utilise déjà le module UsageMonitor. Remplacement forcé." -Level "WARNING"
        }
        
        # Créer une sauvegarde si demandé
        if ($CreateBackup) {
            $backupPath = "$ScriptPath.bak"
            Copy-Item -Path $ScriptPath -Destination $backupPath -Force -ErrorAction Stop
            Write-Log "Sauvegarde créée: $backupPath" -Level "SUCCESS"
        }
        
        # Ajouter le code de suivi d'utilisation
        $newContent = Add-UsageTrackingCode -ScriptPath $ScriptPath -ScriptContent $content
        
        # Écrire le nouveau contenu dans le fichier
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Ajouter le suivi d'utilisation")) {
            Set-Content -Path $ScriptPath -Value $newContent -Force -ErrorAction Stop
            Write-Log "Suivi d'utilisation ajouté avec succès." -Level "SUCCESS"
        }
    }
    catch {
        Write-Log "Erreur lors du traitement du script $ScriptPath : $_" -Level "ERROR"
    }
}

# Point d'entrée principal
Write-Log "Démarrage de l'ajout du suivi d'utilisation..." -Level "TITLE"

# Vérifier si le chemin existe
if (-not (Test-Path -Path $Path)) {
    Write-Log "Le chemin spécifié n'existe pas: $Path" -Level "ERROR"
    exit 1
}

# Traiter les scripts
if (Test-Path -Path $Path -PathType Leaf) {
    # Traiter un seul fichier
    if ($Path -match "\.(ps1|psm1)$") {
        Process-Script -ScriptPath $Path
    }
    else {
        Write-Log "Le fichier spécifié n'est pas un script PowerShell (.ps1 ou .psm1): $Path" -Level "ERROR"
    }
}
else {
    # Traiter un répertoire
    $searchOptions = @{
        Path = $Path
        Filter = "*.ps1"
        File = $true
    }
    
    if ($Recurse) {
        $searchOptions.Recurse = $true
    }
    
    $scripts = Get-ChildItem @searchOptions
    
    Write-Log "Nombre de scripts trouvés: $($scripts.Count)" -Level "INFO"
    
    foreach ($script in $scripts) {
        Process-Script -ScriptPath $script.FullName
    }
    
    # Traiter également les fichiers .psm1
    $searchOptions.Filter = "*.psm1"
    $modules = Get-ChildItem @searchOptions
    
    Write-Log "Nombre de modules trouvés: $($modules.Count)" -Level "INFO"
    
    foreach ($module in $modules) {
        Process-Script -ScriptPath $module.FullName
    }
}

Write-Log "Traitement terminé." -Level "TITLE"
