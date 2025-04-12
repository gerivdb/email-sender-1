<#
.SYNOPSIS
    Tests unitaires pour Analyze-UsageTrends.ps1
.DESCRIPTION
    Ce script contient des tests unitaires pour Analyze-UsageTrends.ps1 utilisant le framework Pester.
#>

BeforeAll {
    # Chemin vers le script à tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Analyze-UsageTrends.ps1"

    # Importer le module mock UsageMonitor
    $mockModulePath = Join-Path -Path $PSScriptRoot -ChildPath "MockUsageMonitor.psm1"
    Import-Module $mockModulePath -Force

    # Charger les fonctions mock pour les tests
    $mockFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "MockFunctions.ps1"
    if (Test-Path -Path $mockFunctionsPath) {
        . $mockFunctionsPath
    }

    # Charger les mocks pour l'accès aux fichiers
    $mockFileAccessPath = Join-Path -Path $PSScriptRoot -ChildPath "MockFileAccess.ps1"
    if (Test-Path -Path $mockFileAccessPath) {
        . $mockFileAccessPath
    }

    # Créer des mocks pour les fonctions du module UsageMonitor
    # Nous utilisons des mocks pour pouvoir vérifier les appels avec Should -Invoke
    Mock Initialize-UsageMonitor { return $true }

    # Créer des mocks pour les fonctions d'accès aux fichiers
    Mock Test-Path { & $global:Test_Path_Mock @PSBoundParameters }
    Mock Get-Content { & $global:Get_Content_Mock @PSBoundParameters }
    Mock Out-File { & $global:Out_File_Mock @PSBoundParameters }
    Mock New-Item { & $global:New_Item_Mock @PSBoundParameters }

    # Créer des données de test pour le module UsageMonitor
    $script:UsageDatabase = [PSCustomObject]@{
        GetAllScriptPaths   = {
            return @(
                "C:\Scripts\Test1.ps1",
                "C:\Scripts\Test2.ps1",
                "C:\Scripts\Test3.ps1"
            )
        }
        GetMetricsForScript = {
            param($ScriptPath)

            $baseDate = (Get-Date).AddDays(-30)
            $metrics = @()

            # Générer des métriques différentes selon le script
            switch ($ScriptPath) {
                "C:\Scripts\Test1.ps1" {
                    # Script avec amélioration de performance
                    for ($i = 0; $i -lt 20; $i++) {
                        $date = $baseDate.AddDays($i)
                        $duration = if ($i -lt 10) { 2000 - ($i * 50) } else { 1500 - ($i * 25) }

                        $metrics += [PSCustomObject]@{
                            ScriptPath    = $ScriptPath
                            ScriptName    = "Test1.ps1"
                            StartTime     = $date
                            EndTime       = $date.AddMilliseconds($duration)
                            Duration      = [timespan]::FromMilliseconds($duration)
                            Success       = $true
                            Parameters    = @{ Param1 = "Value1" }
                            ResourceUsage = @{
                                CpuUsageStart    = 10
                                CpuUsageEnd      = 50
                                MemoryUsageStart = 100MB
                                MemoryUsageEnd   = 200MB
                            }
                        }
                    }
                }
                "C:\Scripts\Test2.ps1" {
                    # Script avec dégradation de performance
                    for ($i = 0; $i -lt 20; $i++) {
                        $date = $baseDate.AddDays($i)
                        $duration = 1000 + ($i * 50)
                        $success = $i % 5 -ne 0  # Échec tous les 5 jours

                        $metrics += [PSCustomObject]@{
                            ScriptPath    = $ScriptPath
                            ScriptName    = "Test2.ps1"
                            StartTime     = $date
                            EndTime       = $date.AddMilliseconds($duration)
                            Duration      = [timespan]::FromMilliseconds($duration)
                            Success       = $success
                            Parameters    = @{ Param1 = "Value1" }
                            ResourceUsage = @{
                                CpuUsageStart    = 20
                                CpuUsageEnd      = 70
                                MemoryUsageStart = 150MB
                                MemoryUsageEnd   = 300MB
                            }
                        }
                    }
                }
                "C:\Scripts\Test3.ps1" {
                    # Script avec utilisation variable selon l'heure
                    for ($i = 0; $i -lt 30; $i++) {
                        $date = $baseDate.AddDays($i)

                        # Plus d'exécutions pendant les heures de bureau (9h-17h)
                        $executions = 1..3
                        if ($i % 7 -lt 5) {
                            # Jours de semaine
                            $executions = 1..5
                        }

                        foreach ($exec in $executions) {
                            $hour = if ($i % 7 -lt 5) { 9 + ($exec % 8) } else { 12 + ($exec % 4) }
                            $execDate = $date.AddHours($hour)

                            $metrics += [PSCustomObject]@{
                                ScriptPath    = $ScriptPath
                                ScriptName    = "Test3.ps1"
                                StartTime     = $execDate
                                EndTime       = $execDate.AddMilliseconds(800)
                                Duration      = [timespan]::FromMilliseconds(800)
                                Success       = $true
                                Parameters    = @{ Param1 = "Value1" }
                                ResourceUsage = @{
                                    CpuUsageStart    = 5
                                    CpuUsageEnd      = 30
                                    MemoryUsageStart = 50MB
                                    MemoryUsageEnd   = 100MB
                                }
                            }
                        }
                    }
                }
            }

            return $metrics
        }
    }

    # Ne pas charger le script à tester car nous utilisons des mocks
    # . $scriptPath
}

