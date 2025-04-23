<#
.SYNOPSIS
    Tests unitaires pour le script de génération de tableaux de bord.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du script dashboard_generator.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le script à tester
$ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "dashboard_generator.ps1"

# Créer des données de test
function New-TestData {
    param (
        [string]$OutputPath,
        [string]$MetricType
    )
    
    # Créer le répertoire de données de test
    $DataDir = Join-Path -Path $OutputPath -ChildPath "data/performance"
    New-Item -Path $DataDir -ItemType Directory -Force | Out-Null
    
    # Créer un fichier CSV de test
    $CsvPath = Join-Path -Path $DataDir -ChildPath "${MetricType}_metrics.csv"
    
    $Data = @()
    $StartDate = (Get-Date).AddDays(-7)
    
    # Générer des données pour 3 métriques différentes
    $Metrics = switch ($MetricType) {
        "system" { @("CPU", "Memory", "Disk", "Network") }
        "application" { @("ResponseTime", "ErrorRate", "Throughput", "ActiveUsers") }
        "business" { @("EMAIL_DELIVERY_RATE", "EMAIL_OPEN_RATE", "EMAIL_CLICK_RATE", "CONVERSION_RATE") }
        default { @("Metric1", "Metric2", "Metric3") }
    }
    
    foreach ($Metric in $Metrics) {
        for ($i = 0; $i -lt 24; $i++) {
            $Timestamp = $StartDate.AddHours($i)
            $Value = Get-Random -Minimum 0 -Maximum 100
            
            $Data += [PSCustomObject]@{
                Timestamp = $Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                Metric = $Metric
                Value = $Value
            }
        }
    }
    
    $Data | Export-Csv -Path $CsvPath -NoTypeInformation
    
    return $DataDir
}

# Créer des templates de test
function New-TestTemplates {
    param (
        [string]$OutputPath
    )
    
    # Créer le répertoire de templates de test
    $TemplatesDir = Join-Path -Path $OutputPath -ChildPath "templates/dashboards"
    New-Item -Path $TemplatesDir -ItemType Directory -Force | Out-Null
    
    # Créer un fichier JSON de templates de test
    $JsonPath = Join-Path -Path $TemplatesDir -ChildPath "dashboard_templates.json"
    
    $Templates = @{
        templates = @(
            @{
                id = "system_dashboard"
                name = "System Dashboard"
                description = "Dashboard for system metrics"
                layout = @{
                    rows = 2
                    columns = 2
                    panels = @(
                        @{
                            id = "cpu_gauge"
                            title = "CPU Usage"
                            type = "gauge"
                            position = @{
                                row = 0
                                col = 0
                                width = 1
                                height = 1
                            }
                            data_source = "system_metrics"
                            metric = "CPU"
                            options = @{
                                min = 0
                                max = 100
                                unit = "%"
                                thresholds = @(
                                    @{
                                        value = 0
                                        color = "#73BF69"
                                    },
                                    @{
                                        value = 70
                                        color = "#FADE2A"
                                    },
                                    @{
                                        value = 90
                                        color = "#F2495C"
                                    }
                                )
                            }
                        },
                        @{
                            id = "memory_gauge"
                            title = "Memory Usage"
                            type = "gauge"
                            position = @{
                                row = 0
                                col = 1
                                width = 1
                                height = 1
                            }
                            data_source = "system_metrics"
                            metric = "Memory"
                            options = @{
                                min = 0
                                max = 100
                                unit = "%"
                                thresholds = @(
                                    @{
                                        value = 0
                                        color = "#73BF69"
                                    },
                                    @{
                                        value = 70
                                        color = "#FADE2A"
                                    },
                                    @{
                                        value = 90
                                        color = "#F2495C"
                                    }
                                )
                            }
                        },
                        @{
                            id = "cpu_trend"
                            title = "CPU Trend"
                            type = "line"
                            position = @{
                                row = 1
                                col = 0
                                width = 2
                                height = 1
                            }
                            data_source = "system_metrics"
                            metric = "CPU"
                            options = @{
                                time_range = "last_24h"
                                interval = "5m"
                                legend = $true
                                tooltip = $true
                            }
                        }
                    )
                }
            }
        )
    }
    
    $Templates | ConvertTo-Json -Depth 10 | Out-File -FilePath $JsonPath -Encoding UTF8
    
    return $TemplatesDir
}

