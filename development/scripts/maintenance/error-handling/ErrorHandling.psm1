<#
.SYNOPSIS
    Module de gestion d'erreurs pour les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour gÃ©rer les erreurs de maniÃ¨re cohÃ©rente dans les scripts PowerShell.
    Il inclut des fonctions pour ajouter des blocs try/catch, journaliser les erreurs et crÃ©er un systÃ¨me
    de journalisation centralisÃ©.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Variables globales pour la configuration
$script:ErrorLogPath = Join-Path -Path $env:TEMP -ChildPath "ErrorLogs"
$script:DefaultErrorLogFile = Join-Path -Path $script:ErrorLogPath -ChildPath "error_log.json"
$script:ErrorDatabase = @{}
$script:ErrorCategories = @{
    "FileSystem" = "Erreurs liÃ©es au systÃ¨me de fichiers"
    "Network" = "Erreurs liÃ©es au rÃ©seau"
    "Authentication" = "Erreurs liÃ©es Ã  l'authentification"
    "Permission" = "Erreurs liÃ©es aux permissions"
    "Syntax" = "Erreurs de syntaxe"
    "Logic" = "Erreurs de logique"
    "Configuration" = "Erreurs de configuration"
    "External" = "Erreurs liÃ©es Ã  des systÃ¨mes externes"
    "Unknown" = "Erreurs inconnues"
}

# Fonction pour initialiser le module
function Initialize-ErrorHandling {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )
    
    try {
        # DÃ©finir le chemin du journal d'erreurs
        if ($LogPath) {
            $script:ErrorLogPath = $LogPath
        }
        
        if (-not (Test-Path -Path $script:ErrorLogPath)) {
            New-Item -Path $script:ErrorLogPath -ItemType Directory -Force | Out-Null
        }
        
        # DÃ©finir le fichier de journal d'erreurs
        if ($LogFile) {
            $script:DefaultErrorLogFile = Join-Path -Path $script:ErrorLogPath -ChildPath $LogFile
        }
        
        # Charger la base de donnÃ©es d'erreurs si elle existe
        if (Test-Path -Path $script:DefaultErrorLogFile) {
            $script:ErrorDatabase = Get-Content -Path $script:DefaultErrorLogFile -Raw | ConvertFrom-Json -AsHashtable
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'initialisation du module de gestion d'erreurs: $_"
        return $false
    }
}

