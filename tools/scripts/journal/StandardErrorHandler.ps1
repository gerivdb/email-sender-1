<#
.SYNOPSIS
    Framework standardisÃ© pour la gestion des erreurs dans les scripts PowerShell.

.DESCRIPTION
    Ce script fournit un ensemble de fonctions pour gÃ©rer les erreurs de maniÃ¨re cohÃ©rente
    dans tous les scripts PowerShell. Il inclut des fonctionnalitÃ©s pour capturer, journaliser,
    catÃ©goriser et gÃ©rer les erreurs, ainsi que pour fournir des informations de dÃ©bogage.

.EXAMPLE
    . .\StandardErrorHandler.ps1
    try {
        # Code qui peut gÃ©nÃ©rer une erreur
        $result = 1 / 0
    }
    catch {
        $errorInfo = New-ErrorInfo -Exception $_ -Source "Division" -Category "MathError" -Severity "Error"
        Write-ErrorLog -ErrorInfo $errorInfo
        Show-ErrorDetails -ErrorInfo $errorInfo -Verbose
    }

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# DÃ©finir les niveaux de sÃ©vÃ©ritÃ© des erreurs
enum ErrorSeverity {
    Debug = 0
    Information = 1
    Warning = 2
    Error = 3
    Critical = 4
    Fatal = 5
}

# DÃ©finir les catÃ©gories d'erreurs
enum ErrorCategory {
    Uncategorized = 0
    Validation = 1
    Authentication = 2
    Authorization = 3
    ResourceAccess = 4
    Configuration = 5
    Syntax = 6
    Runtime = 7
    Network = 8
    Database = 9
    FileSystem = 10
    External = 11
    Timeout = 12
    Encoding = 13
    Compatibility = 14
    Security = 15
    Performance = 16
    Logic = 17
    MathError = 18
    MemoryError = 19
    API = 20
    Dependency = 21
    UserInput = 22
    SystemResource = 23
    Custom = 99
}

# Fonction pour crÃ©er un objet d'information d'erreur
function New-ErrorInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$Exception,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [ErrorCategory]$Category = [ErrorCategory]::Uncategorized,
        
        [Parameter(Mandatory = $false)]
        [ErrorSeverity]$Severity = [ErrorSeverity]::Error,
        
        [Parameter(Mandatory = $false)]
        [string]$AdditionalInfo = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$SuggestedAction = ""
    )
    
    # Extraire les informations de la pile d'appels
    $callStack = Get-PSCallStack | Select-Object -Skip 1
    $callerInfo = if ($callStack.Count -gt 0) {
        $caller = $callStack[0]
        "$($caller.Command) at line $($caller.ScriptLineNumber) in $($caller.ScriptName)"
    }
    else {
        "Unknown caller"
    }
    
    # CrÃ©er l'objet d'information d'erreur
    $errorInfo = [PSCustomObject]@{
        Timestamp = Get-Date
        ErrorId = [Guid]::NewGuid().ToString()
        Message = $Exception.Exception.Message
        ExceptionType = $Exception.Exception.GetType().FullName
        Source = $Source
        Category = $Category
        Severity = $Severity
        ScriptName = $callStack[0].ScriptName
        LineNumber = $callStack[0].ScriptLineNumber
        CallerInfo = $callerInfo
        StackTrace = $Exception.ScriptStackTrace
        AdditionalInfo = $AdditionalInfo
        Context = $Context
        SuggestedAction = $SuggestedAction
        FullException = $Exception
    }
    
    return $errorInfo
}