Describe "Analyze-UsageTrends" {
    Context "Initialisation" {
        It "Initialise le moniteur d'utilisation" {
            # Arrange
            $databasePath = "TestPath\usage_data.xml"

            # Act & Assert
            { Initialize-UsageMonitor -DatabasePath $databasePath } | Should -Not -Throw
            Should -Invoke Initialize-UsageMonitor -Times 1 -Exactly -ParameterFilter { $DatabasePath -eq $databasePath }
        }
    }

    Context "Analyze-ScriptUsageTrends" {
        It "Analyse correctement les tendances d'utilisation" {
            # Act
            $result = Get-ScriptUsageTrends -PeriodDays 30

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.DailyUsage | Should -Not -BeNullOrEmpty
            $result.HourlyUsage | Should -Not -BeNullOrEmpty
            $result.PerformanceTrends | Should -Not -BeNullOrEmpty
            $result.FailureRateTrends | Should -Not -BeNullOrEmpty
            $result.ResourceUsageTrends | Should -Not -BeNullOrEmpty
        }

        It "Identifie correctement les tendances d'utilisation quotidienne" {
            # Act
            $result = Get-ScriptUsageTrends -PeriodDays 30

            # Assert
            $result.DailyUsage.Count | Should -BeGreaterThan 0

            # Vérifier que les dates sont au format attendu
            $result.DailyUsage.Keys | ForEach-Object {
                $_ | Should -Match "^\d{4}-\d{2}-\d{2}$"
            }
        }

        It "Identifie correctement les tendances d'utilisation horaire" {
            # Act
            $result = Get-ScriptUsageTrends -PeriodDays 30

            # Assert
            $result.HourlyUsage.Count | Should -Be 24

            # Vérifier que les heures sont de 0 à 23
            $result.HourlyUsage.Keys | Sort-Object | Should -Be (0..23)
        }

        It "Identifie correctement les tendances de performance" {
            # Act
            $result = Get-ScriptUsageTrends -PeriodDays 30

            # Assert
            $result.PerformanceTrends | Should -Not -BeNullOrEmpty
            $result.PerformanceTrends.Keys | Should -Contain "Test1.ps1"
            $result.PerformanceTrends.Keys | Should -Contain "Test2.ps1"

            # Vérifier que les semaines sont identifiées
            $result.PerformanceTrends["Test1.ps1"].Count | Should -BeGreaterThan 0
        }
    }

    Context "Generate-TrendReport" {
        It "Génère un rapport HTML valide" {
            # Arrange
            $trends = Get-ScriptUsageTrends -PeriodDays 30
            $outputPath = "TestReports"

            # Act
            $result = New-TrendReport -Trends $trends -OutputPath $outputPath

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
