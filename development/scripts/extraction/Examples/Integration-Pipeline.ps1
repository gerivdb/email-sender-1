#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'intégration du module ExtractedInfoModuleV2 avec un pipeline de traitement.

.DESCRIPTION
Ce script montre comment intégrer le module ExtractedInfoModuleV2 avec un pipeline de traitement
pour automatiser l'extraction, la transformation et le chargement (ETL) d'informations.

.NOTES
Date de création : 2025-05-15
#>

# Importer les modules nécessaires
Import-Module ExtractedInfoModuleV2
# Note: Les modules de traitement sont fictifs et utilisés à des fins d'exemple
# Import-Module TextProcessing
# Import-Module DataTransformation
# Import-Module Reporting

#region Définition des étapes du pipeline

# Étape 1: Extraction des données
function Extract-DataFromSources {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    Write-Verbose "Extraction des données depuis $($Sources.Count) sources"
    
    $extractedInfoCollection = New-ExtractedInfoCollection -Name "Données extraites"
    
    foreach ($source in $Sources) {
        Write-Verbose "Traitement de la source : $source"
        
        try {
            # Déterminer le type de source et extraire les données en conséquence
            if ($source -like "*.txt") {
                # Extraire du texte
                $content = Get-Content -Path $source -Raw -ErrorAction Stop
                $info = New-TextExtractedInfo -Source $source -Text $content -Language "fr"
            }
            elseif ($source -like "*.json") {
                # Extraire des données structurées
                $content = Get-Content -Path $source -Raw -ErrorAction Stop
                $data = ConvertFrom-Json -InputObject $content
                $info = New-StructuredDataExtractedInfo -Source $source -Data $data -DataFormat "Json"
            }
            elseif ($source -like "*.csv") {
                # Extraire des données CSV
                $data = Import-Csv -Path $source -ErrorAction Stop
                $info = New-StructuredDataExtractedInfo -Source $source -Data $data -DataFormat "Csv"
            }
            elseif ($source -like "http*") {
                # Simuler l'extraction depuis une URL
                $info = @{
                    _Type = "TextExtractedInfo"
                    Id = [guid]::NewGuid().ToString()
                    Source = $source
                    Text = "Contenu extrait depuis $source"
                    Language = "fr"
                    ConfidenceScore = 85
                    ExtractedAt = Get-Date
                    ProcessingState = "New"
                }
            }
            else {
                Write-Warning "Type de source non pris en charge : $source"
                continue
            }
            
            # Ajouter des métadonnées d'extraction
            $info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
                ExtractedBy = "Pipeline"
                ExtractedAt = Get-Date
                Parameters = $Parameters
            }
            
            # Ajouter l'information extraite à la collection
            $extractedInfoCollection = Add-ExtractedInfoToCollection -Collection $extractedInfoCollection -Info $info
            
            Write-Verbose "Information extraite avec succès depuis $source"
        }
        catch {
            Write-Error "Erreur lors de l'extraction depuis $source : $_"
        }
    }
    
    return $extractedInfoCollection
}

