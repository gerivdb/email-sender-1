# Points d'intégration du module ExtractedInfoModuleV2

Ce document détaille les points d'intégration disponibles dans le module ExtractedInfoModuleV2, permettant d'étendre ses fonctionnalités et de l'intégrer avec d'autres systèmes.

## Points d'extension du module

Le module ExtractedInfoModuleV2 a été conçu avec une architecture extensible, offrant plusieurs points d'extension pour personnaliser son comportement sans modifier le code source.

### 1. Types d'information extraite personnalisés

Vous pouvez créer vos propres types d'information extraite en étendant les types de base :

```powershell
# Définir un nouveau type d'information extraite
function New-CustomExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        
        [Parameter(Mandatory = $true)]
        [string]$CustomProperty1,
        
        [Parameter(Mandatory = $true)]
        [int]$CustomProperty2
    )
    
    # Créer un objet de base
    $info = New-GenericExtractedInfo -Source $Source
    
    # Ajouter les propriétés spécifiques
    $info._Type = "CustomExtractedInfo"
    $info.CustomProperty1 = $CustomProperty1
    $info.CustomProperty2 = $CustomProperty2
    
    # Retourner l'objet
    return $info
}

# Enregistrer le type personnalisé
Register-ExtractedInfoType -TypeName "CustomExtractedInfo" -CreationFunction ${function:New-CustomExtractedInfo}
```

### 2. Validateurs personnalisés

Vous pouvez créer des validateurs personnalisés pour vérifier l'intégrité des objets d'information extraite :

```powershell
# Définir un validateur personnalisé
function Test-CustomExtractedInfo {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )
    
    # Vérifier le type
    if ($Info._Type -ne "CustomExtractedInfo") {
        return $false
    }
    
    # Vérifier les propriétés requises
    if (-not $Info.ContainsKey("CustomProperty1") -or -not $Info.ContainsKey("CustomProperty2")) {
        return $false
    }
    
    # Vérifier les types de données
    if (-not ($Info.CustomProperty1 -is [string]) -or -not ($Info.CustomProperty2 -is [int])) {
        return $false
    }
    
    # Vérifier les contraintes métier
    if ($Info.CustomProperty2 -lt 0 -or $Info.CustomProperty2 -gt 100) {
        return $false
    }
    
    return $true
}

# Enregistrer le validateur personnalisé
Register-ExtractedInfoValidator -TypeName "CustomExtractedInfo" -ValidationFunction ${function:Test-CustomExtractedInfo}
```

### 3. Adaptateurs d'exportation personnalisés

Vous pouvez créer des adaptateurs d'exportation personnalisés pour prendre en charge de nouveaux formats :

```powershell
# Définir un adaptateur d'exportation personnalisé
function Export-CustomFormat {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Créer le format personnalisé
    $result = "CUSTOM_FORMAT_V1`n"
    $result += "TYPE: $($Info._Type)`n"
    $result += "SOURCE: $($Info.Source)`n"
    
    # Ajouter les propriétés spécifiques au type
    switch ($Info._Type) {
        "TextExtractedInfo" {
            $result += "TEXT: $($Info.Text)`n"
            $result += "LANGUAGE: $($Info.Language)`n"
        }
        "StructuredDataExtractedInfo" {
            $result += "DATA_FORMAT: $($Info.DataFormat)`n"
            $result += "DATA: " + (ConvertTo-Json -InputObject $Info.Data -Compress) + "`n"
        }
        # Autres types...
    }
    
    # Ajouter les métadonnées si demandé
    if ($IncludeMetadata -and $Info.ContainsKey("Metadata")) {
        $result += "METADATA: " + (ConvertTo-Json -InputObject $Info.Metadata -Compress) + "`n"
    }
    
    # Écrire dans un fichier si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $result | Out-File -FilePath $OutputPath -Encoding utf8
        return $null
    }
    
    return $result
}

