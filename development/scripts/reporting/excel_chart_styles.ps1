<#
.SYNOPSIS
    Module de styles et personnalisation pour les graphiques Excel.
.DESCRIPTION
    Ce module fournit des fonctionnalitÃ©s pour la personnalisation des graphiques Excel,
    incluant des palettes de couleurs, des styles de lignes, et des thÃ¨mes complets.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de crÃ©ation: 2025-04-25
#>

# VÃ©rifier si le module excel_charts.ps1 est disponible
$ChartsPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_charts.ps1"
if (-not (Test-Path -Path $ChartsPath)) {
    throw "Le module excel_charts.ps1 est requis mais n'a pas Ã©tÃ© trouvÃ©."
}

# Importer le module excel_charts.ps1
. $ChartsPath

#region Palettes de couleurs

# Classe pour reprÃ©senter une palette de couleurs
class ExcelColorPalette {
    [string]$Name
    [string[]]$Colors
    [string]$Description
    [bool]$IsBuiltIn = $true

    # Constructeur par dÃ©faut
    ExcelColorPalette() {
        $this.Name = "Default"
        $this.Colors = @(
            "#4472C4", "#ED7D31", "#A5A5A5", "#FFC000",
            "#5B9BD5", "#70AD47", "#FF0000", "#0070C0"
        )
        $this.Description = "Palette par dÃ©faut d'Excel"
    }

    # Constructeur avec nom et couleurs
    ExcelColorPalette([string]$Name, [string[]]$Colors) {
        $this.Name = $Name
        $this.Colors = $Colors
        $this.Description = "Palette personnalisÃ©e: $Name"
        $this.IsBuiltIn = $false
    }

    # Constructeur complet
    ExcelColorPalette([string]$Name, [string[]]$Colors, [string]$Description, [bool]$IsBuiltIn) {
        $this.Name = $Name
        $this.Colors = $Colors
        $this.Description = $Description
        $this.IsBuiltIn = $IsBuiltIn
    }

    # MÃ©thode pour obtenir une couleur Ã  un index spÃ©cifique (avec rotation)
    [string] GetColor([int]$Index) {
        if ($this.Colors.Count -eq 0) {
            return "#000000"  # Noir par dÃ©faut si la palette est vide
        }

        # Utiliser la rotation pour les index dÃ©passant le nombre de couleurs
        $ColorIndex = $Index % $this.Colors.Count
        return $this.Colors[$ColorIndex]
    }

    # MÃ©thode pour ajouter une couleur Ã  la palette
    [void] AddColor([string]$Color) {
        $this.Colors += $Color
    }

    # MÃ©thode pour remplacer une couleur Ã  un index spÃ©cifique
    [void] ReplaceColor([int]$Index, [string]$Color) {
        if ($Index -ge 0 -and $Index -lt $this.Colors.Count) {
            $this.Colors[$Index] = $Color
        }
    }

    # MÃ©thode pour valider les couleurs (format hexadÃ©cimal)
    [bool] Validate() {
        foreach ($Color in $this.Colors) {
            if (-not ($Color -match '^#[0-9A-Fa-f]{6}$')) {
                return $false
            }
        }
        return $true
    }

    # MÃ©thode pour crÃ©er une copie de la palette
    [ExcelColorPalette] Clone() {
        return [ExcelColorPalette]::new($this.Name, $this.Colors.Clone(), $this.Description, $false)
    }

    # MÃ©thode pour obtenir une version inversÃ©e de la palette
    [ExcelColorPalette] GetReversed() {
        $ReversedColors = $this.Colors.Clone()
        [array]::Reverse($ReversedColors)
        return [ExcelColorPalette]::new("$($this.Name)_Reversed", $ReversedColors, "Version inversÃ©e de $($this.Description)", $false)
    }
}

# Classe pour gÃ©rer un registre de palettes de couleurs
class ExcelColorPaletteRegistry {
    [System.Collections.Generic.Dictionary[string, ExcelColorPalette]] $Palettes

    # Constructeur
    ExcelColorPaletteRegistry() {
        $this.Palettes = [System.Collections.Generic.Dictionary[string, ExcelColorPalette]]::new()
        $this.InitializeBuiltInPalettes()
    }

    # MÃ©thode pour initialiser les palettes prÃ©dÃ©finies
    [void] InitializeBuiltInPalettes() {
        # Palette Office
        $OfficePalette = [ExcelColorPalette]::new(
            "Office",
            @(
                "#4472C4", "#ED7D31", "#A5A5A5", "#FFC000",
                "#5B9BD5", "#70AD47", "#FF0000", "#0070C0"
            ),
            "Palette standard Office",
            $true
        )
        $this.Palettes.Add($OfficePalette.Name, $OfficePalette)

        # Palette Pastel
        $PastelPalette = [ExcelColorPalette]::new(
            "Pastel",
            @(
                "#ABDEE6", "#CBAACB", "#FFFFB5", "#FFCCB6",
                "#F3B0C3", "#C6DBDA", "#FEE1E8", "#FED7C3"
            ),
            "Palette de couleurs pastel",
            $true
        )
        $this.Palettes.Add($PastelPalette.Name, $PastelPalette)

        # Palette Vive
        $VividPalette = [ExcelColorPalette]::new(
            "Vivid",
            @(
                "#FF5733", "#33FF57", "#3357FF", "#F3FF33",
                "#FF33F3", "#33FFF3", "#FF3333", "#33FF33"
            ),
            "Palette de couleurs vives",
            $true
        )
        $this.Palettes.Add($VividPalette.Name, $VividPalette)

        # Palette Monochromatique Bleue
        $BluePalette = [ExcelColorPalette]::new(
            "BlueMonochrome",
            @(
                "#0D47A1", "#1976D2", "#2196F3", "#64B5F6",
                "#90CAF9", "#BBDEFB", "#E3F2FD", "#F5F9FF"
            ),
            "Palette monochromatique bleue",
            $true
        )
        $this.Palettes.Add($BluePalette.Name, $BluePalette)

        # Palette Monochromatique Verte
        $GreenPalette = [ExcelColorPalette]::new(
            "GreenMonochrome",
            @(
                "#1B5E20", "#2E7D32", "#388E3C", "#43A047",
                "#4CAF50", "#66BB6A", "#81C784", "#A5D6A7"
            ),
            "Palette monochromatique verte",
            $true
        )
        $this.Palettes.Add($GreenPalette.Name, $GreenPalette)

        # Palette Web
        $WebPalette = [ExcelColorPalette]::new(
            "Web",
            @(
                "#3498DB", "#E74C3C", "#2ECC71", "#F1C40F",
                "#9B59B6", "#1ABC9C", "#E67E22", "#34495E"
            ),
            "Palette de couleurs web modernes",
            $true
        )
        $this.Palettes.Add($WebPalette.Name, $WebPalette)

        # Palette Sombre
        $DarkPalette = [ExcelColorPalette]::new(
            "Dark",
            @(
                "#1A1A1D", "#4E4E50", "#6F2232", "#950740",
                "#C3073F", "#4E4187", "#371B58", "#7858A6"
            ),
            "Palette de couleurs sombres",
            $true
        )
        $this.Palettes.Add($DarkPalette.Name, $DarkPalette)

        # Palette Corporative
        $CorporatePalette = [ExcelColorPalette]::new(
            "Corporate",
            @(
                "#0073B7", "#5DA5DA", "#FAA43A", "#60BD68",
                "#F17CB0", "#B2912F", "#B276B2", "#DECF3F"
            ),
            "Palette de couleurs corporatives",
            $true
        )
        $this.Palettes.Add($CorporatePalette.Name, $CorporatePalette)
    }

    # MÃ©thode pour obtenir une palette par son nom
    [ExcelColorPalette] GetPalette([string]$Name) {
        if ($this.Palettes.ContainsKey($Name)) {
            return $this.Palettes[$Name]
        }

        # Retourner la palette par dÃ©faut si le nom n'existe pas
        return $this.Palettes["Office"]
    }

    # MÃ©thode pour ajouter une nouvelle palette
    [void] AddPalette([ExcelColorPalette]$Palette) {
        if ($this.Palettes.ContainsKey($Palette.Name)) {
            # Remplacer la palette existante si elle n'est pas prÃ©dÃ©finie
            $ExistingPalette = $this.Palettes[$Palette.Name]
            if (-not $ExistingPalette.IsBuiltIn) {
                $this.Palettes[$Palette.Name] = $Palette
            }
        } else {
            # Ajouter la nouvelle palette
            $this.Palettes.Add($Palette.Name, $Palette)
        }
    }

    # MÃ©thode pour supprimer une palette
    [bool] RemovePalette([string]$Name) {
        if ($this.Palettes.ContainsKey($Name)) {
            $Palette = $this.Palettes[$Name]
            if (-not $Palette.IsBuiltIn) {
                return $this.Palettes.Remove($Name)
            }
        }
        return $false
    }

    # MÃ©thode pour lister toutes les palettes disponibles
    [ExcelColorPalette[]] ListPalettes() {
        return $this.Palettes.Values
    }

    # MÃ©thode pour lister les noms de toutes les palettes
    [string[]] ListPaletteNames() {
        return $this.Palettes.Keys
    }
}

# CrÃ©er une instance globale du registre de palettes
$Global:ExcelColorPaletteRegistry = [ExcelColorPaletteRegistry]::new()

<#
.SYNOPSIS
    Obtient une palette de couleurs par son nom.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re une palette de couleurs prÃ©dÃ©finie ou personnalisÃ©e par son nom.
.PARAMETER Name
    Nom de la palette Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $Palette = Get-ExcelColorPalette -Name "Office"
.OUTPUTS
    ExcelColorPalette - La palette de couleurs demandÃ©e.
#>
function Get-ExcelColorPalette {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $Global:ExcelColorPaletteRegistry.GetPalette($Name)
}

<#
.SYNOPSIS
    CrÃ©e une nouvelle palette de couleurs personnalisÃ©e.
.DESCRIPTION
    Cette fonction crÃ©e une nouvelle palette de couleurs personnalisÃ©e avec les couleurs spÃ©cifiÃ©es.
.PARAMETER Name
    Nom de la nouvelle palette.
