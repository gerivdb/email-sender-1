# Module de gestion du format HTML
# Ce script implémente les fonctionnalités de base pour le support du format HTML
# Nécessite HtmlAgilityPack (peut être installé via Install-Package HtmlAgilityPack)

# Configuration
$HTMLConfig = @{
    # Paramètres par défaut pour le parsing HTML
    DefaultHtmlSettings = @{
        FixNestedTags = $true
        AutoCloseOnEnd = $true
        CheckSyntax = $true
        DefaultEncoding = "UTF-8"
    }
    
    # Paramètres par défaut pour la sanitisation HTML
    DefaultSanitizationSettings = @{
        EnableSanitization = $true
        AllowedTags = @("a", "b", "blockquote", "br", "code", "div", "em", "h1", "h2", "h3", 
                        "img", "li", "ol", "p", "pre", "span", "strong", "table", "td", "th", "tr", "ul")
        AllowedAttributes = @("href", "src", "alt", "title", "class", "id")
        AllowedProtocols = @("http", "https", "mailto")
    }
    
    # Paramètres par défaut pour la génération HTML
    DefaultGenerationSettings = @{
        Doctype = "<!DOCTYPE html>"
        Encoding = "UTF-8"
        IndentOutput = $true
    }
}

# Fonction pour vérifier si HtmlAgilityPack est disponible
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
        Write-Host "HtmlAgilityPack est déjà installé."
        return $true
    }
    
    try {
        # Vérifier si NuGet est disponible
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
        
        Write-Host "HtmlAgilityPack a été installé avec succès."
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'installation de HtmlAgilityPack: $_"
        return $false
    }
}

# Fonction pour créer un nouveau document HTML
function New-HtmlDocument {
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$HtmlSettings
    )
    
    # Vérifier si HtmlAgilityPack est disponible
    if (-not (Test-HtmlAgilityPackAvailable)) {
        if (-not (Install-HtmlAgilityPack)) {
            throw "HtmlAgilityPack n'est pas disponible et n'a pas pu être installé."
        }
    }
    
    # Utiliser les paramètres fournis ou les valeurs par défaut
    $settings = if ($HtmlSettings) { $HtmlSettings } else { $HTMLConfig.DefaultHtmlSettings.Clone() }
    
    # Créer un document HTML
    $htmlDoc = New-Object HtmlAgilityPack.HtmlDocument
    
    # Configurer les options
    $htmlDoc.OptionFixNestedTags = $settings.FixNestedTags
    $htmlDoc.OptionAutoCloseOnEnd = $settings.AutoCloseOnEnd
    $htmlDoc.OptionCheckSyntax = $settings.CheckSyntax
    $htmlDoc.OptionDefaultStreamEncoding = [System.Text.Encoding]::GetEncoding($settings.DefaultEncoding)
    
    return $htmlDoc
}

# Fonction pour parser une chaîne HTML
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
        # Créer un document HTML
        $htmlDoc = New-HtmlDocument -HtmlSettings $HtmlSettings
        
        # Charger le contenu HTML
        $htmlDoc.LoadHtml($HtmlString)
        
        # Sanitiser le document si demandé
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
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier HTML n'existe pas: $FilePath"
    }
    
    # Créer un document HTML
    $htmlDoc = New-HtmlDocument -HtmlSettings $HtmlSettings
    
    # Charger le fichier HTML
    $htmlDoc.Load($FilePath)
    
    # Sanitiser le document si demandé
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
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $settings = if ($SanitizationSettings) { $SanitizationSettings } else { $HTMLConfig.DefaultSanitizationSettings.Clone() }
        
        # Créer une copie du document
        $sanitizedDoc = New-Object HtmlAgilityPack.HtmlDocument
        $sanitizedDoc.LoadHtml($HtmlDocument.DocumentNode.OuterHtml)
        
        # Obtenir tous les nœuds
        $nodes = $sanitizedDoc.DocumentNode.SelectNodes("//*")
        
        if ($null -eq $nodes) {
            return $sanitizedDoc
        }
        
        # Parcourir les nœuds en ordre inverse pour éviter les problèmes lors de la suppression
        for ($i = $nodes.Count - 1; $i -ge 0; $i--) {
            $node = $nodes[$i]
            
            # Vérifier si le tag est autorisé
            if ($node.NodeType -eq [HtmlAgilityPack.HtmlNodeType]::Element -and 
                $settings.AllowedTags -notcontains $node.Name.ToLower()) {
                # Remplacer le nœud par son contenu
                $node.ParentNode.ReplaceChild($sanitizedDoc.CreateTextNode($node.InnerText), $node)
                continue
            }
            
            # Vérifier les attributs
            if ($node.HasAttributes) {
                $attributesToRemove = @()
                
                foreach ($attr in $node.Attributes) {
                    # Vérifier si l'attribut est autorisé
                    if ($settings.AllowedAttributes -notcontains $attr.Name.ToLower()) {
                        $attributesToRemove += $attr.Name
                        continue
                    }
                    
                    # Vérifier les URLs dans les attributs href et src
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
                
                # Supprimer les attributs non autorisés
                foreach ($attrName in $attributesToRemove) {
                    $node.Attributes.Remove($attrName)
                }
            }
        }
        
        return $sanitizedDoc
    }
}

