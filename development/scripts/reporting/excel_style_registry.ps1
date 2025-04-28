<#
.SYNOPSIS
    Module de gestion des styles pour les graphiques Excel.
.DESCRIPTION
    Ce module fournit un registre centralisÃ© pour stocker, gÃ©rer et appliquer
    des styles prÃ©dÃ©finis aux graphiques Excel, incluant les styles de lignes,
    marqueurs, couleurs, bordures et thÃ¨mes complets.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de crÃ©ation: 2025-04-25
#>

# VÃ©rifier si le module excel_chart_styles.ps1 est disponible
$StylesPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_chart_styles.ps1"
if (-not (Test-Path -Path $StylesPath)) {
    throw "Le module excel_chart_styles.ps1 est requis mais n'a pas Ã©tÃ© trouvÃ©."
}

# Importer le module excel_chart_styles.ps1
. $StylesPath

#region Interfaces de base pour les styles

# Interface de base pour tous les styles Excel
class IExcelStyle {
    [string]$Id
    [string]$Name
    [string]$Description
    [string]$Category
    [string[]]$Tags
    [bool]$IsBuiltIn
    [datetime]$CreatedDate
    [datetime]$ModifiedDate

    # Constructeur par dÃ©faut
    IExcelStyle() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Name = "Default Style"
        $this.Description = "Style par dÃ©faut"
        $this.Category = "General"
        $this.Tags = @()
        $this.IsBuiltIn = $false
        $this.CreatedDate = [datetime]::Now
        $this.ModifiedDate = [datetime]::Now
    }

    # Constructeur avec nom et description
    IExcelStyle([string]$Name, [string]$Description) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Name = $Name
        $this.Description = $Description
        $this.Category = "General"
        $this.Tags = @()
        $this.IsBuiltIn = $false
        $this.CreatedDate = [datetime]::Now
        $this.ModifiedDate = [datetime]::Now
    }

    # Constructeur complet
    IExcelStyle([string]$Id, [string]$Name, [string]$Description, [string]$Category, [string[]]$Tags, [bool]$IsBuiltIn) {
        if ([string]::IsNullOrEmpty($Id)) {
            $this.Id = [Guid]::NewGuid().ToString()
        } else {
            $this.Id = $Id
        }
        $this.Name = $Name
        $this.Description = $Description
        $this.Category = $Category
        $this.Tags = $Tags
        $this.IsBuiltIn = $IsBuiltIn
        $this.CreatedDate = [datetime]::Now
        $this.ModifiedDate = [datetime]::Now
    }

    # MÃ©thode pour valider le style (Ã  implÃ©menter dans les classes dÃ©rivÃ©es)
    [bool] Validate() {
        # Validation de base
        if ([string]::IsNullOrEmpty($this.Id) -or [string]::IsNullOrEmpty($this.Name)) {
            return $false
        }
        return $true
    }

    # MÃ©thode pour cloner le style (Ã  implÃ©menter dans les classes dÃ©rivÃ©es)
    [IExcelStyle] Clone() {
        throw "La mÃ©thode Clone() doit Ãªtre implÃ©mentÃ©e dans les classes dÃ©rivÃ©es."
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "$($this.Name) - $($this.Description)"
    }

    # MÃ©thode pour ajouter un tag
    [void] AddTag([string]$Tag) {
        if (-not [string]::IsNullOrEmpty($Tag) -and -not ($this.Tags -contains $Tag)) {
            $this.Tags += $Tag
            $this.ModifiedDate = [datetime]::Now
        }
    }

    # MÃ©thode pour supprimer un tag
    [bool] RemoveTag([string]$Tag) {
        if ($this.Tags -contains $Tag) {
            $this.Tags = $this.Tags | Where-Object { $_ -ne $Tag }
            $this.ModifiedDate = [datetime]::Now
            return $true
        }
        return $false
    }

    # MÃ©thode pour vÃ©rifier si le style a un tag spÃ©cifique
    [bool] HasTag([string]$Tag) {
        return $this.Tags -contains $Tag
    }

    # MÃ©thode pour mettre Ã  jour les mÃ©tadonnÃ©es
    [void] UpdateMetadata([string]$Name, [string]$Description, [string]$Category) {
        if (-not [string]::IsNullOrEmpty($Name)) {
            $this.Name = $Name
        }
        if (-not [string]::IsNullOrEmpty($Description)) {
            $this.Description = $Description
        }
        if (-not [string]::IsNullOrEmpty($Category)) {
            $this.Category = $Category
        }
        $this.ModifiedDate = [datetime]::Now
    }
}

# Interface pour les styles de ligne
class ExcelLineStyle : IExcelStyle {
    [ExcelLineStyleConfig]$LineConfig

    # Constructeur par dÃ©faut
    ExcelLineStyle() : base() {
        $this.LineConfig = [ExcelLineStyleConfig]::new()
        $this.Name = "Default Line Style"
        $this.Description = "Style de ligne par dÃ©faut"
        $this.Category = "Lines"
    }

    # Constructeur avec configuration de ligne
    ExcelLineStyle([ExcelLineStyleConfig]$LineConfig) : base() {
        $this.LineConfig = $LineConfig
        $this.Name = "Custom Line Style"
        $this.Description = "Style de ligne personnalisÃ©"
        $this.Category = "Lines"
    }

    # Constructeur complet
    ExcelLineStyle([string]$Id, [string]$Name, [string]$Description, [string]$Category, [string[]]$Tags, [bool]$IsBuiltIn, [ExcelLineStyleConfig]$LineConfig) : base($Id, $Name, $Description, $Category, $Tags, $IsBuiltIn) {
        $this.LineConfig = $LineConfig
    }

    # MÃ©thode pour valider le style
    [bool] Validate() {
        if (-not ([base]::Validate())) {
            return $false
        }

        if ($null -eq $this.LineConfig) {
            return $false
        }

        return $this.LineConfig.Validate()
    }

