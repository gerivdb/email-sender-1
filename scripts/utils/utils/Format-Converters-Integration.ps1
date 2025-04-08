# Script d'intégration pour le module Format-Converters
# Ce script intègre les convertisseurs XML et HTML dans le module Format-Converters existant

# Chemins des modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$formatConvertersPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "Format-Converters"
$xmlSupportPath = Join-Path -Path $parentPath -ChildPath "XmlSupport.ps1"

# Vérifier si le module Format-Converters existe
if (-not (Test-Path -Path $formatConvertersPath)) {
    Write-Error "Le module Format-Converters n'existe pas: $formatConvertersPath"
    exit 1
}

# Vérifier si le module XmlSupport existe
if (-not (Test-Path -Path $xmlSupportPath)) {
    Write-Error "Le module XmlSupport n'existe pas: $xmlSupportPath"
    exit 1
}

# Importer le module XmlSupport
. $xmlSupportPath

# Créer le dossier d'intégration dans Format-Converters s'il n'existe pas
$integrationPath = Join-Path -Path $formatConvertersPath -ChildPath "Integrations"
if (-not (Test-Path -Path $integrationPath)) {
    New-Item -Path $integrationPath -ItemType Directory -Force | Out-Null
}

# Créer le dossier XML_HTML dans le dossier d'intégration s'il n'existe pas
$xmlHtmlIntegrationPath = Join-Path -Path $integrationPath -ChildPath "XML_HTML"
if (-not (Test-Path -Path $xmlHtmlIntegrationPath)) {
    New-Item -Path $xmlHtmlIntegrationPath -ItemType Directory -Force | Out-Null
}

# Fonction pour copier un fichier avec vérification de la date de modification
function Copy-FileIfNewer {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Error "Le fichier source n'existe pas: $SourcePath"
        return $false
    }
    
    $sourceItem = Get-Item -Path $SourcePath
    
    if (Test-Path -Path $DestinationPath) {
        $destinationItem = Get-Item -Path $DestinationPath
        
        if ($sourceItem.LastWriteTime -gt $destinationItem.LastWriteTime) {
            Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
            Write-Host "Fichier mis à jour: $DestinationPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Fichier déjà à jour: $DestinationPath" -ForegroundColor Cyan
            return $false
        }
    }
    else {
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
        Write-Host "Fichier copié: $DestinationPath" -ForegroundColor Green
        return $true
    }
}

# Copier les fichiers d'implémentation
$implementationPath = Join-Path -Path $parentPath -ChildPath "Implementation"
$implementationFiles = Get-ChildItem -Path $implementationPath -Filter "*.ps1"

foreach ($file in $implementationFiles) {
    $sourcePath = $file.FullName
    $destinationPath = Join-Path -Path $xmlHtmlIntegrationPath -ChildPath $file.Name
    
    Copy-FileIfNewer -SourcePath $sourcePath -DestinationPath $destinationPath
}

# Copier le fichier XmlSupport.ps1
$destinationPath = Join-Path -Path $xmlHtmlIntegrationPath -ChildPath "XmlSupport.ps1"
Copy-FileIfNewer -SourcePath $xmlSupportPath -DestinationPath $destinationPath

# Créer le fichier d'intégration principal
$integrationFile = @"
# Module d'intégration XML_HTML pour Format-Converters
# Ce fichier est généré automatiquement par le script d'intégration

# Importer les modules
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$xmlSupportPath = Join-Path -Path `$scriptPath -ChildPath "XmlSupport.ps1"

# Importer le module XmlSupport
. `$xmlSupportPath

# Fonction pour enregistrer les convertisseurs XML et HTML
function Register-XmlHtmlConverters {
    param (
        [Parameter(Mandatory = `$true)]
        [hashtable]`$ConverterRegistry
    )
    
    # Enregistrer les convertisseurs XML
    `$ConverterRegistry["xml"] = @{
        Name = "XML"
        Description = "Format XML structuré"
        Extensions = @(".xml")
        ImportFunction = { param(`$FilePath) Import-XmlFile -FilePath `$FilePath }
        ExportFunction = { param(`$Data, `$FilePath) Export-XmlFile -InputObject `$Data -FilePath `$FilePath }
        ConvertFromFunction = @{
            "roadmap" = { param(`$Content) ConvertFrom-XmlToRoadmap -XmlContent `$Content }
            "html" = { param(`$Content) ConvertFrom-XmlToHtml -XmlDocument ([xml]`$Content) }
            "json" = { param(`$Content) ConvertFrom-XmlToJson -XmlDocument ([xml]`$Content) }
        }
        ConvertToFunction = @{
            "roadmap" = { param(`$Content) ConvertFrom-RoadmapToXml -RoadmapContent `$Content }
            "html" = { param(`$Content) ConvertFrom-XmlToHtml -XmlDocument ([xml]`$Content) }
            "json" = { param(`$Content) ConvertFrom-XmlToJson -XmlDocument ([xml]`$Content) }
        }
        ValidateFunction = { param(`$Content) Test-XmlContent -XmlContent `$Content }
        AnalyzeFunction = { param(`$FilePath) Invoke-XmlAnalysis -XmlPath `$FilePath -IncludeValidation -IncludeStructure }
    }
    
    # Enregistrer les convertisseurs HTML
    `$ConverterRegistry["html"] = @{
        Name = "HTML"
        Description = "Format HTML pour pages web"
        Extensions = @(".html", ".htm")
        ImportFunction = { param(`$FilePath) Import-HtmlFile -FilePath `$FilePath }
        ExportFunction = { param(`$Data, `$FilePath) Export-HtmlFile -HtmlDocument `$Data -FilePath `$FilePath }
        ConvertFromFunction = @{
            "xml" = { param(`$Content) ConvertFrom-HtmlToXml -HtmlDocument `$Content }
            "text" = { param(`$Content) ConvertTo-PlainText -HtmlDocument `$Content }
        }
        ConvertToFunction = @{
            "xml" = { param(`$Content) ConvertFrom-XmlToHtml -XmlDocument `$Content }
        }
        ValidateFunction = { param(`$Content) `$true } # HTML est plus permissif, pas de validation stricte
        AnalyzeFunction = { param(`$FilePath) `$null } # Pas d'analyse spécifique pour HTML pour le moment
    }
    
    return `$ConverterRegistry
}

# Exporter les fonctions
Export-ModuleMember -Function Register-XmlHtmlConverters
"@

$integrationMainPath = Join-Path -Path $xmlHtmlIntegrationPath -ChildPath "XML_HTML_Integration.ps1"
Set-Content -Path $integrationMainPath -Value $integrationFile -Encoding UTF8

Write-Host "Intégration terminée avec succès!" -ForegroundColor Green
Write-Host "Les convertisseurs XML et HTML sont maintenant disponibles dans le module Format-Converters." -ForegroundColor Green
Write-Host "Chemin d'intégration: $xmlHtmlIntegrationPath" -ForegroundColor Cyan
