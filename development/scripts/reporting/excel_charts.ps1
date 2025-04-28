<#
.SYNOPSIS
    Module de crÃ©ation de graphiques Excel pour les rapports automatiques.
.DESCRIPTION
    Ce module fournit des fonctionnalitÃ©s pour la crÃ©ation et la personnalisation
    de graphiques dans les classeurs Excel.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de crÃ©ation: 2025-04-23
#>

# VÃ©rifier si le module excel_exporter.ps1 est disponible
$ExporterPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_exporter.ps1"
if (-not (Test-Path -Path $ExporterPath)) {
    throw "Le module excel_exporter.ps1 est requis mais n'a pas Ã©tÃ© trouvÃ©."
}

# Importer le module excel_exporter.ps1
. $ExporterPath

#region Types et Ã©numÃ©rations

# Ã‰numÃ©ration des types de graphiques
enum ExcelChartType {
    Line
    Column
    Bar
    Pie
    Doughnut
    Area
    Scatter
    Bubble
    Radar
    Combo
    Waterfall
    Funnel
    BoxPlot
    Gauge
}

# Ã‰numÃ©ration des styles de ligne
enum ExcelLineStyle {
    Solid
    Dash
    Dot
    DashDot
    DashDotDot
    None
}

# Ã‰numÃ©ration des types de marqueurs
enum ExcelMarkerStyle {
    None
    Square
    Diamond
    Triangle
    X
    Star
    Circle
    Plus
    Dash
}

# Ã‰numÃ©ration des positions de lÃ©gende
enum ExcelLegendPosition {
    Top
    Bottom
    Left
    Right
    TopRight
    TopLeft
    BottomRight
    BottomLeft
    None
}

# Ã‰numÃ©ration des types d'Ã©chelle d'axe
enum ExcelAxisScale {
    Linear
    Logarithmic
    DateTime
    Category
}

# Ã‰numÃ©ration des types de lignes de tendance
enum ExcelTrendlineType {
    Linear
    Exponential
    Logarithmic
    Polynomial
    Power
    MovingAverage
}

#endregion

#region Classes de configuration

# Classe de configuration de base pour les graphiques
class ExcelChartConfig {
    [string]$Title = ""
    [string]$SubTitle = ""
    [bool]$ShowLegend = $true
    [ExcelLegendPosition]$LegendPosition = [ExcelLegendPosition]::Right
    [bool]$ShowDataLabels = $false
    [int]$Width = 500
    [int]$Height = 300
    [string]$StyleSet = "ColorfulPalette1"
    [bool]$ShowGridLines = $true
    [bool]$Is3D = $false

    # Constructeur par dÃ©faut
    ExcelChartConfig() {}