    # MÃ©thode pour cloner le style
    [IExcelStyle] Clone() {
        $Clone = [ExcelLineStyle]::new()
        $Clone.Id = [Guid]::NewGuid().ToString()
        $Clone.Name = $this.Name
        $Clone.Description = $this.Description
        $Clone.Category = $this.Category
        $Clone.Tags = $this.Tags.Clone()
        $Clone.IsBuiltIn = $false
        $Clone.CreatedDate = [datetime]::Now
        $Clone.ModifiedDate = [datetime]::Now
        $Clone.LineConfig = $this.LineConfig.Clone()

        return $Clone
    }

    # MÃ©thode pour appliquer le style Ã  une sÃ©rie
    [void] ApplyToSeries([object]$Series) {
        if ($null -ne $this.LineConfig -and $null -ne $Series) {
            $this.LineConfig.ApplyToSeries($Series)
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "Line Style: $($this.Name) - $($this.LineConfig.ToString())"
    }
}

# Interface pour les styles de marqueur
class ExcelMarkerStyle : IExcelStyle {
    [ExcelMarkerConfig]$MarkerConfig

    # Constructeur par dÃ©faut
    ExcelMarkerStyle() : base() {
        $this.MarkerConfig = [ExcelMarkerConfig]::new()
        $this.Name = "Default Marker Style"
        $this.Description = "Style de marqueur par dÃ©faut"
        $this.Category = "Markers"
    }

    # Constructeur avec configuration de marqueur
    ExcelMarkerStyle([ExcelMarkerConfig]$MarkerConfig) : base() {
        $this.MarkerConfig = $MarkerConfig
        $this.Name = "Custom Marker Style"
        $this.Description = "Style de marqueur personnalisÃ©"
        $this.Category = "Markers"
    }

    # Constructeur complet
    ExcelMarkerStyle([string]$Id, [string]$Name, [string]$Description, [string]$Category, [string[]]$Tags, [bool]$IsBuiltIn, [ExcelMarkerConfig]$MarkerConfig) : base($Id, $Name, $Description, $Category, $Tags, $IsBuiltIn) {
        $this.MarkerConfig = $MarkerConfig
    }

    # MÃ©thode pour valider le style
    [bool] Validate() {
        if (-not ([base]::Validate())) {
            return $false
        }

        if ($null -eq $this.MarkerConfig) {
            return $false
        }

        return $this.MarkerConfig.Validate()
    }

    # MÃ©thode pour cloner le style
    [IExcelStyle] Clone() {
        $Clone = [ExcelMarkerStyle]::new()
        $Clone.Id = [Guid]::NewGuid().ToString()
        $Clone.Name = $this.Name
        $Clone.Description = $this.Description
        $Clone.Category = $this.Category
        $Clone.Tags = $this.Tags.Clone()
        $Clone.IsBuiltIn = $false
        $Clone.CreatedDate = [datetime]::Now
        $Clone.ModifiedDate = [datetime]::Now
        $Clone.MarkerConfig = $this.MarkerConfig.Clone()

        return $Clone
    }

    # MÃ©thode pour appliquer le style Ã  une sÃ©rie
    [void] ApplyToSeries([object]$Series) {
        if ($null -ne $this.MarkerConfig -and $null -ne $Series) {
            $this.MarkerConfig.ApplyToSeries($Series)
        }
    }

    # MÃ©thode pour appliquer le style Ã  un point de donnÃ©es
    [void] ApplyToDataPoint([object]$DataPoint) {
        if ($null -ne $this.MarkerConfig -and $null -ne $DataPoint) {
            $this.MarkerConfig.ApplyToDataPoint($DataPoint)
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "Marker Style: $($this.Name) - $($this.MarkerConfig.ToString())"
    }
}

# Interface pour les styles de bordure
class ExcelBorderStyle : IExcelStyle {
    [ExcelBorderStyleConfig]$BorderConfig

    # Constructeur par dÃ©faut
    ExcelBorderStyle() : base() {
        $this.BorderConfig = [ExcelBorderStyleConfig]::new()
        $this.Name = "Default Border Style"
        $this.Description = "Style de bordure par dÃ©faut"
        $this.Category = "Borders"
    }

    # Constructeur avec configuration de bordure
    ExcelBorderStyle([ExcelBorderStyleConfig]$BorderConfig) : base() {
        $this.BorderConfig = $BorderConfig
        $this.Name = "Custom Border Style"
        $this.Description = "Style de bordure personnalisÃ©"
        $this.Category = "Borders"
    }

    # Constructeur complet
    ExcelBorderStyle([string]$Id, [string]$Name, [string]$Description, [string]$Category, [string[]]$Tags, [bool]$IsBuiltIn, [ExcelBorderStyleConfig]$BorderConfig) : base($Id, $Name, $Description, $Category, $Tags, $IsBuiltIn) {
        $this.BorderConfig = $BorderConfig
    }

    # MÃ©thode pour valider le style
    [bool] Validate() {
        if (-not ([base]::Validate())) {
            return $false
        }

        if ($null -eq $this.BorderConfig) {
            return $false
        }

        return $this.BorderConfig.Validate()
    }

    # MÃ©thode pour cloner le style
    [IExcelStyle] Clone() {
        $Clone = [ExcelBorderStyle]::new()
        $Clone.Id = [Guid]::NewGuid().ToString()
        $Clone.Name = $this.Name
        $Clone.Description = $this.Description
        $Clone.Category = $this.Category
        $Clone.Tags = $this.Tags.Clone()
        $Clone.IsBuiltIn = $false
        $Clone.CreatedDate = [datetime]::Now
        $Clone.ModifiedDate = [datetime]::Now
        $Clone.BorderConfig = $this.BorderConfig.Clone()

        return $Clone
    }

    # MÃ©thode pour appliquer le style Ã  un Ã©lÃ©ment
    [void] ApplyToElement([object]$Element) {
        if ($null -ne $this.BorderConfig -and $null -ne $Element) {
            $this.BorderConfig.ApplyToElement($Element)
        }
    }

