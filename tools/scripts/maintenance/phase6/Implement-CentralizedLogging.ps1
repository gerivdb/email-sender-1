<#
.SYNOPSIS
    Implémente un système de journalisation centralisé pour les scripts.
.DESCRIPTION
    Ce script implémente un système de journalisation centralisé pour les scripts PowerShell.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [string]$ScriptsDirectory = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "scripts"),
    [string]$LoggerModulePath = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\CentralizedLogger.ps1"),
    [switch]$CreateBackup,
    [string]$LogFilePath = (Join-Path -Path $PSScriptRoot -ChildPath "centralized_logging.log")
)

# Fonction de journalisation simple
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    } catch { Write-Warning "Impossible d'écrire dans le journal: $_" }
}

# Vérifier si un script utilise déjà le module de journalisation
function Test-LoggerModuleUsage {
    param ([string]$ScriptPath)
    $content = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { return $false }
    return ($content -match "CentralizedLogger\.ps1" -or $content -match "Initialize-Logger" -or 
            $content -match "Write-Log(Info|Warning|Error|Debug|Verbose|Critical)")
}

# Ajouter le module de journalisation à un script
function Add-LoggerModule {
    param ([string]$ScriptPath, [string]$LoggerModulePath, [switch]$CreateBackup)
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Script non trouvé: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    if (Test-LoggerModuleUsage -ScriptPath $ScriptPath) {
        Write-Log "Le script utilise déjà le module de journalisation: $ScriptPath" -Level "INFO"
        return $true
    }
    
    $content = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        Write-Log "Impossible de lire le script: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    # Créer une sauvegarde si demandé
    if ($CreateBackup) {
        Copy-Item -Path $ScriptPath -Destination "$ScriptPath.bak" -Force
        Write-Log "Sauvegarde créée: $ScriptPath.bak" -Level "INFO"
    }
    
    # Calculer le chemin relatif du module de journalisation
    $scriptDir = Split-Path -Path $ScriptPath -Parent
    try {
        $relativeLoggerPath = [System.IO.Path]::GetRelativePath($scriptDir, $LoggerModulePath)
    } catch {
        $relativeLoggerPath = $LoggerModulePath
        Write-Log "Impossible de calculer le chemin relatif: $_" -Level "WARNING"
    }
    
    # Code à ajouter au script
    $loggerCode = @"

# Importer le module de journalisation centralisé
`$loggerPath = Join-Path -Path `$PSScriptRoot -ChildPath "$relativeLoggerPath"
if (Test-Path -Path `$loggerPath) {
    try {
        . `$loggerPath
        Initialize-Logger -LogFilePath (Join-Path -Path `$PSScriptRoot -ChildPath "logs\`$(Get-Date -Format 'yyyy-MM-dd').log") -LogToConsole -LogToFile
        Write-LogInfo "Script démarré: `$(`$MyInvocation.MyCommand.Name)"
    } catch {
        Write-Warning "Impossible de charger le module de journalisation: `$_"
        function Write-Log { param([string]`$Message, [string]`$Level="INFO") 
            Write-Host "``[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')``] [`$Level] `$Message" 
        }
        Set-Alias -Name Write-LogInfo -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogWarning -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogError -Value Write-Log -Scope Script
    }
}

"@
    
    # Ajouter le code au début du script après les commentaires et param
    $header = ""
    if ($content -match '(?s)^(#[^\n]*\n)+') {
        $header = $matches[0]
        $content = $content.Substring($header.Length)
    }
    
    $param = ""
    if ($content -match '(?s)^(\s*param\s*\([^\)]+\))') {
        $param = $matches[0]
        $content = $content.Substring($param.Length)
    }
    
    $newContent = "$header$param$loggerCode$content"
    
    # Enregistrer le nouveau contenu
    if ($PSCmdlet.ShouldProcess($ScriptPath, "Ajouter le module de journalisation")) {
        Set-Content -Path $ScriptPath -Value $newContent
        Write-Log "Module de journalisation ajouté: $ScriptPath" -Level "SUCCESS"
        return $true
    } else {
        Write-Log "Simulation: Module de journalisation ajouté: $ScriptPath" -Level "INFO"
        return $true
    }
}

# Fonction principale
function Implement-CentralizedLogging {
    param ([string]$ScriptsDirectory, [string]$LoggerModulePath, [switch]$CreateBackup)
    
    Write-Log "Démarrage de l'implémentation du système de journalisation centralisé"
    
    # Vérifications
    if (-not (Test-Path -Path $ScriptsDirectory)) {
        Write-Log "Répertoire des scripts non trouvé: $ScriptsDirectory" -Level "ERROR"
        return $false
    }
    
    if (-not (Test-Path -Path $LoggerModulePath)) {
        Write-Log "Module de journalisation non trouvé: $LoggerModulePath" -Level "ERROR"
        return $false
    }
    
    # Récupérer les scripts PowerShell
    $scripts = Get-ChildItem -Path $ScriptsDirectory -Recurse -File -Filter "*.ps1" | 
               Where-Object { -not $_.FullName.Contains(".bak") }
    
    Write-Log "Scripts trouvés: $($scripts.Count)"
    
    $results = @{
        Total = $scripts.Count
        Succeeded = 0
        Skipped = 0
        Failed = 0
    }
    
    foreach ($script in $scripts) {
        if (Test-LoggerModuleUsage -ScriptPath $script.FullName) {
            Write-Log "Ignoré (déjà implémenté): $($script.FullName)" -Level "INFO"
            $results.Skipped++
            continue
        }
        
        if ($PSCmdlet.ShouldProcess($script.FullName, "Ajouter le module de journalisation")) {
            $success = Add-LoggerModule -ScriptPath $script.FullName -LoggerModulePath $LoggerModulePath -CreateBackup:$CreateBackup
            if ($success) { $results.Succeeded++ } else { $results.Failed++ }
        }
    }
    
    Write-Log "Implémentation terminée: $($results.Succeeded) réussis, $($results.Skipped) ignorés, $($results.Failed) échoués"
    return $results
}

# Exécuter la fonction principale
$result = Implement-CentralizedLogging -ScriptsDirectory $ScriptsDirectory -LoggerModulePath $LoggerModulePath -CreateBackup:$CreateBackup

# Afficher un résumé
Write-Host "`nRésumé de l'implémentation:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Scripts traités: $($result.Total)" -ForegroundColor White
Write-Host "Succès: $($result.Succeeded)" -ForegroundColor Green
Write-Host "Ignorés: $($result.Skipped)" -ForegroundColor Yellow
Write-Host "Échecs: $($result.Failed)" -ForegroundColor Red
Write-Host "Taux de réussite: $(if ($result.Total -gt 0) { [math]::Round((($result.Succeeded + $result.Skipped) / $result.Total) * 100, 2) } else { 0 })%" -ForegroundColor $(if ($result.Total -gt 0 -and (($result.Succeeded + $result.Skipped) / $result.Total) -ge 0.8) { "Green" } else { "Yellow" })
Write-Host "Journal: $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
