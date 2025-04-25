# Module principal pour le support des formats XML et HTML
# Ce script sert de point d'entrée pour utiliser toutes les fonctionnalités

# Importer les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$implementationPath = Join-Path -Path $scriptPath -ChildPath "Implementation"
$xmlHandlerPath = Join-Path -Path $implementationPath -ChildPath "XMLFormatHandler.ps1"
$htmlHandlerPath = Join-Path -Path $implementationPath -ChildPath "HTMLFormatHandler.ps1"
$formatConverterPath = Join-Path -Path $implementationPath -ChildPath "FormatConverter.ps1"

# Importer les modules
. $xmlHandlerPath
. $htmlHandlerPath
. $formatConverterPath

# Fonction pour afficher l'aide
function Show-FormatSupportHelp {
    Write-Host "Module de support des formats XML et HTML" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ce module fournit des fonctionnalités pour travailler avec les formats XML et HTML," -ForegroundColor Yellow
    Write-Host "ainsi que pour convertir entre ces formats et JSON." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Fonctions XML:" -ForegroundColor Green
    Write-Host "  ConvertFrom-Xml        - Parse une chaîne XML en objet XmlDocument"
    Write-Host "  ConvertTo-Xml          - Convertit un objet en chaîne XML"
    Write-Host "  Import-XmlFile         - Lit un fichier XML"
    Write-Host "  Export-XmlFile         - Écrit un objet dans un fichier XML"
    Write-Host ""
    
    Write-Host "Fonctions HTML:" -ForegroundColor Green
    Write-Host "  ConvertFrom-Html       - Parse une chaîne HTML en objet HtmlDocument"
    Write-Host "  ConvertTo-Html         - Convertit un objet en document HTML"
    Write-Host "  Import-HtmlFile        - Lit un fichier HTML"
    Write-Host "  Export-HtmlFile        - Écrit un document HTML dans un fichier"
    Write-Host "  Invoke-CssQuery        - Exécute une requête CSS sur un document HTML"
    Write-Host "  Invoke-HtmlSanitization - Sanitise un document HTML"
    Write-Host "  ConvertTo-PlainText    - Convertit un document HTML en texte brut"
    Write-Host ""
    
    Write-Host "Fonctions de conversion:" -ForegroundColor Green
    Write-Host "  ConvertFrom-XmlToHtml  - Convertit un document XML en HTML"
    Write-Host "  ConvertFrom-HtmlToXml  - Convertit un document HTML en XML"
    Write-Host "  ConvertFrom-XmlToJson  - Convertit un document XML en JSON"
    Write-Host "  ConvertFrom-JsonToXml  - Convertit une chaîne JSON en XML"
    Write-Host "  ConvertFrom-HtmlToJson - Convertit un document HTML en JSON"
    Write-Host "  ConvertFrom-JsonToHtml - Convertit une chaîne JSON en HTML"
    Write-Host ""
    
    Write-Host "Utilitaires:" -ForegroundColor Green
    Write-Host "  Install-HtmlAgilityPack - Installe la bibliothèque HtmlAgilityPack"
    Write-Host "  Test-HtmlAgilityPackAvailable - Vérifie si HtmlAgilityPack est disponible"
    Write-Host "  New-HtmlDocument       - Crée un nouveau document HTML"
    Write-Host ""
    
    Write-Host "Exemples:" -ForegroundColor Yellow
    Write-Host "  # Convertir un fichier XML en HTML"
    Write-Host "  `$xmlDoc = Import-XmlFile -FilePath 'data.xml'"
    Write-Host "  `$htmlDoc = ConvertFrom-XmlToHtml -XmlDocument `$xmlDoc"
    Write-Host "  Export-HtmlFile -HtmlDocument `$htmlDoc -FilePath 'output.html'"
    Write-Host ""
    
    Write-Host "  # Sanitiser un fichier HTML"
    Write-Host "  `$htmlDoc = Import-HtmlFile -FilePath 'input.html'"
    Write-Host "  `$sanitizedDoc = Invoke-HtmlSanitization -HtmlDocument `$htmlDoc"
    Write-Host "  Export-HtmlFile -HtmlDocument `$sanitizedDoc -FilePath 'sanitized.html'"
    Write-Host ""
    
    Write-Host "  # Convertir un objet en XML puis en JSON"
    Write-Host "  `$data = @{ person = @{ name = 'John Doe'; age = 30 } }"
    Write-Host "  `$xmlString = ConvertTo-Xml -InputObject `$data"
    Write-Host "  `$xmlDoc = ConvertFrom-Xml -XmlString `$xmlString"
    Write-Host "  `$json = ConvertFrom-XmlToJson -XmlDocument `$xmlDoc"
    Write-Host "  `$json | Out-File -FilePath 'output.json'"
    Write-Host ""
}