    # MÃ©thode pour appliquer le style Ã  une sÃ©rie
    [void] ApplyToSeries([object]$Series) {
        if ($null -ne $this.BorderConfig -and $null -ne $Series) {
            $this.BorderConfig.ApplyToSeries($Series)
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "Border Style: $($this.Name) - $($this.BorderConfig.ToString())"
    }
}

# Interface pour les styles de couleur
class ExcelColorStyle : IExcelStyle {
    [string]$Color
    [int]$Transparency

    # Constructeur par dÃ©faut
    ExcelColorStyle() : base() {
        $this.Color = "#000000"
        $this.Transparency = 0
        $this.Name = "Default Color Style"
        $this.Description = "Style de couleur par dÃ©faut"
        $this.Category = "Colors"
    }

    # Constructeur avec couleur
    ExcelColorStyle([string]$Color) : base() {
        $this.Color = $Color
        $this.Transparency = 0
        $this.Name = "Custom Color Style"
        $this.Description = "Style de couleur personnalisÃ©"
        $this.Category = "Colors"
    }

    # Constructeur complet
    ExcelColorStyle([string]$Id, [string]$Name, [string]$Description, [string]$Category, [string[]]$Tags, [bool]$IsBuiltIn, [string]$Color, [int]$Transparency) : base($Id, $Name, $Description, $Category, $Tags, $IsBuiltIn) {
        $this.Color = $Color
        $this.Transparency = $Transparency
    }

    # MÃ©thode pour valider le style
    [bool] Validate() {
        if (-not ([base]::Validate())) {
            return $false
        }

        # Valider le format de la couleur
        if (-not ($this.Color -match '^#[0-9A-Fa-f]{6}$')) {
            return $false
        }

        # Valider la transparence
        if ($this.Transparency -lt 0 -or $this.Transparency -gt 100) {
            return $false
        }

        return $true
    }

    # MÃ©thode pour cloner le style
    [IExcelStyle] Clone() {
        $Clone = [ExcelColorStyle]::new()
        $Clone.Id = [Guid]::NewGuid().ToString()
        $Clone.Name = $this.Name
        $Clone.Description = $this.Description
        $Clone.Category = $this.Category
        $Clone.Tags = $this.Tags.Clone()
        $Clone.IsBuiltIn = $false
        $Clone.CreatedDate = [datetime]::Now
        $Clone.ModifiedDate = [datetime]::Now
        $Clone.Color = $this.Color
        $Clone.Transparency = $this.Transparency

        return $Clone
    }

    # MÃ©thode pour appliquer la couleur Ã  un Ã©lÃ©ment
    [void] ApplyToElement([object]$Element, [string]$PropertyName = "Color") {
        if ($null -eq $Element) {
            return
        }

        # VÃ©rifier si l'Ã©lÃ©ment a la propriÃ©tÃ© spÃ©cifiÃ©e
        if ($Element.PSObject.Properties.Name -contains $PropertyName) {
            # Si la propriÃ©tÃ© est un objet avec une mÃ©thode SetColor
            if ($Element.$PropertyName.PSObject.Methods.Name -contains "SetColor") {
                $Element.$PropertyName.SetColor($this.Color)
            }
            # Si la propriÃ©tÃ© est une chaÃ®ne
            elseif ($Element.$PropertyName -is [string]) {
                $Element.$PropertyName = $this.Color
            }
        }

        # Appliquer la transparence si disponible
        if ($Element.PSObject.Properties.Name -contains "Transparency") {
            $Element.Transparency = $this.Transparency
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        return "Color Style: $($this.Name) - Color: $($this.Color), Transparency: $($this.Transparency)%"
    }
}

# Interface pour les styles combinÃ©s (thÃ¨mes)
class ExcelCombinedStyle : IExcelStyle {
    [ExcelLineStyle]$LineStyle
    [ExcelMarkerStyle]$MarkerStyle
    [ExcelBorderStyle]$BorderStyle
    [ExcelColorStyle]$ColorStyle

    # Constructeur par dÃ©faut
    ExcelCombinedStyle() : base() {
        $this.LineStyle = $null
        $this.MarkerStyle = $null
        $this.BorderStyle = $null
        $this.ColorStyle = $null
        $this.Name = "Default Combined Style"
        $this.Description = "Style combinÃ© par dÃ©faut"
        $this.Category = "Combined"
    }

    # Constructeur avec styles
    ExcelCombinedStyle([ExcelLineStyle]$LineStyle, [ExcelMarkerStyle]$MarkerStyle, [ExcelBorderStyle]$BorderStyle, [ExcelColorStyle]$ColorStyle) : base() {
        $this.LineStyle = $LineStyle
        $this.MarkerStyle = $MarkerStyle
        $this.BorderStyle = $BorderStyle
        $this.ColorStyle = $ColorStyle
        $this.Name = "Custom Combined Style"
        $this.Description = "Style combinÃ© personnalisÃ©"
        $this.Category = "Combined"
    }

    # Constructeur complet
    ExcelCombinedStyle([string]$Id, [string]$Name, [string]$Description, [string]$Category, [string[]]$Tags, [bool]$IsBuiltIn, [ExcelLineStyle]$LineStyle, [ExcelMarkerStyle]$MarkerStyle, [ExcelBorderStyle]$BorderStyle, [ExcelColorStyle]$ColorStyle) : base($Id, $Name, $Description, $Category, $Tags, $IsBuiltIn) {
        $this.LineStyle = $LineStyle
        $this.MarkerStyle = $MarkerStyle
        $this.BorderStyle = $BorderStyle
        $this.ColorStyle = $ColorStyle
    }