    # Constructeur avec titre
    ExcelChartConfig([string]$Title) {
        $this.Title = $Title
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # VÃ©rifier les dimensions minimales
        if ($this.Width -lt 100 -or $this.Height -lt 100) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les graphiques linÃ©aires
class ExcelLineChartConfig : ExcelChartConfig {
    [bool]$SmoothLines = $false
    [ExcelLineStyle]$LineStyle = [ExcelLineStyle]::Solid
    [ExcelMarkerStyle]$MarkerStyle = [ExcelMarkerStyle]::Circle
    [int]$LineWidth = 2
    [int]$MarkerSize = 6
    [bool]$ShowMarkers = $true
    [ExcelAxisScale]$XAxisScale = [ExcelAxisScale]::Category
    [ExcelAxisScale]$YAxisScale = [ExcelAxisScale]::Linear
    [bool]$ShowSecondaryAxis = $false
    [bool]$ShowTrendline = $false
    [ExcelTrendlineType]$TrendlineType = [ExcelTrendlineType]::Linear
    [bool]$ShowEquation = $false
    [bool]$ShowRSquared = $false

    # Constructeur par dÃ©faut
    ExcelLineChartConfig() : base() {}

    # Constructeur avec titre
    ExcelLineChartConfig([string]$Title) : base($Title) {}

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier les paramÃ¨tres spÃ©cifiques aux graphiques linÃ©aires
        if ($this.LineWidth -lt 1 -or $this.MarkerSize -lt 1) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les graphiques Ã  barres et colonnes
class ExcelBarChartConfig : ExcelChartConfig {
    [bool]$IsStacked = $false
    [bool]$IsStacked100 = $false
    [bool]$IsHorizontal = $false
    [int]$GapWidth = 150
    [int]$Overlap = 0
    [bool]$ShowSeriesNames = $true
    [bool]$ShowValues = $true
    [bool]$ShowPercentages = $false
    [ExcelAxisScale]$CategoryAxisScale = [ExcelAxisScale]::Category
    [ExcelAxisScale]$ValueAxisScale = [ExcelAxisScale]::Linear

    # Constructeur par dÃ©faut
    ExcelBarChartConfig() : base() {}

    # Constructeur avec titre
    ExcelBarChartConfig([string]$Title) : base($Title) {}

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier les paramÃ¨tres spÃ©cifiques aux graphiques Ã  barres
        if ($this.GapWidth -lt 0 -or $this.GapWidth -gt 500) {
            return $false
        }

        if ($this.Overlap -lt -100 -or $this.Overlap -gt 100) {
            return $false
        }

        # VÃ©rifier que les options empilÃ©es sont cohÃ©rentes
        if ($this.IsStacked -and $this.IsStacked100) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les graphiques circulaires
class ExcelPieChartConfig : ExcelChartConfig {
    # PropriÃ©tÃ©s spÃ©cifiques aux graphiques circulaires
    [bool]$IsDoughnut = $false
    [int]$DoughnutHoleSize = 50  # Pourcentage (0-100)
    [int]$FirstSliceAngle = 0  # Angle de dÃ©part en degrÃ©s
    [bool]$ClockwiseRotation = $true

    # PropriÃ©tÃ©s d'Ã©tiquettes
    [bool]$ShowValues = $true
    [bool]$ShowPercentages = $true
    [bool]$ShowLabels = $true
    [bool]$ShowLeaderLines = $true
    [string]$LabelFormat = "#,##0"  # Format pour les valeurs
    [string]$PercentFormat = "0.0%"  # Format pour les pourcentages

    # PropriÃ©tÃ©s de segments
    [bool]$GroupSmallValues = $false
    [double]$SmallValueThreshold = 5.0  # Pourcentage en dessous duquel regrouper
    [string]$SmallValueGroupLabel = "Autres"
    [bool]$ExplodeAllSlices = $false
    [int]$ExplodeDistance = 10  # Pourcentage
    [int[]]$ExplodedSlices = @()  # Indices des segments Ã  exploser

    # Constructeur par dÃ©faut
    ExcelPieChartConfig() : base() {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Right
    }

    # Constructeur avec titre
    ExcelPieChartConfig([string]$Title) : base($Title) {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Right
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier les paramÃ¨tres spÃ©cifiques aux graphiques circulaires
        if ($this.IsDoughnut) {
            if ($this.DoughnutHoleSize -lt 10 -or $this.DoughnutHoleSize -gt 90) {
                return $false
            }
        }

        # VÃ©rifier l'angle de dÃ©part
        if ($this.FirstSliceAngle -lt 0 -or $this.FirstSliceAngle -gt 359) {
            return $false
        }

        # VÃ©rifier le seuil de regroupement
        if ($this.GroupSmallValues -and ($this.SmallValueThreshold -le 0 -or $this.SmallValueThreshold -gt 50)) {
            return $false
        }

        # VÃ©rifier la distance d'explosion
        if ($this.ExplodeAllSlices -or $this.ExplodedSlices.Count -gt 0) {
            if ($this.ExplodeDistance -lt 0 -or $this.ExplodeDistance -gt 100) {
                return $false
            }
        }

        return $true
    }
}

# Classe de configuration pour les graphiques combinÃ©s
class ExcelComboChartConfig : ExcelChartConfig {
    # Types de graphiques pour chaque sÃ©rie
    [ExcelChartType[]]$SeriesTypes = @()  # Types de graphiques pour chaque sÃ©rie
    [bool[]]$UseSecondaryAxis = @()  # Utilisation de l'axe secondaire pour chaque sÃ©rie

    # Configuration des axes
    [ExcelAxisConfig]$PrimaryYAxisConfig = $null
    [ExcelAxisConfig]$SecondaryYAxisConfig = $null
    [ExcelAxisConfig]$XAxisConfig = $null

    # Options de sÃ©ries
    [ExcelSeriesConfig[]]$SeriesConfigs = @()

    # Options de lÃ©gende
    [bool]$GroupLegendsByType = $false
    [bool]$ShowLegendKeys = $true

    # Constructeur par dÃ©faut
    ExcelComboChartConfig() : base() {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Bottom
    }

    # Constructeur avec titre
    ExcelComboChartConfig([string]$Title) : base($Title) {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Bottom
    }

    # MÃ©thode pour ajouter une sÃ©rie
    [void] AddSeries([ExcelChartType]$Type, [bool]$UseSecondary = $false, [ExcelSeriesConfig]$Config = $null) {
        $this.SeriesTypes += $Type
        $this.UseSecondaryAxis += $UseSecondary

        if ($null -ne $Config) {
            $this.SeriesConfigs += $Config
        } else {
            $this.SeriesConfigs += [ExcelSeriesConfig]::new()
        }
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier qu'il y a au moins une sÃ©rie dÃ©finie
        if ($this.SeriesTypes.Count -eq 0) {
            return $false
        }

        # VÃ©rifier que les tableaux ont la mÃªme taille
        if ($this.SeriesTypes.Count -ne $this.UseSecondaryAxis.Count -or
            $this.SeriesTypes.Count -ne $this.SeriesConfigs.Count) {
            return $false
        }

        # Valider les configurations d'axes si spÃ©cifiÃ©es
        if ($null -ne $this.PrimaryYAxisConfig -and -not $this.PrimaryYAxisConfig.Validate()) {
            return $false
        }

        if ($null -ne $this.SecondaryYAxisConfig -and -not $this.SecondaryYAxisConfig.Validate()) {
            return $false
        }

        if ($null -ne $this.XAxisConfig -and -not $this.XAxisConfig.Validate()) {
            return $false
        }

        # Valider les configurations de sÃ©ries
        foreach ($SeriesConfig in $this.SeriesConfigs) {
            if (-not $SeriesConfig.Validate()) {
                return $false
            }
        }

        return $true
    }
}

# Classe de configuration pour les graphiques Ã  bulles
class ExcelBubbleChartConfig : ExcelChartConfig {
    # PropriÃ©tÃ©s spÃ©cifiques aux graphiques Ã  bulles
    [int]$MinBubbleSize = 5  # Taille minimale des bulles en points
    [int]$MaxBubbleSize = 50  # Taille maximale des bulles en points
    [bool]$ScaleBubbleSizeToArea = $true  # Mise Ã  l'Ã©chelle par surface (true) ou diamÃ¨tre (false)
    [bool]$ShowNegativeBubbles = $true  # Afficher les bulles avec des valeurs nÃ©gatives

    # PropriÃ©tÃ©s d'Ã©tiquettes
    [bool]$ShowValues = $false
    [bool]$ShowLabels = $true
    [bool]$ShowBubbleSizes = $false
    [string]$LabelFormat = "#,##0.00"  # Format pour les valeurs

    # PropriÃ©tÃ©s de style
    [bool]$UseColorGradient = $false
    [string]$MinColor = "#FFCCCC"  # Couleur pour les petites bulles
    [string]$MaxColor = "#FF0000"  # Couleur pour les grandes bulles
    [bool]$TransparentBubbles = $false
    [int]$BubbleTransparency = 50  # Pourcentage de transparence (0-100)

    # Constructeur par dÃ©faut
    ExcelBubbleChartConfig() : base() {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Bottom
    }

    # Constructeur avec titre
    ExcelBubbleChartConfig([string]$Title) : base($Title) {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Bottom
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier les tailles de bulles
        if ($this.MinBubbleSize -lt 1 -or $this.MinBubbleSize -gt $this.MaxBubbleSize) {
            return $false
        }

        if ($this.MaxBubbleSize -lt $this.MinBubbleSize -or $this.MaxBubbleSize -gt 100) {
            return $false
        }

        # VÃ©rifier la transparence
        if ($this.TransparentBubbles -and ($this.BubbleTransparency -lt 0 -or $this.BubbleTransparency -gt 100)) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les graphiques en cascade (waterfall)
class ExcelWaterfallChartConfig : ExcelChartConfig {
    # PropriÃ©tÃ©s spÃ©cifiques aux graphiques en cascade
    [string]$PositiveColor = "#00B050"  # Couleur pour les valeurs positives
    [string]$NegativeColor = "#FF0000"  # Couleur pour les valeurs nÃ©gatives
    [string]$TotalColor = "#4472C4"     # Couleur pour les totaux
    [string]$ConnectorColor = "#000000" # Couleur des connecteurs
    [int]$ConnectorWidth = 1            # Ã‰paisseur des connecteurs

    # PropriÃ©tÃ©s d'Ã©tiquettes
    [bool]$ShowValues = $true
    [bool]$ShowLabels = $true
    [string]$LabelFormat = "#,##0"      # Format pour les valeurs

    # PropriÃ©tÃ©s de structure
    [int[]]$TotalIndices = @()          # Indices des barres de total (0-basÃ©)
    [bool]$ShowConnectors = $true       # Afficher les connecteurs entre les barres
    [int]$GapWidth = 150                # Largeur de l'espace entre les barres (0-500)

    # Constructeur par dÃ©faut
    ExcelWaterfallChartConfig() : base() {
        $this.ShowLegend = $false
    }

    # Constructeur avec titre
    ExcelWaterfallChartConfig([string]$Title) : base($Title) {
        $this.ShowLegend = $false
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier la largeur de l'espace
        if ($this.GapWidth -lt 0 -or $this.GapWidth -gt 500) {
            return $false
        }

        # VÃ©rifier l'Ã©paisseur des connecteurs
        if ($this.ConnectorWidth -lt 1 -or $this.ConnectorWidth -gt 10) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les graphiques en entonnoir (funnel)
class ExcelFunnelChartConfig : ExcelChartConfig {
    # PropriÃ©tÃ©s spÃ©cifiques aux graphiques en entonnoir
    [bool]$IsInverted = $false          # Inverser l'entonnoir (plus large en bas)
    [int]$NeckHeight = 30               # Hauteur du goulot en pourcentage (0-100)
    [int]$NeckWidth = 20                # Largeur du goulot en pourcentage (0-100)
    [bool]$Is3D = $false                # Afficher en 3D

    # PropriÃ©tÃ©s d'Ã©tiquettes
    [bool]$ShowValues = $true
    [bool]$ShowPercentages = $true
    [bool]$ShowLabels = $true
    [string]$LabelFormat = "#,##0"      # Format pour les valeurs
    [string]$PercentFormat = "0.0%"     # Format pour les pourcentages

    # PropriÃ©tÃ©s de style
    [string[]]$CustomColors = @()       # Couleurs personnalisÃ©es pour chaque segment
    [bool]$GradientFill = $false        # Utiliser un dÃ©gradÃ© pour le remplissage
    [string]$StartColor = "#4472C4"     # Couleur de dÃ©but du dÃ©gradÃ©
    [string]$EndColor = "#A5A5A5"       # Couleur de fin du dÃ©gradÃ©

    # Constructeur par dÃ©faut
    ExcelFunnelChartConfig() : base() {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Right
    }

    # Constructeur avec titre
    ExcelFunnelChartConfig([string]$Title) : base($Title) {
        $this.ShowLegend = $true
        $this.LegendPosition = [ExcelLegendPosition]::Right
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier les dimensions du goulot
        if ($this.NeckHeight -lt 0 -or $this.NeckHeight -gt 100) {
            return $false
        }

        if ($this.NeckWidth -lt 0 -or $this.NeckWidth -gt 100) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les graphiques de type jauge
class ExcelGaugeChartConfig : ExcelChartConfig {
    # PropriÃ©tÃ©s spÃ©cifiques aux graphiques de type jauge
    [double]$MinValue = 0               # Valeur minimale de la jauge
    [double]$MaxValue = 100             # Valeur maximale de la jauge
    [double]$Value = 0                  # Valeur actuelle de la jauge
    [int]$StartAngle = 0                # Angle de dÃ©part en degrÃ©s (0-359)
    [int]$EndAngle = 180               # Angle de fin en degrÃ©s (0-359)

    # PropriÃ©tÃ©s des zones
    [double[]]$Thresholds = @(33, 66)   # Seuils pour les zones (pourcentages)
    [string[]]$ZoneColors = @("#00B050", "#FFBF00", "#FF0000")  # Couleurs des zones
    [bool]$ShowThresholdLabels = $true  # Afficher les Ã©tiquettes des seuils

    # PropriÃ©tÃ©s d'Ã©tiquettes
    [bool]$ShowValue = $true
    [string]$ValueFormat = "#,##0"      # Format pour la valeur
    [string]$ValueSuffix = "%"          # Suffixe pour la valeur
    [int]$ValueFontSize = 20            # Taille de police pour la valeur

    # PropriÃ©tÃ©s de style
    [int]$GaugeThickness = 30           # Ã‰paisseur de la jauge en pourcentage (10-90)
    [string]$NeedleColor = "#000000"    # Couleur de l'aiguille
    [int]$NeedleWidth = 2               # Ã‰paisseur de l'aiguille
    [bool]$ShowNeedle = $true           # Afficher l'aiguille

    # Constructeur par dÃ©faut
    ExcelGaugeChartConfig() : base() {
        $this.ShowLegend = $false
    }

    # Constructeur avec titre
    ExcelGaugeChartConfig([string]$Title) : base($Title) {
        $this.ShowLegend = $false
    }

    # Constructeur avec valeur
    ExcelGaugeChartConfig([string]$Title, [double]$Value) : base($Title) {
        $this.ShowLegend = $false
        $this.Value = $Value
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier les valeurs
        if ($this.MinValue -ge $this.MaxValue) {
            return $false
        }

        if ($this.Value -lt $this.MinValue -or $this.Value -gt $this.MaxValue) {
            return $false
        }

        # VÃ©rifier les angles
        if ($this.StartAngle -lt 0 -or $this.StartAngle -gt 359 -or
            $this.EndAngle -lt 0 -or $this.EndAngle -gt 359) {
            return $false
        }

        # VÃ©rifier l'Ã©paisseur de la jauge
        if ($this.GaugeThickness -lt 10 -or $this.GaugeThickness -gt 90) {
            return $false
        }

        # VÃ©rifier les seuils
        if ($this.Thresholds.Count -ne ($this.ZoneColors.Count - 1)) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les graphiques de type boÃ®te Ã  moustaches (box plot)
class ExcelBoxPlotChartConfig : ExcelChartConfig {
    # PropriÃ©tÃ©s spÃ©cifiques aux graphiques de type boÃ®te Ã  moustaches
    [bool]$ShowOutliers = $true         # Afficher les valeurs aberrantes
    [bool]$ShowMean = $false            # Afficher la moyenne
    [bool]$ShowMedian = $true           # Afficher la mÃ©diane
    [int]$WhiskerPercentile = 10        # Percentile pour les moustaches (1-49)

    # PropriÃ©tÃ©s d'Ã©tiquettes
    [bool]$ShowValues = $false
    [bool]$ShowStatistics = $false      # Afficher les statistiques (min, max, mÃ©diane, etc.)
    [string]$ValueFormat = "#,##0.00"   # Format pour les valeurs

    # PropriÃ©tÃ©s de style
    [string]$BoxColor = "#4472C4"        # Couleur de la boÃ®te
    [string]$WhiskerColor = "#000000"   # Couleur des moustaches
    [string]$OutlierColor = "#FF0000"   # Couleur des valeurs aberrantes
    [string]$MeanColor = "#00B050"      # Couleur de la moyenne
    [string]$MedianColor = "#FF9900"    # Couleur de la mÃ©diane
    [int]$BoxWidth = 50                 # Largeur de la boÃ®te en pourcentage (10-100)

    # Constructeur par dÃ©faut
    ExcelBoxPlotChartConfig() : base() {
        $this.ShowLegend = $false
    }

    # Constructeur avec titre
    ExcelBoxPlotChartConfig([string]$Title) : base($Title) {
        $this.ShowLegend = $false
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # Appeler la validation de la classe parente
        if (-not ([ExcelChartConfig]$this).Validate()) {
            return $false
        }

        # VÃ©rifier le percentile des moustaches
        if ($this.WhiskerPercentile -lt 1 -or $this.WhiskerPercentile -gt 49) {
            return $false
        }

        # VÃ©rifier la largeur de la boÃ®te
        if ($this.BoxWidth -lt 10 -or $this.BoxWidth -gt 100) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les axes
class ExcelAxisConfig {
    # PropriÃ©tÃ©s de base
    [string]$Title = ""
    [bool]$ShowTitle = $true
    [bool]$ShowLabels = $true
    [bool]$ShowGridLines = $true
    [bool]$ShowLine = $true

    # PropriÃ©tÃ©s d'Ã©chelle
    [ExcelAxisScale]$AxisScale = [ExcelAxisScale]::Linear
    [double]$Min = [double]::NaN
    [double]$Max = [double]::NaN
    [double]$MajorUnit = [double]::NaN
    [double]$MinorUnit = [double]::NaN
    [bool]$LogScale = $false
    [int]$BaseLogScale = 10
    [bool]$Reversed = $false

    # PropriÃ©tÃ©s de formatage
    [string]$LabelFormat = ""
    [int]$LabelRotation = 0
    [string]$FontName = "Calibri"
    [int]$FontSize = 10
    [bool]$FontBold = $false
    [string]$FontColor = "#000000"
    [string]$LineColor = "#000000"
    [int]$LineWidth = 1
    [ExcelLineStyle]$LineStyle = [ExcelLineStyle]::Solid

    # PropriÃ©tÃ©s d'axe secondaire
    [bool]$IsSecondary = $false
    [bool]$SyncWithPrimary = $false

    # Constructeur par dÃ©faut
    ExcelAxisConfig() {}

    # Constructeur avec titre
    ExcelAxisConfig([string]$Title) {
        $this.Title = $Title
    }

    # Constructeur avec Ã©chelle
    ExcelAxisConfig([string]$Title, [ExcelAxisScale]$Scale) {
        $this.Title = $Title
        $this.AxisScale = $Scale
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # VÃ©rifier la rotation des Ã©tiquettes
        if ($this.LabelRotation -lt -90 -or $this.LabelRotation -gt 90) {
            return $false
        }

        # VÃ©rifier la base logarithmique
        if ($this.LogScale -and ($this.BaseLogScale -lt 2)) {
            return $false
        }

        # VÃ©rifier les limites d'axe
        if (-not [double]::IsNaN($this.Min) -and -not [double]::IsNaN($this.Max)) {
            if ($this.Min -ge $this.Max) {
                return $false
            }
        }

        # VÃ©rifier les unitÃ©s
        if (-not [double]::IsNaN($this.MajorUnit)) {
            if ($this.MajorUnit -le 0) {
                return $false
            }
        }

        if (-not [double]::IsNaN($this.MinorUnit)) {
            if ($this.MinorUnit -le 0) {
                return $false
            }
        }

        # VÃ©rifier la taille de police
        if ($this.FontSize -le 0) {
            return $false
        }

        return $true
    }

    # MÃ©thode pour appliquer la configuration Ã  un axe
    [void] ApplyToAxis($Axis) {
        # Configurer le titre
        $Axis.Title.Text = $this.Title
        $Axis.Title.Font.Size = $this.FontSize
        $Axis.Title.Font.Bold = $this.FontBold
        $Axis.Title.Font.Name = $this.FontName
        $Axis.Title.Font.Color.SetColor($this.FontColor)
        $Axis.Title.Visible = $this.ShowTitle

        # Configurer les Ã©tiquettes
        $Axis.LabelFont.Size = $this.FontSize
        $Axis.LabelFont.Bold = $this.FontBold
        $Axis.LabelFont.Name = $this.FontName
        $Axis.LabelFont.Color.SetColor($this.FontColor)
        $Axis.LabelFont.Rotation = $this.LabelRotation

        # Configurer le format des Ã©tiquettes
        if (-not [string]::IsNullOrEmpty($this.LabelFormat)) {
            $Axis.Format = $this.LabelFormat
        }

        # Configurer l'Ã©chelle
        if (-not [double]::IsNaN($this.Min)) {
            $Axis.MinValue = $this.Min
        }

        if (-not [double]::IsNaN($this.Max)) {
            $Axis.MaxValue = $this.Max
        }

        if (-not [double]::IsNaN($this.MajorUnit)) {
            $Axis.MajorUnit = $this.MajorUnit
        }

        if (-not [double]::IsNaN($this.MinorUnit)) {
            $Axis.MinorUnit = $this.MinorUnit
        }

        # Configurer l'Ã©chelle logarithmique
        if ($this.LogScale) {
            $Axis.LogBase = $this.BaseLogScale
        }

        # Configurer l'inversion de l'axe
        if ($this.Reversed) {
            # Utiliser la mÃ©thode SetReversed si disponible, sinon ignorer
            if ($Axis.PSObject.Methods.Name -contains "SetReversed") {
                $Axis.SetReversed($true)
            }
        }

        # Configurer les lignes de grille
        $Axis.MajorGridlines.Visible = $this.ShowGridLines

        # Configurer la ligne d'axe
        if ($Axis.PSObject.Properties.Name -contains "Border") {
            $Axis.Border.Width = $this.LineWidth
            $Axis.Border.Color.SetColor($this.LineColor)

            # Convertir le style de ligne en style de bordure Excel
            $BorderStyle = switch ($this.LineStyle) {
                "Solid" { "Thin" }
                "Dash" { "Dashed" }
                "Dot" { "Dotted" }
                "DashDot" { "DashDot" }
                "DashDotDot" { "DashDotDot" }
                "None" { "None" }
                default { "Thin" }
            }

            # Appliquer le style si la propriÃ©tÃ© existe
            if ($Axis.Border.PSObject.Properties.Name -contains "Style") {
                $Axis.Border.Style = $BorderStyle
            }

            $Axis.Border.Visible = $this.ShowLine
        }
    }
}

# Classe de configuration pour les lignes de tendance
class ExcelTrendlineConfig {
    # PropriÃ©tÃ©s de base
    [ExcelTrendlineType]$Type = [ExcelTrendlineType]::Linear
    [bool]$ShowEquation = $false
    [bool]$ShowRSquared = $false
    [string]$Name = ""

    # PropriÃ©tÃ©s avancÃ©es
    [int]$PolynomialOrder = 2  # Pour les tendances polynomiales
    [int]$Period = 2  # Pour les moyennes mobiles
    [bool]$Forward = $false  # Extrapolation vers l'avant
    [bool]$Backward = $false  # Extrapolation vers l'arriÃ¨re
    [double]$ForwardPeriods = 0.0  # Nombre de pÃ©riodes d'extrapolation vers l'avant
    [double]$BackwardPeriods = 0.0  # Nombre de pÃ©riodes d'extrapolation vers l'arriÃ¨re

    # PropriÃ©tÃ©s de style
    [string]$Color = "#000000"
    [ExcelLineStyle]$LineStyle = [ExcelLineStyle]::Solid
    [int]$LineWidth = 1

    # Constructeur par dÃ©faut
    ExcelTrendlineConfig() {}

    # Constructeur avec type
    ExcelTrendlineConfig([ExcelTrendlineType]$Type) {
        $this.Type = $Type
    }

    # Constructeur avec type et options
    ExcelTrendlineConfig([ExcelTrendlineType]$Type, [bool]$ShowEquation, [bool]$ShowRSquared) {
        $this.Type = $Type
        $this.ShowEquation = $ShowEquation
        $this.ShowRSquared = $ShowRSquared
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # VÃ©rifier l'ordre polynomial
        if ($this.Type -eq [ExcelTrendlineType]::Polynomial -and ($this.PolynomialOrder -lt 2 -or $this.PolynomialOrder -gt 6)) {
            return $false
        }

        # VÃ©rifier la pÃ©riode de moyenne mobile
        if ($this.Type -eq [ExcelTrendlineType]::MovingAverage -and $this.Period -lt 2) {
            return $false
        }

        # VÃ©rifier l'Ã©paisseur de ligne
        if ($this.LineWidth -lt 1) {
            return $false
        }

        return $true
    }
}

# Classe de configuration pour les sÃ©ries de donnÃ©es
class ExcelSeriesConfig {
    [string]$Name = ""
    [string]$XRange = ""
    [string]$YRange = ""
    [string]$SizeRange = ""  # Pour les graphiques Ã  bulles
    [string]$Color = ""
    [ExcelLineStyle]$LineStyle = [ExcelLineStyle]::Solid
    [ExcelMarkerStyle]$MarkerStyle = [ExcelMarkerStyle]::Circle
    [int]$LineWidth = 2
    [int]$MarkerSize = 6
    [bool]$ShowMarkers = $true
    [bool]$UseSecondaryAxis = $false
    [bool]$ShowTrendline = $false
    [ExcelTrendlineType]$TrendlineType = [ExcelTrendlineType]::Linear
    [bool]$ShowEquation = $false
    [bool]$ShowRSquared = $false
    [bool]$Smooth = $false

    # Constructeur par dÃ©faut
    ExcelSeriesConfig() {}

    # Constructeur avec nom
    ExcelSeriesConfig([string]$Name) {
        $this.Name = $Name
    }

    # MÃ©thode pour valider la configuration
    [bool] Validate() {
        # VÃ©rifier que les plages sont spÃ©cifiÃ©es
        if ([string]::IsNullOrEmpty($this.YRange)) {
            return $false
        }

        # VÃ©rifier les paramÃ¨tres de ligne et marqueur
        if ($this.LineWidth -lt 1 -or $this.MarkerSize -lt 1) {
            return $false
        }

        return $true
    }
}

#endregion

#region Fonctions de crÃ©ation de graphiques

<#
.SYNOPSIS
    Configure les axes d'un graphique Excel.
.DESCRIPTION
    Cette fonction configure les axes X et Y d'un graphique Excel selon les configurations spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER ChartName
    Nom du graphique Ã  configurer.
.PARAMETER XAxisConfig
    Configuration de l'axe X.
.PARAMETER YAxisConfig
    Configuration de l'axe Y.
.PARAMETER SecondaryYAxisConfig
    Configuration de l'axe Y secondaire (optionnel).
.EXAMPLE
    $XAxisConfig = [ExcelAxisConfig]::new("Mois")
    $XAxisConfig.LabelRotation = 45

    $YAxisConfig = [ExcelAxisConfig]::new("Ventes")
    $YAxisConfig.Min = 0
    $YAxisConfig.MajorUnit = 1000

    Set-ExcelChartAxes -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MyChart" -XAxisConfig $XAxisConfig -YAxisConfig $YAxisConfig
.OUTPUTS
    None
#>
function Set-ExcelChartAxes {
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

        [Parameter(Mandatory = $false)]
        [ExcelAxisConfig]$XAxisConfig = $null,

        [Parameter(Mandatory = $false)]
        [ExcelAxisConfig]$YAxisConfig = $null,

        [Parameter(Mandatory = $false)]
        [ExcelAxisConfig]$SecondaryYAxisConfig = $null
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

        # Trouver le graphique par son nom
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName) {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # Configurer l'axe X si spÃ©cifiÃ©
        if ($null -ne $XAxisConfig) {
            # Valider la configuration
            if (-not $XAxisConfig.Validate()) {
                throw "Configuration de l'axe X invalide"
            }

            # Appliquer la configuration
            $XAxisConfig.ApplyToAxis($Chart.XAxis)
        }

        # Configurer l'axe Y si spÃ©cifiÃ©
        if ($null -ne $YAxisConfig) {
            # Valider la configuration
            if (-not $YAxisConfig.Validate()) {
                throw "Configuration de l'axe Y invalide"
            }

            # Appliquer la configuration
            $YAxisConfig.ApplyToAxis($Chart.YAxis)
        }

        # Configurer l'axe Y secondaire si spÃ©cifiÃ© et disponible
        if ($null -ne $SecondaryYAxisConfig) {
            # Valider la configuration
            if (-not $SecondaryYAxisConfig.Validate()) {
                throw "Configuration de l'axe Y secondaire invalide"
            }

            # VÃ©rifier si l'axe Y secondaire est disponible
            if ($Chart.PSObject.Properties.Name -contains "SecondaryYAxis") {
                # Activer l'axe Y secondaire si nÃ©cessaire
                if ($Chart.PSObject.Methods.Name -contains "UseSecondaryAxis") {
                    $Chart.UseSecondaryAxis($true)
                }

                # Appliquer la configuration
                $SecondaryYAxisConfig.ApplyToAxis($Chart.SecondaryYAxis)
            } else {
                Write-Warning "L'axe Y secondaire n'est pas disponible pour ce type de graphique"
            }
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
    } catch {
        Write-Error "Erreur lors de la configuration des axes du graphique: $_"
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique linÃ©aire dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique linÃ©aire dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:C10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER XAxisTitle
    Titre de l'axe X.
.PARAMETER YAxisTitle
    Titre de l'axe Y.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER Config
    Configuration du graphique linÃ©aire.
.EXAMPLE
    $ChartId = New-ExcelLineChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:C10" -ChartName "MyChart" -Title "Mon graphique" -XAxisTitle "Axe X" -YAxisTitle "Axe Y" -Position "E1:J15"
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelLineChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "LineChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$XAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$YAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [ExcelLineChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelLineChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # CrÃ©er le graphique
        $Chart = $Worksheet.Drawings.AddChart($ChartName, [OfficeOpenXml.Drawing.Chart.eChartType]::Line)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::$($Config.LegendPosition)
        $Chart.Legend.Font.Size = 10

        # Configurer les axes
        if (-not [string]::IsNullOrEmpty($XAxisTitle)) {
            $Chart.XAxis.Title.Text = $XAxisTitle
            $Chart.XAxis.Title.Font.Size = 12
        }

        if (-not [string]::IsNullOrEmpty($YAxisTitle)) {
            $Chart.YAxis.Title.Text = $YAxisTitle
            $Chart.YAxis.Title.Font.Size = 12
        }

        # Configurer les options spÃ©cifiques aux graphiques linÃ©aires
        $Chart.PlotArea.LineWidth = $Config.LineWidth

        # Ajouter les donnÃ©es
        $Series = $Chart.Series.Add($DataRange, $null)

        # Configurer les marqueurs
        if ($Config.ShowMarkers) {
            $Series.Marker = [OfficeOpenXml.Drawing.Chart.eMarkerStyle]::$($Config.MarkerStyle)
            $Series.MarkerSize = $Config.MarkerSize
        } else {
            $Series.Marker = [OfficeOpenXml.Drawing.Chart.eMarkerStyle]::None
        }

        # Configurer le style de ligne
        $Series.LineWidth = $Config.LineWidth

        # Configurer les lignes lisses
        $Series.Smooth = $Config.SmoothLines

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Ajouter une ligne de tendance si demandÃ©
        if ($Config.ShowTrendline) {
            $Trendline = $Series.TrendLines.Add([OfficeOpenXml.Drawing.Chart.eTrendLine]::$($Config.TrendlineType))
            $Trendline.DisplayEquation = $Config.ShowEquation
            $Trendline.DisplayRSquaredValue = $Config.ShowRSquared
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique (pour l'instant, juste le nom)
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique linÃ©aire: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique Ã  barres ou Ã  colonnes dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique Ã  barres (horizontales) ou Ã  colonnes (verticales) dans une feuille Excel.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:C10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER XAxisTitle
    Titre de l'axe X.
.PARAMETER YAxisTitle
    Titre de l'axe Y.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER IsHorizontal
    Indique si le graphique est horizontal (barres) ou vertical (colonnes).
.PARAMETER Config
    Configuration du graphique Ã  barres.
.EXAMPLE
    $ChartId = New-ExcelBarChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:C10" -ChartName "MyChart" -Title "Mon graphique" -XAxisTitle "Axe X" -YAxisTitle "Axe Y" -Position "E1:J15" -IsHorizontal $false
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelBarChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "BarChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$XAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$YAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [bool]$IsHorizontal = $false,

        [Parameter(Mandatory = $false)]
        [ExcelBarChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelBarChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
            $Config.IsHorizontal = $IsHorizontal
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # DÃ©terminer le type de graphique
        $ChartType = if ($Config.IsHorizontal) {
            if ($Config.IsStacked) {
                if ($Config.IsStacked100) {
                    [OfficeOpenXml.Drawing.Chart.eChartType]::BarStacked100
                } else {
                    [OfficeOpenXml.Drawing.Chart.eChartType]::BarStacked
                }
            } else {
                [OfficeOpenXml.Drawing.Chart.eChartType]::Bar
            }
        } else {
            if ($Config.IsStacked) {
                if ($Config.IsStacked100) {
                    [OfficeOpenXml.Drawing.Chart.eChartType]::ColumnStacked100
                } else {
                    [OfficeOpenXml.Drawing.Chart.eChartType]::ColumnStacked
                }
            } else {
                [OfficeOpenXml.Drawing.Chart.eChartType]::Column
            }
        }

        # CrÃ©er le graphique
        $Chart = $Worksheet.Drawings.AddChart($ChartName, $ChartType)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::$($Config.LegendPosition)
        $Chart.Legend.Font.Size = 10

        # Configurer les axes
        if (-not [string]::IsNullOrEmpty($XAxisTitle)) {
            $Chart.XAxis.Title.Text = $XAxisTitle
            $Chart.XAxis.Title.Font.Size = 12
        }

        if (-not [string]::IsNullOrEmpty($YAxisTitle)) {
            $Chart.YAxis.Title.Text = $YAxisTitle
            $Chart.YAxis.Title.Font.Size = 12
        }

        # Ajouter les donnÃ©es
        $Series = $Chart.Series.Add($DataRange, $null)

        # Configurer les Ã©tiquettes de donnÃ©es
        if ($Config.ShowValues) {
            $Series.DataLabel.ShowValue = $true
        }

        if ($Config.ShowSeriesNames) {
            $Series.DataLabel.ShowSeriesName = $true
        }

        if ($Config.ShowPercentages) {
            $Series.DataLabel.ShowPercent = $true
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique (pour l'instant, juste le nom)
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique Ã  barres: $_"
        return $null
    }
}

#endregion

<#
.SYNOPSIS
    Ajoute une ligne de tendance Ã  une sÃ©rie de donnÃ©es dans un graphique Excel.
.DESCRIPTION
    Cette fonction ajoute une ligne de tendance Ã  une sÃ©rie de donnÃ©es spÃ©cifique dans un graphique Excel.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER SeriesIndex
    Index de la sÃ©rie de donnÃ©es (commence Ã  0).
.PARAMETER TrendlineConfig
    Configuration de la ligne de tendance.
.EXAMPLE
    $TrendlineConfig = [ExcelTrendlineConfig]::new([ExcelTrendlineType]::Linear, $true, $true)
    $TrendlineConfig.Name = "Tendance linÃ©aire"

    Add-ExcelChartTrendline -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MyChart" -SeriesIndex 0 -TrendlineConfig $TrendlineConfig
.OUTPUTS
    None
#>
function Add-ExcelChartTrendline {
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
        [ExcelTrendlineConfig]$TrendlineConfig
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

        # Valider la configuration de la ligne de tendance
        if (-not $TrendlineConfig.Validate()) {
            throw "Configuration de ligne de tendance invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique par son nom
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName) {
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

        # Obtenir la sÃ©rie de donnÃ©es
        $Series = $Chart.Series[$SeriesIndex]

        # Convertir le type de tendance en type EPPlus
        $TrendlineType = switch ($TrendlineConfig.Type) {
            "Linear" { [OfficeOpenXml.Drawing.Chart.eTrendLine]::Linear }
            "Exponential" { [OfficeOpenXml.Drawing.Chart.eTrendLine]::Exponential }
            "Logarithmic" { [OfficeOpenXml.Drawing.Chart.eTrendLine]::Logarithmic }
            "Polynomial" { [OfficeOpenXml.Drawing.Chart.eTrendLine]::Polynomial }
            "Power" { [OfficeOpenXml.Drawing.Chart.eTrendLine]::Power }
            "MovingAverage" { [OfficeOpenXml.Drawing.Chart.eTrendLine]::MovingAverage }
            default { [OfficeOpenXml.Drawing.Chart.eTrendLine]::Linear }
        }

        # Ajouter la ligne de tendance
        $Trendline = $Series.TrendLines.Add($TrendlineType)

        # Configurer les options de base
        $Trendline.DisplayEquation = $TrendlineConfig.ShowEquation
        $Trendline.DisplayRSquaredValue = $TrendlineConfig.ShowRSquared

        # Configurer le nom si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($TrendlineConfig.Name)) {
            $Trendline.Name = $TrendlineConfig.Name
        }

        # Configurer les options avancÃ©es selon le type
        if ($TrendlineConfig.Type -eq [ExcelTrendlineType]::Polynomial) {
            $Trendline.Order = $TrendlineConfig.PolynomialOrder
        } elseif ($TrendlineConfig.Type -eq [ExcelTrendlineType]::MovingAverage) {
            $Trendline.Period = $TrendlineConfig.Period
        }

        # Configurer l'extrapolation
        if ($TrendlineConfig.Forward) {
            $Trendline.Forward = $TrendlineConfig.ForwardPeriods
        }

        if ($TrendlineConfig.Backward) {
            $Trendline.Backward = $TrendlineConfig.BackwardPeriods
        }

        # Configurer le style si possible
        if ($Trendline.PSObject.Properties.Name -contains "Line") {
            if (-not [string]::IsNullOrEmpty($TrendlineConfig.Color)) {
                $Trendline.Line.Color.SetColor($TrendlineConfig.Color)
            }

            $Trendline.Line.Width = $TrendlineConfig.LineWidth

            # Configurer le style de ligne si possible
            if ($Trendline.Line.PSObject.Properties.Name -contains "Style") {
                $LineStyle = switch ($TrendlineConfig.LineStyle) {
                    "Solid" { "Solid" }
                    "Dash" { "Dash" }
                    "Dot" { "Dot" }
                    "DashDot" { "DashDot" }
                    "DashDotDot" { "DashDotDot" }
                    "None" { "None" }
                    default { "Solid" }
                }

                $Trendline.Line.Style = $LineStyle
            }
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
    } catch {
        Write-Error "Erreur lors de l'ajout de la ligne de tendance: $_"
    }
}

<#
.SYNOPSIS
    Ajoute une ligne de rÃ©fÃ©rence horizontale ou verticale Ã  un graphique Excel.
.DESCRIPTION
    Cette fonction ajoute une ligne de rÃ©fÃ©rence horizontale ou verticale Ã  un graphique Excel.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Value
    Valeur de la ligne de rÃ©fÃ©rence.
.PARAMETER IsHorizontal
    Indique si la ligne est horizontale (true) ou verticale (false).
.PARAMETER Label
    Ã‰tiquette de la ligne de rÃ©fÃ©rence (optionnel).
.PARAMETER Color
    Couleur de la ligne (format hexadÃ©cimal, par exemple: "#FF0000" pour rouge).
.PARAMETER LineWidth
    Ã‰paisseur de la ligne.
.PARAMETER LineStyle
    Style de la ligne (Solid, Dash, Dot, DashDot, DashDotDot, None).
.EXAMPLE
    Add-ExcelChartReferenceLine -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MyChart" -Value 1000 -IsHorizontal $true -Label "Objectif" -Color "#FF0000" -LineWidth 2 -LineStyle "Dash"
.OUTPUTS
    None
#>
function Add-ExcelChartReferenceLine {
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
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [bool]$IsHorizontal,

        [Parameter(Mandatory = $false)]
        [string]$Label = "",

        [Parameter(Mandatory = $false)]
        [string]$Color = "#FF0000",

        [Parameter(Mandatory = $false)]
        [int]$LineWidth = 1,

        [Parameter(Mandatory = $false)]
        [ExcelLineStyle]$LineStyle = [ExcelLineStyle]::Dash
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

        # Trouver le graphique par son nom
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName) {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # Ajouter une ligne de rÃ©fÃ©rence en utilisant une sÃ©rie constante
        # Note: Cette approche est une solution de contournement car EPPlus ne prend pas directement en charge les lignes de rÃ©fÃ©rence

        # DÃ©terminer l'axe concernÃ©
        $Axis = if ($IsHorizontal) { $Chart.YAxis } else { $Chart.XAxis }

        # Obtenir les limites de l'axe opposÃ©
        $OppositeAxis = if ($IsHorizontal) { $Chart.XAxis } else { $Chart.YAxis }
        $Min = $OppositeAxis.MinValue
        $Max = $OppositeAxis.MaxValue

        # Si les limites ne sont pas dÃ©finies, utiliser les valeurs par dÃ©faut
        if ([double]::IsNaN($Min)) { $Min = 0 }
        if ([double]::IsNaN($Max)) { $Max = 10 }

        # CrÃ©er une sÃ©rie constante pour reprÃ©senter la ligne de rÃ©fÃ©rence
        # Utiliser des valeurs concatÃ©nÃ©es pour Ã©viter les problÃ¨mes avec les deux-points dans les variables
        $XValues = if ($IsHorizontal) { $Min.ToString() + ":" + $Max.ToString() } else { $Value.ToString() + ":" + $Value.ToString() }
        $YValues = if ($IsHorizontal) { $Value.ToString() + ":" + $Value.ToString() } else { $Min.ToString() + ":" + $Max.ToString() }
        $Series = $Chart.Series.Add($XValues, $YValues)

        # Configurer la sÃ©rie pour qu'elle ressemble Ã  une ligne de rÃ©fÃ©rence
        $Series.LineWidth = $LineWidth
        $Series.Marker = [OfficeOpenXml.Drawing.Chart.eMarkerStyle]::None

        # Configurer la couleur
        if (-not [string]::IsNullOrEmpty($Color)) {
            $Series.LineColor.SetColor($Color)
        }

        # Configurer le style de ligne
        $DashType = switch ($LineStyle) {
            "Solid" { [OfficeOpenXml.Drawing.Chart.eLineStyle]::Solid }
            "Dash" { [OfficeOpenXml.Drawing.Chart.eLineStyle]::Dash }
            "Dot" { [OfficeOpenXml.Drawing.Chart.eLineStyle]::Dot }
            "DashDot" { [OfficeOpenXml.Drawing.Chart.eLineStyle]::DashDot }
            "DashDotDot" { [OfficeOpenXml.Drawing.Chart.eLineStyle]::DashDotDot }
            "None" { [OfficeOpenXml.Drawing.Chart.eLineStyle]::None }
            default { [OfficeOpenXml.Drawing.Chart.eLineStyle]::Dash }
        }

        if ($Series.PSObject.Properties.Name -contains "LineStyle") {
            $Series.LineStyle = $DashType
        }

        # Ajouter une Ã©tiquette si spÃ©cifiÃ©e
        if (-not [string]::IsNullOrEmpty($Label)) {
            $Series.Header = $Label
        } else {
            # Masquer la sÃ©rie dans la lÃ©gende si pas d'Ã©tiquette
            if ($Series.PSObject.Properties.Name -contains "ShowInLegend") {
                $Series.ShowInLegend = $false
            }
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
    } catch {
        Write-Error "Erreur lors de l'ajout de la ligne de rÃ©fÃ©rence: $_"
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique circulaire dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique circulaire ou en anneau dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:B10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER Config
    Configuration du graphique circulaire.
.EXAMPLE
    $Config = [ExcelPieChartConfig]::new("RÃ©partition des ventes")
    $Config.ShowPercentages = $true
    $Config.ShowLabels = $true

    $ChartId = New-ExcelPieChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:B10" -ChartName "PieChart" -Position "E1:J15" -Config $Config
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelPieChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "PieChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [ExcelPieChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelPieChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # DÃ©terminer le type de graphique
        $ChartType = if ($Config.IsDoughnut) {
            [OfficeOpenXml.Drawing.Chart.eChartType]::Doughnut
        } else {
            [OfficeOpenXml.Drawing.Chart.eChartType]::Pie
        }

        # CrÃ©er le graphique
        $Chart = $Worksheet.Drawings.AddChart($ChartName, $ChartType)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::$($Config.LegendPosition)
        $Chart.Legend.Font.Size = 10
        $Chart.Legend.Visible = $Config.ShowLegend

        # Ajouter les donnÃ©es
        $Series = $Chart.Series.Add($DataRange, $null)

        # Configurer les Ã©tiquettes de donnÃ©es
        $Series.DataLabel.ShowValue = $Config.ShowValues
        $Series.DataLabel.ShowPercent = $Config.ShowPercentages
        $Series.DataLabel.ShowCategory = $Config.ShowLabels
        $Series.DataLabel.ShowLeaderLines = $Config.ShowLeaderLines

        # Configurer le format des Ã©tiquettes si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($Config.LabelFormat)) {
            $Series.DataLabel.NumberFormat = $Config.LabelFormat
        }

        # Configurer le format des pourcentages si spÃ©cifiÃ©
        if ($Config.ShowPercentages -and -not [string]::IsNullOrEmpty($Config.PercentFormat)) {
            $Series.DataLabel.PercentageNumberFormat = $Config.PercentFormat
        }

        # Configurer l'angle de dÃ©part si disponible
        if ($Chart.PSObject.Properties.Name -contains "FirstSliceAngle") {
            $Chart.FirstSliceAngle = $Config.FirstSliceAngle
        }

        # Configurer la taille du trou pour les graphiques en anneau
        if ($Config.IsDoughnut -and $Chart.PSObject.Properties.Name -contains "DoughnutHoleSize") {
            $Chart.DoughnutHoleSize = $Config.DoughnutHoleSize
        }

        # Configurer l'explosion des segments
        if ($Config.ExplodeAllSlices) {
            # Exploser tous les segments si demandÃ©
            if ($Series.PSObject.Methods.Name -contains "SetExploded") {
                $Series.SetExploded($true)
            }
        } elseif ($Config.ExplodedSlices.Count -gt 0) {
            # Exploser seulement les segments spÃ©cifiÃ©s
            foreach ($SliceIndex in $Config.ExplodedSlices) {
                if ($Series.PSObject.Methods.Name -contains "SetExploded") {
                    $Series.SetExploded($SliceIndex, $true)
                }
            }
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique (pour l'instant, juste le nom)
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique circulaire: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Regroupe les petites valeurs dans un graphique circulaire.
.DESCRIPTION
    Cette fonction regroupe les petites valeurs dans un graphique circulaire en une seule catÃ©gorie "Autres".
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER ChartName
    Nom du graphique circulaire.
.PARAMETER Threshold
    Seuil en pourcentage en dessous duquel les valeurs sont regroupÃ©es.
.PARAMETER GroupLabel
    Ã‰tiquette pour le groupe de petites valeurs.
.PARAMETER GroupColor
    Couleur pour le groupe de petites valeurs (format hexadÃ©cimal, par exemple: "#CCCCCC").
.EXAMPLE
    Group-ExcelPieChartSmallValues -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "PieChart" -Threshold 5.0 -GroupLabel "Autres" -GroupColor "#CCCCCC"
.OUTPUTS
    None
#>
function Group-ExcelPieChartSmallValues {
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

        [Parameter(Mandatory = $false)]
        [double]$Threshold = 5.0,

        [Parameter(Mandatory = $false)]
        [string]$GroupLabel = "Autres",

        [Parameter(Mandatory = $false)]
        [string]$GroupColor = "#CCCCCC"
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

        # Trouver le graphique par son nom
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName) {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # VÃ©rifier que c'est un graphique circulaire
        if ($Chart.ChartType -ne [OfficeOpenXml.Drawing.Chart.eChartType]::Pie -and
            $Chart.ChartType -ne [OfficeOpenXml.Drawing.Chart.eChartType]::Doughnut) {
            throw "Le graphique n'est pas de type circulaire ou anneau"
        }

        # Obtenir la sÃ©rie de donnÃ©es
        if ($Chart.Series.Count -eq 0) {
            throw "Le graphique ne contient aucune sÃ©rie de donnÃ©es"
        }

        $Series = $Chart.Series[0]

        # Obtenir les donnÃ©es source
        $DataAddress = $Series.Series.DataAddress
        if ([string]::IsNullOrEmpty($DataAddress)) {
            throw "Impossible de dÃ©terminer l'adresse des donnÃ©es"
        }

        # Analyser l'adresse pour obtenir la plage
        $AddressParts = $DataAddress.Split('!')
        if ($AddressParts.Length -ne 2) {
            throw "Format d'adresse de donnÃ©es non valide: $DataAddress"
        }

        $SheetName = $AddressParts[0].Trim("'")
        $Range = $AddressParts[1]

        # Trouver la feuille contenant les donnÃ©es
        $DataSheet = $null
        foreach ($Sheet in $Workbook.Worksheets) {
            if ($Sheet.Name -eq $SheetName) {
                $DataSheet = $Sheet
                break
            }
        }

        if ($null -eq $DataSheet) {
            throw "Feuille de donnÃ©es non trouvÃ©e: $SheetName"
        }

        # Obtenir les valeurs et Ã©tiquettes
        $RangeParts = $Range.Split(':')
        if ($RangeParts.Length -ne 2) {
            throw "Format de plage non valide: $Range"
        }

        # DÃ©terminer les colonnes de valeurs et d'Ã©tiquettes
        $StartCell = $RangeParts[0]
        $EndCell = $RangeParts[1]

        $StartCol = [int][char]$StartCell.Substring(0, 1) - [int][char]'A' + 1
        $EndCol = [int][char]$EndCell.Substring(0, 1) - [int][char]'A' + 1

        $StartRow = [int]::Parse($StartCell.Substring(1))
        $EndRow = [int]::Parse($EndCell.Substring(1))

        # Collecter les donnÃ©es
        $Data = @()
        for ($Row = $StartRow; $Row -le $EndRow; $Row++) {
            $Label = $DataSheet.Cells[$Row, $StartCol].Value
            $Value = $DataSheet.Cells[$Row, $StartCol + 1].Value

            if ($null -ne $Value -and $Value -is [ValueType]) {
                $Data += [PSCustomObject]@{
                    Label = $Label
                    Value = [double]$Value
                }
            }
        }

        # Calculer le total
        $Total = ($Data | Measure-Object -Property Value -Sum).Sum

        if ($Total -le 0) {
            throw "La somme des valeurs est nulle ou nÃ©gative"
        }

        # Identifier les petites valeurs
        $SmallValues = @()
        $LargeValues = @()

        foreach ($Item in $Data) {
            $Percentage = ($Item.Value / $Total) * 100

            if ($Percentage -lt $Threshold) {
                $SmallValues += $Item
            } else {
                $LargeValues += $Item
            }
        }

        # Si aucune petite valeur, rien Ã  faire
        if ($SmallValues.Count -eq 0) {
            Write-Verbose "Aucune petite valeur Ã  regrouper"
            return
        }

        # Calculer la somme des petites valeurs
        $SmallTotal = ($SmallValues | Measure-Object -Property Value -Sum).Sum

        # CrÃ©er une nouvelle feuille temporaire pour les donnÃ©es regroupÃ©es
        $TempSheetName = "Temp_" + [Guid]::NewGuid().ToString().Substring(0, 8)
        $TempSheet = $Workbook.Worksheets.Add($TempSheetName)

        # Ajouter les grandes valeurs
        $Row = 1
        foreach ($Item in $LargeValues) {
            $TempSheet.Cells[$Row, 1].Value = $Item.Label
            $TempSheet.Cells[$Row, 2].Value = $Item.Value
            $Row++
        }

        # Ajouter le groupe des petites valeurs
        $TempSheet.Cells[$Row, 1].Value = $GroupLabel
        $TempSheet.Cells[$Row, 2].Value = $SmallTotal

        # CrÃ©er une nouvelle plage pour les donnÃ©es regroupÃ©es
        $NewRange = "A1:B$Row"

        # Mettre Ã  jour la sÃ©rie avec les nouvelles donnÃ©es
        $Series.Series.DataAddress = "'$TempSheetName'!$NewRange"

        # Configurer la couleur du groupe si spÃ©cifiÃ©e
        if (-not [string]::IsNullOrEmpty($GroupColor) -and $Series.PSObject.Methods.Name -contains "SetColor") {
            $Series.SetColor($Row - 1, $GroupColor)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
    } catch {
        Write-Error "Erreur lors du regroupement des petites valeurs: $_"
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique combinÃ© dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique combinÃ© (plusieurs types de graphiques) dans une feuille Excel.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRanges
    Tableau des plages de donnÃ©es pour chaque sÃ©rie.
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER XAxisTitle
    Titre de l'axe X.
.PARAMETER PrimaryYAxisTitle
    Titre de l'axe Y primaire.
.PARAMETER SecondaryYAxisTitle
    Titre de l'axe Y secondaire.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER Config
    Configuration du graphique combinÃ©.
.EXAMPLE
    $Config = [ExcelComboChartConfig]::new("Ventes et Profits")
    $Config.AddSeries([ExcelChartType]::Column, $false)
    $Config.AddSeries([ExcelChartType]::Line, $true)

    $DataRanges = @("A1:B7", "A1:C7")
    $ChartId = New-ExcelComboChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRanges $DataRanges -ChartName "ComboChart" -Title "Ventes et Profits" -XAxisTitle "Mois" -PrimaryYAxisTitle "Ventes" -SecondaryYAxisTitle "Profits" -Position "E1:J15" -Config $Config
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelComboChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string[]]$DataRanges,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "ComboChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$XAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$PrimaryYAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$SecondaryYAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $true)]
        [ExcelComboChartConfig]$Config
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

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # VÃ©rifier que le nombre de plages de donnÃ©es correspond au nombre de sÃ©ries
        if ($DataRanges.Count -ne $Config.SeriesTypes.Count) {
            throw "Le nombre de plages de donnÃ©es ($($DataRanges.Count)) ne correspond pas au nombre de sÃ©ries dÃ©finies ($($Config.SeriesTypes.Count))"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # DÃ©terminer le type de graphique principal (pour la crÃ©ation initiale)
        # Utiliser le premier type de sÃ©rie comme type principal
        $PrimaryChartType = switch ($Config.SeriesTypes[0]) {
            "Line" { [OfficeOpenXml.Drawing.Chart.eChartType]::Line }
            "Column" { [OfficeOpenXml.Drawing.Chart.eChartType]::Column }
            "Bar" { [OfficeOpenXml.Drawing.Chart.eChartType]::Bar }
            "Area" { [OfficeOpenXml.Drawing.Chart.eChartType]::Area }
            "Scatter" { [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatter }
            "Bubble" { [OfficeOpenXml.Drawing.Chart.eChartType]::Bubble }
            default { [OfficeOpenXml.Drawing.Chart.eChartType]::Line }
        }

        # CrÃ©er le graphique avec le type principal
        $Chart = $Worksheet.Drawings.AddChart($ChartName, $PrimaryChartType)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        } elseif (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::$($Config.LegendPosition)
        $Chart.Legend.Font.Size = 10
        $Chart.Legend.Visible = $Config.ShowLegend

        # Configurer les axes
        if (-not [string]::IsNullOrEmpty($XAxisTitle)) {
            $Chart.XAxis.Title.Text = $XAxisTitle
            $Chart.XAxis.Title.Font.Size = 12
        }

        if (-not [string]::IsNullOrEmpty($PrimaryYAxisTitle)) {
            $Chart.YAxis.Title.Text = $PrimaryYAxisTitle
            $Chart.YAxis.Title.Font.Size = 12
        }

        # Activer l'axe Y secondaire si nÃ©cessaire
        $HasSecondaryAxis = $Config.UseSecondaryAxis -contains $true

        if ($HasSecondaryAxis) {
            # Activer l'axe Y secondaire
            if ($Chart.PSObject.Methods.Name -contains "UseSecondaryAxis") {
                $Chart.UseSecondaryAxis($true)
            }

            # Configurer le titre de l'axe Y secondaire
            if (-not [string]::IsNullOrEmpty($SecondaryYAxisTitle) -and
                $Chart.PSObject.Properties.Name -contains "SecondaryYAxis") {
                $Chart.SecondaryYAxis.Title.Text = $SecondaryYAxisTitle
                $Chart.SecondaryYAxis.Title.Font.Size = 12
            }
        }

        # Appliquer les configurations d'axes personnalisÃ©es si spÃ©cifiÃ©es
        if ($null -ne $Config.XAxisConfig) {
            $Config.XAxisConfig.ApplyToAxis($Chart.XAxis)
        }

        if ($null -ne $Config.PrimaryYAxisConfig) {
            $Config.PrimaryYAxisConfig.ApplyToAxis($Chart.YAxis)
        }

        if ($HasSecondaryAxis -and $null -ne $Config.SecondaryYAxisConfig -and
            $Chart.PSObject.Properties.Name -contains "SecondaryYAxis") {
            $Config.SecondaryYAxisConfig.ApplyToAxis($Chart.SecondaryYAxis)
        }

        # Ajouter les sÃ©ries de donnÃ©es
        for ($i = 0; $i -lt $DataRanges.Count; $i++) {
            $DataRange = $DataRanges[$i]
            $SeriesType = $Config.SeriesTypes[$i]
            $UseSecondary = $Config.UseSecondaryAxis[$i]
            $SeriesConfig = $Config.SeriesConfigs[$i]

            # Convertir le type de sÃ©rie en type EPPlus
            $EPPlusSeriesType = switch ($SeriesType) {
                "Line" { [OfficeOpenXml.Drawing.Chart.eChartType]::Line }
                "Column" { [OfficeOpenXml.Drawing.Chart.eChartType]::Column }
                "Bar" { [OfficeOpenXml.Drawing.Chart.eChartType]::Bar }
                "Area" { [OfficeOpenXml.Drawing.Chart.eChartType]::Area }
                "Scatter" { [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatter }
                "Bubble" { [OfficeOpenXml.Drawing.Chart.eChartType]::Bubble }
                default { [OfficeOpenXml.Drawing.Chart.eChartType]::Line }
            }

            # Ajouter la sÃ©rie avec le type spÃ©cifiÃ©
            $Series = $Chart.Series.Add($DataRange, $null, $EPPlusSeriesType)

            # Configurer l'utilisation de l'axe secondaire
            if ($UseSecondary -and $Chart.PSObject.Methods.Name -contains "UseSecondaryAxis") {
                $Series.UseSecondaryAxis = $true
            }

            # Appliquer la configuration de sÃ©rie si spÃ©cifiÃ©e
            if ($null -ne $SeriesConfig) {
                # Configurer le nom de la sÃ©rie
                if (-not [string]::IsNullOrEmpty($SeriesConfig.Name)) {
                    $Series.Header = $SeriesConfig.Name
                }

                # Configurer le style de ligne
                if ($SeriesType -eq "Line" -or $SeriesType -eq "Area") {
                    $Series.LineWidth = $SeriesConfig.LineWidth

                    # Configurer les marqueurs
                    if ($SeriesConfig.ShowMarkers) {
                        $Series.Marker = [OfficeOpenXml.Drawing.Chart.eMarkerStyle]::$($SeriesConfig.MarkerStyle)
                        $Series.MarkerSize = $SeriesConfig.MarkerSize
                    } else {
                        $Series.Marker = [OfficeOpenXml.Drawing.Chart.eMarkerStyle]::None
                    }

                    # Configurer les lignes lisses
                    if ($Series.PSObject.Properties.Name -contains "Smooth") {
                        $Series.Smooth = $SeriesConfig.Smooth
                    }
                }

                # Configurer la couleur
                if (-not [string]::IsNullOrEmpty($SeriesConfig.Color)) {
                    if ($Series.PSObject.Properties.Name -contains "Fill") {
                        $Series.Fill.Color.SetColor($SeriesConfig.Color)
                    } elseif ($Series.PSObject.Properties.Name -contains "LineColor") {
                        $Series.LineColor.SetColor($SeriesConfig.Color)
                    }
                }
            }
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique (pour l'instant, juste le nom)
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique combinÃ©: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique Ã  bulles dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique Ã  bulles dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:C10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER XAxisTitle
    Titre de l'axe X.
.PARAMETER YAxisTitle
    Titre de l'axe Y.
.PARAMETER BubbleSizeTitle
    Titre pour la taille des bulles (lÃ©gende).
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER Config
    Configuration du graphique Ã  bulles.
.EXAMPLE
    $Config = [ExcelBubbleChartConfig]::new("Analyse des produits")
    $Config.MinBubbleSize = 10
    $Config.MaxBubbleSize = 40
    $Config.ShowLabels = $true

    $ChartId = New-ExcelBubbleChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:C10" -ChartName "BubbleChart" -Title "Analyse des produits" -XAxisTitle "Prix" -YAxisTitle "Ventes" -BubbleSizeTitle "Part de marchÃ©" -Position "E1:J15" -Config $Config
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelBubbleChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "BubbleChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$XAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$YAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$BubbleSizeTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [ExcelBubbleChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelBubbleChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # CrÃ©er le graphique
        $Chart = $Worksheet.Drawings.AddChart($ChartName, [OfficeOpenXml.Drawing.Chart.eChartType]::Bubble)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        } elseif (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::$($Config.LegendPosition)
        $Chart.Legend.Font.Size = 10
        $Chart.Legend.Visible = $Config.ShowLegend

        # Configurer les axes
        if (-not [string]::IsNullOrEmpty($XAxisTitle)) {
            $Chart.XAxis.Title.Text = $XAxisTitle
            $Chart.XAxis.Title.Font.Size = 12
        }

        if (-not [string]::IsNullOrEmpty($YAxisTitle)) {
            $Chart.YAxis.Title.Text = $YAxisTitle
            $Chart.YAxis.Title.Font.Size = 12
        }

        # Ajouter les donnÃ©es
        $Series = $Chart.Series.Add($DataRange, $null)

        # Configurer les Ã©tiquettes de donnÃ©es
        $Series.DataLabel.ShowValue = $Config.ShowValues
        $Series.DataLabel.ShowCategory = $Config.ShowLabels

        if ($Config.ShowBubbleSizes) {
            $Series.DataLabel.ShowBubbleSize = $true
        }

        # Configurer le format des Ã©tiquettes si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($Config.LabelFormat)) {
            $Series.DataLabel.NumberFormat = $Config.LabelFormat
        }

        # Configurer la taille des bulles
        if ($Chart.PSObject.Properties.Name -contains "BubbleScale") {
            $Chart.BubbleScale = $Config.MaxBubbleSize
        }

        # Configurer la mise Ã  l'Ã©chelle des bulles
        if ($Chart.PSObject.Properties.Name -contains "BubbleScaleByArea") {
            $Chart.BubbleScaleByArea = $Config.ScaleBubbleSizeToArea
        }

        # Configurer l'affichage des bulles nÃ©gatives
        if ($Chart.PSObject.Properties.Name -contains "ShowNegativeBubbles") {
            $Chart.ShowNegativeBubbles = $Config.ShowNegativeBubbles
        }

        # Configurer la transparence des bulles
        if ($Config.TransparentBubbles -and $Series.PSObject.Properties.Name -contains "Transparency") {
            $Series.Transparency = $Config.BubbleTransparency
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique (pour l'instant, juste le nom)
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique Ã  bulles: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique en aires dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique en aires dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:C10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER XAxisTitle
    Titre de l'axe X.
.PARAMETER YAxisTitle
    Titre de l'axe Y.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER IsStacked
    Indique si le graphique est empilÃ©.
.PARAMETER IsStacked100
    Indique si le graphique est empilÃ© Ã  100%.
.EXAMPLE
    $ChartId = New-ExcelAreaChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:C10" -ChartName "AreaChart" -Title "Ã‰volution des ventes" -XAxisTitle "Mois" -YAxisTitle "Ventes" -Position "E1:J15" -IsStacked $true
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelAreaChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "AreaChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$XAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$YAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [bool]$IsStacked = $false,

        [Parameter(Mandatory = $false)]
        [bool]$IsStacked100 = $false
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

        # VÃ©rifier que les options empilÃ©es sont cohÃ©rentes
        if ($IsStacked -and $IsStacked100) {
            throw "Les options IsStacked et IsStacked100 ne peuvent pas Ãªtre activÃ©es simultanÃ©ment."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # DÃ©terminer le type de graphique
        $ChartType = if ($IsStacked100) {
            [OfficeOpenXml.Drawing.Chart.eChartType]::AreaStacked100
        } elseif ($IsStacked) {
            [OfficeOpenXml.Drawing.Chart.eChartType]::AreaStacked
        } else {
            [OfficeOpenXml.Drawing.Chart.eChartType]::Area
        }

        # CrÃ©er le graphique
        $Chart = $Worksheet.Drawings.AddChart($ChartName, $ChartType)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::Bottom
        $Chart.Legend.Font.Size = 10

        # Configurer les axes
        if (-not [string]::IsNullOrEmpty($XAxisTitle)) {
            $Chart.XAxis.Title.Text = $XAxisTitle
            $Chart.XAxis.Title.Font.Size = 12
        }

        if (-not [string]::IsNullOrEmpty($YAxisTitle)) {
            $Chart.YAxis.Title.Text = $YAxisTitle
            $Chart.YAxis.Title.Font.Size = 12
        }

        # Ajouter les donnÃ©es
        $Series = $Chart.Series.Add($DataRange, $null)

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize(15, 10)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique (pour l'instant, juste le nom)
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique en aires: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique radar dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique radar dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:C10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER IsFilled
    Indique si le graphique radar est rempli.
.PARAMETER WithMarkers
    Indique si les marqueurs doivent Ãªtre affichÃ©s.
.EXAMPLE
    $ChartId = New-ExcelRadarChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:C10" -ChartName "RadarChart" -Title "Analyse comparative" -Position "E1:J15" -IsFilled $true
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelRadarChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "RadarChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [bool]$IsFilled = $false,

        [Parameter(Mandatory = $false)]
        [bool]$WithMarkers = $true
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

        # DÃ©terminer le type de graphique
        $ChartType = if ($IsFilled) {
            [OfficeOpenXml.Drawing.Chart.eChartType]::RadarFilled
        } elseif ($WithMarkers) {
            [OfficeOpenXml.Drawing.Chart.eChartType]::RadarMarkers
        } else {
            [OfficeOpenXml.Drawing.Chart.eChartType]::Radar
        }

        # CrÃ©er le graphique
        $Chart = $Worksheet.Drawings.AddChart($ChartName, $ChartType)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::Bottom
        $Chart.Legend.Font.Size = 10

        # Ajouter les donnÃ©es
        $Series = $Chart.Series.Add($DataRange, $null)

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize(15, 10)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique (pour l'instant, juste le nom)
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique radar: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique en cascade (waterfall) dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique en cascade (waterfall) dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:B10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER XAxisTitle
    Titre de l'axe X.
.PARAMETER YAxisTitle
    Titre de l'axe Y.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER TotalIndices
    Indices des barres de total (0-basÃ©).
.PARAMETER Config
    Configuration du graphique en cascade.
.EXAMPLE
    $Config = [ExcelWaterfallChartConfig]::new("Analyse des profits")
    $Config.PositiveColor = "#00B050"
    $Config.NegativeColor = "#FF0000"
    $Config.TotalColor = "#4472C4"
    $Config.TotalIndices = @(0, 5)

    $ChartId = New-ExcelWaterfallChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:B6" -ChartName "WaterfallChart" -Title "Analyse des profits" -XAxisTitle "CatÃ©gorie" -YAxisTitle "Montant" -Position "E1:J15" -Config $Config
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelWaterfallChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "WaterfallChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$XAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$YAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [int[]]$TotalIndices = @(),

        [Parameter(Mandatory = $false)]
        [ExcelWaterfallChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelWaterfallChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
            if ($TotalIndices.Count -gt 0) {
                $Config.TotalIndices = $TotalIndices
            }
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Analyser la plage de donnÃ©es pour obtenir les valeurs
        $RangeParts = $DataRange.Split(':')
        if ($RangeParts.Length -ne 2) {
            throw "Format de plage non valide: $DataRange"
        }

        $StartCell = $RangeParts[0]
        $EndCell = $RangeParts[1]

        $StartCol = [int][char]$StartCell.Substring(0, 1) - [int][char]'A' + 1
        $EndCol = [int][char]$EndCell.Substring(0, 1) - [int][char]'A' + 1

        $StartRow = [int]::Parse($StartCell.Substring(1))
        $EndRow = [int]::Parse($EndCell.Substring(1))

        # CrÃ©er une feuille temporaire pour les donnÃ©es du graphique en cascade
        $TempSheetName = "Temp_Waterfall_" + [Guid]::NewGuid().ToString().Substring(0, 8)
        $TempSheet = $Workbook.Worksheets.Add($TempSheetName)

        # Copier les Ã©tiquettes de catÃ©gorie
        for ($Row = $StartRow; $Row -le $EndRow; $Row++) {
            $TempSheet.Cells[$Row - $StartRow + 1, 1].Value = $Worksheet.Cells[$Row, $StartCol].Value
        }

        # Calculer les valeurs cumulÃ©es et les valeurs de chaque barre
        $RunningTotal = 0
        $RowCount = $EndRow - $StartRow + 1

        for ($i = 0; $i -lt $RowCount; $i++) {
            $Row = $StartRow + $i
            $Value = [double]$Worksheet.Cells[$Row, $StartCol + 1].Value

            # DÃ©terminer si c'est une barre de total
            $IsTotal = $Config.TotalIndices -contains $i

            if ($IsTotal) {
                # Pour les totaux, on utilise la valeur directement
                $TempSheet.Cells[$i + 1, 2].Value = 0  # Valeur de dÃ©part
                $TempSheet.Cells[$i + 1, 3].Value = $Value  # Valeur finale
                $RunningTotal = $Value  # RÃ©initialiser le total courant
            } else {
                # Pour les autres barres, on calcule la diffÃ©rence
                $TempSheet.Cells[$i + 1, 2].Value = $RunningTotal  # Valeur de dÃ©part
                $TempSheet.Cells[$i + 1, 3].Value = $RunningTotal + $Value  # Valeur finale
                $RunningTotal += $Value  # Mettre Ã  jour le total courant
            }

            # Stocker le type de barre (1 = positif, -1 = nÃ©gatif, 0 = total)
            if ($IsTotal) {
                $TempSheet.Cells[$i + 1, 4].Value = 0  # Total
            } elseif ($Value -ge 0) {
                $TempSheet.Cells[$i + 1, 4].Value = 1  # Positif
            } else {
                $TempSheet.Cells[$i + 1, 4].Value = -1  # NÃ©gatif
            }
        }

        # CrÃ©er le graphique (utiliser un graphique en colonnes empilÃ©es comme base)
        $Chart = $Worksheet.Drawings.AddChart($ChartName, [OfficeOpenXml.Drawing.Chart.eChartType]::ColumnStacked)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        } elseif (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Visible = $Config.ShowLegend

        # Configurer les axes
        if (-not [string]::IsNullOrEmpty($XAxisTitle)) {
            $Chart.XAxis.Title.Text = $XAxisTitle
            $Chart.XAxis.Title.Font.Size = 12
        }

        if (-not [string]::IsNullOrEmpty($YAxisTitle)) {
            $Chart.YAxis.Title.Text = $YAxisTitle
            $Chart.YAxis.Title.Font.Size = 12
        }

        # Ajouter les sÃ©ries de donnÃ©es
        $Series1 = $Chart.Series.Add("$TempSheetName!A1:A$RowCount", "$TempSheetName!B1:B$RowCount")
        $Series2 = $Chart.Series.Add("$TempSheetName!A1:A$RowCount", "$TempSheetName!B1:C$RowCount")

        # Configurer les sÃ©ries
        $Series1.Header = "Base"
        $Series2.Header = "Variation"

        # Masquer la premiÃ¨re sÃ©rie dans la lÃ©gende
        if ($Series1.PSObject.Properties.Name -contains "ShowInLegend") {
            $Series1.ShowInLegend = $false
        }

        # Configurer les couleurs des barres en fonction du type (positif, nÃ©gatif, total)
        for ($i = 0; $i -lt $RowCount; $i++) {
            $BarType = [int]$TempSheet.Cells[$i + 1, 4].Value

            if ($BarType -eq 0) {
                # Total
                if ($Series2.PSObject.Methods.Name -contains "SetColor") {
                    $Series2.SetColor($i, $Config.TotalColor)
                }
            } elseif ($BarType -eq 1) {
                # Positif
                if ($Series2.PSObject.Methods.Name -contains "SetColor") {
                    $Series2.SetColor($i, $Config.PositiveColor)
                }
            } else {
                # NÃ©gatif
                if ($Series2.PSObject.Methods.Name -contains "SetColor") {
                    $Series2.SetColor($i, $Config.NegativeColor)
                }
            }
        }

        # Configurer les Ã©tiquettes de donnÃ©es
        if ($Config.ShowValues) {
            $Series2.DataLabel.ShowValue = $true
            if (-not [string]::IsNullOrEmpty($Config.LabelFormat)) {
                $Series2.DataLabel.NumberFormat = $Config.LabelFormat
            }
        }

        if ($Config.ShowLabels) {
            $Series2.DataLabel.ShowCategory = $true
        }

        # Configurer la largeur de l'espace entre les barres
        if ($Chart.PSObject.Properties.Name -contains "GapWidth") {
            $Chart.GapWidth = $Config.GapWidth
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique en cascade: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique en entonnoir (funnel) dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique en entonnoir (funnel) dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:B10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER Config
    Configuration du graphique en entonnoir.
.EXAMPLE
    $Config = [ExcelFunnelChartConfig]::new("Processus de vente")
    $Config.ShowPercentages = $true
    $Config.ShowLabels = $true
    $Config.NeckWidth = 30

    $ChartId = New-ExcelFunnelChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:B6" -ChartName "FunnelChart" -Title "Processus de vente" -Position "E1:J15" -Config $Config
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelFunnelChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "FunnelChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [ExcelFunnelChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelFunnelChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Analyser la plage de donnÃ©es pour obtenir les valeurs
        $RangeParts = $DataRange.Split(':')
        if ($RangeParts.Length -ne 2) {
            throw "Format de plage non valide: $DataRange"
        }

        $StartCell = $RangeParts[0]
        $EndCell = $RangeParts[1]

        $StartCol = [int][char]$StartCell.Substring(0, 1) - [int][char]'A' + 1
        $EndCol = [int][char]$EndCell.Substring(0, 1) - [int][char]'A' + 1

        $StartRow = [int]::Parse($StartCell.Substring(1))
        $EndRow = [int]::Parse($EndCell.Substring(1))

        # CrÃ©er une feuille temporaire pour les donnÃ©es du graphique en entonnoir
        $TempSheetName = "Temp_Funnel_" + [Guid]::NewGuid().ToString().Substring(0, 8)
        $TempSheet = $Workbook.Worksheets.Add($TempSheetName)

        # Collecter les donnÃ©es et calculer les pourcentages
        $Data = @()
        $Total = 0

        for ($Row = $StartRow; $Row -le $EndRow; $Row++) {
            $Label = $Worksheet.Cells[$Row, $StartCol].Value
            $Value = [double]$Worksheet.Cells[$Row, $StartCol + 1].Value

            if ($Value -gt 0) {
                # Ignorer les valeurs nÃ©gatives ou nulles
                $Data += [PSCustomObject]@{
                    Label = $Label
                    Value = $Value
                }

                if ($Row -eq $StartRow) {
                    # Utiliser la premiÃ¨re valeur comme total
                    $Total = $Value
                }
            }
        }

        # Trier les donnÃ©es par valeur dÃ©croissante
        $Data = $Data | Sort-Object -Property Value -Descending

        # Copier les donnÃ©es dans la feuille temporaire et calculer les pourcentages
        for ($i = 0; $i -lt $Data.Count; $i++) {
            $TempSheet.Cells[$i + 1, 1].Value = $Data[$i].Label
            $TempSheet.Cells[$i + 1, 2].Value = $Data[$i].Value
            $TempSheet.Cells[$i + 1, 3].Value = $Data[$i].Value / $Total
        }

        # CrÃ©er le graphique (utiliser un graphique en colonnes empilÃ©es comme base)
        # Note: Excel n'a pas de type de graphique en entonnoir natif, nous allons simuler avec un graphique en colonnes
        $Chart = $Worksheet.Drawings.AddChart($ChartName, [OfficeOpenXml.Drawing.Chart.eChartType]::ColumnStacked100)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        } elseif (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Position = [OfficeOpenXml.Drawing.Chart.eLegendPosition]::$($Config.LegendPosition)
        $Chart.Legend.Font.Size = 10
        $Chart.Legend.Visible = $Config.ShowLegend

        # Ajouter les sÃ©ries de donnÃ©es
        $Series = $Chart.Series.Add("$TempSheetName!A1:A$($Data.Count)", "$TempSheetName!B1:B$($Data.Count)")

        # Configurer les Ã©tiquettes de donnÃ©es
        if ($Config.ShowValues) {
            $Series.DataLabel.ShowValue = $true
            if (-not [string]::IsNullOrEmpty($Config.LabelFormat)) {
                $Series.DataLabel.NumberFormat = $Config.LabelFormat
            }
        }

        if ($Config.ShowPercentages) {
            $Series.DataLabel.ShowPercent = $true
            if (-not [string]::IsNullOrEmpty($Config.PercentFormat)) {
                $Series.DataLabel.PercentageNumberFormat = $Config.PercentFormat
            }
        }

        if ($Config.ShowLabels) {
            $Series.DataLabel.ShowCategory = $true
        }

        # Configurer les couleurs personnalisÃ©es si spÃ©cifiÃ©es
        if ($Config.CustomColors.Count -gt 0) {
            for ($i = 0; $i -lt [Math]::Min($Data.Count, $Config.CustomColors.Count); $i++) {
                if ($Series.PSObject.Methods.Name -contains "SetColor") {
                    $Series.SetColor($i, $Config.CustomColors[$i])
                }
            }
        } elseif ($Config.GradientFill) {
            # CrÃ©er un dÃ©gradÃ© de couleurs
            $StartColorRGB = ConvertFrom-HexColor -HexColor $Config.StartColor
            $EndColorRGB = ConvertFrom-HexColor -HexColor $Config.EndColor

            for ($i = 0; $i -lt $Data.Count; $i++) {
                $Factor = $i / [Math]::Max(1, $Data.Count - 1)

                $R = $StartColorRGB.R + ($EndColorRGB.R - $StartColorRGB.R) * $Factor
                $G = $StartColorRGB.G + ($EndColorRGB.G - $StartColorRGB.G) * $Factor
                $B = $StartColorRGB.B + ($EndColorRGB.B - $StartColorRGB.B) * $Factor

                $Color = "#{0:X2}{1:X2}{2:X2}" -f [int]$R, [int]$G, [int]$B

                if ($Series.PSObject.Methods.Name -contains "SetColor") {
                    $Series.SetColor($i, $Color)
                }
            }
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique en entonnoir: $_"
        return $null
    }
}

# Fonction auxiliaire pour convertir une couleur hexadÃ©cimale en RGB
function ConvertFrom-HexColor {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HexColor
    )

    # Supprimer le # si prÃ©sent
    $HexColor = $HexColor -replace '#', ''

    # Convertir en RGB
    $R = [Convert]::ToInt32($HexColor.Substring(0, 2), 16)
    $G = [Convert]::ToInt32($HexColor.Substring(2, 2), 16)
    $B = [Convert]::ToInt32($HexColor.Substring(4, 2), 16)

    return [PSCustomObject]@{
        R = $R
        G = $G
        B = $B
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique de type jauge dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique de type jauge dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER Value
    Valeur actuelle de la jauge.
.PARAMETER MinValue
    Valeur minimale de la jauge (dÃ©faut: 0).
.PARAMETER MaxValue
    Valeur maximale de la jauge (dÃ©faut: 100).
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER Position
    Position du graphique (par exemple: "E1:J15").
.PARAMETER Config
    Configuration du graphique de type jauge.
.EXAMPLE
    $Config = [ExcelGaugeChartConfig]::new("Performance", 75)
    $Config.Thresholds = @(33, 66)
    $Config.ZoneColors = @("#FF0000", "#FFBF00", "#00B050")
    $Config.ShowValue = $true

    $ChartId = New-ExcelGaugeChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -Value 75 -ChartName "GaugeChart" -Title "Performance" -Position "E1:J15" -Config $Config
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelGaugeChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $false)]
        [double]$MinValue = 0,

        [Parameter(Mandatory = $false)]
        [double]$MaxValue = 100,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "GaugeChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [ExcelGaugeChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelGaugeChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
            $Config.Value = $Value
            $Config.MinValue = $MinValue
            $Config.MaxValue = $MaxValue
        } else {
            # Mettre Ã  jour les valeurs si spÃ©cifiÃ©es dans les paramÃ¨tres
            if ($Value -ne 0) {
                $Config.Value = $Value
            }
            if ($MinValue -ne 0) {
                $Config.MinValue = $MinValue
            }
            if ($MaxValue -ne 100) {
                $Config.MaxValue = $MaxValue
            }
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # CrÃ©er une feuille temporaire pour les donnÃ©es du graphique de type jauge
        $TempSheetName = "Temp_Gauge_" + [Guid]::NewGuid().ToString().Substring(0, 8)
        $TempSheet = $Workbook.Worksheets.Add($TempSheetName)

        # Calculer les angles en radians
        $StartAngle = $Config.StartAngle * [Math]::PI / 180
        $EndAngle = $Config.EndAngle * [Math]::PI / 180
        $TotalAngle = $EndAngle - $StartAngle

        # Calculer le pourcentage de la valeur actuelle
        $ValueRange = $Config.MaxValue - $Config.MinValue
        $ValuePercent = ($Config.Value - $Config.MinValue) / $ValueRange

        # Nombre de points pour dessiner l'arc
        $NumPoints = 100

        # Rayon extÃ©rieur et intÃ©rieur (pour l'Ã©paisseur)
        $OuterRadius = 1.0
        $InnerRadius = 1.0 - ($Config.GaugeThickness / 100.0)

        # Centre du cercle
        $CenterX = 0.0
        $CenterY = 0.0

        # PrÃ©parer les donnÃ©es pour les zones
        $ZoneAngles = @($StartAngle)

        foreach ($Threshold in $Config.Thresholds) {
            $ThresholdPercent = ($Threshold - $Config.MinValue) / $ValueRange
            $ZoneAngles += $StartAngle + $ThresholdPercent * $TotalAngle
        }

        $ZoneAngles += $EndAngle

        # CrÃ©er les donnÃ©es pour chaque zone
        for ($ZoneIndex = 0; $ZoneIndex -lt $Config.ZoneColors.Count; $ZoneIndex++) {
            $ZoneStartAngle = $ZoneAngles[$ZoneIndex]
            $ZoneEndAngle = $ZoneAngles[$ZoneIndex + 1]
            $ZoneAngleRange = $ZoneEndAngle - $ZoneStartAngle

            # CrÃ©er les points pour cette zone
            $PointsPerZone = [Math]::Max(5, [Math]::Floor($NumPoints * ($ZoneAngleRange / $TotalAngle)))

            for ($i = 0; $i -le $PointsPerZone; $i++) {
                $Angle = $ZoneStartAngle + ($i / $PointsPerZone) * $ZoneAngleRange

                # CoordonnÃ©es du point extÃ©rieur
                $OuterX = $CenterX + $OuterRadius * [Math]::Cos($Angle)
                $OuterY = $CenterY + $OuterRadius * [Math]::Sin($Angle)

                # CoordonnÃ©es du point intÃ©rieur
                $InnerX = $CenterX + $InnerRadius * [Math]::Cos($Angle)
                $InnerY = $CenterY + $InnerRadius * [Math]::Sin($Angle)

                # Ajouter les points Ã  la feuille temporaire
                $RowIndex = $ZoneIndex * ($PointsPerZone + 1) * 2 + $i * 2 + 1

                $TempSheet.Cells[$RowIndex, 1].Value = $OuterX
                $TempSheet.Cells[$RowIndex, 2].Value = $OuterY
                $TempSheet.Cells[$RowIndex, 3].Value = $ZoneIndex + 1  # Identifiant de la zone

                $TempSheet.Cells[$RowIndex + 1, 1].Value = $InnerX
                $TempSheet.Cells[$RowIndex + 1, 2].Value = $InnerY
                $TempSheet.Cells[$RowIndex + 1, 3].Value = $ZoneIndex + 1  # Identifiant de la zone
            }
        }

        # Calculer l'angle de l'aiguille
        $NeedleAngle = $StartAngle + $ValuePercent * $TotalAngle

        # CoordonnÃ©es de l'aiguille
        $NeedleX = $CenterX + $OuterRadius * 0.8 * [Math]::Cos($NeedleAngle)
        $NeedleY = $CenterY + $OuterRadius * 0.8 * [Math]::Sin($NeedleAngle)

        # Ajouter les coordonnÃ©es de l'aiguille Ã  la feuille temporaire
        $NeedleRowIndex = $Config.ZoneColors.Count * ($NumPoints + 1) * 2 + 1

        $TempSheet.Cells[$NeedleRowIndex, 1].Value = $CenterX
        $TempSheet.Cells[$NeedleRowIndex, 2].Value = $CenterY
        $TempSheet.Cells[$NeedleRowIndex, 3].Value = 0  # Identifiant spÃ©cial pour l'aiguille

        $TempSheet.Cells[$NeedleRowIndex + 1, 1].Value = $NeedleX
        $TempSheet.Cells[$NeedleRowIndex + 1, 2].Value = $NeedleY
        $TempSheet.Cells[$NeedleRowIndex + 1, 3].Value = 0  # Identifiant spÃ©cial pour l'aiguille

        # Ajouter la valeur au centre
        $TempSheet.Cells[$NeedleRowIndex + 2, 1].Value = $CenterX
        $TempSheet.Cells[$NeedleRowIndex + 2, 2].Value = $CenterY - 0.2  # LÃ©gÃ¨rement en dessous du centre
        $TempSheet.Cells[$NeedleRowIndex + 2, 3].Value = $Config.Value.ToString($Config.ValueFormat) + $Config.ValueSuffix

        # CrÃ©er le graphique (utiliser un graphique de dispersion comme base)
        $Chart = $Worksheet.Drawings.AddChart($ChartName, [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatter)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        } elseif (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Visible = $false

        # Configurer les axes
        $Chart.XAxis.MinValue = -1.1
        $Chart.XAxis.MaxValue = 1.1
        $Chart.YAxis.MinValue = -1.1
        $Chart.YAxis.MaxValue = 1.1

        # Masquer les axes
        $Chart.XAxis.MajorTickMark = [OfficeOpenXml.Drawing.Chart.eAxisTickMark]::None
        $Chart.XAxis.MinorTickMark = [OfficeOpenXml.Drawing.Chart.eAxisTickMark]::None
        $Chart.YAxis.MajorTickMark = [OfficeOpenXml.Drawing.Chart.eAxisTickMark]::None
        $Chart.YAxis.MinorTickMark = [OfficeOpenXml.Drawing.Chart.eAxisTickMark]::None

        $Chart.XAxis.MajorGridlines.Visible = $false
        $Chart.YAxis.MajorGridlines.Visible = $false

        $Chart.XAxis.Visible = $false
        $Chart.YAxis.Visible = $false

        # Ajouter les sÃ©ries pour chaque zone
        for ($ZoneIndex = 0; $ZoneIndex -lt $Config.ZoneColors.Count; $ZoneIndex++) {
            $StartRow = $ZoneIndex * ($NumPoints + 1) * 2 + 1
            $EndRow = ($ZoneIndex + 1) * ($NumPoints + 1) * 2

            $Series = $Chart.Series.Add("$TempSheetName!A$StartRow:B$EndRow", $null, [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatter)
            $Series.Header = "Zone $($ZoneIndex + 1)"

            # Configurer l'apparence de la sÃ©rie
            if ($Series.PSObject.Properties.Name -contains "Fill") {
                $Series.Fill.Color.SetColor($Config.ZoneColors[$ZoneIndex])
            }

            if ($Series.PSObject.Properties.Name -contains "MarkerSize") {
                $Series.MarkerSize = 2
            }

            if ($Series.PSObject.Properties.Name -contains "ShowInLegend") {
                $Series.ShowInLegend = $false
            }
        }

        # Ajouter la sÃ©rie pour l'aiguille si nÃ©cessaire
        if ($Config.ShowNeedle) {
            $NeedleStartRow = $Config.ZoneColors.Count * ($NumPoints + 1) * 2 + 1
            $NeedleEndRow = $NeedleStartRow + 1

            $NeedleSeries = $Chart.Series.Add("$TempSheetName!A$NeedleStartRow:B$NeedleEndRow", $null, [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatterLines)
            $NeedleSeries.Header = "Aiguille"

            # Configurer l'apparence de l'aiguille
            if ($NeedleSeries.PSObject.Properties.Name -contains "LineColor") {
                $NeedleSeries.LineColor.SetColor($Config.NeedleColor)
            }

            if ($NeedleSeries.PSObject.Properties.Name -contains "LineWidth") {
                $NeedleSeries.LineWidth = $Config.NeedleWidth
            }

            if ($NeedleSeries.PSObject.Properties.Name -contains "ShowInLegend") {
                $NeedleSeries.ShowInLegend = $false
            }
        }

        # Ajouter la valeur au centre si nÃ©cessaire
        if ($Config.ShowValue) {
            $ValueRow = $Config.ZoneColors.Count * ($NumPoints + 1) * 2 + 3

            $ValueSeries = $Chart.Series.Add("$TempSheetName!A$ValueRow:B$ValueRow", "$TempSheetName!C$ValueRow:C$ValueRow", [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatter)
            $ValueSeries.Header = "Valeur"

            # Configurer l'apparence de la valeur
            if ($ValueSeries.PSObject.Properties.Name -contains "MarkerSize") {
                $ValueSeries.MarkerSize = 1
            }

            if ($ValueSeries.PSObject.Properties.Name -contains "MarkerStyle") {
                $ValueSeries.MarkerStyle = [OfficeOpenXml.Drawing.Chart.eMarkerStyle]::None
            }

            if ($ValueSeries.PSObject.Properties.Name -contains "ShowInLegend") {
                $ValueSeries.ShowInLegend = $false
            }

            # Afficher les Ã©tiquettes de donnÃ©es
            $ValueSeries.DataLabel.ShowValue = $false
            $ValueSeries.DataLabel.ShowCategory = $false
            $ValueSeries.DataLabel.ShowSeriesName = $false
            $ValueSeries.DataLabel.ShowLegendKey = $false
            $ValueSeries.DataLabel.ShowPercent = $false
            $ValueSeries.DataLabel.ShowBubbleSize = $false
            $ValueSeries.DataLabel.Position = [OfficeOpenXml.Drawing.Chart.eLabelPosition]::Center
            $ValueSeries.DataLabel.Font.Size = $Config.ValueFontSize
            $ValueSeries.DataLabel.Font.Bold = $true

            # Utiliser la valeur comme Ã©tiquette personnalisÃ©e
            $ValueSeries.DataLabel.ShowCustom = $true
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 15)  # CarrÃ© pour un meilleur rendu de la jauge
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize(15, 15)  # CarrÃ© pour un meilleur rendu de la jauge
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique de type jauge: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un graphique de type boÃ®te Ã  moustaches (box plot) dans une feuille Excel.
.DESCRIPTION
    Cette fonction crÃ©e un graphique de type boÃ®te Ã  moustaches (box plot) dans une feuille Excel avec les options spÃ©cifiÃ©es.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER DataRange
    Plage de donnÃ©es pour le graphique (par exemple: "A1:E10").
.PARAMETER ChartName
    Nom du graphique.
.PARAMETER Title
    Titre du graphique.
.PARAMETER XAxisTitle
    Titre de l'axe X.
.PARAMETER YAxisTitle
    Titre de l'axe Y.
.PARAMETER Position
    Position du graphique (par exemple: "F1:L15").
.PARAMETER Config
    Configuration du graphique de type boÃ®te Ã  moustaches.
.EXAMPLE
    $Config = [ExcelBoxPlotChartConfig]::new("Distribution des ventes")
    $Config.ShowOutliers = $true
    $Config.ShowMedian = $true
    $Config.BoxColor = "#4472C4"

    $ChartId = New-ExcelBoxPlotChart -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -DataRange "A1:E10" -ChartName "BoxPlotChart" -Title "Distribution des ventes" -XAxisTitle "CatÃ©gorie" -YAxisTitle "Valeur" -Position "F1:L15" -Config $Config
.OUTPUTS
    System.String - Identifiant du graphique crÃ©Ã©.
#>
function New-ExcelBoxPlotChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$DataRange,

        [Parameter(Mandatory = $false)]
        [string]$ChartName = "BoxPlotChart",

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$XAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$YAxisTitle = "",

        [Parameter(Mandatory = $false)]
        [string]$Position = "",

        [Parameter(Mandatory = $false)]
        [ExcelBoxPlotChartConfig]$Config = $null
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

        # Utiliser la configuration par dÃ©faut si non spÃ©cifiÃ©e
        if ($null -eq $Config) {
            $Config = [ExcelBoxPlotChartConfig]::new()
            if (-not [string]::IsNullOrEmpty($Title)) {
                $Config.Title = $Title
            }
        }

        # Valider la configuration
        if (-not $Config.Validate()) {
            throw "Configuration de graphique invalide"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Analyser la plage de donnÃ©es pour obtenir les valeurs
        $RangeParts = $DataRange.Split(':')
        if ($RangeParts.Length -ne 2) {
            throw "Format de plage non valide: $DataRange"
        }

        $StartCell = $RangeParts[0]
        $EndCell = $RangeParts[1]

        $StartCol = [int][char]$StartCell.Substring(0, 1) - [int][char]'A' + 1
        $EndCol = [int][char]$EndCell.Substring(0, 1) - [int][char]'A' + 1

        $StartRow = [int]::Parse($StartCell.Substring(1))
        $EndRow = [int]::Parse($EndCell.Substring(1))

        # CrÃ©er une feuille temporaire pour les donnÃ©es du graphique de type boÃ®te Ã  moustaches
        $TempSheetName = "Temp_BoxPlot_" + [Guid]::NewGuid().ToString().Substring(0, 8)
        $TempSheet = $Workbook.Worksheets.Add($TempSheetName)

        # Collecter les donnÃ©es et calculer les statistiques pour chaque sÃ©rie
        $SeriesCount = $EndCol - $StartCol

        for ($ColIndex = 0; $ColIndex -lt $SeriesCount; $ColIndex++) {
            $Col = $StartCol + $ColIndex + 1  # +1 car la premiÃ¨re colonne contient les Ã©tiquettes
            $SeriesName = $Worksheet.Cells[$StartRow, $Col].Value

            # Collecter les valeurs de cette sÃ©rie
            $Values = @()
            for ($Row = $StartRow + 1; $Row -le $EndRow; $Row++) {
                $Value = $Worksheet.Cells[$Row, $Col].Value
                if ($null -ne $Value -and $Value -is [double]) {
                    $Values += $Value
                }
            }

            # Trier les valeurs
            $Values = $Values | Sort-Object

            # Calculer les statistiques
            $Min = $Values[0]
            $Max = $Values[$Values.Count - 1]

            $Q1Index = [Math]::Floor($Values.Count * 0.25)
            $Q1 = $Values[$Q1Index]

            $MedianIndex = [Math]::Floor($Values.Count * 0.5)
            $Median = $Values[$MedianIndex]

            $Q3Index = [Math]::Floor($Values.Count * 0.75)
            $Q3 = $Values[$Q3Index]

            # Calculer l'IQR (Interquartile Range)
            $IQR = $Q3 - $Q1

            # DÃ©terminer les limites des moustaches
            $LowerWhisker = [Math]::Max($Min, $Q1 - 1.5 * $IQR)
            $UpperWhisker = [Math]::Min($Max, $Q3 + 1.5 * $IQR)

            # Identifier les valeurs aberrantes
            $Outliers = @()
            foreach ($Value in $Values) {
                if ($Value -lt $LowerWhisker -or $Value -gt $UpperWhisker) {
                    $Outliers += $Value
                }
            }

            # Calculer la moyenne si nÃ©cessaire
            $Mean = 0
            if ($Config.ShowMean) {
                $Mean = ($Values | Measure-Object -Average).Average
            }

            # Stocker les statistiques dans la feuille temporaire
            $TempSheet.Cells[1, $ColIndex * 7 + 1].Value = $SeriesName
            $TempSheet.Cells[2, $ColIndex * 7 + 1].Value = $Min
            $TempSheet.Cells[2, $ColIndex * 7 + 2].Value = $LowerWhisker
            $TempSheet.Cells[2, $ColIndex * 7 + 3].Value = $Q1
            $TempSheet.Cells[2, $ColIndex * 7 + 4].Value = $Median
            $TempSheet.Cells[2, $ColIndex * 7 + 5].Value = $Q3
            $TempSheet.Cells[2, $ColIndex * 7 + 6].Value = $UpperWhisker
            $TempSheet.Cells[2, $ColIndex * 7 + 7].Value = $Max

            # Stocker la moyenne si nÃ©cessaire
            if ($Config.ShowMean) {
                $TempSheet.Cells[3, $ColIndex * 7 + 1].Value = $Mean
            }

            # Stocker les valeurs aberrantes si nÃ©cessaire
            if ($Config.ShowOutliers) {
                for ($i = 0; $i -lt $Outliers.Count; $i++) {
                    $TempSheet.Cells[4 + $i, $ColIndex * 7 + 1].Value = $Outliers[$i]
                }
            }
        }

        # CrÃ©er le graphique (utiliser un graphique en colonnes comme base)
        $Chart = $Worksheet.Drawings.AddChart($ChartName, [OfficeOpenXml.Drawing.Chart.eChartType]::ColumnStacked)

        # Configurer le titre
        if (-not [string]::IsNullOrEmpty($Config.Title)) {
            $Chart.Title.Text = $Config.Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        } elseif (-not [string]::IsNullOrEmpty($Title)) {
            $Chart.Title.Text = $Title
            $Chart.Title.Font.Size = 14
            $Chart.Title.Font.Bold = $true
        }

        # Configurer la lÃ©gende
        $Chart.Legend.Visible = $false

        # Configurer les axes
        if (-not [string]::IsNullOrEmpty($XAxisTitle)) {
            $Chart.XAxis.Title.Text = $XAxisTitle
            $Chart.XAxis.Title.Font.Size = 12
        }

        if (-not [string]::IsNullOrEmpty($YAxisTitle)) {
            $Chart.YAxis.Title.Text = $YAxisTitle
            $Chart.YAxis.Title.Font.Size = 12
        }

        # Ajouter les sÃ©ries pour chaque boÃ®te Ã  moustaches
        for ($ColIndex = 0; $ColIndex -lt $SeriesCount; $ColIndex++) {
            $SeriesName = $TempSheet.Cells[1, $ColIndex * 7 + 1].Value

            # Ajouter la sÃ©rie pour la boÃ®te (Q1 Ã  Q3)
            $BoxSeries = $Chart.Series.Add("$TempSheetName!A1:A1", "$TempSheetName!${ColIndex}3:${ColIndex}5", [OfficeOpenXml.Drawing.Chart.eChartType]::ColumnStacked)
            $BoxSeries.Header = "$SeriesName (BoÃ®te)"

            # Configurer l'apparence de la boÃ®te
            if ($BoxSeries.PSObject.Properties.Name -contains "Fill") {
                $BoxSeries.Fill.Color.SetColor($Config.BoxColor)
            }

            # Ajouter la sÃ©rie pour les moustaches
            $WhiskerSeries = $Chart.Series.Add("$TempSheetName!A1:A1", "$TempSheetName!${ColIndex}2:${ColIndex}6", [OfficeOpenXml.Drawing.Chart.eChartType]::Line)
            $WhiskerSeries.Header = "$SeriesName (Moustaches)"

            # Configurer l'apparence des moustaches
            if ($WhiskerSeries.PSObject.Properties.Name -contains "LineColor") {
                $WhiskerSeries.LineColor.SetColor($Config.WhiskerColor)
            }

            # Ajouter la sÃ©rie pour la mÃ©diane si nÃ©cessaire
            if ($Config.ShowMedian) {
                $MedianSeries = $Chart.Series.Add("$TempSheetName!A1:A1", "$TempSheetName!${ColIndex}4:${ColIndex}4", [OfficeOpenXml.Drawing.Chart.eChartType]::Line)
                $MedianSeries.Header = "$SeriesName (MÃ©diane)"

                # Configurer l'apparence de la mÃ©diane
                if ($MedianSeries.PSObject.Properties.Name -contains "LineColor") {
                    $MedianSeries.LineColor.SetColor($Config.MedianColor)
                }
            }

            # Ajouter la sÃ©rie pour la moyenne si nÃ©cessaire
            if ($Config.ShowMean) {
                $MeanSeries = $Chart.Series.Add("$TempSheetName!A1:A1", "$TempSheetName!${ColIndex}3:${ColIndex}3", [OfficeOpenXml.Drawing.Chart.eChartType]::Line)
                $MeanSeries.Header = "$SeriesName (Moyenne)"

                # Configurer l'apparence de la moyenne
                if ($MeanSeries.PSObject.Properties.Name -contains "LineColor") {
                    $MeanSeries.LineColor.SetColor($Config.MeanColor)
                }
            }

            # Ajouter la sÃ©rie pour les valeurs aberrantes si nÃ©cessaire
            if ($Config.ShowOutliers) {
                $OutlierCount = 0
                for ($i = 4; $i -lt 20; $i++) {
                    # Limiter Ã  16 valeurs aberrantes par sÃ©rie
                    $OutlierValue = $TempSheet.Cells[$i, $ColIndex * 7 + 1].Value
                    if ($null -ne $OutlierValue) {
                        $OutlierCount++
                    } else {
                        break
                    }
                }

                if ($OutlierCount -gt 0) {
                    $OutlierSeries = $Chart.Series.Add("$TempSheetName!A1:A1", "$TempSheetName!${ColIndex}4:${ColIndex}$(4+$OutlierCount-1)", [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatter)
                    $OutlierSeries.Header = "$SeriesName (Valeurs aberrantes)"

                    # Configurer l'apparence des valeurs aberrantes
                    if ($OutlierSeries.PSObject.Properties.Name -contains "MarkerColor") {
                        $OutlierSeries.MarkerColor.SetColor($Config.OutlierColor)
                    }

                    if ($OutlierSeries.PSObject.Properties.Name -contains "MarkerSize") {
                        $OutlierSeries.MarkerSize = 5
                    }
                }
            }

            # Afficher les statistiques si nÃ©cessaire
            if ($Config.ShowStatistics) {
                $StatsSeries = $Chart.Series.Add("$TempSheetName!A1:A1", "$TempSheetName!${ColIndex}2:${ColIndex}7", [OfficeOpenXml.Drawing.Chart.eChartType]::XYScatter)
                $StatsSeries.Header = "$SeriesName (Statistiques)"

                # Configurer l'apparence des statistiques
                if ($StatsSeries.PSObject.Properties.Name -contains "MarkerSize") {
                    $StatsSeries.MarkerSize = 1
                }

                if ($StatsSeries.PSObject.Properties.Name -contains "MarkerStyle") {
                    $StatsSeries.MarkerStyle = [OfficeOpenXml.Drawing.Chart.eMarkerStyle]::None
                }

                # Afficher les Ã©tiquettes de donnÃ©es
                $StatsSeries.DataLabel.ShowValue = $true
                if (-not [string]::IsNullOrEmpty($Config.ValueFormat)) {
                    $StatsSeries.DataLabel.NumberFormat = $Config.ValueFormat
                }
            }
        }

        # Configurer la position du graphique
        if (-not [string]::IsNullOrEmpty($Position)) {
            $PositionParts = $Position.Split(':')
            if ($PositionParts.Length -eq 2) {
                $FromRow = [int]::Parse($PositionParts[0].Substring(1))
                $FromCol = [int][char]$PositionParts[0].Substring(0, 1) - [int][char]'A' + 1
                $ToRow = [int]::Parse($PositionParts[1].Substring(1))
                $ToCol = [int][char]$PositionParts[1].Substring(0, 1) - [int][char]'A' + 1

                $Chart.SetPosition($FromRow, 0, $FromCol, 0)
                $Chart.SetSize($ToCol - $FromCol, $ToRow - $FromRow)
            } else {
                # Position par dÃ©faut
                $Chart.SetPosition(1, 0, 5, 0)
                $Chart.SetSize(15, 10)
            }
        } else {
            # Position par dÃ©faut
            $Chart.SetPosition(1, 0, 5, 0)
            $Chart.SetSize($Config.Width / 7, $Config.Height / 20)
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        # Retourner l'identifiant du graphique
        return $ChartName
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du graphique de type boÃ®te Ã  moustaches: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-ExcelLineChart, New-ExcelBarChart, New-ExcelPieChart, New-ExcelComboChart, New-ExcelBubbleChart, New-ExcelAreaChart, New-ExcelRadarChart, New-ExcelWaterfallChart, New-ExcelFunnelChart, New-ExcelGaugeChart, New-ExcelBoxPlotChart, Set-ExcelChartAxes, Add-ExcelChartTrendline, Add-ExcelChartReferenceLine, Group-ExcelPieChartSmallValues