# Fonction pour Ã©crire les informations d'erreur dans un journal
function Write-ErrorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ErrorInfo,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$AppendToEventLog,
        
        [Parameter(Mandatory = $false)]
        [switch]$SendNotification
    )
    
    # DÃ©terminer le chemin du journal
    if ([string]::IsNullOrEmpty($LogPath)) {
        $LogPath = Join-Path -Path $env:TEMP -ChildPath "ErrorLog.json"
    }
    
    # CrÃ©er le dossier du journal si nÃ©cessaire
    $logDirectory = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDirectory -PathType Container)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Formater l'entrÃ©e de journal
    $logEntry = [PSCustomObject]@{
        Timestamp = $ErrorInfo.Timestamp
        ErrorId = $ErrorInfo.ErrorId
        Message = $ErrorInfo.Message
        ExceptionType = $ErrorInfo.ExceptionType
        Source = $ErrorInfo.Source
        Category = $ErrorInfo.Category.ToString()
        Severity = $ErrorInfo.Severity.ToString()
        ScriptName = $ErrorInfo.ScriptName
        LineNumber = $ErrorInfo.LineNumber
        CallerInfo = $ErrorInfo.CallerInfo
        AdditionalInfo = $ErrorInfo.AdditionalInfo
        SuggestedAction = $ErrorInfo.SuggestedAction
    }
    
    # Convertir l'entrÃ©e en JSON
    $jsonEntry = ConvertTo-Json -InputObject $logEntry -Depth 10
    
    # Ajouter l'entrÃ©e au fichier journal
    try {
        Add-Content -Path $LogPath -Value $jsonEntry -Encoding UTF8
        Write-Verbose "Erreur journalisÃ©e dans '$LogPath'"
    }
    catch {
        Write-Warning "Impossible d'Ã©crire dans le journal des erreurs: $_"
    }
    
    # Ã‰crire dans le journal des Ã©vÃ©nements Windows si demandÃ©
    if ($AppendToEventLog) {
        try {
            $eventLogMessage = "[$($ErrorInfo.Severity)] $($ErrorInfo.Category): $($ErrorInfo.Message)`nSource: $($ErrorInfo.Source)`nScript: $($ErrorInfo.ScriptName):$($ErrorInfo.LineNumber)`nID: $($ErrorInfo.ErrorId)"
            $eventLogEntryType = switch ($ErrorInfo.Severity) {
                ([ErrorSeverity]::Debug) { "Information" }
                ([ErrorSeverity]::Information) { "Information" }
                ([ErrorSeverity]::Warning) { "Warning" }
                ([ErrorSeverity]::Error) { "Error" }
                ([ErrorSeverity]::Critical) { "Error" }
                ([ErrorSeverity]::Fatal) { "Error" }
                default { "Information" }
            }
            
            Write-EventLog -LogName "Application" -Source "PowerShell" -EventId 1000 -EntryType $eventLogEntryType -Message $eventLogMessage -ErrorAction Stop
            Write-Verbose "Erreur Ã©crite dans le journal des Ã©vÃ©nements Windows"
        }
        catch {
            Write-Warning "Impossible d'Ã©crire dans le journal des Ã©vÃ©nements Windows: $_"
        }
    }
    
    # Envoyer une notification si demandÃ©
    if ($SendNotification) {
        try {
            # Cette fonction peut Ãªtre personnalisÃ©e pour envoyer des notifications par e-mail, SMS, etc.
            Send-ErrorNotification -ErrorInfo $ErrorInfo
        }
        catch {
            Write-Warning "Impossible d'envoyer la notification d'erreur: $_"
        }
    }
    
    return $logEntry
}

# Fonction pour envoyer des notifications d'erreur (Ã  personnaliser selon les besoins)
function Send-ErrorNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ErrorInfo
    )
    
    # Cette fonction est un placeholder qui peut Ãªtre personnalisÃ©e pour envoyer des notifications
    # par e-mail, SMS, webhook, etc.
    
    Write-Verbose "Notification d'erreur envoyÃ©e pour l'erreur ID: $($ErrorInfo.ErrorId)"
}

