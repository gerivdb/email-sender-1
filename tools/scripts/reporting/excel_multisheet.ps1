<#
.SYNOPSIS
    Module de gestion des feuilles multiples pour Excel.
.DESCRIPTION
    Ce module fournit des fonctionnalitÃ©s pour la gestion de feuilles multiples
    dans les classeurs Excel, y compris la rÃ©partition des donnÃ©es et la navigation.
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

<#
.SYNOPSIS
    CrÃ©e un classeur Excel avec plusieurs feuilles.
.DESCRIPTION
    Cette fonction crÃ©e un classeur Excel avec plusieurs feuilles et retourne les identifiants.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER Path
    Chemin oÃ¹ le classeur sera sauvegardÃ© (optionnel).
.PARAMETER SheetNames
    Tableau des noms de feuilles Ã  crÃ©er.
.EXAMPLE
    $Result = New-ExcelMultiSheetWorkbook -Exporter $Exporter -Path "C:\Temp\Rapport.xlsx" -SheetNames @("RÃ©sumÃ©", "DonnÃ©es", "Graphiques")
.OUTPUTS
    System.Collections.Hashtable - Table de hachage contenant les identifiants du classeur et des feuilles.
#>
function New-ExcelMultiSheetWorkbook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ExcelExporter]$Exporter,
        
        [Parameter(Mandatory=$false)]
        [string]$Path = "",
        
        [Parameter(Mandatory=$true)]
        [string[]]$SheetNames
    )
    
    try {
        # CrÃ©er un nouveau classeur
        $WorkbookId = New-ExcelWorkbook -Exporter $Exporter -Path $Path
        
        if ($null -eq $WorkbookId) {
            throw "Erreur lors de la crÃ©ation du classeur Excel."
        }
        
        # CrÃ©er les feuilles
        $Worksheets = @{}
        
        foreach ($SheetName in $SheetNames) {
            $WorksheetId = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name $SheetName
            
            if ($null -eq $WorksheetId) {
                throw "Erreur lors de la crÃ©ation de la feuille '$SheetName'."
            }
            
            $Worksheets[$SheetName] = $WorksheetId
        }
        
        # Sauvegarder le classeur
        if (-not [string]::IsNullOrEmpty($Path)) {
            Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
        }
        
        # Retourner les identifiants
        return @{
            WorkbookId = $WorkbookId
            Worksheets = $Worksheets
        }
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation du classeur multi-feuilles: $_"
        return $null
    }
}

<#
.SYNOPSIS
    RÃ©partit des donnÃ©es sur plusieurs feuilles Excel.
.DESCRIPTION
    Cette fonction rÃ©partit des donnÃ©es sur plusieurs feuilles Excel selon diffÃ©rentes stratÃ©gies.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER Data
    DonnÃ©es Ã  rÃ©partir.
.PARAMETER Strategy
    StratÃ©gie de rÃ©partition (ByCategory, BySize, ByProperty).
.PARAMETER CategoryProperty
    PropriÃ©tÃ© Ã  utiliser pour la rÃ©partition par catÃ©gorie.
.PARAMETER MaxRowsPerSheet
    Nombre maximum de lignes par feuille pour la rÃ©partition par taille.
.PARAMETER SheetPrefix
    PrÃ©fixe pour les noms de feuilles gÃ©nÃ©rÃ©es automatiquement.
.EXAMPLE
    $Result = Split-ExcelDataToSheets -Exporter $Exporter -WorkbookId $WorkbookId -Data $Data -Strategy "ByCategory" -CategoryProperty "Department"
.OUTPUTS
    System.Collections.Hashtable - Table de hachage contenant les identifiants des feuilles crÃ©Ã©es.
