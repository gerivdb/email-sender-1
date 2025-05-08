# Tests pour le script de rapport de comparaison des noyaux
# Run with Pester: Invoke-Pester -Path ".\KernelComparisonReport.Tests.ps1"

# Importer le script à tester
$scriptPath = Split-Path -Parent $PSScriptRoot
$scriptToTest = Join-Path -Path $scriptPath -ChildPath "KernelComparisonReport.ps1"

Describe "Tests pour KernelComparisonReport.ps1" {
    Context "Tests de base" {
        BeforeAll {
            # Créer un répertoire temporaire pour les rapports
            $tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
            New-Item -Path $tempDir -ItemType Directory | Out-Null
            
            # Sauvegarder le répertoire courant
            $originalLocation = Get-Location
            
            # Se déplacer dans le répertoire temporaire
            Set-Location -Path $tempDir
        }
        
        AfterAll {
            # Revenir au répertoire d'origine
            Set-Location -Path $originalLocation
            
            # Supprimer le répertoire temporaire
            if (Test-Path -Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }
        }
        
        It "Le script devrait s'exécuter sans erreur avec les paramètres par défaut" {
            # Exécuter le script avec des paramètres minimaux pour accélérer les tests
            { & $scriptToTest -DataSizes @(10) -IncludePerformanceTests -IncludePrecisionTests:$false } | Should -Not -Throw
        }
        
        It "Le script devrait générer un rapport au format texte" {
            # Exécuter le script avec le format texte
            & $scriptToTest -OutputFormat Text -DataSizes @(10) -IncludePerformanceTests -IncludePrecisionTests:$false
            
            # Vérifier que le rapport a été généré
            $reportPath = Join-Path -Path $scriptPath -ChildPath "reports\kernel_comparison_report.text"
            Test-Path -Path $reportPath | Should -Be $true
        }
        
        It "Le script devrait générer un rapport au format HTML" {
            # Exécuter le script avec le format HTML
            & $scriptToTest -OutputFormat HTML -DataSizes @(10) -IncludePerformanceTests -IncludePrecisionTests:$false
            
            # Vérifier que le rapport a été généré
            $reportPath = Join-Path -Path $scriptPath -ChildPath "reports\kernel_comparison_report.html"
            Test-Path -Path $reportPath | Should -Be $true
        }
        
        It "Le script devrait générer un rapport au format JSON" {
            # Exécuter le script avec le format JSON
            & $scriptToTest -OutputFormat JSON -DataSizes @(10) -IncludePerformanceTests -IncludePrecisionTests:$false
            
            # Vérifier que le rapport a été généré
            $reportPath = Join-Path -Path $scriptPath -ChildPath "reports\kernel_comparison_report.json"
            Test-Path -Path $reportPath | Should -Be $true
        }
        
        It "Le script devrait générer un rapport au format CSV" {
            # Exécuter le script avec le format CSV
            & $scriptToTest -OutputFormat CSV -DataSizes @(10) -IncludePerformanceTests -IncludePrecisionTests:$false
            
            # Vérifier que le rapport a été généré
            $reportPath = Join-Path -Path $scriptPath -ChildPath "reports\kernel_comparison_report.csv"
            Test-Path -Path $reportPath | Should -Be $true
        }
    }
    
    Context "Tests des fonctions utilitaires" {
        BeforeAll {
            # Charger les fonctions du script
            . $scriptToTest
        }
        
        It "Get-NormalSample devrait générer un échantillon de la taille spécifiée" {
            $sample = Get-NormalSample -NumPoints 100 -Mean 0 -StdDev 1
            
            $sample | Should -Not -BeNullOrEmpty
            $sample.Count | Should -Be 100
        }
        
        It "Get-NormalDensity devrait calculer la densité correctement" {
            $density = Get-NormalDensity -X 0 -Mean 0 -StdDev 1
            
            $density | Should -BeOfType [double]
            $density | Should -BeApproximately 0.3989 0.0001
        }
        
        It "Get-MeanSquaredError devrait calculer l'erreur quadratique moyenne correctement" {
            $density1 = @(1, 2, 3)
            $density2 = @(2, 3, 4)
            
            $mse = Get-MeanSquaredError -Density1 $density1 -Density2 $density2
            
            $mse | Should -BeOfType [double]
            $mse | Should -Be 1
        }
    }
    
    Context "Tests des fonctions de rapport" {
        BeforeAll {
            # Charger les fonctions du script
            . $scriptToTest
            
            # Créer des données de test
            $performanceResults = @{
                10 = @{
                    "Gaussian" = @{
                        ExecutionTime = 10
                        Density = 0.1
                    }
                    "Epanechnikov" = @{
                        ExecutionTime = 5
                        Density = 0.2
                    }
                }
                100 = @{
                    "Gaussian" = @{
                        ExecutionTime = 100
                        Density = 0.1
                    }
                    "Epanechnikov" = @{
                        ExecutionTime = 50
                        Density = 0.2
                    }
                }
            }
            
            $precisionResults = @{
                "Gaussian" = @{
                    MSE = 0.01
                    Densities = @(0.1, 0.2, 0.3)
                    EvaluationPoints = @(-1, 0, 1)
                }
                "Epanechnikov" = @{
                    MSE = 0.02
                    Densities = @(0.2, 0.3, 0.4)
                    EvaluationPoints = @(-1, 0, 1)
                }
            }
        }
        
        It "Get-TextReport devrait générer un rapport au format texte" {
            $report = Get-TextReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -BeOfType [string]
            $report | Should -Match "Rapport de comparaison des noyaux"
            $report | Should -Match "Tests de performance"
            $report | Should -Match "Tests de précision"
        }
        
        It "Get-HtmlReport devrait générer un rapport au format HTML" {
            $report = Get-HtmlReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -BeOfType [string]
            $report | Should -Match "<!DOCTYPE html>"
            $report | Should -Match "<title>Rapport de comparaison des noyaux"
            $report | Should -Match "<h2>Tests de performance</h2>"
            $report | Should -Match "<h2>Tests de précision</h2>"
        }
        
        It "Get-JsonReport devrait générer un rapport au format JSON" {
            $report = Get-JsonReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -BeOfType [string]
            
            # Vérifier que le rapport est un JSON valide
            { $report | ConvertFrom-Json } | Should -Not -Throw
            
            # Vérifier que le JSON contient les données attendues
            $json = $report | ConvertFrom-Json
            $json.Performance | Should -Not -BeNullOrEmpty
            $json.Precision | Should -Not -BeNullOrEmpty
        }
        
        It "Get-CsvReport devrait générer un rapport au format CSV" {
            $report = Get-CsvReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -BeOfType [string]
            $report | Should -Match "DataSize,KernelType,ExecutionTime,MSE"
            $report | Should -Match "10,Gaussian,10,0.01"
            $report | Should -Match "10,Epanechnikov,5,0.02"
            $report | Should -Match "100,Gaussian,100,0.01"
            $report | Should -Match "100,Epanechnikov,50,0.02"
        }
    }
}