# Fonction pour ajouter un bloc try/catch Ã  un script
function Add-TryCatchBlock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$BackupFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # VÃ©rifier que le fichier existe
        if (-not (Test-Path -Path $ScriptPath)) {
            throw "Le fichier spÃ©cifiÃ© n'existe pas: $ScriptPath"
        }
        
        # CrÃ©er une sauvegarde si demandÃ©
        if ($BackupFile) {
            $backupPath = "$ScriptPath.bak"
            Copy-Item -Path $ScriptPath -Destination $backupPath -Force
        }
        
        # Lire le contenu du script
        $scriptContent = Get-Content -Path $ScriptPath -Raw
        
        # VÃ©rifier si le script contient dÃ©jÃ  des blocs try/catch
        $hasTryCatch = $scriptContent -match "try\s*\{"
        
        if ($hasTryCatch -and -not $Force) {
            Write-Warning "Le script contient dÃ©jÃ  des blocs try/catch. Utilisez -Force pour les remplacer."
            return $false
        }
        
        # Analyser le script pour identifier les fonctions et les sections principales
        $functions = [regex]::Matches($scriptContent, "function\s+([a-zA-Z0-9_-]+)\s*\{")
        
        if ($functions.Count -gt 0) {
            # Script avec des fonctions
            $modifiedContent = $scriptContent
            
            foreach ($function in $functions) {
                $functionName = $function.Groups[1].Value
                $functionStart = $function.Index
                
                # Trouver la fin de la fonction
                $braceCount = 0
                $currentPos = $functionStart + $function.Length - 1
                $functionEnd = $scriptContent.Length - 1
                
                for ($i = $currentPos; $i -lt $scriptContent.Length; $i++) {
                    if ($scriptContent[$i] -eq '{') {
                        $braceCount++
                    }
                    elseif ($scriptContent[$i] -eq '}') {
                        $braceCount--
                        if ($braceCount -eq 0) {
                            $functionEnd = $i
                            break
                        }
                    }
                }
                
                # Extraire le corps de la fonction
                $functionBody = $scriptContent.Substring($functionStart, $functionEnd - $functionStart + 1)
                
                # VÃ©rifier si la fonction contient dÃ©jÃ  un bloc try/catch
                if ($functionBody -match "try\s*\{" -and -not $Force) {
                    continue
                }
                
                # Ajouter le bloc try/catch
                $newFunctionBody = $functionBody -replace "(\{[\r\n\s]*)((?!\s*try\s*\{).*?)([\r\n\s]*\}[\r\n\s]*$)", "`$1try {`r`n`$2`r`n    } catch {`r`n        Write-Error `"Erreur dans la fonction $functionName : `$_`"`r`n        Write-Log-Error -ErrorRecord `$_ -FunctionName `"$functionName`"`r`n    }`r`n`$3"
                
                # Remplacer la fonction dans le script
                $modifiedContent = $modifiedContent.Replace($functionBody, $newFunctionBody)
            }
            
            # Ã‰crire le contenu modifiÃ© dans le fichier
            Set-Content -Path $ScriptPath -Value $modifiedContent -Force
        }
        else {
            # Script sans fonctions, ajouter un bloc try/catch global
            $newContent = @"
try {
$scriptContent
} catch {
    Write-Error "Erreur dans le script : `$_"
    Write-Log-Error -ErrorRecord `$_ -FunctionName "Main"
}
"@
            
            # Ã‰crire le contenu modifiÃ© dans le fichier
            Set-Content -Path $ScriptPath -Value $newContent -Force
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'ajout des blocs try/catch: $_"
        return $false
    }
}

# Fonction pour journaliser une erreur
function Write-Log-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $false)]
        [string]$FunctionName = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile = $script:DefaultErrorLogFile
    )
    
    try {
        # CrÃ©er le rÃ©pertoire de journaux s'il n'existe pas
        $logDir = Split-Path -Path $LogFile -Parent
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # DÃ©terminer la catÃ©gorie d'erreur si non spÃ©cifiÃ©e
        if ($Category -eq "Unknown") {
            if ($ErrorRecord.Exception -is [System.IO.IOException]) {
                $Category = "FileSystem"
            }
            elseif ($ErrorRecord.Exception -is [System.Net.WebException]) {
                $Category = "Network"
            }
            elseif ($ErrorRecord.Exception -is [System.UnauthorizedAccessException]) {
                $Category = "Permission"
            }
            elseif ($ErrorRecord.Exception -is [System.Management.Automation.ParseException]) {
                $Category = "Syntax"
            }
        }
        
        # CrÃ©er l'entrÃ©e d'erreur
        $errorEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            FunctionName = $FunctionName
            Category = $Category
            Message = $ErrorRecord.Exception.Message
            ScriptStackTrace = $ErrorRecord.ScriptStackTrace
            ErrorDetails = $ErrorRecord.ErrorDetails
            PositionMessage = $ErrorRecord.InvocationInfo.PositionMessage
            Exception = $ErrorRecord.Exception.GetType().FullName
        }
        
        # Charger le journal existant ou crÃ©er un nouveau
        $errorLog = @()
        if (Test-Path -Path $LogFile) {
            $errorLog = Get-Content -Path $LogFile -Raw | ConvertFrom-Json
            if (-not $errorLog) {
                $errorLog = @()
            }
        }
        
        # Ajouter la nouvelle entrÃ©e
        $errorLog += $errorEntry
        
        # Enregistrer le journal
        $errorLog | ConvertTo-Json -Depth 5 | Set-Content -Path $LogFile -Force
        
        # Mettre Ã  jour la base de donnÃ©es d'erreurs
        $errorHash = Get-Hash-For-Error -ErrorRecord $ErrorRecord
        if (-not $script:ErrorDatabase.ContainsKey($errorHash)) {
            $script:ErrorDatabase[$errorHash] = @{
                FirstOccurrence = $errorEntry.Timestamp
                LastOccurrence = $errorEntry.Timestamp
                Count = 1
                Category = $Category
                Message = $ErrorRecord.Exception.Message
                Solutions = @()
            }
        }
        else {
            $script:ErrorDatabase[$errorHash].LastOccurrence = $errorEntry.Timestamp
            $script:ErrorDatabase[$errorHash].Count++
        }
        
        # Enregistrer la base de donnÃ©es d'erreurs
        $script:ErrorDatabase | ConvertTo-Json -Depth 5 | Set-Content -Path "$script:ErrorLogPath\error_database.json" -Force
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la journalisation de l'erreur: $_"
        return $false
    }
}

# Fonction pour obtenir un hash unique pour une erreur
function Get-Hash-For-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    $errorString = "$($ErrorRecord.Exception.GetType().FullName)|$($ErrorRecord.Exception.Message)|$($ErrorRecord.InvocationInfo.ScriptLineNumber)"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($errorString)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    $hash = [System.BitConverter]::ToString($algorithm.ComputeHash($bytes))
    
    return $hash.Replace("-", "")
}

# Fonction pour crÃ©er un systÃ¨me de journalisation centralisÃ©
function New-CentralizedLoggingSystem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath = $script:ErrorLogPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAnalytics
    )
    
    try {
        # CrÃ©er le rÃ©pertoire de journaux s'il n'existe pas
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er les sous-rÃ©pertoires
        $directories = @(
            "Errors",
            "Warnings",
            "Information",
            "Debug"
        )
        
        foreach ($dir in $directories) {
            $dirPath = Join-Path -Path $LogPath -ChildPath $dir
            if (-not (Test-Path -Path $dirPath)) {
                New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
            }
        }
        
        # CrÃ©er le fichier de configuration
        $configPath = Join-Path -Path $LogPath -ChildPath "logging_config.json"
        $config = @{
            LogPath = $LogPath
            ErrorLogFile = Join-Path -Path $LogPath -ChildPath "Errors\error_log.json"
            WarningLogFile = Join-Path -Path $LogPath -ChildPath "Warnings\warning_log.json"
            InfoLogFile = Join-Path -Path $LogPath -ChildPath "Information\info_log.json"
            DebugLogFile = Join-Path -Path $LogPath -ChildPath "Debug\debug_log.json"
            RotationInterval = "Daily"
            MaxLogSize = 10MB
            MaxLogAge = 30
            IncludeAnalytics = $IncludeAnalytics
        }
        
        $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Force
        
        # CrÃ©er le script de rotation des journaux
        $rotationScriptPath = Join-Path -Path $LogPath -ChildPath "Rotate-Logs.ps1"
        $rotationScript = @"
<#
.SYNOPSIS
    Script de rotation des journaux.

.DESCRIPTION
    Ce script effectue la rotation des fichiers journaux selon la configuration spÃ©cifiÃ©e.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Charger la configuration
`$configPath = Join-Path -Path `$PSScriptRoot -ChildPath "logging_config.json"
`$config = Get-Content -Path `$configPath -Raw | ConvertFrom-Json

# Fonction pour effectuer la rotation d'un fichier journal
function Rotate-LogFile {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$LogFile,
        
        [Parameter(Mandatory = `$false)]
        [int]`$MaxLogAge = 30,
        
        [Parameter(Mandatory = `$false)]
        [long]`$MaxLogSize = 10MB
    )
    
    if (-not (Test-Path -Path `$LogFile)) {
        return
    }
    
    `$logFileInfo = Get-Item -Path `$LogFile
    `$logDir = `$logFileInfo.DirectoryName
    `$logName = `$logFileInfo.BaseName
    `$logExt = `$logFileInfo.Extension
    
    # VÃ©rifier si la rotation est nÃ©cessaire
    `$needRotation = `$false
    
    # Rotation basÃ©e sur la taille
    if (`$logFileInfo.Length -gt `$MaxLogSize) {
        `$needRotation = `$true
    }
    
    # Rotation basÃ©e sur l'Ã¢ge
    `$rotationInterval = `$config.RotationInterval
    `$lastWriteTime = `$logFileInfo.LastWriteTime
    
    switch (`$rotationInterval) {
        "Daily" {
            if ((Get-Date) - `$lastWriteTime).Days -ge 1) {
                `$needRotation = `$true
            }
        }
        "Weekly" {
            if ((Get-Date) - `$lastWriteTime).Days -ge 7) {
                `$needRotation = `$true
            }
        }
        "Monthly" {
            if ((Get-Date) - `$lastWriteTime).Days -ge 30) {
                `$needRotation = `$true
            }
        }
    }
    
    if (`$needRotation) {
        `$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        `$newLogFile = Join-Path -Path `$logDir -ChildPath "`$logName`_`$timestamp`$logExt"
        
        Move-Item -Path `$LogFile -Destination `$newLogFile -Force
        
        # CrÃ©er un nouveau fichier journal vide
        New-Item -Path `$LogFile -ItemType File -Force | Out-Null
        
        # Supprimer les anciens fichiers journaux
        `$oldLogs = Get-ChildItem -Path `$logDir -Filter "`$logName`_*`$logExt" | Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-`$MaxLogAge) }
        foreach (`$oldLog in `$oldLogs) {
            Remove-Item -Path `$oldLog.FullName -Force
        }
    }
}

# Effectuer la rotation des journaux
Rotate-LogFile -LogFile `$config.ErrorLogFile -MaxLogAge `$config.MaxLogAge -MaxLogSize `$config.MaxLogSize
Rotate-LogFile -LogFile `$config.WarningLogFile -MaxLogAge `$config.MaxLogAge -MaxLogSize `$config.MaxLogSize
Rotate-LogFile -LogFile `$config.InfoLogFile -MaxLogAge `$config.MaxLogAge -MaxLogSize `$config.MaxLogSize
Rotate-LogFile -LogFile `$config.DebugLogFile -MaxLogAge `$config.MaxLogAge -MaxLogSize `$config.MaxLogSize
"@
        
        Set-Content -Path $rotationScriptPath -Value $rotationScript -Force
        
        # CrÃ©er le script d'analyse des erreurs si demandÃ©
        if ($IncludeAnalytics) {
            $analyticsScriptPath = Join-Path -Path $LogPath -ChildPath "Analyze-Errors.ps1"
            $analyticsScript = @"
<#
.SYNOPSIS
    Script d'analyse des erreurs.

.DESCRIPTION
    Ce script analyse les erreurs journalisÃ©es pour identifier des patterns et suggÃ©rer des solutions.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Charger la configuration
`$configPath = Join-Path -Path `$PSScriptRoot -ChildPath "logging_config.json"
`$config = Get-Content -Path `$configPath -Raw | ConvertFrom-Json

# Charger la base de donnÃ©es d'erreurs
`$errorDatabasePath = Join-Path -Path `$PSScriptRoot -ChildPath "error_database.json"
`$errorDatabase = @{}

if (Test-Path -Path `$errorDatabasePath) {
    `$errorDatabase = Get-Content -Path `$errorDatabasePath -Raw | ConvertFrom-Json -AsHashtable
}

# Analyser les erreurs
`$errorLogPath = `$config.ErrorLogFile
`$errorLog = @()

if (Test-Path -Path `$errorLogPath) {
    `$errorLog = Get-Content -Path `$errorLogPath -Raw | ConvertFrom-Json
}

# GÃ©nÃ©rer un rapport d'analyse
`$reportPath = Join-Path -Path `$PSScriptRoot -ChildPath "error_analysis_report.md"
`$report = @"
# Rapport d'analyse des erreurs

## RÃ©sumÃ©
- **Nombre total d'erreurs**: `$(`$errorLog.Count)
- **Date de gÃ©nÃ©ration**: `$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Erreurs les plus frÃ©quentes

| CatÃ©gorie | Message | Occurrences | DerniÃ¨re occurrence |
|-----------|---------|-------------|---------------------|
"@

# Ajouter les erreurs les plus frÃ©quentes au rapport
`$topErrors = `$errorDatabase.GetEnumerator() | Sort-Object { `$_.Value.Count } -Descending | Select-Object -First 10

foreach (`$error in `$topErrors) {
    `$report += "`n| `$(`$error.Value.Category) | `$(`$error.Value.Message) | `$(`$error.Value.Count) | `$(`$error.Value.LastOccurrence) |"
}

