<#
.SYNOPSIS
    Crée un générateur paramétrable de données synthétiques pour les tests.

.DESCRIPTION
    Cette fonction crée un générateur configurable pour produire des données synthétiques
    utilisées dans les tests de performance et de fonctionnalité du module d'extraction.
    Le générateur peut produire différents types de données extraites avec des paramètres
    personnalisables.

.PARAMETER Configuration
    Hashtable contenant la configuration du générateur. Les clés possibles sont:
    - TextRatio: Pourcentage de données textuelles (vs structurées)
    - LanguageDistribution: Hashtable des langues et leur probabilité
    - MetadataFields: Champs de métadonnées à générer
    - ConfidenceScoreRange: Plage de scores de confiance [min, max]
    - DataComplexity: Niveau de complexité des données (1-10)
    - RandomSeed: Graine pour la génération aléatoire

.PARAMETER PresetName
    Nom d'une configuration prédéfinie à utiliser. Options disponibles:
    - Simple: Configuration basique avec peu de variété
    - Realistic: Configuration réaliste avec distribution naturelle
    - Complex: Configuration complexe avec grande variété
    - HighVolume: Configuration optimisée pour les tests de volume

.EXAMPLE
    $generator = New-SyntheticDataGenerator -PresetName "Realistic"
    $textData = $generator.GenerateTextData(100)

.EXAMPLE
    $config = @{
        TextRatio = 0.7
        LanguageDistribution = @{
            "fr" = 0.6
            "en" = 0.3
            "es" = 0.1
        }
        ConfidenceScoreRange = @(60, 100)
    }
    $generator = New-SyntheticDataGenerator -Configuration $config
    $structuredData = $generator.GenerateStructuredData(50)

.NOTES
    Ce générateur est conçu pour les tests et ne doit pas être utilisé en production.