# Enregistrer l'adaptateur d'exportation personnalisé
Register-ExtractedInfoExporter -FormatName "Custom" -ExportFunction ${function:Export-CustomFormat}
```

### 4. Processeurs personnalisés

Vous pouvez créer des processeurs personnalisés pour transformer les objets d'information extraite :

```powershell
# Définir un processeur personnalisé
function Process-TextExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )
    
    # Vérifier le type
    if ($Info._Type -ne "TextExtractedInfo") {
        throw "Ce processeur ne peut traiter que les objets de type TextExtractedInfo."
    }
    
    # Transformer le texte
    $processedText = $Info.Text.ToUpper()
    
    # Créer un nouvel objet avec le texte transformé
    $processedInfo = $Info.Clone()
    $processedInfo.Text = $processedText
    
    # Ajouter des métadonnées de traitement
    if (-not $processedInfo.ContainsKey("Metadata")) {
        $processedInfo.Metadata = @{}
    }
    
    $processedInfo.Metadata["ProcessedBy"] = "TextProcessor"
    $processedInfo.Metadata["ProcessedAt"] = Get-Date
    
    return $processedInfo
}

# Enregistrer le processeur personnalisé
Register-ExtractedInfoProcessor -TypeName "TextExtractedInfo" -ProcessorName "Uppercase" -ProcessFunction ${function:Process-TextExtractedInfo}
```

## Utilisation des événements et hooks

Le module ExtractedInfoModuleV2 utilise un système d'événements pour permettre l'exécution de code personnalisé à des moments clés du cycle de vie des objets d'information extraite.

### 1. Événements disponibles

Le module expose les événements suivants :

| Événement | Description | Paramètres |
|-----------|-------------|------------|
| `OnInfoCreated` | Déclenché après la création d'un objet d'information extraite | `$Info` : L'objet créé |
| `OnInfoValidated` | Déclenché après la validation d'un objet | `$Info` : L'objet validé<br>`$IsValid` : Résultat de la validation |
| `OnInfoExported` | Déclenché après l'exportation d'un objet | `$Info` : L'objet exporté<br>`$Format` : Format d'exportation<br>`$Result` : Résultat de l'exportation |
| `OnInfoProcessed` | Déclenché après le traitement d'un objet | `$OriginalInfo` : L'objet original<br>`$ProcessedInfo` : L'objet traité |
| `OnCollectionModified` | Déclenché après la modification d'une collection | `$Collection` : La collection modifiée<br>`$Operation` : Type d'opération (Add, Remove, Clear) |

### 2. Enregistrement des gestionnaires d'événements

Vous pouvez enregistrer des gestionnaires d'événements pour exécuter du code personnalisé :

```powershell
# Enregistrer un gestionnaire pour l'événement OnInfoCreated
Register-ExtractedInfoEventHandler -Event "OnInfoCreated" -Name "LogCreation" -ScriptBlock {
    param($Info)
    
    Write-Log -Message "Nouvel objet créé : $($Info._Type) - $($Info.Id)" -Level Info
}

# Enregistrer un gestionnaire pour l'événement OnInfoValidated
Register-ExtractedInfoEventHandler -Event "OnInfoValidated" -Name "NotifyInvalidInfo" -ScriptBlock {
    param($Info, $IsValid)
    
    if (-not $IsValid) {
        Write-Log -Message "Objet invalide détecté : $($Info._Type) - $($Info.Id)" -Level Warning
        Send-Email -To "admin@example.com" -Subject "Objet invalide détecté" -Body "Un objet invalide a été détecté : $($Info | ConvertTo-Json -Depth 3)"
    }
}

# Enregistrer un gestionnaire pour l'événement OnCollectionModified
Register-ExtractedInfoEventHandler -Event "OnCollectionModified" -Name "UpdateDatabase" -ScriptBlock {
    param($Collection, $Operation)
    
    Write-Log -Message "Collection modifiée : $($Collection.Name) - Opération : $Operation" -Level Info
    
    # Mettre à jour la base de données
    switch ($Operation) {
        "Add" {
            # Code pour ajouter à la base de données
        }
        "Remove" {
            # Code pour supprimer de la base de données
        }
        "Clear" {
            # Code pour vider la table dans la base de données
        }
    }
}
```

### 3. Suppression des gestionnaires d'événements

Vous pouvez supprimer des gestionnaires d'événements lorsqu'ils ne sont plus nécessaires :

```powershell
# Supprimer un gestionnaire spécifique
Unregister-ExtractedInfoEventHandler -Event "OnInfoCreated" -Name "LogCreation"