`$report += @"

## Recommandations

"@

# Ajouter des recommandations basÃ©es sur les catÃ©gories d'erreurs
`$errorCategories = `$errorLog | Group-Object -Property Category

foreach (`$category in `$errorCategories) {
    `$report += "`n### `$(`$category.Name) (`$(`$category.Count) erreurs)`n"
    
    switch (`$category.Name) {
        "FileSystem" {
            `$report += @"
- VÃ©rifiez les permissions des fichiers et rÃ©pertoires
- Assurez-vous que les chemins sont correctement spÃ©cifiÃ©s
- Utilisez des chemins absolus plutÃ´t que relatifs
"@
        }
        "Network" {
            `$report += @"
- VÃ©rifiez la connectivitÃ© rÃ©seau
- Assurez-vous que les URL sont correctes
- VÃ©rifiez les paramÃ¨tres du proxy si applicable
"@
        }
        "Permission" {
            `$report += @"
- ExÃ©cutez le script avec des privilÃ¨ges administratifs
- VÃ©rifiez les permissions des utilisateurs
- Utilisez des jetons d'authentification valides
"@
        }
        "Syntax" {
            `$report += @"
- VÃ©rifiez la syntaxe du code
- Utilisez un linter pour dÃ©tecter les erreurs de syntaxe
- Assurez-vous que les variables sont correctement dÃ©clarÃ©es
"@
        }
        default {
            `$report += "- Aucune recommandation spÃ©cifique disponible pour cette catÃ©gorie"
        }
    }
}