    # MÃ©thode pour valider le style
    [bool] Validate() {
        if (-not ([base]::Validate())) {
            return $false
        }

        # Au moins un style doit Ãªtre dÃ©fini
        if ($null -eq $this.LineStyle -and $null -eq $this.MarkerStyle -and $null -eq $this.BorderStyle -and $null -eq $this.ColorStyle) {
            return $false
        }

        # Valider chaque style dÃ©fini
        if ($null -ne $this.LineStyle -and -not $this.LineStyle.Validate()) {
            return $false
        }

        if ($null -ne $this.MarkerStyle -and -not $this.MarkerStyle.Validate()) {
            return $false
        }

        if ($null -ne $this.BorderStyle -and -not $this.BorderStyle.Validate()) {
            return $false
        }

        if ($null -ne $this.ColorStyle -and -not $this.ColorStyle.Validate()) {
            return $false
        }

        return $true
    }

    # MÃ©thode pour cloner le style
    [IExcelStyle] Clone() {
        $Clone = [ExcelCombinedStyle]::new()
        $Clone.Id = [Guid]::NewGuid().ToString()
        $Clone.Name = $this.Name
        $Clone.Description = $this.Description
        $Clone.Category = $this.Category
        $Clone.Tags = $this.Tags.Clone()
        $Clone.IsBuiltIn = $false
        $Clone.CreatedDate = [datetime]::Now
        $Clone.ModifiedDate = [datetime]::Now

        if ($null -ne $this.LineStyle) {
            $Clone.LineStyle = $this.LineStyle.Clone() -as [ExcelLineStyle]
        }

        if ($null -ne $this.MarkerStyle) {
            $Clone.MarkerStyle = $this.MarkerStyle.Clone() -as [ExcelMarkerStyle]
        }

        if ($null -ne $this.BorderStyle) {
            $Clone.BorderStyle = $this.BorderStyle.Clone() -as [ExcelBorderStyle]
        }

        if ($null -ne $this.ColorStyle) {
            $Clone.ColorStyle = $this.ColorStyle.Clone() -as [ExcelColorStyle]
        }

        return $Clone
    }

    # MÃ©thode pour appliquer le style Ã  une sÃ©rie
    [void] ApplyToSeries([object]$Series) {
        if ($null -eq $Series) {
            return
        }

        if ($null -ne $this.LineStyle) {
            $this.LineStyle.ApplyToSeries($Series)
        }

        if ($null -ne $this.MarkerStyle) {
            $this.MarkerStyle.ApplyToSeries($Series)
        }

        if ($null -ne $this.BorderStyle) {
            $this.BorderStyle.ApplyToSeries($Series)
        }

        if ($null -ne $this.ColorStyle) {
            $this.ColorStyle.ApplyToElement($Series)
        }
    }

    # MÃ©thode pour convertir en chaÃ®ne
    [string] ToString() {
        $Components = @()

        if ($null -ne $this.LineStyle) {
            $Components += "Line"
        }

        if ($null -ne $this.MarkerStyle) {
            $Components += "Marker"
        }

        if ($null -ne $this.BorderStyle) {
            $Components += "Border"
        }

        if ($null -ne $this.ColorStyle) {
            $Components += "Color"
        }

        $ComponentsStr = $Components -join ", "

        return "Combined Style: $($this.Name) - Components: $ComponentsStr"
    }
}

#endregion

#region Registre de styles

# Classe pour le registre de styles Excel
class ExcelStyleRegistry {
    # Dictionnaire principal pour stocker tous les styles
    [System.Collections.Generic.Dictionary[string, IExcelStyle]] $Styles

    # Dictionnaires spÃ©cialisÃ©s par type de style
    [System.Collections.Generic.Dictionary[string, ExcelLineStyle]] $LineStyles
    [System.Collections.Generic.Dictionary[string, ExcelMarkerStyle]] $MarkerStyles
    [System.Collections.Generic.Dictionary[string, ExcelBorderStyle]] $BorderStyles
    [System.Collections.Generic.Dictionary[string, ExcelColorStyle]] $ColorStyles
    [System.Collections.Generic.Dictionary[string, ExcelCombinedStyle]] $CombinedStyles

    # Dictionnaire pour les catÃ©gories
    [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]] $Categories

    # Dictionnaire pour les tags
    [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]] $Tags

    # Historique des modifications
    [System.Collections.Generic.Dictionary[string, System.Collections.Generic.Stack[IExcelStyle]]] $History

    # Constructeur
    ExcelStyleRegistry() {
        $this.Styles = [System.Collections.Generic.Dictionary[string, IExcelStyle]]::new()
        $this.LineStyles = [System.Collections.Generic.Dictionary[string, ExcelLineStyle]]::new()
        $this.MarkerStyles = [System.Collections.Generic.Dictionary[string, ExcelMarkerStyle]]::new()
        $this.BorderStyles = [System.Collections.Generic.Dictionary[string, ExcelBorderStyle]]::new()
        $this.ColorStyles = [System.Collections.Generic.Dictionary[string, ExcelColorStyle]]::new()
        $this.CombinedStyles = [System.Collections.Generic.Dictionary[string, ExcelCombinedStyle]]::new()
        $this.Categories = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()
        $this.Tags = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()
        $this.History = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.Stack[IExcelStyle]]]::new()
    }

    # PropriÃ©tÃ© pour obtenir le nombre total de styles
    [int] get_Count() {
        return $this.Styles.Count
    }

    # PropriÃ©tÃ© pour vÃ©rifier si le registre est vide
    [bool] get_IsEmpty() {
        return $this.Styles.Count -eq 0
    }

