<#
.SYNOPSIS
    Module principal du système d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour collecter, analyser et apprendre des erreurs PowerShell.
#>

# Variables globales
$script:ErrorDatabase = @{}
$script:ErrorDatabasePath = Join-Path -Path $PSScriptRoot -ChildPath "data\error-database.json"
$script:ErrorLogsPath = Join-Path -Path $PSScriptRoot -ChildPath "logs"
$script:ErrorPatternsPath = Join-Path -Path $PSScriptRoot -ChildPath "patterns"
$script:IsInitialized = $false

# Fonction d'initialisation
function Initialize-ErrorLearningSystem {
    [CmdletBinding()]
    param (
        [switch]$Force
    )

    if ($script:IsInitialized -and -not $Force) {
        Write-Verbose "Le système d'apprentissage des erreurs est déjà initialisé."
        return
    }

    # Créer les dossiers nécessaires
    $folders = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "data"),
        $script:ErrorLogsPath,
        $script:ErrorPatternsPath
    )

    foreach ($folder in $folders) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            Write-Verbose "Dossier créé : $folder"
        }
    }

    # Charger la base de données des erreurs
    if (Test-Path -Path $script:ErrorDatabasePath) {
        try {
            $script:ErrorDatabase = Get-Content -Path $script:ErrorDatabasePath -Raw | ConvertFrom-Json -AsHashtable
            Write-Verbose "Base de données des erreurs chargée."
        }
        catch {
            Write-Warning "Impossible de charger la base de données des erreurs : $_"
            $script:ErrorDatabase = @{}
        }
    }
    else {
        $script:ErrorDatabase = @{
            Errors = @()
            Patterns = @()
            Statistics = @{
                TotalErrors = 0
                CategorizedErrors = @{}
                LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }

        # Sauvegarder la base de données vide
        $script:ErrorDatabase | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ErrorDatabasePath -Force
        Write-Verbose "Nouvelle base de données des erreurs créée."
    }

    $script:IsInitialized = $true
    Write-Verbose "Système d'apprentissage des erreurs initialisé."
}

# Fonction pour enregistrer une erreur
function Register-PowerShellError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$Source = "Unknown",

        [Parameter(Mandatory = $false)]
        [string]$Category = "Uncategorized",

        [Parameter(Mandatory = $false)]
        [string]$Solution = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalInfo = @{}
    )

    # Vérifier si le système est initialisé
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }

    # Créer un objet d'erreur
    $errorObject = @{
        Id = [guid]::NewGuid().ToString()
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Source = $Source
        Category = $Category
        ErrorMessage = $ErrorRecord.Exception.Message
        ErrorType = $ErrorRecord.Exception.GetType().FullName
        ScriptStackTrace = $ErrorRecord.ScriptStackTrace
        PositionMessage = $ErrorRecord.InvocationInfo.PositionMessage
        Line = $ErrorRecord.InvocationInfo.Line
        Solution = $Solution
        AdditionalInfo = $AdditionalInfo
    }

    # Ajouter l'erreur à la base de données
    $script:ErrorDatabase.Errors += $errorObject
    $script:ErrorDatabase.Statistics.TotalErrors++

    # Mettre à jour les statistiques par catégorie
    if (-not $script:ErrorDatabase.Statistics.CategorizedErrors.ContainsKey($Category)) {
        $script:ErrorDatabase.Statistics.CategorizedErrors[$Category] = 0
    }
    $script:ErrorDatabase.Statistics.CategorizedErrors[$Category]++

    # Mettre à jour la date de dernière mise à jour
    $script:ErrorDatabase.Statistics.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Sauvegarder la base de données
    $script:ErrorDatabase | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ErrorDatabasePath -Force

    # Journaliser l'erreur
    $logFileName = "error-log-$(Get-Date -Format 'yyyy-MM-dd').json"
    $logFilePath = Join-Path -Path $script:ErrorLogsPath -ChildPath $logFileName

    $errorObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFilePath -Append -Encoding utf8

    Write-Verbose "Erreur enregistrée avec l'ID : $($errorObject.Id)"
    return $errorObject.Id
}

# Fonction pour analyser les erreurs
function Get-PowerShellErrorAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Category = "",

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 10,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStatistics
    )

    # Vérifier si le système est initialisé
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }

    # Filtrer les erreurs par catégorie si spécifié
    $errors = if ($Category) {
        $script:ErrorDatabase.Errors | Where-Object { $_.Category -eq $Category }
    }
    else {
        $script:ErrorDatabase.Errors
    }

    # Limiter le nombre de résultats
    $errors = $errors | Select-Object -Last $MaxResults

    # Préparer le résultat
    $result = @{
        Errors = $errors
    }

    # Ajouter les statistiques si demandé
    if ($IncludeStatistics) {
        $result.Statistics = $script:ErrorDatabase.Statistics
    }

    return $result
}

# Fonction pour obtenir des suggestions basées sur une erreur
function Get-ErrorSuggestions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    # Vérifier si le système est initialisé
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }

    # Extraire le message d'erreur
    $errorMessage = $ErrorRecord.Exception.Message
    $errorType = $ErrorRecord.Exception.GetType().FullName

    # Rechercher des erreurs similaires dans la base de données
    $similarErrors = $script:ErrorDatabase.Errors | Where-Object {
        $_.ErrorType -eq $errorType -or $_.ErrorMessage -like "*$errorMessage*"
    }

    # Si aucune erreur similaire n'est trouvée, retourner un message
    if (-not $similarErrors -or $similarErrors.Count -eq 0) {
        return @{
            Found = $false
            Message = "Aucune suggestion trouvée pour cette erreur."
            Suggestions = @()
        }
    }

    # Extraire les solutions uniques
    $suggestions = $similarErrors | Where-Object { $_.Solution } | Select-Object -Property Solution, Category -Unique

    return @{
        Found = $true
        Message = "Suggestions trouvées pour cette erreur."
        Suggestions = $suggestions
        SimilarErrors = $similarErrors
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorLearningSystem, Register-PowerShellError, Get-PowerShellErrorAnalysis, Get-ErrorSuggestions