.PARAMETER Colors
    Tableau de couleurs au format hexadÃ©cimal (#RRGGBB).
.PARAMETER Description
    Description de la palette (optionnel).
.EXAMPLE
    $Colors = @("#FF0000", "#00FF00", "#0000FF", "#FFFF00")
    New-ExcelColorPalette -Name "MaPalette" -Colors $Colors -Description "Ma palette personnalisÃ©e"
.OUTPUTS
    ExcelColorPalette - La nouvelle palette de couleurs crÃ©Ã©e.
#>
function New-ExcelColorPalette {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$Colors,

        [Parameter(Mandatory = $false)]
        [string]$Description = "Palette personnalisÃ©e"
    )

    # CrÃ©er la nouvelle palette
    $Palette = [ExcelColorPalette]::new($Name, $Colors, $Description, $false)

    # Valider la palette
    if (-not $Palette.Validate()) {
        throw "Les couleurs spÃ©cifiÃ©es ne sont pas au format hexadÃ©cimal valide (#RRGGBB)."
    }

    # Ajouter la palette au registre
    $Global:ExcelColorPaletteRegistry.AddPalette($Palette)

    return $Palette
}

<#
.SYNOPSIS
    Liste toutes les palettes de couleurs disponibles.
.DESCRIPTION
    Cette fonction liste toutes les palettes de couleurs prÃ©dÃ©finies et personnalisÃ©es disponibles.
.PARAMETER IncludeColors
    Si spÃ©cifiÃ©, inclut les couleurs de chaque palette dans la sortie.
.PARAMETER BuiltInOnly
    Si spÃ©cifiÃ©, liste uniquement les palettes prÃ©dÃ©finies.
.PARAMETER CustomOnly
    Si spÃ©cifiÃ©, liste uniquement les palettes personnalisÃ©es.
.EXAMPLE
    Get-ExcelColorPaletteList -IncludeColors
.OUTPUTS
    PSObject[] - Liste des palettes disponibles avec leurs propriÃ©tÃ©s.
#>
function Get-ExcelColorPaletteList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$IncludeColors,

        [Parameter(Mandatory = $false)]
        [switch]$BuiltInOnly,

        [Parameter(Mandatory = $false)]
        [switch]$CustomOnly
    )

    $Palettes = $Global:ExcelColorPaletteRegistry.ListPalettes()
    $Result = @()

    foreach ($Palette in $Palettes) {
        # Filtrer selon les paramÃ¨tres
        if ($BuiltInOnly -and -not $Palette.IsBuiltIn) {
            continue
        }

        if ($CustomOnly -and $Palette.IsBuiltIn) {
            continue
        }

        $PaletteInfo = [PSCustomObject]@{
            Name        = $Palette.Name
            Description = $Palette.Description
            IsBuiltIn   = $Palette.IsBuiltIn
            ColorCount  = $Palette.Colors.Count
        }

        if ($IncludeColors) {
            $PaletteInfo | Add-Member -MemberType NoteProperty -Name "Colors" -Value $Palette.Colors
        }

        $Result += $PaletteInfo
    }

    return $Result
}

<#
.SYNOPSIS
    Supprime une palette de couleurs personnalisÃ©e.
.DESCRIPTION
    Cette fonction supprime une palette de couleurs personnalisÃ©e du registre.
    Les palettes prÃ©dÃ©finies ne peuvent pas Ãªtre supprimÃ©es.
.PARAMETER Name
    Nom de la palette Ã  supprimer.
.EXAMPLE
    Remove-ExcelColorPalette -Name "MaPalette"
.OUTPUTS
    System.Boolean - True si la suppression a rÃ©ussi, False sinon.
#>
function Remove-ExcelColorPalette {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $Global:ExcelColorPaletteRegistry.RemovePalette($Name)
}

<#
.SYNOPSIS
    Applique une palette de couleurs Ã  un graphique Excel.
.DESCRIPTION
    Cette fonction applique une palette de couleurs spÃ©cifiÃ©e Ã  un graphique Excel existant.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER PaletteName
    Le nom de la palette de couleurs Ã  appliquer.
.PARAMETER StartIndex
    L'index de dÃ©part dans la palette (0 par dÃ©faut).
.PARAMETER ReverseOrder
    Si spÃ©cifiÃ©, applique les couleurs dans l'ordre inverse.
.EXAMPLE
    Set-ExcelChartColorPalette -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -PaletteName "Pastel"
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartColorPalette {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [string]$PaletteName,

        [Parameter(Mandatory = $false)]
        [int]$StartIndex = 0,

        [Parameter(Mandatory = $false)]
        [switch]$ReverseOrder
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # Obtenir la palette de couleurs
        $Palette = $Global:ExcelColorPaletteRegistry.GetPalette($PaletteName)

        # Appliquer les couleurs aux sÃ©ries du graphique
        $SeriesCount = $Chart.Series.Count

        for ($i = 0; $i -lt $SeriesCount; $i++) {
            $Series = $Chart.Series[$i]

            # Calculer l'index de couleur
            $ColorIndex = if ($ReverseOrder) {
                $SeriesCount - 1 - $i + $StartIndex
            } else {
                $i + $StartIndex
            }

            $Color = $Palette.GetColor($ColorIndex)

            # Appliquer la couleur Ã  la sÃ©rie
            if ($Series.PSObject.Properties.Name -contains "Fill") {
                $Series.Fill.Color.SetColor($Color)
            } elseif ($Series.PSObject.Properties.Name -contains "LineColor") {
                $Series.LineColor.SetColor($Color)
            }
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de l'application de la palette de couleurs: $_"
        return $false
    }
}

#endregion

#region Personnalisation des couleurs par sÃ©rie

<#
.SYNOPSIS
    Modifie la couleur d'une sÃ©rie spÃ©cifique dans un graphique Excel.
.DESCRIPTION
    Cette fonction permet de modifier la couleur d'une sÃ©rie spÃ©cifique dans un graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER SeriesIndex
    L'index de la sÃ©rie Ã  modifier (0-basÃ©).