    # MÃ©thode pour ajouter un style au registre
    [bool] Add([IExcelStyle]$Style) {
        if ($null -eq $Style -or -not $Style.Validate()) {
            return $false
        }

        # VÃ©rifier si l'ID existe dÃ©jÃ 
        if ($this.Styles.ContainsKey($Style.Id)) {
            return $false
        }

        # Ajouter au dictionnaire principal
        $this.Styles.Add($Style.Id, $Style)

        # Ajouter au dictionnaire spÃ©cialisÃ© correspondant
        if ($Style -is [ExcelLineStyle]) {
            $this.LineStyles.Add($Style.Id, $Style)
        } elseif ($Style -is [ExcelMarkerStyle]) {
            $this.MarkerStyles.Add($Style.Id, $Style)
        } elseif ($Style -is [ExcelBorderStyle]) {
            $this.BorderStyles.Add($Style.Id, $Style)
        } elseif ($Style -is [ExcelColorStyle]) {
            $this.ColorStyles.Add($Style.Id, $Style)
        } elseif ($Style -is [ExcelCombinedStyle]) {
            $this.CombinedStyles.Add($Style.Id, $Style)
        }

        # Ajouter Ã  la catÃ©gorie
        if (-not [string]::IsNullOrEmpty($Style.Category)) {
            if (-not $this.Categories.ContainsKey($Style.Category)) {
                $this.Categories.Add($Style.Category, [System.Collections.Generic.List[string]]::new())
            }
            $this.Categories[$Style.Category].Add($Style.Id)
        }

        # Ajouter aux tags
        foreach ($Tag in $Style.Tags) {
            if (-not [string]::IsNullOrEmpty($Tag)) {
                if (-not $this.Tags.ContainsKey($Tag)) {
                    $this.Tags.Add($Tag, [System.Collections.Generic.List[string]]::new())
                }
                $this.Tags[$Tag].Add($Style.Id)
            }
        }

        return $true
    }

    # MÃ©thode pour ajouter plusieurs styles au registre
    [int] AddRange([IExcelStyle[]]$Styles) {
        $AddedCount = 0

        foreach ($Style in $Styles) {
            if ($this.Add($Style)) {
                $AddedCount++
            }
        }

        return $AddedCount
    }

    # MÃ©thode pour supprimer un style du registre par ID
    [bool] Remove([string]$Id) {
        if (-not $this.Styles.ContainsKey($Id)) {
            return $false
        }

        $Style = $this.Styles[$Id]

        # Supprimer des dictionnaires spÃ©cialisÃ©s
        if ($Style -is [ExcelLineStyle]) {
            $this.LineStyles.Remove($Id)
        } elseif ($Style -is [ExcelMarkerStyle]) {
            $this.MarkerStyles.Remove($Id)
        } elseif ($Style -is [ExcelBorderStyle]) {
            $this.BorderStyles.Remove($Id)
        } elseif ($Style -is [ExcelColorStyle]) {
            $this.ColorStyles.Remove($Id)
        } elseif ($Style -is [ExcelCombinedStyle]) {
            $this.CombinedStyles.Remove($Id)
        }

        # Supprimer de la catÃ©gorie
        if (-not [string]::IsNullOrEmpty($Style.Category) -and $this.Categories.ContainsKey($Style.Category)) {
            $this.Categories[$Style.Category].Remove($Id)

            # Supprimer la catÃ©gorie si elle est vide
            if ($this.Categories[$Style.Category].Count -eq 0) {
                $this.Categories.Remove($Style.Category)
            }
        }

        # Supprimer des tags
        foreach ($Tag in $Style.Tags) {
            if (-not [string]::IsNullOrEmpty($Tag) -and $this.Tags.ContainsKey($Tag)) {
                $this.Tags[$Tag].Remove($Id)

                # Supprimer le tag s'il est vide
                if ($this.Tags[$Tag].Count -eq 0) {
                    $this.Tags.Remove($Tag)
                }
            }
        }

        # Supprimer du dictionnaire principal
        return $this.Styles.Remove($Id)
    }

    # MÃ©thode pour supprimer plusieurs styles du registre par ID
    [int] RemoveRange([string[]]$Ids) {
        $RemovedCount = 0

        foreach ($Id in $Ids) {
            if ($this.Remove($Id)) {
                $RemovedCount++
            }
        }

        return $RemovedCount
    }

    # MÃ©thode pour mettre Ã  jour un style existant
    [bool] Update([string]$Id, [IExcelStyle]$Style) {
        if (-not $this.Styles.ContainsKey($Id) -or $null -eq $Style -or -not $Style.Validate()) {
            return $false
        }

        # Sauvegarder l'ancien style dans l'historique
        $OldStyle = $this.Styles[$Id]
        if (-not $this.History.ContainsKey($Id)) {
            $this.History[$Id] = [System.Collections.Generic.Stack[IExcelStyle]]::new()
        }
        $this.History[$Id].Push($OldStyle.Clone())

        # Supprimer l'ancien style
        $this.Remove($Id)

        # Ajouter le nouveau style avec le mÃªme ID
        $Style.Id = $Id
        return $this.Add($Style)
    }

    # MÃ©thode pour vÃ©rifier si un style a un historique de modifications
    [bool] HasHistory([string]$Id) {
        return $this.History.ContainsKey($Id) -and $this.History[$Id].Count -gt 0
    }

    # MÃ©thode pour restaurer la version prÃ©cÃ©dente d'un style
    [bool] RestorePreviousVersion([string]$Id) {
        if (-not $this.HasHistory($Id)) {
            return $false
        }

        # RÃ©cupÃ©rer la version prÃ©cÃ©dente
        $PreviousVersion = $this.History[$Id].Pop()

        # Supprimer la version actuelle
        $this.Remove($Id)

        # Ajouter la version prÃ©cÃ©dente
        $PreviousVersion.Id = $Id
        return $this.Add($PreviousVersion)
    }

    # MÃ©thode pour vÃ©rifier si un style existe par ID
    [bool] Contains([string]$Id) {
        return $this.Styles.ContainsKey($Id)
    }

    # MÃ©thode pour vÃ©rifier si un style existe par nom
    [bool] ContainsByName([string]$Name) {
        foreach ($Style in $this.Styles.Values) {
            if ($Style.Name -eq $Name) {
                return $true
            }
        }
        return $false
    }

