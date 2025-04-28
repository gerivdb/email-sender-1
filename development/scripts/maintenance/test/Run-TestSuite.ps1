#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute la suite complète de tests pour la solution d'organisation des scripts.
.DESCRIPTION
    Ce script exécute la suite complète de tests pour la solution d'organisation des scripts,
    y compris les tests unitaires, les tests d'intégration et la couverture de code.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de test.
.PARAMETER GenerateHTML
    Génère des rapports HTML en plus des rapports XML.
.EXAMPLE
    .\Run-TestSuite.ps1 -OutputPath ".\reports" -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Ajouter au fichier de log
    $logFilePath = Join-Path -Path $OutputPath -ChildPath "test_suite.log"
    Add-Content -Path $logFilePath -Value $logMessage -Encoding UTF8
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Créer les sous-dossiers pour les différents types de rapports
$testsPath = Join-Path -Path $OutputPath -ChildPath "tests"
$coveragePath = Join-Path -Path $OutputPath -ChildPath "coverage"
$integrationPath = Join-Path -Path $OutputPath -ChildPath "integration"

foreach ($path in @($testsPath, $coveragePath, $integrationPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Exécuter les tests unitaires
$allTestsScript = Join-Path -Path $PSScriptRoot -ChildPath "Run-AllTests.ps1"
Write-Log "Exécution des tests unitaires..." -Level "INFO"
$allTestsParams = @{
    OutputPath = $testsPath
}
if ($GenerateHTML) {
    $allTestsParams.Add("GenerateHTML", $true)
}
& $allTestsScript @allTestsParams
$allTestsResult = $LASTEXITCODE

# Exécuter les tests de couverture de code
$codeCoverageScript = Join-Path -Path $PSScriptRoot -ChildPath "Get-CodeCoverage.ps1"
Write-Log "Génération de la couverture de code..." -Level "INFO"
$codeCoverageParams = @{
    OutputPath = $coveragePath
}
if ($GenerateHTML) {
    $codeCoverageParams.Add("GenerateHTML", $true)
}
& $codeCoverageScript @codeCoverageParams
$codeCoverageResult = $LASTEXITCODE

# Exécuter les tests d'intégration
$integrationTestScript = Join-Path -Path $PSScriptRoot -ChildPath "Test-Integration.ps1"
Write-Log "Exécution des tests d'intégration..." -Level "INFO"
& $integrationTestScript -OutputPath $integrationPath
$integrationTestResult = $LASTEXITCODE

# Générer un rapport global
$reportPath = Join-Path -Path $OutputPath -ChildPath "TestSuiteReport.md"
$reportContent = @"
# Rapport de la suite de tests

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

| Type de test | Résultat |
|--------------|----------|
| Tests unitaires | $(if ($allTestsResult -eq 0) { "✅ Réussi" } else { "❌ Échoué" }) |
| Couverture de code | $(if ($codeCoverageResult -eq 0) { "✅ Réussi" } else { "❌ Échoué" }) |
| Tests d'intégration | $(if ($integrationTestResult -eq 0) { "✅ Réussi" } else { "❌ Échoué" }) |
| **Résultat global** | $(if (($allTestsResult -eq 0) -and ($codeCoverageResult -eq 0) -and ($integrationTestResult -eq 0)) { "✅ Réussi" } else { "❌ Échoué" }) |

## Détails

### Tests unitaires

Les tests unitaires vérifient le bon fonctionnement de chaque composant de la solution d'organisation des scripts.

- Rapport XML: [TestResults.xml]($testsPath/TestResults.xml)
$(if ($GenerateHTML) { "- Rapport HTML: [TestResults.html]($testsPath/TestResults.html)" })

### Couverture de code

La couverture de code mesure le pourcentage de code couvert par les tests unitaires.

- Rapport XML: [Coverage.xml]($coveragePath/Coverage.xml)
$(if ($GenerateHTML) { "- Rapport HTML: [Coverage.html]($coveragePath/Coverage.html)" })

### Tests d'intégration

Les tests d'intégration vérifient que tous les composants fonctionnent correctement ensemble.

- Journal: [integration_test.log]($integrationPath/integration_test.log)

## Conclusion

$(if (($allTestsResult -eq 0) -and ($codeCoverageResult -eq 0) -and ($integrationTestResult -eq 0)) {
    "Tous les tests ont réussi. La solution d'organisation des scripts fonctionne correctement."
} else {
    "Certains tests ont échoué. Veuillez consulter les rapports détaillés pour plus d'informations."
})
"@

Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
Write-Log "Rapport global généré: $reportPath" -Level "SUCCESS"

# Afficher un résumé
Write-Log "`nRésumé de la suite de tests:" -Level "INFO"
Write-Log "  Tests unitaires: $(if ($allTestsResult -eq 0) { "Réussi" } else { "Échoué" })" -Level $(if ($allTestsResult -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Couverture de code: $(if ($codeCoverageResult -eq 0) { "Réussi" } else { "Échoué" })" -Level $(if ($codeCoverageResult -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests d'intégration: $(if ($integrationTestResult -eq 0) { "Réussi" } else { "Échoué" })" -Level $(if ($integrationTestResult -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Résultat global: $(if (($allTestsResult -eq 0) -and ($codeCoverageResult -eq 0) -and ($integrationTestResult -eq 0)) { "Réussi" } else { "Échoué" })" -Level $(if (($allTestsResult -eq 0) -and ($codeCoverageResult -eq 0) -and ($integrationTestResult -eq 0)) { "SUCCESS" } else { "ERROR" })

# Retourner le code de sortie en fonction des résultats
if (($allTestsResult -eq 0) -and ($codeCoverageResult -eq 0) -and ($integrationTestResult -eq 0)) {
    Write-Log "`nTous les tests ont réussi!" -Level "SUCCESS"
    exit 0
}
else {
    Write-Log "`nCertains tests ont échoué. Veuillez consulter les rapports pour plus de détails." -Level "ERROR"
    exit 1
}