.PARAMETER Color
    La couleur Ã  appliquer au format hexadÃ©cimal (#RRGGBB).
.PARAMETER Transparency
    Le niveau de transparence Ã  appliquer (0-100, oÃ¹ 0 est opaque et 100 est transparent).
.EXAMPLE
    Set-ExcelChartSeriesColor -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -SeriesIndex 0 -Color "#FF0000" -Transparency 30
.OUTPUTS
    System.Boolean - True si la modification a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesColor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [int]$SeriesIndex,

        [Parameter(Mandatory = $true)]
        [string]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Transparency = 0
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # VÃ©rifier le format de la couleur
        if (-not ($Color -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # VÃ©rifier que l'index de sÃ©rie est valide
        if ($SeriesIndex -lt 0 -or $SeriesIndex -ge $Chart.Series.Count) {
            throw "Index de sÃ©rie invalide: $SeriesIndex. Le graphique contient $($Chart.Series.Count) sÃ©ries."
        }

        # Obtenir la sÃ©rie
        $Series = $Chart.Series[$SeriesIndex]

        # Appliquer la couleur Ã  la sÃ©rie
        if ($Series.PSObject.Properties.Name -contains "Fill") {
            # Pour les graphiques Ã  colonnes, barres, aires, etc.
            $Series.Fill.Color.SetColor($Color)

            # Appliquer la transparence si spÃ©cifiÃ©e
            if ($Transparency -gt 0 -and $Series.Fill.PSObject.Properties.Name -contains "Transparency") {
                $Series.Fill.Transparency = $Transparency
            }
        } elseif ($Series.PSObject.Properties.Name -contains "LineColor") {
            # Pour les graphiques linÃ©aires
            $Series.LineColor.SetColor($Color)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de la modification de la couleur de la sÃ©rie: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Applique un dÃ©gradÃ© de couleurs aux sÃ©ries d'un graphique Excel.
.DESCRIPTION
    Cette fonction applique un dÃ©gradÃ© de couleurs entre deux couleurs spÃ©cifiÃ©es aux sÃ©ries d'un graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER StartColor
    La couleur de dÃ©but du dÃ©gradÃ© au format hexadÃ©cimal (#RRGGBB).
.PARAMETER EndColor
    La couleur de fin du dÃ©gradÃ© au format hexadÃ©cimal (#RRGGBB).
.PARAMETER ReverseOrder
    Si spÃ©cifiÃ©, applique le dÃ©gradÃ© dans l'ordre inverse.
.PARAMETER Transparency
    Le niveau de transparence Ã  appliquer (0-100, oÃ¹ 0 est opaque et 100 est transparent).
.EXAMPLE
    Set-ExcelChartSeriesGradient -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -StartColor "#FF0000" -EndColor "#0000FF"
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesGradient {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [string]$StartColor,

        [Parameter(Mandatory = $true)]
        [string]$EndColor,

        [Parameter(Mandatory = $false)]
        [switch]$ReverseOrder,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Transparency = 0
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # VÃ©rifier le format des couleurs
        if (-not ($StartColor -match '^#[0-9A-Fa-f]{6}$') -or -not ($EndColor -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # Obtenir le nombre de sÃ©ries
        $SeriesCount = $Chart.Series.Count
        if ($SeriesCount -lt 2) {
            # Si une seule sÃ©rie, appliquer la couleur de dÃ©but
            if ($SeriesCount -eq 1) {
                Set-ExcelChartSeriesColor -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName $ChartName -SeriesIndex 0 -Color $StartColor -Transparency $Transparency | Out-Null
            }
            return $true
        }

        # Convertir les couleurs hexadÃ©cimales en composantes RGB
        $StartColorRGB = ConvertFrom-HexColor -HexColor $StartColor
        $EndColorRGB = ConvertFrom-HexColor -HexColor $EndColor

        # Appliquer le dÃ©gradÃ© Ã  chaque sÃ©rie
        for ($i = 0; $i -lt $SeriesCount; $i++) {
            # Calculer la position dans le dÃ©gradÃ© (0 Ã  1)
            $Position = if ($SeriesCount -eq 1) { 0 } else { $i / ($SeriesCount - 1) }

            # Inverser la position si demandÃ©
            if ($ReverseOrder) {
                $Position = 1 - $Position
            }

            # Calculer la couleur interpolÃ©e
            $R = [int]($StartColorRGB.R + ($EndColorRGB.R - $StartColorRGB.R) * $Position)
            $G = [int]($StartColorRGB.G + ($EndColorRGB.G - $StartColorRGB.G) * $Position)
            $B = [int]($StartColorRGB.B + ($EndColorRGB.B - $StartColorRGB.B) * $Position)

            # Formater la couleur en hexadÃ©cimal
            $Color = "#{0:X2}{1:X2}{2:X2}" -f $R, $G, $B

            # Appliquer la couleur Ã  la sÃ©rie
            Set-ExcelChartSeriesColor -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName $ChartName -SeriesIndex $i -Color $Color -Transparency $Transparency | Out-Null
        }

        return $true
    } catch {
        Write-Error "Erreur lors de l'application du dÃ©gradÃ© de couleurs: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Applique une coloration conditionnelle aux sÃ©ries d'un graphique Excel.
.DESCRIPTION
    Cette fonction applique des couleurs diffÃ©rentes aux sÃ©ries d'un graphique Excel en fonction de leurs valeurs.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER PositiveColor
    La couleur Ã  appliquer aux valeurs positives au format hexadÃ©cimal (#RRGGBB).
.PARAMETER NegativeColor
    La couleur Ã  appliquer aux valeurs nÃ©gatives au format hexadÃ©cimal (#RRGGBB).
.PARAMETER NeutralColor
    La couleur Ã  appliquer aux valeurs nulles au format hexadÃ©cimal (#RRGGBB).
.PARAMETER Threshold
    La valeur seuil pour considÃ©rer une valeur comme positive ou nÃ©gative (dÃ©faut: 0).
.PARAMETER Transparency
    Le niveau de transparence Ã  appliquer (0-100, oÃ¹ 0 est opaque et 100 est transparent).
.EXAMPLE
    Set-ExcelChartSeriesConditionalColor -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -PositiveColor "#00FF00" -NegativeColor "#FF0000" -NeutralColor "#CCCCCC"
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesConditionalColor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [string]$PositiveColor,

        [Parameter(Mandatory = $true)]
        [string]$NegativeColor,

        [Parameter(Mandatory = $false)]
        [string]$NeutralColor = "#CCCCCC",

        [Parameter(Mandatory = $false)]
        [double]$Threshold = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Transparency = 0
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # VÃ©rifier le format des couleurs
        if (-not ($PositiveColor -match '^#[0-9A-Fa-f]{6}$') -or
            -not ($NegativeColor -match '^#[0-9A-Fa-f]{6}$') -or
            -not ($NeutralColor -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # Obtenir les sÃ©ries du graphique
        $SeriesCount = $Chart.Series.Count

        # CrÃ©er une feuille temporaire pour analyser les donnÃ©es
        $TempSheetName = "Temp_ConditionalColor_" + [Guid]::NewGuid().ToString().Substring(0, 8)
        $TempSheet = $Workbook.Worksheets.Add($TempSheetName)

        # Pour chaque sÃ©rie, extraire les valeurs et appliquer la couleur conditionnelle
        for ($i = 0; $i -lt $SeriesCount; $i++) {
            $Series = $Chart.Series[$i]

            # Obtenir la plage de donnÃ©es de la sÃ©rie
            $DataRange = $Series.Series

            # Si la plage est vide ou non valide, passer Ã  la sÃ©rie suivante
            if ([string]::IsNullOrEmpty($DataRange)) {
                continue
            }

            # Extraire les valeurs de la sÃ©rie
            $Values = @()

            # Analyser la plage de donnÃ©es
            if ($DataRange -match '(.*?)!(.*?)$') {
                $SheetName = $Matches[1]
                $Range = $Matches[2]

                # Obtenir la feuille source
                $SourceSheet = $null
                foreach ($Sheet in $Workbook.Worksheets) {
                    if ($Sheet.Name -eq $SheetName -or "'$($Sheet.Name)'" -eq $SheetName) {
                        $SourceSheet = $Sheet
                        break
                    }
                }

                if ($null -ne $SourceSheet) {
                    # Copier les valeurs dans la feuille temporaire
                    $SourceSheet.Cells[$Range].Copy($TempSheet.Cells["A1"])

                    # Lire les valeurs
                    $RowCount = $TempSheet.Dimension.Rows
                    for ($row = 1; $row -le $RowCount; $row++) {
                        $Value = $TempSheet.Cells[$row, 1].Value
                        if ($null -ne $Value -and $Value -is [double]) {
                            $Values += $Value
                        }
                    }
                }
            }

            # DÃ©terminer la couleur en fonction des valeurs
            $Color = $NeutralColor

            if ($Values.Count -gt 0) {
                $Average = ($Values | Measure-Object -Average).Average

                if ($Average -gt $Threshold) {
                    $Color = $PositiveColor
                } elseif ($Average -lt $Threshold) {
                    $Color = $NegativeColor
                }
            }

            # Appliquer la couleur Ã  la sÃ©rie
            Set-ExcelChartSeriesColor -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName $ChartName -SeriesIndex $i -Color $Color -Transparency $Transparency | Out-Null
        }

        # Supprimer la feuille temporaire
        $Workbook.Worksheets.Delete($TempSheetName)

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de l'application de la coloration conditionnelle: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Configure la rotation automatique des couleurs pour les sÃ©ries d'un graphique Excel.
.DESCRIPTION
    Cette fonction configure la rotation automatique des couleurs pour les sÃ©ries d'un graphique Excel
    en utilisant une palette de couleurs spÃ©cifiÃ©e.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER PaletteName
    Le nom de la palette de couleurs Ã  utiliser pour la rotation.
.PARAMETER StartIndex
    L'index de dÃ©part dans la palette (0-basÃ©).
.PARAMETER Interval
    L'intervalle entre les couleurs dans la palette (dÃ©faut: 1).
.PARAMETER Transparency
    Le niveau de transparence Ã  appliquer (0-100, oÃ¹ 0 est opaque et 100 est transparent).
.EXAMPLE
    Set-ExcelChartSeriesColorRotation -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -PaletteName "Vivid" -StartIndex 0 -Interval 2
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesColorRotation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [string]$PaletteName,

        [Parameter(Mandatory = $false)]
        [int]$StartIndex = 0,

        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Transparency = 0
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # Obtenir la palette de couleurs
        $Palette = $Global:ExcelColorPaletteRegistry.GetPalette($PaletteName)

        # Obtenir le nombre de sÃ©ries
        $SeriesCount = $Chart.Series.Count

        # Appliquer les couleurs en rotation
        for ($i = 0; $i -lt $SeriesCount; $i++) {
            $ColorIndex = $StartIndex + ($i * $Interval)
            $Color = $Palette.GetColor($ColorIndex)

            # Appliquer la couleur Ã  la sÃ©rie
            Set-ExcelChartSeriesColor -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName $ChartName -SeriesIndex $i -Color $Color -Transparency $Transparency | Out-Null
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de la configuration de la rotation des couleurs: $_"
        return $false
    }
}

#endregion

#region Styles de lignes et marqueurs

# Ã‰numÃ©ration pour les styles de ligne
Enum ExcelLineStyle {
    Solid = 0
    Dash = 1
    Dot = 2
    DashDot = 3
    DashDotDot = 4
    None = 5
}

# Ã‰numÃ©ration pour les styles de bordure
Enum ExcelBorderStyle {
    None = 0
    Thin = 1
    Medium = 2
    Thick = 3
    Double = 4
    Hair = 5
    Dotted = 6
    Dashed = 7
    MediumDashed = 8
    DashDot = 9
    MediumDashDot = 10
    DashDotDot = 11
    MediumDashDotDot = 12
    SlantDashDot = 13
}

# Ã‰numÃ©ration pour les styles de marqueurs
Enum ExcelMarkerStyle {
    # Styles de marqueurs standard
    None = 0        # Aucun marqueur
    Square = 1      # CarrÃ©
    Diamond = 2     # Losange
    Triangle = 3    # Triangle
    X = 4           # X
    Star = 5        # Ã‰toile
    Circle = 6      # Cercle
    Plus = 7        # Plus
    Dash = 8        # Tiret
    Dot = 9         # Point

    # Styles de marqueurs avancÃ©s
    TriangleDown = 10  # Triangle inversÃ©
    Pentagon = 11      # Pentagone
    Hexagon = 12       # Hexagone
    Cross = 13         # Croix
    Picture = 14       # Image personnalisÃ©e
}

# Classe pour la conversion des styles de marqueurs
class ExcelMarkerStyleConverter {
    # Dictionnaire de correspondance entre ExcelMarkerStyle et eMarkerStyle d'EPPlus
    static [hashtable] $StyleMapping = @{
        [ExcelMarkerStyle]::None         = 0          # eMarkerStyle.None
        [ExcelMarkerStyle]::Square       = 1        # eMarkerStyle.Square
        [ExcelMarkerStyle]::Diamond      = 2       # eMarkerStyle.Diamond
        [ExcelMarkerStyle]::Triangle     = 3      # eMarkerStyle.Triangle
        [ExcelMarkerStyle]::X            = 4             # eMarkerStyle.X
        [ExcelMarkerStyle]::Star         = 5          # eMarkerStyle.Star
        [ExcelMarkerStyle]::Circle       = 6        # eMarkerStyle.Circle
        [ExcelMarkerStyle]::Plus         = 7          # eMarkerStyle.Plus
        [ExcelMarkerStyle]::Dash         = 8          # eMarkerStyle.Dash
        [ExcelMarkerStyle]::Dot          = 9           # eMarkerStyle.Dot
        [ExcelMarkerStyle]::TriangleDown = 3  # Utilise Triangle avec rotation
        [ExcelMarkerStyle]::Pentagon     = 1      # Utilise Square comme approximation
        [ExcelMarkerStyle]::Hexagon      = 1       # Utilise Square comme approximation
        [ExcelMarkerStyle]::Cross        = 7         # Utilise Plus comme approximation
        [ExcelMarkerStyle]::Picture      = 0       # Non supportÃ© directement
    }

    # Dictionnaire des descriptions des styles de marqueurs
    static [hashtable] $StyleDescriptions = @{
        [ExcelMarkerStyle]::None         = "Aucun marqueur"
        [ExcelMarkerStyle]::Square       = "Marqueur carrÃ©"
        [ExcelMarkerStyle]::Diamond      = "Marqueur en forme de losange"
        [ExcelMarkerStyle]::Triangle     = "Marqueur en forme de triangle"
        [ExcelMarkerStyle]::X            = "Marqueur en forme de X"
        [ExcelMarkerStyle]::Star         = "Marqueur en forme d'Ã©toile"
        [ExcelMarkerStyle]::Circle       = "Marqueur circulaire"
        [ExcelMarkerStyle]::Plus         = "Marqueur en forme de plus"
        [ExcelMarkerStyle]::Dash         = "Marqueur en forme de tiret"
        [ExcelMarkerStyle]::Dot          = "Marqueur en forme de point"
        [ExcelMarkerStyle]::TriangleDown = "Marqueur en forme de triangle inversÃ©"
        [ExcelMarkerStyle]::Pentagon     = "Marqueur en forme de pentagone"
        [ExcelMarkerStyle]::Hexagon      = "Marqueur en forme d'hexagone"
        [ExcelMarkerStyle]::Cross        = "Marqueur en forme de croix"
        [ExcelMarkerStyle]::Picture      = "Marqueur avec image personnalisÃ©e"
    }

    # MÃ©thode pour convertir ExcelMarkerStyle en eMarkerStyle d'EPPlus
    static [int] ToEPPlusStyle([ExcelMarkerStyle]$Style) {
        return [ExcelMarkerStyleConverter]::StyleMapping[$Style]
    }

    # MÃ©thode pour obtenir la description d'un style de marqueur
    static [string] GetDescription([ExcelMarkerStyle]$Style) {
        return [ExcelMarkerStyleConverter]::StyleDescriptions[$Style]
    }

    # MÃ©thode pour obtenir tous les styles disponibles avec leurs descriptions
    static [PSObject[]] GetAllStyles() {
        $Result = @()

        foreach ($Style in [Enum]::GetValues([ExcelMarkerStyle])) {
            $StyleInfo = [PSCustomObject]@{
                Style       = $Style
                Name        = $Style.ToString()
                Description = [ExcelMarkerStyleConverter]::GetDescription($Style)
                EPPlusValue = [ExcelMarkerStyleConverter]::ToEPPlusStyle($Style)
            }

            $Result += $StyleInfo
        }

        return $Result
    }

    # MÃ©thode pour vÃ©rifier si un style nÃ©cessite un traitement spÃ©cial
    static [bool] RequiresSpecialHandling([ExcelMarkerStyle]$Style) {
        return $Style -in @(
            [ExcelMarkerStyle]::TriangleDown,
            [ExcelMarkerStyle]::Pentagon,
            [ExcelMarkerStyle]::Hexagon,
            [ExcelMarkerStyle]::Cross,
            [ExcelMarkerStyle]::Picture
        )
    }

    # Tailles de marqueurs prÃ©dÃ©finies
    static [hashtable] $PredefinedSizes = @{
        "Tiny"       = 3
        "Small"      = 5
        "Medium"     = 7
        "Large"      = 10
        "ExtraLarge" = 15
        "Huge"       = 20
    }

    # Limites de taille
    static [int] $MinSize = 1
    static [int] $MaxSize = 25
    static [int] $DefaultSize = 7

    # MÃ©thode pour valider une taille de marqueur
    static [bool] ValidateSize([int]$Size) {
        return $Size -ge [ExcelMarkerStyleConverter]::MinSize -and $Size -le [ExcelMarkerStyleConverter]::MaxSize
    }

    # MÃ©thode pour obtenir une taille prÃ©dÃ©finie
    static [int] GetPredefinedSize([string]$SizeName) {
        if ([ExcelMarkerStyleConverter]::PredefinedSizes.ContainsKey($SizeName)) {
            return [ExcelMarkerStyleConverter]::PredefinedSizes[$SizeName]
        }
        return [ExcelMarkerStyleConverter]::DefaultSize
    }

    # MÃ©thode pour obtenir toutes les tailles prÃ©dÃ©finies
    static [PSObject[]] GetAllPredefinedSizes() {
        $Result = @()

        foreach ($SizeName in [ExcelMarkerStyleConverter]::PredefinedSizes.Keys) {
            $SizeValue = [ExcelMarkerStyleConverter]::PredefinedSizes[$SizeName]
            $SizeInfo = [PSCustomObject]@{
                Name  = $SizeName
                Value = $SizeValue
            }

            $Result += $SizeInfo
        }

        return $Result
    }

    # MÃ©thode pour appliquer un style de marqueur Ã  une sÃ©rie
    static [void] ApplyToSeries([object]$Series, [ExcelMarkerStyle]$Style, [int]$Size = 7) {
        if ($null -eq $Series) {
            return
        }

        # VÃ©rifier si la sÃ©rie supporte les marqueurs
        if (-not ($Series.PSObject.Properties.Name -contains "MarkerStyle")) {
            return
        }

        # Valider et ajuster la taille si nÃ©cessaire
        if (-not [ExcelMarkerStyleConverter]::ValidateSize($Size)) {
            $Size = [Math]::Max([ExcelMarkerStyleConverter]::MinSize, [Math]::Min($Size, [ExcelMarkerStyleConverter]::MaxSize))
        }

        # Appliquer le style de marqueur de base
        $Series.MarkerStyle = [ExcelMarkerStyleConverter]::ToEPPlusStyle($Style)

        # Appliquer la taille du marqueur
        if ($Series.PSObject.Properties.Name -contains "MarkerSize") {
            $Series.MarkerSize = $Size
        }

        # Traitement spÃ©cial pour certains styles
        if ([ExcelMarkerStyleConverter]::RequiresSpecialHandling($Style)) {
            switch ($Style) {
                ([ExcelMarkerStyle]::TriangleDown) {
                    # Pour un triangle inversÃ©, on utilise un triangle normal avec une rotation
                    if ($Series.PSObject.Properties.Name -contains "MarkerRotation") {
                        $Series.MarkerRotation = 180
                    }
                }
                ([ExcelMarkerStyle]::Pentagon) {
                    # ApproximÃ© par un carrÃ© pour l'instant
                    # Aucun traitement spÃ©cial supplÃ©mentaire
                }
                ([ExcelMarkerStyle]::Hexagon) {
                    # ApproximÃ© par un carrÃ© pour l'instant
                    # Aucun traitement spÃ©cial supplÃ©mentaire
                }
                ([ExcelMarkerStyle]::Cross) {
                    # ApproximÃ© par un plus pour l'instant
                    # Aucun traitement spÃ©cial supplÃ©mentaire
                }
                ([ExcelMarkerStyle]::Picture) {
                    # Le support d'images personnalisÃ©es nÃ©cessiterait une implÃ©mentation spÃ©cifique
                    # Non implÃ©mentÃ© pour l'instant
                }
            }
        }
    }
}

# Classe pour configurer les marqueurs
class ExcelMarkerConfig {
    [ExcelMarkerStyle]$Style = [ExcelMarkerStyle]::Circle
    [int]$Size = 7
    [string]$Color = "#000000"
    [string]$BorderColor = ""
    [int]$BorderWidth = 1
    [string]$Description = ""

    # Constructeur par dÃ©faut
    ExcelMarkerConfig() {
        $this.Description = "Configuration de marqueur par dÃ©faut"
    }

    # Constructeur avec style et taille
    ExcelMarkerConfig([ExcelMarkerStyle]$Style, [int]$Size) {
        $this.Style = $Style
        $this.Size = $Size
        $this.Description = "Marqueur $($Style) de taille $Size"
    }

    # Constructeur complet
    ExcelMarkerConfig([ExcelMarkerStyle]$Style, [int]$Size, [string]$Color, [string]$BorderColor, [int]$BorderWidth, [string]$Description) {
        $this.Style = $Style
        $this.Size = $Size
        $this.Color = $Color
        $this.BorderColor = $BorderColor
        $this.BorderWidth = $BorderWidth
        $this.Description = $Description
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Valider la taille
        if (-not [ExcelMarkerStyleConverter]::ValidateSize($this.Size)) {
            return $false
        }

        # Valider la largeur de bordure
        if ($this.BorderWidth -lt 1 -or $this.BorderWidth -gt 5) {
            return $false
        }

        # Valider le format des couleurs
        if ($this.Color -ne "" -and -not ($this.Color -match '^#[0-9A-Fa-f]{6}$')) {
            return $false
        }

        if ($this.BorderColor -ne "" -and -not ($this.BorderColor -match '^#[0-9A-Fa-f]{6}$')) {
            return $false
        }

        return $true
    }

    # MÃ©thode pour crÃ©er une copie de la configuration
    [ExcelMarkerConfig] Clone() {
        $Clone = [ExcelMarkerConfig]::new()
        $Clone.Style = $this.Style
        $Clone.Size = $this.Size
        $Clone.Color = $this.Color
        $Clone.BorderColor = $this.BorderColor
        $Clone.BorderWidth = $this.BorderWidth
        $Clone.Description = $this.Description

        return $Clone
    }

    # MÃ©thode pour appliquer la configuration Ã  une sÃ©rie
    [void] ApplyToSeries([object]$Series) {
        if ($null -eq $Series) {
            return
        }

        # Appliquer le style et la taille
        [ExcelMarkerStyleConverter]::ApplyToSeries($Series, $this.Style, $this.Size)

        # Appliquer la couleur du marqueur si spÃ©cifiÃ©e
        if ($this.Color -ne "" -and $Series.PSObject.Properties.Name -contains "MarkerColor") {
            $Series.MarkerColor.SetColor($this.Color)
        }

        # Appliquer la couleur de bordure si spÃ©cifiÃ©e
        if ($this.BorderColor -ne "" -and $Series.PSObject.Properties.Name -contains "MarkerBorderColor") {
            $Series.MarkerBorderColor.SetColor($this.BorderColor)
        }

        # Appliquer la largeur de bordure si spÃ©cifiÃ©e
        if ($Series.PSObject.Properties.Name -contains "MarkerBorderWidth") {
            $Series.MarkerBorderWidth = $this.BorderWidth
        }
    }

    # MÃ©thode pour appliquer la configuration Ã  un point de donnÃ©es
    [void] ApplyToDataPoint([object]$DataPoint) {
        if ($null -eq $DataPoint) {
            return
        }

        # Appliquer le style de marqueur
        if ($DataPoint.PSObject.Properties.Name -contains "MarkerStyle") {
            $DataPoint.MarkerStyle = [ExcelMarkerStyleConverter]::ToEPPlusStyle($this.Style)
        }

        # Appliquer la taille du marqueur
        if ($DataPoint.PSObject.Properties.Name -contains "MarkerSize") {
            $DataPoint.MarkerSize = $this.Size
        }

        # Appliquer la couleur du marqueur si spÃ©cifiÃ©e
        if ($this.Color -ne "" -and $DataPoint.PSObject.Properties.Name -contains "MarkerColor") {
            $DataPoint.MarkerColor.SetColor($this.Color)
        }

        # Appliquer la couleur de bordure si spÃ©cifiÃ©e
        if ($this.BorderColor -ne "" -and $DataPoint.PSObject.Properties.Name -contains "MarkerBorderColor") {
            $DataPoint.MarkerBorderColor.SetColor($this.BorderColor)
        }

        # Appliquer la largeur de bordure si spÃ©cifiÃ©e
        if ($DataPoint.PSObject.Properties.Name -contains "MarkerBorderWidth") {
            $DataPoint.MarkerBorderWidth = $this.BorderWidth
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "$($this.Description) (Style: $($this.Style), Taille: $($this.Size))"
    }
}

# Classe pour reprÃ©senter un style de ligne
class ExcelLineStyleConfig {
    [int]$Width = 1                          # Largeur de la ligne (1-10)
    [ExcelLineStyle]$Style = [ExcelLineStyle]::Solid  # Style de la ligne
    [string]$Color = "#000000"               # Couleur de la ligne
    [int]$Transparency = 0                   # Transparence (0-100)
    [bool]$Smooth = $false                   # Lissage des lignes (pour les graphiques linÃ©aires)
    [string]$Description = ""                # Description du style
    [bool]$IsBuiltIn = $false                # Indique si c'est un style prÃ©dÃ©fini

    # Constructeur par dÃ©faut
    ExcelLineStyleConfig() {
        $this.Description = "Style de ligne par dÃ©faut"
    }

    # Constructeur avec paramÃ¨tres de base
    ExcelLineStyleConfig([int]$Width, [ExcelLineStyle]$Style, [string]$Color) {
        $this.Width = $Width
        $this.Style = $Style
        $this.Color = $Color
        $this.Description = "Style de ligne personnalisÃ©"
    }

    # Constructeur complet
    ExcelLineStyleConfig([int]$Width, [ExcelLineStyle]$Style, [string]$Color, [int]$Transparency, [bool]$Smooth, [string]$Description) {
        $this.Width = $Width
        $this.Style = $Style
        $this.Color = $Color
        $this.Transparency = $Transparency
        $this.Smooth = $Smooth
        $this.Description = $Description
    }

    # MÃ©thode pour valider le style
    [bool] Validate() {
        # VÃ©rifier la largeur
        if ($this.Width -lt 1 -or $this.Width -gt 10) {
            return $false
        }

        # VÃ©rifier la transparence
        if ($this.Transparency -lt 0 -or $this.Transparency -gt 100) {
            return $false
        }

        # VÃ©rifier le format de la couleur
        if (-not ($this.Color -match '^#[0-9A-Fa-f]{6}$')) {
            return $false
        }

        return $true
    }

    # MÃ©thode pour crÃ©er une copie du style
    [ExcelLineStyleConfig] Clone() {
        $Clone = [ExcelLineStyleConfig]::new()
        $Clone.Width = $this.Width
        $Clone.Style = $this.Style
        $Clone.Color = $this.Color
        $Clone.Transparency = $this.Transparency
        $Clone.Smooth = $this.Smooth
        $Clone.Description = $this.Description
        $Clone.IsBuiltIn = $false  # Une copie n'est jamais un style prÃ©dÃ©fini

        return $Clone
    }

    # MÃ©thode pour appliquer le style Ã  une sÃ©rie
    [void] ApplyToSeries([object]$Series) {
        if ($null -eq $Series) {
            return
        }

        # Appliquer la couleur
        if ($Series.PSObject.Properties.Name -contains "LineColor") {
            $Series.LineColor.SetColor($this.Color)
        }

        # Appliquer la largeur
        if ($Series.PSObject.Properties.Name -contains "LineWidth") {
            $Series.LineWidth = $this.Width
        }

        # Appliquer le style de ligne
        if ($Series.PSObject.Properties.Name -contains "LineStyle") {
            switch ($this.Style) {
                ([ExcelLineStyle]::Solid) { $Series.LineStyle = [OfficeOpenXml.Drawing.Chart.eLineStyle]::Solid }
                ([ExcelLineStyle]::Dash) { $Series.LineStyle = [OfficeOpenXml.Drawing.Chart.eLineStyle]::Dash }
                ([ExcelLineStyle]::Dot) { $Series.LineStyle = [OfficeOpenXml.Drawing.Chart.eLineStyle]::Dot }
                ([ExcelLineStyle]::DashDot) { $Series.LineStyle = [OfficeOpenXml.Drawing.Chart.eLineStyle]::DashDot }
                ([ExcelLineStyle]::DashDotDot) { $Series.LineStyle = [OfficeOpenXml.Drawing.Chart.eLineStyle]::DashDotDot }
                ([ExcelLineStyle]::None) { $Series.LineStyle = [OfficeOpenXml.Drawing.Chart.eLineStyle]::None }
            }
        }

        # Appliquer la transparence
        if ($this.Transparency -gt 0 -and $Series.PSObject.Properties.Name -contains "Transparency") {
            $Series.Transparency = $this.Transparency
        }

        # Appliquer le lissage
        if ($Series.PSObject.Properties.Name -contains "Smooth") {
            $Series.Smooth = $this.Smooth
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "$($this.Description) (Largeur: $($this.Width), Style: $($this.Style), Couleur: $($this.Color))"
    }
}

# Classe pour gÃ©rer un registre de styles de ligne
class ExcelLineStyleRegistry {
    [System.Collections.Generic.Dictionary[string, ExcelLineStyleConfig]] $Styles

    # Constructeur
    ExcelLineStyleRegistry() {
        $this.Styles = [System.Collections.Generic.Dictionary[string, ExcelLineStyleConfig]]::new()
        $this.InitializeBuiltInStyles()
    }

    # MÃ©thode pour initialiser les styles prÃ©dÃ©finis
    [void] InitializeBuiltInStyles() {
        # Style par dÃ©faut
        $DefaultStyle = [ExcelLineStyleConfig]::new()
        $DefaultStyle.Description = "Style par dÃ©faut"
        $DefaultStyle.IsBuiltIn = $true
        $this.Styles.Add("Default", $DefaultStyle)

        # Style fin
        $ThinStyle = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Solid, "#000000")
        $ThinStyle.Description = "Ligne fine"
        $ThinStyle.IsBuiltIn = $true
        $this.Styles.Add("Thin", $ThinStyle)

        # Style Ã©pais
        $ThickStyle = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Solid, "#000000")
        $ThickStyle.Description = "Ligne Ã©paisse"
        $ThickStyle.IsBuiltIn = $true
        $this.Styles.Add("Thick", $ThickStyle)

        # Style pointillÃ©
        $DottedStyle = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dot, "#000000")
        $DottedStyle.Description = "Ligne pointillÃ©e"
        $DottedStyle.IsBuiltIn = $true
        $this.Styles.Add("Dotted", $DottedStyle)

        # Style tirets
        $DashedStyle = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
        $DashedStyle.Description = "Ligne en tirets"
        $DashedStyle.IsBuiltIn = $true
        $this.Styles.Add("Dashed", $DashedStyle)

        # Style tiret-point
        $DashDotStyle = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
        $DashDotStyle.Description = "Ligne tiret-point"
        $DashDotStyle.IsBuiltIn = $true
        $this.Styles.Add("DashDot", $DashDotStyle)

        # Style rouge Ã©pais
        $ThickRedStyle = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Solid, "#FF0000")
        $ThickRedStyle.Description = "Ligne rouge Ã©paisse"
        $ThickRedStyle.IsBuiltIn = $true
        $this.Styles.Add("ThickRed", $ThickRedStyle)

        # Style bleu fin
        $ThinBlueStyle = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Solid, "#0000FF")
        $ThinBlueStyle.Description = "Ligne bleue fine"
        $ThinBlueStyle.IsBuiltIn = $true
        $this.Styles.Add("ThinBlue", $ThinBlueStyle)

        # Style vert pointillÃ©
        $DottedGreenStyle = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dot, "#00FF00")
        $DottedGreenStyle.Description = "Ligne verte pointillÃ©e"
        $DottedGreenStyle.IsBuiltIn = $true
        $this.Styles.Add("DottedGreen", $DottedGreenStyle)

        # Style lissÃ©
        $SmoothStyle = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#000000")
        $SmoothStyle.Smooth = $true
        $SmoothStyle.Description = "Ligne lissÃ©e"
        $SmoothStyle.IsBuiltIn = $true
        $this.Styles.Add("Smooth", $SmoothStyle)
    }

    # MÃ©thode pour obtenir un style par son nom
    [ExcelLineStyleConfig] GetStyle([string]$Name) {
        if ($this.Styles.ContainsKey($Name)) {
            return $this.Styles[$Name]
        }

        # Retourner le style par dÃ©faut si le nom n'existe pas
        return $this.Styles["Default"]
    }

    # MÃ©thode pour ajouter un nouveau style
    [void] AddStyle([string]$Name, [ExcelLineStyleConfig]$Style) {
        if ($this.Styles.ContainsKey($Name)) {
            # Remplacer le style existant s'il n'est pas prÃ©dÃ©fini
            $ExistingStyle = $this.Styles[$Name]
            if (-not $ExistingStyle.IsBuiltIn) {
                $this.Styles[$Name] = $Style
            }
        } else {
            # Ajouter le nouveau style
            $this.Styles.Add($Name, $Style)
        }
    }

    # MÃ©thode pour supprimer un style
    [bool] RemoveStyle([string]$Name) {
        if ($this.Styles.ContainsKey($Name)) {
            $Style = $this.Styles[$Name]
            if (-not $Style.IsBuiltIn) {
                return $this.Styles.Remove($Name)
            }
        }
        return $false
    }

    # MÃ©thode pour lister tous les styles disponibles
    [ExcelLineStyleConfig[]] ListStyles() {
        return $this.Styles.Values
    }

    # MÃ©thode pour lister les noms de tous les styles
    [string[]] ListStyleNames() {
        return $this.Styles.Keys
    }
}

# CrÃ©er une instance globale du registre de styles de ligne
$Global:ExcelLineStyleRegistry = [ExcelLineStyleRegistry]::new()

<#
.SYNOPSIS
    Obtient un style de ligne par son nom.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re un style de ligne prÃ©dÃ©fini ou personnalisÃ© par son nom.
.PARAMETER Name
    Nom du style Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $Style = Get-ExcelLineStyle -Name "Dashed"
.OUTPUTS
    ExcelLineStyleConfig - Le style de ligne demandÃ©.
#>
function Get-ExcelLineStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $Global:ExcelLineStyleRegistry.GetStyle($Name)
}

<#
.SYNOPSIS
    CrÃ©e un nouveau style de ligne personnalisÃ©.
.DESCRIPTION
    Cette fonction crÃ©e un nouveau style de ligne personnalisÃ© avec les propriÃ©tÃ©s spÃ©cifiÃ©es.
.PARAMETER Name
    Nom du nouveau style.
.PARAMETER Width
    Largeur de la ligne (1-10).
.PARAMETER Style
    Style de la ligne (Solid, Dash, Dot, DashDot, DashDotDot, None).
.PARAMETER Color
    Couleur de la ligne au format hexadÃ©cimal (#RRGGBB).
.PARAMETER Transparency
    Transparence de la ligne (0-100).
.PARAMETER Smooth
    Indique si la ligne doit Ãªtre lissÃ©e.
.PARAMETER Description
    Description du style (optionnel).
.EXAMPLE
    New-ExcelLineStyle -Name "MonStyle" -Width 2 -Style Dash -Color "#FF0000" -Description "Mon style personnalisÃ©"
.OUTPUTS
    ExcelLineStyleConfig - Le nouveau style de ligne crÃ©Ã©.
#>
function New-ExcelLineStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 10)]
        [int]$Width,

        [Parameter(Mandatory = $true)]
        [ExcelLineStyle]$Style,

        [Parameter(Mandatory = $true)]
        [string]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Transparency = 0,

        [Parameter(Mandatory = $false)]
        [bool]$Smooth = $false,

        [Parameter(Mandatory = $false)]
        [string]$Description = "Style personnalisÃ©"
    )

    # CrÃ©er le nouveau style
    $LineStyle = [ExcelLineStyleConfig]::new($Width, $Style, $Color, $Transparency, $Smooth, $Description)

    # Valider le style
    if (-not $LineStyle.Validate()) {
        throw "Style de ligne invalide. VÃ©rifiez les paramÃ¨tres."
    }

    # Ajouter le style au registre
    $Global:ExcelLineStyleRegistry.AddStyle($Name, $LineStyle)

    return $LineStyle
}

<#
.SYNOPSIS
    Liste tous les styles de ligne disponibles.
.DESCRIPTION
    Cette fonction liste tous les styles de ligne prÃ©dÃ©finis et personnalisÃ©s disponibles.
.PARAMETER BuiltInOnly
    Si spÃ©cifiÃ©, liste uniquement les styles prÃ©dÃ©finis.
.PARAMETER CustomOnly
    Si spÃ©cifiÃ©, liste uniquement les styles personnalisÃ©s.
.EXAMPLE
    Get-ExcelLineStyleList -BuiltInOnly
.OUTPUTS
    PSObject[] - Liste des styles disponibles avec leurs propriÃ©tÃ©s.
#>
function Get-ExcelLineStyleList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$BuiltInOnly,

        [Parameter(Mandatory = $false)]
        [switch]$CustomOnly
    )

    $Styles = $Global:ExcelLineStyleRegistry.ListStyles()
    $Result = @()

    foreach ($Style in $Styles) {
        # Filtrer selon les paramÃ¨tres
        if ($BuiltInOnly -and -not $Style.IsBuiltIn) {
            continue
        }

        if ($CustomOnly -and $Style.IsBuiltIn) {
            continue
        }

        $StyleInfo = [PSCustomObject]@{
            Name         = $Styles.Keys | Where-Object { $Styles[$_] -eq $Style } | Select-Object -First 1
            Description  = $Style.Description
            Width        = $Style.Width
            Style        = $Style.Style
            Color        = $Style.Color
            Transparency = $Style.Transparency
            Smooth       = $Style.Smooth
            IsBuiltIn    = $Style.IsBuiltIn
        }

        $Result += $StyleInfo
    }

    return $Result
}

<#
.SYNOPSIS
    Supprime un style de ligne personnalisÃ©.
.DESCRIPTION
    Cette fonction supprime un style de ligne personnalisÃ© du registre.
    Les styles prÃ©dÃ©finis ne peuvent pas Ãªtre supprimÃ©s.
.PARAMETER Name
    Nom du style Ã  supprimer.
.EXAMPLE
    Remove-ExcelLineStyle -Name "MonStyle"
.OUTPUTS
    System.Boolean - True si la suppression a rÃ©ussi, False sinon.
#>
function Remove-ExcelLineStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $Global:ExcelLineStyleRegistry.RemoveStyle($Name)
}

<#
.SYNOPSIS
    Applique un style de ligne Ã  une sÃ©rie dans un graphique Excel.
.DESCRIPTION
    Cette fonction applique un style de ligne spÃ©cifiÃ© Ã  une sÃ©rie dans un graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER SeriesIndex
    L'index de la sÃ©rie Ã  modifier (0-basÃ©).
.PARAMETER StyleName
    Le nom du style de ligne Ã  appliquer.
.PARAMETER Style
    Un objet de style de ligne Ã  appliquer (alternative Ã  StyleName).
.EXAMPLE
    Set-ExcelChartSeriesLineStyle -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -SeriesIndex 0 -StyleName "Dashed"
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesLineStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [int]$SeriesIndex,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string]$StyleName,

        [Parameter(Mandatory = $true, ParameterSetName = "ByObject")]
        [ExcelLineStyleConfig]$Style
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # VÃ©rifier que l'index de sÃ©rie est valide
        if ($SeriesIndex -lt 0 -or $SeriesIndex -ge $Chart.Series.Count) {
            throw "Index de sÃ©rie invalide: $SeriesIndex. Le graphique contient $($Chart.Series.Count) sÃ©ries."
        }

        # Obtenir la sÃ©rie
        $Series = $Chart.Series[$SeriesIndex]

        # Obtenir le style de ligne
        if ($PSCmdlet.ParameterSetName -eq "ByName") {
            $LineStyle = $Global:ExcelLineStyleRegistry.GetStyle($StyleName)
        } else {
            $LineStyle = $Style
        }

        # Appliquer le style Ã  la sÃ©rie
        $LineStyle.ApplyToSeries($Series)

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de l'application du style de ligne: $_"
        return $false
    }
}