    # MÃ©thode pour obtenir un style par ID
    [IExcelStyle] GetById([string]$Id) {
        if ($this.Styles.ContainsKey($Id)) {
            return $this.Styles[$Id]
        }
        return $null
    }

    # MÃ©thode pour obtenir un style par nom
    [IExcelStyle] GetByName([string]$Name) {
        foreach ($Style in $this.Styles.Values) {
            if ($Style.Name -eq $Name) {
                return $Style
            }
        }
        return $null
    }

    # MÃ©thode pour obtenir tous les styles d'une catÃ©gorie
    [IExcelStyle[]] GetByCategory([string]$Category) {
        $Result = @()

        if ($this.Categories.ContainsKey($Category)) {
            foreach ($Id in $this.Categories[$Category]) {
                if ($this.Styles.ContainsKey($Id)) {
                    $Result += $this.Styles[$Id]
                }
            }
        }

        return $Result
    }

    # MÃ©thode pour obtenir tous les styles avec un tag spÃ©cifique
    [IExcelStyle[]] GetByTag([string]$Tag) {
        $Result = @()

        if ($this.Tags.ContainsKey($Tag)) {
            foreach ($Id in $this.Tags[$Tag]) {
                if ($this.Styles.ContainsKey($Id)) {
                    $Result += $this.Styles[$Id]
                }
            }
        }

        return $Result
    }

    # MÃ©thode pour obtenir tous les styles d'un type spÃ©cifique
    [IExcelStyle[]] GetByType([string]$TypeName) {
        $Result = @()

        switch ($TypeName.ToLower()) {
            "line" {
                $Result = $this.LineStyles.Values
            }
            "marker" {
                $Result = $this.MarkerStyles.Values
            }
            "border" {
                $Result = $this.BorderStyles.Values
            }
            "color" {
                $Result = $this.ColorStyles.Values
            }
            "combined" {
                $Result = $this.CombinedStyles.Values
            }
            default {
                $Result = $this.Styles.Values
            }
        }

        return $Result
    }

    # MÃ©thode pour obtenir toutes les catÃ©gories
    [string[]] GetCategories() {
        return $this.Categories.Keys
    }

    # MÃ©thode pour obtenir tous les tags
    [string[]] GetTags() {
        return $this.Tags.Keys
    }

    # MÃ©thode pour vider le registre
    [void] Clear() {
        $this.Styles.Clear()
        $this.LineStyles.Clear()
        $this.MarkerStyles.Clear()
        $this.BorderStyles.Clear()
        $this.ColorStyles.Clear()
        $this.CombinedStyles.Clear()
        $this.Categories.Clear()
        $this.Tags.Clear()
        $this.History.Clear()
    }

    # MÃ©thode pour obtenir tous les styles
    [IExcelStyle[]] GetAll() {
        return $this.Styles.Values
    }

    # MÃ©thode pour rechercher des styles par critÃ¨res
    [IExcelStyle[]] Search([hashtable]$Criteria) {
        $Result = @()

        foreach ($Style in $this.Styles.Values) {
            $Match = $true

            foreach ($Key in $Criteria.Keys) {
                $Value = $Criteria[$Key]

                switch ($Key.ToLower()) {
                    "name" {
                        if ($Style.Name -notlike $Value) {
                            $Match = $false
                        }
                    }
                    "description" {
                        if ($Style.Description -notlike $Value) {
                            $Match = $false
                        }
                    }
                    "category" {
                        if ($Style.Category -ne $Value) {
                            $Match = $false
                        }
                    }
                    "tag" {
                        if (-not $Style.HasTag($Value)) {
                            $Match = $false
                        }
                    }
                    "type" {
                        $TypeMatch = $false
                        switch ($Value.ToLower()) {
                            "line" { $TypeMatch = $Style -is [ExcelLineStyle] }
                            "marker" { $TypeMatch = $Style -is [ExcelMarkerStyle] }
                            "border" { $TypeMatch = $Style -is [ExcelBorderStyle] }
                            "color" { $TypeMatch = $Style -is [ExcelColorStyle] }
                            "combined" { $TypeMatch = $Style -is [ExcelCombinedStyle] }
                        }
                        if (-not $TypeMatch) {
                            $Match = $false
                        }
                    }
                    "isbuiltin" {
                        if ($Style.IsBuiltIn -ne $Value) {
                            $Match = $false
                        }
                    }
                }

                if (-not $Match) {
                    break
                }
            }

            if ($Match) {
                $Result += $Style
            }
        }

        return $Result
    }

    # MÃ©thode pour importer des styles depuis un autre registre
    [int] Import([ExcelStyleRegistry]$Registry) {
        if ($null -eq $Registry) {
            return 0
        }

        return $this.AddRange($Registry.GetAll())
    }
}

#endregion

#region Singleton pour le registre de styles

# Classe singleton pour le registre de styles Excel
class ExcelStyleRegistrySingleton {
    static [ExcelStyleRegistry] $Instance
    static [bool] $Initialized = $false

    # Constructeur privÃ©
    hidden ExcelStyleRegistrySingleton() {}

    # MÃ©thode pour obtenir l'instance unique
    static [ExcelStyleRegistry] GetInstance() {
        if (-not [ExcelStyleRegistrySingleton]::Initialized) {
            [ExcelStyleRegistrySingleton]::Instance = [ExcelStyleRegistry]::new()
            [ExcelStyleRegistrySingleton]::Initialized = $true
        }

        return [ExcelStyleRegistrySingleton]::Instance
    }

    # MÃ©thode pour rÃ©initialiser l'instance
    static [void] Reset() {
        if ([ExcelStyleRegistrySingleton]::Initialized) {
            [ExcelStyleRegistrySingleton]::Instance.Clear()
        }
    }

    # MÃ©thode pour crÃ©er une nouvelle instance isolÃ©e
    static [ExcelStyleRegistry] CreateIsolatedInstance() {
        return [ExcelStyleRegistry]::new()
    }
}

