<#
.SYNOPSIS
    Module d'export Excel pour les rapports automatiques.
.DESCRIPTION
    Ce module fournit une couche d'abstraction pour la génération de fichiers Excel
    en utilisant le module ImportExcel.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-04-23
#>

# Vérifier si le module ImportExcel est installé
$InstallerPath = Join-Path -Path $PSScriptRoot -ChildPath "install_excel_module.ps1"
if (Test-Path -Path $InstallerPath) {
    & $InstallerPath -RequiredVersion "5.4.5"
} else {
    if (-not (Get-Module -Name "ImportExcel" -ListAvailable)) {
        throw "Module ImportExcel non installé et script d'installation non trouvé"
    }
}

# Importer le module ImportExcel
Import-Module -Name "ImportExcel" -ErrorAction Stop

#region Exceptions

# Classe ExcelException
# Exception de base pour toutes les erreurs liées à Excel
class ExcelException : System.Exception {
    ExcelException([string]$Message) : base($Message) {}
    ExcelException([string]$Message, [System.Exception]$InnerException) : base($Message, $InnerException) {}
}

# Classe ExcelWorkbookException
# Exception liée aux opérations sur les classeurs
class ExcelWorkbookException : ExcelException {
    ExcelWorkbookException([string]$Message) : base($Message) {}
    ExcelWorkbookException([string]$Message, [System.Exception]$InnerException) : base($Message, $InnerException) {}
}

# Classe ExcelWorksheetException
# Exception liée aux opérations sur les feuilles de calcul
class ExcelWorksheetException : ExcelException {
    ExcelWorksheetException([string]$Message) : base($Message) {}
    ExcelWorksheetException([string]$Message, [System.Exception]$InnerException) : base($Message, $InnerException) {}
}

# Classe ExcelDataException
# Exception liée aux opérations sur les données
class ExcelDataException : ExcelException {
    ExcelDataException([string]$Message) : base($Message) {}
    ExcelDataException([string]$Message, [System.Exception]$InnerException) : base($Message, $InnerException) {}
}

#endregion

#region Configuration

# Classe ExcelConfiguration
# Configuration pour les exporteurs Excel
class ExcelConfiguration {
    # Propriétés statiques
    static [hashtable] $DefaultStyles = @{
        Header   = @{
            Bold                = $true
            BackgroundColor     = "#4472C4"
            ForegroundColor     = "#FFFFFF"
            HorizontalAlignment = "Center"
            VerticalAlignment   = "Center"
            BorderAround        = $true
            FontSize            = 12
        }
        Data     = @{
            BorderAround        = $true
            HorizontalAlignment = "Left"
            VerticalAlignment   = "Center"
            FontSize            = 11
        }
        Total    = @{
            Bold            = $true
            BackgroundColor = "#D9E1F2"
            BorderAround    = $true
            FontSize        = 11
        }
        Title    = @{
            Bold                = $true
            FontSize            = 14
            HorizontalAlignment = "Center"
            VerticalAlignment   = "Center"
            MergeCells          = $true
        }
        Subtitle = @{
            Bold                = $true
            FontSize            = 12
            HorizontalAlignment = "Center"
            VerticalAlignment   = "Center"
            MergeCells          = $true
        }
    }

    static [hashtable] $ChartOptions = @{
        Line   = @{
            Title          = "Graphique linéaire"
            ShowLegend     = $true
            ShowDataLabels = $false
            Width          = 600
            Height         = 400
        }
        Bar    = @{
            Title          = "Graphique à barres"
            ShowLegend     = $true
            ShowDataLabels = $true
            Width          = 600
            Height         = 400
        }
        Pie    = @{
            Title          = "Graphique circulaire"
            ShowLegend     = $true
            ShowDataLabels = $true
            Width          = 500
            Height         = 500
        }
        Column = @{
            Title          = "Graphique à colonnes"
            ShowLegend     = $true
            ShowDataLabels = $true
            Width          = 600
            Height         = 400
        }
    }

    static [hashtable] $ExportOptions = @{
        AutoSize              = $true
        AutoFilter            = $true
        FreezeTopRow          = $true
        BoldTopRow            = $true
        TableStyle            = "Medium2"
        ShowTotal             = $false
        ConditionalFormatting = $false
    }

    # Méthode statique pour configurer les styles
    static [void] ConfigureStyles([hashtable]$Styles) {
        foreach ($Key in $Styles.Keys) {
            [ExcelConfiguration]::DefaultStyles[$Key] = $Styles[$Key]
        }
    }

    # Méthode statique pour configurer les options de graphique
    static [void] ConfigureChartOptions([hashtable]$Options) {
        foreach ($Key in $Options.Keys) {
            [ExcelConfiguration]::ChartOptions[$Key] = $Options[$Key]
        }
    }

    # Méthode statique pour configurer les options d'export
    static [void] ConfigureExportOptions([hashtable]$Options) {
        foreach ($Key in $Options.Keys) {
            [ExcelConfiguration]::ExportOptions[$Key] = $Options[$Key]
        }
    }
}

#endregion

#region ExcelExporter

