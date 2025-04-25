<#
.SYNOPSIS
    Initialise la gestion des erreurs pour TestOmnibus.
.DESCRIPTION
    Ce script initialise la gestion des erreurs pour TestOmnibus en utilisant
    le module ErrorHandler.ps1. Il configure un gestionnaire d'erreurs global
    et fournit des fonctions pour gérer les erreurs de manière cohérente.
.EXAMPLE
    . .\Initialize-ErrorHandling.ps1
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

# Importer le module de gestion des erreurs
$errorHandlerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\utils\ErrorHandling\ErrorHandler.ps1"
if (Test-Path -Path $errorHandlerPath) {
    . $errorHandlerPath
} else {
    Write-Warning "Le module de gestion des erreurs n'a pas été trouvé: $errorHandlerPath"
    
    # Définir des fonctions de base pour la gestion des erreurs si le module n'est pas disponible
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
        
        # Afficher l'erreur
        Write-Error "ERREUR dans '$Context': $($ErrorRecord.Exception.Message)"
        
        # Gérer l'erreur selon les paramètres
        if ($ThrowException) {
            throw $ErrorRecord
        }
        
        if ($ExitScript) {
            exit 1
        }
    }
    
    function Set-GlobalErrorHandler {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $false)]
            [string]$LogPath = "$env:TEMP\ErrorLogs\$(Get-Date -Format 'yyyyMMdd').log"
        )
        
        Write-Host "Gestionnaire d'erreurs simplifié configuré." -ForegroundColor Yellow
    }
}

# Configurer le gestionnaire d'erreurs global
$logPath = Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\ErrorLogs\$(Get-Date -Format 'yyyyMMdd').log"
Set-GlobalErrorHandler -LogPath $logPath

# Fonction pour gérer les erreurs spécifiques à TestOmnibus
function Handle-TestOmnibusError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $false)]
        [string]$TestName = "Test inconnu",
        
        [Parameter(Mandatory = $false)]
        [switch]$ContinueExecution,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddToReport
    )
    
    # Contexte spécifique à TestOmnibus
    $context = "TestOmnibus - $TestName"
    
    # Journaliser l'erreur
    Handle-Error -ErrorRecord $ErrorRecord -Context $context
    
    # Ajouter l'erreur au rapport si demandé
    if ($AddToReport) {
        $reportPath = Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results\error_report.json"
        
        # Créer le répertoire de rapports s'il n'existe pas
        $reportDir = Split-Path -Path $reportPath -Parent
        if (-not (Test-Path -Path $reportDir)) {
            New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
        }
        
        # Charger le rapport existant ou créer un nouveau
        if (Test-Path -Path $reportPath) {
            $report = Get-Content -Path $reportPath -Raw | ConvertFrom-Json
        } else {
            $report = @{
                Errors = @()
                GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                UpdatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        
        # Ajouter l'erreur au rapport
        $errorEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            TestName = $TestName
            Message = $ErrorRecord.Exception.Message
            ScriptName = $ErrorRecord.InvocationInfo.ScriptName
            LineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber
            StackTrace = $ErrorRecord.ScriptStackTrace
        }
        
        $report.Errors += $errorEntry
        $report.UpdatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Enregistrer le rapport
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    }
    
    # Sortir du script si demandé
    if (-not $ContinueExecution) {
        exit 1
    }
}

Write-Host "Gestion des erreurs initialisée pour TestOmnibus" -ForegroundColor Green
