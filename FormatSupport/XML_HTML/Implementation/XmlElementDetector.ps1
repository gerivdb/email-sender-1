# Module de détection des éléments XML
# Ce script implémente les fonctionnalités pour détecter et analyser les éléments XML

# Configuration
$XmlDetectorConfig = @{
    # Paramètres par défaut pour la détection des éléments XML
    DefaultDetectionSettings = @{
        IncludeAttributes = $true
        IncludeNamespaces = $true
        IncludeValues = $true
        MaxDepth = 0  # 0 = illimité
        IgnoreComments = $true
        IgnoreProcessingInstructions = $true
        IgnoreWhitespace = $true
    }
}

# Classe pour représenter un élément XML
class XmlElementInfo {
    [string]$Name
    [string]$Path
    [int]$Depth
    [hashtable]$Attributes
    [string]$Value
    [string]$Namespace
    [string]$NamespaceUri
    [System.Collections.ArrayList]$Children
    
    XmlElementInfo([string]$name, [string]$path, [int]$depth) {
        $this.Name = $name
        $this.Path = $path
        $this.Depth = $depth
        $this.Attributes = @{}
        $this.Value = ""
        $this.Namespace = ""
        $this.NamespaceUri = ""
        $this.Children = New-Object System.Collections.ArrayList
    }
    
    [string] ToString() {
        $result = "$($this.Path) ($($this.Name))"
        
        if ($this.Namespace) {
            $result += " [Namespace: $($this.Namespace)]"
        }
        
        if ($this.Attributes.Count -gt 0) {
            $result += " [Attributes: $($this.Attributes.Count)]"
        }
        
        if ($this.Children.Count -gt 0) {
            $result += " [Children: $($this.Children.Count)]"
        }
        
        return $result
    }
}