# Enregistrer le rapport
`$report | Set-Content -Path `$reportPath -Force

Write-Host "Rapport d'analyse gÃ©nÃ©rÃ©: `$reportPath"
"@
            
            Set-Content -Path $analyticsScriptPath -Value $analyticsScript -Force
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation du systÃ¨me de journalisation centralisÃ©: $_"
        return $false
    }
}

# Fonction pour ajouter une solution Ã  une erreur connue
function Add-ErrorSolution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorHash,
        
        [Parameter(Mandatory = $true)]
        [string]$Solution,
        
        [Parameter(Mandatory = $false)]
        [string]$Author = $env:USERNAME,
        
        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = "$script:ErrorLogPath\error_database.json"
    )
    
    try {
        # Charger la base de donnÃ©es d'erreurs
        $errorDatabase = @{}
        if (Test-Path -Path $DatabasePath) {
            $errorDatabase = Get-Content -Path $DatabasePath -Raw | ConvertFrom-Json -AsHashtable
        }
        
        # VÃ©rifier si l'erreur existe
        if (-not $errorDatabase.ContainsKey($ErrorHash)) {
            Write-Error "L'erreur spÃ©cifiÃ©e n'existe pas dans la base de donnÃ©es."
            return $false
        }
        
        # Ajouter la solution
        $solutionEntry = @{
            Solution = $Solution
            Author = $Author
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if (-not $errorDatabase[$ErrorHash].Solutions) {
            $errorDatabase[$ErrorHash].Solutions = @()
        }
        
        $errorDatabase[$ErrorHash].Solutions += $solutionEntry
        
        # Enregistrer la base de donnÃ©es
        $errorDatabase | ConvertTo-Json -Depth 5 | Set-Content -Path $DatabasePath -Force
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'ajout de la solution: $_"
        return $false
    }
}

# Exporter les fonctions du module
Export-ModuleMember -Function Initialize-ErrorHandling, Add-TryCatchBlock, Write-Log-Error, New-CentralizedLoggingSystem, Add-ErrorSolution
