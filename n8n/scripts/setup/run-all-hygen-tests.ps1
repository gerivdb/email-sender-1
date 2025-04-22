<#
.SYNOPSIS
    Script d'exécution de tous les tests Hygen.

.DESCRIPTION
    Ce script exécute tous les tests Hygen (installation, templates, utilitaires)
    et génère un rapport global des résultats.

.PARAMETER Interactive
    Si spécifié, le script sera exécuté en mode interactif, permettant à l'utilisateur de répondre aux prompts.

.PARAMETER PerformanceTest
    Si spécifié, des tests de performance seront exécutés.

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.PARAMETER OutputFolder
    Dossier de sortie pour les fichiers générés. Par défaut, les fichiers seront générés dans les dossiers standard.

.EXAMPLE
    .\run-all-hygen-tests.ps1
    Exécute tous les tests Hygen en mode non interactif.

.EXAMPLE
    .\run-all-hygen-tests.ps1 -Interactive
    Exécute tous les tests Hygen en mode interactif.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-11
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [switch]$Interactive = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$PerformanceTest = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepGeneratedFiles = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = ""
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
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour exécuter un script de test
function Invoke-TestScript {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory=$false)]
        [string]$TestName = ""
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script de test n'existe pas: $ScriptPath"
        return $false
    }
    
    try {
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Exécuter")) {
            $scriptCommand = "& '$ScriptPath'"
            if ($Arguments.Count -gt 0) {
                $scriptCommand += " " + ($Arguments -join " ")
            }
            
            Write-Info "Exécution du script de test: $scriptCommand"
            
            # Mesurer le temps d'exécution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Exécuter le script
            Invoke-Expression $scriptCommand
            $exitCode = $LASTEXITCODE
            
            $stopwatch.Stop()
            $executionTime = $stopwatch.Elapsed.TotalSeconds
            
            if ($exitCode -eq 0) {
                Write-Success "Script de test exécuté avec succès: $ScriptPath (temps: $($executionTime.ToString("0.000")) secondes)"
                
                return [PSCustomObject]@{
                    TestName = if ([string]::IsNullOrEmpty($TestName)) { $ScriptPath } else { $TestName }
                    Success = $true
                    ExecutionTime = $executionTime
                    ExitCode = $exitCode
                }
            } else {
                Write-Error "Erreur lors de l'exécution du script de test: $ScriptPath (code: $exitCode, temps: $($executionTime.ToString("0.000")) secondes)"
                
                return [PSCustomObject]@{
                    TestName = if ([string]::IsNullOrEmpty($TestName)) { $ScriptPath } else { $TestName }
                    Success = $false
                    ExecutionTime = $executionTime
                    ExitCode = $exitCode
                }
            }
        } else {
            return $null
        }
    }
    catch {
        Write-Error "Erreur lors de l'exécution du script de test: $ScriptPath - $_"
        
        return [PSCustomObject]@{
            TestName = if ([string]::IsNullOrEmpty($TestName)) { $ScriptPath } else { $TestName }
            Success = $false
            ExecutionTime = 0
            ExitCode = -1
        }
    }
}

# Fonction pour exécuter tous les tests
function Start-AllTests {
    $projectRoot = Get-ProjectPath
    $setupPath = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\setup"
    
    Write-Info "Exécution de tous les tests Hygen..."
    
    # Préparer les arguments communs
    $commonArgs = @()
    if ($KeepGeneratedFiles) {
        $commonArgs += "-KeepGeneratedFiles"
    }
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $commonArgs += "-OutputFolder '$OutputFolder'"
    }
    
    $results = @()
    
    # Test 1: Finalisation de l'installation
    $finalizeInstallationScript = Join-Path -Path $setupPath -ChildPath "finalize-hygen-installation.ps1"
    Write-Info "`nTest 1: Finalisation de l'installation..."
    $finalizeArgs = $commonArgs.Clone()
    $finalizeArgs += "-SkipCleanTest"
    $results += Invoke-TestScript -ScriptPath $finalizeInstallationScript -Arguments $finalizeArgs -TestName "Finalisation de l'installation"
    
    # Test 2: Validation des templates
    $validateTemplatesScript = Join-Path -Path $setupPath -ChildPath "validate-hygen-templates.ps1"
    Write-Info "`nTest 2: Validation des templates..."
    $validateTemplatesArgs = $commonArgs.Clone()
    if ($Interactive) {
        $validateTemplatesArgs += "-Interactive"
    }
    $results += Invoke-TestScript -ScriptPath $validateTemplatesScript -Arguments $validateTemplatesArgs -TestName "Validation des templates"
    
    # Test 3: Validation des scripts d'utilitaires
    $validateUtilitiesScript = Join-Path -Path $setupPath -ChildPath "validate-hygen-utilities.ps1"
    Write-Info "`nTest 3: Validation des scripts d'utilitaires..."
    $validateUtilitiesArgs = $commonArgs.Clone()
    if ($Interactive) {
        $validateUtilitiesArgs += "-Interactive"
    }
    if ($PerformanceTest) {
        $validateUtilitiesArgs += "-PerformanceTest"
    }
    $results += Invoke-TestScript -ScriptPath $validateUtilitiesScript -Arguments $validateUtilitiesArgs -TestName "Validation des scripts d'utilitaires"
    
    return $results
}

