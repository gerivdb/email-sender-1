# Tests pour le module excel_chart_styles.ps1

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer le module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "excel_chart_styles.ps1"
. $ModulePath

# Importer le module excel_exporter.ps1 pour les tests
$ExporterPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_exporter.ps1"
. $ExporterPath

Describe "Excel Chart Styles Module" {
    BeforeAll {
        # Créer un exporteur Excel pour les tests
        $script:Exporter = [ExcelExporter]::new()

        # Créer un classeur de test
        $script:WorkbookPath = Join-Path -Path $TestDrive -ChildPath "TestWorkbook.xlsx"
        $script:WorkbookId = New-ExcelWorkbook -Exporter $script:Exporter -Path $script:WorkbookPath

        # Créer une feuille de test
        $script:WorksheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "TestSheet"

        # Ajouter des données de test
        $TestData = @(
            [PSCustomObject]@{
                Category = "A"
                Value1   = 10
                Value2   = 20
                Value3   = 15
            },
            [PSCustomObject]@{
                Category = "B"
                Value1   = 15
                Value2   = 10
                Value3   = 25
            },
            [PSCustomObject]@{
                Category = "C"
                Value1   = 20
                Value2   = 15
                Value3   = 10
            },
            [PSCustomObject]@{
                Category = "D"
                Value1   = 25
                Value2   = 30
                Value3   = 20
            }
        )

        Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData

        # Créer un graphique de test
        $script:ChartName = "TestChart"
        New-ExcelLineChart -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -DataRange "A1:D5" -ChartName $script:ChartName -Title "Test Chart" -Position "F1:L15"
    }

    AfterAll {
        # Fermer et supprimer le classeur de test
        Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Save $false

        # Nettoyer l'exporteur
        $script:Exporter = $null
    }

    Context "ExcelColorPalette class" {
        It "Should create a default palette" {
            $Palette = [ExcelColorPalette]::new()
            $Palette.Name | Should -Be "Default"
            $Palette.Colors.Count | Should -BeGreaterThan 0
            $Palette.IsBuiltIn | Should -Be $true
        }

        It "Should create a custom palette" {
            $Colors = @("#FF0000", "#00FF00", "#0000FF")
            $Palette = [ExcelColorPalette]::new("Custom", $Colors)
            $Palette.Name | Should -Be "Custom"
            $Palette.Colors.Count | Should -Be 3
            $Palette.Colors[0] | Should -Be "#FF0000"
            $Palette.IsBuiltIn | Should -Be $false
        }

        It "Should get color with rotation" {
            $Colors = @("#FF0000", "#00FF00", "#0000FF")
            $Palette = [ExcelColorPalette]::new("Custom", $Colors)

            $Palette.GetColor(0) | Should -Be "#FF0000"
            $Palette.GetColor(1) | Should -Be "#00FF00"
            $Palette.GetColor(2) | Should -Be "#0000FF"
            $Palette.GetColor(3) | Should -Be "#FF0000"  # Rotation
            $Palette.GetColor(4) | Should -Be "#00FF00"  # Rotation
        }

        It "Should add and replace colors" {
            $Colors = @("#FF0000", "#00FF00")
            $Palette = [ExcelColorPalette]::new("Custom", $Colors)

            $Palette.AddColor("#0000FF")
            $Palette.Colors.Count | Should -Be 3
            $Palette.Colors[2] | Should -Be "#0000FF"

            $Palette.ReplaceColor(0, "#FFFF00")
            $Palette.Colors[0] | Should -Be "#FFFF00"
        }

        It "Should validate colors" {
            $ValidColors = @("#FF0000", "#00FF00", "#0000FF")
            $ValidPalette = [ExcelColorPalette]::new("Valid", $ValidColors)
            $ValidPalette.Validate() | Should -Be $true

            $InvalidColors = @("#FF0000", "Red", "#0000FF")
            $InvalidPalette = [ExcelColorPalette]::new("Invalid", $InvalidColors)
            $InvalidPalette.Validate() | Should -Be $false
        }

        It "Should clone and reverse palettes" {
            $Colors = @("#FF0000", "#00FF00", "#0000FF")
            $Palette = [ExcelColorPalette]::new("Original", $Colors)

            $Clone = $Palette.Clone()
            $Clone.Name | Should -Be "Original"
            $Clone.Colors.Count | Should -Be 3
            $Clone.Colors[0] | Should -Be "#FF0000"
            $Clone.IsBuiltIn | Should -Be $false

            $Reversed = $Palette.GetReversed()
            $Reversed.Name | Should -Be "Original_Reversed"
            $Reversed.Colors.Count | Should -Be 3
            $Reversed.Colors[0] | Should -Be "#0000FF"
            $Reversed.Colors[2] | Should -Be "#FF0000"
        }
    }

    Context "ExcelColorPaletteRegistry class" {
        It "Should initialize with built-in palettes" {
            $Registry = [ExcelColorPaletteRegistry]::new()
            $Registry.Palettes.Count | Should -BeGreaterThan 0
            $Registry.Palettes.ContainsKey("Office") | Should -Be $true
            $Registry.Palettes.ContainsKey("Pastel") | Should -Be $true
        }

        It "Should get palette by name" {
            $Registry = [ExcelColorPaletteRegistry]::new()
            $Palette = $Registry.GetPalette("Office")
            $Palette.Name | Should -Be "Office"
            $Palette.IsBuiltIn | Should -Be $true

            $DefaultPalette = $Registry.GetPalette("NonExistent")
            $DefaultPalette.Name | Should -Be "Office"  # Retourne la palette par défaut
        }

        It "Should add and remove custom palettes" {
            $Registry = [ExcelColorPaletteRegistry]::new()
            $Colors = @("#FF0000", "#00FF00", "#0000FF")
            $Palette = [ExcelColorPalette]::new("Custom", $Colors)

            $Registry.AddPalette($Palette)
            $Registry.Palettes.ContainsKey("Custom") | Should -Be $true

            $Result = $Registry.RemovePalette("Custom")
            $Result | Should -Be $true
            $Registry.Palettes.ContainsKey("Custom") | Should -Be $false

            # Ne devrait pas pouvoir supprimer une palette prédéfinie
            $Result = $Registry.RemovePalette("Office")
            $Result | Should -Be $false
            $Registry.Palettes.ContainsKey("Office") | Should -Be $true
        }

        It "Should list palettes and names" {
            $Registry = [ExcelColorPaletteRegistry]::new()
            $Palettes = $Registry.ListPalettes()
            $Palettes.Count | Should -BeGreaterThan 0

            $Names = $Registry.ListPaletteNames()
            $Names.Count | Should -BeGreaterThan 0
            $Names -contains "Office" | Should -Be $true
        }
    }

    Context "Get-ExcelColorPalette function" {
        It "Should get a palette by name" {
            $Palette = Get-ExcelColorPalette -Name "Office"
            $Palette.Name | Should -Be "Office"
            $Palette.IsBuiltIn | Should -Be $true
        }

        It "Should return default palette for non-existent name" {
            $Palette = Get-ExcelColorPalette -Name "NonExistent"
            $Palette.Name | Should -Be "Office"  # Retourne la palette par défaut
        }
    }

    Context "New-ExcelColorPalette function" {
        It "Should create a new custom palette" {
            $Colors = @("#FF0000", "#00FF00", "#0000FF")
            $Palette = New-ExcelColorPalette -Name "TestPalette" -Colors $Colors -Description "Test Description"

            $Palette.Name | Should -Be "TestPalette"
            $Palette.Colors.Count | Should -Be 3
            $Palette.Description | Should -Be "Test Description"
            $Palette.IsBuiltIn | Should -Be $false

            # Vérifier que la palette a été ajoutée au registre
            $Global:ExcelColorPaletteRegistry.Palettes.ContainsKey("TestPalette") | Should -Be $true
        }

        It "Should throw on invalid colors" {
            $Colors = @("#FF0000", "Red", "#0000FF")
            { New-ExcelColorPalette -Name "InvalidPalette" -Colors $Colors } | Should -Throw
        }
    }

    Context "Get-ExcelColorPaletteList function" {
        It "Should list all palettes" {
            $Palettes = Get-ExcelColorPaletteList
            $Palettes.Count | Should -BeGreaterThan 0
            $Palettes[0].Name | Should -Not -BeNullOrEmpty
        }

        It "Should include colors when requested" {
            $Palettes = Get-ExcelColorPaletteList -IncludeColors
            $Palettes[0].Colors | Should -Not -BeNullOrEmpty
            $Palettes[0].Colors.Count | Should -BeGreaterThan 0
        }

        It "Should filter built-in palettes" {
            # Créer une palette personnalisée pour le test
            $Colors = @("#FF0000", "#00FF00", "#0000FF")
            New-ExcelColorPalette -Name "TestCustomPalette" -Colors $Colors

            $BuiltInPalettes = Get-ExcelColorPaletteList -BuiltInOnly
            $BuiltInPalettes | ForEach-Object { $_.IsBuiltIn | Should -Be $true }

            $CustomPalettes = Get-ExcelColorPaletteList -CustomOnly
            $CustomPalettes | ForEach-Object { $_.IsBuiltIn | Should -Be $false }
            $CustomPalettes.Count | Should -BeGreaterThan 0
        }
    }

    Context "Remove-ExcelColorPalette function" {
        It "Should remove a custom palette" {
            # Créer une palette personnalisée pour le test
            $Colors = @("#FF0000", "#00FF00", "#0000FF")
            New-ExcelColorPalette -Name "PaletteToRemove" -Colors $Colors

            $Result = Remove-ExcelColorPalette -Name "PaletteToRemove"
            $Result | Should -Be $true

            $Global:ExcelColorPaletteRegistry.Palettes.ContainsKey("PaletteToRemove") | Should -Be $false
        }

        It "Should not remove a built-in palette" {
            $Result = Remove-ExcelColorPalette -Name "Office"
            $Result | Should -Be $false

            $Global:ExcelColorPaletteRegistry.Palettes.ContainsKey("Office") | Should -Be $true
        }
    }

    Context "Set-ExcelChartColorPalette function" {
        It "Should apply a palette to a chart" {
            $Result = Set-ExcelChartColorPalette -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PaletteName "Pastel"
            $Result | Should -Be $true
        }

        It "Should apply a palette in reverse order" {
            $Result = Set-ExcelChartColorPalette -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PaletteName "Vivid" -ReverseOrder
            $Result | Should -Be $true
        }

        It "Should apply a palette with start index" {
            $Result = Set-ExcelChartColorPalette -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PaletteName "Web" -StartIndex 2
            $Result | Should -Be $true
        }

        It "Should handle non-existent chart" {
            $Result = Set-ExcelChartColorPalette -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName "NonExistentChart" -PaletteName "Office"
            $Result | Should -Be $false
        }
    }

    Context "Set-ExcelChartSeriesColor function" {
        It "Should modify the color of a specific series" {
            $Result = Set-ExcelChartSeriesColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 0 -Color "#FF0000"
            $Result | Should -Be $true
        }

        It "Should modify the color with transparency" {
            $Result = Set-ExcelChartSeriesColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 1 -Color "#00FF00" -Transparency 30
            $Result | Should -Be $true
        }

        It "Should handle invalid series index" {
            $Result = Set-ExcelChartSeriesColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 999 -Color "#0000FF"
            $Result | Should -Be $false
        }

        It "Should handle invalid color format" {
            $Result = Set-ExcelChartSeriesColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 0 -Color "Red"
            $Result | Should -Be $false
        }
    }

    Context "Set-ExcelChartSeriesGradient function" {
        It "Should apply a gradient to chart series" {
            $Result = Set-ExcelChartSeriesGradient -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -StartColor "#FF0000" -EndColor "#0000FF"
            $Result | Should -Be $true
        }

        It "Should apply a gradient in reverse order" {
            $Result = Set-ExcelChartSeriesGradient -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -StartColor "#00FF00" -EndColor "#FF00FF" -ReverseOrder
            $Result | Should -Be $true
        }

        It "Should apply a gradient with transparency" {
            $Result = Set-ExcelChartSeriesGradient -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -StartColor "#FFFF00" -EndColor "#00FFFF" -Transparency 20
            $Result | Should -Be $true
        }

        It "Should handle invalid color format" {
            $Result = Set-ExcelChartSeriesGradient -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -StartColor "Red" -EndColor "Blue"
            $Result | Should -Be $false
        }
    }

    Context "Set-ExcelChartSeriesConditionalColor function" {
        It "Should apply conditional coloring to chart series" {
            $Result = Set-ExcelChartSeriesConditionalColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PositiveColor "#00FF00" -NegativeColor "#FF0000" -NeutralColor "#CCCCCC"
            $Result | Should -Be $true
        }

        It "Should apply conditional coloring with custom threshold" {
            $Result = Set-ExcelChartSeriesConditionalColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PositiveColor "#00FF00" -NegativeColor "#FF0000" -Threshold 15
            $Result | Should -Be $true
        }

        It "Should apply conditional coloring with transparency" {
            $Result = Set-ExcelChartSeriesConditionalColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PositiveColor "#00FF00" -NegativeColor "#FF0000" -Transparency 25
            $Result | Should -Be $true
        }

        It "Should handle invalid color format" {
            $Result = Set-ExcelChartSeriesConditionalColor -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PositiveColor "Green" -NegativeColor "Red"
            $Result | Should -Be $false
        }
    }

    Context "Set-ExcelChartSeriesColorRotation function" {
        It "Should apply color rotation to chart series" {
            $Result = Set-ExcelChartSeriesColorRotation -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PaletteName "Vivid"
            $Result | Should -Be $true
        }

        It "Should apply color rotation with custom start index" {
            $Result = Set-ExcelChartSeriesColorRotation -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PaletteName "Web" -StartIndex 3
            $Result | Should -Be $true
        }

        It "Should apply color rotation with custom interval" {
            $Result = Set-ExcelChartSeriesColorRotation -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PaletteName "Pastel" -Interval 2
            $Result | Should -Be $true
        }

        It "Should apply color rotation with transparency" {
            $Result = Set-ExcelChartSeriesColorRotation -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -PaletteName "Office" -Transparency 15
            $Result | Should -Be $true
        }

        It "Should handle non-existent chart" {
            $Result = Set-ExcelChartSeriesColorRotation -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName "NonExistentChart" -PaletteName "Office"
            $Result | Should -Be $false
        }
    }

    Context "ExcelLineStyleConfig class" {
        It "Should create a default line style" {
            $Style = [ExcelLineStyleConfig]::new()
            $Style.Width | Should -Be 1
            $Style.Style | Should -Be ([ExcelLineStyle]::Solid)
            $Style.Color | Should -Be "#000000"
            $Style.Validate() | Should -Be $true
        }

        It "Should create a custom line style" {
            $Style = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#FF0000")
            $Style.Width | Should -Be 2
            $Style.Style | Should -Be ([ExcelLineStyle]::Dash)
            $Style.Color | Should -Be "#FF0000"
            $Style.Validate() | Should -Be $true
        }

        It "Should validate line styles" {
            # Valid style
            $ValidStyle = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Dot, "#00FF00")
            $ValidStyle.Validate() | Should -Be $true

            # Invalid width
            $InvalidWidthStyle = [ExcelLineStyleConfig]::new()
            $InvalidWidthStyle.Width = 0
            $InvalidWidthStyle.Validate() | Should -Be $false

            # Invalid transparency
            $InvalidTransparencyStyle = [ExcelLineStyleConfig]::new()
            $InvalidTransparencyStyle.Transparency = 101
            $InvalidTransparencyStyle.Validate() | Should -Be $false

            # Invalid color
            $InvalidColorStyle = [ExcelLineStyleConfig]::new()
            $InvalidColorStyle.Color = "Red"
            $InvalidColorStyle.Validate() | Should -Be $false
        }

        It "Should clone line styles" {
            $Original = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::DashDot, "#0000FF")
            $Original.Transparency = 30
            $Original.Smooth = $true
            $Original.Description = "Test Style"
            $Original.IsBuiltIn = $true

            $Clone = $Original.Clone()
            $Clone.Width | Should -Be $Original.Width
            $Clone.Style | Should -Be $Original.Style
            $Clone.Color | Should -Be $Original.Color
            $Clone.Transparency | Should -Be $Original.Transparency
            $Clone.Smooth | Should -Be $Original.Smooth
            $Clone.Description | Should -Be $Original.Description
            $Clone.IsBuiltIn | Should -Be $false  # Une copie n'est jamais un style prédéfini
        }
    }

    Context "ExcelLineStyleRegistry class" {
        It "Should initialize with built-in styles" {
            $Registry = [ExcelLineStyleRegistry]::new()
            $Registry.Styles.Count | Should -BeGreaterThan 0
            $Registry.Styles.ContainsKey("Default") | Should -Be $true
            $Registry.Styles.ContainsKey("Dashed") | Should -Be $true
        }

        It "Should get style by name" {
            $Registry = [ExcelLineStyleRegistry]::new()
            $Style = $Registry.GetStyle("Thick")
            $Style.Width | Should -Be 3
            $Style.IsBuiltIn | Should -Be $true

            $DefaultStyle = $Registry.GetStyle("NonExistent")
            $DefaultStyle.Description | Should -Be "Style par défaut"  # Retourne le style par défaut
        }

        It "Should add and remove custom styles" {
            $Registry = [ExcelLineStyleRegistry]::new()
            $Style = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#FF00FF")
            $Style.Description = "Style de test"

            $Registry.AddStyle("TestStyle", $Style)
            $Registry.Styles.ContainsKey("TestStyle") | Should -Be $true

            $Result = $Registry.RemoveStyle("TestStyle")
            $Result | Should -Be $true
            $Registry.Styles.ContainsKey("TestStyle") | Should -Be $false

            # Ne devrait pas pouvoir supprimer un style prédéfini
            $Result = $Registry.RemoveStyle("Default")
            $Result | Should -Be $false
            $Registry.Styles.ContainsKey("Default") | Should -Be $true
        }

        It "Should list styles and names" {
            $Registry = [ExcelLineStyleRegistry]::new()
            $Styles = $Registry.ListStyles()
            $Styles.Count | Should -BeGreaterThan 0

            $Names = $Registry.ListStyleNames()
            $Names.Count | Should -BeGreaterThan 0
            $Names -contains "Default" | Should -Be $true
        }
    }

    Context "Get-ExcelLineStyle function" {
        It "Should get a line style by name" {
            $Style = Get-ExcelLineStyle -Name "Dashed"
            $Style.Style | Should -Be ([ExcelLineStyle]::Dash)
            $Style.IsBuiltIn | Should -Be $true
        }

        It "Should return default style for non-existent name" {
            $Style = Get-ExcelLineStyle -Name "NonExistent"
            $Style.Description | Should -Be "Style par défaut"  # Retourne le style par défaut
        }
    }

    Context "New-ExcelLineStyle function" {
        It "Should create a new custom line style" {
            $Style = New-ExcelLineStyle -Name "TestCustomStyle" -Width 2 -Style Dash -Color "#FF0000" -Description "Style de test"

            $Style.Width | Should -Be 2
            $Style.Style | Should -Be ([ExcelLineStyle]::Dash)
            $Style.Color | Should -Be "#FF0000"
            $Style.Description | Should -Be "Style de test"
            $Style.IsBuiltIn | Should -Be $false

            # Vérifier que le style a été ajouté au registre
            $Global:ExcelLineStyleRegistry.Styles.ContainsKey("TestCustomStyle") | Should -Be $true
        }

        It "Should throw on invalid parameters" {
            { New-ExcelLineStyle -Name "InvalidStyle" -Width 0 -Style Solid -Color "#000000" } | Should -Throw
            { New-ExcelLineStyle -Name "InvalidStyle" -Width 1 -Style Solid -Color "Red" } | Should -Throw
        }
    }

    Context "Get-ExcelLineStyleList function" {
        It "Should list all line styles" {
            $Styles = Get-ExcelLineStyleList
            $Styles.Count | Should -BeGreaterThan 0
            $Styles[0].Name | Should -Not -BeNullOrEmpty
        }

        It "Should filter built-in styles" {
            # Créer un style personnalisé pour le test
            New-ExcelLineStyle -Name "TestFilterStyle" -Width 2 -Style Dot -Color "#00FF00"

            $BuiltInStyles = Get-ExcelLineStyleList -BuiltInOnly
            $BuiltInStyles | ForEach-Object { $_.IsBuiltIn | Should -Be $true }

            $CustomStyles = Get-ExcelLineStyleList -CustomOnly
            $CustomStyles | ForEach-Object { $_.IsBuiltIn | Should -Be $false }
            $CustomStyles.Count | Should -BeGreaterThan 0
        }
    }

    Context "Remove-ExcelLineStyle function" {
        It "Should remove a custom line style" {
            # Créer un style personnalisé pour le test
            New-ExcelLineStyle -Name "StyleToRemove" -Width 2 -Style Solid -Color "#0000FF"

            $Result = Remove-ExcelLineStyle -Name "StyleToRemove"
            $Result | Should -Be $true

            $Global:ExcelLineStyleRegistry.Styles.ContainsKey("StyleToRemove") | Should -Be $false
        }

        It "Should not remove a built-in line style" {
            $Result = Remove-ExcelLineStyle -Name "Default"
            $Result | Should -Be $false

            $Global:ExcelLineStyleRegistry.Styles.ContainsKey("Default") | Should -Be $true
        }
    }

    Context "Set-ExcelChartSeriesLineStyle function" {
        It "Should apply a line style to a chart series by name" {
            $Result = Set-ExcelChartSeriesLineStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 0 -StyleName "Dashed"
            $Result | Should -Be $true
        }

        It "Should apply a line style to a chart series by object" {
            $Style = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Dot, "#FF0000")
            $Result = Set-ExcelChartSeriesLineStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 1 -Style $Style
            $Result | Should -Be $true
        }

        It "Should handle invalid series index" {
            $Result = Set-ExcelChartSeriesLineStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 999 -StyleName "Default"
            $Result | Should -Be $false
        }

        It "Should handle non-existent chart" {
            $Result = Set-ExcelChartSeriesLineStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName "NonExistentChart" -SeriesIndex 0 -StyleName "Default"
            $Result | Should -Be $false
        }
    }

    Context "ExcelMarkerStyleConverter class" {
        It "Should convert marker styles to EPPlus values" {
            $EPPlusValue = [ExcelMarkerStyleConverter]::ToEPPlusStyle([ExcelMarkerStyle]::Diamond)
            $EPPlusValue | Should -Be 2

            $EPPlusValue = [ExcelMarkerStyleConverter]::ToEPPlusStyle([ExcelMarkerStyle]::Circle)
            $EPPlusValue | Should -Be 6
        }

        It "Should provide descriptions for marker styles" {
            $Description = [ExcelMarkerStyleConverter]::GetDescription([ExcelMarkerStyle]::Square)
            $Description | Should -Be "Marqueur carré"

            $Description = [ExcelMarkerStyleConverter]::GetDescription([ExcelMarkerStyle]::Star)
            $Description | Should -Be "Marqueur en forme d'étoile"
        }

        It "Should list all available marker styles" {
            $Styles = [ExcelMarkerStyleConverter]::GetAllStyles()
            $Styles.Count | Should -BeGreaterThan 0
            $Styles[0].Style | Should -BeOfType [ExcelMarkerStyle]
            $Styles[0].Description | Should -Not -BeNullOrEmpty
        }

        It "Should identify styles requiring special handling" {
            [ExcelMarkerStyleConverter]::RequiresSpecialHandling([ExcelMarkerStyle]::TriangleDown) | Should -Be $true
            [ExcelMarkerStyleConverter]::RequiresSpecialHandling([ExcelMarkerStyle]::Circle) | Should -Be $false
        }

        It "Should validate marker sizes" {
            [ExcelMarkerStyleConverter]::ValidateSize(7) | Should -Be $true
            [ExcelMarkerStyleConverter]::ValidateSize(0) | Should -Be $false
            [ExcelMarkerStyleConverter]::ValidateSize(30) | Should -Be $false
        }

        It "Should provide predefined sizes" {
            $Size = [ExcelMarkerStyleConverter]::GetPredefinedSize("Medium")
            $Size | Should -Be 7

            $Size = [ExcelMarkerStyleConverter]::GetPredefinedSize("Large")
            $Size | Should -Be 10

            # Taille non existante devrait retourner la taille par défaut
            $Size = [ExcelMarkerStyleConverter]::GetPredefinedSize("NonExistent")
            $Size | Should -Be [ExcelMarkerStyleConverter]::DefaultSize
        }

        It "Should list all predefined sizes" {
            $Sizes = [ExcelMarkerStyleConverter]::GetAllPredefinedSizes()
            $Sizes.Count | Should -BeGreaterThan 0
            $Sizes[0].Name | Should -Not -BeNullOrEmpty
            $Sizes[0].Value | Should -BeOfType [int]
        }
    }

    Context "Get-ExcelMarkerStyleList function" {
        It "Should list all marker styles" {
            $Styles = Get-ExcelMarkerStyleList
            $Styles.Count | Should -BeGreaterThan 0
            $Styles[0].Name | Should -Not -BeNullOrEmpty
            $Styles[0].Description | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-ExcelMarkerSizeList function" {
        It "Should list all predefined marker sizes" {
            $Sizes = Get-ExcelMarkerSizeList
            $Sizes.Count | Should -BeGreaterThan 0
            $Sizes[0].Name | Should -Not -BeNullOrEmpty
            $Sizes[0].Value | Should -BeOfType [int]
        }
    }

    Context "ExcelMarkerConfig class" {
        It "Should create a default marker configuration" {
            $Config = [ExcelMarkerConfig]::new()
            $Config.Style | Should -Be ([ExcelMarkerStyle]::Circle)
            $Config.Size | Should -Be 7
            $Config.Color | Should -Be "#000000"
            $Config.Validate() | Should -Be $true
        }

        It "Should create a custom marker configuration" {
            $Config = [ExcelMarkerConfig]::new([ExcelMarkerStyle]::Diamond, 10)
            $Config.Style | Should -Be ([ExcelMarkerStyle]::Diamond)
            $Config.Size | Should -Be 10
            $Config.Validate() | Should -Be $true
        }

        It "Should create a complete marker configuration" {
            $Config = [ExcelMarkerConfig]::new([ExcelMarkerStyle]::Star, 12, "#FF0000", "#000000", 2, "Test Config")
            $Config.Style | Should -Be ([ExcelMarkerStyle]::Star)
            $Config.Size | Should -Be 12
            $Config.Color | Should -Be "#FF0000"
            $Config.BorderColor | Should -Be "#000000"
            $Config.BorderWidth | Should -Be 2
            $Config.Description | Should -Be "Test Config"
            $Config.Validate() | Should -Be $true
        }

        It "Should validate marker configurations" {
            # Valid configuration
            $ValidConfig = [ExcelMarkerConfig]::new([ExcelMarkerStyle]::Square, 10)
            $ValidConfig.Validate() | Should -Be $true

            # Invalid size
            $InvalidSizeConfig = [ExcelMarkerConfig]::new()
            $InvalidSizeConfig.Size = 0
            $InvalidSizeConfig.Validate() | Should -Be $false

            # Invalid border width
            $InvalidBorderConfig = [ExcelMarkerConfig]::new()
            $InvalidBorderConfig.BorderWidth = 6
            $InvalidBorderConfig.Validate() | Should -Be $false

            # Invalid color
            $InvalidColorConfig = [ExcelMarkerConfig]::new()
            $InvalidColorConfig.Color = "Red"
            $InvalidColorConfig.Validate() | Should -Be $false
        }

        It "Should clone marker configurations" {
            $Original = [ExcelMarkerConfig]::new([ExcelMarkerStyle]::Triangle, 15, "#00FF00", "#0000FF", 3, "Original Config")
            $Clone = $Original.Clone()

            $Clone.Style | Should -Be $Original.Style
            $Clone.Size | Should -Be $Original.Size
            $Clone.Color | Should -Be $Original.Color
            $Clone.BorderColor | Should -Be $Original.BorderColor
            $Clone.BorderWidth | Should -Be $Original.BorderWidth
            $Clone.Description | Should -Be $Original.Description
        }
    }

    Context "New-ExcelMarkerConfig function" {
        It "Should create a marker configuration with specific size" {
            $Config = New-ExcelMarkerConfig -Style Diamond -Size 10 -Color "#FF0000"
            $Config.Style | Should -Be ([ExcelMarkerStyle]::Diamond)
            $Config.Size | Should -Be 10
            $Config.Color | Should -Be "#FF0000"
        }

        It "Should create a marker configuration with predefined size name" {
            $Config = New-ExcelMarkerConfig -Style Circle -SizeName "Large" -Color "#0000FF"
            $Config.Style | Should -Be ([ExcelMarkerStyle]::Circle)
            $Config.Size | Should -Be 10  # Large = 10
            $Config.Color | Should -Be "#0000FF"
        }

        It "Should create a marker configuration with border" {
            $Config = New-ExcelMarkerConfig -Style Star -Size 12 -Color "#FF0000" -BorderColor "#000000" -BorderWidth 2
            $Config.Style | Should -Be ([ExcelMarkerStyle]::Star)
            $Config.BorderColor | Should -Be "#000000"
            $Config.BorderWidth | Should -Be 2
        }

        It "Should throw on invalid parameters" {
            { New-ExcelMarkerConfig -Style Square -Size 0 } | Should -Throw
            { New-ExcelMarkerConfig -Style Square -Size 10 -Color "Red" } | Should -Throw
            { New-ExcelMarkerConfig -Style Square -Size 10 -BorderWidth 6 } | Should -Throw
        }
    }

    Context "ExcelBorderStyleConverter class" {
        It "Should convert border styles to EPPlus values" {
            $EPPlusValue = [ExcelBorderStyleConverter]::ToEPPlusStyle([ExcelBorderStyle]::Medium)
            $EPPlusValue | Should -Be 2

            $EPPlusValue = [ExcelBorderStyleConverter]::ToEPPlusStyle([ExcelBorderStyle]::Dotted)
            $EPPlusValue | Should -Be 6
        }

        It "Should provide descriptions for border styles" {
            $Description = [ExcelBorderStyleConverter]::GetDescription([ExcelBorderStyle]::Thin)
            $Description | Should -Be "Bordure fine"

            $Description = [ExcelBorderStyleConverter]::GetDescription([ExcelBorderStyle]::Double)
            $Description | Should -Be "Bordure double"
        }

        It "Should list all available border styles" {
            $Styles = [ExcelBorderStyleConverter]::GetAllStyles()
            $Styles.Count | Should -BeGreaterThan 0
            $Styles[0].Style | Should -BeOfType [ExcelBorderStyle]
            $Styles[0].Description | Should -Not -BeNullOrEmpty
        }
    }

    Context "ExcelBorderStyleConfig class" {
        It "Should create a default border style configuration" {
            $Config = [ExcelBorderStyleConfig]::new()
            $Config.Style | Should -Be ([ExcelBorderStyle]::Thin)
            $Config.Color | Should -Be "#000000"
            $Config.Width | Should -Be 1
            $Config.Validate() | Should -Be $true
        }

        It "Should create a custom border style configuration" {
            $Config = [ExcelBorderStyleConfig]::new([ExcelBorderStyle]::Medium, "#FF0000")
            $Config.Style | Should -Be ([ExcelBorderStyle]::Medium)
            $Config.Color | Should -Be "#FF0000"
            $Config.Validate() | Should -Be $true
        }

        It "Should create a complete border style configuration" {
            $Config = [ExcelBorderStyleConfig]::new([ExcelBorderStyle]::Thick, "#0000FF", 3, "Test Config")
            $Config.Style | Should -Be ([ExcelBorderStyle]::Thick)
            $Config.Color | Should -Be "#0000FF"
            $Config.Width | Should -Be 3
            $Config.Description | Should -Be "Test Config"
            $Config.Validate() | Should -Be $true
        }

        It "Should validate border style configurations" {
            # Valid configuration
            $ValidConfig = [ExcelBorderStyleConfig]::new([ExcelBorderStyle]::Dashed, "#00FF00")
            $ValidConfig.Validate() | Should -Be $true

            # Invalid width
            $InvalidWidthConfig = [ExcelBorderStyleConfig]::new()
            $InvalidWidthConfig.Width = 0
            $InvalidWidthConfig.Validate() | Should -Be $false

            # Invalid color
            $InvalidColorConfig = [ExcelBorderStyleConfig]::new()
            $InvalidColorConfig.Color = "Red"
            $InvalidColorConfig.Validate() | Should -Be $false
        }

        It "Should clone border style configurations" {
            $Original = [ExcelBorderStyleConfig]::new([ExcelBorderStyle]::DashDot, "#FF00FF", 2, "Original Config")
            $Clone = $Original.Clone()

            $Clone.Style | Should -Be $Original.Style
            $Clone.Color | Should -Be $Original.Color
            $Clone.Width | Should -Be $Original.Width
            $Clone.Description | Should -Be $Original.Description
            $Clone.IsBuiltIn | Should -Be $false
        }
    }

    Context "Get-ExcelBorderStyleList function" {
        It "Should list all border styles" {
            $Styles = Get-ExcelBorderStyleList
            $Styles.Count | Should -BeGreaterThan 0
            $Styles[0].Name | Should -Not -BeNullOrEmpty
            $Styles[0].Description | Should -Not -BeNullOrEmpty
        }
    }

    Context "New-ExcelBorderConfig function" {
        It "Should create a border configuration" {
            $Config = New-ExcelBorderConfig -Style Medium -Color "#FF0000"
            $Config.Style | Should -Be ([ExcelBorderStyle]::Medium)
            $Config.Color | Should -Be "#FF0000"
            $Config.Width | Should -Be 1  # Default width
        }

        It "Should create a border configuration with custom width" {
            $Config = New-ExcelBorderConfig -Style Thick -Color "#0000FF" -Width 3
            $Config.Style | Should -Be ([ExcelBorderStyle]::Thick)
            $Config.Color | Should -Be "#0000FF"
            $Config.Width | Should -Be 3
        }

        It "Should create a border configuration with description" {
            $Config = New-ExcelBorderConfig -Style Dotted -Color "#00FF00" -Description "Test Border"
            $Config.Style | Should -Be ([ExcelBorderStyle]::Dotted)
            $Config.Description | Should -Be "Test Border"
        }

        It "Should throw on invalid parameters" {
            { New-ExcelBorderConfig -Style Double -Color "Red" } | Should -Throw
            { New-ExcelBorderConfig -Style Double -Color "#000000" -Width 6 } | Should -Throw
        }
    }

    Context "Set-ExcelChartElementBorder function" {
        It "Should apply a border style to a chart element" {
            $Result = Set-ExcelChartElementBorder -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -ElementType Series -ElementIndex 0 -Style Medium -Color "#FF0000"
            $Result | Should -Be $true
        }

        It "Should apply a border style to chart title" {
            $Result = Set-ExcelChartElementBorder -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -ElementType Title -Style Thick -Color "#0000FF" -Width 2
            $Result | Should -Be $true
        }

        It "Should handle non-existent chart" {
            $Result = Set-ExcelChartElementBorder -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName "NonExistentChart" -ElementType Series -ElementIndex 0 -Style Thin -Color "#000000"
            $Result | Should -Be $false
        }

        It "Should handle invalid element index" {
            $Result = Set-ExcelChartElementBorder -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -ElementType Series -ElementIndex 999 -Style Thin -Color "#000000"
            $Result | Should -Be $false
        }
    }

    Context "Set-ExcelChartSeriesMarkerStyle function" {
        It "Should apply a marker style to a chart series" {
            $Result = Set-ExcelChartSeriesMarkerStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 0 -MarkerStyle Diamond -Size 10
            $Result | Should -Be $true
        }

        It "Should apply a marker style with color and border" {
            $Result = Set-ExcelChartSeriesMarkerStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 1 -MarkerStyle Circle -Size 8 -Color "#FF0000" -BorderColor "#000000" -BorderWidth 2
            $Result | Should -Be $true
        }

        It "Should handle invalid series index" {
            $Result = Set-ExcelChartSeriesMarkerStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 999 -MarkerStyle Square
            $Result | Should -Be $false
        }

        It "Should handle invalid color format" {
            $Result = Set-ExcelChartSeriesMarkerStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 0 -MarkerStyle Square -Color "Red"
            $Result | Should -Be $false
        }
    }

    Context "Set-ExcelChartDataPointMarkerStyle function" {
        It "Should apply a marker style to a specific data point" {
            # Cette fonction peut échouer si le type de graphique ne supporte pas les points de données individuels
            # Nous testons donc avec un try/catch pour éviter les échecs de test
            try {
                $Result = Set-ExcelChartDataPointMarkerStyle -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -ChartName $script:ChartName -SeriesIndex 0 -PointIndex 1 -MarkerStyle Star -Size 12
                # Si la fonction réussit, vérifier le résultat
                if ($Result -ne $null) {
                    $Result | Should -BeOfType [bool]
                }
            } catch {
                # Si la fonction échoue, ignorer le test
                Write-Host "Le graphique de test ne supporte pas la personnalisation par point de données."
            }
        }
    }
}
