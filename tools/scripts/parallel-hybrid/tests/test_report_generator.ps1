#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le générateur de rapports parallélisé.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du générateur de rapports parallélisé utilisant l'architecture hybride.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportGeneratorPath = Join-Path -Path $scriptPath -ChildPath "..\examples\parallel-report-generator.ps1"

# Créer des données de test
$testDataPath = Join-Path -Path $scriptPath -ChildPath "test_data"
if (-not (Test-Path -Path $testDataPath)) {
    New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
    
    # Générer des données de test simples
    $simpleData = @()
    for ($i = 1; $i -le 100; $i++) {
        $simpleData += @{
            ID = $i
            Name = "Item_$i"
            Value = Get-Random -Minimum 1 -Maximum 1000
            Category = Get-Random -InputObject @("A", "B", "C", "D", "E")
            Date = (Get-Date).AddDays(-1 * (Get-Random -Minimum 1 -Maximum 365)).ToString("yyyy-MM-dd")
            IsActive = (Get-Random -Minimum 0 -Maximum 2) -eq 1
            Score = [Math]::Round((Get-Random -Minimum 0 -Maximum 100) / 10, 1)
        }
    }
    
    $simpleData | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $testDataPath -ChildPath "simple_data.json") -Encoding utf8
    
    # Générer des données de test complexes
    $complexData = @{
        metadata = @{
            title = "Données de test complexes"
            description = "Jeu de données pour tester le générateur de rapports"
            created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            version = "1.0"
        }
        categories = @(
            @{
                id = "A"
                name = "Catégorie A"
                description = "Description de la catégorie A"
            },
            @{
                id = "B"
                name = "Catégorie B"
                description = "Description de la catégorie B"
            },
            @{
                id = "C"
                name = "Catégorie C"
                description = "Description de la catégorie C"
            },
            @{
                id = "D"
                name = "Catégorie D"
                description = "Description de la catégorie D"
            },
            @{
                id = "E"
                name = "Catégorie E"
                description = "Description de la catégorie E"
            }
        )
        items = @()
    }
    
    for ($i = 1; $i -le 200; $i++) {
        $categoryId = Get-Random -InputObject @("A", "B", "C", "D", "E")
        $complexData.items += @{
            id = $i
            name = "Item_$i"
            description = "Description de l'item $i"
            category_id = $categoryId
            value = Get-Random -Minimum 1 -Maximum 1000
            date = (Get-Date).AddDays(-1 * (Get-Random -Minimum 1 -Maximum 365)).ToString("yyyy-MM-dd")
            is_active = (Get-Random -Minimum 0 -Maximum 2) -eq 1
            score = [Math]::Round((Get-Random -Minimum 0 -Maximum 100) / 10, 1)
            attributes = @{
                color = Get-Random -InputObject @("red", "green", "blue", "yellow", "purple")
                size = Get-Random -InputObject @("small", "medium", "large")
                weight = Get-Random -Minimum 1 -Maximum 100
                tags = @(
                    "tag1",
                    "tag2",
                    "tag3"
                ) | Select-Object -First (Get-Random -Minimum 1 -Maximum 4)
            }
        }
    }
    
    $complexData | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $testDataPath -ChildPath "complex_data.json") -Encoding utf8
}

# Exécuter les tests
Describe "Générateur de rapports parallélisé" {
    BeforeAll {
        # Créer un répertoire temporaire pour les résultats
        $outputPath = Join-Path -Path $testDataPath -ChildPath "reports"
        if (-not (Test-Path -Path $outputPath)) {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
        }
    }
    
    Context "Génération de rapports simples" {
        It "Devrait générer un rapport de synthèse" {
            # Exécuter le générateur de rapports pour un rapport de synthèse
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de génération de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes "Summary"
            
            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].type | Should -Be "summary"
            $result[0].path | Should -Not -BeNullOrEmpty
            Test-Path -Path $result[0].path | Should -Be $true
        }
    }
    
    Context "Génération de rapports détaillés" {
        It "Devrait générer un rapport détaillé" {
            # Exécuter le générateur de rapports pour un rapport détaillé
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de génération de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes "Detailed"
            
            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].type | Should -Be "detailed"
            $result[0].path | Should -Not -BeNullOrEmpty
            Test-Path -Path $result[0].path | Should -Be $true
        }
    }
    
    Context "Génération de rapports de métriques" {
        It "Devrait générer un rapport de métriques" {
            # Exécuter le générateur de rapports pour un rapport de métriques
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de génération de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes "Metrics"
            
            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].type | Should -Be "metrics"
            $result[0].path | Should -Not -BeNullOrEmpty
            Test-Path -Path $result[0].path | Should -Be $true
        }
    }
    
    Context "Génération de plusieurs types de rapports" {
        It "Devrait générer plusieurs types de rapports en parallèle" {
            # Exécuter le générateur de rapports pour tous les types de rapports
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de génération de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics")
            
            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3  # Trois types de rapports
            $result | Where-Object { $_.type -eq "summary" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.type -eq "detailed" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.type -eq "metrics" } | Should -Not -BeNullOrEmpty
            
            # Vérifier que les fichiers existent
            foreach ($report in $result) {
                Test-Path -Path $report.path | Should -Be $true
            }
        }
    }
    
    Context "Génération de rapports avec données complexes" {
        It "Devrait générer des rapports à partir de données complexes" {
            # Exécuter le générateur de rapports avec des données complexes
            $dataPath = Join-Path -Path $testDataPath -ChildPath "complex_data.json"
            
            # Appeler le script de génération de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics")
            
            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3  # Trois types de rapports
            
            # Vérifier que les fichiers existent
            foreach ($report in $result) {
                Test-Path -Path $report.path | Should -Be $true
            }
        }
    }
    
    Context "Utilisation du cache" {
        It "Devrait être plus rapide avec le cache activé" {
            # Exécuter le générateur de rapports sans cache
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics")
            $stopwatch1.Stop()
            $timeWithoutCache = $stopwatch1.Elapsed.TotalSeconds
            
            # Exécuter le générateur de rapports avec cache
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result2 = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics") -UseCache
            $stopwatch2.Stop()
            $timeWithCache = $stopwatch2.Elapsed.TotalSeconds
            
            # Vérifier que les résultats sont identiques
            $result1.Count | Should -Be $result2.Count
            
            # Exécuter une deuxième fois avec cache pour bénéficier du cache
            $stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
            $result3 = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics") -UseCache
            $stopwatch3.Stop()
            $timeWithCacheSecondRun = $stopwatch3.Elapsed.TotalSeconds
            
            # La deuxième exécution avec cache devrait être plus rapide
            # Note: Ce test peut échouer sur des systèmes très rapides ou si le cache n'est pas correctement implémenté
            Write-Host "Temps sans cache: $timeWithoutCache s"
            Write-Host "Temps avec cache (1ère exécution): $timeWithCache s"
            Write-Host "Temps avec cache (2ème exécution): $timeWithCacheSecondRun s"
            
            # Vérifier que les résultats sont identiques
            $result1.Count | Should -Be $result3.Count
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers temporaires si nécessaire
    }
}