# Étape 2: Transformation des données
function Transform-ExtractedData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Collection,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Transformations = @("Normalize", "Clean", "Enrich"),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    Write-Verbose "Transformation des données de la collection $($Collection.Name)"
    
    $transformedCollection = New-ExtractedInfoCollection -Name "$($Collection.Name) - Transformé"
    
    foreach ($infoId in $Collection.Items.Keys) {
        $info = $Collection.Items[$infoId]
        $transformedInfo = $info.Clone()
        
        Write-Verbose "Application des transformations à l'objet $($info.Id)"
        
        foreach ($transformation in $Transformations) {
            Write-Verbose "Application de la transformation : $transformation"
            
            try {
                switch ($transformation) {
                    "Normalize" {
                        # Normalisation des données selon le type
                        switch ($transformedInfo._Type) {
                            "TextExtractedInfo" {
                                # Normaliser le texte
                                $transformedInfo.Text = $transformedInfo.Text -replace '\s+', ' '
                                $transformedInfo.Text = $transformedInfo.Text.Trim()
                            }
                            "StructuredDataExtractedInfo" {
                                # Normaliser les données structurées
                                if ($transformedInfo.Data -is [array]) {
                                    # Normaliser chaque élément du tableau
                                    for ($i = 0; $i -lt $transformedInfo.Data.Count; $i++) {
                                        if ($transformedInfo.Data[$i] -is [hashtable] -or $transformedInfo.Data[$i] -is [PSCustomObject]) {
                                            # Normaliser les propriétés
                                            foreach ($prop in $transformedInfo.Data[$i].PSObject.Properties) {
                                                if ($prop.Value -is [string]) {
                                                    $prop.Value = $prop.Value.Trim()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    "Clean" {
                        # Nettoyage des données selon le type
                        switch ($transformedInfo._Type) {
                            "TextExtractedInfo" {
                                # Nettoyer le texte
                                $transformedInfo.Text = $transformedInfo.Text -replace '[^\p{L}\p{N}\p{P}\p{Z}]', ''
                            }
                            "StructuredDataExtractedInfo" {
                                # Nettoyer les données structurées
                                # Implémentation spécifique selon les besoins
                            }
                        }
                    }
                    "Enrich" {
                        # Enrichissement des données selon le type
                        switch ($transformedInfo._Type) {
                            "TextExtractedInfo" {
                                # Enrichir le texte avec des métadonnées supplémentaires
                                $wordCount = ($transformedInfo.Text -split '\s+').Count
                                $charCount = $transformedInfo.Text.Length
                                
                                if (-not $transformedInfo.ContainsKey('Metadata')) {
                                    $transformedInfo.Metadata = @{}
                                }
                                
                                $transformedInfo.Metadata["WordCount"] = $wordCount
                                $transformedInfo.Metadata["CharacterCount"] = $charCount
                                $transformedInfo.Metadata["AverageWordLength"] = if ($wordCount -gt 0) { $charCount / $wordCount } else { 0 }
                            }
                            "StructuredDataExtractedInfo" {
                                # Enrichir les données structurées
                                # Implémentation spécifique selon les besoins
                            }
                        }
                    }
                    default {
                        Write-Warning "Transformation non reconnue : $transformation"
                    }
                }
            }
            catch {
                Write-Error "Erreur lors de l'application de la transformation $transformation à l'objet $($info.Id) : $_"
            }
        }
        
        # Mettre à jour les métadonnées de transformation
        if (-not $transformedInfo.ContainsKey('Metadata')) {
            $transformedInfo.Metadata = @{}
        }
        
        $transformedInfo.Metadata["TransformedBy"] = "Pipeline"
        $transformedInfo.Metadata["TransformedAt"] = Get-Date
        $transformedInfo.Metadata["AppliedTransformations"] = $Transformations
        $transformedInfo.Metadata["TransformationParameters"] = $Parameters
        
        # Mettre à jour l'état de traitement
        $transformedInfo.ProcessingState = "Processed"
        
        # Ajouter l'information transformée à la collection
        $transformedCollection = Add-ExtractedInfoToCollection -Collection $transformedCollection -Info $transformedInfo
        
        Write-Verbose "Transformation terminée pour l'objet $($info.Id)"
    }
    
    return $transformedCollection
}

# Étape 3: Chargement des données
function Load-TransformedData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Collection,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("File", "Database", "API")]
        [string]$DestinationType,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    Write-Verbose "Chargement des données de la collection $($Collection.Name) vers $DestinationType : $Destination"
    
    $results = @{
        SuccessCount = 0
        FailureCount = 0
        Errors = @()
    }
    
    foreach ($infoId in $Collection.Items.Keys) {
        $info = $Collection.Items[$infoId]
        
        Write-Verbose "Chargement de l'objet $($info.Id)"
        
        try {
            switch ($DestinationType) {
                "File" {
                    # Déterminer le format de fichier en fonction de l'extension
                    $extension = [System.IO.Path]::GetExtension($Destination)
                    $format = switch ($extension) {
                        ".json" { "Json" }
                        ".xml" { "Xml" }
                        ".md" { "Markdown" }
                        ".txt" { "Text" }
                        default { "Json" }
                    }
                    
                    # Créer le dossier de destination s'il n'existe pas
                    $folder = [System.IO.Path]::GetDirectoryName($Destination)
                    if (-not (Test-Path -Path $folder)) {
                        New-Item -Path $folder -ItemType Directory -Force | Out-Null
                    }
                    
                    # Exporter l'objet dans le format approprié
                    $filePath = Join-Path -Path $folder -ChildPath "$($info.Id)$extension"
                    Export-ExtractedInfo -Info $info -Format $format -OutputPath $filePath
                    
                    Write-Verbose "Objet exporté vers $filePath"
                }
                "Database" {
                    # Simuler l'insertion dans une base de données
                    # Dans un cas réel, on utiliserait une fonction spécifique au type de base de données
                    Write-Verbose "Simulation de l'insertion dans la base de données $Destination"
                    
                    # Exemple de code pour SQL Server
                    <#
                    $connectionString = $Parameters.ConnectionString
                    $tableName = $Parameters.TableName
                    
                    $json = ConvertTo-Json -InputObject $info -Depth 10 -Compress
                    
                    $query = @"
                    IF EXISTS (SELECT * FROM $tableName WHERE Id = '$($info.Id)')
                    BEGIN
                        UPDATE $tableName
                        SET Type = '$($info._Type)',
                            Source = '$($info.Source)',
                            Content = @Content,
                            ModifiedAt = GETDATE()
                        WHERE Id = '$($info.Id)'
                    END
                    ELSE
                    BEGIN
                        INSERT INTO $tableName (Id, Type, Source, Content, CreatedAt, ModifiedAt)
                        VALUES ('$($info.Id)', '$($info._Type)', '$($info.Source)', @Content, GETDATE(), GETDATE())
                    END
                    "@
                    
                    $sqlParams = @{
                        Content = $json
                    }
                    
                    Invoke-Sqlcmd -Query $query -ConnectionString $connectionString -Parameters $sqlParams
                    #>
                }
                "API" {
                    # Simuler l'envoi à une API
                    # Dans un cas réel, on utiliserait Invoke-RestMethod
                    Write-Verbose "Simulation de l'envoi à l'API $Destination"
                    
                    <#
                    $apiUrl = $Destination
                    $apiKey = $Parameters.ApiKey
                    
                    $headers = @{
                        "Content-Type" = "application/json"
                        "Authorization" = "Bearer $apiKey"
                    }
                    
                    $body = ConvertTo-Json -InputObject $info -Depth 10
                    
                    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
                    #>
                }
            }
            
            $results.SuccessCount++
        }
        catch {
            Write-Error "Erreur lors du chargement de l'objet $($info.Id) : $_"
            $results.FailureCount++
            $results.Errors += @{
                InfoId = $info.Id
                Error = $_.ToString()
            }
        }
    }
    
    Write-Verbose "Chargement terminé. Succès: $($results.SuccessCount), Échecs: $($results.FailureCount)"
    return $results
}
#endregion

#region Définition du pipeline complet

# Fonction pour exécuter le pipeline complet
function Invoke-ExtractedInfoPipeline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Transformations = @("Normalize", "Clean", "Enrich"),
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("File", "Database", "API")]
        [string]$DestinationType,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ExtractionParameters = @{},
        
        [Parameter(Mandatory = $false)]
        [hashtable]$TransformationParameters = @{},
        
        [Parameter(Mandatory = $false)]
        [hashtable]$LoadParameters = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport,
        
        [Parameter(Mandatory = $false)]
        [string]$ReportPath
    )
    
    Write-Host "Démarrage du pipeline de traitement..."
    $startTime = Get-Date
    
    # Étape 1: Extraction
    Write-Host "Étape 1: Extraction des données depuis $($Sources.Count) sources..."
    $extractedCollection = Extract-DataFromSources -Sources $Sources -Parameters $ExtractionParameters
    Write-Host "Extraction terminée. $($extractedCollection.Items.Count) objets extraits."
    
    # Étape 2: Transformation
    Write-Host "Étape 2: Transformation des données avec $($Transformations.Count) transformations..."
    $transformedCollection = Transform-ExtractedData -Collection $extractedCollection -Transformations $Transformations -Parameters $TransformationParameters
    Write-Host "Transformation terminée. $($transformedCollection.Items.Count) objets transformés."
    
    # Étape 3: Chargement
    Write-Host "Étape 3: Chargement des données vers $DestinationType : $Destination..."
    $loadResults = Load-TransformedData -Collection $transformedCollection -DestinationType $DestinationType -Destination $Destination -Parameters $LoadParameters
    Write-Host "Chargement terminé. Succès: $($loadResults.SuccessCount), Échecs: $($loadResults.FailureCount)"
    
    # Génération du rapport
    if ($GenerateReport) {
        Write-Host "Génération du rapport..."
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        $report = @{
            PipelineStartTime = $startTime
            PipelineEndTime = $endTime
            PipelineDuration = $duration
            SourceCount = $Sources.Count
            ExtractedCount = $extractedCollection.Items.Count
            TransformedCount = $transformedCollection.Items.Count
            LoadedSuccessCount = $loadResults.SuccessCount
            LoadedFailureCount = $loadResults.FailureCount
            Transformations = $Transformations
            DestinationType = $DestinationType
            Destination = $Destination
            Errors = $loadResults.Errors
        }
        
        if (-not [string]::IsNullOrEmpty($ReportPath)) {
            $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $ReportPath -Encoding utf8
            Write-Host "Rapport généré et enregistré dans $ReportPath"
        }
        
        return $report
    }
    
    return @{
        ExtractedCollection = $extractedCollection
        TransformedCollection = $transformedCollection
        LoadResults = $loadResults
    }
}
#endregion

# Exemple d'utilisation
function Example-PipelineIntegration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InputFolder = ".\input",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".\output",
        
        [Parameter(Mandatory = $false)]
        [string]$ReportPath = ".\report.json"
    )
    
    # Créer les dossiers s'ils n'existent pas
    if (-not (Test-Path -Path $InputFolder)) {
        New-Item -Path $InputFolder -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer des fichiers d'exemple
    $textFilePath = Join-Path -Path $InputFolder -ChildPath "example.txt"
    "Ceci est un exemple de texte à traiter. Il contient plusieurs mots et phrases." | Out-File -FilePath $textFilePath -Encoding utf8
    
    $jsonFilePath = Join-Path -Path $InputFolder -ChildPath "example.json"
    @{
        Name = "Exemple"
        Properties = @{
            Value1 = 123
            Value2 = "ABC"
        }
        Items = @(
            @{ Id = 1; Name = "Item 1" },
            @{ Id = 2; Name = "Item 2" }
        )
    } | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonFilePath -Encoding utf8
    
    # Définir les sources
    $sources = @(
        $textFilePath,
        $jsonFilePath
    )
    
    # Exécuter le pipeline
    $result = Invoke-ExtractedInfoPipeline -Sources $sources `
                                          -Transformations @("Normalize", "Clean", "Enrich") `
                                          -DestinationType "File" `
                                          -Destination $OutputFolder `
                                          -GenerateReport `
                                          -ReportPath $ReportPath
    
    # Afficher un résumé
    Write-Host "`nRésumé du pipeline :"
    Write-Host "- Durée totale : $($result.PipelineDuration.TotalSeconds) secondes"
    Write-Host "- Sources traitées : $($result.SourceCount)"
    Write-Host "- Objets extraits : $($result.ExtractedCount)"
    Write-Host "- Objets transformés : $($result.TransformedCount)"
    Write-Host "- Objets chargés avec succès : $($result.LoadedSuccessCount)"
    Write-Host "- Objets chargés avec échec : $($result.LoadedFailureCount)"
    
    return $result
}

# Exécuter l'exemple
# Example-PipelineIntegration -InputFolder "C:\Temp\Pipeline\Input" -OutputFolder "C:\Temp\Pipeline\Output" -ReportPath "C:\Temp\Pipeline\report.json"
