<#
.SYNOPSIS
    Script pour collecter et analyser les erreurs PowerShell.
.DESCRIPTION
    Ce script collecte les erreurs PowerShell Ã  partir des journaux d'Ã©vÃ©nements et des fichiers de log.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "",

    [Parameter(Mandatory = $false)]
    [int]$MaxErrors = 100,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeEventLogs,

    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeOnly
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem

# Fonction pour collecter les erreurs Ã  partir des fichiers de log
function Get-ErrorsFromLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [int]$MaxErrors = 100
    )

    if (-not (Test-Path -Path $LogPath)) {
        Write-Warning "Le chemin de log spÃ©cifiÃ© n'existe pas : $LogPath"
        return @()
    }

    $logFiles = Get-ChildItem -Path $LogPath -Filter "*.log" -Recurse
    $errors = @()

    foreach ($logFile in $logFiles) {
        Write-Verbose "Analyse du fichier de log : $($logFile.FullName)"

        $content = Get-Content -Path $logFile.FullName -Raw

        # Rechercher les erreurs PowerShell dans le fichier de log
        $errorMatches = [regex]::Matches($content, "(?ms)Error:\s*(.*?)(?=\r?\n\r?\n|\z)")

        foreach ($match in $errorMatches) {
            $errorMessage = $match.Groups[1].Value.Trim()

            # CrÃ©er un objet d'erreur
            $errorObject = @{
                Source = $logFile.Name
                ErrorMessage = $errorMessage
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Category = "LogFile"
            }

            $errors += $errorObject

            if ($errors.Count -ge $MaxErrors) {
                Write-Verbose "Nombre maximum d'erreurs atteint : $MaxErrors"
                break
            }
        }

        if ($errors.Count -ge $MaxErrors) {
            break
        }
    }

    return $errors
}

# Fonction pour collecter les erreurs Ã  partir des journaux d'Ã©vÃ©nements
function Get-ErrorsFromEventLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxErrors = 100
    )

    $errors = @()

    try {
        $eventLogs = Get-WinEvent -LogName "Windows PowerShell" -MaxEvents $MaxErrors -ErrorAction Stop |
            Where-Object { $_.LevelDisplayName -eq "Error" }

        foreach ($event in $eventLogs) {
            # CrÃ©er un objet d'erreur
            $errorObject = @{
                Source = "EventLog"
                ErrorMessage = $event.Message
                Timestamp = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                Category = "EventLog"
                EventId = $event.Id
                MachineName = $event.MachineName
            }

            $errors += $errorObject
        }
    }
    catch {
        Write-Warning "Impossible de rÃ©cupÃ©rer les journaux d'Ã©vÃ©nements : $_"
    }

    return $errors
}

# Collecter les erreurs
$collectedErrors = @()

if (-not $AnalyzeOnly) {
    # Collecter les erreurs Ã  partir des fichiers de log
    if ($LogPath) {
        $logErrors = Get-ErrorsFromLogs -LogPath $LogPath -MaxErrors $MaxErrors
        $collectedErrors += $logErrors
        Write-Host "Erreurs collectÃ©es Ã  partir des fichiers de log : $($logErrors.Count)"
    }

    # Collecter les erreurs Ã  partir des journaux d'Ã©vÃ©nements
    if ($IncludeEventLogs) {
        $eventLogErrors = Get-ErrorsFromEventLogs -MaxErrors $MaxErrors
        $collectedErrors += $eventLogErrors
        Write-Host "Erreurs collectÃ©es Ã  partir des journaux d'Ã©vÃ©nements : $($eventLogErrors.Count)"
    }

    # Enregistrer les erreurs collectÃ©es
    foreach ($error in $collectedErrors) {
        # CrÃ©er un ErrorRecord factice pour l'enregistrement
        $exception = New-Object System.Exception($error.ErrorMessage)
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "CollectedError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )

        # Enregistrer l'erreur
        Register-PowerShellError -ErrorRecord $errorRecord -Source $error.Source -Category $error.Category -AdditionalInfo $error
    }

    Write-Host "Total des erreurs collectÃ©es et enregistrÃ©es : $($collectedErrors.Count)"
}

# Analyser les erreurs
$analysisResult = Get-PowerShellErrorAnalysis -IncludeStatistics
$totalErrors = $analysisResult.Statistics.TotalErrors
$categories = $analysisResult.Statistics.CategorizedErrors

Write-Host "`nAnalyse des erreurs :"
Write-Host "Total des erreurs enregistrÃ©es : $totalErrors"
Write-Host "`nRÃ©partition par catÃ©gorie :"

foreach ($category in $categories.Keys) {
    $count = $categories[$category]
    $percentage = [math]::Round(($count / $totalErrors) * 100, 2)
    Write-Host "  $category : $count ($percentage%)"
}

Write-Host "`nErreurs rÃ©centes :"
$recentErrors = $analysisResult.Errors | Select-Object -Last 5

foreach ($error in $recentErrors) {
    Write-Host "`n  ID : $($error.Id)"
    Write-Host "  Timestamp : $($error.Timestamp)"
    Write-Host "  Source : $($error.Source)"
    Write-Host "  CatÃ©gorie : $($error.Category)"
    Write-Host "  Message : $($error.ErrorMessage)"
}

Write-Host "`nAnalyse terminÃ©e."
