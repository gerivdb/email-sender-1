# Module de conversion entre formats XML et HTML
# Ce script implémente les fonctionnalités pour convertir entre XML, HTML et JSON

# Importer les modules de gestion des formats
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$xmlHandlerPath = Join-Path -Path $scriptPath -ChildPath "XMLFormatHandler.ps1"
$htmlHandlerPath = Join-Path -Path $scriptPath -ChildPath "HTMLFormatHandler.ps1"

if (Test-Path -Path $xmlHandlerPath) {
    . $xmlHandlerPath
}
else {
    Write-Error "Le module XMLFormatHandler est introuvable: $xmlHandlerPath"
}

if (Test-Path -Path $htmlHandlerPath) {
    . $htmlHandlerPath
}
else {
    Write-Error "Le module HTMLFormatHandler est introuvable: $htmlHandlerPath"
}

# Configuration
$ConverterConfig = @{
    # Paramètres par défaut pour la conversion XML vers HTML
    DefaultXmlToHtmlSettings = @{
        AddCssStyles = $true
        DefaultCss = @"
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
"@
        WrapInHtmlDocument = $true
    }
    
    # Paramètres par défaut pour la conversion HTML vers XML
    DefaultHtmlToXmlSettings = @{
        PreserveWhitespace = $false
        IncludeDoctype = $false
        RootElementName = "html"
    }
    
    # Paramètres par défaut pour la conversion XML vers JSON
    DefaultXmlToJsonSettings = @{
        ConvertAttributesToProperties = $true
        IncludeDeclaration = $false
        PrettyPrint = $true
    }
    
    # Paramètres par défaut pour la conversion JSON vers XML
    DefaultJsonToXmlSettings = @{
        RootElementName = "root"
        ArrayItemName = "item"
        AddTypeAttributes = $false
    }
}

