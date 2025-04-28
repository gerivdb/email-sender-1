<#
.SYNOPSIS
    Tests unitaires pour le script de gÃ©nÃ©ration de graphiques de tendances.
.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    du script trend_charts.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le script Ã  tester
$ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "trend_charts.ps1"

# CrÃ©er des donnÃ©es de test
function New-TestData {
    param (
        [string]$OutputPath,
        [string]$MetricType
    )

    # CrÃ©er le rÃ©pertoire de donnÃ©es de test
    $DataDir = Join-Path -Path $OutputPath -ChildPath "data/performance"
    New-Item -Path $DataDir -ItemType Directory -Force | Out-Null

    # CrÃ©er un fichier CSV de test
    $CsvPath = Join-Path -Path $DataDir -ChildPath "${MetricType}_metrics.csv"

    $Data = @()
    $StartDate = (Get-Date).AddDays(-7)

    # GÃ©nÃ©rer des donnÃ©es pour 3 mÃ©triques diffÃ©rentes
    foreach ($Metric in @("CPU", "Memory", "Disk")) {
        for ($i = 0; $i -lt 24; $i++) {
            $Timestamp = $StartDate.AddHours($i)
            $Value = Get-Random -Minimum 0 -Maximum 100

            $Data += [PSCustomObject]@{
                Timestamp = $Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                Metric    = $Metric
                Value     = $Value
            }
        }
    }

    $Data | Export-Csv -Path $CsvPath -NoTypeInformation

    return $DataDir
}

# CrÃ©er des templates de test
function New-TestTemplates {
    param (
        [string]$OutputPath
    )

    # CrÃ©er le rÃ©pertoire de templates de test
    $TemplatesDir = Join-Path -Path $OutputPath -ChildPath "templates/charts"
    New-Item -Path $TemplatesDir -ItemType Directory -Force | Out-Null

    # CrÃ©er un fichier JSON de templates de test
    $JsonPath = Join-Path -Path $TemplatesDir -ChildPath "chartdevelopment/templates.json"

    $Templates = @{
        templates = @(
            @{
                id          = "line"
                name        = "Line Chart"
                description = "Line chart for time series data"
                type        = "line"
                options     = @{
                    xAxis   = @{
                        type  = "time"
                        title = "Time"
                    }
                    yAxis   = @{
                        title = "Value"
                    }
                    legend  = @{
                        position = "bottom"
                    }
                    tooltip = @{
                        show   = $true
                        format = "{value} at {time}"
                    }
                    colors  = @("#1f77b4", "#ff7f0e", "#2ca02c")
                }
            },
            @{
                id          = "area"
                name        = "Area Chart"
                description = "Area chart for time series data"
                type        = "area"
                options     = @{
                    xAxis   = @{
                        type  = "time"
                        title = "Time"
                    }
                    yAxis   = @{
                        title = "Value"
                    }
                    legend  = @{
                        position = "bottom"
                    }
                    tooltip = @{
                        show   = $true
                        format = "{value} at {time}"
                    }
                    colors  = @("#1f77b4", "#ff7f0e", "#2ca02c")
                    opacity = 0.7
                }
            }
        )
    }

    $Templates | ConvertTo-Json -Depth 10 | Out-File -FilePath $JsonPath -Encoding UTF8

    return $TemplatesDir
}

