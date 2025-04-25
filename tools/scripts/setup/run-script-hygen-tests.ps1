<#
.SYNOPSIS
    Script d'exécution des tests unitaires pour les templates Hygen scripts.

.DESCRIPTION
    Ce script exécute les tests unitaires pour les templates Hygen scripts.

.PARAMETER OutputPath
    Chemin du fichier de rapport de tests. Par défaut, "scripts\docs\hygen-test-report.md".

.EXAMPLE
    .\run-script-hygen-tests.ps1
    Exécute les tests unitaires et génère un rapport dans le chemin par défaut.

.EXAMPLE
    .\run-script-hygen-tests.ps1 -OutputPath "C:\Temp\test-report.md"
    Exécute les tests unitaires et génère un rapport dans le chemin spécifié.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
    Date de création: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ""
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour exécuter les tests unitaires
function Invoke-Tests {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TestPath
    )
    
    # Vérifier si Pester est installé
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Pester n'est pas installé. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer Pester
    Import-Module -Name Pester -Force
    
    # Configurer Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPath
    $pesterConfig.Output.Verbosity = "Detailed"
    
    # Exécuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig -PassThru
    
    return $testResults
}

# Fonction pour générer un rapport de tests
function New-TestReport {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [object]$TestResults,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    if ($PSCmdlet.ShouldProcess($OutputPath, "Générer le rapport")) {
        $report = @"
# Rapport de tests unitaires pour les templates Hygen scripts

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- **Tests exécutés**: $($TestResults.TotalCount)
- **Tests réussis**: $($TestResults.PassedCount)
- **Tests échoués**: $($TestResults.FailedCount)
- **Tests ignorés**: $($TestResults.SkippedCount)
- **Durée totale**: $($TestResults.Duration.TotalSeconds.ToString("0.00")) secondes

## Détails des tests

"@
        
        foreach ($container in $TestResults.Containers) {
            $report += "`n### $($container.Item)`n"
            
            foreach ($block in $container.Blocks) {
                $report += "`n#### $($block.Name)`n"
                
                foreach ($test in $block.Tests) {
                    $status = if ($test.Result -eq "Passed") { "✓" } else { "✗" }
                    $report += "`n- $status $($test.Name)"
                    
                    if ($test.Result -eq "Failed") {
                        $report += "`n  - Erreur: $($test.ErrorRecord.Exception.Message)"
                    }
                }
            }
        }
        
        $report += @"

## Conclusion

"@
        
        if ($TestResults.FailedCount -eq 0) {
            $report += "`nTous les tests ont réussi. Les templates Hygen scripts sont correctement installés et fonctionnent comme prévu."
        } else {
            $report += "`nCertains tests ont échoué. Veuillez consulter les détails des tests pour plus d'informations."
        }
        
        Set-Content -Path $OutputPath -Value $report
        Write-Success "Rapport de tests généré: $OutputPath"
        
        return $OutputPath
    } else {
        return $null
    }
}

# Fonction principale
function Start-TestExecution {
    Write-Info "Exécution des tests unitaires pour les templates Hygen scripts..."
    
    # Déterminer le chemin de sortie
    $projectRoot = Get-ProjectPath
    $scriptsRoot = Join-Path -Path $projectRoot -ChildPath "scripts"
    $docsFolder = Join-Path -Path $scriptsRoot -ChildPath "docs"
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $docsFolder -ChildPath "hygen-test-report.md"
    }
    
    # Déterminer le chemin des tests
    $testPath = Join-Path -Path $scriptsRoot -ChildPath "tests\ScriptHygen.Tests.ps1"
    
    # Vérifier si le fichier de test existe
    if (-not (Test-Path -Path $testPath)) {
        Write-Error "Le fichier de test n'existe pas: $testPath"
        return $false
    }
    
    # Exécuter les tests
    Write-Info "Exécution des tests: $testPath"
    $testResults = Invoke-Tests -TestPath $testPath
    
    # Afficher les résultats
    Write-Info "Tests exécutés: $($testResults.TotalCount)"
    Write-Info "Tests réussis: $($testResults.PassedCount)"
    Write-Info "Tests échoués: $($testResults.FailedCount)"
    Write-Info "Tests ignorés: $($testResults.SkippedCount)"
    Write-Info "Durée totale: $($testResults.Duration.TotalSeconds.ToString("0.00")) secondes"
    
    # Générer le rapport
    $reportPath = New-TestReport -TestResults $testResults -OutputPath $OutputPath
    
    # Afficher le résultat
    if ($reportPath) {
        Write-Success "Rapport de tests généré: $reportPath"
    } else {
        Write-Error "Impossible de générer le rapport de tests"
    }
    
    return $testResults.FailedCount -eq 0
}

# Exécuter les tests
Start-TestExecution