# Classe ExcelExporter
# Implémentation de l'interface d'exportation Excel
class ExcelExporter {
    # Propriétés privées
    hidden [hashtable] $_workbooks = @{}
    hidden [hashtable] $_worksheets = @{}
    hidden [string] $_lastError = ""
    hidden [hashtable] $_formatCache = @{}
    hidden [hashtable] $_typeConverters = @{}

    # Constructeur
    ExcelExporter() {
        # Vérifier si le module ImportExcel est chargé
        if (-not (Get-Module -Name "ImportExcel")) {
            try {
                Import-Module -Name "ImportExcel" -ErrorAction Stop
            } catch {
                $this._lastError = "Erreur lors du chargement du module ImportExcel: $_"
                throw [ExcelException]::new($this._lastError)
            }
        }

        # Initialiser les convertisseurs de types
        $this.InitializeTypeConverters()
    }

    # Méthode pour initialiser les convertisseurs de types
    hidden [void] InitializeTypeConverters() {
        # Convertisseur pour les types numériques
        $this._typeConverters["Numeric"] = {
            param($Value, $Options)

            # Déterminer le format numérique
            $Format = if ($Options -and $Options.ContainsKey("Format")) { $Options.Format } else { "General" }

            # Convertir la valeur en nombre
            try {
                $NumericValue = [double]$Value
                return @{
                    Value  = $NumericValue
                    Format = $Format
                    Type   = "Numeric"
                }
            } catch {
                # Si la conversion échoue, retourner la valeur d'origine
                return @{
                    Value  = $Value
                    Format = "General"
                    Type   = "Text"
                }
            }
        }

        # Convertisseur pour les chaînes de caractères
        $this._typeConverters["Text"] = {
            param($Value, $Options)

            # Déterminer le format de texte
            $Format = if ($Options -and $Options.ContainsKey("Format")) { $Options.Format } else { "@" }

            # Convertir la valeur en chaîne
            $TextValue = if ($null -eq $Value) { "" } else { $Value.ToString() }

            return @{
                Value  = $TextValue
                Format = $Format
                Type   = "Text"
            }
        }

        # Convertisseur pour les valeurs booléennes
        $this._typeConverters["Boolean"] = {
            param($Value, $Options)

            # Déterminer le format booléen
            $Format = if ($Options -and $Options.ContainsKey("Format")) { $Options.Format } else { "Yes/No" }

            # Convertir la valeur en booléen
            try {
                $BoolValue = [bool]$Value
                return @{
                    Value  = $BoolValue
                    Format = $Format
                    Type   = "Boolean"
                }
            } catch {
                # Si la conversion échoue, retourner la valeur d'origine
                return @{
                    Value  = $Value
                    Format = "General"
                    Type   = "Text"
                }
            }
        }

        # Convertisseur pour les dates et heures
        $this._typeConverters["DateTime"] = {
            param($Value, $Options)

            # Déterminer le format de date
            $Format = if ($Options -and $Options.ContainsKey("Format")) { $Options.Format } else { "yyyy-MM-dd HH:mm:ss" }

            # Convertir la valeur en date
            try {
                $DateValue = if ($Value -is [DateTime]) {
                    $Value
                } else {
                    [DateTime]::Parse($Value)
                }

                return @{
                    Value  = $DateValue
                    Format = $Format
                    Type   = "DateTime"
                }
            } catch {
                # Si la conversion échoue, retourner la valeur d'origine
                return @{
                    Value  = $Value
                    Format = "General"
                    Type   = "Text"
                }
            }
        }

        # Convertisseur pour les valeurs nulles ou vides
        $this._typeConverters["Null"] = {
            param($Value, $Options)

            return @{
                Value  = [string]::Empty
                Format = "General"
                Type   = "Text"
            }
        }
    }

    #region Méthodes de création de classeurs et feuilles

    <#
    .SYNOPSIS
        Crée un nouveau classeur Excel.
    .DESCRIPTION
        Cette méthode crée un nouveau classeur Excel et retourne un identifiant unique.
    .PARAMETER Path
        Chemin où le classeur sera sauvegardé (optionnel).
    .EXAMPLE
        $WorkbookId = $Exporter.CreateWorkbook("C:\Temp\Rapport.xlsx")
    .OUTPUTS
        System.String - Identifiant unique du classeur.
    #>
    [string] CreateWorkbook([string]$Path = "") {
        try {
            # Créer un package Excel
            $ExcelPackage = New-Object OfficeOpenXml.ExcelPackage

            # Si un chemin est spécifié, associer le package à ce fichier
            if (-not [string]::IsNullOrEmpty($Path)) {
                # Vérifier si le répertoire parent existe
                $Directory = Split-Path -Parent $Path
                if (-not [string]::IsNullOrEmpty($Directory) -and -not (Test-Path -Path $Directory)) {
                    New-Item -Path $Directory -ItemType Directory -Force | Out-Null
                }

                $FileInfo = New-Object System.IO.FileInfo($Path)
                $ExcelPackage = New-Object OfficeOpenXml.ExcelPackage($FileInfo)
            }

            # Générer un ID unique pour le classeur
            $WorkbookId = [Guid]::NewGuid().ToString()

            # Stocker le classeur dans la collection
            $this._workbooks[$WorkbookId] = @{
                Package    = $ExcelPackage
                Path       = $Path
                Worksheets = @{}
            }

            return $WorkbookId
        } catch {
            $this._lastError = "Erreur lors de la création du classeur: $_"
            throw [ExcelWorkbookException]::new($this._lastError, $_.Exception)
        }
    }

