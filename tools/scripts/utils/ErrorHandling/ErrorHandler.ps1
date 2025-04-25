<#
.SYNOPSIS
    Module de gestion des erreurs pour les scripts PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour gérer les erreurs de manière cohérente
    dans les scripts PowerShell, avec journalisation et rapports.
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

# Fonction pour gérer les erreurs de manière cohérente
function Handle-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $false)]
        [string]$Context = "Opération générale",
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\ErrorLogs\$(Get-Date -Format 'yyyyMMdd').log",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowException,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExitScript
    )
    
    # Créer le répertoire de logs s'il n'existe pas
    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Formater le message d'erreur
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorMessage = "[$timestamp] ERREUR dans '$Context': $($ErrorRecord.Exception.Message)"
    $errorDetails = @"
Détails de l'erreur:
  Message: $($ErrorRecord.Exception.Message)
  Type d'exception: $($ErrorRecord.Exception.GetType().FullName)
  Catégorie: $($ErrorRecord.CategoryInfo.Category)
  Cible: $($ErrorRecord.CategoryInfo.TargetName)
  Script: $($ErrorRecord.InvocationInfo.ScriptName)
  Ligne: $($ErrorRecord.InvocationInfo.ScriptLineNumber)
  Position: $($ErrorRecord.InvocationInfo.PositionMessage)
  Pile d'appels: 
$($ErrorRecord.ScriptStackTrace)
"@
    
    # Journaliser l'erreur
    $logEntry = @"
==================================================
$errorMessage
$errorDetails
==================================================

"@
    
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
    
    # Afficher l'erreur dans la console
    Write-Error $errorMessage
    Write-Verbose $errorDetails
    
    # Gérer l'erreur selon les paramètres
    if ($ThrowException) {
        throw $ErrorRecord
    }
    
    if ($ExitScript) {
        # Sortir du script avec un code d'erreur
        exit 1
    }
}

# Fonction pour configurer un gestionnaire d'erreurs global
function Set-GlobalErrorHandler {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\ErrorLogs\$(Get-Date -Format 'yyyyMMdd').log"
    )
    
    # Définir le gestionnaire d'erreurs global
    $global:ErrorActionPreference = "Continue"
    
    # Créer un gestionnaire d'erreurs qui sera appelé pour chaque erreur non gérée
    $global:error_handler = {
        param($sender, $eventArgs)
        
        $exception = $eventArgs.Exception
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            "GlobalErrorHandler",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        Handle-Error -ErrorRecord $errorRecord -Context "Erreur non gérée" -LogPath $LogPath
    }
    
    # Attacher le gestionnaire d'erreurs à l'événement d'erreur
    $null = [AppDomain]::CurrentDomain.add_UnhandledException($global:error_handler)
    
    Write-Host "Gestionnaire d'erreurs global configuré. Les erreurs seront journalisées dans: $LogPath" -ForegroundColor Cyan
}