# Fonction pour convertir XML en HTML
function ConvertFrom-XmlToHtml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Xml.XmlDocument]$XmlDocument,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $settings = if ($ConversionSettings) { $ConversionSettings } else { $ConverterConfig.DefaultXmlToHtmlSettings.Clone() }
        
        # Créer un document HTML
        $htmlDoc = New-HtmlDocument
        
        # Créer un document HTML de base si demandé
        if ($settings.WrapInHtmlDocument) {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>XML Converted to HTML</title>
    $(if ($settings.AddCssStyles) { "<style>$($settings.DefaultCss)</style>" })
</head>
<body></body>
</html>
"@
            $htmlDoc.LoadHtml($html)
        }
        else {
            $htmlDoc.LoadHtml("<div></div>")
        }
        
        # Obtenir le nœud parent
        $parentNode = if ($settings.WrapInHtmlDocument) { 
            $htmlDoc.DocumentNode.SelectSingleNode("//body") 
        } else { 
            $htmlDoc.DocumentNode.SelectSingleNode("//div") 
        }
        
        # Fonction récursive pour convertir les nœuds XML en nœuds HTML
        function ConvertXmlNodeToHtml($xmlNode, $htmlParent) {
            switch ($xmlNode.NodeType) {
                ([System.Xml.XmlNodeType]::Element) {
                    # Créer une section pour l'élément
                    $section = $htmlDoc.CreateElement("div")
                    $section.SetAttributeValue("class", "xml-element")
                    $htmlParent.AppendChild($section) | Out-Null
                    
                    # Ajouter le nom de l'élément
                    $header = $htmlDoc.CreateElement("h3")
                    $header.InnerHtml = $xmlNode.Name
                    $section.AppendChild($header) | Out-Null
                    
                    # Ajouter les attributs s'il y en a
                    if ($xmlNode.Attributes.Count -gt 0) {
                        $attrTable = $htmlDoc.CreateElement("table")
                        $attrTable.SetAttributeValue("class", "xml-attributes")
                        $section.AppendChild($attrTable) | Out-Null
                        
                        $attrHeader = $htmlDoc.CreateElement("tr")
                        $attrTable.AppendChild($attrHeader) | Out-Null
                        
                        $nameHeader = $htmlDoc.CreateElement("th")
                        $nameHeader.InnerHtml = "Attribute"
                        $attrHeader.AppendChild($nameHeader) | Out-Null
                        
                        $valueHeader = $htmlDoc.CreateElement("th")
                        $valueHeader.InnerHtml = "Value"
                        $attrHeader.AppendChild($valueHeader) | Out-Null
                        
                        foreach ($attr in $xmlNode.Attributes) {
                            $attrRow = $htmlDoc.CreateElement("tr")
                            $attrTable.AppendChild($attrRow) | Out-Null
                            
                            $attrName = $htmlDoc.CreateElement("td")
                            $attrName.InnerHtml = $attr.Name
                            $attrRow.AppendChild($attrName) | Out-Null
                            
                            $attrValue = $htmlDoc.CreateElement("td")
                            $attrValue.InnerHtml = $attr.Value
                            $attrRow.AppendChild($attrValue) | Out-Null
                        }
                    }
                    
                    # Ajouter le contenu de l'élément
                    $content = $htmlDoc.CreateElement("div")
                    $content.SetAttributeValue("class", "xml-content")
                    $section.AppendChild($content) | Out-Null
                    
                    # Traiter les nœuds enfants
                    if ($xmlNode.HasChildNodes) {
                        foreach ($childNode in $xmlNode.ChildNodes) {
                            ConvertXmlNodeToHtml $childNode $content
                        }
                    }
                }
                ([System.Xml.XmlNodeType]::Text) {
                    # Créer un paragraphe pour le texte
                    $p = $htmlDoc.CreateElement("p")
                    $p.InnerHtml = $xmlNode.Value
                    $htmlParent.AppendChild($p) | Out-Null
                }
                ([System.Xml.XmlNodeType]::CDATA) {
                    # Créer un bloc pre pour les données CDATA
                    $pre = $htmlDoc.CreateElement("pre")
                    $pre.SetAttributeValue("class", "xml-cdata")
                    $pre.InnerHtml = $xmlNode.Value
                    $htmlParent.AppendChild($pre) | Out-Null
                }
                ([System.Xml.XmlNodeType]::Comment) {
                    # Créer un bloc pour les commentaires
                    $comment = $htmlDoc.CreateElement("div")
                    $comment.SetAttributeValue("class", "xml-comment")
                    $comment.InnerHtml = "<!-- " + $xmlNode.Value + " -->"
                    $htmlParent.AppendChild($comment) | Out-Null
                }
            }
        }
        
        # Convertir le document XML en HTML
        ConvertXmlNodeToHtml $XmlDocument.DocumentElement $parentNode
        
        return $htmlDoc
    }
}

# Fonction pour convertir HTML en XML
function ConvertFrom-HtmlToXml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $settings = if ($ConversionSettings) { $ConversionSettings } else { $ConverterConfig.DefaultHtmlToXmlSettings.Clone() }
        
        # Créer un document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        
        # Ajouter la déclaration XML si demandé
        if ($settings.IncludeDoctype) {
            $xmlDecl = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
            $xmlDoc.AppendChild($xmlDecl) | Out-Null
        }
        
        # Créer l'élément racine
        $rootElement = $xmlDoc.CreateElement($settings.RootElementName)
        $xmlDoc.AppendChild($rootElement) | Out-Null
        
        # Fonction récursive pour convertir les nœuds HTML en nœuds XML
        function ConvertHtmlNodeToXml($htmlNode, $xmlParent) {
            switch ($htmlNode.NodeType) {
                ([HtmlAgilityPack.HtmlNodeType]::Element) {
                    # Créer un élément XML
                    $xmlElement = $xmlDoc.CreateElement($htmlNode.Name)
                    $xmlParent.AppendChild($xmlElement) | Out-Null
                    
                    # Ajouter les attributs
                    foreach ($attr in $htmlNode.Attributes) {
                        $xmlAttr = $xmlDoc.CreateAttribute($attr.Name)
                        $xmlAttr.Value = $attr.Value
                        $xmlElement.Attributes.Append($xmlAttr) | Out-Null
                    }
                    
                    # Traiter les nœuds enfants
                    foreach ($childNode in $htmlNode.ChildNodes) {
                        ConvertHtmlNodeToXml $childNode $xmlElement
                    }
                }
                ([HtmlAgilityPack.HtmlNodeType]::Text) {
                    # Ignorer le texte vide si demandé
                    if (-not $settings.PreserveWhitespace -and [string]::IsNullOrWhiteSpace($htmlNode.InnerText)) {
                        return
                    }
                    
                    # Créer un nœud texte
                    $xmlText = $xmlDoc.CreateTextNode($htmlNode.InnerText)
                    $xmlParent.AppendChild($xmlText) | Out-Null
                }
                ([HtmlAgilityPack.HtmlNodeType]::Comment) {
                    # Créer un nœud commentaire
                    $xmlComment = $xmlDoc.CreateComment($htmlNode.InnerText)
                    $xmlParent.AppendChild($xmlComment) | Out-Null
                }
            }
        }
        
        # Convertir le document HTML en XML
        foreach ($childNode in $HtmlDocument.DocumentNode.ChildNodes) {
            ConvertHtmlNodeToXml $childNode $rootElement
        }
        
        return $xmlDoc
    }
}