    <#
    .SYNOPSIS
        Ajoute une feuille de calcul à un classeur Excel.
    .DESCRIPTION
        Cette méthode ajoute une feuille de calcul à un classeur Excel et retourne un identifiant unique.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .PARAMETER Name
        Nom de la feuille de calcul.
    .EXAMPLE
        $WorksheetId = $Exporter.AddWorksheet($WorkbookId, "Données")
    .OUTPUTS
        System.String - Identifiant unique de la feuille de calcul.
    #>
    [string] AddWorksheet([string]$WorkbookId, [string]$Name) {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]
            $ExcelPackage = $Workbook.Package

            # Vérifier si une feuille avec ce nom existe déjà
            $Worksheet = $ExcelPackage.Workbook.Worksheets | Where-Object { $_.Name -eq $Name }

            if ($null -eq $Worksheet) {
                # Créer une nouvelle feuille
                $Worksheet = $ExcelPackage.Workbook.Worksheets.Add($Name)
            }

            # Générer un ID unique pour la feuille
            $WorksheetId = [Guid]::NewGuid().ToString()

            # Stocker la feuille dans la collection
            $Workbook.Worksheets[$WorksheetId] = $Worksheet

            return $WorksheetId
        } catch {
            $this._lastError = "Erreur lors de l'ajout de la feuille de calcul: $_"
            throw [ExcelWorksheetException]::new($this._lastError, $_.Exception)
        }
    }

    <#
    .SYNOPSIS
        Obtient une feuille de calcul existante dans un classeur Excel.
    .DESCRIPTION
        Cette méthode récupère une feuille de calcul existante dans un classeur Excel et retourne un identifiant unique.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .PARAMETER Name
        Nom de la feuille de calcul.
    .EXAMPLE
        $WorksheetId = $Exporter.GetWorksheet($WorkbookId, "Données")
    .OUTPUTS
        System.String - Identifiant unique de la feuille de calcul.
    #>
    [string] GetWorksheet([string]$WorkbookId, [string]$Name) {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]
            $ExcelPackage = $Workbook.Package

            # Vérifier si une feuille avec ce nom existe
            $Worksheet = $ExcelPackage.Workbook.Worksheets | Where-Object { $_.Name -eq $Name }

            if ($null -eq $Worksheet) {
                throw "Feuille de calcul non trouvée: $Name"
            }

            # Vérifier si cette feuille est déjà dans la collection
            foreach ($Key in $Workbook.Worksheets.Keys) {
                if ($Workbook.Worksheets[$Key].Name -eq $Name) {
                    return $Key
                }
            }

            # Si la feuille n'est pas dans la collection, l'ajouter
            $WorksheetId = [Guid]::NewGuid().ToString()
            $Workbook.Worksheets[$WorksheetId] = $Worksheet

            return $WorksheetId
        } catch {
            $this._lastError = "Erreur lors de la récupération de la feuille de calcul: $_"
            throw [ExcelWorksheetException]::new($this._lastError, $_.Exception)
        }
    }

    <#
    .SYNOPSIS
        Liste toutes les feuilles de calcul d'un classeur Excel.
    .DESCRIPTION
        Cette méthode liste toutes les feuilles de calcul d'un classeur Excel.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .EXAMPLE
        $Worksheets = $Exporter.ListWorksheets($WorkbookId)
    .OUTPUTS
        System.Collections.Hashtable - Table de hachage des feuilles de calcul (ID -> Nom).
    #>
    [hashtable] ListWorksheets([string]$WorkbookId) {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]
            $ExcelPackage = $Workbook.Package

            # Créer une table de hachage des feuilles de calcul
            $Worksheets = @{}

            foreach ($Worksheet in $ExcelPackage.Workbook.Worksheets) {
                # Vérifier si cette feuille est déjà dans la collection
                $Found = $false

                foreach ($Key in $Workbook.Worksheets.Keys) {
                    if ($Workbook.Worksheets[$Key].Name -eq $Worksheet.Name) {
                        $Worksheets[$Key] = $Worksheet.Name
                        $Found = $true
                        break
                    }
                }

                # Si la feuille n'est pas dans la collection, l'ajouter
                if (-not $Found) {
                    $WorksheetId = [Guid]::NewGuid().ToString()
                    $Workbook.Worksheets[$WorksheetId] = $Worksheet
                    $Worksheets[$WorksheetId] = $Worksheet.Name
                }
            }

            return $Worksheets
        } catch {
            $this._lastError = "Erreur lors de la liste des feuilles de calcul: $_"
            throw [ExcelWorksheetException]::new($this._lastError, $_.Exception)
        }
    }

    #endregion

    #region Méthodes de sauvegarde et fermeture

    <#
    .SYNOPSIS
        Sauvegarde un classeur Excel.
    .DESCRIPTION
        Cette méthode sauvegarde un classeur Excel.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .PARAMETER Path
        Chemin où le classeur sera sauvegardé (optionnel).
    .EXAMPLE
        $Path = $Exporter.SaveWorkbook($WorkbookId, "C:\Temp\Rapport.xlsx")
    .OUTPUTS
        System.String - Chemin du fichier sauvegardé.
    #>
    [string] SaveWorkbook([string]$WorkbookId, [string]$Path = "") {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]
            $ExcelPackage = $Workbook.Package

            # Si un chemin est spécifié, sauvegarder à cet emplacement
            if (-not [string]::IsNullOrEmpty($Path)) {
                # Vérifier si le répertoire parent existe
                $Directory = Split-Path -Parent $Path
                if (-not [string]::IsNullOrEmpty($Directory) -and -not (Test-Path -Path $Directory)) {
                    New-Item -Path $Directory -ItemType Directory -Force | Out-Null
                }

                # Sauvegarder le classeur
                $ExcelPackage.SaveAs((New-Object System.IO.FileInfo($Path)))
                $Workbook.Path = $Path
                return $Path
            } else {
                # Si aucun chemin n'est spécifié, utiliser le chemin existant
                if ([string]::IsNullOrEmpty($Workbook.Path)) {
                    throw "Aucun chemin spécifié pour la sauvegarde du classeur"
                }

                # Sauvegarder le classeur
                $ExcelPackage.Save()
                return $Workbook.Path
            }
        } catch {
            $this._lastError = "Erreur lors de la sauvegarde du classeur: $_"
            throw [ExcelWorkbookException]::new($this._lastError, $_.Exception)
        }
    }

    <#
    .SYNOPSIS
        Ferme un classeur Excel et libère les ressources.
    .DESCRIPTION
        Cette méthode ferme un classeur Excel et libère les ressources.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .EXAMPLE
        $Exporter.CloseWorkbook($WorkbookId)
    .OUTPUTS
        None
    #>
    [void] CloseWorkbook([string]$WorkbookId) {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]
            $ExcelPackage = $Workbook.Package

            # Fermer le classeur et libérer les ressources
            $ExcelPackage.Dispose()

            # Supprimer le classeur de la collection
            $this._workbooks.Remove($WorkbookId)
        } catch {
            $this._lastError = "Erreur lors de la fermeture du classeur: $_"
            throw [ExcelWorkbookException]::new($this._lastError, $_.Exception)
        }
    }

    <#
    .SYNOPSIS
        Ferme tous les classeurs Excel et libère les ressources.
    .DESCRIPTION
        Cette méthode ferme tous les classeurs Excel et libère les ressources.
    .EXAMPLE
        $Exporter.CloseAllWorkbooks()
    .OUTPUTS
        None
    #>
    [void] CloseAllWorkbooks() {
        try {
            # Fermer tous les classeurs
            foreach ($WorkbookId in @($this._workbooks.Keys)) {
                $this.CloseWorkbook($WorkbookId)
            }
        } catch {
            $this._lastError = "Erreur lors de la fermeture de tous les classeurs: $_"
            throw [ExcelWorkbookException]::new($this._lastError, $_.Exception)
        }
    }

    #endregion

    #region Méthodes de manipulation des données

    <#
    .SYNOPSIS
        Ajoute des données à une feuille de calcul.
    .DESCRIPTION
        Cette méthode ajoute des données à une feuille de calcul avec conversion automatique des types.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .PARAMETER WorksheetId
        Identifiant de la feuille de calcul.
    .PARAMETER Data
        Données à ajouter (peut être un objet, un tableau ou une collection).
    .PARAMETER StartRow
        Ligne de départ (par défaut: 1).
    .PARAMETER StartColumn
        Colonne de départ (par défaut: 1).
    .PARAMETER IncludeHeaders
        Indique si les en-têtes doivent être inclus (par défaut: $true).
    .PARAMETER AutoFormat
        Indique si le formatage automatique doit être appliqué (par défaut: $true).
    .EXAMPLE
        $Exporter.AddData($WorkbookId, $WorksheetId, $Data, 1, 1, $true, $true)
    .OUTPUTS
        None
    #>
    [void] AddData(
        [string]$WorkbookId,
        [string]$WorksheetId,
        $Data,
        [int]$StartRow = 1,
        [int]$StartColumn = 1,
        [bool]$IncludeHeaders = $true,
        [bool]$AutoFormat = $true
    ) {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]

            # Vérifier si la feuille existe
            if (-not $Workbook.Worksheets.ContainsKey($WorksheetId)) {
                throw "Feuille de calcul non trouvée: $WorksheetId"
            }

            $Worksheet = $Workbook.Worksheets[$WorksheetId]
            $Row = $StartRow

            # Si les données sont nulles, ne rien faire
            if ($null -eq $Data) {
                return
            }

            # Si les données sont un tableau d'objets
            if ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [string]) {
                # Obtenir le premier élément pour déterminer les propriétés
                $FirstItem = $Data | Select-Object -First 1

                # Si le premier élément est un objet avec des propriétés
                if ($FirstItem -is [PSObject] -and $IncludeHeaders) {
                    $Properties = $FirstItem.PSObject.Properties.Name
                    $Column = $StartColumn

                    # Ajouter les en-têtes
                    foreach ($Property in $Properties) {
                        $Worksheet.Cells[$Row, $Column].Value = $Property

                        # Appliquer le style d'en-tête si le formatage automatique est activé
                        if ($AutoFormat) {
                            $this.ApplyHeaderStyle($Worksheet, $Row, $Column)
                        }

                        $Column++
                    }

                    $Row++
                }

                # Ajouter les données
                foreach ($Item in $Data) {
                    $Column = $StartColumn

                    if ($Item -is [PSObject] -and $FirstItem -is [PSObject]) {
                        foreach ($Property in $Properties) {
                            $Value = $Item.$Property
                            $this.AddCellValue($Worksheet, $Row, $Column, $Value, $AutoFormat)
                            $Column++
                        }
                    } elseif ($Item -is [System.Collections.IEnumerable] -and $Item -isnot [string]) {
                        foreach ($Value in $Item) {
                            $this.AddCellValue($Worksheet, $Row, $Column, $Value, $AutoFormat)
                            $Column++
                        }
                    } else {
                        $this.AddCellValue($Worksheet, $Row, $Column, $Item, $AutoFormat)
                    }

                    $Row++
                }
            } else {
                # Si les données sont une valeur simple
                $this.AddCellValue($Worksheet, $Row, $StartColumn, $Data, $AutoFormat)
            }
        } catch {
            $this._lastError = "Erreur lors de l'ajout des données: $_"
            throw [ExcelDataException]::new($this._lastError, $_.Exception)
        }
    }

    <#
    .SYNOPSIS
        Ajoute une valeur à une cellule avec conversion de type.
    .DESCRIPTION
        Cette méthode ajoute une valeur à une cellule avec conversion automatique du type.
    .PARAMETER Worksheet
        Feuille de calcul.
    .PARAMETER Row
        Numéro de ligne.
    .PARAMETER Column
        Numéro de colonne.
    .PARAMETER Value
        Valeur à ajouter.
    .PARAMETER AutoFormat
        Indique si le formatage automatique doit être appliqué.
    .EXAMPLE
        $Exporter.AddCellValue($Worksheet, 1, 1, $Value, $true)
    .OUTPUTS
        None
    #>
    hidden [void] AddCellValue($Worksheet, [int]$Row, [int]$Column, $Value, [bool]$AutoFormat) {
        # Déterminer le type de la valeur
        $TypeInfo = $this.GetValueTypeInfo($Value)

        # Ajouter la valeur à la cellule
        $Worksheet.Cells[$Row, $Column].Value = $TypeInfo.Value

        # Appliquer le format si nécessaire
        if ($AutoFormat) {
            $this.ApplyCellFormat($Worksheet, $Row, $Column, $TypeInfo)
        }
    }

    <#
    .SYNOPSIS
        Détermine le type d'une valeur et la convertit si nécessaire.
    .DESCRIPTION
        Cette méthode détermine le type d'une valeur et la convertit dans le format approprié.
    .PARAMETER Value
        Valeur à analyser.
    .EXAMPLE
        $TypeInfo = $Exporter.GetValueTypeInfo($Value)
    .OUTPUTS
        System.Collections.Hashtable - Informations sur le type et la valeur convertie.
    #>
    hidden [hashtable] GetValueTypeInfo($Value) {
        # Si la valeur est nulle, utiliser le convertisseur Null
        if ($null -eq $Value) {
            return $this._typeConverters["Null"].Invoke($Value, $null)
        }

        # Déterminer le type de la valeur
        $TypeName = switch ($Value.GetType().Name) {
            { $_ -in "Int32", "Int64", "Double", "Single", "Decimal" } { "Numeric" }
            "Boolean" { "Boolean" }
            "DateTime" { "DateTime" }
            default { "Text" }
        }

        # Utiliser le convertisseur approprié
        return $this._typeConverters[$TypeName].Invoke($Value, $null)
    }

    <#
    .SYNOPSIS
        Applique un format à une cellule en fonction du type de données.
    .DESCRIPTION
        Cette méthode applique un format à une cellule en fonction du type de données.
    .PARAMETER Worksheet
        Feuille de calcul.
    .PARAMETER Row
        Numéro de ligne.
    .PARAMETER Column
        Numéro de colonne.
    .PARAMETER TypeInfo
        Informations sur le type de données.
    .EXAMPLE
        $Exporter.ApplyCellFormat($Worksheet, 1, 1, $TypeInfo)
    .OUTPUTS
        None
    #>
    hidden [void] ApplyCellFormat($Worksheet, [int]$Row, [int]$Column, [hashtable]$TypeInfo) {
        $Cell = $Worksheet.Cells[$Row, $Column]

        # Appliquer le format en fonction du type
        switch ($TypeInfo.Type) {
            "Numeric" {
                $Cell.Style.Numberformat.Format = switch ($TypeInfo.Format) {
                    "Currency" { "$#,##0.00" }
                    "Percentage" { "0.00%" }
                    "Integer" { "0" }
                    "Decimal2" { "0.00" }
                    default { "General" }
                }
            }
            "DateTime" {
                $Cell.Style.Numberformat.Format = $TypeInfo.Format
            }
            "Boolean" {
                $Cell.Style.Numberformat.Format = switch ($TypeInfo.Format) {
                    "Yes/No" {
                        """Yes"";""No"";"""" }
                    "True/False" { """True""; ""False""; """" 
                    }
                    "1/0" { "1;0;" }
                    default {
                        """Yes"";""No"";"""" }
                }
            }
            default {
                $Cell.Style.Numberformat.Format = "@"
            }
        }
    }

    <#
    .SYNOPSIS
        Applique un style d'en-tête à une cellule.
    .DESCRIPTION
        Cette méthode applique un style d'en-tête à une cellule.
    .PARAMETER Worksheet
        Feuille de calcul.
    .PARAMETER Row
        Numéro de ligne.
    .PARAMETER Column
        Numéro de colonne.
    .EXAMPLE
        $Exporter.ApplyHeaderStyle($Worksheet, 1, 1)
    .OUTPUTS
        None
    #>
    hidden [void] ApplyHeaderStyle($Worksheet, [int]$Row, [int]$Column) {
        $Cell = $Worksheet.Cells[$Row, $Column]

        # Appliquer le style d'en-tête
        $Cell.Style.Font.Bold = $true
        $Cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
        $Cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(200, 200, 200))
        $Cell.Style.Border.Bottom.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
        $Cell.Style.HorizontalAlignment = [OfficeOpenXml.Style.ExcelHorizontalAlignment]::Center
    }

    <#
    .SYNOPSIS
        Lit des données d'une feuille de calcul.
    .DESCRIPTION
        Cette méthode lit des données d'une feuille de calcul et les convertit en objets PowerShell.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .PARAMETER WorksheetId
        Identifiant de la feuille de calcul.
    .PARAMETER Range
        Plage de cellules à lire (par exemple: "A1:C10"). Si non spécifié, lit toutes les données.
    .PARAMETER IncludeHeaders
        Indique si la première ligne doit être considérée comme des en-têtes (par défaut: $true).
    .EXAMPLE
        $Data = $Exporter.ReadData($WorkbookId, $WorksheetId, "A1:C10", $true)
    .OUTPUTS
        System.Collections.ArrayList - Données lues sous forme d'objets PowerShell.
    #>
    [System.Collections.ArrayList] ReadData(
        [string]$WorkbookId,
        [string]$WorksheetId,
        [string]$Range = "",
        [bool]$IncludeHeaders = $true
    ) {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]

            # Vérifier si la feuille existe
            if (-not $Workbook.Worksheets.ContainsKey($WorksheetId)) {
                throw "Feuille de calcul non trouvée: $WorksheetId"
            }

            $Worksheet = $Workbook.Worksheets[$WorksheetId]

            # Déterminer la plage à lire
            $DataRange = if ([string]::IsNullOrEmpty($Range)) {
                $Worksheet.Dimension
            }
            else {
                $Worksheet.Cells[$Range]
            }

            # Si la plage est vide, retourner une liste vide
            if ($null -eq $DataRange) {
                return New-Object System.Collections.ArrayList
            }

            $StartRow = $DataRange.Start.Row
            $EndRow = $DataRange.End.Row
            $StartColumn = $DataRange.Start.Column
            $EndColumn = $DataRange.End.Column

            $Result = New-Object System.Collections.ArrayList

            # Lire les en-têtes si nécessaire
            $Headers = @()

            if ($IncludeHeaders -and $StartRow -lt $EndRow) {
                for ($Column = $StartColumn; $Column -le $EndColumn; $Column++) {
                    $HeaderValue = $Worksheet.Cells[$StartRow, $Column].Value
                    $Headers += if ($null -eq $HeaderValue) { "Column$Column" } else { $HeaderValue.ToString() }
                }

                $StartRow++
            }
            else {
                # Si pas d'en-têtes, créer des noms de colonnes par défaut
                for ($Column = $StartColumn; $Column -le $EndColumn; $Column++) {
                    $Headers += "Column$Column"
                }
            }

            # Lire les données
            for ($Row = $StartRow; $Row -le $EndRow; $Row++) {
                $RowData = [ordered]@{}

                for ($Column = $StartColumn; $Column -le $EndColumn; $Column++) {
                    $HeaderIndex = $Column - $StartColumn
                    $CellValue = $Worksheet.Cells[$Row, $Column].Value

                    # Convertir la valeur si nécessaire
                    $RowData[$Headers[$HeaderIndex]] = $CellValue
                }

                # Ajouter l'objet à la liste de résultats
                $Result.Add([PSCustomObject]$RowData) | Out-Null
            }

            return $Result
        }
        catch {
            $this._lastError = "Erreur lors de la lecture des données: $_"
            throw [ExcelDataException]::new($this._lastError, $_.Exception)
        }
    }

    #endregion

    #region Méthodes utilitaires

    <#
    .SYNOPSIS
        Obtient la dernière erreur survenue.
    .DESCRIPTION
        Cette méthode retourne la dernière erreur survenue lors de l'utilisation de l'exporteur.
    .EXAMPLE
        $LastError = $Exporter.GetLastError()
    .OUTPUTS
        System.String - Message de la dernière erreur.
    #>
    [string] GetLastError() {
        return $this._lastError
    }

    <#
    .SYNOPSIS
        Vérifie si un classeur existe.
    .DESCRIPTION
        Cette méthode vérifie si un classeur existe dans la collection.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .EXAMPLE
        $Exists = $Exporter.WorkbookExists($WorkbookId)
    .OUTPUTS
        System.Boolean - True si le classeur existe, False sinon.
    #>
    [bool] WorkbookExists([string]$WorkbookId) {
        return $this._workbooks.ContainsKey($WorkbookId)
    }

    <#
    .SYNOPSIS
        Vérifie si une feuille de calcul existe dans un classeur.
    .DESCRIPTION
        Cette méthode vérifie si une feuille de calcul existe dans un classeur.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .PARAMETER WorksheetId
        Identifiant de la feuille de calcul.
    .EXAMPLE
        $Exists = $Exporter.WorksheetExists($WorkbookId, $WorksheetId)
    .OUTPUTS
        System.Boolean - True si la feuille existe, False sinon.
    #>
    [bool] WorksheetExists([string]$WorkbookId, [string]$WorksheetId) {
        if (-not $this._workbooks.ContainsKey($WorkbookId)) {
            return $false
        }

        return $this._workbooks[$WorkbookId].Worksheets.ContainsKey($WorksheetId)
    }

    <#
    .SYNOPSIS
        Obtient le nom d'une feuille de calcul.
    .DESCRIPTION
        Cette méthode retourne le nom d'une feuille de calcul.
    .PARAMETER WorkbookId
        Identifiant du classeur.
    .PARAMETER WorksheetId
        Identifiant de la feuille de calcul.
    .EXAMPLE
        $Name = $Exporter.GetWorksheetName($WorkbookId, $WorksheetId)
    .OUTPUTS
        System.String - Nom de la feuille de calcul.
    #>
    [string] GetWorksheetName([string]$WorkbookId, [string]$WorksheetId) {
        try {
            # Vérifier si le classeur existe
            if (-not $this._workbooks.ContainsKey($WorkbookId)) {
                throw "Classeur non trouvé: $WorkbookId"
            }

            $Workbook = $this._workbooks[$WorkbookId]

            # Vérifier si la feuille existe
            if (-not $Workbook.Worksheets.ContainsKey($WorksheetId)) {
                throw "Feuille de calcul non trouvée: $WorksheetId"
            }

            return $Workbook.Worksheets[$WorksheetId].Name
        } catch {
            $this._lastError = "Erreur lors de la récupération du nom de la feuille de calcul: $_"
            throw [ExcelWorksheetException]::new($this._lastError, $_.Exception)
        }
    }

    #endregion
}