# Fonction pour détecter les éléments XML dans une chaîne
function Get-XmlElements {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$XmlContent,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $config = if ($Settings) { 
            $mergedSettings = $XmlDetectorConfig.DefaultDetectionSettings.Clone()
            foreach ($key in $Settings.Keys) {
                $mergedSettings[$key] = $Settings[$key]
            }
            $mergedSettings
        } else { 
            $XmlDetectorConfig.DefaultDetectionSettings.Clone() 
        }
        
        # Charger le document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        
        try {
            $xmlDoc.LoadXml($XmlContent)
        }
        catch {
            throw "Erreur lors du chargement du XML: $_"
        }
        
        # Créer un tableau pour stocker les éléments
        $elements = New-Object System.Collections.ArrayList
        
        # Analyser les éléments de manière récursive
        $rootElement = $xmlDoc.DocumentElement
        $rootInfo = [XmlElementInfo]::new($rootElement.LocalName, "/$($rootElement.LocalName)", 0)
        
        # Ajouter les attributs du nœud racine
        if ($config.IncludeAttributes -and $rootElement.HasAttributes) {
            foreach ($attr in $rootElement.Attributes) {
                if ($attr.Name -ne "xmlns" -and -not $attr.Name.StartsWith("xmlns:")) {
                    $rootInfo.Attributes[$attr.Name] = $attr.Value
                }
            }
        }
        
        # Ajouter les informations de namespace du nœud racine
        if ($config.IncludeNamespaces -and $rootElement.NamespaceURI) {
            $rootInfo.Namespace = $rootElement.Prefix
            $rootInfo.NamespaceUri = $rootElement.NamespaceURI
        }
        
        # Ajouter la valeur du nœud racine
        if ($config.IncludeValues -and $rootElement.InnerText) {
            $rootInfo.Value = $rootElement.InnerText
        }
        
        [void]$elements.Add($rootInfo)
        
        # Fonction récursive pour analyser les nœuds enfants
        function Process-XmlNode {
            param (
                [System.Xml.XmlNode]$Node,
                [XmlElementInfo]$ParentInfo,
                [int]$CurrentDepth
            )
            
            # Vérifier la profondeur maximale
            if ($config.MaxDepth -gt 0 -and $CurrentDepth -ge $config.MaxDepth) {
                return
            }
            
            # Parcourir les nœuds enfants
            foreach ($childNode in $Node.ChildNodes) {
                # Ignorer les nœuds de commentaire si demandé
                if ($config.IgnoreComments -and $childNode.NodeType -eq [System.Xml.XmlNodeType]::Comment) {
                    continue
                }
                
                # Ignorer les nœuds d'instruction de traitement si demandé
                if ($config.IgnoreProcessingInstructions -and $childNode.NodeType -eq [System.Xml.XmlNodeType]::ProcessingInstruction) {
                    continue
                }
                
                # Ignorer les nœuds de texte vide si demandé
                if ($config.IgnoreWhitespace -and $childNode.NodeType -eq [System.Xml.XmlNodeType]::Text -and [string]::IsNullOrWhiteSpace($childNode.Value)) {
                    continue
                }
                
                # Traiter uniquement les nœuds d'élément
                if ($childNode.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                    $childPath = "$($ParentInfo.Path)/$($childNode.LocalName)"
                    $childInfo = [XmlElementInfo]::new($childNode.LocalName, $childPath, $CurrentDepth + 1)
                    
                    # Ajouter les attributs
                    if ($config.IncludeAttributes -and $childNode.HasAttributes) {
                        foreach ($attr in $childNode.Attributes) {
                            if ($attr.Name -ne "xmlns" -and -not $attr.Name.StartsWith("xmlns:")) {
                                $childInfo.Attributes[$attr.Name] = $attr.Value
                            }
                        }
                    }
                    
                    # Ajouter les informations de namespace
                    if ($config.IncludeNamespaces -and $childNode.NamespaceURI) {
                        $childInfo.Namespace = $childNode.Prefix
                        $childInfo.NamespaceUri = $childNode.NamespaceURI
                    }
                    
                    # Ajouter la valeur
                    if ($config.IncludeValues -and $childNode.InnerText) {
                        $childInfo.Value = $childNode.InnerText
                    }
                    
                    # Ajouter l'élément à la liste des enfants du parent
                    [void]$ParentInfo.Children.Add($childInfo)
                    
                    # Ajouter l'élément à la liste globale
                    [void]$elements.Add($childInfo)
                    
                    # Traiter les nœuds enfants de manière récursive
                    Process-XmlNode -Node $childNode -ParentInfo $childInfo -CurrentDepth ($CurrentDepth + 1)
                }
            }
        }
        
        # Démarrer l'analyse récursive
        Process-XmlNode -Node $rootElement -ParentInfo $rootInfo -CurrentDepth 0
        
        return $elements
    }
}

# Fonction pour détecter les éléments XML dans un fichier
function Get-XmlElementsFromFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $XmlPath)) {
        throw "Le fichier XML n'existe pas: $XmlPath"
    }
    
    # Lire le contenu du fichier XML
    $xmlContent = Get-Content -Path $XmlPath -Raw
    
    # Détecter les éléments XML
    return Get-XmlElements -XmlContent $xmlContent -Settings $Settings
}