# Fonction pour convertir XML en JSON
function ConvertFrom-XmlToJson {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Xml.XmlDocument]$XmlDocument,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $settings = if ($ConversionSettings) { $ConversionSettings } else { $ConverterConfig.DefaultXmlToJsonSettings.Clone() }
        
        # Fonction récursive pour convertir les nœuds XML en objets JSON
        function ConvertXmlNodeToJson($node) {
            # Créer un objet pour ce nœud
            $result = @{}
            
            # Ajouter les attributs comme propriétés si demandé
            if ($settings.ConvertAttributesToProperties -and $node.Attributes.Count -gt 0) {
                foreach ($attr in $node.Attributes) {
                    $result["@" + $attr.Name] = $attr.Value
                }
            }
            
            # Traiter les nœuds enfants
            $childElements = @($node.ChildNodes | Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element })
            
            # Si le nœud n'a que du texte, retourner le texte
            if ($childElements.Count -eq 0 -and $node.ChildNodes.Count -gt 0) {
                $textValue = $node.InnerText.Trim()
                if ([string]::IsNullOrEmpty($textValue)) {
                    return $result
                }
                else {
                    return $textValue
                }
            }
            
            # Regrouper les nœuds enfants par nom
            $groupedChildren = $childElements | Group-Object -Property Name
            
            foreach ($group in $groupedChildren) {
                # Si plusieurs nœuds ont le même nom, les traiter comme un tableau
                if ($group.Count -gt 1) {
                    $result[$group.Name] = @($group.Group | ForEach-Object { ConvertXmlNodeToJson $_ })
                }
                else {
                    $result[$group.Name] = ConvertXmlNodeToJson $group.Group[0]
                }
            }
            
            return $result
        }
        
        # Convertir le document XML en objet JSON
        $jsonObject = ConvertXmlNodeToJson $XmlDocument.DocumentElement
        
        # Ajouter le nom de l'élément racine
        $rootObject = @{}
        $rootObject[$XmlDocument.DocumentElement.Name] = $jsonObject
        
        # Convertir l'objet en JSON
        $jsonOptions = if ($settings.PrettyPrint) { 
            [System.Text.Json.JsonSerializerOptions]::new()
            $jsonOptions.WriteIndented = $true
            $jsonOptions
        } else { 
            $null 
        }
        
        $json = [System.Text.Json.JsonSerializer]::Serialize($rootObject, $jsonOptions)
        
        return $json
    }
}