# Supprimer tous les gestionnaires pour un événement
Unregister-ExtractedInfoEventHandler -Event "OnInfoValidated" -All

# Supprimer tous les gestionnaires
Unregister-ExtractedInfoEventHandler -All
```

### 4. Hooks personnalisés

En plus des événements standard, vous pouvez définir des hooks personnalisés pour des points d'extension spécifiques :

```powershell
# Définir un hook personnalisé
function Add-CustomHook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HookName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    # Vérifier si la variable globale existe
    if (-not (Get-Variable -Name "ExtractedInfoHooks" -Scope Global -ErrorAction SilentlyContinue)) {
        $global:ExtractedInfoHooks = @{}
    }
    
    # Ajouter le hook
    if (-not $global:ExtractedInfoHooks.ContainsKey($HookName)) {
        $global:ExtractedInfoHooks[$HookName] = @()
    }
    
    $global:ExtractedInfoHooks[$HookName] += $ScriptBlock
}

# Exécuter un hook personnalisé
function Invoke-CustomHook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HookName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    # Vérifier si la variable globale existe
    if (-not (Get-Variable -Name "ExtractedInfoHooks" -Scope Global -ErrorAction SilentlyContinue)) {
        return
    }
    
    # Vérifier si le hook existe
    if (-not $global:ExtractedInfoHooks.ContainsKey($HookName)) {
        return
    }
    
    # Exécuter tous les scripts enregistrés pour ce hook
    foreach ($scriptBlock in $global:ExtractedInfoHooks[$HookName]) {
        try {
            & $scriptBlock @Parameters
        }
        catch {
            Write-Warning "Erreur lors de l'exécution du hook '$HookName' : $_"
        }
    }
}

# Exemple d'utilisation
Add-CustomHook -HookName "BeforeExport" -ScriptBlock {
    param($Info, $Format)
    
    Write-Log -Message "Préparation de l'exportation de l'objet $($Info.Id) au format $Format" -Level Info
    
    # Prétraitement avant exportation
    if ($Format -eq "Json" -and $Info._Type -eq "TextExtractedInfo") {
        # Nettoyer le texte avant l'exportation
        $Info.Text = $Info.Text -replace '[^\p{L}\p{N}\p{P}\p{Z}]', ''
    }
}

# Appel du hook
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
Invoke-CustomHook -HookName "BeforeExport" -Parameters @{
    Info = $info
    Format = "Json"
}
```

## Interfaces d'intégration

Le module ExtractedInfoModuleV2 expose plusieurs interfaces d'intégration pour faciliter l'interaction avec d'autres systèmes.

### 1. Interface de stockage

L'interface de stockage permet de persister les objets d'information extraite dans différents systèmes de stockage :

```powershell
# Définir une interface de stockage personnalisée
class CustomStorageProvider : IExtractedInfoStorageProvider {
    # Propriétés
    [string]$ConnectionString
    
    # Constructeur
    CustomStorageProvider([string]$connectionString) {
        $this.ConnectionString = $connectionString
    }
    
    # Méthodes de l'interface
    [void] SaveInfo([hashtable]$Info) {
        # Code pour sauvegarder l'objet dans le système de stockage
        $json = ConvertTo-Json -InputObject $Info -Depth 10
        # Exemple : sauvegarder dans une base de données
        Invoke-SqlQuery -Query "INSERT INTO ExtractedInfo (Id, Type, Content) VALUES (@Id, @Type, @Content)" -Parameters @{
            Id = $Info.Id
            Type = $Info._Type
            Content = $json
        } -ConnectionString $this.ConnectionString
    }
    
