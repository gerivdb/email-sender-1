<#
.SYNOPSIS
    Framework standardisé pour la gestion des erreurs dans les scripts PowerShell.

.DESCRIPTION
    Ce script fournit un ensemble de fonctions pour gérer les erreurs de manière cohérente
    dans tous les scripts PowerShell. Il inclut des fonctionnalités pour capturer, journaliser,
    catégoriser et gérer les erreurs, ainsi que pour fournir des informations de débogage.

.EXAMPLE
    . .\StandardErrorHandler.ps1
    try {
        # Code qui peut générer une erreur
        $result = 1 / 0
    }
    catch {
        $errorInfo = New-ErrorInfo -Exception $_ -Source "Division" -Category "MathError" -Severity "Error"
        Write-ErrorLog -ErrorInfo $errorInfo
        Show-ErrorDetails -ErrorInfo $errorInfo -Verbose
    }

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
    Version: 1.0
#>

# Définir les niveaux de sévérité des erreurs
enum ErrorSeverity {
    Debug = 0
    Information = 1
    Warning = 2
    Error = 3
    Critical = 4
    Fatal = 5
}

# Définir les catégories d'erreurs
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

# Fonction pour créer un objet d'information d'erreur
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
    
    # Créer l'objet d'information d'erreur
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

# Fonction pour écrire les informations d'erreur dans un journal
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
    
    # Déterminer le chemin du journal
    if ([string]::IsNullOrEmpty($LogPath)) {
        $LogPath = Join-Path -Path $env:TEMP -ChildPath "ErrorLog.json"
    }
    
    # Créer le dossier du journal si nécessaire
    $logDirectory = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDirectory -PathType Container)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Formater l'entrée de journal
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
    
    # Convertir l'entrée en JSON
    $jsonEntry = ConvertTo-Json -InputObject $logEntry -Depth 10
    
    # Ajouter l'entrée au fichier journal
    try {
        Add-Content -Path $LogPath -Value $jsonEntry -Encoding UTF8
        Write-Verbose "Erreur journalisée dans '$LogPath'"
    }
    catch {
        Write-Warning "Impossible d'écrire dans le journal des erreurs: $_"
    }
    
    # Écrire dans le journal des événements Windows si demandé
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
            Write-Verbose "Erreur écrite dans le journal des événements Windows"
        }
        catch {
            Write-Warning "Impossible d'écrire dans le journal des événements Windows: $_"
        }
    }
    
    # Envoyer une notification si demandé
    if ($SendNotification) {
        try {
            # Cette fonction peut être personnalisée pour envoyer des notifications par e-mail, SMS, etc.
            Send-ErrorNotification -ErrorInfo $ErrorInfo
        }
        catch {
            Write-Warning "Impossible d'envoyer la notification d'erreur: $_"
        }
    }
    
    return $logEntry
}

# Fonction pour envoyer des notifications d'erreur (à personnaliser selon les besoins)
function Send-ErrorNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ErrorInfo
    )
    
    # Cette fonction est un placeholder qui peut être personnalisée pour envoyer des notifications
    # par e-mail, SMS, webhook, etc.
    
    Write-Verbose "Notification d'erreur envoyée pour l'erreur ID: $($ErrorInfo.ErrorId)"
}