# Fonction pour générer un rapport sur la structure XML
function Get-XmlStructureReport {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$XmlContent,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsHtml
    )
    
    process {
        # Détecter les éléments XML
        $elements = Get-XmlElements -XmlContent $XmlContent -Settings $Settings
        
        # Créer un rapport
        if ($AsHtml) {
            # Générer un rapport HTML
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de structure XML</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .element-name { font-weight: bold; }
        .element-path { color: #666; }
        .element-attributes { color: #0066cc; }
        .element-value { color: #009900; }
        .element-namespace { color: #cc6600; }
        .depth-0 { background-color: #f2f2f2; }
        .depth-1 { padding-left: 20px; }
        .depth-2 { padding-left: 40px; }
        .depth-3 { padding-left: 60px; }
        .depth-4 { padding-left: 80px; }
        .depth-5 { padding-left: 100px; }
    </style>
</head>
<body>
    <h1>Rapport de structure XML</h1>
    
    <h2>Résumé</h2>
    <p>Nombre total d'éléments: $($elements.Count)</p>
    <p>Profondeur maximale: $($elements | Measure-Object -Property Depth -Maximum | Select-Object -ExpandProperty Maximum)</p>
    <p>Nombre d'éléments avec attributs: $($elements | Where-Object { $_.Attributes.Count -gt 0 } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    <p>Nombre d'éléments avec namespace: $($elements | Where-Object { $_.Namespace } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    
    <h2>Structure des éléments</h2>
    <table>
        <tr>
            <th>Élément</th>
            <th>Chemin</th>
            <th>Profondeur</th>
            <th>Attributs</th>
            <th>Namespace</th>
            <th>Valeur</th>
        </tr>
"@
            
            foreach ($element in $elements) {
                $html += @"
        <tr class="depth-$($element.Depth)">
            <td class="element-name">$($element.Name)</td>
            <td class="element-path">$($element.Path)</td>
            <td>$($element.Depth)</td>
            <td class="element-attributes">
"@
                
                if ($element.Attributes.Count -gt 0) {
                    $html += "<ul>"
                    foreach ($attrName in $element.Attributes.Keys) {
                        $html += "<li>$attrName = $($element.Attributes[$attrName])</li>"
                    }
                    $html += "</ul>"
                }
                
                $html += @"
            </td>
            <td class="element-namespace">$($element.Namespace)$($element.NamespaceUri)</td>
            <td class="element-value">$($element.Value)</td>
        </tr>
"@
            }
            
            $html += @"
    </table>
</body>
</html>
"@
            
            return $html
        }
        else {
            # Générer un rapport texte
            $report = "Rapport de structure XML`n"
            $report += "======================`n`n"
            
            $report += "Résumé`n"
            $report += "------`n"
            $report += "Nombre total d'éléments: $($elements.Count)`n"
            $report += "Profondeur maximale: $($elements | Measure-Object -Property Depth -Maximum | Select-Object -ExpandProperty Maximum)`n"
            $report += "Nombre d'éléments avec attributs: $($elements | Where-Object { $_.Attributes.Count -gt 0 } | Measure-Object | Select-Object -ExpandProperty Count)`n"
            $report += "Nombre d'éléments avec namespace: $($elements | Where-Object { $_.Namespace } | Measure-Object | Select-Object -ExpandProperty Count)`n`n"
            
            $report += "Structure des éléments`n"
            $report += "---------------------`n"
            
            foreach ($element in $elements) {
                $indent = "  " * $element.Depth
                $report += "$indent- $($element.Name) ($($element.Path))`n"
                
                if ($element.Attributes.Count -gt 0) {
                    $report += "$indent  Attributs:`n"
                    foreach ($attrName in $element.Attributes.Keys) {
                        $report += "$indent    $attrName = $($element.Attributes[$attrName])`n"
                    }
                }
                
                if ($element.Namespace) {
                    $report += "$indent  Namespace: $($element.Namespace) ($($element.NamespaceUri))`n"
                }
                
                if ($element.Value) {
                    $report += "$indent  Valeur: $($element.Value)`n"
                }
                
                $report += "`n"
            }
            
            return $report
        }
    }
}

# Fonction pour générer un rapport sur la structure XML d'un fichier
function Get-XmlStructureReportFromFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsHtml,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $XmlPath)) {
        throw "Le fichier XML n'existe pas: $XmlPath"
    }
    
    # Lire le contenu du fichier XML
    $xmlContent = Get-Content -Path $XmlPath -Raw
    
    # Générer le rapport
    $report = Get-XmlStructureReport -XmlContent $xmlContent -Settings $Settings -AsHtml:$AsHtml
    
    # Enregistrer le rapport si un chemin de sortie est spécifié
    if ($OutputPath) {
        # Créer le répertoire de destination si nécessaire
        $outputDir = Split-Path -Path $OutputPath -Parent
        
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Déterminer l'encodage en fonction du format
        $encoding = if ($AsHtml) { "UTF8" } else { "ASCII" }
        
        # Enregistrer le rapport
        Set-Content -Path $OutputPath -Value $report -Encoding $encoding
        
        return $OutputPath
    }
    
    return $report
}

# Fonction pour mapper les éléments XML vers la structure de roadmap
function ConvertTo-RoadmapMapping {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$XmlContent
    )
    
    process {
        # Détecter les éléments XML
        $elements = Get-XmlElements -XmlContent $XmlContent
        
        # Créer un mapping
        $mapping = @{
            RootElement = $null
            Sections = @()
            Phases = @()
            Tasks = @()
            Subtasks = @()
            Notes = @()
            Metadata = @()
        }
        
        # Analyser les éléments
        foreach ($element in $elements) {
            # Identifier l'élément racine
            if ($element.Depth -eq 0) {
                $mapping.RootElement = $element
                continue
            }
            
            # Identifier les sections
            if ($element.Name -eq "section") {
                $mapping.Sections += $element
                continue
            }
            
            # Identifier les phases
            if ($element.Name -eq "phase") {
                $mapping.Phases += $element
                continue
            }
            
            # Identifier les tâches
            if ($element.Name -eq "task") {
                $mapping.Tasks += $element
                continue
            }
            
            # Identifier les sous-tâches
            if ($element.Name -eq "subtask") {
                $mapping.Subtasks += $element
                continue
            }
            
            # Identifier les notes
            if ($element.Name -eq "note") {
                $mapping.Notes += $element
                continue
            }
            
            # Identifier les métadonnées
            if ($element.Name -eq "metadata" -or $element.Path -match "/section/metadata/") {
                $mapping.Metadata += $element
                continue
            }
        }
        
        # Générer un rapport de mapping
        $report = "Mapping XML vers Roadmap`n"
        $report += "======================`n`n"
        
        $report += "Élément racine: $($mapping.RootElement.Name) ($($mapping.RootElement.Path))`n`n"
        
        $report += "Sections ($($mapping.Sections.Count)):`n"
        foreach ($section in $mapping.Sections) {
            $report += "  - $($section.Name) ($($section.Path))`n"
            $report += "    ID: $($section.Attributes["id"])`n"
            $report += "    Titre: $($section.Attributes["title"])`n`n"
        }
        
        $report += "Phases ($($mapping.Phases.Count)):`n"
        foreach ($phase in $mapping.Phases) {
            $report += "  - $($phase.Name) ($($phase.Path))`n"
            $report += "    ID: $($phase.Attributes["id"])`n"
            $report += "    Titre: $($phase.Attributes["title"])`n"
            $report += "    Terminée: $($phase.Attributes["completed"])`n`n"
        }
        
        $report += "Tâches ($($mapping.Tasks.Count)):`n"
        foreach ($task in $mapping.Tasks) {
            $report += "  - $($task.Name) ($($task.Path))`n"
            $report += "    Titre: $($task.Attributes["title"])`n"
            $report += "    Temps estimé: $($task.Attributes["estimatedTime"])`n"
            $report += "    Date de début: $($task.Attributes["startDate"])`n"
            $report += "    Terminée: $($task.Attributes["completed"])`n`n"
        }
        
        $report += "Sous-tâches ($($mapping.Subtasks.Count)):`n"
        foreach ($subtask in $mapping.Subtasks) {
            $report += "  - $($subtask.Name) ($($subtask.Path))`n"
            $report += "    Titre: $($subtask.Attributes["title"])`n"
            $report += "    Terminée: $($subtask.Attributes["completed"])`n`n"
        }
        
        $report += "Notes ($($mapping.Notes.Count)):`n"
        foreach ($note in $mapping.Notes) {
            $report += "  - $($note.Name) ($($note.Path))`n"
            $report += "    Texte: $($note.Value)`n`n"
        }
        
        $report += "Métadonnées ($($mapping.Metadata.Count)):`n"
        foreach ($metadata in $mapping.Metadata) {
            $report += "  - $($metadata.Name) ($($metadata.Path))`n"
            
            if ($metadata.Name -eq "metadata") {
                $report += "    Éléments enfants:`n"
                foreach ($child in $metadata.Children) {
                    $report += "      - $($child.Name): $($child.Value)`n"
                }
            }
            else {
                $report += "    Valeur: $($metadata.Value)`n"
            }
            
            $report += "`n"
        }
        
        return @{
            Mapping = $mapping
            Report = $report
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-XmlElements, Get-XmlElementsFromFile
Export-ModuleMember -Function Get-XmlStructureReport, Get-XmlStructureReportFromFile
Export-ModuleMember -Function ConvertTo-RoadmapMapping
