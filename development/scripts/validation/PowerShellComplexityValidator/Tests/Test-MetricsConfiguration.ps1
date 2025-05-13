#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module MetricsConfiguration.
.DESCRIPTION
    Ce script teste les fonctionnalités du module MetricsConfiguration
    pour la validation de la complexité du code PowerShell.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée pour des tests complets."
    Write-Warning "Exécution des tests en mode basique."
    $usePester = $false
}
else {
    Import-Module -Name Pester -Force
    $usePester = $true
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\MetricsConfiguration.psm1'

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module MetricsConfiguration.psm1 n'existe pas au chemin spécifié: $modulePath"
}

# Importer le module à tester
Import-Module -Name $modulePath -Force

# Créer un dossier temporaire pour les tests
$tempDir = Join-Path -Path $PSScriptRoot -ChildPath 'temp'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Verbose "Dossier temporaire créé : $tempDir"
}

# Chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $tempDir -ChildPath 'TestComplexityMetrics.json'

# Fonction pour exécuter les tests sans Pester
function Invoke-BasicTests {
    [CmdletBinding()]
    param()

    $testsPassed = 0
    $testsFailed = 0
    $totalTests = 0

    function Test-Case {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true)]
            [scriptblock]$Test
        )
        
        $totalTests++
        Write-Host "Test: $Name" -ForegroundColor Cyan
        
        try {
            $result = & $Test
            if ($result) {
                Write-Host "  Réussi" -ForegroundColor Green
                $script:testsPassed++
            }
            else {
                Write-Host "  Échoué" -ForegroundColor Red
                $script:testsFailed++
            }
        }
        catch {
            Write-Host "  Erreur: $_" -ForegroundColor Red
            $script:testsFailed++
        }
    }

    # Test 1: Vérifier que le module est chargé
    Test-Case -Name "Le module est chargé" -Test {
        $null -ne (Get-Module -Name "MetricsConfiguration")
    }

    # Test 2: Vérifier que les fonctions sont exportées
    Test-Case -Name "Les fonctions sont exportées" -Test {
        $expectedFunctions = @(
            "Import-ComplexityMetricsConfiguration",
            "Test-ComplexityMetricsConfiguration",
            "Get-ComplexityMetricsConfiguration",
            "Set-ComplexityMetricsThreshold",
            "Export-ComplexityMetricsConfiguration"
        )
        
        $exportedFunctions = (Get-Module -Name "MetricsConfiguration").ExportedFunctions.Keys
        
        $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $exportedFunctions }
        
        if ($missingFunctions.Count -gt 0) {
            Write-Host "  Fonctions manquantes: $($missingFunctions -join ', ')" -ForegroundColor Yellow
            return $false
        }
        
        return $true
    }

    # Test 3: Vérifier que la configuration par défaut peut être chargée
    Test-Case -Name "La configuration par défaut peut être chargée" -Test {
        $config = Get-ComplexityMetricsConfiguration
        return $null -ne $config
    }

    # Test 4: Vérifier que la configuration contient les métriques requises
    Test-Case -Name "La configuration contient les métriques requises" -Test {
        $config = Get-ComplexityMetricsConfiguration
        
        $requiredMetrics = @(
            "CyclomaticComplexity",
            "NestingDepth",
            "FunctionLength",
            "ParameterCount"
        )
        
        $missingMetrics = $requiredMetrics | Where-Object {
            -not (Get-Member -InputObject $config.ComplexityMetrics -Name $_ -MemberType Properties)
        }
        
        if ($missingMetrics.Count -gt 0) {
            Write-Host "  Métriques manquantes: $($missingMetrics -join ', ')" -ForegroundColor Yellow
            return $false
        }
        
        return $true
    }

    # Test 5: Vérifier que les seuils peuvent être modifiés
    Test-Case -Name "Les seuils peuvent être modifiés" -Test {
        $originalValue = (Get-ComplexityMetricsConfiguration).ComplexityMetrics.CyclomaticComplexity.Thresholds.Medium.Value
        $newValue = $originalValue + 5
        
        $result = Set-ComplexityMetricsThreshold -MetricName "CyclomaticComplexity" -ThresholdName "Medium" -Value $newValue
        
        $updatedValue = (Get-ComplexityMetricsConfiguration).ComplexityMetrics.CyclomaticComplexity.Thresholds.Medium.Value
        
        return $result -and ($updatedValue -eq $newValue)
    }

    # Test 6: Vérifier que la configuration peut être exportée
    Test-Case -Name "La configuration peut être exportée" -Test {
        $result = Export-ComplexityMetricsConfiguration -OutputPath $testConfigPath
        
        return $result -and (Test-Path -Path $testConfigPath)
    }

    # Test 7: Vérifier que la configuration exportée peut être importée
    Test-Case -Name "La configuration exportée peut être importée" -Test {
        $config = Import-ComplexityMetricsConfiguration -ConfigPath $testConfigPath
        
        return $null -ne $config
    }

    # Afficher le résumé des tests
    Write-Host "`nRésumé des tests:" -ForegroundColor Yellow
    Write-Host "  Tests réussis: $testsPassed" -ForegroundColor Green
    Write-Host "  Tests échoués: $testsFailed" -ForegroundColor Red
    Write-Host "  Total des tests: $totalTests" -ForegroundColor Cyan
    
    return $testsFailed -eq 0
}

