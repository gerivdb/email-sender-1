#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'intégration du module ExtractedInfoModuleV2 avec un module d'extraction web.

.DESCRIPTION
Ce script montre comment intégrer le module ExtractedInfoModuleV2 avec un module d'extraction web
pour créer un pipeline complet d'extraction et de traitement d'informations à partir de pages web.

.NOTES
Date de création : 2025-05-15
#>

# Importer les modules nécessaires
Import-Module ExtractedInfoModuleV2
# Note: Le module WebScrapingModule est fictif et utilisé à des fins d'exemple
# Import-Module WebScrapingModule

# Fonction pour extraire des informations d'une page web
function Get-WebPageInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    Write-Verbose "Extraction d'informations depuis $Url"
    
    try {
        # Simuler l'extraction de contenu web
        # Dans un cas réel, on utiliserait une fonction du module WebScrapingModule
        # $webContent = Get-WebContent -Url $Url
        $webContent = @{
            Title = "Exemple de titre de page"
            Content = "Ceci est un exemple de contenu extrait d'une page web. Il contient du texte qui peut être traité par le module ExtractedInfoModuleV2."
            Metadata = @{
                Author = "Auteur de la page"
                PublishedDate = Get-Date
                Keywords = @("exemple", "web", "extraction")
            }
        }
        
        # Créer un objet TextExtractedInfo à partir du contenu web
        $extractedInfo = New-TextExtractedInfo -Source $Url -Text $webContent.Content -Language "fr"
        
        # Ajouter des métadonnées si demandé
        if ($IncludeMetadata) {
            $metadata = @{
                WebTitle = $webContent.Title
                WebAuthor = $webContent.Metadata.Author
                WebPublishedDate = $webContent.Metadata.PublishedDate
                WebKeywords = $webContent.Metadata.Keywords
                ExtractionDate = Get-Date
            }
            
            $extractedInfo = Add-ExtractedInfoMetadata -Info $extractedInfo -Metadata $metadata
        }
        
        # Exporter l'information extraite si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            Export-ExtractedInfo -Info $extractedInfo -Format "Json" -OutputPath $OutputPath
        }
        
        return $extractedInfo
    }
    catch {
        Write-Error "Erreur lors de l'extraction d'informations depuis $Url : $_"
        return $null
    }
}

# Fonction pour extraire des informations de plusieurs pages web
function Get-MultipleWebPagesInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Urls,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder
    )
    
    Write-Verbose "Extraction d'informations depuis $($Urls.Count) pages web"
    
    # Créer une collection pour stocker les informations extraites
    $collection = New-ExtractedInfoCollection -Name "Web Pages Collection"
    
    # Extraire les informations de chaque page web
    foreach ($url in $Urls) {
        Write-Verbose "Traitement de $url"
        
        $outputPath = $null
        if (-not [string]::IsNullOrEmpty($OutputFolder)) {
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($url) + ".json"
            $outputPath = Join-Path -Path $OutputFolder -ChildPath $fileName
        }
        
        $extractedInfo = Get-WebPageInfo -Url $url -IncludeMetadata:$IncludeMetadata -OutputPath $outputPath
        
        if ($null -ne $extractedInfo) {
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $extractedInfo
        }
    }
    
    return $collection
}

# Fonction pour analyser une collection d'informations extraites
function Analyze-WebPagesCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Collection,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    Write-Verbose "Analyse de la collection $($Collection.Name)"
    
    # Obtenir les statistiques de la collection
    $statistics = Get-ExtractedInfoStatistics -Collection $Collection
    
    # Exporter les statistiques si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $statistics | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
    }
    
    return $statistics
}

# Exemple d'utilisation
function Example-WebScrapingIntegration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".\output"
    )
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Liste d'URLs à traiter
    $urls = @(
        "https://example.com/page1",
        "https://example.com/page2",
        "https://example.com/page3"
    )
    
    # Extraire les informations des pages web
    $collection = Get-MultipleWebPagesInfo -Urls $urls -IncludeMetadata -OutputFolder $OutputFolder
    
    # Analyser la collection
    $statistics = Analyze-WebPagesCollection -Collection $collection -OutputPath (Join-Path -Path $OutputFolder -ChildPath "statistics.json")
    
    # Afficher un résumé
    Write-Host "Résumé de l'extraction :"
    Write-Host "- Pages traitées : $($collection.Items.Count)"
    Write-Host "- Taille moyenne du contenu : $($statistics.ContentStatistics.AverageLength) caractères"
    Write-Host "- Mots uniques : $($statistics.ContentStatistics.UniqueWords.Count)"
    
    return $collection
}

# Exécuter l'exemple
# Example-WebScrapingIntegration -OutputFolder "C:\Temp\WebExtraction"