    [hashtable] LoadInfo([string]$Id) {
        # Code pour charger l'objet depuis le système de stockage
        $result = Invoke-SqlQuery -Query "SELECT Content FROM ExtractedInfo WHERE Id = @Id" -Parameters @{
            Id = $Id
        } -ConnectionString $this.ConnectionString
        
        if ($result.Rows.Count -eq 0) {
            throw "Objet non trouvé : $Id"
        }
        
        return (ConvertFrom-Json -InputObject $result.Rows[0].Content -AsHashtable)
    }
    
    [void] DeleteInfo([string]$Id) {
        # Code pour supprimer l'objet du système de stockage
        Invoke-SqlQuery -Query "DELETE FROM ExtractedInfo WHERE Id = @Id" -Parameters @{
            Id = $Id
        } -ConnectionString $this.ConnectionString
    }
    
    [string[]] ListInfoIds() {
        # Code pour lister tous les IDs disponibles
        $result = Invoke-SqlQuery -Query "SELECT Id FROM ExtractedInfo" -ConnectionString $this.ConnectionString
        return $result.Rows | ForEach-Object { $_.Id }
    }
}

# Enregistrer le fournisseur de stockage personnalisé
Register-ExtractedInfoStorageProvider -Name "CustomDB" -Provider ([CustomStorageProvider]::new("Server=localhost;Database=ExtractedInfo;Trusted_Connection=True;"))

# Utiliser le fournisseur de stockage
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
Save-ExtractedInfo -Info $info -ProviderName "CustomDB"
$loadedInfo = Get-ExtractedInfo -Id $info.Id -ProviderName "CustomDB"
```

### 2. Interface de traitement

L'interface de traitement permet d'intégrer des processeurs personnalisés dans le pipeline de traitement :

```powershell
# Définir une interface de traitement personnalisée
class CustomProcessor : IExtractedInfoProcessor {
    # Propriétés
    [string]$Name
    [string[]]$SupportedTypes
    
    # Constructeur
    CustomProcessor([string]$name, [string[]]$supportedTypes) {
        $this.Name = $name
        $this.SupportedTypes = $supportedTypes
    }
    
    # Méthodes de l'interface
    [bool] CanProcess([hashtable]$Info) {
        return $this.SupportedTypes -contains $Info._Type
    }
    
    [hashtable] Process([hashtable]$Info) {
        # Code pour traiter l'objet
        $processedInfo = $Info.Clone()
        
        # Exemple de traitement
        switch ($Info._Type) {
            "TextExtractedInfo" {
                # Traitement spécifique pour le texte
                $processedInfo.Text = $this.ProcessText($Info.Text)
            }
            "StructuredDataExtractedInfo" {
                # Traitement spécifique pour les données structurées
                $processedInfo.Data = $this.ProcessData($Info.Data)
            }
        }
        
        # Ajouter des métadonnées de traitement
        if (-not $processedInfo.ContainsKey("Metadata")) {
            $processedInfo.Metadata = @{}
        }
        
        $processedInfo.Metadata["ProcessedBy"] = $this.Name
        $processedInfo.Metadata["ProcessedAt"] = Get-Date
        
        return $processedInfo
    }
    
    # Méthodes internes
    hidden [string] ProcessText([string]$text) {
        # Exemple : nettoyer et normaliser le texte
        $text = $text -replace '\s+', ' '
        $text = $text.Trim()
        return $text
    }
    
    hidden [object] ProcessData([object]$data) {
        # Exemple : traiter les données structurées
        if ($data -is [hashtable]) {
            $processedData = $data.Clone()
            # Traitement spécifique
            return $processedData
        }
        
        return $data
    }
}

# Enregistrer le processeur personnalisé
Register-ExtractedInfoProcessor -Processor ([CustomProcessor]::new("TextCleaner", @("TextExtractedInfo", "StructuredDataExtractedInfo")))

