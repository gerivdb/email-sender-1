# Module de gestion du format HTML
# Ce script implÃ©mente les fonctionnalitÃ©s de base pour le support du format HTML
# NÃ©cessite HtmlAgilityPack (peut Ãªtre installÃ© via Install-Package HtmlAgilityPack)

# Configuration
$HTMLConfig = @{
    # ParamÃ¨tres par dÃ©faut pour le parsing HTML
    DefaultHtmlSettings = @{
        FixNestedTags = $true
        AutoCloseOnEnd = $true
        CheckSyntax = $true
        DefaultEncoding = "UTF-8"
    }
    
    # ParamÃ¨tres par dÃ©faut pour la sanitisation HTML
    DefaultSanitizationSettings = @{
        EnableSanitization = $true
        AllowedTags = @("a", "b", "blockquote", "br", "code", "div", "em", "h1", "h2", "h3", 
                        "img", "li", "ol", "p", "pre", "span", "strong", "table", "td", "th", "tr", "ul")
        AllowedAttributes = @("href", "src", "alt", "title", "class", "id")
        AllowedProtocols = @("http", "https", "mailto")
    }
    
    # ParamÃ¨tres par dÃ©faut pour la gÃ©nÃ©ration HTML
    DefaultGenerationSettings = @{
        Doctype = "<!DOCTYPE html>"
        Encoding = "UTF-8"
        IndentOutput = $true
    }
}

# Fonction pour vÃ©rifier si HtmlAgilityPack est disponible
function Test-HtmlAgilityPackAvailable {
    try {
        [Reflection.Assembly]::LoadWithPartialName("HtmlAgilityPack") | Out-Null
        return $null -ne ([System.Type]::GetType("HtmlAgilityPack.HtmlDocument"))
    }
    catch {
        return $false
    }
}

# Fonction pour installer HtmlAgilityPack
function Install-HtmlAgilityPack {
    if (Test-HtmlAgilityPackAvailable) {
        Write-Host "HtmlAgilityPack est dÃ©jÃ  installÃ©."
        return $true
    }
    
    try {
        # VÃ©rifier si NuGet est disponible
        $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        
        if (-not $nuget) {
            Write-Host "Installation du fournisseur de packages NuGet..."
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
        }
        
        # Installer HtmlAgilityPack
        Write-Host "Installation de HtmlAgilityPack..."
        Install-Package HtmlAgilityPack -Force -Scope CurrentUser | Out-Null
        
        # Charger l'assembly
        [Reflection.Assembly]::LoadWithPartialName("HtmlAgilityPack") | Out-Null
        
        Write-Host "HtmlAgilityPack a Ã©tÃ© installÃ© avec succÃ¨s."
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'installation de HtmlAgilityPack: $_"
        return $false
    }
}

# Fonction pour crÃ©er un nouveau document HTML
function New-HtmlDocument {
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$HtmlSettings
    )
    
    # VÃ©rifier si HtmlAgilityPack est disponible
    if (-not (Test-HtmlAgilityPackAvailable)) {
        if (-not (Install-HtmlAgilityPack)) {
            throw "HtmlAgilityPack n'est pas disponible et n'a pas pu Ãªtre installÃ©."
        }
    }
    
    # Utiliser les paramÃ¨tres fournis ou les valeurs par dÃ©faut
    $settings = if ($HtmlSettings) { $HtmlSettings } else { $HTMLConfig.DefaultHtmlSettings.Clone() }
    
    # CrÃ©er un document HTML
    $htmlDoc = New-Object HtmlAgilityPack.HtmlDocument
    
    # Configurer les options
    $htmlDoc.OptionFixNestedTags = $settings.FixNestedTags
    $htmlDoc.OptionAutoCloseOnEnd = $settings.AutoCloseOnEnd
    $htmlDoc.OptionCheckSyntax = $settings.CheckSyntax
    $htmlDoc.OptionDefaultStreamEncoding = [System.Text.Encoding]::GetEncoding($settings.DefaultEncoding)
    
    return $htmlDoc
}