#endregion

#region Fonctions d'exportation

<#
.SYNOPSIS
    Crée un nouvel exporteur Excel.
.DESCRIPTION
    Cette fonction crée un nouvel exporteur Excel.
.EXAMPLE
    $Exporter = New-ExcelExporter
.OUTPUTS
    ExcelExporter - Un nouvel exporteur Excel.
#>
function New-ExcelExporter {
    [CmdletBinding()]
    param ()

    try {
        return [ExcelExporter]::new()
    } catch {
        Write-Error "Erreur lors de la création de l'exporteur Excel: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Crée un nouveau classeur Excel.
.DESCRIPTION
    Cette fonction crée un nouveau classeur Excel.
.PARAMETER Exporter
    Exporteur Excel à utiliser.
.PARAMETER Path
    Chemin où le classeur sera sauvegardé (optionnel).
.EXAMPLE
    $WorkbookId = New-ExcelWorkbook -Exporter $Exporter -Path "C:\Temp\Rapport.xlsx"
.OUTPUTS
    System.String - Identifiant unique du classeur.
#>
function New-ExcelWorkbook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $false)]
        [string]$Path = ""
    )

    try {
        return $Exporter.CreateWorkbook($Path)
    } catch {
        Write-Error "Erreur lors de la création du classeur Excel: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Ajoute une feuille de calcul à un classeur Excel.
.DESCRIPTION
    Cette fonction ajoute une feuille de calcul à un classeur Excel.
.PARAMETER Exporter
    Exporteur Excel à utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER Name
    Nom de la feuille de calcul.
.EXAMPLE
    $WorksheetId = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name "Données"
.OUTPUTS
    System.String - Identifiant unique de la feuille de calcul.
#>
function Add-ExcelWorksheet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        return $Exporter.AddWorksheet($WorkbookId, $Name)
    } catch {
        Write-Error "Erreur lors de l'ajout de la feuille de calcul: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Sauvegarde un classeur Excel.
.DESCRIPTION
    Cette fonction sauvegarde un classeur Excel.
.PARAMETER Exporter
    Exporteur Excel à utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER Path
    Chemin où le classeur sera sauvegardé (optionnel).
.EXAMPLE
    $Path = Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId -Path "C:\Temp\Rapport.xlsx"
.OUTPUTS
    System.String - Chemin du fichier sauvegardé.
#>
function Save-ExcelWorkbook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $false)]
        [string]$Path = ""
    )

    try {
        return $Exporter.SaveWorkbook($WorkbookId, $Path)
    } catch {
        Write-Error "Erreur lors de la sauvegarde du classeur Excel: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Ferme un classeur Excel et libère les ressources.
.DESCRIPTION
    Cette fonction ferme un classeur Excel et libère les ressources.
.PARAMETER Exporter
    Exporteur Excel à utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.EXAMPLE
    Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
.OUTPUTS
    None
#>
function Close-ExcelWorkbook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId
    )

    try {
        $Exporter.CloseWorkbook($WorkbookId)
    } catch {
        Write-Error "Erreur lors de la fermeture du classeur Excel: $_"
    }
}