#>
function New-SyntheticDataGenerator {
    [CmdletBinding(DefaultParameterSetName = 'CustomConfig')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'CustomConfig')]
        [hashtable]$Configuration = @{},

        [Parameter(Mandatory = $true, ParameterSetName = 'Preset')]
        [ValidateSet('Simple', 'Realistic', 'Complex', 'HighVolume')]
        [string]$PresetName
    )

    # Configurations prédéfinies
    $presets = @{
        Simple = @{
            TextRatio = 0.5
            LanguageDistribution = @{
                "fr" = 1.0
            }
            MetadataFields = @("Author", "Category")
            ConfidenceScoreRange = @(70, 90)
            DataComplexity = 3
            RandomSeed = $null
        }
        Realistic = @{
            TextRatio = 0.7
            LanguageDistribution = @{
                "fr" = 0.6
                "en" = 0.3
                "de" = 0.05
                "es" = 0.05
            }
            MetadataFields = @("Author", "Category", "Tags", "Source", "CreatedDate")
            ConfidenceScoreRange = @(50, 100)
            DataComplexity = 6
            RandomSeed = $null
        }
        Complex = @{
            TextRatio = 0.4
            LanguageDistribution = @{
                "fr" = 0.4
                "en" = 0.3
                "de" = 0.1
                "es" = 0.1
                "it" = 0.05
                "pt" = 0.05
            }
            MetadataFields = @("Author", "Category", "Tags", "Source", "CreatedDate", "ModifiedDate", "Version", "Status", "Priority")
            ConfidenceScoreRange = @(30, 100)
            DataComplexity = 9
            RandomSeed = $null
        }
        HighVolume = @{
            TextRatio = 0.6
            LanguageDistribution = @{
                "fr" = 0.5
                "en" = 0.5
            }
            MetadataFields = @("Author", "Category", "Source")
            ConfidenceScoreRange = @(60, 95)
            DataComplexity = 5
            RandomSeed = 12345  # Graine fixe pour la reproductibilité
        }
    }

    # Si un preset est spécifié, utiliser cette configuration
    if ($PSCmdlet.ParameterSetName -eq 'Preset') {
        $Configuration = $presets[$PresetName]
    }

    # Valeurs par défaut pour les paramètres non spécifiés
    $defaultConfig = @{
        TextRatio = 0.6
        LanguageDistribution = @{
            "fr" = 0.7
            "en" = 0.3
        }
        MetadataFields = @("Author", "Category", "Tags")
        ConfidenceScoreRange = @(60, 100)
        DataComplexity = 5
        RandomSeed = $null
    }

    # Fusionner la configuration fournie avec les valeurs par défaut
    foreach ($key in $defaultConfig.Keys) {
        if (-not $Configuration.ContainsKey($key)) {
            $Configuration[$key] = $defaultConfig[$key]
        }
    }

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $Configuration.RandomSeed) {
        $random = New-Object System.Random($Configuration.RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }

    # Fonction pour générer un texte aléatoire
    function Get-RandomText {
        param (
            [int]$MinWords = 10,
            [int]$MaxWords = 100,
            [int]$Complexity = 5
        )

        $wordCount = $random.Next($MinWords, $MaxWords + 1)
        
        # Listes de mots par complexité
        $simpleWords = @("le", "la", "un", "une", "et", "ou", "de", "des", "ce", "cette", "ces", "mon", "ma", "mes", "ton", "ta", "tes", "son", "sa", "ses", "notre", "nos", "votre", "vos", "leur", "leurs", "je", "tu", "il", "elle", "nous", "vous", "ils", "elles", "être", "avoir", "faire", "dire", "voir", "venir", "aller", "prendre", "mettre", "passer", "donner", "trouver", "parler", "aimer", "vouloir", "pouvoir", "savoir", "falloir", "devoir")
        $mediumWords = @("information", "extraction", "document", "analyse", "système", "processus", "méthode", "technique", "résultat", "donnée", "structure", "fonction", "module", "paramètre", "variable", "constante", "condition", "boucle", "itération", "récursion", "algorithme", "performance", "optimisation", "implémentation", "développement", "conception", "architecture", "interface", "composant", "service", "application", "programme", "logiciel", "bibliothèque", "framework", "plateforme", "environnement", "infrastructure", "configuration", "installation")
        $complexWords = @("parallélisation", "synchronisation", "désérialisation", "interopérabilité", "internationalisation", "localisation", "authentification", "autorisation", "cryptographie", "virtualisation", "conteneurisation", "orchestration", "microservice", "résilience", "scalabilité", "disponibilité", "maintenabilité", "testabilité", "observabilité", "traçabilité", "idempotence", "atomicité", "consistance", "isolation", "durabilité", "polymorphisme", "encapsulation", "héritage", "abstraction", "métaprogrammation")

        # Sélectionner les listes de mots en fonction de la complexité
        $wordLists = @()
        if ($Complexity -le 3) {
            $wordLists += ,($simpleWords * 3)
            $wordLists += ,($mediumWords * 1)
        }
        elseif ($Complexity -le 7) {
            $wordLists += ,($simpleWords * 2)
            $wordLists += ,($mediumWords * 2)
            $wordLists += ,($complexWords * 1)
        }
        else {
            $wordLists += ,($simpleWords * 1)
            $wordLists += ,($mediumWords * 2)
            $wordLists += ,($complexWords * 3)
        }
        
        $allWords = $wordLists | ForEach-Object { $_ } | Sort-Object { $random.Next() }
        
        # Générer le texte
        $words = @()
        for ($i = 0; $i -lt $wordCount; $i++) {
            $wordIndex = $random.Next(0, $allWords.Count)
            $words += $allWords[$wordIndex]
        }
        
        # Construire des phrases
        $text = ""
        $currentSentence = ""
        foreach ($word in $words) {
            if ($currentSentence -eq "") {
                # Première lettre en majuscule
                $currentSentence = $word.Substring(0, 1).ToUpper() + $word.Substring(1)
            }
            else {
                $currentSentence += " " + $word
            }
            
            # 20% de chance de terminer la phrase
            if ($random.NextDouble() -lt 0.2 -or $currentSentence.Split(" ").Count -gt 15) {
                $currentSentence += ". "
                $text += $currentSentence
                $currentSentence = ""
            }
        }
        
        # Ajouter la dernière phrase si nécessaire
        if ($currentSentence -ne "") {
            $text += $currentSentence + "."
        }
        
        return $text.Trim()
    }

    # Fonction pour générer des métadonnées aléatoires
    function Get-RandomMetadata {
        param (
            [string[]]$Fields,
            [int]$Complexity = 5
        )
        
        $metadata = @{}
        
        foreach ($field in $Fields) {
            switch ($field) {
                "Author" {
                    $authors = @("Jean Dupont", "Marie Martin", "Pierre Durand", "Sophie Lefebvre", "Thomas Bernard", "Julie Robert", "Nicolas Petit", "Isabelle Dubois", "François Moreau", "Catherine Simon")
                    $metadata[$field] = $authors[$random.Next(0, $authors.Count)]
                }
                "Category" {
                    $categories = @("Document", "Rapport", "Présentation", "Email", "Note", "Contrat", "Facture", "Formulaire", "Manuel", "Procédure")
                    $metadata[$field] = $categories[$random.Next(0, $categories.Count)]
                }
                "Tags" {
                    $allTags = @("important", "urgent", "confidentiel", "archive", "brouillon", "final", "révision", "validation", "référence", "template", "projet", "client", "interne", "externe", "technique", "commercial", "juridique", "financier", "administratif", "ressources humaines")
                    $tagCount = $random.Next(1, [Math]::Min(5, $Complexity))
                    $tags = @()
                    
                    for ($i = 0; $i -lt $tagCount; $i++) {
                        $tagIndex = $random.Next(0, $allTags.Count)
                        if (-not $tags.Contains($allTags[$tagIndex])) {
                            $tags += $allTags[$tagIndex]
                        }
                    }
                    
                    $metadata[$field] = $tags
                }
                "Source" {
                    $sources = @("Email", "Web", "Scanner", "API", "Base de données", "Import manuel", "Système externe", "Application mobile", "Formulaire web", "Service tiers")
                    $metadata[$field] = $sources[$random.Next(0, $sources.Count)]
                }
                "CreatedDate" {
                    # Date entre il y a 1 an et aujourd'hui
                    $daysAgo = $random.Next(0, 365)
                    $metadata[$field] = (Get-Date).AddDays(-$daysAgo)
                }
                "ModifiedDate" {
                    if ($metadata.ContainsKey("CreatedDate")) {
                        # Date entre la date de création et aujourd'hui
                        $createdDate = $metadata["CreatedDate"]
                        $daysAfterCreation = $random.Next(0, [Math]::Max(1, (New-TimeSpan -Start $createdDate -End (Get-Date)).Days))
                        $metadata[$field] = $createdDate.AddDays($daysAfterCreation)
                    }
                    else {
                        $daysAgo = $random.Next(0, 30)
                        $metadata[$field] = (Get-Date).AddDays(-$daysAgo)
                    }
                }
                "Version" {
                    $major = $random.Next(1, 3)
                    $minor = $random.Next(0, 10)
                    $patch = $random.Next(0, 10)
                    $metadata[$field] = "$major.$minor.$patch"
                }
                "Status" {
                    $statuses = @("Brouillon", "En révision", "Validé", "Publié", "Archivé", "Obsolète")
                    $metadata[$field] = $statuses[$random.Next(0, $statuses.Count)]
                }
                "Priority" {
                    $priorities = @("Basse", "Normale", "Haute", "Critique")
                    $metadata[$field] = $priorities[$random.Next(0, $priorities.Count)]
                }
                default {
                    $metadata[$field] = "Valeur pour $field"
                }
            }
        }
        
        return $metadata
    }

    # Fonction pour générer une langue aléatoire selon la distribution
    function Get-RandomLanguage {
        param (
            [hashtable]$Distribution
        )
        
        $value = $random.NextDouble()
        $cumulative = 0
        
        foreach ($language in $Distribution.Keys) {
            $cumulative += $Distribution[$language]
            if ($value -lt $cumulative) {
                return $language
            }
        }
        
        # Par défaut, retourner la première langue
        return $Distribution.Keys | Select-Object -First 1
    }

    # Fonction pour générer un score de confiance aléatoire
    function Get-RandomConfidenceScore {
        param (
            [int]$Min,
            [int]$Max
        )
        
        return $random.Next($Min, $Max + 1)
    }

    # Fonction pour générer des données structurées aléatoires
    function Get-RandomStructuredData {
        param (
            [int]$MinItems = 1,
            [int]$MaxItems = 10,
            [int]$Complexity = 5
        )
        
        $itemCount = $random.Next($MinItems, $MaxItems + 1)
        $data = @()
        
        # Types de données possibles
        $dataTypes = @("string", "number", "boolean", "date", "object", "array")
        $weightedTypes = @()
        
        # Ajuster les poids selon la complexité
        if ($Complexity -le 3) {
            $weightedTypes = @("string", "string", "string", "number", "number", "boolean")
        }
        elseif ($Complexity -le 7) {
            $weightedTypes = @("string", "string", "number", "number", "boolean", "date", "date", "object")
        }
        else {
            $weightedTypes = @("string", "number", "boolean", "date", "object", "object", "array", "array")
        }
        
        # Générer les éléments
        for ($i = 0; $i -lt $itemCount; $i++) {
            $item = @{}
            $propertyCount = $random.Next(2, [Math]::Min(10, $Complexity * 2))
            
            for ($j = 0; $j -lt $propertyCount; $j++) {
                $propertyName = "Property$($j + 1)"
                $typeIndex = $random.Next(0, $weightedTypes.Count)
                $type = $weightedTypes[$typeIndex]
                
                switch ($type) {
                    "string" {
                        $item[$propertyName] = "Value$($random.Next(1, 100))"
                    }
                    "number" {
                        $item[$propertyName] = $random.Next(1, 1000)
                    }
                    "boolean" {
                        $item[$propertyName] = $random.Next(0, 2) -eq 1
                    }
                    "date" {
                        $daysAgo = $random.Next(0, 365)
                        $item[$propertyName] = (Get-Date).AddDays(-$daysAgo).ToString("yyyy-MM-dd")
                    }
                    "object" {
                        if ($Complexity -gt 3) {
                            $nestedObject = @{}
                            $nestedPropertyCount = $random.Next(1, 3)
                            
                            for ($k = 0; $k -lt $nestedPropertyCount; $k++) {
                                $nestedName = "Nested$($k + 1)"
                                $nestedObject[$nestedName] = "NestedValue$($random.Next(1, 100))"
                            }
                            
                            $item[$propertyName] = $nestedObject
                        }
                        else {
                            $item[$propertyName] = "SimpleValue$($random.Next(1, 100))"
                        }
                    }
                    "array" {
                        if ($Complexity -gt 5) {
                            $array = @()
                            $arraySize = $random.Next(1, 5)
                            
                            for ($k = 0; $k -lt $arraySize; $k++) {
                                $array += "ArrayItem$($k + 1)"
                            }
                            
                            $item[$propertyName] = $array
                        }
                        else {
                            $item[$propertyName] = "SimpleValue$($random.Next(1, 100))"
                        }
                    }
                }
            }
            
            $data += $item
        }
        
        return $data
    }

    # Créer l'objet générateur
    $generator = [PSCustomObject]@{
        Configuration = $Configuration
        
        # Méthode pour générer des données textuelles
        GenerateTextData = {
            param (
                [int]$Count = 1,
                [hashtable]$OverrideConfig = @{}
            )
            
            $config = $this.Configuration.Clone()
            foreach ($key in $OverrideConfig.Keys) {
                $config[$key] = $OverrideConfig[$key]
            }
            
            $result = @()
            
            for ($i = 0; $i -lt $Count; $i++) {
                $language = Get-RandomLanguage -Distribution $config.LanguageDistribution
                $confidenceScore = Get-RandomConfidenceScore -Min $config.ConfidenceScoreRange[0] -Max $config.ConfidenceScoreRange[1]
                $metadata = Get-RandomMetadata -Fields $config.MetadataFields -Complexity $config.DataComplexity
                
                $textInfo = @{
                    _Type = "TextExtractedInfo"
                    Id = [guid]::NewGuid().ToString()
                    Source = "synthetic_text_$($i + 1).txt"
                    Text = Get-RandomText -MinWords (10 * $config.DataComplexity) -MaxWords (20 * $config.DataComplexity) -Complexity $config.DataComplexity
                    Language = $language
                    ConfidenceScore = $confidenceScore
                    ExtractedAt = Get-Date
                    ProcessingState = "Processed"
                    Metadata = $metadata
                }
                
                $result += $textInfo
            }
            
            return $result
        }
        
        # Méthode pour générer des données structurées
        GenerateStructuredData = {
            param (
                [int]$Count = 1,
                [hashtable]$OverrideConfig = @{}
            )
            
            $config = $this.Configuration.Clone()
            foreach ($key in $OverrideConfig.Keys) {
                $config[$key] = $OverrideConfig[$key]
            }
            
            $result = @()
            
            for ($i = 0; $i -lt $Count; $i++) {
                $confidenceScore = Get-RandomConfidenceScore -Min $config.ConfidenceScoreRange[0] -Max $config.ConfidenceScoreRange[1]
                $metadata = Get-RandomMetadata -Fields $config.MetadataFields -Complexity $config.DataComplexity
                $dataFormat = if ($random.Next(0, 2) -eq 0) { "Json" } else { "Xml" }
                
                $structuredInfo = @{
                    _Type = "StructuredDataExtractedInfo"
                    Id = [guid]::NewGuid().ToString()
                    Source = "synthetic_data_$($i + 1).$($dataFormat.ToLower())"
                    Data = Get-RandomStructuredData -MinItems 1 -MaxItems $config.DataComplexity -Complexity $config.DataComplexity
                    DataFormat = $dataFormat
                    ConfidenceScore = $confidenceScore
                    ExtractedAt = Get-Date
                    ProcessingState = "Processed"
                    Metadata = $metadata
                }
                
                $result += $structuredInfo
            }
            
            return $result
        }
        
        # Méthode pour générer un mélange de données
        GenerateMixedData = {
            param (
                [int]$Count = 10,
                [hashtable]$OverrideConfig = @{}
            )
            
            $config = $this.Configuration.Clone()
            foreach ($key in $OverrideConfig.Keys) {
                $config[$key] = $OverrideConfig[$key]
            }
            
            $textCount = [Math]::Round($Count * $config.TextRatio)
            $structuredCount = $Count - $textCount
            
            $textData = $this.GenerateTextData.Invoke($textCount, $OverrideConfig)
            $structuredData = $this.GenerateStructuredData.Invoke($structuredCount, $OverrideConfig)
            
            # Mélanger les résultats
            $result = @($textData) + @($structuredData) | Sort-Object { $random.Next() }
            
            return $result
        }
        
        # Méthode pour générer une collection complète
        GenerateCollection = {
            param (
                [int]$ItemCount = 10,
                [string]$Name = "Synthetic Collection",
                [string]$Description = "Collection de données synthétiques générée pour les tests",
                [hashtable]$OverrideConfig = @{}
            )
            
            $mixedData = $this.GenerateMixedData.Invoke($ItemCount, $OverrideConfig)
            
            $collection = @{
                Name = $Name
                Description = $Description
                CreatedAt = Get-Date
                Items = @{}
            }
            
            foreach ($item in $mixedData) {
                $collection.Items[$item.Id] = $item
            }
            
            return $collection
        }
        
        # Méthode pour exporter une collection vers un fichier
        ExportCollection = {
            param (
                [hashtable]$Collection,
                [string]$OutputPath,
                [string]$Format = "JSON"
            )
            
            if (-not (Test-Path -Path (Split-Path -Path $OutputPath -Parent))) {
                New-Item -Path (Split-Path -Path $OutputPath -Parent) -ItemType Directory -Force | Out-Null
            }
            
            switch ($Format.ToUpper()) {
                "JSON" {
                    $Collection | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                "CSV" {
                    $flatItems = @()
                    foreach ($item in $Collection.Items.Values) {
                        $flatItem = [PSCustomObject]@{
                            Id = $item.Id
                            Type = $item._Type
                            Source = $item.Source
                            ConfidenceScore = $item.ConfidenceScore
                            ExtractedAt = $item.ExtractedAt
                            ProcessingState = $item.ProcessingState
                        }
                        
                        if ($item._Type -eq "TextExtractedInfo") {
                            Add-Member -InputObject $flatItem -MemberType NoteProperty -Name "Text" -Value $item.Text
                            Add-Member -InputObject $flatItem -MemberType NoteProperty -Name "Language" -Value $item.Language
                        }
                        else {
                            Add-Member -InputObject $flatItem -MemberType NoteProperty -Name "DataFormat" -Value $item.DataFormat
                            Add-Member -InputObject $flatItem -MemberType NoteProperty -Name "DataSummary" -Value "$(($item.Data | ConvertTo-Json -Compress).Substring(0, [Math]::Min(50, ($item.Data | ConvertTo-Json -Compress).Length)))..."
                        }
                        
                        $flatItems += $flatItem
                    }
                    
                    $flatItems | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
                "XML" {
                    # Convertir en XML simple
                    $xmlWriter = New-Object System.XMl.XmlTextWriter($OutputPath, [System.Text.Encoding]::UTF8)
                    $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
                    $xmlWriter.WriteStartDocument()
                    
                    $xmlWriter.WriteStartElement("Collection")
                    $xmlWriter.WriteAttributeString("Name", $Collection.Name)
                    $xmlWriter.WriteAttributeString("Description", $Collection.Description)
                    $xmlWriter.WriteAttributeString("CreatedAt", $Collection.CreatedAt.ToString("o"))
                    
                    $xmlWriter.WriteStartElement("Items")
                    
                    foreach ($item in $Collection.Items.Values) {
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
                default {
                    throw "Format non pris en charge: $Format. Utilisez JSON, CSV ou XML."
                }
            }
            
            return $OutputPath
        }
    }
    
    return $generator
}