# Fonction pour parser une chaÃ®ne HTML
function ConvertFrom-Html {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$HtmlString,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$HtmlSettings,
        
        [Parameter(Mandatory = $false)]
        [switch]$Sanitize,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SanitizationSettings
    )
    
    process {
        # CrÃ©er un document HTML
        $htmlDoc = New-HtmlDocument -HtmlSettings $HtmlSettings
        
        # Charger le contenu HTML
        $htmlDoc.LoadHtml($HtmlString)
        
        # Sanitiser le document si demandÃ©
        if ($Sanitize) {
            $htmlDoc = Invoke-HtmlSanitization -HtmlDocument $htmlDoc -SanitizationSettings $SanitizationSettings
        }
        
        return $htmlDoc
    }
}

# Fonction pour lire un fichier HTML
function Import-HtmlFile {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$HtmlSettings,
        
        [Parameter(Mandatory = $false)]
        [switch]$Sanitize,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SanitizationSettings
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier HTML n'existe pas: $FilePath"
    }
    
    # CrÃ©er un document HTML
    $htmlDoc = New-HtmlDocument -HtmlSettings $HtmlSettings
    
    # Charger le fichier HTML
    $htmlDoc.Load($FilePath)
    
    # Sanitiser le document si demandÃ©
    if ($Sanitize) {
        $htmlDoc = Invoke-HtmlSanitization -HtmlDocument $htmlDoc -SanitizationSettings $SanitizationSettings
    }
    
    return $htmlDoc
}

# Fonction pour sanitiser un document HTML
function Invoke-HtmlSanitization {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SanitizationSettings
    )
    
    process {
        # Utiliser les paramÃ¨tres fournis ou les valeurs par dÃ©faut
        $settings = if ($SanitizationSettings) { $SanitizationSettings } else { $HTMLConfig.DefaultSanitizationSettings.Clone() }
        
        # CrÃ©er une copie du document
        $sanitizedDoc = New-Object HtmlAgilityPack.HtmlDocument
        $sanitizedDoc.LoadHtml($HtmlDocument.DocumentNode.OuterHtml)
        
        # Obtenir tous les nÅ“uds
        $nodes = $sanitizedDoc.DocumentNode.SelectNodes("//*")
        
        if ($null -eq $nodes) {
            return $sanitizedDoc
        }
        
        # Parcourir les nÅ“uds en ordre inverse pour Ã©viter les problÃ¨mes lors de la suppression
        for ($i = $nodes.Count - 1; $i -ge 0; $i--) {
            $node = $nodes[$i]
            
            # VÃ©rifier si le tag est autorisÃ©
            if ($node.NodeType -eq [HtmlAgilityPack.HtmlNodeType]::Element -and 
                $settings.AllowedTags -notcontains $node.Name.ToLower()) {
                # Remplacer le nÅ“ud par son contenu
                $node.ParentNode.ReplaceChild($sanitizedDoc.CreateTextNode($node.InnerText), $node)
                continue
            }
            
            # VÃ©rifier les attributs
            if ($node.HasAttributes) {
                $attributesToRemove = @()
                
                foreach ($attr in $node.Attributes) {
                    # VÃ©rifier si l'attribut est autorisÃ©
                    if ($settings.AllowedAttributes -notcontains $attr.Name.ToLower()) {
                        $attributesToRemove += $attr.Name
                        continue
                    }
                    
                    # VÃ©rifier les URLs dans les attributs href et src
                    if ($attr.Name -eq "href" -or $attr.Name -eq "src") {
                        $url = $attr.Value
                        $isValid = $false
                        
                        foreach ($protocol in $settings.AllowedProtocols) {
                            if ($url -match "^$protocol`:") {
                                $isValid = $true
                                break
                            }
                        }
                        
                        if (-not $isValid) {
                            $attributesToRemove += $attr.Name
                        }
                    }
                }
                
                # Supprimer les attributs non autorisÃ©s
                foreach ($attrName in $attributesToRemove) {
                    $node.Attributes.Remove($attrName)
                }
            }
        }
        
        return $sanitizedDoc
    }
}

