<#
.SYNOPSIS
    Génère une collection de test d'informations extraites de taille spécifiée.

.DESCRIPTION
    Cette fonction génère une collection complète d'informations extraites pour les tests
    de performance et de fonctionnalité. Elle permet de personnaliser la taille, la composition
    et d'autres caractéristiques de la collection.

.PARAMETER Size
    Taille de la collection à générer. Options prédéfinies: 'Small', 'Medium', 'Large', 'ExtraLarge'.
    Small: ~100 éléments
    Medium: ~1000 éléments
    Large: ~10000 éléments
    ExtraLarge: ~50000 éléments
    Par défaut: 'Small'.

.PARAMETER ItemCount
    Nombre exact d'éléments à générer. Remplace le paramètre Size si spécifié.

.PARAMETER TextRatio
    Ratio d'éléments textuels par rapport aux éléments structurés (0.0-1.0).
    Par défaut: 0.7 (70% de texte, 30% de données structurées).

.PARAMETER Complexity
    Niveau de complexité des données (1-10). Influence la structure et la variété des données.
    1-3: Données simples avec peu de variété
    4-7: Données intermédiaires avec une variété modérée
    8-10: Données complexes avec une grande variété
    Par défaut: 5.

.PARAMETER OutputPath
    Chemin où sauvegarder la collection générée. Si non spécifié, la collection est uniquement
    retournée en mémoire.

.PARAMETER OutputFormat
    Format de sortie si OutputPath est spécifié. Options: 'JSON', 'XML', 'CSV'.
    Par défaut: 'JSON'.

.PARAMETER Name
    Nom de la collection. Par défaut: "Collection de test".

.PARAMETER Description
    Description de la collection. Par défaut: "Collection générée automatiquement pour les tests".

.PARAMETER RandomSeed
    Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
    des collections identiques à chaque exécution avec la même graine.

.PARAMETER IncludePerformanceMetrics
    Si spécifié, mesure et affiche les métriques de performance pendant la génération.

.EXAMPLE
    $collection = New-TestCollection -Size 'Medium' -TextRatio 0.6 -Complexity 7

.EXAMPLE
    New-TestCollection -ItemCount 500 -OutputPath "C:\Temp\test_collection.json" -RandomSeed 12345 -IncludePerformanceMetrics

.NOTES
    Cette fonction est conçue pour les tests et ne doit pas être utilisée en production.
