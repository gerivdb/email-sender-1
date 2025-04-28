<#
.SYNOPSIS
    Script d'exÃ©cution des tests unitaires pour les templates Hygen scripts.

.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour les templates Hygen scripts.

.PARAMETER OutputPath
    Chemin du fichier de rapport de tests. Par dÃ©faut, "scripts\docs\hygen-test-report.md".

.EXAMPLE
    .\run-script-hygen-tests.ps1
    ExÃ©cute les tests unitaires et gÃ©nÃ¨re un rapport dans le chemin par dÃ©faut.

.EXAMPLE
    .\run-script-hygen-tests.ps1 -OutputPath "C:\Temp\test-report.md"
    ExÃ©cute les tests unitaires et gÃ©nÃ¨re un rapport dans le chemin spÃ©cifiÃ©.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
    Date de crÃ©ation: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ""
)

# DÃ©finir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succÃ¨s
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "âœ“ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "âœ— $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "â„¹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "âš  $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour exÃ©cuter les tests unitaires
function Invoke-Tests {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TestPath
    )
    
    # VÃ©rifier si Pester est installÃ©
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Pester n'est pas installÃ©. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer Pester
    Import-Module -Name Pester -Force
    
    # Configurer Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPath
    $pesterConfig.Output.Verbosity = "Detailed"
    
    # ExÃ©cuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig -PassThru
    
    return $testResults
}

# Fonction pour gÃ©nÃ©rer un rapport de tests
function New-TestReport {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [object]$TestResults,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    if ($PSCmdlet.ShouldProcess($OutputPath, "GÃ©nÃ©rer le rapport")) {
        $report = @"
# Rapport de tests unitaires pour les templates Hygen scripts

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## RÃ©sumÃ©

- **Tests exÃ©cutÃ©s**: $($TestResults.TotalCount)
- **Tests rÃ©ussis**: $($TestResults.PassedCount)
- **Tests Ã©chouÃ©s**: $($TestResults.FailedCount)
- **Tests ignorÃ©s**: $($TestResults.SkippedCount)
- **DurÃ©e totale**: $($TestResults.Duration.TotalSeconds.ToString("0.00")) secondes

## DÃ©tails des tests

"@
        
        foreach ($container in $TestResults.Containers) {
            $report += "`n### $($container.Item)`n"
            
            foreach ($block in $container.Blocks) {
                $report += "`n#### $($block.Name)`n"
                
                foreach ($test in $block.Tests) {
                    $status = if ($test.Result -eq "Passed") { "âœ“" } else { "âœ—" }
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
            $report += "`nTous les tests ont rÃ©ussi. Les templates Hygen scripts sont correctement installÃ©s et fonctionnent comme prÃ©vu."
        } else {
            $report += "`nCertains tests ont Ã©chouÃ©. Veuillez consulter les dÃ©tails des tests pour plus d'informations."
        }
        
        Set-Content -Path $OutputPath -Value $report
        Write-Success "Rapport de tests gÃ©nÃ©rÃ©: $OutputPath"
        
        return $OutputPath
    } else {
        return $null
    }
}

# Fonction principale
function Start-TestExecution {
    Write-Info "ExÃ©cution des tests unitaires pour les templates Hygen scripts..."
    
    # DÃ©terminer le chemin de sortie
    $projectRoot = Get-ProjectPath
    $scriptsRoot = Join-Path -Path $projectRoot -ChildPath "scripts"
    $docsFolder = Join-Path -Path $scriptsRoot -ChildPath "docs"
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $docsFolder -ChildPath "hygen-test-report.md"
    }
    
    # DÃ©terminer le chemin des tests
    $testPath = Join-Path -Path $scriptsRoot -ChildPath "tests\ScriptHygen.Tests.ps1"
    
    # VÃ©rifier si le fichier de test existe
    if (-not (Test-Path -Path $testPath)) {
        Write-Error "Le fichier de test n'existe pas: $testPath"
        return $false
    }
    
    # ExÃ©cuter les tests
    Write-Info "ExÃ©cution des tests: $testPath"
    $testResults = Invoke-Tests -TestPath $testPath
    
    # Afficher les rÃ©sultats
    Write-Info "Tests exÃ©cutÃ©s: $($testResults.TotalCount)"
    Write-Info "Tests rÃ©ussis: $($testResults.PassedCount)"
    Write-Info "Tests Ã©chouÃ©s: $($testResults.FailedCount)"
    Write-Info "Tests ignorÃ©s: $($testResults.SkippedCount)"
    Write-Info "DurÃ©e totale: $($testResults.Duration.TotalSeconds.ToString("0.00")) secondes"
    
    # GÃ©nÃ©rer le rapport
    $reportPath = New-TestReport -TestResults $testResults -OutputPath $OutputPath
    
    # Afficher le rÃ©sultat
    if ($reportPath) {
        Write-Success "Rapport de tests gÃ©nÃ©rÃ©: $reportPath"
    } else {
        Write-Error "Impossible de gÃ©nÃ©rer le rapport de tests"
    }
    
    return $testResults.FailedCount -eq 0
}

# ExÃ©cuter les tests
Start-TestExecution
