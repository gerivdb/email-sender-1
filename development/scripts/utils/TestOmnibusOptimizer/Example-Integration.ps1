<#
.SYNOPSIS
    Exemple d'utilisation du module TestOmnibusOptimizer.
.DESCRIPTION
    Ce script montre comment utiliser le module TestOmnibusOptimizer pour
    combiner les fonctionnalitÃ©s de TestOmnibus et du SystÃ¨me d'Optimisation Proactive.
.EXAMPLE
    .\Example-Integration.ps1
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
    Version: 1.0
#>

# Importer le module TestOmnibusOptimizer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "TestOmnibusOptimizer.psm1"
Import-Module $modulePath -Force

# DÃ©finir les chemins
$testPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tests"
$usageDataPath = Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"
$outputPath = Join-Path -Path $env:TEMP -ChildPath "TestOmnibusOptimizer\Reports"

# Ajouter le chemin vers les tests de Example-Usage.ps1
$exampleUsageTestPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "PSCacheManager\Example-Usage.Tests.ps1"
$exampleUsageUnitTestPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "PSCacheManager\Example-Usage.Unit.Tests.ps1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests si nÃ©cessaire
if (-not (Test-Path -Path $testPath)) {
    New-Item -Path $testPath -ItemType Directory -Force | Out-Null
}

# Copier les fichiers de test dans le rÃ©pertoire de tests
if (Test-Path -Path $exampleUsageTestPath) {
    Write-Host "Test Example-Usage.Tests.ps1 trouvÃ©: $exampleUsageTestPath" -ForegroundColor Green
    Copy-Item -Path $exampleUsageTestPath -Destination $testPath -Force
    Write-Host "Test Example-Usage.Tests.ps1 copiÃ© dans le rÃ©pertoire de tests: $testPath" -ForegroundColor Green
}

if (Test-Path -Path $exampleUsageUnitTestPath) {
    Write-Host "Test Example-Usage.Unit.Tests.ps1 trouvÃ©: $exampleUsageUnitTestPath" -ForegroundColor Green
    Copy-Item -Path $exampleUsageUnitTestPath -Destination $testPath -Force
    Write-Host "Test Example-Usage.Unit.Tests.ps1 copiÃ© dans le rÃ©pertoire de tests: $testPath" -ForegroundColor Green
}

# VÃ©rifier si le rÃ©pertoire de tests existe
if (-not (Test-Path -Path $testPath)) {
    Write-Warning "Le rÃ©pertoire de tests n'existe pas: $testPath"
    Write-Host "CrÃ©ation d'un rÃ©pertoire de tests de dÃ©monstration..." -ForegroundColor Cyan

    $testPath = Join-Path -Path $env:TEMP -ChildPath "TestOmnibusOptimizer\DemoTests"
    New-Item -Path $testPath -ItemType Directory -Force | Out-Null

    # CrÃ©er quelques tests de dÃ©monstration
    $test1 = @"
Describe "Test-SuccessfulFunction" {
    It "Should return true" {
        function Test-SuccessfulFunction {
            return $true
        }

        Test-SuccessfulFunction | Should -Be $true
    }
}
"@

    $test2 = @"
Describe "Test-FailingFunction" {
    It "Should return true but will fail" {
        function Test-FailingFunction {
            return $false
        }

        Test-FailingFunction | Should -Be $true
    }
}
"@

    $test3 = @"
Describe "Test-SlowFunction" {
    It "Should be slow but successful" {
        function Test-SlowFunction {
            Start-Sleep -Seconds 2
            return $true
        }

        Test-SlowFunction | Should -Be $true
    }
}
"@

    $test1 | Out-File -FilePath (Join-Path -Path $testPath -ChildPath "Test-SuccessfulFunction.Tests.ps1") -Encoding utf8 -Force
    $test2 | Out-File -FilePath (Join-Path -Path $testPath -ChildPath "Test-FailingFunction.Tests.ps1") -Encoding utf8 -Force
    $test3 | Out-File -FilePath (Join-Path -Path $testPath -ChildPath "Test-SlowFunction.Tests.ps1") -Encoding utf8 -Force

    Write-Host "Tests de dÃ©monstration crÃ©Ã©s dans: $testPath" -ForegroundColor Green
}