#>
function New-TestCollection {
    [CmdletBinding(DefaultParameterSetName = 'BySize')]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'BySize')]
        [ValidateSet('Small', 'Medium', 'Large', 'ExtraLarge')]
        [string]$Size = 'Small',
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCount')]
        [int]$ItemCount,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$TextRatio = 0.7,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Complexity = 5,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'XML', 'CSV')]
        [string]$OutputFormat = 'JSON',
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "Collection de test",
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Collection générée automatiquement pour les tests",
        
        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludePerformanceMetrics
    )
    
    # Définir le nombre d'éléments en fonction de la taille
    if ($PSCmdlet.ParameterSetName -eq 'BySize') {
        $ItemCount = switch ($Size) {
            'Small' { 100 }
            'Medium' { 1000 }
            'Large' { 10000 }
            'ExtraLarge' { 50000 }
            default { 100 }
        }
    }
    
    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }
    
    # Initialiser les métriques de performance si demandé
    if ($IncludePerformanceMetrics) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $memoryBefore = [System.GC]::GetTotalMemory($true)
    }
    
    # Créer la collection
    $collection = @{
        Name = $Name
        Description = $Description
        CreatedAt = Get-Date
        Items = @{}
    }
    
    # Calculer le nombre d'éléments textuels et structurés
    $textCount = [Math]::Round($ItemCount * $TextRatio)
    $structuredCount = $ItemCount - $textCount
    
    # Générer les éléments textuels
    if ($IncludePerformanceMetrics) {
        Write-Host "Génération de $textCount éléments textuels..."
        $textStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }
    
    for ($i = 1; $i -le $textCount; $i++) {
        # Générer un texte aléatoire
        $wordCount = $random.Next(50, 500)
        $text = New-RandomTextData -WordCount $wordCount -Complexity $Complexity -RandomSeed ($RandomSeed + $i)
        
        # Générer des métadonnées aléatoires
        $metadata = New-RandomMetadata -Complexity $Complexity -RandomSeed ($RandomSeed + $i)
        
        # Créer l'élément textuel
        $textInfo = @{
            _Type = "TextExtractedInfo"
            Id = [guid]::NewGuid().ToString()
            Source = "test_text_$i.txt"
            Text = $text
            Language = if ($metadata.ContainsKey("Language")) { $metadata["Language"] } else { "fr" }
            ConfidenceScore = $random.Next(50, 101)
            ExtractedAt = (Get-Date).AddDays(-$random.Next(0, 30))
            ProcessingState = "Processed"
            Metadata = $metadata
        }
        
        # Ajouter l'élément à la collection
        $collection.Items[$textInfo.Id] = $textInfo
        
        # Afficher la progression si demandé
        if ($IncludePerformanceMetrics -and $i % [Math]::Max(1, $textCount / 10) -eq 0) {
            $percent = [Math]::Round(($i / $textCount) * 100)
            Write-Progress -Activity "Génération des éléments textuels" -Status "$percent% Complet" -PercentComplete $percent
        }
    }
    
    if ($IncludePerformanceMetrics) {
        $textStopwatch.Stop()
        Write-Host "Éléments textuels générés en $($textStopwatch.Elapsed.TotalSeconds) secondes."
    }
    
    # Générer les éléments structurés
    if ($IncludePerformanceMetrics) {
        Write-Host "Génération de $structuredCount éléments structurés..."
        $structuredStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }
    
    for ($i = 1; $i -le $structuredCount; $i++) {
        # Générer des données structurées aléatoires
        $data = New-RandomStructuredData -ItemCount 1 -Complexity $Complexity -RandomSeed ($RandomSeed + $textCount + $i)
        
        # Générer des métadonnées aléatoires
        $metadata = New-RandomMetadata -Complexity $Complexity -RandomSeed ($RandomSeed + $textCount + $i)
        
        # Déterminer le format des données
        $dataFormat = if ($random.Next(0, 2) -eq 0) { "Json" } else { "Xml" }
        
        # Créer l'élément structuré
        $structuredInfo = @{
            _Type = "StructuredDataExtractedInfo"
            Id = [guid]::NewGuid().ToString()
            Source = "test_data_$i.$($dataFormat.ToLower())"
            Data = $data
            DataFormat = $dataFormat
            ConfidenceScore = $random.Next(60, 101)
            ExtractedAt = (Get-Date).AddDays(-$random.Next(0, 30))
            ProcessingState = "Processed"
            Metadata = $metadata
        }
        
        # Ajouter l'élément à la collection
        $collection.Items[$structuredInfo.Id] = $structuredInfo
        
        # Afficher la progression si demandé
        if ($IncludePerformanceMetrics -and $i % [Math]::Max(1, $structuredCount / 10) -eq 0) {
            $percent = [Math]::Round(($i / $structuredCount) * 100)
            Write-Progress -Activity "Génération des éléments structurés" -Status "$percent% Complet" -PercentComplete $percent
        }
    }
    
    if ($IncludePerformanceMetrics) {
        $structuredStopwatch.Stop()
        Write-Host "Éléments structurés générés en $($structuredStopwatch.Elapsed.TotalSeconds) secondes."
    }
    
    # Sauvegarder la collection si un chemin de sortie est spécifié
    if ($OutputPath) {
        if ($IncludePerformanceMetrics) {
            Write-Host "Sauvegarde de la collection au format $OutputFormat..."
            $saveStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder la collection dans le format spécifié
        switch ($OutputFormat.ToUpper()) {
            "JSON" {
                $collection | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            "XML" {
                # Créer un document XML
                $xmlWriter = New-Object System.XMl.XmlTextWriter($OutputPath, [System.Text.Encoding]::UTF8)
                $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
                $xmlWriter.WriteStartDocument()
                
                $xmlWriter.WriteStartElement("Collection")
                $xmlWriter.WriteAttributeString("Name", $collection.Name)
                $xmlWriter.WriteAttributeString("Description", $collection.Description)
                $xmlWriter.WriteAttributeString("CreatedAt", $collection.CreatedAt.ToString("o"))
                
                $xmlWriter.WriteStartElement("Items")
                
                foreach ($item in $collection.Items.Values) {
                    $xmlWriter.WriteStartElement("Item")
                    $xmlWriter.WriteAttributeString("Id", $item.Id)
                    $xmlWriter.WriteAttributeString("Type", $item._Type)
                    
                    foreach ($prop in $item.Keys | Where-Object { $_ -ne "Id" -and $_ -ne "_Type" }) {
                        if ($null -ne $item[$prop]) {
                            if ($item[$prop] -is [hashtable] -or $item[$prop] -is [System.Collections.Specialized.OrderedDictionary]) {
                                $xmlWriter.WriteStartElement($prop)
                                foreach ($subProp in $item[$prop].Keys) {
                                    $xmlWriter.WriteElementString($subProp, $item[$prop][$subProp].ToString())
                                }
                                $xmlWriter.WriteEndElement()
                            }
                            elseif ($item[$prop] -is [array]) {
                                $xmlWriter.WriteStartElement($prop)
                                foreach ($element in $item[$prop]) {
                                    $xmlWriter.WriteElementString("Item", $element.ToString())
                                }
                                $xmlWriter.WriteEndElement()
                            }
                            else {
                                $xmlWriter.WriteElementString($prop, $item[$prop].ToString())
                            }
                        }
                    }
                    
                    $xmlWriter.WriteEndElement() # Item
                }
                
                $xmlWriter.WriteEndElement() # Items
                $xmlWriter.WriteEndElement() # Collection
                
                $xmlWriter.WriteEndDocument()
                $xmlWriter.Flush()
                $xmlWriter.Close()
            }
            "CSV" {
                # Pour CSV, nous devons aplatir les objets
                $flatItems = @()
                
                foreach ($item in $collection.Items.Values) {
                    $flatItem = [ordered]@{
                        Id = $item.Id
                        Type = $item._Type
                        Source = $item.Source
                        ConfidenceScore = $item.ConfidenceScore
                        ExtractedAt = $item.ExtractedAt
                        ProcessingState = $item.ProcessingState
                    }
                    
                    if ($item._Type -eq "TextExtractedInfo") {
                        $flatItem["Text"] = if ($item.Text.Length -gt 100) { $item.Text.Substring(0, 100) + "..." } else { $item.Text }
                        $flatItem["Language"] = $item.Language
                    }
                    else {
                        $flatItem["DataFormat"] = $item.DataFormat
                        $flatItem["DataSummary"] = "Data object with multiple properties"
                    }
                    
                    # Ajouter les métadonnées
                    foreach ($metaKey in $item.Metadata.Keys) {
                        $metaValue = $item.Metadata[$metaKey]
                        if ($metaValue -is [array]) {
                            $flatItem["Metadata_$metaKey"] = ($metaValue -join ", ")
                        }
                        else {
                            $flatItem["Metadata_$metaKey"] = $metaValue
                        }
                    }
                    
                    $flatItems += [PSCustomObject]$flatItem
                }
                
                $flatItems | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
        }
        
        if ($IncludePerformanceMetrics) {
            $saveStopwatch.Stop()
            Write-Host "Collection sauvegardée en $($saveStopwatch.Elapsed.TotalSeconds) secondes."
        }
    }
    
    # Afficher les métriques de performance si demandé
    if ($IncludePerformanceMetrics) {
        $stopwatch.Stop()
        $memoryAfter = [System.GC]::GetTotalMemory($true)
        $memoryUsed = ($memoryAfter - $memoryBefore) / 1MB
        
        Write-Host "Métriques de performance:"
        Write-Host "  Temps total: $($stopwatch.Elapsed.TotalSeconds) secondes"
        Write-Host "  Mémoire utilisée: $([Math]::Round($memoryUsed, 2)) MB"
        Write-Host "  Éléments générés: $($collection.Items.Count)"
        Write-Host "  Éléments par seconde: $([Math]::Round($collection.Items.Count / $stopwatch.Elapsed.TotalSeconds, 2))"
    }
    
    return $collection
}

# Exporter la fonction
Export-ModuleMember -Function New-TestCollection