#endregion

<#
.SYNOPSIS
    Liste tous les styles de marqueurs disponibles.
.DESCRIPTION
    Cette fonction liste tous les styles de marqueurs disponibles avec leurs descriptions.
.EXAMPLE
    Get-ExcelMarkerStyleList
.OUTPUTS
    PSObject[] - Liste des styles de marqueurs disponibles avec leurs propriÃ©tÃ©s.
#>
function Get-ExcelMarkerStyleList {
    [CmdletBinding()]
    param ()

    return [ExcelMarkerStyleConverter]::GetAllStyles()
}

<#
.SYNOPSIS
    Liste toutes les tailles de marqueurs prÃ©dÃ©finies.
.DESCRIPTION
    Cette fonction liste toutes les tailles de marqueurs prÃ©dÃ©finies disponibles.
.EXAMPLE
    Get-ExcelMarkerSizeList
.OUTPUTS
    PSObject[] - Liste des tailles prÃ©dÃ©finies avec leurs valeurs.
#>
function Get-ExcelMarkerSizeList {
    [CmdletBinding()]
    param ()

    return [ExcelMarkerStyleConverter]::GetAllPredefinedSizes()
}

<#
.SYNOPSIS
    CrÃ©e une nouvelle configuration de marqueur.
.DESCRIPTION
    Cette fonction crÃ©e une nouvelle configuration de marqueur avec les propriÃ©tÃ©s spÃ©cifiÃ©es.