# Fonction pour afficher les dÃ©tails d'une erreur
function Show-ErrorDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ErrorInfo,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeStackTrace,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsJson
    )
    
    if ($AsJson) {
        return ConvertTo-Json -InputObject $ErrorInfo -Depth 10
    }
    
    # DÃ©terminer la couleur en fonction de la sÃ©vÃ©ritÃ©
    $severityColor = switch ($ErrorInfo.Severity) {
        ([ErrorSeverity]::Debug) { "Gray" }
        ([ErrorSeverity]::Information) { "White" }
        ([ErrorSeverity]::Warning) { "Yellow" }
        ([ErrorSeverity]::Error) { "Red" }
        ([ErrorSeverity]::Critical) { "Magenta" }
        ([ErrorSeverity]::Fatal) { "DarkRed" }
        default { "White" }
    }
    
    # Afficher les informations d'erreur
    Write-Host "=== DÃ©tails de l'erreur ===" -ForegroundColor $severityColor
    Write-Host "ID: $($ErrorInfo.ErrorId)" -ForegroundColor $severityColor
    Write-Host "Timestamp: $($ErrorInfo.Timestamp)" -ForegroundColor $severityColor
    Write-Host "SÃ©vÃ©ritÃ©: $($ErrorInfo.Severity)" -ForegroundColor $severityColor
    Write-Host "CatÃ©gorie: $($ErrorInfo.Category)" -ForegroundColor $severityColor
    Write-Host "Source: $($ErrorInfo.Source)" -ForegroundColor $severityColor
    Write-Host "Message: $($ErrorInfo.Message)" -ForegroundColor $severityColor
    Write-Host "Type d'exception: $($ErrorInfo.ExceptionType)" -ForegroundColor $severityColor
    Write-Host "Script: $($ErrorInfo.ScriptName):$($ErrorInfo.LineNumber)" -ForegroundColor $severityColor
    Write-Host "Appelant: $($ErrorInfo.CallerInfo)" -ForegroundColor $severityColor
    
    if (-not [string]::IsNullOrEmpty($ErrorInfo.AdditionalInfo)) {
        Write-Host "Informations supplÃ©mentaires: $($ErrorInfo.AdditionalInfo)" -ForegroundColor $severityColor
    }
    
    if (-not [string]::IsNullOrEmpty($ErrorInfo.SuggestedAction)) {
        Write-Host "Action suggÃ©rÃ©e: $($ErrorInfo.SuggestedAction)" -ForegroundColor "Cyan"
    }
    
    if ($IncludeStackTrace) {
        Write-Host "`nTrace de la pile:" -ForegroundColor $severityColor
        Write-Host $ErrorInfo.StackTrace -ForegroundColor $severityColor
    }
    
    if ($IncludeContext -and $ErrorInfo.Context.Count -gt 0) {
        Write-Host "`nContexte:" -ForegroundColor $severityColor
        foreach ($key in $ErrorInfo.Context.Keys) {
            Write-Host "  $key = $($ErrorInfo.Context[$key])" -ForegroundColor $severityColor
        }
    }
}