# ExÃ©cuter les tests
Describe "Trend Charts Script Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $TestDir = Join-Path -Path $TestDrive -ChildPath "trend_charts_tests"
        New-Item -Path $TestDir -ItemType Directory -Force | Out-Null

        # CrÃ©er des donnÃ©es et templates de test
        $script:DataPath = New-TestData -OutputPath $TestDir -MetricType "system"
        $script:TemplatesPath = New-TestTemplates -OutputPath $TestDir
        $script:TemplatesFile = Join-Path -Path $TemplatesPath -ChildPath "chartdevelopment/templates.json"

        # CrÃ©er un rÃ©pertoire de sortie pour les graphiques
        $OutputPath = Join-Path -Path $TestDir -ChildPath "output/charts"
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    Context "Import-ChartTemplates function" {
        It "Should import chart templates correctly" {
            # Dot-source le script pour accÃ©der aux fonctions
            . $ScriptPath

            $Templates = Import-ChartTemplates -TemplatesPath $TemplatesFile

            $Templates | Should -Not -BeNullOrEmpty
            $Templates.Count | Should -Be 2
            $Templates[0].id | Should -Be "line"
            $Templates[1].id | Should -Be "area"
        }

        It "Should return null for non-existent template file" {
            # Dot-source le script pour accÃ©der aux fonctions
            . $ScriptPath

            $Templates = Import-ChartTemplates -TemplatesPath "non_existent_file.json"

            $Templates | Should -BeNullOrEmpty
        }
    }

    Context "Import-PerformanceData function" {
        It "Should import performance data correctly" {
            # Dot-source le script pour accÃ©der aux fonctions
            . $ScriptPath

            $StartDate = (Get-Date).AddDays(-7)
            $EndDate = (Get-Date)

            $Data = Import-PerformanceData -DataPath $DataPath -MetricType "system" -StartDate $StartDate -EndDate $EndDate

            $Data | Should -Not -BeNullOrEmpty
            $Data.Count | Should -BeGreaterThan 0
            $Data[0].Metric | Should -BeIn @("CPU", "Memory", "Disk")
        }

        It "Should return null for non-existent data file" {
            # Dot-source le script pour accÃ©der aux fonctions
            . $ScriptPath

            $StartDate = (Get-Date).AddDays(-7)
            $EndDate = (Get-Date)

            $Data = Import-PerformanceData -DataPath $DataPath -MetricType "non_existent" -StartDate $StartDate -EndDate $EndDate

            $Data | Should -BeNullOrEmpty
        }
    }

    Context "New-TrendChart function" {
        It "Should generate a chart configuration file" {
            # Dot-source le script pour accÃ©der aux fonctions
            . $ScriptPath

            $StartDate = (Get-Date).AddDays(-7)
            $EndDate = (Get-Date)

            $Data = Import-PerformanceData -DataPath $DataPath -MetricType "system" -StartDate $StartDate -EndDate $EndDate
            $Templates = Import-ChartTemplates -TemplatesPath $TemplatesFile

            $MetricData = $Data | Where-Object { $_.Metric -eq "CPU" }
            $Template = $Templates | Where-Object { $_.type -eq "line" } | Select-Object -First 1

            $ChartOutputPath = Join-Path -Path $OutputPath -ChildPath "test_chart.json"
            $Result = New-TrendChart -Data $MetricData -Template $Template -OutputPath $ChartOutputPath -MetricName "CPU" -Title "CPU Usage"

            $Result | Should -Be $true
            Test-Path -Path $ChartOutputPath | Should -Be $true

            $ChartConfig = Get-Content -Path $ChartOutputPath -Raw | ConvertFrom-Json
            $ChartConfig.type | Should -Be "line"
            $ChartConfig.data.datasets[0].label | Should -Be "CPU"
        }
    }

    Context "New-HtmlChart function" {
        It "Should generate an HTML file for the chart" {
            # Dot-source le script pour accÃ©der aux fonctions
            . $ScriptPath

            $StartDate = (Get-Date).AddDays(-7)
            $EndDate = (Get-Date)

            $Data = Import-PerformanceData -DataPath $DataPath -MetricType "system" -StartDate $StartDate -EndDate $EndDate
            $Templates = Import-ChartTemplates -TemplatesPath $TemplatesFile

            $MetricData = $Data | Where-Object { $_.Metric -eq "CPU" }
            $Template = $Templates | Where-Object { $_.type -eq "line" } | Select-Object -First 1

            $ChartOutputPath = Join-Path -Path $OutputPath -ChildPath "test_chart.json"
            New-TrendChart -Data $MetricData -Template $Template -OutputPath $ChartOutputPath -MetricName "CPU" -Title "CPU Usage"

            $HtmlOutputPath = Join-Path -Path $OutputPath -ChildPath "test_chart.html"
            $Result = New-HtmlChart -ChartConfigPath $ChartOutputPath -OutputPath $HtmlOutputPath -Title "CPU Usage"

            $Result | Should -Be $true
            Test-Path -Path $HtmlOutputPath | Should -Be $true

            $HtmlContent = Get-Content -Path $HtmlOutputPath -Raw
            $HtmlContent | Should -Match "<title>CPU Usage</title>"
            $HtmlContent | Should -Match "<canvas id=`"chart`"></canvas>"
        }
    }

    Context "Start-TrendChartGeneration function" {
        It "Should generate charts for all metrics and types" {
            # Dot-source le script pour accÃ©der aux fonctions
            . $ScriptPath

            $StartDate = (Get-Date).AddDays(-7)
            $EndDate = (Get-Date)
            $Templates = Import-ChartTemplates -TemplatesPath $TemplatesFile

            $Result = Start-TrendChartGeneration -DataPath $DataPath -OutputPath $OutputPath -Templates $Templates -ChartType "all" -MetricType "system" -StartDate $StartDate -EndDate $EndDate

            $Result | Should -Be $true

            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $ChartFiles = Get-ChildItem -Path $OutputPath -Filter "*.json"
            $ChartFiles.Count | Should -BeGreaterThan 0

            $HtmlFiles = Get-ChildItem -Path $OutputPath -Filter "*.html"
            $HtmlFiles.Count | Should -BeGreaterThan 0
        }
    }
}

# Ne pas exÃ©cuter les tests automatiquement Ã  la fin du script
# Pour exÃ©cuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\trend_charts.tests.ps1 -Output Detailed