# Exécuter les tests
Describe "Dashboard Generator Script Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "dashboard_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # Créer des données et templates de test
        $script:DataPath = New-TestData -OutputPath $script:TestDir -MetricType "system"
        $script:TemplatesPath = New-TestTemplates -OutputPath $script:TestDir
        $script:TemplatesFile = Join-Path -Path $script:TemplatesPath -ChildPath "dashboard_templates.json"
        
        # Créer un répertoire de sortie pour les tableaux de bord
        $script:OutputPath = Join-Path -Path $script:TestDir -ChildPath "output/dashboards"
        New-Item -Path $script:OutputPath -ItemType Directory -Force | Out-Null
    }
    
    Context "Import-DashboardTemplates function" {
        It "Should import dashboard templates correctly" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Templates = Import-DashboardTemplates -TemplatesPath $script:TemplatesFile
            
            $Templates | Should -Not -BeNullOrEmpty
            $Templates.Count | Should -Be 1
            $Templates[0].id | Should -Be "system_dashboard"
        }
        
        It "Should return null for non-existent template file" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Templates = Import-DashboardTemplates -TemplatesPath "non_existent_file.json"
            
            $Templates | Should -BeNullOrEmpty
        }
    }
    
    Context "Import-PerformanceData function" {
        It "Should import performance data correctly" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Data = Import-PerformanceData -DataPath $script:DataPath -MetricType "system" -TimeRange "last_day"
            
            $Data | Should -Not -BeNullOrEmpty
            $Data.Count | Should -BeGreaterThan 0
            $Data[0].Metric | Should -BeIn @("CPU", "Memory", "Disk", "Network")
        }
        
        It "Should return null for non-existent data file" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Data = Import-PerformanceData -DataPath $script:DataPath -MetricType "non_existent" -TimeRange "last_day"
            
            $Data | Should -BeNullOrEmpty
        }
    }
    
    Context "New-DashboardPanel function" {
        It "Should generate a gauge panel correctly" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Data = Import-PerformanceData -DataPath $script:DataPath -MetricType "system" -TimeRange "last_day"
            $Templates = Import-DashboardTemplates -TemplatesPath $script:TemplatesFile
            
            $Panel = $Templates[0].layout.panels | Where-Object { $_.type -eq "gauge" -and $_.metric -eq "CPU" } | Select-Object -First 1
            
            $PanelConfig = New-DashboardPanel -Panel $Panel -Data $Data
            
            $PanelConfig | Should -Not -BeNullOrEmpty
            $PanelConfig.id | Should -Be "cpu_gauge"
            $PanelConfig.type | Should -Be "gauge"
            $PanelConfig.value | Should -BeOfType [double]
        }
        
        It "Should generate a line panel correctly" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Data = Import-PerformanceData -DataPath $script:DataPath -MetricType "system" -TimeRange "last_day"
            $Templates = Import-DashboardTemplates -TemplatesPath $script:TemplatesFile
            
            $Panel = $Templates[0].layout.panels | Where-Object { $_.type -eq "line" } | Select-Object -First 1
            
            $PanelConfig = New-DashboardPanel -Panel $Panel -Data $Data
            
            $PanelConfig | Should -Not -BeNullOrEmpty
            $PanelConfig.id | Should -Be "cpu_trend"
            $PanelConfig.type | Should -Be "line"
            $PanelConfig.series | Should -Not -BeNullOrEmpty
            $PanelConfig.series[0].data | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "New-Dashboard function" {
        It "Should generate a dashboard configuration file" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Data = Import-PerformanceData -DataPath $script:DataPath -MetricType "system" -TimeRange "last_day"
            $Templates = Import-DashboardTemplates -TemplatesPath $script:TemplatesFile
            
            $DashboardOutputPath = Join-Path -Path $script:OutputPath -ChildPath "test_dashboard.json"
            $Result = New-Dashboard -Template $Templates[0] -Data $Data -OutputPath $DashboardOutputPath
            
            $Result | Should -Be $true
            Test-Path -Path $DashboardOutputPath | Should -Be $true
            
            $DashboardConfig = Get-Content -Path $DashboardOutputPath -Raw | ConvertFrom-Json
            $DashboardConfig.id | Should -Be "system_dashboard"
            $DashboardConfig.panels.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "New-DashboardHtml function" {
        It "Should generate an HTML file for the dashboard" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Data = Import-PerformanceData -DataPath $script:DataPath -MetricType "system" -TimeRange "last_day"
            $Templates = Import-DashboardTemplates -TemplatesPath $script:TemplatesFile
            
            $DashboardOutputPath = Join-Path -Path $script:OutputPath -ChildPath "test_dashboard.json"
            New-Dashboard -Template $Templates[0] -Data $Data -OutputPath $DashboardOutputPath
            
            $HtmlOutputPath = Join-Path -Path $script:OutputPath -ChildPath "test_dashboard.html"
            $Result = New-DashboardHtml -DashboardConfigPath $DashboardOutputPath -OutputPath $HtmlOutputPath -Title "Test Dashboard"
            
            $Result | Should -Be $true
            Test-Path -Path $HtmlOutputPath | Should -Be $true
            
            $HtmlContent = Get-Content -Path $HtmlOutputPath -Raw
            $HtmlContent | Should -Match "<title>Test Dashboard</title>"
            $HtmlContent | Should -Match "<div class=`"dashboard-grid`">"
        }
    }
    
    Context "Start-DashboardGeneration function" {
        It "Should generate dashboards for the specified type" {
            # Dot-source le script pour accéder aux fonctions
            . $ScriptPath
            
            $Templates = Import-DashboardTemplates -TemplatesPath $script:TemplatesFile
            
            $Result = Start-DashboardGeneration -DataPath $script:DataPath -OutputPath $script:OutputPath -Templates $Templates -DashboardType "system" -TimeRange "last_day"
            
            $Result | Should -Be $true
            
            # Vérifier que les fichiers ont été créés
            $DashboardFile = Join-Path -Path $script:OutputPath -ChildPath "system_dashboard.json"
            Test-Path -Path $DashboardFile | Should -Be $true
            
            $HtmlFile = Join-Path -Path $script:OutputPath -ChildPath "system_dashboard.html"
            Test-Path -Path $HtmlFile | Should -Be $true
        }
    }
}

# Ne pas exécuter les tests automatiquement à la fin du script
# Pour exécuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\dashboard_generator.tests.ps1 -Output Detailed