<#
.SYNOPSIS
    Liste toutes les feuilles de calcul d'un classeur Excel.
.DESCRIPTION
    Cette fonction liste toutes les feuilles de calcul d'un classeur Excel.
.PARAMETER Exporter
    Exporteur Excel à utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.EXAMPLE
    $Worksheets = Get-ExcelWorksheets -Exporter $Exporter -WorkbookId $WorkbookId
.OUTPUTS
    System.Collections.Hashtable - Table de hachage des feuilles de calcul (ID -> Nom).
#>
function Get-ExcelWorksheets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId
    )

    try {
        return $Exporter.ListWorksheets($WorkbookId)
    } catch {
        Write-Error "Erreur lors de la liste des feuilles de calcul: $_"
        return $null
    }
}

#endregion

<#
.SYNOPSIS
    Ajoute des données à une feuille de calcul Excel.
.DESCRIPTION
    Cette fonction ajoute des données à une feuille de calcul Excel.
.PARAMETER Exporter
    Exporteur Excel à utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER Data
    Données à ajouter (peut être un objet, un tableau ou une collection).
.PARAMETER StartRow
    Ligne de départ (par défaut: 1).
.PARAMETER StartColumn
    Colonne de départ (par défaut: 1).
.PARAMETER IncludeHeaders
    Indique si les en-têtes doivent être inclus (par défaut: $true).