# VÃ©rifier si les donnÃ©es d'utilisation existent
if (-not (Test-Path -Path $usageDataPath)) {
    Write-Warning "Les donnÃ©es d'utilisation n'existent pas: $usageDataPath"
    Write-Host "CrÃ©ation de donnÃ©es d'utilisation de dÃ©monstration..." -ForegroundColor Cyan

    # Importer le module UsageMonitor
    $usageMonitorPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "UsageMonitor\UsageMonitor.psm1"
    Import-Module $usageMonitorPath -Force

    # Initialiser le moniteur d'utilisation
    Initialize-UsageMonitor -DatabasePath $usageDataPath

    # Simuler l'utilisation de quelques scripts
    $scriptPaths = @(
        (Join-Path -Path $testPath -ChildPath "Test-SuccessfulFunction.ps1"),
        (Join-Path -Path $testPath -ChildPath "Test-FailingFunction.ps1"),
        (Join-Path -Path $testPath -ChildPath "Test-SlowFunction.ps1")
    )

    foreach ($scriptPath in $scriptPaths) {
        # CrÃ©er le script s'il n'existe pas
        if (-not (Test-Path -Path $scriptPath)) {
            $scriptName = Split-Path -Path $scriptPath -Leaf
            $scriptContent = "function $($scriptName -replace '\.ps1', '') { return `$true }"
            $scriptContent | Out-File -FilePath $scriptPath -Encoding utf8 -Force
        }

        # Simuler plusieurs exÃ©cutions
        for ($i = 1; $i -le 10; $i++) {
            $executionId = Start-ScriptUsageTracking -ScriptPath $scriptPath

            # Simuler une exÃ©cution
            $success = $true

            if ($scriptPath -match "Failing") {
                # Simuler un Ã©chec occasionnel
                $success = ($i % 3 -ne 0)
            } elseif ($scriptPath -match "Slow") {
                # Simuler une exÃ©cution lente
                Start-Sleep -Milliseconds 10  # Simuler une exÃ©cution plus longue
            } else {
                # Simuler une exÃ©cution normale
            }

            Start-Sleep -Milliseconds 10  # Simuler une exÃ©cution minimale

            # Terminer le suivi d'utilisation
            Stop-ScriptUsageTracking -ExecutionId $executionId -Success $success -ErrorMessage $(if (-not $success) { "Erreur simulÃ©e" } else { "" })
        }
    }

    # Sauvegarder la base de donnÃ©es
    Save-UsageDatabase

    Write-Host "DonnÃ©es d'utilisation de dÃ©monstration crÃ©Ã©es dans: $usageDataPath" -ForegroundColor Green
}

# ExÃ©cuter TestOmnibus avec des paramÃ¨tres optimisÃ©s
Write-Host "`n=== Execution de TestOmnibus avec des parametres optimises ===" -ForegroundColor Green
$config = Invoke-OptimizedTestOmnibus -TestPath $testPath -UsageDataPath $usageDataPath -OutputPath $outputPath -GenerateCombinedReport

# Afficher la configuration utilisÃ©e
Write-Host "`nConfiguration utilisÃ©e:" -ForegroundColor Yellow
$config | ConvertTo-Json -Depth 3

# GÃ©nÃ©rer des suggestions d'optimisation
Write-Host "`n=== Generation de suggestions d'optimisation ===" -ForegroundColor Green
$testResultsPath = Join-Path -Path $outputPath -ChildPath "TestResults\results.xml"

# VÃ©rifier si les rÃ©sultats de test existent
if (Test-Path -Path $testResultsPath) {
    $suggestions = Get-CombinedOptimizationSuggestions -TestResultsPath $testResultsPath -UsageDataPath $usageDataPath -OutputPath $outputPath

    # Afficher les suggestions
    Write-Host "`nSuggestions d'optimisation:" -ForegroundColor Yellow

    # Afficher les suggestions dans un format plus lisible avec encodage correct
    foreach ($suggestion in $suggestions) {
        Write-Host "`nScript: $($suggestion.ScriptName)" -ForegroundColor Cyan
        Write-Host "Priorite: $($suggestion.Priority)" -ForegroundColor $(switch ($suggestion.Priority) {
                "Critical" { "Red" }
                "High" { "Yellow" }
                "Medium" { "Green" }
                default { "White" }
            })
        Write-Host "Type: $($suggestion.Type)"

        # Afficher les details
        if ($suggestion.TestStatus) {
            Write-Host "Test: $($suggestion.TestStatus)"
        }

        if ($suggestion.UsageFailRate -and $suggestion.UsageFailRate -ne "N/A") {
            Write-Host "Taux d'echec: $($suggestion.UsageFailRate)%"
        }

        if ($suggestion.TestDuration) {
            Write-Host "Duree de test: $($suggestion.TestDuration) ms"
        }

        if ($suggestion.UsageDuration -and $suggestion.UsageDuration -ne "N/A") {
            Write-Host "Duree en production: $($suggestion.UsageDuration) ms"
        }

        if ($suggestion.UsageCount) {
            Write-Host "Nombre d'executions: $($suggestion.UsageCount)"
        }

        Write-Host "Suggestion: $($suggestion.Suggestion)" -ForegroundColor White
        Write-Host "--------------------------------------------------"
    }
} else {
    Write-Warning "Les rÃ©sultats de test n'existent pas: $testResultsPath"
}

# Afficher les chemins des rapports
Write-Host "`n=== Rapports generes ===" -ForegroundColor Green
Write-Host "Rapport de test: $(Join-Path -Path $outputPath -ChildPath "TestResults\report.html")" -ForegroundColor Cyan
Write-Host "Rapport combine: $(Join-Path -Path $outputPath -ChildPath "combined_report.html")" -ForegroundColor Cyan
Write-Host "Suggestions d'optimisation: $(Join-Path -Path $outputPath -ChildPath "optimization_suggestions.html")" -ForegroundColor Cyan

# Ouvrir les rapports dans le navigateur
$combinedReportPath = Join-Path -Path $outputPath -ChildPath "combined_report.html"
$suggestionsPath = Join-Path -Path $outputPath -ChildPath "optimization_suggestions.html"

if (Test-Path -Path $combinedReportPath) {
    Write-Host "`nOuverture du rapport combine..." -ForegroundColor Green
    Start-Process $combinedReportPath
}

if (Test-Path -Path $suggestionsPath) {
    Write-Host "Ouverture des suggestions d'optimisation..." -ForegroundColor Green
    Start-Process $suggestionsPath
}