# Fonction pour exécuter les tests
function Invoke-FormatSupportTests {
    $testsPath = Join-Path -Path $scriptPath -ChildPath "Tests\Test-FormatSupport.ps1"
    
    if (Test-Path -Path $testsPath) {
        & $testsPath
    }
    else {
        Write-Error "Le script de tests est introuvable: $testsPath"
    }
}

# Fonction pour convertir un fichier d'un format à un autre
function Convert-FormatFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("xml", "html", "json")]
        [string]$InputFormat,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("xml", "html", "json")]
        [string]$OutputFormat,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    # Vérifier si les formats d'entrée et de sortie sont identiques
    if ($InputFormat -eq $OutputFormat) {
        Write-Error "Les formats d'entrée et de sortie sont identiques: $InputFormat"
        return $false
    }
    
    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
        return $false
    }
    
    try {
        # Lire le fichier d'entrée
        $inputContent = $null
        
        switch ($InputFormat) {
            "xml" {
                $inputContent = Import-XmlFile -FilePath $InputPath
            }
            "html" {
                $inputContent = Import-HtmlFile -FilePath $InputPath
            }
            "json" {
                $inputContent = Get-Content -Path $InputPath -Raw
            }
        }
        
        # Convertir le contenu
        $outputContent = $null
        
        switch ("$InputFormat-$OutputFormat") {
            "xml-html" {
                $outputContent = ConvertFrom-XmlToHtml -XmlDocument $inputContent -ConversionSettings $ConversionSettings
            }
            "xml-json" {
                $outputContent = ConvertFrom-XmlToJson -XmlDocument $inputContent -ConversionSettings $ConversionSettings
            }
            "html-xml" {
                $outputContent = ConvertFrom-HtmlToXml -HtmlDocument $inputContent -ConversionSettings $ConversionSettings
            }
            "html-json" {
                $outputContent = ConvertFrom-HtmlToJson -HtmlDocument $inputContent -ConversionSettings $ConversionSettings
            }
            "json-xml" {
                $outputContent = ConvertFrom-JsonToXml -JsonString $inputContent -ConversionSettings $ConversionSettings
            }
            "json-html" {
                $outputContent = ConvertFrom-JsonToHtml -JsonString $inputContent -ConversionSettings $ConversionSettings
            }
        }
        
        # Écrire le fichier de sortie
        switch ($OutputFormat) {
            "xml" {
                $outputContent.Save($OutputPath)
            }
            "html" {
                Export-HtmlFile -HtmlDocument $outputContent -FilePath $OutputPath
            }
            "json" {
                $outputContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
        
        Write-Host "Conversion réussie: $InputPath -> $OutputPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erreur lors de la conversion: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Show-FormatSupportHelp, Invoke-FormatSupportTests, Convert-FormatFile

# Exporter les fonctions des modules importés
Export-ModuleMember -Function ConvertFrom-Xml, ConvertTo-Xml, Import-XmlFile, Export-XmlFile
Export-ModuleMember -Function ConvertFrom-Html, ConvertTo-Html, Import-HtmlFile, Export-HtmlFile
Export-ModuleMember -Function Invoke-CssQuery, Invoke-HtmlSanitization, ConvertTo-PlainText, ConvertTo-Xml
Export-ModuleMember -Function ConvertFrom-XmlToHtml, ConvertFrom-HtmlToXml
Export-ModuleMember -Function ConvertFrom-XmlToJson, ConvertFrom-JsonToXml
Export-ModuleMember -Function ConvertFrom-HtmlToJson, ConvertFrom-JsonToHtml
Export-ModuleMember -Function Install-HtmlAgilityPack, Test-HtmlAgilityPackAvailable, New-HtmlDocument

# Afficher un message d'accueil
Write-Host "Module de support des formats XML et HTML chargé." -ForegroundColor Cyan
Write-Host "Utilisez Show-FormatSupportHelp pour afficher l'aide." -ForegroundColor Cyan