# Utiliser le processeur
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu   du   document" -Language "fr"
$processedInfo = Process-ExtractedInfo -Info $info -ProcessorName "TextCleaner"
```

### 3. Interface d'analyse

L'interface d'analyse permet d'intégrer des analyseurs personnalisés pour extraire des informations supplémentaires :

```powershell
# Définir une interface d'analyse personnalisée
class CustomAnalyzer : IExtractedInfoAnalyzer {
    # Propriétés
    [string]$Name
    [string[]]$SupportedTypes
    
    # Constructeur
    CustomAnalyzer([string]$name, [string[]]$supportedTypes) {
        $this.Name = $name
        $this.SupportedTypes = $supportedTypes
    }
    
    # Méthodes de l'interface
    [bool] CanAnalyze([hashtable]$Info) {
        return $this.SupportedTypes -contains $Info._Type
    }
    
    [hashtable] Analyze([hashtable]$Info) {
        # Code pour analyser l'objet
        $analysisResults = @{}
        
        # Exemple d'analyse
        switch ($Info._Type) {
            "TextExtractedInfo" {
                # Analyse spécifique pour le texte
                $analysisResults = $this.AnalyzeText($Info.Text)
            }
            "StructuredDataExtractedInfo" {
                # Analyse spécifique pour les données structurées
                $analysisResults = $this.AnalyzeData($Info.Data)
            }
        }
        
        return $analysisResults
    }
    
    # Méthodes internes
    hidden [hashtable] AnalyzeText([string]$text) {
        # Exemple : analyser le texte
        $wordCount = ($text -split '\s+').Count
        $charCount = $text.Length
        $sentenceCount = ($text -split '[.!?]+').Count
        
        return @{
            WordCount = $wordCount
            CharacterCount = $charCount
            SentenceCount = $sentenceCount
            AverageWordLength = if ($wordCount -gt 0) { $charCount / $wordCount } else { 0 }
        }
    }
    
    hidden [hashtable] AnalyzeData([object]$data) {
        # Exemple : analyser les données structurées
        $analysis = @{
            ItemCount = 0
            Types = @{}
        }
        
        if ($data -is [hashtable]) {
            $analysis.ItemCount = $data.Count
            
            foreach ($key in $data.Keys) {
                $type = if ($null -eq $data[$key]) { "Null" } else { $data[$key].GetType().Name }
                
                if (-not $analysis.Types.ContainsKey($type)) {
                    $analysis.Types[$type] = 0
                }
                
                $analysis.Types[$type]++
            }
        }
        
        return $analysis
    }
}

# Enregistrer l'analyseur personnalisé
Register-ExtractedInfoAnalyzer -Analyzer ([CustomAnalyzer]::new("ContentAnalyzer", @("TextExtractedInfo", "StructuredDataExtractedInfo")))

# Utiliser l'analyseur
$info = New-TextExtractedInfo -Source "document.txt" -Text "Ceci est un exemple de texte. Il contient plusieurs phrases. Chaque phrase a un sens." -Language "fr"
$analysis = Analyze-ExtractedInfo -Info $info -AnalyzerName "ContentAnalyzer"
```

## Formats d'échange de données

Le module ExtractedInfoModuleV2 prend en charge plusieurs formats d'échange de données pour faciliter l'interopérabilité avec d'autres systèmes.

### 1. Format JSON

Le format JSON est le format d'échange principal du module :

```powershell
# Exporter au format JSON
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
$json = Export-ExtractedInfo -Info $info -Format "Json"

# Structure JSON
<#
{
    "_Type": "TextExtractedInfo",
    "Id": "00000000-0000-0000-0000-000000000000",
    "Source": "document.txt",
    "Text": "Contenu du document",
    "Language": "fr",
    "ConfidenceScore": 100,
    "ExtractedAt": "2025-05-15T10:00:00Z",
    "ProcessingState": "New",
    "Metadata": {
        "CreatedBy": "ExtractedInfoModuleV2",
        "CreatedAt": "2025-05-15T10:00:00Z"
    }
}
#>