# Fonction pour convertir JSON en XML
function ConvertFrom-JsonToXml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$JsonString,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $settings = if ($ConversionSettings) { $ConversionSettings } else { $ConverterConfig.DefaultJsonToXmlSettings.Clone() }
        
        # Convertir la chaîne JSON en objet PowerShell
        $jsonObject = $JsonString | ConvertFrom-Json
        
        # Créer un document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        
        # Ajouter la déclaration XML
        $xmlDecl = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
        $xmlDoc.AppendChild($xmlDecl) | Out-Null
        
        # Fonction récursive pour convertir les objets JSON en nœuds XML
        function ConvertJsonToXmlNode($obj, $parentNode, $nodeName) {
            # Si l'objet est null, créer un élément vide
            if ($null -eq $obj) {
                $element = $xmlDoc.CreateElement($nodeName)
                if ($settings.AddTypeAttributes) {
                    $element.SetAttribute("xsi:nil", "http://www.w3.org/2001/XMLSchema-instance", "true")
                }
                $parentNode.AppendChild($element) | Out-Null
                return
            }
            
            # Traiter différents types d'objets
            switch ($obj.GetType().Name) {
                # Types simples
                { $_ -in @("String", "Int32", "Int64", "Double", "Decimal", "Boolean", "DateTime", "Guid") } {
                    $element = $xmlDoc.CreateElement($nodeName)
                    if ($settings.AddTypeAttributes) {
                        $element.SetAttribute("type", $_.ToLower())
                    }
                    $element.InnerText = $obj.ToString()
                    $parentNode.AppendChild($element) | Out-Null
                }
                
                # Tableau
                { $_ -eq "Object[]" } {
                    foreach ($item in $obj) {
                        ConvertJsonToXmlNode $item $parentNode $settings.ArrayItemName
                    }
                }
                
                # Objet
                "PSCustomObject" {
                    $element = $xmlDoc.CreateElement($nodeName)
                    $parentNode.AppendChild($element) | Out-Null
                    
                    foreach ($prop in $obj.PSObject.Properties) {
                        ConvertJsonToXmlNode $prop.Value $element $prop.Name
                    }
                }
                
                # Type par défaut
                default {
                    $element = $xmlDoc.CreateElement($nodeName)
                    $element.InnerText = $obj.ToString()
                    $parentNode.AppendChild($element) | Out-Null
                }
            }
        }
        
        # Convertir l'objet JSON en XML
        $rootName = $settings.RootElementName
        
        # Si l'objet JSON a une seule propriété, utiliser son nom comme racine
        if ($jsonObject.PSObject.Properties.Count -eq 1) {
            $rootProp = $jsonObject.PSObject.Properties[0]
            $rootName = $rootProp.Name
            ConvertJsonToXmlNode $rootProp.Value $xmlDoc $rootName
        }
        else {
            # Sinon, créer un élément racine et ajouter toutes les propriétés comme enfants
            $rootElement = $xmlDoc.CreateElement($rootName)
            $xmlDoc.AppendChild($rootElement) | Out-Null
            
            foreach ($prop in $jsonObject.PSObject.Properties) {
                ConvertJsonToXmlNode $prop.Value $rootElement $prop.Name
            }
        }
        
        return $xmlDoc
    }
}

# Fonction pour convertir HTML en JSON
function ConvertFrom-HtmlToJson {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    process {
        # Convertir d'abord HTML en XML
        $xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $HtmlDocument -ConversionSettings $ConversionSettings
        
        # Puis XML en JSON
        $json = ConvertFrom-XmlToJson -XmlDocument $xmlDoc -ConversionSettings $ConversionSettings
        
        return $json
    }
}

# Fonction pour convertir JSON en HTML
function ConvertFrom-JsonToHtml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$JsonString,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    process {
        # Convertir d'abord JSON en XML
        $xmlDoc = ConvertFrom-JsonToXml -JsonString $JsonString -ConversionSettings $ConversionSettings
        
        # Puis XML en HTML
        $htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc -ConversionSettings $ConversionSettings
        
        return $htmlDoc
    }
}

# Exporter les fonctions
Export-ModuleMember -Function ConvertFrom-XmlToHtml, ConvertFrom-HtmlToXml
Export-ModuleMember -Function ConvertFrom-XmlToJson, ConvertFrom-JsonToXml
Export-ModuleMember -Function ConvertFrom-HtmlToJson, ConvertFrom-JsonToHtml