#endregion

#region Fonctions d'accÃ¨s au registre de styles

<#
.SYNOPSIS
    Obtient l'instance unique du registre de styles Excel.
.DESCRIPTION
    Cette fonction retourne l'instance unique du registre de styles Excel,
    en utilisant le pattern singleton.
.EXAMPLE
    $Registry = Get-ExcelStyleRegistry
.OUTPUTS
    ExcelStyleRegistry - L'instance unique du registre de styles Excel.
#>
function Get-ExcelStyleRegistry {
    [CmdletBinding()]
    param ()

    return [ExcelStyleRegistrySingleton]::GetInstance()
}

<#
.SYNOPSIS
    CrÃ©e une nouvelle instance isolÃ©e du registre de styles Excel.
.DESCRIPTION
    Cette fonction crÃ©e une nouvelle instance isolÃ©e du registre de styles Excel,
    indÃ©pendante de l'instance singleton.
.EXAMPLE
    $IsolatedRegistry = New-ExcelStyleRegistry
.OUTPUTS
    ExcelStyleRegistry - Une nouvelle instance du registre de styles Excel.
#>
function New-ExcelStyleRegistry {
    [CmdletBinding()]
    param ()

    return [ExcelStyleRegistrySingleton]::CreateIsolatedInstance()
}

<#
.SYNOPSIS
    RÃ©initialise le registre de styles Excel.
.DESCRIPTION
    Cette fonction vide complÃ¨tement le registre de styles Excel.
.EXAMPLE
    Reset-ExcelStyleRegistry
#>
function Reset-ExcelStyleRegistry {
    [CmdletBinding()]
    param ()

    [ExcelStyleRegistrySingleton]::Reset()
}

<#
.SYNOPSIS
    Ajoute un style au registre de styles Excel.
.DESCRIPTION
    Cette fonction ajoute un style au registre de styles Excel.
.PARAMETER Style
    Le style Ã  ajouter au registre.
.EXAMPLE
    $Style = [ExcelLineStyle]::new()
    Add-ExcelStyle -Style $Style
.OUTPUTS
    System.Boolean - True si l'ajout a rÃ©ussi, False sinon.
#>
function Add-ExcelStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [IExcelStyle]$Style
    )

    process {
        $Registry = Get-ExcelStyleRegistry
        return $Registry.Add($Style)
    }
}

<#
.SYNOPSIS
    Supprime un style du registre de styles Excel.
.DESCRIPTION
    Cette fonction supprime un style du registre de styles Excel.
.PARAMETER Id
    L'ID du style Ã  supprimer.
.EXAMPLE
    Remove-ExcelStyle -Id "12345678-1234-1234-1234-123456789012"
.OUTPUTS
    System.Boolean - True si la suppression a rÃ©ussi, False sinon.
#>
function Remove-ExcelStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Id
    )

    process {
        $Registry = Get-ExcelStyleRegistry
        return $Registry.Remove($Id)
    }
}

<#
.SYNOPSIS
    Obtient un style du registre de styles Excel par son ID.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re un style du registre de styles Excel par son ID.
.PARAMETER Id
    L'ID du style Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $Style = Get-ExcelStyleById -Id "12345678-1234-1234-1234-123456789012"
.OUTPUTS
    IExcelStyle - Le style correspondant Ã  l'ID spÃ©cifiÃ©, ou $null si aucun style n'est trouvÃ©.
#>
function Get-ExcelStyleById {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Id
    )

    process {
        $Registry = Get-ExcelStyleRegistry
        return $Registry.GetById($Id)
    }
}

<#
.SYNOPSIS
    Obtient un style du registre de styles Excel par son nom.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re un style du registre de styles Excel par son nom.
.PARAMETER Name
    Le nom du style Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $Style = Get-ExcelStyleByName -Name "Mon Style"
.OUTPUTS
    IExcelStyle - Le style correspondant au nom spÃ©cifiÃ©, ou $null si aucun style n'est trouvÃ©.
#>
function Get-ExcelStyleByName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name
    )

    process {
        $Registry = Get-ExcelStyleRegistry
        return $Registry.GetByName($Name)
    }
}

<#
.SYNOPSIS
    Obtient tous les styles d'une catÃ©gorie spÃ©cifique.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re tous les styles d'une catÃ©gorie spÃ©cifique du registre de styles Excel.
.PARAMETER Category
    La catÃ©gorie des styles Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $Styles = Get-ExcelStyleByCategory -Category "Lines"
.OUTPUTS
    IExcelStyle[] - Les styles correspondant Ã  la catÃ©gorie spÃ©cifiÃ©e.
#>
function Get-ExcelStyleByCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Category
    )

    process {
        $Registry = Get-ExcelStyleRegistry
        return $Registry.GetByCategory($Category)
    }
}

<#
.SYNOPSIS
    Obtient tous les styles avec un tag spÃ©cifique.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re tous les styles avec un tag spÃ©cifique du registre de styles Excel.
.PARAMETER Tag
    Le tag des styles Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $Styles = Get-ExcelStyleByTag -Tag "Business"
.OUTPUTS
    IExcelStyle[] - Les styles correspondant au tag spÃ©cifiÃ©.
#>
function Get-ExcelStyleByTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Tag
    )

    process {
        $Registry = Get-ExcelStyleRegistry
        return $Registry.GetByTag($Tag)
    }
}

<#
.SYNOPSIS
    Obtient tous les styles d'un type spÃ©cifique.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re tous les styles d'un type spÃ©cifique du registre de styles Excel.
.PARAMETER Type
    Le type des styles Ã  rÃ©cupÃ©rer (Line, Marker, Border, Color, Combined).
.EXAMPLE
    $Styles = Get-ExcelStyleByType -Type "Line"
.OUTPUTS
    IExcelStyle[] - Les styles correspondant au type spÃ©cifiÃ©.