# Fonction pour analyser une erreur et suggÃ©rer des actions
function Get-ErrorAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ErrorInfo
    )
    
    $analysis = [PSCustomObject]@{
        ErrorId = $ErrorInfo.ErrorId
        PossibleCauses = @()
        SuggestedActions = @()
        References = @()
        Severity = $ErrorInfo.Severity
    }
    
    # Analyser l'erreur en fonction de son type et de sa catÃ©gorie
    switch ($ErrorInfo.ExceptionType) {
        "System.IO.FileNotFoundException" {
            $analysis.PossibleCauses += "Le fichier spÃ©cifiÃ© n'existe pas ou n'est pas accessible."
            $analysis.SuggestedActions += "VÃ©rifiez que le chemin du fichier est correct et que le fichier existe."
            $analysis.SuggestedActions += "VÃ©rifiez les permissions d'accÃ¨s au fichier."
            $analysis.References += "https://docs.microsoft.com/en-us/dotnet/api/system.io.filenotfoundexception"
        }
        "System.UnauthorizedAccessException" {
            $analysis.PossibleCauses += "AccÃ¨s refusÃ© au fichier ou Ã  la ressource."
            $analysis.SuggestedActions += "VÃ©rifiez les permissions d'accÃ¨s Ã  la ressource."
            $analysis.SuggestedActions += "ExÃ©cutez le script avec des privilÃ¨ges Ã©levÃ©s si nÃ©cessaire."
            $analysis.References += "https://docs.microsoft.com/en-us/dotnet/api/system.unauthorizedaccessexception"
        }
        "System.Net.WebException" {
            $analysis.PossibleCauses += "Erreur de connexion rÃ©seau ou de requÃªte HTTP."
            $analysis.SuggestedActions += "VÃ©rifiez la connectivitÃ© rÃ©seau."
            $analysis.SuggestedActions += "VÃ©rifiez que l'URL est correcte et accessible."
            $analysis.SuggestedActions += "VÃ©rifiez les paramÃ¨tres de proxy et les certificats SSL."
            $analysis.References += "https://docs.microsoft.com/en-us/dotnet/api/system.net.webexception"
        }
        "System.Management.Automation.CommandNotFoundException" {
            $analysis.PossibleCauses += "La commande ou le module PowerShell spÃ©cifiÃ© n'existe pas ou n'est pas chargÃ©."
            $analysis.SuggestedActions += "VÃ©rifiez que le module est installÃ© et importÃ©."
            $analysis.SuggestedActions += "VÃ©rifiez l'orthographe de la commande."
            $analysis.References += "https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview"
        }
        default {
            # Analyse basÃ©e sur la catÃ©gorie d'erreur
            switch ($ErrorInfo.Category) {
                ([ErrorCategory]::Encoding) {
                    $analysis.PossibleCauses += "ProblÃ¨me d'encodage de caractÃ¨res."
                    $analysis.SuggestedActions += "VÃ©rifiez l'encodage du fichier (UTF-8 avec BOM pour les scripts PowerShell)."
                    $analysis.SuggestedActions += "Utilisez les outils de normalisation d'encodage."
                }
                ([ErrorCategory]::Validation) {
                    $analysis.PossibleCauses += "Les donnÃ©es d'entrÃ©e ne respectent pas les critÃ¨res de validation."
                    $analysis.SuggestedActions += "VÃ©rifiez le format et la validitÃ© des donnÃ©es d'entrÃ©e."
                }
                ([ErrorCategory]::Configuration) {
                    $analysis.PossibleCauses += "Erreur dans la configuration de l'application ou du script."
                    $analysis.SuggestedActions += "VÃ©rifiez les fichiers de configuration et les paramÃ¨tres."
                }
                ([ErrorCategory]::Timeout) {
                    $analysis.PossibleCauses += "L'opÃ©ration a dÃ©passÃ© le dÃ©lai d'attente maximal."
                    $analysis.SuggestedActions += "Augmentez le dÃ©lai d'attente ou optimisez l'opÃ©ration."
                    $analysis.SuggestedActions += "VÃ©rifiez la disponibilitÃ© des ressources externes."
                }
                default {
                    $analysis.PossibleCauses += "Cause indÃ©terminÃ©e."
                    $analysis.SuggestedActions += "Examinez le message d'erreur et la trace de la pile pour plus d'informations."
                }
            }
        }
    }
    
    # Ajouter des suggestions gÃ©nÃ©riques si aucune suggestion spÃ©cifique n'a Ã©tÃ© trouvÃ©e
    if ($analysis.SuggestedActions.Count -eq 0) {
        $analysis.SuggestedActions += "Consultez la documentation pour plus d'informations sur cette erreur."
        $analysis.SuggestedActions += "Recherchez des solutions en ligne pour le message d'erreur spÃ©cifique."
    }
    
    return $analysis
}