# Fonction pour exécuter une requête CSS sur un document HTML
function Invoke-CssQuery {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [HtmlAgilityPack.HtmlDocument]$HtmlDocument,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$CssSelector
    )
    
    process {
        try {
            # Exécuter la requête CSS
            $nodes = $HtmlDocument.DocumentNode.SelectNodes($CssSelector)
            
            # Retourner les nœuds trouvés
            return $nodes
        }
        catch {
            Write-Error "Erreur lors de l'exécution de la requête CSS: $_"
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
        # Créer un document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        
        # Créer un nœud racine
        $root = $xmlDoc.CreateElement("html")
        $xmlDoc.AppendChild($root) | Out-Null
        
        # Fonction récursive pour convertir les nœuds HTML en nœuds XML
        function ConvertNode($htmlNode, $xmlParent) {
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
                        ConvertNode $childNode $xmlElement
                    }
                }
                ([HtmlAgilityPack.HtmlNodeType]::Text) {
                    # Créer un nœud texte
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

# Fonction pour générer un document HTML à partir d'un objet
function ConvertTo-Html {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$GenerationSettings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $settings = if ($GenerationSettings) { $GenerationSettings } else { $HTMLConfig.DefaultGenerationSettings.Clone() }
        
        # Créer un document HTML
        $htmlDoc = New-HtmlDocument
        
        # Créer un document HTML de base
        $html = $settings.Doctype + "`n<html><head><meta charset=`"" + $settings.Encoding + "`"></head><body></body></html>"
        $htmlDoc.LoadHtml($html)
        
        # Obtenir le nœud body
        $bodyNode = $htmlDoc.DocumentNode.SelectSingleNode("//body")
        
        # Fonction récursive pour convertir un objet en HTML
        function ConvertObjectToHtml($node, $obj) {
            # Si l'objet est null, ne rien faire
            if ($null -eq $obj) {
                return
            }
            
            # Traiter différents types d'objets
            switch ($obj.GetType().Name) {
                # Types simples
                { $_ -in @("String", "Int32", "Int64", "Double", "Decimal", "Boolean", "DateTime", "Guid") } {
                    $textNode = $htmlDoc.CreateTextNode($obj.ToString())
                    $node.AppendChild($textNode) | Out-Null
                }
                
                # Hashtable ou PSCustomObject
                { $_ -in @("Hashtable", "PSCustomObject") } {
                    $properties = if ($_ -eq "Hashtable") { $obj.Keys } else { $obj.PSObject.Properties.Name }
                    
                    # Créer une table HTML
                    $table = $htmlDoc.CreateElement("table")
                    $node.AppendChild($table) | Out-Null
                    
                    foreach ($propName in $properties) {
                        $propValue = if ($_ -eq "Hashtable") { $obj[$propName] } else { $obj.$propName }
                        
                        # Créer une ligne pour la propriété
                        $row = $htmlDoc.CreateElement("tr")
                        $table.AppendChild($row) | Out-Null
                        
                        # Créer une cellule pour le nom de la propriété
                        $nameCell = $htmlDoc.CreateElement("th")
                        $nameCell.InnerHtml = $propName
                        $row.AppendChild($nameCell) | Out-Null
                        
                        # Créer une cellule pour la valeur de la propriété
                        $valueCell = $htmlDoc.CreateElement("td")
                        $row.AppendChild($valueCell) | Out-Null
                        
                        # Convertir la valeur de la propriété de manière récursive
                        ConvertObjectToHtml $valueCell $propValue
                    }
                }
                
                # Array ou Collection
                { $_ -match "Array|Collection|List" } {
                    # Créer une liste HTML
                    $list = $htmlDoc.CreateElement("ul")
                    $node.AppendChild($list) | Out-Null
                    
                    foreach ($item in $obj) {
                        # Créer un élément de liste pour l'item
                        $listItem = $htmlDoc.CreateElement("li")
                        $list.AppendChild($listItem) | Out-Null
                        
                        # Convertir l'item de manière récursive
                        ConvertObjectToHtml $listItem $item
                    }
                }
                
                # Type par défaut
                default {
                    # Essayer de traiter comme un objet avec des propriétés
                    try {
                        # Créer une div pour l'objet
                        $div = $htmlDoc.CreateElement("div")
                        $node.AppendChild($div) | Out-Null
                        
                        foreach ($prop in $obj.PSObject.Properties) {
                            # Créer un paragraphe pour la propriété
                            $p = $htmlDoc.CreateElement("p")
                            $div.AppendChild($p) | Out-Null
                            
                            # Ajouter le nom de la propriété
                            $strong = $htmlDoc.CreateElement("strong")
                            $strong.InnerHtml = $prop.Name + ": "
                            $p.AppendChild($strong) | Out-Null
                            
                            # Convertir la valeur de la propriété de manière récursive
                            ConvertObjectToHtml $p $prop.Value
                        }
                    }
                    catch {
                        # Si tout échoue, convertir en chaîne
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

# Fonction pour écrire un document HTML dans un fichier
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
        # Créer le répertoire parent si nécessaire
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
