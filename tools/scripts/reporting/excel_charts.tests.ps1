<#
.SYNOPSIS
    Tests unitaires pour le module de création de graphiques Excel.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module excel_charts.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers les modules à tester
$ExporterPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_exporter.ps1"
$ChartsPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_charts.ps1"

# Exécuter les tests
Describe "Excel Charts Module Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "excel_charts_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null

        # Importer les modules à tester
        . $ExporterPath
        . $ChartsPath

        # Créer un exporteur Excel
        $script:Exporter = New-ExcelExporter

        # Créer un classeur de test
        $script:WorkbookPath = Join-Path -Path $script:TestDir -ChildPath "charts_test.xlsx"
        $script:WorkbookId = New-ExcelWorkbook -Exporter $script:Exporter -Path $script:WorkbookPath

        # Créer une feuille de test
        $script:WorksheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "TestCharts"

        # Ajouter des données de test
        $TestData = @(
            [PSCustomObject]@{
                Month  = "Janvier"
                Sales  = 1200
                Costs  = 800
                Profit = 400
            },
            [PSCustomObject]@{
                Month  = "Février"
                Sales  = 1500
                Costs  = 900
                Profit = 600
            },
            [PSCustomObject]@{
                Month  = "Mars"
                Sales  = 1300
                Costs  = 850
                Profit = 450
            },
            [PSCustomObject]@{
                Month  = "Avril"
                Sales  = 1700
                Costs  = 950
                Profit = 750
            },
            [PSCustomObject]@{
                Month  = "Mai"
                Sales  = 1900
                Costs  = 1000
                Profit = 900
            },
            [PSCustomObject]@{
                Month  = "Juin"
                Sales  = 2100
                Costs  = 1100
                Profit = 1000
            }
        )

        Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId | Out-Null
    }

    AfterAll {
        # Fermer le classeur
        Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
    }

    Context "New-ExcelLineChart function" {
        It "Should create a line chart with default settings" {
            $ChartName = New-ExcelLineChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:D7" -ChartName "TestLineChart" -Title "Test Line Chart" -XAxisTitle "Month" -YAxisTitle "Value" -Position "F1:L15"

            $ChartName | Should -Be "TestLineChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a line chart with custom configuration" {
            $Config = [ExcelLineChartConfig]::new("Custom Line Chart")
            $Config.ShowMarkers = $true
            $Config.MarkerStyle = [ExcelMarkerStyle]::Diamond
            $Config.LineWidth = 3
            $Config.SmoothLines = $true
            $Config.ShowTrendline = $true
            $Config.ShowEquation = $true

            $ChartName = New-ExcelLineChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:B7" -ChartName "CustomLineChart" -XAxisTitle "Month" -YAxisTitle "Sales" -Position "F16:L30" -Config $Config

            $ChartName | Should -Be "CustomLineChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelBarChart function" {
        It "Should create a column chart with default settings" {
            $ChartName = New-ExcelBarChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:D7" -ChartName "TestColumnChart" -Title "Test Column Chart" -XAxisTitle "Month" -YAxisTitle "Value" -Position "M1:S15" -IsHorizontal $false

            $ChartName | Should -Be "TestColumnChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a bar chart with custom configuration" {
            $Config = [ExcelBarChartConfig]::new("Custom Bar Chart")
            $Config.IsHorizontal = $true
            $Config.IsStacked = $true
            $Config.ShowValues = $true
            $Config.ShowPercentages = $false

            $ChartName = New-ExcelBarChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:D7" -ChartName "CustomBarChart" -XAxisTitle "Value" -YAxisTitle "Month" -Position "M16:S30" -Config $Config

            $ChartName | Should -Be "CustomBarChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "Set-ExcelChartAxes function" {
        It "Should configure chart axes with custom settings" {
            # Créer un graphique de test
            $ChartName = New-ExcelLineChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:B7" -ChartName "AxesTestChart" -Title "Axes Test Chart" -Position "A31:G45"

            # Configurer les axes
            $XAxisConfig = [ExcelAxisConfig]::new("Mois")
            $XAxisConfig.LabelRotation = 45
            $XAxisConfig.FontBold = $true

            $YAxisConfig = [ExcelAxisConfig]::new("Ventes")
            $YAxisConfig.Min = 0
            $YAxisConfig.Max = 2500
            $YAxisConfig.MajorUnit = 500
            $YAxisConfig.FontSize = 12
            $YAxisConfig.FontColor = "#0000FF"

            { Set-ExcelChartAxes -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $ChartName -XAxisConfig $XAxisConfig -YAxisConfig $YAxisConfig } | Should -Not -Throw

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "Add-ExcelChartTrendline function" {
        It "Should add a linear trendline to a chart series" {
            # Créer un graphique de test
            $ChartName = New-ExcelLineChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:B7" -ChartName "TrendlineTestChart" -Title "Trendline Test Chart" -Position "H31:N45"

            # Configurer la ligne de tendance
            $TrendlineConfig = [ExcelTrendlineConfig]::new([ExcelTrendlineType]::Linear)
            $TrendlineConfig.ShowEquation = $true
            $TrendlineConfig.ShowRSquared = $true
            $TrendlineConfig.Name = "Tendance linéaire"
            $TrendlineConfig.Color = "#FF0000"
            $TrendlineConfig.LineWidth = 2

            { Add-ExcelChartTrendline -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $ChartName -SeriesIndex 0 -TrendlineConfig $TrendlineConfig } | Should -Not -Throw

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "Add-ExcelChartReferenceLine function" {
        It "Should add a horizontal reference line to a chart" {
            # Créer un graphique de test
            $ChartName = New-ExcelLineChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:B7" -ChartName "ReferenceLineTestChart" -Title "Reference Line Test Chart" -Position "O31:U45"

            { Add-ExcelChartReferenceLine -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $ChartName -Value 1500 -IsHorizontal $true -Label "Objectif" -Color "#FF0000" -LineWidth 2 -LineStyle ([ExcelLineStyle]::Dash) } | Should -Not -Throw

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelPieChart function" {
        It "Should create a pie chart with default settings" {
            # Créer des données de test pour le graphique circulaire
            $PieData = @(
                [PSCustomObject]@{
                    Category = "Produit A"
                    Value    = 35
                },
                [PSCustomObject]@{
                    Category = "Produit B"
                    Value    = 25
                },
                [PSCustomObject]@{
                    Category = "Produit C"
                    Value    = 20
                },
                [PSCustomObject]@{
                    Category = "Produit D"
                    Value    = 15
                },
                [PSCustomObject]@{
                    Category = "Produit E"
                    Value    = 5
                }
            )

            # Ajouter les données à une nouvelle feuille
            $PieSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "PieData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $PieSheetId -Data $PieData

            # Créer le graphique circulaire
            $ChartName = New-ExcelPieChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $PieSheetId -DataRange "A1:B6" -ChartName "TestPieChart" -Title "Test Pie Chart" -Position "D1:J15"

            $ChartName | Should -Be "TestPieChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a doughnut chart with custom configuration" {
            # Utiliser les données de la feuille PieData
            $PieSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["PieData"].Index

            # Créer une configuration personnalisée
            $Config = [ExcelPieChartConfig]::new("Graphique en anneau")
            $Config.IsDoughnut = $true
            $Config.DoughnutHoleSize = 60
            $Config.ShowPercentages = $true
            $Config.ShowLabels = $true
            $Config.ShowValues = $false
            $Config.ExplodeAllSlices = $true
            $Config.ExplodeDistance = 15

            # Créer le graphique en anneau
            $ChartName = New-ExcelPieChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $PieSheetId -DataRange "A1:B6" -ChartName "TestDoughnutChart" -Position "D16:J30" -Config $Config

            $ChartName | Should -Be "TestDoughnutChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "Group-ExcelPieChartSmallValues function" {
        It "Should group small values in a pie chart" {
            # Utiliser les données de la feuille PieData
            $PieSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["PieData"].Index

            # Créer un graphique circulaire
            $ChartName = New-ExcelPieChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $PieSheetId -DataRange "A1:B6" -ChartName "GroupTestChart" -Title "Group Test Chart" -Position "K1:Q15"

            # Regrouper les petites valeurs
            { Group-ExcelPieChartSmallValues -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $PieSheetId -ChartName $ChartName -Threshold 10.0 -GroupLabel "Autres produits" -GroupColor "#CCCCCC" } | Should -Not -Throw

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelComboChart function" {
        It "Should create a combo chart with line and column series" {
            # Créer des données de test pour le graphique combiné
            $ComboData1 = @(
                [PSCustomObject]@{
                    Month = "Janvier"
                    Sales = 1200
                },
                [PSCustomObject]@{
                    Month = "Février"
                    Sales = 1500
                },
                [PSCustomObject]@{
                    Month = "Mars"
                    Sales = 1300
                },
                [PSCustomObject]@{
                    Month = "Avril"
                    Sales = 1700
                }
            )

            $ComboData2 = @(
                [PSCustomObject]@{
                    Month  = "Janvier"
                    Profit = 400
                },
                [PSCustomObject]@{
                    Month  = "Février"
                    Profit = 600
                },
                [PSCustomObject]@{
                    Month  = "Mars"
                    Profit = 450
                },
                [PSCustomObject]@{
                    Month  = "Avril"
                    Profit = 750
                }
            )

            # Ajouter les données à une nouvelle feuille
            $ComboSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "ComboData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $ComboSheetId -Data $ComboData1 -StartCell "A1"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $ComboSheetId -Data $ComboData2 -StartCell "D1"

            # Créer la configuration du graphique combiné
            $Config = [ExcelComboChartConfig]::new("Ventes et Profits")
            $Config.AddSeries([ExcelChartType]::Column, $false)
            $Config.AddSeries([ExcelChartType]::Line, $true)

            # Créer le graphique combiné
            $DataRanges = @("A1:B5", "D1:E5")
            $ChartName = New-ExcelComboChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $ComboSheetId -DataRanges $DataRanges -ChartName "TestComboChart" -Title "Ventes et Profits" -XAxisTitle "Mois" -PrimaryYAxisTitle "Ventes" -SecondaryYAxisTitle "Profits" -Position "G1:M15" -Config $Config

            $ChartName | Should -Be "TestComboChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelBubbleChart function" {
        It "Should create a bubble chart with custom configuration" {
            # Créer des données de test pour le graphique à bulles
            $BubbleData = @(
                [PSCustomObject]@{
                    Product = "Produit A"
                    Price   = 100
                    Sales   = 500
                    Market  = 25
                },
                [PSCustomObject]@{
                    Product = "Produit B"
                    Price   = 150
                    Sales   = 300
                    Market  = 15
                },
                [PSCustomObject]@{
                    Product = "Produit C"
                    Price   = 80
                    Sales   = 700
                    Market  = 35
                },
                [PSCustomObject]@{
                    Product = "Produit D"
                    Price   = 200
                    Sales   = 200
                    Market  = 10
                }
            )

            # Ajouter les données à une nouvelle feuille
            $BubbleSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "BubbleData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $BubbleSheetId -Data $BubbleData

            # Créer la configuration du graphique à bulles
            $Config = [ExcelBubbleChartConfig]::new("Analyse des produits")
            $Config.MinBubbleSize = 10
            $Config.MaxBubbleSize = 40
            $Config.ShowLabels = $true
            $Config.TransparentBubbles = $true
            $Config.BubbleTransparency = 30

            # Créer le graphique à bulles
            $ChartName = New-ExcelBubbleChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $BubbleSheetId -DataRange "A1:D5" -ChartName "TestBubbleChart" -Title "Analyse des produits" -XAxisTitle "Prix" -YAxisTitle "Ventes" -BubbleSizeTitle "Part de marché" -Position "F1:L15" -Config $Config

            $ChartName | Should -Be "TestBubbleChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelAreaChart function" {
        It "Should create an area chart with default settings" {
            # Créer des données de test pour le graphique en aires
            $AreaData = @(
                [PSCustomObject]@{
                    Month    = "Janvier"
                    Product1 = 100
                    Product2 = 150
                    Product3 = 80
                },
                [PSCustomObject]@{
                    Month    = "Février"
                    Product1 = 120
                    Product2 = 130
                    Product3 = 90
                },
                [PSCustomObject]@{
                    Month    = "Mars"
                    Product1 = 140
                    Product2 = 120
                    Product3 = 100
                },
                [PSCustomObject]@{
                    Month    = "Avril"
                    Product1 = 160
                    Product2 = 140
                    Product3 = 110
                }
            )

            # Ajouter les données à une nouvelle feuille
            $AreaSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "AreaData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $AreaSheetId -Data $AreaData

            # Créer le graphique en aires
            $ChartName = New-ExcelAreaChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $AreaSheetId -DataRange "A1:D5" -ChartName "TestAreaChart" -Title "Évolution des ventes" -XAxisTitle "Mois" -YAxisTitle "Ventes" -Position "F1:L15"

            $ChartName | Should -Be "TestAreaChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a stacked area chart" {
            # Utiliser les données de la feuille AreaData
            $AreaSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["AreaData"].Index

            # Créer le graphique en aires empilées
            $ChartName = New-ExcelAreaChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $AreaSheetId -DataRange "A1:D5" -ChartName "TestStackedAreaChart" -Title "Ventes empilées" -XAxisTitle "Mois" -YAxisTitle "Ventes" -Position "F16:L30" -IsStacked $true

            $ChartName | Should -Be "TestStackedAreaChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelRadarChart function" {
        It "Should create a radar chart with default settings" {
            # Créer des données de test pour le graphique radar
            $RadarData = @(
                [PSCustomObject]@{
                    Category = "Performance"
                    Product1 = 8
                    Product2 = 6
                    Product3 = 9
                },
                [PSCustomObject]@{
                    Category = "Prix"
                    Product1 = 7
                    Product2 = 9
                    Product3 = 5
                },
                [PSCustomObject]@{
                    Category = "Qualité"
                    Product1 = 9
                    Product2 = 7
                    Product3 = 8
                },
                [PSCustomObject]@{
                    Category = "Support"
                    Product1 = 6
                    Product2 = 8
                    Product3 = 7
                },
                [PSCustomObject]@{
                    Category = "Innovation"
                    Product1 = 8
                    Product2 = 5
                    Product3 = 9
                }
            )

            # Ajouter les données à une nouvelle feuille
            $RadarSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "RadarData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $RadarSheetId -Data $RadarData

            # Créer le graphique radar
            $ChartName = New-ExcelRadarChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $RadarSheetId -DataRange "A1:D6" -ChartName "TestRadarChart" -Title "Comparaison des produits" -Position "F1:L15"

            $ChartName | Should -Be "TestRadarChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a filled radar chart" {
            # Utiliser les données de la feuille RadarData
            $RadarSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["RadarData"].Index

            # Créer le graphique radar rempli
            $ChartName = New-ExcelRadarChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $RadarSheetId -DataRange "A1:D6" -ChartName "TestFilledRadarChart" -Title "Comparaison des produits (rempli)" -Position "F16:L30" -IsFilled $true

            $ChartName | Should -Be "TestFilledRadarChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelWaterfallChart function" {
        It "Should create a waterfall chart with default settings" {
            # Créer des données de test pour le graphique en cascade
            $WaterfallData = @(
                [PSCustomObject]@{
                    Category = "Début"
                    Value    = 1000
                },
                [PSCustomObject]@{
                    Category = "Ventes"
                    Value    = 500
                },
                [PSCustomObject]@{
                    Category = "Coûts"
                    Value    = -300
                },
                [PSCustomObject]@{
                    Category = "Taxes"
                    Value    = -100
                },
                [PSCustomObject]@{
                    Category = "Fin"
                    Value    = 1100
                }
            )

            # Ajouter les données à une nouvelle feuille
            $WaterfallSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "WaterfallData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $WaterfallSheetId -Data $WaterfallData

            # Créer le graphique en cascade
            $ChartName = New-ExcelWaterfallChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $WaterfallSheetId -DataRange "A1:B6" -ChartName "TestWaterfallChart" -Title "Analyse des profits" -XAxisTitle "Catégorie" -YAxisTitle "Montant" -Position "F1:L15" -TotalIndices @(0, 4)

            $ChartName | Should -Be "TestWaterfallChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a waterfall chart with custom configuration" {
            # Utiliser les données de la feuille WaterfallData
            $WaterfallSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["WaterfallData"].Index

            # Créer une configuration personnalisée
            $Config = [ExcelWaterfallChartConfig]::new("Analyse des profits (personnalisé)")
            $Config.PositiveColor = "#00B050"
            $Config.NegativeColor = "#FF0000"
            $Config.TotalColor = "#4472C4"
            $Config.TotalIndices = @(0, 4)
            $Config.ShowValues = $true
            $Config.ShowLabels = $true
            $Config.GapWidth = 200

            # Créer le graphique en cascade
            $ChartName = New-ExcelWaterfallChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $WaterfallSheetId -DataRange "A1:B6" -ChartName "TestCustomWaterfallChart" -Position "F16:L30" -Config $Config

            $ChartName | Should -Be "TestCustomWaterfallChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelFunnelChart function" {
        It "Should create a funnel chart with default settings" {
            # Créer des données de test pour le graphique en entonnoir
            $FunnelData = @(
                [PSCustomObject]@{
                    Stage = "Prospects"
                    Count = 1000
                },
                [PSCustomObject]@{
                    Stage = "Contacts qualifiés"
                    Count = 750
                },
                [PSCustomObject]@{
                    Stage = "Opportunités"
                    Count = 500
                },
                [PSCustomObject]@{
                    Stage = "Propositions"
                    Count = 300
                },
                [PSCustomObject]@{
                    Stage = "Contrats"
                    Count = 150
                }
            )

            # Ajouter les données à une nouvelle feuille
            $FunnelSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "FunnelData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $FunnelSheetId -Data $FunnelData

            # Créer le graphique en entonnoir
            $ChartName = New-ExcelFunnelChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $FunnelSheetId -DataRange "A1:B6" -ChartName "TestFunnelChart" -Title "Processus de vente" -Position "F1:L15"

            $ChartName | Should -Be "TestFunnelChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a funnel chart with custom configuration" {
            # Utiliser les données de la feuille FunnelData
            $FunnelSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["FunnelData"].Index

            # Créer une configuration personnalisée
            $Config = [ExcelFunnelChartConfig]::new("Processus de vente (personnalisé)")
            $Config.ShowPercentages = $true
            $Config.ShowLabels = $true
            $Config.ShowValues = $true
            $Config.GradientFill = $true
            $Config.StartColor = "#4472C4"
            $Config.EndColor = "#A5A5A5"

            # Créer le graphique en entonnoir
            $ChartName = New-ExcelFunnelChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $FunnelSheetId -DataRange "A1:B6" -ChartName "TestCustomFunnelChart" -Position "F16:L30" -Config $Config

            $ChartName | Should -Be "TestCustomFunnelChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelGaugeChart function" {
        It "Should create a gauge chart with default settings" {
            # Créer une feuille pour le test
            $GaugeSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "GaugeData"

            # Créer le graphique de type jauge
            $ChartName = New-ExcelGaugeChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $GaugeSheetId -Value 75 -ChartName "TestGaugeChart" -Title "Performance" -Position "F1:L15"

            $ChartName | Should -Be "TestGaugeChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a gauge chart with custom configuration" {
            # Utiliser la feuille GaugeData
            $GaugeSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["GaugeData"].Index

            # Créer une configuration personnalisée
            $Config = [ExcelGaugeChartConfig]::new("Performance (personnalisé)", 65)
            $Config.Thresholds = @(30, 70)
            $Config.ZoneColors = @("#FF0000", "#FFBF00", "#00B050")
            $Config.ShowValue = $true
            $Config.ValueSuffix = "%"
            $Config.ValueFontSize = 24
            $Config.GaugeThickness = 40
            $Config.StartAngle = 180
            $Config.EndAngle = 0

            # Créer le graphique de type jauge
            $ChartName = New-ExcelGaugeChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $GaugeSheetId -ChartName "TestCustomGaugeChart" -Position "F16:L30" -Config $Config

            $ChartName | Should -Be "TestCustomGaugeChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }

    Context "New-ExcelBoxPlotChart function" {
        It "Should create a box plot chart with default settings" {
            # Créer des données de test pour le graphique de type boîte à moustaches
            $BoxPlotData = @(
                [PSCustomObject]@{
                    Category = "Catégorie"
                    Serie1   = "Série 1"
                    Serie2   = "Série 2"
                    Serie3   = "Série 3"
                },
                [PSCustomObject]@{
                    Category = "Valeur 1"
                    Serie1   = 10
                    Serie2   = 15
                    Serie3   = 8
                },
                [PSCustomObject]@{
                    Category = "Valeur 2"
                    Serie1   = 12
                    Serie2   = 18
                    Serie3   = 9
                },
                [PSCustomObject]@{
                    Category = "Valeur 3"
                    Serie1   = 15
                    Serie2   = 20
                    Serie3   = 12
                },
                [PSCustomObject]@{
                    Category = "Valeur 4"
                    Serie1   = 18
                    Serie2   = 22
                    Serie3   = 14
                },
                [PSCustomObject]@{
                    Category = "Valeur 5"
                    Serie1   = 20
                    Serie2   = 25
                    Serie3   = 16
                },
                [PSCustomObject]@{
                    Category = "Valeur 6"
                    Serie1   = 22
                    Serie2   = 28
                    Serie3   = 18
                },
                [PSCustomObject]@{
                    Category = "Valeur 7"
                    Serie1   = 25
                    Serie2   = 30
                    Serie3   = 20
                },
                [PSCustomObject]@{
                    Category = "Valeur 8"
                    Serie1   = 28
                    Serie2   = 35
                    Serie3   = 22
                },
                [PSCustomObject]@{
                    Category = "Valeur 9"
                    Serie1   = 30
                    Serie2   = 40
                    Serie3   = 25
                },
                [PSCustomObject]@{
                    Category = "Valeur 10"
                    Serie1   = 35
                    Serie2   = 45
                    Serie3   = 30
                }
            )

            # Ajouter les données à une nouvelle feuille
            $BoxPlotSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "BoxPlotData"
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $BoxPlotSheetId -Data $BoxPlotData

            # Créer le graphique de type boîte à moustaches
            $ChartName = New-ExcelBoxPlotChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $BoxPlotSheetId -DataRange "A1:D11" -ChartName "TestBoxPlotChart" -Title "Distribution des valeurs" -XAxisTitle "Séries" -YAxisTitle "Valeurs" -Position "F1:L15"

            $ChartName | Should -Be "TestBoxPlotChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }

        It "Should create a box plot chart with custom configuration" {
            # Utiliser les données de la feuille BoxPlotData
            $BoxPlotSheetId = $script:Exporter._workbooks[$script:WorkbookId].Worksheets["BoxPlotData"].Index

            # Créer une configuration personnalisée
            $Config = [ExcelBoxPlotChartConfig]::new("Distribution des valeurs (personnalisé)")
            $Config.ShowOutliers = $true
            $Config.ShowMedian = $true
            $Config.ShowMean = $true
            $Config.ShowStatistics = $true
            $Config.BoxColor = "#4472C4"
            $Config.WhiskerColor = "#000000"
            $Config.MedianColor = "#FF9900"
            $Config.MeanColor = "#00B050"
            $Config.OutlierColor = "#FF0000"
            $Config.BoxWidth = 60
            $Config.ValueFormat = "#,##0.00"

            # Créer le graphique de type boîte à moustaches
            $ChartName = New-ExcelBoxPlotChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $BoxPlotSheetId -DataRange "A1:D11" -ChartName "TestCustomBoxPlotChart" -Position "F16:L30" -Config $Config

            $ChartName | Should -Be "TestCustomBoxPlotChart"

            # Vérifier que le fichier a été créé
            Test-Path -Path $script:WorkbookPath | Should -Be $true
        }
    }
}

# Ne pas exécuter les tests automatiquement à la fin du script
# Pour exécuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\excel_charts.tests.ps1 -Output Detailed