# Fonction pour générer un rapport d'erreurs
function Get-ErrorReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\ErrorLogs\$(Get-Date -Format 'yyyyMMdd').log",
        
        [Parameter(Mandatory = $false)]
        [switch]$LastDay,
        
        [Parameter(Mandatory = $false)]
        [switch]$LastWeek,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateHtml,
        
        [Parameter(Mandatory = $false)]
        [string]$HtmlOutputPath = "$env:TEMP\ErrorReports\ErrorReport_$(Get-Date -Format 'yyyyMMdd').html"
    )
    
    # Déterminer les fichiers de log à analyser
    $logFiles = @()
    
    if ($LastDay) {
        $startDate = (Get-Date).AddDays(-1)
        $endDate = Get-Date
        
        for ($date = $startDate; $date -le $endDate; $date = $date.AddDays(1)) {
            $logFile = "$env:TEMP\ErrorLogs\$($date.ToString('yyyyMMdd')).log"
            if (Test-Path -Path $logFile) {
                $logFiles += $logFile
            }
        }
    }
    elseif ($LastWeek) {
        $startDate = (Get-Date).AddDays(-7)
        $endDate = Get-Date
        
        for ($date = $startDate; $date -le $endDate; $date = $date.AddDays(1)) {
            $logFile = "$env:TEMP\ErrorLogs\$($date.ToString('yyyyMMdd')).log"
            if (Test-Path -Path $logFile) {
                $logFiles += $logFile
            }
        }
    }
    else {
        if (Test-Path -Path $LogPath) {
            $logFiles += $LogPath
        }
    }
    
    # Analyser les fichiers de log
    $errorEntries = @()
    
    foreach ($logFile in $logFiles) {
        $content = Get-Content -Path $logFile -Raw
        
        # Extraire les entrées d'erreur
        $pattern = '(?s)==================================================\r?\n\[(.*?)\] ERREUR dans \'(.*?)\':(.*?)==================================================\r?\n'
        $matches = [regex]::Matches($content, $pattern)
        
        foreach ($match in $matches) {
            $timestamp = $match.Groups[1].Value.Trim()
            $context = $match.Groups[2].Value.Trim()
            $details = $match.Groups[3].Value.Trim()
            
            $errorEntries += [PSCustomObject]@{
                Timestamp = [datetime]::ParseExact($timestamp, "yyyy-MM-dd HH:mm:ss", $null)
                Context = $context
                Details = $details
            }
        }
    }
    
    # Trier les erreurs par horodatage
    $errorEntries = $errorEntries | Sort-Object -Property Timestamp -Descending
    
    # Générer un rapport HTML si demandé
    if ($GenerateHtml) {
        # Créer le répertoire de rapports s'il n'existe pas
        $reportDir = Split-Path -Path $HtmlOutputPath -Parent
        if (-not (Test-Path -Path $reportDir)) {
            New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
        }
        
        # Générer le HTML
        $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'erreurs</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        .error-entry {
            margin-bottom: 20px;
            padding: 15px;
            background-color: #f8f9fa;
            border-left: 4px solid #e74c3c;
            border-radius: 3px;
        }
        .error-timestamp {
            color: #7f8c8d;
            font-size: 0.9em;
            margin-bottom: 5px;
        }
        .error-context {
            font-weight: bold;
            color: #e74c3c;
            margin-bottom: 10px;
        }
        .error-details {
            font-family: monospace;
            white-space: pre-wrap;
            background-color: #f1f1f1;
            padding: 10px;
            border-radius: 3px;
            overflow-x: auto;
        }
        .summary {
            margin-bottom: 20px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 3px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport d'erreurs</h1>
        <div class="summary">
            <p><strong>Période:</strong> $(if ($LastDay) { "Dernières 24 heures" } elseif ($LastWeek) { "Dernière semaine" } else { "Journée courante" })</p>
            <p><strong>Nombre d'erreurs:</strong> $($errorEntries.Count)</p>
            <p><strong>Généré le:</strong> $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
        </div>
        
        <h2>Erreurs détectées</h2>
"@
        
        if ($errorEntries.Count -gt 0) {
            foreach ($entry in $errorEntries) {
                $htmlContent += @"
        <div class="error-entry">
            <div class="error-timestamp">$($entry.Timestamp.ToString("dd/MM/yyyy HH:mm:ss"))</div>
            <div class="error-context">$($entry.Context)</div>
            <div class="error-details">$($entry.Details)</div>
        </div>
"@
            }
        }
        else {
            $htmlContent += @"
        <p>Aucune erreur détectée pour la période spécifiée.</p>
"@
        }
        
        $htmlContent += @"
        <div class="footer">
            <p>Généré par le module de gestion des erreurs</p>
        </div>
    </div>
</body>
</html>
"@
        
        # Enregistrer le rapport HTML
        $htmlContent | Out-File -FilePath $HtmlOutputPath -Encoding UTF8
        
        Write-Host "Rapport HTML généré: $HtmlOutputPath" -ForegroundColor Green
        
        return $HtmlOutputPath
    }
    
    # Retourner les entrées d'erreur
    return $errorEntries
}

# Exporter les fonctions
Export-ModuleMember -Function Handle-Error, Set-GlobalErrorHandler, Get-ErrorReport