#>
function Get-ExcelStyleByType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("Line", "Marker", "Border", "Color", "Combined")]
        [string]$Type
    )

    process {
        $Registry = Get-ExcelStyleRegistry
        return $Registry.GetByType($Type)
    }
}

<#
.SYNOPSIS
    Recherche des styles selon des critÃ¨res spÃ©cifiques.
.DESCRIPTION
    Cette fonction recherche des styles selon des critÃ¨res spÃ©cifiques dans le registre de styles Excel.
.PARAMETER Criteria
    Les critÃ¨res de recherche sous forme de hashtable.
.EXAMPLE
    $Criteria = @{
        Name = "*Line*"
        Category = "Lines"
        Tag = "Business"
        Type = "Line"
        IsBuiltIn = $true
    }
    $Styles = Search-ExcelStyle -Criteria $Criteria
.OUTPUTS
    IExcelStyle[] - Les styles correspondant aux critÃ¨res spÃ©cifiÃ©s.
#>
function Search-ExcelStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria
    )

    $Registry = Get-ExcelStyleRegistry
    return $Registry.Search($Criteria)
}

<#
.SYNOPSIS
    Obtient toutes les catÃ©gories de styles disponibles.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re toutes les catÃ©gories de styles disponibles dans le registre de styles Excel.
.EXAMPLE
    $Categories = Get-ExcelStyleCategory
.OUTPUTS
    string[] - Les catÃ©gories de styles disponibles.
#>
function Get-ExcelStyleCategory {
    [CmdletBinding()]
    param ()

    $Registry = Get-ExcelStyleRegistry
    return $Registry.GetCategories()
}

<#
.SYNOPSIS
    Obtient tous les tags de styles disponibles.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re tous les tags de styles disponibles dans le registre de styles Excel.
.EXAMPLE
    $Tags = Get-ExcelStyleTag
.OUTPUTS
    string[] - Les tags de styles disponibles.
#>
function Get-ExcelStyleTag {
    [CmdletBinding()]
    param ()

    $Registry = Get-ExcelStyleRegistry
    return $Registry.GetTags()
}

<#
.SYNOPSIS
    Obtient tous les styles disponibles.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re tous les styles disponibles dans le registre de styles Excel.
.EXAMPLE
    $AllStyles = Get-ExcelStyle
.OUTPUTS
    IExcelStyle[] - Tous les styles disponibles.
#>
function Get-ExcelStyle {
    [CmdletBinding()]
    param ()

    $Registry = Get-ExcelStyleRegistry
    return $Registry.GetAll()
}

<#
.SYNOPSIS
    Met Ã  jour un style existant dans le registre de styles Excel.
.DESCRIPTION
    Cette fonction met Ã  jour un style existant dans le registre de styles Excel.
.PARAMETER Id
    L'ID du style Ã  mettre Ã  jour.
.PARAMETER Style
    Le nouveau style Ã  utiliser pour la mise Ã  jour.
.EXAMPLE
    $NewStyle = [ExcelLineStyle]::new()
    Update-ExcelStyle -Id "12345678-1234-1234-1234-123456789012" -Style $NewStyle
.OUTPUTS
    System.Boolean - True si la mise Ã  jour a rÃ©ussi, False sinon.
#>
function Update-ExcelStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [IExcelStyle]$Style
    )

    $Registry = Get-ExcelStyleRegistry
    return $Registry.Update($Id, $Style)
}

<#
.SYNOPSIS
    Applique un style Ã  une sÃ©rie de graphique Excel.
.DESCRIPTION
    Cette fonction applique un style Ã  une sÃ©rie de graphique Excel.
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
.PARAMETER StyleId
    L'ID du style Ã  appliquer.
.PARAMETER StyleName
    Le nom du style Ã  appliquer (alternative Ã  StyleId).
.EXAMPLE
    Set-ExcelChartSeriesStyle -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -SeriesIndex 0 -StyleId "12345678-1234-1234-1234-123456789012"
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesStyle {
    [CmdletBinding(DefaultParameterSetName = "ById")]
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

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]$StyleId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string]$StyleName
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

        # Obtenir le style
        $Registry = Get-ExcelStyleRegistry
        $Style = $null

        if ($PSCmdlet.ParameterSetName -eq "ById") {
            $Style = $Registry.GetById($StyleId)
        } else {
            $Style = $Registry.GetByName($StyleName)
        }

        if ($null -eq $Style) {
            throw "Style non trouvÃ©: $($PSCmdlet.ParameterSetName -eq 'ById' ? $StyleId : $StyleName)"
        }

        # Appliquer le style Ã  la sÃ©rie
        if ($Style -is [ExcelLineStyle]) {
            $Style.ApplyToSeries($Series)
        } elseif ($Style -is [ExcelMarkerStyle]) {
            $Style.ApplyToSeries($Series)
        } elseif ($Style -is [ExcelBorderStyle]) {
            $Style.ApplyToSeries($Series)
        } elseif ($Style -is [ExcelColorStyle]) {
            $Style.ApplyToElement($Series)
        } elseif ($Style -is [ExcelCombinedStyle]) {
            $Style.ApplyToSeries($Series)
        } else {
            throw "Type de style non supportÃ©: $($Style.GetType().Name)"
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $true
    } catch {
        Write-Error "Erreur lors de l'application du style: $_"
        return $false
    }
}

#endregion

# Exporter les classes et fonctions
Export-ModuleMember -Function Get-ExcelStyleRegistry, New-ExcelStyleRegistry, Reset-ExcelStyleRegistry, Add-ExcelStyle, Remove-ExcelStyle, Get-ExcelStyleById, Get-ExcelStyleByName, Get-ExcelStyleByCategory, Get-ExcelStyleByTag, Get-ExcelStyleByType, Search-ExcelStyle, Get-ExcelStyleCategory, Get-ExcelStyleTag, Get-ExcelStyle, Update-ExcelStyle, Set-ExcelChartSeriesStyle -Variable *