#>
function Split-ExcelDataToSheets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ExcelExporter]$Exporter,
        
        [Parameter(Mandatory=$true)]
        [string]$WorkbookId,
        
        [Parameter(Mandatory=$true)]
        $Data,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("ByCategory", "BySize", "ByProperty")]
        [string]$Strategy,
        
        [Parameter(Mandatory=$false)]
        [string]$CategoryProperty = "",
        
        [Parameter(Mandatory=$false)]
        [int]$MaxRowsPerSheet = 1000,
        
        [Parameter(Mandatory=$false)]
        [string]$SheetPrefix = "Sheet"
    )
    
    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }
        
        # VÃ©rifier si les donnÃ©es sont valides
        if ($null -eq $Data -or ($Data -is [array] -and $Data.Count -eq 0)) {
            throw "Les donnÃ©es sont vides ou nulles."
        }
        
        # CrÃ©er un dictionnaire pour stocker les feuilles crÃ©Ã©es
        $Worksheets = @{}
        
        # RÃ©partir les donnÃ©es selon la stratÃ©gie
        switch ($Strategy) {
            "ByCategory" {
                # VÃ©rifier si la propriÃ©tÃ© de catÃ©gorie est spÃ©cifiÃ©e
                if ([string]::IsNullOrEmpty($CategoryProperty)) {
                    throw "La propriÃ©tÃ© de catÃ©gorie est requise pour la stratÃ©gie 'ByCategory'."
                }
                
                # Regrouper les donnÃ©es par catÃ©gorie
                $GroupedData = $Data | Group-Object -Property $CategoryProperty
                
                # CrÃ©er une feuille pour chaque catÃ©gorie
                foreach ($Group in $GroupedData) {
                    $CategoryName = if ($null -eq $Group.Name -or $Group.Name -eq "") { "Non catÃ©gorisÃ©" } else { $Group.Name }
                    $SheetName = $CategoryName -replace '[\\\/\[\]\:\*\?]', '_'
                    
                    # Limiter la longueur du nom de la feuille Ã  31 caractÃ¨res (limite Excel)
                    if ($SheetName.Length -gt 31) {
                        $SheetName = $SheetName.Substring(0, 28) + "..."
                    }
                    
                    # CrÃ©er la feuille
                    $WorksheetId = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name $SheetName
                    
                    if ($null -eq $WorksheetId) {
                        throw "Erreur lors de la crÃ©ation de la feuille '$SheetName'."
                    }
                    
                    # Ajouter les donnÃ©es Ã  la feuille
                    Add-ExcelData -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -Data $Group.Group
                    
                    # Stocker l'identifiant de la feuille
                    $Worksheets[$CategoryName] = $WorksheetId
                }
            }
            "BySize" {
                # Calculer le nombre de feuilles nÃ©cessaires
                $TotalItems = if ($Data -is [array]) { $Data.Count } else { 1 }
                $SheetCount = [Math]::Ceiling($TotalItems / $MaxRowsPerSheet)
                
                # CrÃ©er les feuilles et rÃ©partir les donnÃ©es
                for ($i = 0; $i -lt $SheetCount; $i++) {
                    $SheetName = "$SheetPrefix$($i + 1)"
                    
                    # CrÃ©er la feuille
                    $WorksheetId = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name $SheetName
                    
                    if ($null -eq $WorksheetId) {
                        throw "Erreur lors de la crÃ©ation de la feuille '$SheetName'."
                    }
                    
                    # Calculer l'index de dÃ©but et de fin pour cette feuille
                    $StartIndex = $i * $MaxRowsPerSheet
                    $EndIndex = [Math]::Min($StartIndex + $MaxRowsPerSheet - 1, $TotalItems - 1)
                    
                    # Extraire les donnÃ©es pour cette feuille
                    $SheetData = if ($Data -is [array]) { $Data[$StartIndex..$EndIndex] } else { $Data }
                    
                    # Ajouter les donnÃ©es Ã  la feuille
                    Add-ExcelData -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -Data $SheetData
                    
                    # Stocker l'identifiant de la feuille
                    $Worksheets[$SheetName] = $WorksheetId
                }
            }
            "ByProperty" {
                # VÃ©rifier si la propriÃ©tÃ© de catÃ©gorie est spÃ©cifiÃ©e
                if ([string]::IsNullOrEmpty($CategoryProperty)) {
                    throw "La propriÃ©tÃ© est requise pour la stratÃ©gie 'ByProperty'."
                }
                
                # Obtenir les valeurs uniques de la propriÃ©tÃ©
                $UniqueValues = $Data | ForEach-Object { $_.$CategoryProperty } | Select-Object -Unique
                
                # CrÃ©er une feuille pour chaque valeur unique
                foreach ($Value in $UniqueValues) {
                    $PropertyValue = if ($null -eq $Value -or $Value -eq "") { "Non dÃ©fini" } else { $Value }
                    $SheetName = $PropertyValue -replace '[\\\/\[\]\:\*\?]', '_'
                    
                    # Limiter la longueur du nom de la feuille Ã  31 caractÃ¨res (limite Excel)
                    if ($SheetName.Length -gt 31) {
                        $SheetName = $SheetName.Substring(0, 28) + "..."
                    }
                    
                    # CrÃ©er la feuille
                    $WorksheetId = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name $SheetName
                    
                    if ($null -eq $WorksheetId) {
                        throw "Erreur lors de la crÃ©ation de la feuille '$SheetName'."
                    }
                    
                    # Filtrer les donnÃ©es pour cette valeur
                    $FilteredData = $Data | Where-Object { $_.$CategoryProperty -eq $Value }
                    
                    # Ajouter les donnÃ©es Ã  la feuille
                    Add-ExcelData -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -Data $FilteredData
                    
                    # Stocker l'identifiant de la feuille
                    $Worksheets[$PropertyValue] = $WorksheetId
                }
            }
        }
        
        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
        
        # Retourner les identifiants des feuilles
        return $Worksheets
    }
    catch {
        Write-Error "Erreur lors de la rÃ©partition des donnÃ©es sur les feuilles: $_"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e des liens de navigation entre les feuilles Excel.
.DESCRIPTION
    Cette fonction crÃ©e des liens de navigation entre les feuilles d'un classeur Excel.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER NavigationMap
    Table de hachage dÃ©finissant les liens de navigation (De -> Vers).
.PARAMETER IncludeHomeButton
    Indique si un bouton "Accueil" doit Ãªtre ajoutÃ© Ã  chaque feuille.
.PARAMETER HomeSheetId
    Identifiant de la feuille d'accueil.
.EXAMPLE
    $NavigationMap = @{
        $Sheet1Id = @($Sheet2Id, $Sheet3Id)
        $Sheet2Id = @($Sheet1Id, $Sheet3Id)
        $Sheet3Id = @($Sheet1Id, $Sheet2Id)
    }
    Add-ExcelSheetNavigation -Exporter $Exporter -WorkbookId $WorkbookId -NavigationMap $NavigationMap -IncludeHomeButton $true -HomeSheetId $Sheet1Id
.OUTPUTS
    None
#>
function Add-ExcelSheetNavigation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ExcelExporter]$Exporter,
        
        [Parameter(Mandatory=$true)]
        [string]$WorkbookId,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$NavigationMap,
        
        [Parameter(Mandatory=$false)]
        [bool]$IncludeHomeButton = $true,
        
        [Parameter(Mandatory=$false)]
        [string]$HomeSheetId = ""
    )
    
    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }
        
        # Obtenir les noms des feuilles
        $SheetNames = @{}
        
        foreach ($SheetId in $NavigationMap.Keys + $NavigationMap.Values) {
            if ($SheetId -is [array]) {
                foreach ($Id in $SheetId) {
                    if (-not $SheetNames.ContainsKey($Id)) {
                        $SheetNames[$Id] = $Exporter.GetWorksheetName($WorkbookId, $Id)
                    }
                }
            }
            else {
                if (-not $SheetNames.ContainsKey($SheetId)) {
                    $SheetNames[$SheetId] = $Exporter.GetWorksheetName($WorkbookId, $SheetId)
                }
            }
        }
        
        # Si un identifiant de feuille d'accueil est spÃ©cifiÃ©, vÃ©rifier qu'il existe
        if ($IncludeHomeButton -and -not [string]::IsNullOrEmpty($HomeSheetId)) {
            if (-not $Exporter.WorksheetExists($WorkbookId, $HomeSheetId)) {
                throw "Feuille d'accueil non trouvÃ©e: $HomeSheetId"
            }
            
            if (-not $SheetNames.ContainsKey($HomeSheetId)) {
                $SheetNames[$HomeSheetId] = $Exporter.GetWorksheetName($WorkbookId, $HomeSheetId)
            }
        }
        
        # CrÃ©er les liens de navigation
        foreach ($SourceSheetId in $NavigationMap.Keys) {
            $TargetSheetIds = $NavigationMap[$SourceSheetId]
            
            # CrÃ©er les liens vers les feuilles cibles
            $Row = 1
            $Column = 1
            
            # Ajouter un titre pour la navigation
            $Worksheet = $Exporter._workbooks[$WorkbookId].Worksheets[$SourceSheetId]
            $Worksheet.Cells[$Row, $Column].Value = "Navigation:"
            $Worksheet.Cells[$Row, $Column].Style.Font.Bold = $true
            
            $Column++
            
            # Ajouter les liens vers les feuilles cibles
            foreach ($TargetSheetId in $TargetSheetIds) {
                $TargetSheetName = $SheetNames[$TargetSheetId]
                
                # CrÃ©er un lien hypertexte
                $Worksheet.Cells[$Row, $Column].Value = $TargetSheetName
                $Worksheet.Cells[$Row, $Column].Hyperlink = New-Object OfficeOpenXml.ExcelHyperLink("'$TargetSheetName'!A1", $TargetSheetName)
                $Worksheet.Cells[$Row, $Column].Style.Font.UnderLine = $true
                $Worksheet.Cells[$Row, $Column].Style.Font.Color.SetColor([System.Drawing.Color]::Blue)
                
                $Column++
            }
            
            # Ajouter un bouton "Accueil" si demandÃ©
            if ($IncludeHomeButton -and -not [string]::IsNullOrEmpty($HomeSheetId) -and $SourceSheetId -ne $HomeSheetId) {
                $HomeSheetName = $SheetNames[$HomeSheetId]
                
                $Worksheet.Cells[$Row, $Column].Value = "Accueil"
                $Worksheet.Cells[$Row, $Column].Hyperlink = New-Object OfficeOpenXml.ExcelHyperLink("'$HomeSheetName'!A1", "Accueil")
                $Worksheet.Cells[$Row, $Column].Style.Font.UnderLine = $true
                $Worksheet.Cells[$Row, $Column].Style.Font.Color.SetColor([System.Drawing.Color]::Red)
            }
        }
        
        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation des liens de navigation: $_"
    }
}