# Fonction pour exÃ©cuter une requÃªte CSS sur un document HTML
function Invoke-CssQuery {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$CssSelector
    )
    
    process {
        try {
            # ExÃ©cuter la requÃªte CSS
            $nodes = $HtmlDocument.DocumentNode.SelectNodes($CssSelector)
            
            # Retourner les nÅ“uds trouvÃ©s
            return $nodes
        }
        catch {
            Write-Error "Erreur lors de l'exÃ©cution de la requÃªte CSS: $_"
            throw
        }
    }
}

# Fonction pour convertir un document HTML en texte
function ConvertTo-PlainText {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument
    )
    
    process {
        return $HtmlDocument.DocumentNode.InnerText
    }
}

# Fonction pour convertir un document HTML en XML
function ConvertTo-Xml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument
    )
    
    process {
        # CrÃ©er un document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        
        # CrÃ©er un nÅ“ud racine
        $root = $xmlDoc.CreateElement("html")
        $xmlDoc.AppendChild($root) | Out-Null
        
        # Fonction rÃ©cursive pour convertir les nÅ“uds HTML en nÅ“uds XML
        function ConvertNode($htmlNode, $xmlParent) {
            switch ($htmlNode.NodeType) {
                ([HtmlAgilityPack.HtmlNodeType]::Element) {
                    # CrÃ©er un Ã©lÃ©ment XML
                    $xmlElement = $xmlDoc.CreateElement($htmlNode.Name)
                    $xmlParent.AppendChild($xmlElement) | Out-Null
                    
                    # Ajouter les attributs
                    foreach ($attr in $htmlNode.Attributes) {
                        $xmlAttr = $xmlDoc.CreateAttribute($attr.Name)
                        $xmlAttr.Value = $attr.Value
                        $xmlElement.Attributes.Append($xmlAttr) | Out-Null
                    }
                    
                    # Traiter les nÅ“uds enfants
                    foreach ($childNode in $htmlNode.ChildNodes) {
                        ConvertNode $childNode $xmlElement
                    }
                }
                ([HtmlAgilityPack.HtmlNodeType]::Text) {
                    # CrÃ©er un nÅ“ud texte
                    $xmlText = $xmlDoc.CreateTextNode($htmlNode.InnerText)
                    $xmlParent.AppendChild($xmlText) | Out-Null
                }
            }
        }
        
        # Convertir le document HTML en XML
        ConvertNode $HtmlDocument.DocumentNode $root
        
        return $xmlDoc
    }
}

