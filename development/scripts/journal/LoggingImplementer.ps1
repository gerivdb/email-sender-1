<#
.SYNOPSIS
    ImplÃ©mente un systÃ¨me de journalisation centralisÃ© dans les scripts PowerShell.
.DESCRIPTION
    Ce script ajoute un systÃ¨me de journalisation centralisÃ© aux scripts PowerShell
    existants pour amÃ©liorer le suivi et le dÃ©bogage des erreurs.
.EXAMPLE
    . .\LoggingImplementer.ps1
    Add-LoggingToScript -Path "C:\path\to\script.ps1" -CreateBackup
#>

function Add-LoggingToScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Advanced", "Enterprise")]
        [string]$LoggingLevel = "Basic",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    process {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "Le fichier '$Path' n'existe pas."
            return $false
        }
        
        # DÃ©terminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $Path
        }
        
        # DÃ©terminer le chemin du fichier journal
        if ([string]::IsNullOrEmpty($LogFilePath)) {
            $scriptName = Split-Path -Path $Path -Leaf
            $LogFilePath = "`$env:TEMP\$scriptName.log"
        }
        
        # CrÃ©er une sauvegarde si demandÃ©
        if ($CreateBackup) {
            $backupPath = "$Path.bak"
            Copy-Item -Path $Path -Destination $backupPath -Force
            Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
        }
        
        # Lire le contenu du script
        $content = Get-Content -Path $Path -Raw
        
        # VÃ©rifier si le script a dÃ©jÃ  une fonction de journalisation
        if ($content -match 'function\s+(Write-Log|Log-Message|Add-Log)') {
            Write-Verbose "Le script a dÃ©jÃ  une fonction de journalisation."
            
            # Mettre Ã  jour la fonction existante si nÃ©cessaire
            # (Cette partie pourrait Ãªtre dÃ©veloppÃ©e davantage)
            
            return $true
        }
        
        # CrÃ©er la fonction de journalisation en fonction du niveau demandÃ©
        $loggingFunction = switch ($LoggingLevel) {
            "Basic" {
                @"

# Fonction de journalisation basique
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, Position = 0)]
        [string]`$Message,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]`$Level = "INFO",
        
        [Parameter(Mandatory = `$false)]
        [string]`$LogFilePath = "$LogFilePath"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logEntry = "``[`$timestamp``] [`$Level] `$Message"
    
    # Afficher dans la console
    switch (`$Level) {
        "INFO" { Write-Host `$logEntry -ForegroundColor White }
        "WARNING" { Write-Host `$logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host `$logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose `$logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        Add-Content -Path `$LogFilePath -Value `$logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}

"@
            }
            "Advanced" {
                @"

# Fonction de journalisation avancÃ©e
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, Position = 0)]
        [string]`$Message,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "VERBOSE")]
        [string]`$Level = "INFO",
        
        [Parameter(Mandatory = `$false)]
        [string]`$LogFilePath = "$LogFilePath",
        
        [Parameter(Mandatory = `$false)]
        [int]`$MaxLogSizeKB = 1024,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$NoConsole,
        
        [Parameter(Mandatory = `$false)]
        [string]`$Source = "",
        
        [Parameter(Mandatory = `$false)]
        [System.Management.Automation.ErrorRecord]`$ErrorRecord
    )
    
    # Obtenir des informations sur l'appelant
    if ([string]::IsNullOrEmpty(`$Source)) {
        `$callStack = Get-PSCallStack | Select-Object -Skip 1 -First 1
        `$Source = if (`$callStack) {
            "`$(`$callStack.Command)::`$(`$callStack.ScriptLineNumber)"
        }
        else {
            "Unknown"
        }
    }
    
    # Formater le message
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    `$logEntry = "``[`$timestamp``] [`$Level] [`$Source] `$Message"
    
    # Ajouter les dÃ©tails de l'erreur si fournis
    if (`$ErrorRecord) {
        `$logEntry += "``nException: `$(`$ErrorRecord.Exception.GetType().FullName)"
        `$logEntry += "``nMessage: `$(`$ErrorRecord.Exception.Message)"
        `$logEntry += "``nStack Trace: `$(`$ErrorRecord.ScriptStackTrace)"
    }
    
    # Afficher dans la console si demandÃ©
    if (-not `$NoConsole) {
        switch (`$Level) {
            "INFO" { Write-Host `$logEntry -ForegroundColor White }
            "WARNING" { Write-Host `$logEntry -ForegroundColor Yellow }
            "ERROR" { Write-Host `$logEntry -ForegroundColor Red }
            "DEBUG" { Write-Debug `$logEntry }
            "VERBOSE" { Write-Verbose `$logEntry }
        }
    }
    
    # VÃ©rifier et faire pivoter le fichier journal si nÃ©cessaire
    try {
        if (Test-Path -Path `$LogFilePath) {
            `$logFile = Get-Item -Path `$LogFilePath
            if (`$logFile.Length / 1KB -gt `$MaxLogSizeKB) {
                `$backupPath = "`$LogFilePath.bak"
                if (Test-Path -Path `$backupPath) {
                    Remove-Item -Path `$backupPath -Force
                }
                Rename-Item -Path `$LogFilePath -NewName `$backupPath
            }
        }
        
        # CrÃ©er le dossier du journal si nÃ©cessaire
        `$logDir = Split-Path -Path `$LogFilePath -Parent
        if (-not [string]::IsNullOrEmpty(`$logDir) -and -not (Test-Path -Path `$logDir)) {
            New-Item -Path `$logDir -ItemType Directory -Force | Out-Null
        }
        
        # Ã‰crire dans le fichier journal
        Add-Content -Path `$LogFilePath -Value `$logEntry
    }
    catch {
        Write-Warning "Impossible d'Ã©crire dans le fichier journal: `$_"
    }
}

# Fonctions d'aide pour la journalisation
function Write-LogInfo { param([string]`$Message) Write-Log -Message `$Message -Level "INFO" }
function Write-LogWarning { param([string]`$Message) Write-Log -Message `$Message -Level "WARNING" }
function Write-LogError { param([string]`$Message, [System.Management.Automation.ErrorRecord]`$ErrorRecord) Write-Log -Message `$Message -Level "ERROR" -ErrorRecord `$ErrorRecord }
function Write-LogDebug { param([string]`$Message) Write-Log -Message `$Message -Level "DEBUG" }
function Write-LogVerbose { param([string]`$Message) Write-Log -Message `$Message -Level "VERBOSE" }

"@
            }
            "Enterprise" {
                @"

# SystÃ¨me de journalisation d'entreprise
`$script:LoggerConfig = @{
    LogFilePath = "$LogFilePath"
    MaxLogSizeKB = 5120
    MaxLogFiles = 5
    MinLevel = "INFO"
    EnableConsole = `$true
    EnableFile = `$true
    EnableEventLog = `$false
    EventLogSource = "PowerShellScripts"
    EventLogName = "Application"
}

function Initialize-Logger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$false)]
        [string]`$LogFilePath,
        
        [Parameter(Mandatory = `$false)]
        [int]`$MaxLogSizeKB,
        
        [Parameter(Mandatory = `$false)]
        [int]`$MaxLogFiles,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("DEBUG", "VERBOSE", "INFO", "WARNING", "ERROR")]
        [string]`$MinLevel,
        
        [Parameter(Mandatory = `$false)]
        [bool]`$EnableConsole,
        
        [Parameter(Mandatory = `$false)]
        [bool]`$EnableFile,
        
        [Parameter(Mandatory = `$false)]
        [bool]`$EnableEventLog,
        
        [Parameter(Mandatory = `$false)]
        [string]`$EventLogSource,
        
        [Parameter(Mandatory = `$false)]
        [string]`$EventLogName
    )
    
    # Mettre Ã  jour la configuration
    if (`$PSBoundParameters.ContainsKey('LogFilePath')) { `$script:LoggerConfig.LogFilePath = `$LogFilePath }
    if (`$PSBoundParameters.ContainsKey('MaxLogSizeKB')) { `$script:LoggerConfig.MaxLogSizeKB = `$MaxLogSizeKB }
    if (`$PSBoundParameters.ContainsKey('MaxLogFiles')) { `$script:LoggerConfig.MaxLogFiles = `$MaxLogFiles }
    if (`$PSBoundParameters.ContainsKey('MinLevel')) { `$script:LoggerConfig.MinLevel = `$MinLevel }
    if (`$PSBoundParameters.ContainsKey('EnableConsole')) { `$script:LoggerConfig.EnableConsole = `$EnableConsole }
    if (`$PSBoundParameters.ContainsKey('EnableFile')) { `$script:LoggerConfig.EnableFile = `$EnableFile }
    if (`$PSBoundParameters.ContainsKey('EnableEventLog')) { `$script:LoggerConfig.EnableEventLog = `$EnableEventLog }
    if (`$PSBoundParameters.ContainsKey('EventLogSource')) { `$script:LoggerConfig.EventLogSource = `$EventLogSource }
    if (`$PSBoundParameters.ContainsKey('EventLogName')) { `$script:LoggerConfig.EventLogName = `$EventLogName }
    
    # Initialiser le journal des Ã©vÃ©nements si nÃ©cessaire
    if (`$script:LoggerConfig.EnableEventLog) {
        try {
            if (-not [System.Diagnostics.EventLog]::SourceExists(`$script:LoggerConfig.EventLogSource)) {
                [System.Diagnostics.EventLog]::CreateEventSource(`$script:LoggerConfig.EventLogSource, `$script:LoggerConfig.EventLogName)
            }
        }
        catch {
            Write-Warning "Impossible d'initialiser le journal des Ã©vÃ©nements: `$_"
            `$script:LoggerConfig.EnableEventLog = `$false
        }
    }
    
    # CrÃ©er le dossier du journal si nÃ©cessaire
    if (`$script:LoggerConfig.EnableFile) {
        try {
            `$logDir = Split-Path -Path `$script:LoggerConfig.LogFilePath -Parent
            if (-not [string]::IsNullOrEmpty(`$logDir) -and -not (Test-Path -Path `$logDir)) {
                New-Item -Path `$logDir -ItemType Directory -Force | Out-Null
            }
        }
        catch {
            Write-Warning "Impossible de crÃ©er le dossier du journal: `$_"
        }
    }
    
    # Journaliser l'initialisation
    Write-Log -Message "Logger initialisÃ© avec le niveau minimum: `$(`$script:LoggerConfig.MinLevel)" -Level "INFO"
}

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, Position = 0)]
        [string]`$Message,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("DEBUG", "VERBOSE", "INFO", "WARNING", "ERROR")]
        [string]`$Level = "INFO",
        
        [Parameter(Mandatory = `$false)]
        [string]`$Source = "",
        
        [Parameter(Mandatory = `$false)]
        [System.Management.Automation.ErrorRecord]`$ErrorRecord,
        
        [Parameter(Mandatory = `$false)]
        [int]`$EventId = 0
    )
    
    # VÃ©rifier le niveau minimum
    `$levelValues = @{
        "DEBUG" = 0
        "VERBOSE" = 1
        "INFO" = 2
        "WARNING" = 3
        "ERROR" = 4
    }
    
    if (`$levelValues[`$Level] -lt `$levelValues[`$script:LoggerConfig.MinLevel]) {
        return
    }
    
    # Obtenir des informations sur l'appelant
    if ([string]::IsNullOrEmpty(`$Source)) {
        `$callStack = Get-PSCallStack | Select-Object -Skip 1 -First 1
        `$Source = if (`$callStack) {
            "`$(`$callStack.Command)::`$(`$callStack.ScriptLineNumber)"
        }
        else {
            "Unknown"
        }
    }
    
    # Formater le message
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    `$logEntry = "``[`$timestamp``] [`$Level] [`$Source] `$Message"
    
    # Ajouter les dÃ©tails de l'erreur si fournis
    if (`$ErrorRecord) {
        `$logEntry += "``nException: `$(`$ErrorRecord.Exception.GetType().FullName)"
        `$logEntry += "``nMessage: `$(`$ErrorRecord.Exception.Message)"
        `$logEntry += "``nStack Trace: `$(`$ErrorRecord.ScriptStackTrace)"
    }
    
    # Journaliser dans la console
    if (`$script:LoggerConfig.EnableConsole) {
        switch (`$Level) {
            "DEBUG" { Write-Debug `$logEntry }
            "VERBOSE" { Write-Verbose `$logEntry }
            "INFO" { Write-Host `$logEntry -ForegroundColor White }
            "WARNING" { Write-Host `$logEntry -ForegroundColor Yellow }
            "ERROR" { Write-Host `$logEntry -ForegroundColor Red }
        }
    }
    
    # Journaliser dans le fichier
    if (`$script:LoggerConfig.EnableFile) {
        try {
            # VÃ©rifier et faire pivoter le fichier journal si nÃ©cessaire
            if (Test-Path -Path `$script:LoggerConfig.LogFilePath) {
                `$logFile = Get-Item -Path `$script:LoggerConfig.LogFilePath
                if (`$logFile.Length / 1KB -gt `$script:LoggerConfig.MaxLogSizeKB) {
                    # Faire pivoter les fichiers journaux
                    for (`$i = `$script:LoggerConfig.MaxLogFiles - 1; `$i -ge 1; `$i--) {
                        `$oldPath = "`$(`$script:LoggerConfig.LogFilePath).`$i"
                        `$newPath = "`$(`$script:LoggerConfig.LogFilePath).`$(`$i + 1)"
                        
                        if (Test-Path -Path `$oldPath) {
                            if (Test-Path -Path `$newPath) {
                                Remove-Item -Path `$newPath -Force
                            }
                            Rename-Item -Path `$oldPath -NewName `$newPath
                        }
                    }
                    
                    # Renommer le fichier journal actuel
                    `$backupPath = "`$(`$script:LoggerConfig.LogFilePath).1"
                    if (Test-Path -Path `$backupPath) {
                        Remove-Item -Path `$backupPath -Force
                    }
                    Rename-Item -Path `$script:LoggerConfig.LogFilePath -NewName `$backupPath
                }
            }
            
            # Ã‰crire dans le fichier journal
            Add-Content -Path `$script:LoggerConfig.LogFilePath -Value `$logEntry
        }
        catch {
            Write-Warning "Impossible d'Ã©crire dans le fichier journal: `$_"
        }
    }
    
    # Journaliser dans le journal des Ã©vÃ©nements
    if (`$script:LoggerConfig.EnableEventLog) {
        try {
            `$eventType = switch (`$Level) {
                "DEBUG" { "Information" }
                "VERBOSE" { "Information" }
                "INFO" { "Information" }
                "WARNING" { "Warning" }
                "ERROR" { "Error" }
                default { "Information" }
            }
            
            `$eventIdToUse = if (`$EventId -eq 0) {
                switch (`$Level) {
                    "DEBUG" { 100 }
                    "VERBOSE" { 200 }
                    "INFO" { 300 }
                    "WARNING" { 400 }
                    "ERROR" { 500 }
                    default { 900 }
                }
            }
            else {
                `$EventId
            }
            
            Write-EventLog -LogName `$script:LoggerConfig.EventLogName -Source `$script:LoggerConfig.EventLogSource -EventId `$eventIdToUse -EntryType `$eventType -Message `$logEntry
        }
        catch {
            Write-Warning "Impossible d'Ã©crire dans le journal des Ã©vÃ©nements: `$_"
        }
    }
}

# Fonctions d'aide pour la journalisation
function Write-LogDebug { param([string]`$Message, [string]`$Source = "") Write-Log -Message `$Message -Level "DEBUG" -Source `$Source }
function Write-LogVerbose { param([string]`$Message, [string]`$Source = "") Write-Log -Message `$Message -Level "VERBOSE" -Source `$Source }
function Write-LogInfo { param([string]`$Message, [string]`$Source = "") Write-Log -Message `$Message -Level "INFO" -Source `$Source }
function Write-LogWarning { param([string]`$Message, [string]`$Source = "") Write-Log -Message `$Message -Level "WARNING" -Source `$Source }
function Write-LogError { param([string]`$Message, [System.Management.Automation.ErrorRecord]`$ErrorRecord, [string]`$Source = "") Write-Log -Message `$Message -Level "ERROR" -ErrorRecord `$ErrorRecord -Source `$Source }

# Initialiser le logger
Initialize-Logger

"@
            }
        }
        
        # Extraire les commentaires et les dÃ©clarations param au dÃ©but du script
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
        
        # Construire le nouveau contenu
        $newContent = @"
$header
$param

# Configuration de la gestion d'erreurs
`$ErrorActionPreference = 'Stop'
`$Error.Clear()
$loggingFunction
# DÃ©but du script original
$content
"@
        
        # Ajouter des appels de journalisation aux endroits clÃ©s
        $newContent = $newContent -replace '(?m)^(\s*)Write-Error\s+([''"])(.+?)([''"])', '$1Write-LogError $2$3$4'
        $newContent = $newContent -replace '(?m)^(\s*)Write-Warning\s+([''"])(.+?)([''"])', '$1Write-LogWarning $2$3$4'
        $newContent = $newContent -replace '(?m)^(\s*)Write-Verbose\s+([''"])(.+?)([''"])', '$1Write-LogVerbose $2$3$4'
        $newContent = $newContent -replace '(?m)^(\s*)Write-Debug\s+([''"])(.+?)([''"])', '$1Write-LogDebug $2$3$4'
        
        # Ajouter des appels de journalisation dans les blocs catch
        $newContent = $newContent -replace '(?m)catch\s*{(\s*?)(?!\s*Write-Log)', 'catch {$1Write-LogError "Une erreur s''est produite" $_$1'
        
        # Appliquer les modifications si ce n'est pas un test
        if (-not $WhatIf) {
            Set-Content -Path $OutputPath -Value $newContent
            Write-Verbose "SystÃ¨me de journalisation ajoutÃ© au script."
            return $true
        }
        else {
            # Afficher les modifications prÃ©vues
            Write-Host "Modifications prÃ©vues pour le script '$Path':"
            Write-Host "- Ajout d'un systÃ¨me de journalisation de niveau '$LoggingLevel'"
            Write-Host "- Configuration de ErrorActionPreference Ã  'Stop'"
            Write-Host "- Remplacement des appels Write-Error par Write-LogError"
            Write-Host "- Remplacement des appels Write-Warning par Write-LogWarning"
            Write-Host "- Ajout de journalisation dans les blocs catch"
            
            return $true
        }
    }
}

function Add-LoggingToDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.ps1",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Advanced", "Enterprise")]
        [string]$LoggingLevel = "Basic",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Le rÃ©pertoire '$Path' n'existe pas."
        return $null
    }
    
    # Obtenir la liste des fichiers Ã  traiter
    $files = Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse
    
    $results = @{
        TotalFiles = $files.Count
        ModifiedFiles = 0
        SkippedFiles = 0
        FailedFiles = 0
        Details = @()
    }
    
    foreach ($file in $files) {
        Write-Verbose "Traitement du fichier: $($file.FullName)"
        
        try {
            # DÃ©terminer le chemin du fichier journal
            $scriptLogFilePath = if ([string]::IsNullOrEmpty($LogFilePath)) {
                "`$env:TEMP\$($file.Name).log"
            }
            else {
                $LogFilePath
            }
            
            # Ajouter la journalisation
            $success = Add-LoggingToScript -Path $file.FullName -CreateBackup:$CreateBackup -LoggingLevel $LoggingLevel -LogFilePath $scriptLogFilePath -WhatIf:$WhatIf
            
            if ($success -and -not $WhatIf) {
                $results.ModifiedFiles++
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "Modified"
                    LoggingLevel = $LoggingLevel
                }
            }
            elseif ($WhatIf) {
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "WhatIf"
                    LoggingLevel = $LoggingLevel
                }
            }
            else {
                $results.SkippedFiles++
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "Skipped"
                    Reason = "Le script a dÃ©jÃ  une fonction de journalisation"
                }
            }
        }
        catch {
            $results.FailedFiles++
            $results.Details += [PSCustomObject]@{
                FilePath = $file.FullName
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
    }
    
    return [PSCustomObject]$results
}

# Exporter les fonctions
Export-ModuleMember -Function Add-LoggingToScript, Add-LoggingToDirectory