.PARAMETER AutoFormat
    Indique si le formatage automatique doit être appliqué (par défaut: $true).
.EXAMPLE
    Add-ExcelData -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -Data $Data
.OUTPUTS
    None
#>
function Add-ExcelData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory=$true)]
        [string]$WorkbookId,

        [Parameter(Mandatory=$true)]
        [string]$WorksheetId,

        [Parameter(Mandatory=$true)]
        $Data,

        [Parameter(Mandatory=$false)]
        [int]$StartRow = 1,

        [Parameter(Mandatory=$false)]
        [int]$StartColumn = 1,

        [Parameter(Mandatory=$false)]
        [bool]$IncludeHeaders = $true,

        [Parameter(Mandatory=$false)]
        [bool]$AutoFormat = $true
    )

    try {
        $Exporter.AddData($WorkbookId, $WorksheetId, $Data, $StartRow, $StartColumn, $IncludeHeaders, $AutoFormat)
    }
    catch {
        Write-Error "Erreur lors de l'ajout des données: $_"
    }
}

<#
.SYNOPSIS
    Lit des données d'une feuille de calcul Excel.
.DESCRIPTION
    Cette fonction lit des données d'une feuille de calcul Excel et les convertit en objets PowerShell.
.PARAMETER Exporter
    Exporteur Excel à utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER WorksheetId
    Identifiant de la feuille de calcul.
.PARAMETER Range
    Plage de cellules à lire (par exemple: "A1:C10"). Si non spécifié, lit toutes les données.
.PARAMETER IncludeHeaders
    Indique si la première ligne doit être considérée comme des en-têtes (par défaut: $true).
.EXAMPLE
    $Data = Get-ExcelData -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId
.OUTPUTS
    System.Collections.ArrayList - Données lues sous forme d'objets PowerShell.
#>
function Get-ExcelData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory=$true)]
        [string]$WorkbookId,

        [Parameter(Mandatory=$true)]
        [string]$WorksheetId,

        [Parameter(Mandatory=$false)]
        [string]$Range = "",

        [Parameter(Mandatory=$false)]
        [bool]$IncludeHeaders = $true
    )

    try {
        return $Exporter.ReadData($WorkbookId, $WorksheetId, $Range, $IncludeHeaders)
    }
    catch {
        Write-Error "Erreur lors de la lecture des données: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-ExcelExporter, New-ExcelWorkbook, Add-ExcelWorksheet, Save-ExcelWorkbook, Close-ExcelWorkbook, Get-ExcelWorksheets, Add-ExcelData, Get-ExcelData