# Fonction pour générer un rapport global
function Generate-GlobalReport {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]$Results
    )
    
    $projectRoot = Get-ProjectPath
    $reportPath = Join-Path -Path $projectRoot -ChildPath "n8n\docs\hygen-global-test-report.md"
    
    if ($PSCmdlet.ShouldProcess($reportPath, "Générer le rapport")) {
        $successfulTests = $Results | Where-Object { $_.Success }
        $failedTests = $Results | Where-Object { -not $_.Success }
        
        $successRate = ($successfulTests.Count / $Results.Count) * 100
        $totalExecutionTime = ($Results | Measure-Object -Property ExecutionTime -Sum).Sum
        
        $report = @"
# Rapport global des tests Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- **Nombre total de tests**: $($Results.Count)
- **Tests réussis**: $($successfulTests.Count)
- **Tests échoués**: $($failedTests.Count)
- **Taux de succès**: $($successRate.ToString("0.00"))%
- **Temps d'exécution total**: $($totalExecutionTime.ToString("0.000")) secondes

## Résultats détaillés

| Test | Statut | Temps d'exécution (s) |
|------|--------|------------------------|
"@
        
        foreach ($result in $Results) {
            $status = if ($result.Success) { "✓ Réussi" } else { "✗ Échoué" }
            $report += "`n| $($result.TestName) | $status | $($result.ExecutionTime.ToString("0.000")) |"
        }
        
        $report += @"

## Analyse

### Tests réussis

"@
        
        if ($successfulTests.Count -gt 0) {
            foreach ($test in $successfulTests) {
                $report += "`n- $($test.TestName) (temps: $($test.ExecutionTime.ToString("0.000")) secondes)"
            }
        } else {
            $report += "`n- Aucun test réussi"
        }
        
        $report += @"

### Tests échoués

"@
        
        if ($failedTests.Count -gt 0) {
            foreach ($test in $failedTests) {
                $report += "`n- $($test.TestName) (temps: $($test.ExecutionTime.ToString("0.000")) secondes, code: $($test.ExitCode))"
            }
        } else {
            $report += "`n- Aucun test échoué"
        }
        
        $report += @"

## Conclusion

"@
        
        if ($successRate -eq 100) {
            $report += "`nTous les tests ont été exécutés avec succès. Hygen est correctement installé et configuré."
        } elseif ($successRate -ge 80) {
            $report += "`nLa plupart des tests ont été exécutés avec succès. Quelques problèmes mineurs ont été détectés."
        } elseif ($successRate -ge 50) {
            $report += "`nCertains tests ont échoué. Des problèmes importants ont été détectés."
        } else {
            $report += "`nLa plupart des tests ont échoué. Des problèmes critiques ont été détectés."
        }
        
        $report += @"

## Prochaines étapes

1. Corriger les problèmes détectés
2. Exécuter à nouveau les tests
3. Valider les bénéfices et l'utilité de Hygen
"@
        
        Set-Content -Path $reportPath -Value $report
        Write-Success "Rapport global généré: $reportPath"
        
        return $reportPath
    } else {
        return $null
    }
}

# Fonction principale
function Start-AllHygenTests {
    Write-Info "Exécution de tous les tests Hygen..."
    
    # Exécuter tous les tests
    $results = Start-AllTests
    
    # Générer un rapport global
    $reportPath = Generate-GlobalReport -Results $results
    
    # Afficher le résultat global
    Write-Host "`nRésultat global des tests:" -ForegroundColor $infoColor
    $successfulTests = $results | Where-Object { $_.Success }
    $failedTests = $results | Where-Object { -not $_.Success }
    
    $successRate = ($successfulTests.Count / $results.Count) * 100
    $totalExecutionTime = ($results | Measure-Object -Property ExecutionTime -Sum).Sum
    
    Write-Host "- Nombre total de tests: $($results.Count)" -ForegroundColor $infoColor
    Write-Host "- Tests réussis: $($successfulTests.Count)" -ForegroundColor $successColor
    Write-Host "- Tests échoués: $($failedTests.Count)" -ForegroundColor $errorColor
    Write-Host "- Taux de succès: $($successRate.ToString("0.00"))%" -ForegroundColor $infoColor
    Write-Host "- Temps d'exécution total: $($totalExecutionTime.ToString("0.000")) secondes" -ForegroundColor $infoColor
    
    if ($reportPath) {
        Write-Success "Rapport global généré: $reportPath"
    }
    
    return $successfulTests.Count -eq $results.Count
}

# Exécuter tous les tests
Start-AllHygenTests