.PARAMETER Style
    Le style de marqueur Ã  utiliser.
.PARAMETER Size
    La taille du marqueur (1-25).
.PARAMETER SizeName
    Le nom d'une taille prÃ©dÃ©finie (Tiny, Small, Medium, Large, ExtraLarge, Huge).
.PARAMETER Color
    La couleur du marqueur au format hexadÃ©cimal (#RRGGBB).
.PARAMETER BorderColor
    La couleur de bordure du marqueur au format hexadÃ©cimal (#RRGGBB).
.PARAMETER BorderWidth
    La largeur de la bordure du marqueur (1-5).
.PARAMETER Description
    Description de la configuration (optionnel).
.EXAMPLE
    $MarkerConfig = New-ExcelMarkerConfig -Style Diamond -Size 10 -Color "#FF0000" -BorderColor "#000000" -BorderWidth 2
.EXAMPLE
    $MarkerConfig = New-ExcelMarkerConfig -Style Circle -SizeName "Large" -Color "#0000FF"
.OUTPUTS
    ExcelMarkerConfig - La nouvelle configuration de marqueur crÃ©Ã©e.
#>
function New-ExcelMarkerConfig {
    [CmdletBinding(DefaultParameterSetName = "BySize")]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelMarkerStyle]$Style,

        [Parameter(Mandatory = $true, ParameterSetName = "BySize")]
        [ValidateRange(1, 25)]
        [int]$Size,

        [Parameter(Mandatory = $true, ParameterSetName = "BySizeName")]
        [ValidateSet("Tiny", "Small", "Medium", "Large", "ExtraLarge", "Huge")]
        [string]$SizeName,

        [Parameter(Mandatory = $false)]
        [string]$Color = "#000000",

        [Parameter(Mandatory = $false)]
        [string]$BorderColor = "",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$BorderWidth = 1,

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    # DÃ©terminer la taille Ã  utiliser
    $ActualSize = if ($PSCmdlet.ParameterSetName -eq "BySizeName") {
        [ExcelMarkerStyleConverter]::GetPredefinedSize($SizeName)
    } else {
        $Size
    }

    # CrÃ©er la description si non spÃ©cifiÃ©e
    if ([string]::IsNullOrEmpty($Description)) {
        $SizeDesc = if ($PSCmdlet.ParameterSetName -eq "BySizeName") { $SizeName } else { $ActualSize }
        $Description = "Marqueur $Style de taille $SizeDesc"
    }

    # CrÃ©er la configuration
    $MarkerConfig = [ExcelMarkerConfig]::new($Style, $ActualSize, $Color, $BorderColor, $BorderWidth, $Description)

    # Valider la configuration
    if (-not $MarkerConfig.Validate()) {
        throw "Configuration de marqueur invalide. VÃ©rifiez les paramÃ¨tres."
    }

    return $MarkerConfig
}

<#
.SYNOPSIS
    Applique un style de marqueur Ã  une sÃ©rie dans un graphique Excel.
.DESCRIPTION
    Cette fonction applique un style de marqueur spÃ©cifiÃ© Ã  une sÃ©rie dans un graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER SeriesIndex
    L'index de la sÃ©rie Ã  modifier (0-basÃ©).
.PARAMETER MarkerStyle
    Le style de marqueur Ã  appliquer.
.PARAMETER Size
    La taille du marqueur (1-25).
.PARAMETER Color
    La couleur du marqueur au format hexadÃ©cimal (#RRGGBB).
.PARAMETER BorderColor
    La couleur de bordure du marqueur au format hexadÃ©cimal (#RRGGBB).
.PARAMETER BorderWidth
    La largeur de la bordure du marqueur (1-5).
.EXAMPLE
    Set-ExcelChartSeriesMarkerStyle -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -SeriesIndex 0 -MarkerStyle Diamond -Size 10 -Color "#FF0000" -BorderColor "#000000" -BorderWidth 2
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesMarkerStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [int]$SeriesIndex,

        [Parameter(Mandatory = $true)]
        [ExcelMarkerStyle]$MarkerStyle,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 25)]
        [int]$Size = 7,

        [Parameter(Mandatory = $false)]
        [string]$Color = "",

        [Parameter(Mandatory = $false)]
        [string]$BorderColor = "",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$BorderWidth = 1
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # VÃ©rifier le format des couleurs
        if ($Color -ne "" -and -not ($Color -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide pour le marqueur. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        if ($BorderColor -ne "" -and -not ($BorderColor -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide pour la bordure. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # VÃ©rifier que l'index de sÃ©rie est valide
        if ($SeriesIndex -lt 0 -or $SeriesIndex -ge $Chart.Series.Count) {
            throw "Index de sÃ©rie invalide: $SeriesIndex. Le graphique contient $($Chart.Series.Count) sÃ©ries."
        }

        # Obtenir la sÃ©rie
        $Series = $Chart.Series[$SeriesIndex]

        # Appliquer le style de marqueur
        [ExcelMarkerStyleConverter]::ApplyToSeries($Series, $MarkerStyle, $Size)

        # Appliquer la couleur du marqueur si spÃ©cifiÃ©e
        if ($Color -ne "" -and $Series.PSObject.Properties.Name -contains "MarkerColor") {
            $Series.MarkerColor.SetColor($Color)
        }

        # Appliquer la couleur de bordure si spÃ©cifiÃ©e
        if ($BorderColor -ne "" -and $Series.PSObject.Properties.Name -contains "MarkerBorderColor") {
            $Series.MarkerBorderColor.SetColor($BorderColor)
        }

        # Appliquer la largeur de bordure si spÃ©cifiÃ©e
        if ($Series.PSObject.Properties.Name -contains "MarkerBorderWidth") {
            $Series.MarkerBorderWidth = $BorderWidth
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de l'application du style de marqueur: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Applique un style de marqueur Ã  un point de donnÃ©es spÃ©cifique dans un graphique Excel.
.DESCRIPTION
    Cette fonction applique un style de marqueur spÃ©cifiÃ© Ã  un point de donnÃ©es spÃ©cifique dans un graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER SeriesIndex
    L'index de la sÃ©rie contenant le point de donnÃ©es (0-basÃ©).
.PARAMETER PointIndex
    L'index du point de donnÃ©es Ã  modifier (0-basÃ©).
.PARAMETER MarkerStyle
    Le style de marqueur Ã  appliquer.
.PARAMETER Size
    La taille du marqueur (1-25).
.PARAMETER Color
    La couleur du marqueur au format hexadÃ©cimal (#RRGGBB).
.PARAMETER BorderColor
    La couleur de bordure du marqueur au format hexadÃ©cimal (#RRGGBB).
.PARAMETER BorderWidth
    La largeur de la bordure du marqueur (1-5).
.EXAMPLE
    Set-ExcelChartDataPointMarkerStyle -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -SeriesIndex 0 -PointIndex 2 -MarkerStyle Star -Size 12 -Color "#00FF00"
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartDataPointMarkerStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [int]$SeriesIndex,

        [Parameter(Mandatory = $true)]
        [int]$PointIndex,

        [Parameter(Mandatory = $true)]
        [ExcelMarkerStyle]$MarkerStyle,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 25)]
        [int]$Size = 7,

        [Parameter(Mandatory = $false)]
        [string]$Color = "",

        [Parameter(Mandatory = $false)]
        [string]$BorderColor = "",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$BorderWidth = 1
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # VÃ©rifier le format des couleurs
        if ($Color -ne "" -and -not ($Color -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide pour le marqueur. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        if ($BorderColor -ne "" -and -not ($BorderColor -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide pour la bordure. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # VÃ©rifier que l'index de sÃ©rie est valide
        if ($SeriesIndex -lt 0 -or $SeriesIndex -ge $Chart.Series.Count) {
            throw "Index de sÃ©rie invalide: $SeriesIndex. Le graphique contient $($Chart.Series.Count) sÃ©ries."
        }

        # Obtenir la sÃ©rie
        $Series = $Chart.Series[$SeriesIndex]

        # VÃ©rifier si la sÃ©rie supporte les points de donnÃ©es
        if (-not ($Series.PSObject.Properties.Name -contains "Points")) {
            throw "La sÃ©rie ne supporte pas la personnalisation par point de donnÃ©es."
        }

        # VÃ©rifier que l'index de point est valide
        if ($PointIndex -lt 0 -or $PointIndex -ge $Series.Points.Count) {
            throw "Index de point invalide: $PointIndex. La sÃ©rie contient $($Series.Points.Count) points."
        }

        # Obtenir le point de donnÃ©es
        $DataPoint = $Series.Points[$PointIndex]

        # Appliquer le style de marqueur
        if ($DataPoint.PSObject.Properties.Name -contains "MarkerStyle") {
            $DataPoint.MarkerStyle = [ExcelMarkerStyleConverter]::ToEPPlusStyle($MarkerStyle)
        }

        # Appliquer la taille du marqueur
        if ($DataPoint.PSObject.Properties.Name -contains "MarkerSize") {
            $DataPoint.MarkerSize = $Size
        }

        # Appliquer la couleur du marqueur si spÃ©cifiÃ©e
        if ($Color -ne "" -and $DataPoint.PSObject.Properties.Name -contains "MarkerColor") {
            $DataPoint.MarkerColor.SetColor($Color)
        }

        # Appliquer la couleur de bordure si spÃ©cifiÃ©e
        if ($BorderColor -ne "" -and $DataPoint.PSObject.Properties.Name -contains "MarkerBorderColor") {
            $DataPoint.MarkerBorderColor.SetColor($BorderColor)
        }

        # Appliquer la largeur de bordure si spÃ©cifiÃ©e
        if ($DataPoint.PSObject.Properties.Name -contains "MarkerBorderWidth") {
            $DataPoint.MarkerBorderWidth = $BorderWidth
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de l'application du style de marqueur au point de donnÃ©es: $_"
        return $false
    }
}

# Classe pour la conversion des styles de bordure
class ExcelBorderStyleConverter {
    # Dictionnaire de correspondance entre ExcelBorderStyle et eBorderStyle d'EPPlus
    static [hashtable] $StyleMapping = @{
        [ExcelBorderStyle]::None             = 0             # eBorderStyle.None
        [ExcelBorderStyle]::Thin             = 1             # eBorderStyle.Thin
        [ExcelBorderStyle]::Medium           = 2           # eBorderStyle.Medium
        [ExcelBorderStyle]::Thick            = 3            # eBorderStyle.Thick
        [ExcelBorderStyle]::Double           = 4           # eBorderStyle.Double
        [ExcelBorderStyle]::Hair             = 5             # eBorderStyle.Hair
        [ExcelBorderStyle]::Dotted           = 6           # eBorderStyle.Dotted
        [ExcelBorderStyle]::Dashed           = 7           # eBorderStyle.Dashed
        [ExcelBorderStyle]::MediumDashed     = 8     # eBorderStyle.MediumDashed
        [ExcelBorderStyle]::DashDot          = 9          # eBorderStyle.DashDot
        [ExcelBorderStyle]::MediumDashDot    = 10   # eBorderStyle.MediumDashDot
        [ExcelBorderStyle]::DashDotDot       = 11      # eBorderStyle.DashDotDot
        [ExcelBorderStyle]::MediumDashDotDot = 12 # eBorderStyle.MediumDashDotDot
        [ExcelBorderStyle]::SlantDashDot     = 13    # eBorderStyle.SlantDashDot
    }

    # Dictionnaire des descriptions des styles de bordure
    static [hashtable] $StyleDescriptions = @{
        [ExcelBorderStyle]::None             = "Aucune bordure"
        [ExcelBorderStyle]::Thin             = "Bordure fine"
        [ExcelBorderStyle]::Medium           = "Bordure moyenne"
        [ExcelBorderStyle]::Thick            = "Bordure Ã©paisse"
        [ExcelBorderStyle]::Double           = "Bordure double"
        [ExcelBorderStyle]::Hair             = "Bordure trÃ¨s fine"
        [ExcelBorderStyle]::Dotted           = "Bordure pointillÃ©e"
        [ExcelBorderStyle]::Dashed           = "Bordure en tirets"
        [ExcelBorderStyle]::MediumDashed     = "Bordure moyenne en tirets"
        [ExcelBorderStyle]::DashDot          = "Bordure tiret-point"
        [ExcelBorderStyle]::MediumDashDot    = "Bordure moyenne tiret-point"
        [ExcelBorderStyle]::DashDotDot       = "Bordure tiret-point-point"
        [ExcelBorderStyle]::MediumDashDotDot = "Bordure moyenne tiret-point-point"
        [ExcelBorderStyle]::SlantDashDot     = "Bordure tiret-point oblique"
    }

    # MÃ©thode pour convertir ExcelBorderStyle en eBorderStyle d'EPPlus
    static [int] ToEPPlusStyle([ExcelBorderStyle]$Style) {
        return [ExcelBorderStyleConverter]::StyleMapping[$Style]
    }

    # MÃ©thode pour obtenir la description d'un style de bordure
    static [string] GetDescription([ExcelBorderStyle]$Style) {
        return [ExcelBorderStyleConverter]::StyleDescriptions[$Style]
    }

    # MÃ©thode pour obtenir tous les styles disponibles avec leurs descriptions
    static [PSObject[]] GetAllStyles() {
        $Result = @()

        foreach ($Style in [Enum]::GetValues([ExcelBorderStyle])) {
            $StyleInfo = [PSCustomObject]@{
                Style       = $Style
                Name        = $Style.ToString()
                Description = [ExcelBorderStyleConverter]::GetDescription($Style)
                EPPlusValue = [ExcelBorderStyleConverter]::ToEPPlusStyle($Style)
            }

            $Result += $StyleInfo
        }

        return $Result
    }
}

# Classe pour configurer les bordures
class ExcelBorderStyleConfig {
    [ExcelBorderStyle]$Style = [ExcelBorderStyle]::Thin
    [string]$Color = "#000000"
    [int]$Width = 1                # Ã‰paisseur supplÃ©mentaire (1-5)
    [string]$Description = ""
    [bool]$IsBuiltIn = $false

    # Constructeur par dÃ©faut
    ExcelBorderStyleConfig() {
        $this.Description = "Configuration de bordure par dÃ©faut"
    }

    # Constructeur avec style et couleur
    ExcelBorderStyleConfig([ExcelBorderStyle]$Style, [string]$Color) {
        $this.Style = $Style
        $this.Color = $Color
        $this.Description = "Bordure $($Style) de couleur $Color"
    }

    # Constructeur complet
    ExcelBorderStyleConfig([ExcelBorderStyle]$Style, [string]$Color, [int]$Width, [string]$Description) {
        $this.Style = $Style
        $this.Color = $Color
        $this.Width = $Width
        $this.Description = $Description
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Valider la largeur
        if ($this.Width -lt 1 -or $this.Width -gt 5) {
            return $false
        }

        # Valider le format de la couleur
        if (-not ($this.Color -match '^#[0-9A-Fa-f]{6}$')) {
            return $false
        }

        return $true
    }

    # MÃ©thode pour crÃ©er une copie de la configuration
    [ExcelBorderStyleConfig] Clone() {
        $Clone = [ExcelBorderStyleConfig]::new()
        $Clone.Style = $this.Style
        $Clone.Color = $this.Color
        $Clone.Width = $this.Width
        $Clone.Description = $this.Description
        $Clone.IsBuiltIn = $false  # Une copie n'est jamais un style prÃ©dÃ©fini

        return $Clone
    }

    # MÃ©thode pour appliquer la configuration Ã  un Ã©lÃ©ment de graphique
    [void] ApplyToElement([object]$Element) {
        if ($null -eq $Element) {
            return
        }

        # Appliquer le style de bordure si l'Ã©lÃ©ment supporte cette propriÃ©tÃ©
        if ($Element.PSObject.Properties.Name -contains "Border") {
            if ($Element.Border.PSObject.Properties.Name -contains "Style") {
                $Element.Border.Style = [ExcelBorderStyleConverter]::ToEPPlusStyle($this.Style)
            }

            if ($Element.Border.PSObject.Properties.Name -contains "Color") {
                $Element.Border.Color.SetColor($this.Color)
            }

            if ($Element.Border.PSObject.Properties.Name -contains "Width") {
                $Element.Border.Width = $this.Width
            }
        }
        # Si l'Ã©lÃ©ment a des propriÃ©tÃ©s de bordure directes
        elseif ($Element.PSObject.Properties.Name -contains "BorderStyle") {
            $Element.BorderStyle = [ExcelBorderStyleConverter]::ToEPPlusStyle($this.Style)

            if ($Element.PSObject.Properties.Name -contains "BorderColor") {
                $Element.BorderColor.SetColor($this.Color)
            }

            if ($Element.PSObject.Properties.Name -contains "BorderWidth") {
                $Element.BorderWidth = $this.Width
            }
        }
    }

    # MÃ©thode pour appliquer la configuration Ã  une sÃ©rie
    [void] ApplyToSeries([object]$Series) {
        if ($null -eq $Series) {
            return
        }

        # Appliquer Ã  l'Ã©lÃ©ment de sÃ©rie principal
        $this.ApplyToElement($Series)

        # Appliquer aux marqueurs si disponibles
        if ($Series.PSObject.Properties.Name -contains "MarkerBorderStyle") {
            $Series.MarkerBorderStyle = [ExcelBorderStyleConverter]::ToEPPlusStyle($this.Style)

            if ($Series.PSObject.Properties.Name -contains "MarkerBorderColor") {
                $Series.MarkerBorderColor.SetColor($this.Color)
            }

            if ($Series.PSObject.Properties.Name -contains "MarkerBorderWidth") {
                $Series.MarkerBorderWidth = $this.Width
            }
        }
    }

    # MÃ©thode pour appliquer la configuration Ã  un point de donnÃ©es
    [void] ApplyToDataPoint([object]$DataPoint) {
        if ($null -eq $DataPoint) {
            return
        }

        # Appliquer Ã  l'Ã©lÃ©ment de point de donnÃ©es principal
        $this.ApplyToElement($DataPoint)

        # Appliquer aux marqueurs si disponibles
        if ($DataPoint.PSObject.Properties.Name -contains "MarkerBorderStyle") {
            $DataPoint.MarkerBorderStyle = [ExcelBorderStyleConverter]::ToEPPlusStyle($this.Style)

            if ($DataPoint.PSObject.Properties.Name -contains "MarkerBorderColor") {
                $DataPoint.MarkerBorderColor.SetColor($this.Color)
            }

            if ($DataPoint.PSObject.Properties.Name -contains "MarkerBorderWidth") {
                $DataPoint.MarkerBorderWidth = $this.Width
            }
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "$($this.Description) (Style: $($this.Style), Couleur: $($this.Color), Ã‰paisseur: $($this.Width))"
    }
}

<#
.SYNOPSIS
    Liste tous les styles de bordure disponibles.
.DESCRIPTION
    Cette fonction liste tous les styles de bordure disponibles avec leurs descriptions.
.EXAMPLE
    Get-ExcelBorderStyleList
.OUTPUTS
    PSObject[] - Liste des styles de bordure disponibles avec leurs propriÃ©tÃ©s.
#>
function Get-ExcelBorderStyleList {
    [CmdletBinding()]
    param ()

    return [ExcelBorderStyleConverter]::GetAllStyles()
}

<#
.SYNOPSIS
    CrÃ©e une nouvelle configuration de bordure.
.DESCRIPTION
    Cette fonction crÃ©e une nouvelle configuration de bordure avec les propriÃ©tÃ©s spÃ©cifiÃ©es.
.PARAMETER Style
    Le style de bordure Ã  utiliser.
.PARAMETER Color
    La couleur de la bordure au format hexadÃ©cimal (#RRGGBB).
.PARAMETER Width
    L'Ã©paisseur supplÃ©mentaire de la bordure (1-5).
.PARAMETER Description
    Description de la configuration (optionnel).
.EXAMPLE
    $BorderConfig = New-ExcelBorderConfig -Style Medium -Color "#FF0000" -Width 2
.OUTPUTS
    ExcelBorderStyleConfig - La nouvelle configuration de bordure crÃ©Ã©e.
#>
function New-ExcelBorderConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelBorderStyle]$Style,

        [Parameter(Mandatory = $true)]
        [string]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$Width = 1,

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    # CrÃ©er la description si non spÃ©cifiÃ©e
    if ([string]::IsNullOrEmpty($Description)) {
        $Description = "Bordure $Style de couleur $Color"
    }

    # CrÃ©er la configuration
    $BorderConfig = [ExcelBorderStyleConfig]::new($Style, $Color, $Width, $Description)

    # Valider la configuration
    if (-not $BorderConfig.Validate()) {
        throw "Configuration de bordure invalide. VÃ©rifiez les paramÃ¨tres."
    }

    return $BorderConfig
}

<#
.SYNOPSIS
    Applique un style de bordure Ã  un Ã©lÃ©ment de graphique Excel.
.DESCRIPTION
    Cette fonction applique un style de bordure spÃ©cifiÃ© Ã  un Ã©lÃ©ment de graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER ElementType
    Le type d'Ã©lÃ©ment Ã  modifier (Series, Title, Legend, Plot, Axis).
.PARAMETER ElementIndex
    L'index de l'Ã©lÃ©ment Ã  modifier (pour les sÃ©ries et axes).
.PARAMETER Style
    Le style de bordure Ã  appliquer.
.PARAMETER Color
    La couleur de la bordure au format hexadÃ©cimal (#RRGGBB).
.PARAMETER Width
    L'Ã©paisseur supplÃ©mentaire de la bordure (1-5).
.EXAMPLE
    Set-ExcelChartElementBorder -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -ElementType Series -ElementIndex 0 -Style Medium -Color "#FF0000" -Width 2
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartElementBorder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Series", "Title", "Legend", "Plot", "Axis")]
        [string]$ElementType,

        [Parameter(Mandatory = $false)]
        [int]$ElementIndex = 0,

        [Parameter(Mandatory = $true)]
        [ExcelBorderStyle]$Style,

        [Parameter(Mandatory = $true)]
        [string]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$Width = 1
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # VÃ©rifier le format de la couleur
        if (-not ($Color -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # CrÃ©er la configuration de bordure
        $BorderConfig = [ExcelBorderStyleConfig]::new($Style, $Color, $Width, "")

        # Obtenir l'Ã©lÃ©ment Ã  modifier
        $Element = $null

        switch ($ElementType) {
            "Series" {
                if ($ElementIndex -lt 0 -or $ElementIndex -ge $Chart.Series.Count) {
                    throw "Index de sÃ©rie invalide: $ElementIndex. Le graphique contient $($Chart.Series.Count) sÃ©ries."
                }
                $Element = $Chart.Series[$ElementIndex]
                $BorderConfig.ApplyToSeries($Element)
            }
            "Title" {
                if ($Chart.PSObject.Properties.Name -contains "Title") {
                    $Element = $Chart.Title
                    $BorderConfig.ApplyToElement($Element)
                }
            }
            "Legend" {
                if ($Chart.PSObject.Properties.Name -contains "Legend") {
                    $Element = $Chart.Legend
                    $BorderConfig.ApplyToElement($Element)
                }
            }
            "Plot" {
                if ($Chart.PSObject.Properties.Name -contains "PlotArea") {
                    $Element = $Chart.PlotArea
                    $BorderConfig.ApplyToElement($Element)
                }
            }
            "Axis" {
                if ($Chart.PSObject.Properties.Name -contains "Axis") {
                    if ($ElementIndex -lt 0 -or $ElementIndex -ge $Chart.Axis.Count) {
                        throw "Index d'axe invalide: $ElementIndex. Le graphique contient $($Chart.Axis.Count) axes."
                    }
                    $Element = $Chart.Axis[$ElementIndex]
                    $BorderConfig.ApplyToElement($Element)
                }
            }
        }

        if ($null -eq $Element) {
            throw "Ã‰lÃ©ment non trouvÃ© ou non supportÃ©: $ElementType"
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de l'application du style de bordure: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-ExcelColorPalette, New-ExcelColorPalette, Get-ExcelColorPaletteList, Remove-ExcelColorPalette, Set-ExcelChartColorPalette, Set-ExcelChartSeriesColor, Set-ExcelChartSeriesGradient, Set-ExcelChartSeriesConditionalColor, Set-ExcelChartSeriesColorRotation, Get-ExcelLineStyle, New-ExcelLineStyle, Get-ExcelLineStyleList, Remove-ExcelLineStyle, Set-ExcelChartSeriesLineStyle, Get-ExcelMarkerStyleList, Get-ExcelMarkerSizeList, New-ExcelMarkerConfig, Set-ExcelChartSeriesMarkerStyle, Set-ExcelChartDataPointMarkerStyle, Get-ExcelBorderStyleList, New-ExcelBorderConfig, Set-ExcelChartElementBorder
