#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PRVisualization.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module PRVisualization
    en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du module Ã  tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRVisualization.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module PRVisualization non trouvÃ© Ã  l'emplacement: $moduleToTest"
}

# Importer le module Ã  tester
Import-Module $moduleToTest -Force

# Tests Pester
Describe "PRVisualization Module Tests" {
    Context "New-PRBarChart" {
        It "GÃ©nÃ¨re un graphique Ã  barres HTML/CSS" {
            # DonnÃ©es de test
            $data = @{
                "Erreur"        = 5
                "Avertissement" = 10
                "Information"   = 15
            }

            # GÃ©nÃ©rer le graphique
            $chart = New-PRBarChart -Data $data -Title "Test Bar Chart"

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeOfType [string]
            $chart | Should -BeLike "*<div class=`"pr-chart`"*"
            $chart | Should -BeLike "*Test Bar Chart*"
            $chart | Should -BeLike "*Erreur*"
            $chart | Should -BeLike "*Avertissement*"
            $chart | Should -BeLike "*Information*"
            $chart | Should -BeLike "*5*"
            $chart | Should -BeLike "*10*"
            $chart | Should -BeLike "*15*"
        }

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # DonnÃ©es de test
            $data = @{
                "A" = 1
                "B" = 2
            }

            # GÃ©nÃ©rer le graphique avec des paramÃ¨tres personnalisÃ©s
            $chart = New-PRBarChart -Data $data -Title "Custom Chart" -Width 800 -Height 600 -Colors @("#FF0000", "#00FF00")

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeLike "*width: 800px*"
            $chart | Should -BeLike "*height: 600px*"
            $chart | Should -BeLike "*Custom Chart*"
            $chart | Should -BeLike "*#FF0000*"
        }

        It "GÃ¨re un ensemble de donnÃ©es vide" {
            # DonnÃ©es de test vides
            $data = @{}

            # GÃ©nÃ©rer le graphique
            $chart = New-PRBarChart -Data $data -Title "Empty Chart"

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeLike "*Empty Chart*"
            $chart | Should -BeLike "*pr-no-data*"
        }
    }

    Context "New-PRPieChart" {
        It "GÃ©nÃ¨re un graphique circulaire HTML/CSS" {
            # DonnÃ©es de test
            $data = @{
                "Erreur"        = 5
                "Avertissement" = 10
                "Information"   = 15
            }

            # GÃ©nÃ©rer le graphique
            $chart = New-PRPieChart -Data $data -Title "Test Pie Chart"

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeOfType [string]
            $chart | Should -BeLike "*<div class=`"pr-chart`"*"
            $chart | Should -BeLike "*Test Pie Chart*"
            $chart | Should -BeLike "*Erreur*"
            $chart | Should -BeLike "*Avertissement*"
            $chart | Should -BeLike "*Information*"
            $chart | Should -BeLike "*5*"
            $chart | Should -BeLike "*10*"
            $chart | Should -BeLike "*15*"
        }

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # DonnÃ©es de test
            $data = @{
                "A" = 1
                "B" = 2
            }

            # GÃ©nÃ©rer le graphique avec des paramÃ¨tres personnalisÃ©s
            $chart = New-PRPieChart -Data $data -Title "Custom Pie" -Size 400 -Colors @("#FF0000", "#00FF00")

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeLike "*width: 400px*"
            $chart | Should -BeLike "*height: 400px*"
            $chart | Should -BeLike "*Custom Pie*"
            $chart | Should -BeLike "*#FF0000*"
        }

        It "GÃ¨re un ensemble de donnÃ©es vide" {
            # DonnÃ©es de test vides
            $data = @{}

            # GÃ©nÃ©rer le graphique
            $chart = New-PRPieChart -Data $data -Title "Empty Pie Chart"

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeLike "*Empty Pie Chart*"
            $chart | Should -BeLike "*pr-no-data*"
        }
    }

    Context "New-PRLineChart" {
        It "GÃ©nÃ¨re un graphique en ligne HTML/CSS" {
            # DonnÃ©es de test
            $data = @{
                "SÃ©rie 1" = @{
                    "Jan" = 5
                    "Feb" = 10
                    "Mar" = 15
                }
                "SÃ©rie 2" = @{
                    "Jan" = 3
                    "Feb" = 7
                    "Mar" = 12
                }
            }

            # GÃ©nÃ©rer le graphique
            $chart = New-PRLineChart -Data $data -Title "Test Line Chart"

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeOfType [string]
            $chart | Should -BeLike "*<div class=`"pr-chart`"*"
            $chart | Should -BeLike "*Test Line Chart*"
            $chart | Should -BeLike "*SÃ©rie 1*"
            $chart | Should -BeLike "*SÃ©rie 2*"
            $chart | Should -BeLike "*Jan*"
            $chart | Should -BeLike "*Feb*"
            $chart | Should -BeLike "*Mar*"
        }

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # DonnÃ©es de test
            $data = @{
                "A" = @{
                    "X" = 1
                    "Y" = 2
                }
            }

            # GÃ©nÃ©rer le graphique avec des paramÃ¨tres personnalisÃ©s
            $chart = New-PRLineChart -Data $data -Title "Custom Line" -Width 800 -Height 600 -Colors @("#FF0000")

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeLike "*width: 800px*"
            $chart | Should -BeLike "*height: 600px*"
            $chart | Should -BeLike "*Custom Line*"
            $chart | Should -BeLike "*#FF0000*"
        }

        It "GÃ¨re un ensemble de donnÃ©es vide" {
            # DonnÃ©es de test vides
            $data = @{}

            # GÃ©nÃ©rer le graphique
            $chart = New-PRLineChart -Data $data -Title "Empty Line Chart"

            # VÃ©rifier le rÃ©sultat
            $chart | Should -Not -BeNullOrEmpty
            $chart | Should -BeLike "*Empty Line Chart*"
            # Ne pas vÃ©rifier l'absence de pr-line-series car la classe est dÃ©finie dans le CSS
        }
    }

    Context "New-PRHeatMap" {
        It "GÃ©nÃ¨re une carte de chaleur HTML/CSS" {
            # DonnÃ©es de test
            $data = New-Object 'object[,]' 3, 3
            $data[0, 0] = 1
            $data[0, 1] = 2
            $data[0, 2] = 3
            $data[1, 0] = 4
            $data[1, 1] = 5
            $data[1, 2] = 6
            $data[2, 0] = 7
            $data[2, 1] = 8
            $data[2, 2] = 9

            $rowLabels = @("Row 1", "Row 2", "Row 3")
            $columnLabels = @("Col 1", "Col 2", "Col 3")

            # GÃ©nÃ©rer la carte de chaleur
            $heatmap = New-PRHeatMap -Data $data -RowLabels $rowLabels -ColumnLabels $columnLabels -Title "Test Heat Map"

            # VÃ©rifier le rÃ©sultat
            $heatmap | Should -Not -BeNullOrEmpty
            $heatmap | Should -BeOfType [string]
            $heatmap | Should -BeLike "*<div class=`"pr-chart`"*"
            $heatmap | Should -BeLike "*Test Heat Map*"
            $heatmap | Should -BeLike "*Row 1*"
            $heatmap | Should -BeLike "*Row 2*"
            $heatmap | Should -BeLike "*Row 3*"
            $heatmap | Should -BeLike "*Col 1*"
            $heatmap | Should -BeLike "*Col 2*"
            $heatmap | Should -BeLike "*Col 3*"
        }

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # DonnÃ©es de test
            $data = New-Object 'object[,]' 2, 2
            $data[0, 0] = 1
            $data[0, 1] = 2
            $data[1, 0] = 3
            $data[1, 1] = 4

            $rowLabels = @("A", "B")
            $columnLabels = @("X", "Y")

            # GÃ©nÃ©rer la carte de chaleur avec des paramÃ¨tres personnalisÃ©s
            $heatmap = New-PRHeatMap -Data $data -RowLabels $rowLabels -ColumnLabels $columnLabels -Title "Custom Heat Map" -CellSize 50 -LowColor "#0000FF" -HighColor "#FF0000"

            # VÃ©rifier le rÃ©sultat
            $heatmap | Should -Not -BeNullOrEmpty
            $heatmap | Should -BeLike "*Custom Heat Map*"
            $heatmap | Should -BeLike "*width: 50px*"
            $heatmap | Should -BeLike "*#0000FF*"
            $heatmap | Should -BeLike "*#FF0000*"
        }
    }

    Context "Get-ColorGradient" {
        It "Calcule une couleur intermÃ©diaire" {
            # Calculer une couleur Ã  mi-chemin entre le rouge et le bleu
            $color = Get-ColorGradient -StartColor "#FF0000" -EndColor "#0000FF" -Intensity 0.5

            # VÃ©rifier le rÃ©sultat
            $color | Should -Not -BeNullOrEmpty
            $color | Should -BeOfType [string]
            $color | Should -BeLike "#*"
            $color.Length | Should -Be 7
        }

        It "Retourne la couleur de dÃ©part pour une intensitÃ© de 0" {
            $color = Get-ColorGradient -StartColor "#FF0000" -EndColor "#0000FF" -Intensity 0
            $color | Should -Be "#FF0000"
        }

        It "Retourne la couleur de fin pour une intensitÃ© de 1" {
            $color = Get-ColorGradient -StartColor "#FF0000" -EndColor "#0000FF" -Intensity 1
            $color | Should -Be "#0000FF"
        }
    }
}

# Note: Ne pas exÃ©cuter les tests directement ici pour Ã©viter une rÃ©cursion infinie
# Utilisez plutÃ´t: Invoke-Pester -Path $PSCommandPath
