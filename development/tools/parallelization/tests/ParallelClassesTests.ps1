# Tests unitaires pour les classes du module UnifiedParallel
# Utilise Pester pour les tests unitaires

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$modulePath = Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir les tests
Describe "Classes du module UnifiedParallel" {
    BeforeAll {
        # Initialiser le module avant tous les tests
        Initialize-UnifiedParallel
        
        # Créer des instances des classes pour les tests
        $script:parallelResult = [PSCustomObject]@{
            Value = "Test result"
            Success = $true
            Error = $null
            StartTime = [datetime]::Now
            EndTime = [datetime]::Now.AddSeconds(1)
            Duration = [timespan]::FromSeconds(1)
            ThreadId = 1
            Item = "Test item"
        }
        
        # Créer une erreur pour les tests
        try {
            throw "Test error"
        } catch {
            $script:errorRecord = $_
        }
    }

    AfterAll {
        # Nettoyer après tous les tests
        Clear-UnifiedParallel
    }

    Context "Objets de résultat" {
        It "Crée correctement un objet de résultat" {
            $result = [PSCustomObject]@{
                Value = "Test result"
                Success = $true
                Error = $null
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(1)
                Duration = [timespan]::FromSeconds(1)
                ThreadId = 1
                Item = "Test item"
            }
            
            $result.Value | Should -Be "Test result"
            $result.Success | Should -Be $true
            $result.Error | Should -Be $null
            $result.Duration | Should -Be ([timespan]::FromSeconds(1))
            $result.ThreadId | Should -Be 1
            $result.Item | Should -Be "Test item"
        }
        
        It "Gère correctement les erreurs" {
            $result = [PSCustomObject]@{
                Value = $null
                Success = $false
                Error = $script:errorRecord
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(1)
                Duration = [timespan]::FromSeconds(1)
                ThreadId = 1
                Item = "Test item"
            }
            
            $result.Success | Should -Be $false
            $result.Error | Should -Not -BeNullOrEmpty
            $result.Error.Exception.Message | Should -Be "Test error"
        }
    }
    
    Context "Traitement des résultats" {
        It "Traite correctement une liste de résultats" {
            # Créer une liste de résultats
            $results = New-Object System.Collections.ArrayList
            
            # Ajouter des résultats
            [void]$results.Add([PSCustomObject]@{
                Value = "Test result 1"
                Success = $true
                Error = $null
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(1)
                Duration = [timespan]::FromSeconds(1)
                ThreadId = 1
                Item = "Test item 1"
            })
            
            [void]$results.Add([PSCustomObject]@{
                Value = "Test result 2"
                Success = $true
                Error = $null
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(1)
                Duration = [timespan]::FromSeconds(1)
                ThreadId = 2
                Item = "Test item 2"
            })
            
            [void]$results.Add([PSCustomObject]@{
                Value = $null
                Success = $false
                Error = $script:errorRecord
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(1)
                Duration = [timespan]::FromSeconds(1)
                ThreadId = 3
                Item = "Test item 3"
            })
            
            # Vérifier le traitement
            $successResults = $results | Where-Object { $_.Success }
            $errorResults = $results | Where-Object { -not $_.Success }
            
            $successResults.Count | Should -Be 2
            $errorResults.Count | Should -Be 1
            $successResults[0].Value | Should -Be "Test result 1"
            $successResults[1].Value | Should -Be "Test result 2"
            $errorResults[0].Error.Exception.Message | Should -Be "Test error"
        }
    }
    
    Context "Métriques de performance" {
        It "Calcule correctement les métriques de performance" {
            # Créer une liste de résultats
            $results = New-Object System.Collections.ArrayList
            
            # Ajouter des résultats avec des durées différentes
            [void]$results.Add([PSCustomObject]@{
                Value = "Test result 1"
                Success = $true
                Error = $null
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(1)
                Duration = [timespan]::FromSeconds(1)
                ThreadId = 1
                Item = "Test item 1"
            })
            
            [void]$results.Add([PSCustomObject]@{
                Value = "Test result 2"
                Success = $true
                Error = $null
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(2)
                Duration = [timespan]::FromSeconds(2)
                ThreadId = 2
                Item = "Test item 2"
            })
            
            [void]$results.Add([PSCustomObject]@{
                Value = $null
                Success = $false
                Error = $script:errorRecord
                StartTime = [datetime]::Now
                EndTime = [datetime]::Now.AddSeconds(3)
                Duration = [timespan]::FromSeconds(3)
                ThreadId = 3
                Item = "Test item 3"
            })
            
            # Calculer les métriques
            $totalDuration = [timespan]::FromTicks(($results | ForEach-Object { $_.Duration.Ticks } | Measure-Object -Sum).Sum)
            $avgDuration = [timespan]::FromTicks(($results | ForEach-Object { $_.Duration.Ticks } | Measure-Object -Average).Average)
            $minDuration = [timespan]::FromTicks(($results | ForEach-Object { $_.Duration.Ticks } | Measure-Object -Minimum).Minimum)
            $maxDuration = [timespan]::FromTicks(($results | ForEach-Object { $_.Duration.Ticks } | Measure-Object -Maximum).Maximum)
            
            # Vérifier les métriques
            $totalDuration.TotalSeconds | Should -Be 6
            $avgDuration.TotalSeconds | Should -Be 2
            $minDuration.TotalSeconds | Should -Be 1
            $maxDuration.TotalSeconds | Should -Be 3
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