# Fonction pour afficher les détails d'une erreur
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
    
    # Déterminer la couleur en fonction de la sévérité
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
    Write-Host "=== Détails de l'erreur ===" -ForegroundColor $severityColor
    Write-Host "ID: $($ErrorInfo.ErrorId)" -ForegroundColor $severityColor
    Write-Host "Timestamp: $($ErrorInfo.Timestamp)" -ForegroundColor $severityColor
    Write-Host "Sévérité: $($ErrorInfo.Severity)" -ForegroundColor $severityColor
    Write-Host "Catégorie: $($ErrorInfo.Category)" -ForegroundColor $severityColor
    Write-Host "Source: $($ErrorInfo.Source)" -ForegroundColor $severityColor
    Write-Host "Message: $($ErrorInfo.Message)" -ForegroundColor $severityColor
    Write-Host "Type d'exception: $($ErrorInfo.ExceptionType)" -ForegroundColor $severityColor
    Write-Host "Script: $($ErrorInfo.ScriptName):$($ErrorInfo.LineNumber)" -ForegroundColor $severityColor
    Write-Host "Appelant: $($ErrorInfo.CallerInfo)" -ForegroundColor $severityColor
    
    if (-not [string]::IsNullOrEmpty($ErrorInfo.AdditionalInfo)) {
        Write-Host "Informations supplémentaires: $($ErrorInfo.AdditionalInfo)" -ForegroundColor $severityColor
    }
    
    if (-not [string]::IsNullOrEmpty($ErrorInfo.SuggestedAction)) {
        Write-Host "Action suggérée: $($ErrorInfo.SuggestedAction)" -ForegroundColor "Cyan"
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

# Fonction pour analyser une erreur et suggérer des actions
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
    
    # Analyser l'erreur en fonction de son type et de sa catégorie
    switch ($ErrorInfo.ExceptionType) {
        "System.IO.FileNotFoundException" {
            $analysis.PossibleCauses += "Le fichier spécifié n'existe pas ou n'est pas accessible."
            $analysis.SuggestedActions += "Vérifiez que le chemin du fichier est correct et que le fichier existe."
            $analysis.SuggestedActions += "Vérifiez les permissions d'accès au fichier."
            $analysis.References += "https://docs.microsoft.com/en-us/dotnet/api/system.io.filenotfoundexception"
        }
        "System.UnauthorizedAccessException" {
            $analysis.PossibleCauses += "Accès refusé au fichier ou à la ressource."
            $analysis.SuggestedActions += "Vérifiez les permissions d'accès à la ressource."
            $analysis.SuggestedActions += "Exécutez le script avec des privilèges élevés si nécessaire."
            $analysis.References += "https://docs.microsoft.com/en-us/dotnet/api/system.unauthorizedaccessexception"
        }
        "System.Net.WebException" {
            $analysis.PossibleCauses += "Erreur de connexion réseau ou de requête HTTP."
            $analysis.SuggestedActions += "Vérifiez la connectivité réseau."
            $analysis.SuggestedActions += "Vérifiez que l'URL est correcte et accessible."
            $analysis.SuggestedActions += "Vérifiez les paramètres de proxy et les certificats SSL."
            $analysis.References += "https://docs.microsoft.com/en-us/dotnet/api/system.net.webexception"
        }
        "System.Management.Automation.CommandNotFoundException" {
            $analysis.PossibleCauses += "La commande ou le module PowerShell spécifié n'existe pas ou n'est pas chargé."
            $analysis.SuggestedActions += "Vérifiez que le module est installé et importé."
            $analysis.SuggestedActions += "Vérifiez l'orthographe de la commande."
            $analysis.References += "https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview"
        }
        default {
            # Analyse basée sur la catégorie d'erreur
            switch ($ErrorInfo.Category) {
                ([ErrorCategory]::Encoding) {
                    $analysis.PossibleCauses += "Problème d'encodage de caractères."
                    $analysis.SuggestedActions += "Vérifiez l'encodage du fichier (UTF-8 avec BOM pour les scripts PowerShell)."
                    $analysis.SuggestedActions += "Utilisez les outils de normalisation d'encodage."
                }
                ([ErrorCategory]::Validation) {
                    $analysis.PossibleCauses += "Les données d'entrée ne respectent pas les critères de validation."
                    $analysis.SuggestedActions += "Vérifiez le format et la validité des données d'entrée."
                }
                ([ErrorCategory]::Configuration) {
                    $analysis.PossibleCauses += "Erreur dans la configuration de l'application ou du script."
                    $analysis.SuggestedActions += "Vérifiez les fichiers de configuration et les paramètres."
                }
                ([ErrorCategory]::Timeout) {
                    $analysis.PossibleCauses += "L'opération a dépassé le délai d'attente maximal."
                    $analysis.SuggestedActions += "Augmentez le délai d'attente ou optimisez l'opération."
                    $analysis.SuggestedActions += "Vérifiez la disponibilité des ressources externes."
                }
                default {
                    $analysis.PossibleCauses += "Cause indéterminée."
                    $analysis.SuggestedActions += "Examinez le message d'erreur et la trace de la pile pour plus d'informations."
                }
            }
        }
    }
    
    # Ajouter des suggestions génériques si aucune suggestion spécifique n'a été trouvée
    if ($analysis.SuggestedActions.Count -eq 0) {
        $analysis.SuggestedActions += "Consultez la documentation pour plus d'informations sur cette erreur."
        $analysis.SuggestedActions += "Recherchez des solutions en ligne pour le message d'erreur spécifique."
    }
    
    return $analysis
}

# Fonction pour tester si une erreur correspond à un modèle spécifique
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
    
    # Vérifier le modèle de message
    if (-not [string]::IsNullOrEmpty($MessagePattern)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.Message -match $MessagePattern)
    }
    
    # Vérifier le type d'exception
    if (-not [string]::IsNullOrEmpty($ExceptionType)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.ExceptionType -match $ExceptionType)
    }
    
    # Vérifier la catégorie
    if ($Category -ne [ErrorCategory]::Uncategorized) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.Category -eq $Category)
    }
    
    # Vérifier le modèle de source
    if (-not [string]::IsNullOrEmpty($SourcePattern)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.Source -match $SourcePattern)
    }
    
    # Vérifier le modèle de nom de script
    if (-not [string]::IsNullOrEmpty($ScriptNamePattern)) {
        $matchesPattern = $matchesPattern -and ($ErrorInfo.ScriptName -match $ScriptNamePattern)
    }
    
    return $matchesPattern
}

# Fonction pour récupérer les erreurs du journal
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
    
    # Déterminer le chemin du journal
    if ([string]::IsNullOrEmpty($LogPath)) {
        $LogPath = Join-Path -Path $env:TEMP -ChildPath "ErrorLog.json"
    }
    
    # Vérifier si le fichier journal existe
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
        
        # Filtrer les entrées
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
            
            # Filtrer par sévérité
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
        
        # Limiter le nombre de résultats si demandé
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
    
    # Récupérer les erreurs du journal
    $errors = Get-ErrorLogs -LogPath $LogPath -StartTime $StartTime -EndTime $EndTime
    
    if ($errors.Count -eq 0) {
        Write-Warning "Aucune erreur trouvée dans le journal."
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
            "Jusqu'à $EndTime"
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
    
    # Grouper par catégorie
    if ($GroupByCategory) {
        $categoryGroups = $errors | Group-Object -Property Category | Sort-Object -Property Count -Descending
        $statistics.MostCommonCategories = $categoryGroups | Select-Object -Property Name, Count
    }
    
    # Grouper par sévérité
    if ($GroupBySeverity) {
        $severityGroups = $errors | Group-Object -Property Severity | Sort-Object -Property Name
        $statistics.SeverityDistribution = $severityGroups | Select-Object -Property Name, Count
    }
    
    # Grouper par script
    if ($GroupByScript) {
        $scriptGroups = $errors | Group-Object -Property ScriptName | Sort-Object -Property Count -Descending
        $statistics.MostCommonScripts = $scriptGroups | Select-Object -Property Name, Count
    }
    
    # Créer une timeline
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
