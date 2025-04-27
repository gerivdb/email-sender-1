<#
.SYNOPSIS
    Initialise la gestion des erreurs pour TestOmnibus.
.DESCRIPTION
    Ce script initialise la gestion des erreurs pour TestOmnibus en utilisant
    le module ErrorHandler.ps1. Il configure un gestionnaire d'erreurs global
    et fournit des fonctions pour gÃ©rer les erreurs de maniÃ¨re cohÃ©rente.
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
    Write-Warning "Le module de gestion des erreurs n'a pas Ã©tÃ© trouvÃ©: $errorHandlerPath"
    
    # DÃ©finir des fonctions de base pour la gestion des erreurs si le module n'est pas disponible
    function Handle-Error {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.ErrorRecord]$ErrorRecord,
            
            [Parameter(Mandatory = $false)]
            [string]$Context = "OpÃ©ration gÃ©nÃ©rale",
            
            [Parameter(Mandatory = $false)]
            [string]$LogPath = "$env:TEMP\ErrorLogs\$(Get-Date -Format 'yyyyMMdd').log",
            
            [Parameter(Mandatory = $false)]
            [switch]$ThrowException,
            
            [Parameter(Mandatory = $false)]
            [switch]$ExitScript
        )
        
        # Afficher l'erreur
        Write-Error "ERREUR dans '$Context': $($ErrorRecord.Exception.Message)"
        
        # GÃ©rer l'erreur selon les paramÃ¨tres
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
        
        Write-Host "Gestionnaire d'erreurs simplifiÃ© configurÃ©." -ForegroundColor Yellow
    }
}

# Configurer le gestionnaire d'erreurs global
$logPath = Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\ErrorLogs\$(Get-Date -Format 'yyyyMMdd').log"
Set-GlobalErrorHandler -LogPath $logPath

# Fonction pour gÃ©rer les erreurs spÃ©cifiques Ã  TestOmnibus
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
    
    # Contexte spÃ©cifique Ã  TestOmnibus
    $context = "TestOmnibus - $TestName"
    
    # Journaliser l'erreur
    Handle-Error -ErrorRecord $ErrorRecord -Context $context
    
    # Ajouter l'erreur au rapport si demandÃ©
    if ($AddToReport) {
        $reportPath = Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results\error_report.json"
        
        # CrÃ©er le rÃ©pertoire de rapports s'il n'existe pas
        $reportDir = Split-Path -Path $reportPath -Parent
        if (-not (Test-Path -Path $reportDir)) {
            New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
        }
        
        # Charger le rapport existant ou crÃ©er un nouveau
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
    
    # Sortir du script si demandÃ©
    if (-not $ContinueExecution) {
        exit 1
    }
}

Write-Host "Gestion des erreurs initialisÃ©e pour TestOmnibus" -ForegroundColor Green