# Fonction pour exécuter les tests avec Pester
function Invoke-PesterTests {
    [CmdletBinding()]
    param()

    Describe "Module MetricsConfiguration" {
        Context "Chargement du module" {
            It "Le module est chargé" {
                Get-Module -Name "MetricsConfiguration" | Should -Not -BeNullOrEmpty
            }
            
            It "Les fonctions sont exportées" {
                $expectedFunctions = @(
                    "Import-ComplexityMetricsConfiguration",
                    "Test-ComplexityMetricsConfiguration",
                    "Get-ComplexityMetricsConfiguration",
                    "Set-ComplexityMetricsThreshold",
                    "Export-ComplexityMetricsConfiguration"
                )
                
                $exportedFunctions = (Get-Module -Name "MetricsConfiguration").ExportedFunctions.Keys
                
                foreach ($function in $expectedFunctions) {
                    $exportedFunctions | Should -Contain $function
                }
            }
        }
        
        Context "Fonctionnalités de base" {
            It "La configuration par défaut peut être chargée" {
                $config = Get-ComplexityMetricsConfiguration
                $config | Should -Not -BeNullOrEmpty
            }
            
            It "La configuration contient les métriques requises" {
                $config = Get-ComplexityMetricsConfiguration
                
                $requiredMetrics = @(
                    "CyclomaticComplexity",
                    "NestingDepth",
                    "FunctionLength",
                    "ParameterCount"
                )
                
                foreach ($metric in $requiredMetrics) {
                    $config.ComplexityMetrics | Get-Member -Name $metric -MemberType Properties | Should -Not -BeNullOrEmpty
                }
            }
        }
        
        Context "Modification et exportation" {
            It "Les seuils peuvent être modifiés" {
                $originalValue = (Get-ComplexityMetricsConfiguration).ComplexityMetrics.CyclomaticComplexity.Thresholds.Medium.Value
                $newValue = $originalValue + 5
                
                $result = Set-ComplexityMetricsThreshold -MetricName "CyclomaticComplexity" -ThresholdName "Medium" -Value $newValue
                
                $result | Should -BeTrue
                
                $updatedValue = (Get-ComplexityMetricsConfiguration).ComplexityMetrics.CyclomaticComplexity.Thresholds.Medium.Value
                $updatedValue | Should -Be $newValue
            }
            
            It "La configuration peut être exportée" {
                $result = Export-ComplexityMetricsConfiguration -OutputPath $testConfigPath
                
                $result | Should -BeTrue
                Test-Path -Path $testConfigPath | Should -BeTrue
            }
            
            It "La configuration exportée peut être importée" {
                $config = Import-ComplexityMetricsConfiguration -ConfigPath $testConfigPath
                
                $config | Should -Not -BeNullOrEmpty
            }
        }
    }
}

# Exécuter les tests
if ($usePester) {
    Invoke-PesterTests
}
else {
    Invoke-BasicTests
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

Write-Host "`nTests terminés." -ForegroundColor Yellow