# Fonction pour tester si une erreur correspond Ã  un modÃ¨le spÃ©cifique
function Test-ErrorPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ErrorInfo,
        
        [Parameter(Mandatory = $false)]
        [string]$MessagePattern = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ExceptionType = "",
        
        [Parameter(Mandatory = $false)]
        [ErrorCategory]$Category = [ErrorCategory]::Uncategorized,
        
        [Parameter(Mandatory = $false)]
        [string]$SourcePattern = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ScriptNamePattern = ""
    )
    
    $matchesPattern = $true
    
    # VÃ©rifier le modÃ¨le de message
    if (-not [string]::IsNullOrEmpty($MessagePattern)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.Message -match $MessagePattern)
    }
    
    # VÃ©rifier le type d'exception
    if (-not [string]::IsNullOrEmpty($ExceptionType)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.ExceptionType -match $ExceptionType)
    }
    
    # VÃ©rifier la catÃ©gorie
    if ($Category -ne [ErrorCategory]::Uncategorized) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.Category -eq $Category)
    }
    
    # VÃ©rifier le modÃ¨le de source
    if (-not [string]::IsNullOrEmpty($SourcePattern)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.Source -match $SourcePattern)
    }
    
    # VÃ©rifier le modÃ¨le de nom de script
    if (-not [string]::IsNullOrEmpty($ScriptNamePattern)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.ScriptName -match $ScriptNamePattern)
    }
    
    return $matchesPattern
}

# Fonction pour rÃ©cupÃ©rer les erreurs du journal
function Get-ErrorLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime,
        
        [Parameter(Mandatory = $false)]
        [ErrorSeverity]$MinimumSeverity = [ErrorSeverity]::Debug,
        
        [Parameter(Mandatory = $false)]
        [string]$SourcePattern = "",
        
        [Parameter(Mandatory = $false)]
        [string]$MessagePattern = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ScriptNamePattern = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0
    )
    
    # DÃ©terminer le chemin du journal
    if ([string]::IsNullOrEmpty($LogPath)) {
        $LogPath = Join-Path -Path $env:TEMP -ChildPath "ErrorLog.json"
    }
    
    # VÃ©rifier si le fichier journal existe
    if (-not (Test-Path -Path $LogPath -PathType Leaf)) {
        Write-Warning "Le fichier journal '$LogPath' n'existe pas."
        return @()
    }
    
    try {
        # Lire le fichier journal
        $logEntries = @()
        $jsonLines = Get-Content -Path $LogPath -Encoding UTF8
        
        foreach ($line in $jsonLines) {
            try {
                $entry = ConvertFrom-Json -InputObject $line
                $logEntries += $entry
            }
            catch {
                Write-Warning "Impossible de parser la ligne du journal: $line"
            }
        }
        
        # Filtrer les entrÃ©es
        $filteredEntries = $logEntries | Where-Object {
            $matchesFilter = $true
            
            # Filtrer par plage de temps
            if ($PSBoundParameters.ContainsKey('StartTime')) {
                $entryTime = [DateTime]::Parse($_.Timestamp)
                $matchesFilter = $matchesFilter -and ($entryTime -ge $StartTime)
            }
            
            if ($PSBoundParameters.ContainsKey('EndTime')) {
                $entryTime = [DateTime]::Parse($_.Timestamp)
                $matchesFilter = $matchesFilter -and ($entryTime -le $EndTime)
            }
            
            # Filtrer par sÃ©vÃ©ritÃ©
            $entrySeverity = [Enum]::Parse([ErrorSeverity], $_.Severity)
            $matchesFilter = $matchesFilter -and ($entrySeverity -ge $MinimumSeverity)
            
            # Filtrer par source
            if (-not [string]::IsNullOrEmpty($SourcePattern)) {
                $matchesFilter = $matchesFilter -and ($_.Source -match $SourcePattern)
            }
            
            # Filtrer par message
            if (-not [string]::IsNullOrEmpty($MessagePattern)) {
                $matchesFilter = $matchesFilter -and ($_.Message -match $MessagePattern)
            }
            
            # Filtrer par nom de script
            if (-not [string]::IsNullOrEmpty($ScriptNamePattern)) {
                $matchesFilter = $matchesFilter -and ($_.ScriptName -match $ScriptNamePattern)
            }
            
            return $matchesFilter
        }
        
        # Limiter le nombre de rÃ©sultats si demandÃ©
        if ($MaxResults -gt 0 -and $filteredEntries.Count -gt $MaxResults) {
            $filteredEntries = $filteredEntries | Select-Object -First $MaxResults
        }
        
        return $filteredEntries
    }
    catch {
        Write-Error "Erreur lors de la lecture du journal des erreurs: $_"
        return @()
    }
}

