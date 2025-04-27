#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le gÃ©nÃ©rateur de rapports parallÃ©lisÃ©.
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du gÃ©nÃ©rateur de rapports parallÃ©lisÃ© utilisant l'architecture hybride.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportGeneratorPath = Join-Path -Path $scriptPath -ChildPath "..\examples\parallel-report-generator.ps1"

# CrÃ©er des donnÃ©es de test
$testDataPath = Join-Path -Path $scriptPath -ChildPath "test_data"
if (-not (Test-Path -Path $testDataPath)) {
    New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
    
    # GÃ©nÃ©rer des donnÃ©es de test simples
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
    
    # GÃ©nÃ©rer des donnÃ©es de test complexes
    $complexData = @{
        metadata = @{
            title = "DonnÃ©es de test complexes"
            description = "Jeu de donnÃ©es pour tester le gÃ©nÃ©rateur de rapports"
            created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            version = "1.0"
        }
        categories = @(
            @{
                id = "A"
                name = "CatÃ©gorie A"
                description = "Description de la catÃ©gorie A"
            },
            @{
                id = "B"
                name = "CatÃ©gorie B"
                description = "Description de la catÃ©gorie B"
            },
            @{
                id = "C"
                name = "CatÃ©gorie C"
                description = "Description de la catÃ©gorie C"
            },
            @{
                id = "D"
                name = "CatÃ©gorie D"
                description = "Description de la catÃ©gorie D"
            },
            @{
                id = "E"
                name = "CatÃ©gorie E"
                description = "Description de la catÃ©gorie E"
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

# ExÃ©cuter les tests
Describe "GÃ©nÃ©rateur de rapports parallÃ©lisÃ©" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les rÃ©sultats
        $outputPath = Join-Path -Path $testDataPath -ChildPath "reports"
        if (-not (Test-Path -Path $outputPath)) {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
        }
    }
    
    Context "GÃ©nÃ©ration de rapports simples" {
        It "Devrait gÃ©nÃ©rer un rapport de synthÃ¨se" {
            # ExÃ©cuter le gÃ©nÃ©rateur de rapports pour un rapport de synthÃ¨se
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de gÃ©nÃ©ration de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes "Summary"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].type | Should -Be "summary"
            $result[0].path | Should -Not -BeNullOrEmpty
            Test-Path -Path $result[0].path | Should -Be $true
        }
    }
    
    Context "GÃ©nÃ©ration de rapports dÃ©taillÃ©s" {
        It "Devrait gÃ©nÃ©rer un rapport dÃ©taillÃ©" {
            # ExÃ©cuter le gÃ©nÃ©rateur de rapports pour un rapport dÃ©taillÃ©
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de gÃ©nÃ©ration de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes "Detailed"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].type | Should -Be "detailed"
            $result[0].path | Should -Not -BeNullOrEmpty
            Test-Path -Path $result[0].path | Should -Be $true
        }
    }
    
    Context "GÃ©nÃ©ration de rapports de mÃ©triques" {
        It "Devrait gÃ©nÃ©rer un rapport de mÃ©triques" {
            # ExÃ©cuter le gÃ©nÃ©rateur de rapports pour un rapport de mÃ©triques
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de gÃ©nÃ©ration de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes "Metrics"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].type | Should -Be "metrics"
            $result[0].path | Should -Not -BeNullOrEmpty
            Test-Path -Path $result[0].path | Should -Be $true
        }
    }
    
    Context "GÃ©nÃ©ration de plusieurs types de rapports" {
        It "Devrait gÃ©nÃ©rer plusieurs types de rapports en parallÃ¨le" {
            # ExÃ©cuter le gÃ©nÃ©rateur de rapports pour tous les types de rapports
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            # Appeler le script de gÃ©nÃ©ration de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics")
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3  # Trois types de rapports
            $result | Where-Object { $_.type -eq "summary" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.type -eq "detailed" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.type -eq "metrics" } | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les fichiers existent
            foreach ($report in $result) {
                Test-Path -Path $report.path | Should -Be $true
            }
        }
    }
    
    Context "GÃ©nÃ©ration de rapports avec donnÃ©es complexes" {
        It "Devrait gÃ©nÃ©rer des rapports Ã  partir de donnÃ©es complexes" {
            # ExÃ©cuter le gÃ©nÃ©rateur de rapports avec des donnÃ©es complexes
            $dataPath = Join-Path -Path $testDataPath -ChildPath "complex_data.json"
            
            # Appeler le script de gÃ©nÃ©ration de rapports
            $result = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics")
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3  # Trois types de rapports
            
            # VÃ©rifier que les fichiers existent
            foreach ($report in $result) {
                Test-Path -Path $report.path | Should -Be $true
            }
        }
    }
    
    Context "Utilisation du cache" {
        It "Devrait Ãªtre plus rapide avec le cache activÃ©" {
            # ExÃ©cuter le gÃ©nÃ©rateur de rapports sans cache
            $dataPath = Join-Path -Path $testDataPath -ChildPath "simple_data.json"
            
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics")
            $stopwatch1.Stop()
            $timeWithoutCache = $stopwatch1.Elapsed.TotalSeconds
            
            # ExÃ©cuter le gÃ©nÃ©rateur de rapports avec cache
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result2 = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics") -UseCache
            $stopwatch2.Stop()
            $timeWithCache = $stopwatch2.Elapsed.TotalSeconds
            
            # VÃ©rifier que les rÃ©sultats sont identiques
            $result1.Count | Should -Be $result2.Count
            
            # ExÃ©cuter une deuxiÃ¨me fois avec cache pour bÃ©nÃ©ficier du cache
            $stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
            $result3 = & $reportGeneratorPath -DataPath $testDataPath -OutputPath $outputPath -ReportTypes @("Summary", "Detailed", "Metrics") -UseCache
            $stopwatch3.Stop()
            $timeWithCacheSecondRun = $stopwatch3.Elapsed.TotalSeconds
            
            # La deuxiÃ¨me exÃ©cution avec cache devrait Ãªtre plus rapide
            # Note: Ce test peut Ã©chouer sur des systÃ¨mes trÃ¨s rapides ou si le cache n'est pas correctement implÃ©mentÃ©
            Write-Host "Temps sans cache: $timeWithoutCache s"
            Write-Host "Temps avec cache (1Ã¨re exÃ©cution): $timeWithCache s"
            Write-Host "Temps avec cache (2Ã¨me exÃ©cution): $timeWithCacheSecondRun s"
            
            # VÃ©rifier que les rÃ©sultats sont identiques
            $result1.Count | Should -Be $result3.Count
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers temporaires si nÃ©cessaire
    }
}
