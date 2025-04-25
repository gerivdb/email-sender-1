#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute des tests spécifiques pour le projet MCP.
.DESCRIPTION
    Ce script exécute des tests spécifiques pour le projet MCP, en évitant les problèmes de récursion.
.EXAMPLE
    .\Run-SpecificTests.ps1
    Exécute les tests spécifiés.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>
[CmdletBinding()]
param ()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Vérifier si Pester est installé
Write-Log "Vérification de l'installation de Pester..." -Level "INFO"
$pesterInstalled = Get-Module -Name Pester -ListAvailable
if (-not $pesterInstalled) {
    Write-Log "Pester n'est pas installé. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Créer un dossier pour les rapports
$reportsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Chemins des fichiers de test spécifiques
$testFiles = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "unit\MCPManager.Tests.Complete.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "unit\MCPClient.Tests.Complete.ps1")
)

# Exécuter chaque test spécifique
foreach ($testFile in $testFiles) {
    if (Test-Path $testFile) {
        Write-Log "Exécution du test: $testFile" -Level "INFO"
        
        # Créer une configuration Pester
        $config = New-PesterConfiguration
        $config.Run.Path = $testFile
        $config.Run.PassThru = $true
        $config.Output.Verbosity = 'Detailed'
        
        # Exécuter le test
        $results = Invoke-Pester -Configuration $config
        
        # Afficher les résultats
        Write-Log "Tests exécutés: $($results.TotalCount)" -Level "INFO"
        Write-Log "Tests réussis: $($results.PassedCount)" -Level "SUCCESS"
        Write-Log "Tests échoués: $($results.FailedCount)" -Level $(if ($results.FailedCount -gt 0) { "ERROR" } else { "INFO" })
        Write-Log "Tests ignorés: $($results.SkippedCount)" -Level "INFO"
        Write-Log "Tests non exécutés: $($results.NotRunCount)" -Level "INFO"
        
        # Afficher les détails des tests échoués
        if ($results.FailedCount -gt 0) {
            Write-Log "Détails des tests échoués:" -Level "ERROR"
            foreach ($failed in $results.Failed) {
                Write-Log "  - $($failed.Name): $($failed.ErrorRecord.Exception.Message)" -Level "ERROR"
            }
        }
    } else {
        Write-Log "Fichier de test non trouvé: $testFile" -Level "ERROR"
    }
}

Write-Log "Tous les tests ont été exécutés" -Level "SUCCESS"