# Fonction pour obtenir des statistiques sur les erreurs
function Get-ErrorStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime,
        
        [Parameter(Mandatory = $false)]
        [switch]$GroupBySource,
        
        [Parameter(Mandatory = $false)]
        [switch]$GroupByCategory,
        
        [Parameter(Mandatory = $false)]
        [switch]$GroupBySeverity,
        
        [Parameter(Mandatory = $false)]
        [switch]$GroupByScript,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTimeline
    )
    
    # RÃ©cupÃ©rer les erreurs du journal
    $errors = Get-ErrorLogs -LogPath $LogPath -StartTime $StartTime -EndTime $EndTime
    
    if ($errors.Count -eq 0) {
        Write-Warning "Aucune erreur trouvÃ©e dans le journal."
        return $null
    }
    
    $statistics = [PSCustomObject]@{
        TotalErrors = $errors.Count
        TimeRange = if ($PSBoundParameters.ContainsKey('StartTime') -and $PSBoundParameters.ContainsKey('EndTime')) {
            "$StartTime - $EndTime"
        }
        elseif ($PSBoundParameters.ContainsKey('StartTime')) {
            "Depuis $StartTime"
        }
        elseif ($PSBoundParameters.ContainsKey('EndTime')) {
            "Jusqu'Ã  $EndTime"
        }
        else {
            "Toutes les erreurs"
        }
        MostCommonSources = @()
        MostCommonCategories = @()
        SeverityDistribution = @()
        MostCommonScripts = @()
        Timeline = @()
    }
    
    # Grouper par source
    if ($GroupBySource) {
        $sourceGroups = $errors | Group-Object -Property Source | Sort-Object -Property Count -Descending
        $statistics.MostCommonSources = $sourceGroups | Select-Object -Property Name, Count
    }
    
    # Grouper par catÃ©gorie
    if ($GroupByCategory) {
        $categoryGroups = $errors | Group-Object -Property Category | Sort-Object -Property Count -Descending
        $statistics.MostCommonCategories = $categoryGroups | Select-Object -Property Name, Count
    }
    
    # Grouper par sÃ©vÃ©ritÃ©
    if ($GroupBySeverity) {
        $severityGroups = $errors | Group-Object -Property Severity | Sort-Object -Property Name
        $statistics.SeverityDistribution = $severityGroups | Select-Object -Property Name, Count
    }
    
    # Grouper par script
    if ($GroupByScript) {
        $scriptGroups = $errors | Group-Object -Property ScriptName | Sort-Object -Property Count -Descending
        $statistics.MostCommonScripts = $scriptGroups | Select-Object -Property Name, Count
    }
    
    # CrÃ©er une timeline
    if ($IncludeTimeline) {
        # Convertir les timestamps en objets DateTime
        $errorsWithDateTime = $errors | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name DateTimeObj -Value ([DateTime]::Parse($_.Timestamp)) -PassThru
        }
        
        # Grouper par jour
        $dailyGroups = $errorsWithDateTime | Group-Object -Property { $_.DateTimeObj.Date } | Sort-Object -Property Name
        
        $statistics.Timeline = $dailyGroups | ForEach-Object {
            [PSCustomObject]@{
                Date = $_.Name
                Count = $_.Count
                Errors = $_.Group
            }
        }
    }
    
    return $statistics
}

# Exporter les fonctions
Export-ModuleMember -Function New-ErrorInfo, Write-ErrorLog, Show-ErrorDetails, Get-ErrorAnalysis, Test-ErrorPattern, Get-ErrorLogs, Get-ErrorStatistics