# Fonction pour gÃ©nÃ©rer un document HTML Ã  partir d'un objet
function ConvertTo-Html {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$GenerationSettings
    )
    
    process {
        # Utiliser les paramÃ¨tres fournis ou les valeurs par dÃ©faut
        $settings = if ($GenerationSettings) { $GenerationSettings } else { $HTMLConfig.DefaultGenerationSettings.Clone() }
        
        # CrÃ©er un document HTML
        $htmlDoc = New-HtmlDocument
        
        # CrÃ©er un document HTML de base
        $html = $settings.Doctype + "`n<html><head><meta charset=`"" + $settings.Encoding + "`"></head><body></body></html>"
        $htmlDoc.LoadHtml($html)
        
        # Obtenir le nÅ“ud body
        $bodyNode = $htmlDoc.DocumentNode.SelectSingleNode("//body")
        
        # Fonction rÃ©cursive pour convertir un objet en HTML
        function ConvertObjectToHtml($node, $obj) {
            # Si l'objet est null, ne rien faire
            if ($null -eq $obj) {
                return
            }
            
            # Traiter diffÃ©rents types d'objets
            switch ($obj.GetType().Name) {
                # Types simples
                { $_ -in @("String", "Int32", "Int64", "Double", "Decimal", "Boolean", "DateTime", "Guid") } {
                    $textNode = $htmlDoc.CreateTextNode($obj.ToString())
                    $node.AppendChild($textNode) | Out-Null
                }
                
                # Hashtable ou PSCustomObject
                { $_ -in @("Hashtable", "PSCustomObject") } {
                    $properties = if ($_ -eq "Hashtable") { $obj.Keys } else { $obj.PSObject.Properties.Name }
                    
                    # CrÃ©er une table HTML
                    $table = $htmlDoc.CreateElement("table")
                    $node.AppendChild($table) | Out-Null
                    
                    foreach ($propName in $properties) {
                        $propValue = if ($_ -eq "Hashtable") { $obj[$propName] } else { $obj.$propName }
                        
                        # CrÃ©er une ligne pour la propriÃ©tÃ©
                        $row = $htmlDoc.CreateElement("tr")
                        $table.AppendChild($row) | Out-Null
                        
                        # CrÃ©er une cellule pour le nom de la propriÃ©tÃ©
                        $nameCell = $htmlDoc.CreateElement("th")
                        $nameCell.InnerHtml = $propName
                        $row.AppendChild($nameCell) | Out-Null
                        
                        # CrÃ©er une cellule pour la valeur de la propriÃ©tÃ©
                        $valueCell = $htmlDoc.CreateElement("td")
                        $row.AppendChild($valueCell) | Out-Null
                        
                        # Convertir la valeur de la propriÃ©tÃ© de maniÃ¨re rÃ©cursive
                        ConvertObjectToHtml $valueCell $propValue
                    }
                }
                
                # Array ou Collection
                { $_ -match "Array|Collection|List" } {
                    # CrÃ©er une liste HTML
                    $list = $htmlDoc.CreateElement("ul")
                    $node.AppendChild($list) | Out-Null
                    
                    foreach ($item in $obj) {
                        # CrÃ©er un Ã©lÃ©ment de liste pour l'item
                        $listItem = $htmlDoc.CreateElement("li")
                        $list.AppendChild($listItem) | Out-Null
                        
                        # Convertir l'item de maniÃ¨re rÃ©cursive
                        ConvertObjectToHtml $listItem $item
                    }
                }
                
                # Type par dÃ©faut
                default {
                    # Essayer de traiter comme un objet avec des propriÃ©tÃ©s
                    try {
                        # CrÃ©er une div pour l'objet
                        $div = $htmlDoc.CreateElement("div")
                        $node.AppendChild($div) | Out-Null
                        
                        foreach ($prop in $obj.PSObject.Properties) {
                            # CrÃ©er un paragraphe pour la propriÃ©tÃ©
                            $p = $htmlDoc.CreateElement("p")
                            $div.AppendChild($p) | Out-Null
                            
                            # Ajouter le nom de la propriÃ©tÃ©
                            $strong = $htmlDoc.CreateElement("strong")
                            $strong.InnerHtml = $prop.Name + ": "
                            $p.AppendChild($strong) | Out-Null
                            
                            # Convertir la valeur de la propriÃ©tÃ© de maniÃ¨re rÃ©cursive
                            ConvertObjectToHtml $p $prop.Value
                        }
                    }
                    catch {
                        # Si tout Ã©choue, convertir en chaÃ®ne
                        $textNode = $htmlDoc.CreateTextNode($obj.ToString())
                        $node.AppendChild($textNode) | Out-Null
                    }
                }
            }
        }
        
        # Convertir l'objet en HTML
        ConvertObjectToHtml $bodyNode $InputObject
        
        return $htmlDoc
    }
}

# Fonction pour Ã©crire un document HTML dans un fichier
function Export-HtmlFile {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF-8"
    )
    
    process {
        # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
        $directory = Split-Path -Path $FilePath -Parent
        if (-not [string]::IsNullOrEmpty($directory) -and -not (Test-Path -Path $directory)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer le document HTML
        $HtmlDocument.Save($FilePath, [System.Text.Encoding]::GetEncoding($Encoding))
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Install-HtmlAgilityPack, Test-HtmlAgilityPackAvailable, New-HtmlDocument
Export-ModuleMember -Function ConvertFrom-Html, ConvertTo-Html, Import-HtmlFile, Export-HtmlFile
Export-ModuleMember -Function Invoke-CssQuery, Invoke-HtmlSanitization, ConvertTo-PlainText, ConvertTo-Xml