# Importer depuis JSON
$importedInfo = Import-ExtractedInfo -Content $json -Format "Json"
```

### 2. Format XML

Le format XML est également pris en charge pour l'interopérabilité avec les systèmes basés sur XML :

```powershell
# Exporter au format XML
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
$xml = Export-ExtractedInfo -Info $info -Format "Xml"

# Structure XML
<#
<ExtractedInfo>
    <_Type>TextExtractedInfo</_Type>
    <Id>00000000-0000-0000-0000-000000000000</Id>
    <Source>document.txt</Source>
    <Text>Contenu du document</Text>
    <Language>fr</Language>
    <ConfidenceScore>100</ConfidenceScore>
    <ExtractedAt>2025-05-15T10:00:00Z</ExtractedAt>
    <ProcessingState>New</ProcessingState>
    <Metadata>{"CreatedBy":"ExtractedInfoModuleV2","CreatedAt":"2025-05-15T10:00:00Z"}</Metadata>
</ExtractedInfo>
#>

# Importer depuis XML
$importedInfo = Import-ExtractedInfo -Content $xml -Format "Xml"
```

### 3. Format CSV

Le format CSV est pris en charge pour les données structurées :

```powershell
# Exporter au format CSV (pour les données structurées)
$data = @(
    [PSCustomObject]@{ Name = "John"; Age = 30; Email = "john@example.com" },
    [PSCustomObject]@{ Name = "Jane"; Age = 25; Email = "jane@example.com" }
)
$info = New-StructuredDataExtractedInfo -Source "data.csv" -Data $data -DataFormat "Csv"

# Exporter les données au format CSV
$csv = $info.Data | ConvertTo-Csv -NoTypeInformation

# Structure CSV
<#
"Name","Age","Email"
"John","30","john@example.com"
"Jane","25","jane@example.com"
#>

# Importer depuis CSV
$csvData = ConvertFrom-Csv -InputObject $csv
$importedInfo = New-StructuredDataExtractedInfo -Source "imported.csv" -Data $csvData -DataFormat "Csv"
```

### 4. Format personnalisé

Vous pouvez définir des formats personnalisés pour des besoins spécifiques :

```powershell
# Définir un format personnalisé
function Export-CustomYamlFormat {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Créer le format YAML
    $yaml = "---`n"
    $yaml += "type: $($Info._Type)`n"
    $yaml += "id: $($Info.Id)`n"
    $yaml += "source: $($Info.Source)`n"
    
    # Ajouter les propriétés spécifiques au type
    switch ($Info._Type) {
        "TextExtractedInfo" {
            $yaml += "text: |-`n"
            foreach ($line in ($Info.Text -split "`n")) {
                $yaml += "  $line`n"
            }
            $yaml += "language: $($Info.Language)`n"
        }
        "StructuredDataExtractedInfo" {
            $yaml += "data_format: $($Info.DataFormat)`n"
            $yaml += "data: " + (ConvertTo-Json -InputObject $Info.Data -Compress) + "`n"
        }
    }
    
    # Ajouter les métadonnées si demandé
    if ($IncludeMetadata -and $Info.ContainsKey("Metadata")) {
        $yaml += "metadata:`n"
        foreach ($key in $Info.Metadata.Keys) {
            $value = $Info.Metadata[$key]
            $yaml += "  $key: $value`n"
        }
    }
    
    # Écrire dans un fichier si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $yaml | Out-File -FilePath $OutputPath -Encoding utf8
        return $null
    }
    
    return $yaml
}

# Enregistrer le format personnalisé
Register-ExtractedInfoExporter -FormatName "Yaml" -ExportFunction ${function:Export-CustomYamlFormat}

# Utiliser le format personnalisé
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
$yaml = Export-ExtractedInfo -Info $info -Format "Yaml"
```

Ces points d'intégration vous permettent d'étendre les fonctionnalités du module ExtractedInfoModuleV2 et de l'intégrer avec d'autres systèmes de manière flexible et modulaire.