<#
.SYNOPSIS
    CrÃ©e une table des matiÃ¨res pour un classeur Excel.
.DESCRIPTION
    Cette fonction crÃ©e une table des matiÃ¨res pour un classeur Excel avec des liens vers toutes les feuilles.
.PARAMETER Exporter
    Exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    Identifiant du classeur.
.PARAMETER TocSheetName
    Nom de la feuille de table des matiÃ¨res (par dÃ©faut: "Sommaire").
.PARAMETER IncludeDescription
    Indique si des descriptions doivent Ãªtre incluses pour chaque feuille.
.PARAMETER Descriptions
    Table de hachage des descriptions pour chaque feuille (ID -> Description).
.EXAMPLE
    $Descriptions = @{
        $Sheet1Id = "RÃ©sumÃ© des donnÃ©es"
        $Sheet2Id = "DonnÃ©es dÃ©taillÃ©es"
        $Sheet3Id = "Graphiques et analyses"
    }
    Add-ExcelTableOfContents -Exporter $Exporter -WorkbookId $WorkbookId -TocSheetName "Sommaire" -IncludeDescription $true -Descriptions $Descriptions
.OUTPUTS
    System.String - Identifiant de la feuille de table des matiÃ¨res.
#>
function Add-ExcelTableOfContents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ExcelExporter]$Exporter,
        
        [Parameter(Mandatory=$true)]
        [string]$WorkbookId,
        
        [Parameter(Mandatory=$false)]
        [string]$TocSheetName = "Sommaire",
        
        [Parameter(Mandatory=$false)]
        [bool]$IncludeDescription = $false,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Descriptions = @{}
    )
    
    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }
        
        # CrÃ©er la feuille de table des matiÃ¨res
        $TocSheetId = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name $TocSheetName
        
        if ($null -eq $TocSheetId) {
            throw "Erreur lors de la crÃ©ation de la feuille de table des matiÃ¨res."
        }
        
        # Obtenir toutes les feuilles du classeur
        $AllSheets = Get-ExcelWorksheets -Exporter $Exporter -WorkbookId $WorkbookId
        
        # CrÃ©er la table des matiÃ¨res
        $TocWorksheet = $Exporter._workbooks[$WorkbookId].Worksheets[$TocSheetId]
        
        # Ajouter un titre
        $TocWorksheet.Cells[1, 1].Value = "Table des matiÃ¨res"
        $TocWorksheet.Cells[1, 1].Style.Font.Bold = $true
        $TocWorksheet.Cells[1, 1].Style.Font.Size = 14
        
        # Ajouter les en-tÃªtes
        $Row = 3
        $TocWorksheet.Cells[$Row, 1].Value = "NÂ°"
        $TocWorksheet.Cells[$Row, 2].Value = "Feuille"
        
        if ($IncludeDescription) {
            $TocWorksheet.Cells[$Row, 3].Value = "Description"
        }
        
        # Mettre en forme les en-tÃªtes
        $TocWorksheet.Cells[$Row, 1].Style.Font.Bold = $true
        $TocWorksheet.Cells[$Row, 2].Style.Font.Bold = $true
        
        if ($IncludeDescription) {
            $TocWorksheet.Cells[$Row, 3].Style.Font.Bold = $true
        }
        
        # Ajouter les liens vers les feuilles
        $Row++
        $Index = 1
        
        foreach ($SheetId in $AllSheets.Keys) {
            $SheetName = $AllSheets[$SheetId]
            
            # Ignorer la feuille de table des matiÃ¨res elle-mÃªme
            if ($SheetId -eq $TocSheetId) {
                continue
            }
            
            # Ajouter le numÃ©ro
            $TocWorksheet.Cells[$Row, 1].Value = $Index
            
            # Ajouter le lien vers la feuille
            $TocWorksheet.Cells[$Row, 2].Value = $SheetName
            $TocWorksheet.Cells[$Row, 2].Hyperlink = New-Object OfficeOpenXml.ExcelHyperLink("'$SheetName'!A1", $SheetName)
            $TocWorksheet.Cells[$Row, 2].Style.Font.UnderLine = $true
            $TocWorksheet.Cells[$Row, 2].Style.Font.Color.SetColor([System.Drawing.Color]::Blue)
            
            # Ajouter la description si demandÃ©e
            if ($IncludeDescription) {
                $Description = if ($Descriptions.ContainsKey($SheetId)) { $Descriptions[$SheetId] } else { "" }
                $TocWorksheet.Cells[$Row, 3].Value = $Description
            }
            
            $Row++
            $Index++
        }
        
        # Ajuster la largeur des colonnes
        $TocWorksheet.Column(1).Width = 5
        $TocWorksheet.Column(2).Width = 30
        
        if ($IncludeDescription) {
            $TocWorksheet.Column(3).Width = 50
        }
        
        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null
        
        # Retourner l'identifiant de la feuille de table des matiÃ¨res
        return $TocSheetId
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation de la table des matiÃ¨res: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-ExcelMultiSheetWorkbook, Split-ExcelDataToSheets, Add-ExcelSheetNavigation, Add-ExcelTableOfContents
