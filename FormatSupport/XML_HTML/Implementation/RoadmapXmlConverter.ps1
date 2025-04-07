# Module de conversion entre format Roadmap (Markdown) et XML
# Ce script implémente les fonctionnalités pour convertir une roadmap en XML et vice versa

# Configuration
$RoadmapXmlConfig = @{
    # Paramètres par défaut pour la conversion Roadmap vers XML
    DefaultRoadmapToXmlSettings = @{
        IncludeXmlDeclaration = $true
        Encoding = "UTF-8"
        Indent = $true
        IndentChars = "  "
        RootElementName = "roadmap"
        SectionElementName = "section"
        PhaseElementName = "phase"
        TaskElementName = "task"
        SubtaskElementName = "subtask"
        NoteElementName = "note"
        MetadataElementName = "metadata"
    }
    
    # Paramètres par défaut pour la conversion XML vers Roadmap
    DefaultXmlToRoadmapSettings = @{
        RootElementName = "roadmap"
        SectionElementName = "section"
        PhaseElementName = "phase"
        TaskElementName = "task"
        SubtaskElementName = "subtask"
        NoteElementName = "note"
        MetadataElementName = "metadata"
        DefaultIndent = "  "
    }
}

# Fonction pour convertir une chaîne Markdown en document XML
function ConvertFrom-RoadmapToXml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$RoadmapContent,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $config = if ($Settings) { 
            $mergedSettings = $RoadmapXmlConfig.DefaultRoadmapToXmlSettings.Clone()
            foreach ($key in $Settings.Keys) {
                $mergedSettings[$key] = $Settings[$key]
            }
            $mergedSettings
        } else { 
            $RoadmapXmlConfig.DefaultRoadmapToXmlSettings.Clone() 
        }
        
        # Créer un document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        
        # Ajouter la déclaration XML si demandé
        if ($config.IncludeXmlDeclaration) {
            $xmlDecl = $xmlDoc.CreateXmlDeclaration("1.0", $config.Encoding, $null)
            [void]$xmlDoc.AppendChild($xmlDecl)
        }
        
        # Créer l'élément racine
        $rootElement = $xmlDoc.CreateElement($config.RootElementName)
        [void]$xmlDoc.AppendChild($rootElement)
        
        # Extraire le titre de la roadmap
        $titleMatch = [regex]::Match($RoadmapContent, "^# (.+)$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($titleMatch.Success) {
            $rootElement.SetAttribute("title", $titleMatch.Groups[1].Value)
        }
        
        # Extraire la vue d'ensemble
        $overviewMatch = [regex]::Match($RoadmapContent, "(?s)^## Vue d'ensemble.+?\n\n(.+?)(?=\n\n## )")
        if ($overviewMatch.Success) {
            $overviewElement = $xmlDoc.CreateElement("overview")
            $overviewElement.InnerText = $overviewMatch.Groups[1].Value.Trim()
            [void]$rootElement.AppendChild($overviewElement)
        }
        
        # Extraire les sections
        $sectionMatches = [regex]::Matches($RoadmapContent, "(?s)^## (\d+)\. (.+?)\n(.+?)(?=\n\n## |$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        foreach ($sectionMatch in $sectionMatches) {
            $sectionId = $sectionMatch.Groups[1].Value
            $sectionTitle = $sectionMatch.Groups[2].Value
            $sectionContent = $sectionMatch.Groups[3].Value
            
            # Créer l'élément de section
            $sectionElement = $xmlDoc.CreateElement($config.SectionElementName)
            $sectionElement.SetAttribute("id", $sectionId)
            $sectionElement.SetAttribute("title", $sectionTitle)
            
            # Extraire les métadonnées
            $metadataMatches = [regex]::Matches($sectionContent, "\*\*(.+?)\*\*: (.+?)(?=\n\*\*|\n\n)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
            if ($metadataMatches.Count -gt 0) {
                $metadataElement = $xmlDoc.CreateElement($config.MetadataElementName)
                
                foreach ($metadataMatch in $metadataMatches) {
                    $metadataKey = $metadataMatch.Groups[1].Value
                    $metadataValue = $metadataMatch.Groups[2].Value
                    
                    # Convertir la clé en nom d'élément XML valide
                    $metadataKeyElement = ConvertTo-ValidXmlName $metadataKey
                    
                    $metadataItemElement = $xmlDoc.CreateElement($metadataKeyElement)
                    $metadataItemElement.InnerText = $metadataValue.Trim()
                    [void]$metadataElement.AppendChild($metadataItemElement)
                }
                
                [void]$sectionElement.AppendChild($metadataElement)
            }
            
            # Extraire les phases
            $phaseMatches = [regex]::Matches($sectionContent, "(?s)- \[([ x])\] \*\*Phase (\d+): (.+?)\*\*(.+?)(?=\n- \[|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
            foreach ($phaseMatch in $phaseMatches) {
                $phaseCompleted = $phaseMatch.Groups[1].Value -eq "x"
                $phaseId = $phaseMatch.Groups[2].Value
                $phaseTitle = $phaseMatch.Groups[3].Value
                $phaseContent = $phaseMatch.Groups[4].Value
                
                # Créer l'élément de phase
                $phaseElement = $xmlDoc.CreateElement($config.PhaseElementName)
                $phaseElement.SetAttribute("id", $phaseId)
                $phaseElement.SetAttribute("title", $phaseTitle)
                $phaseElement.SetAttribute("completed", $phaseCompleted.ToString().ToLower())
                
                # Extraire les tâches
                $taskMatches = [regex]::Matches($phaseContent, "(?s)\n  - \[([ x])\] (.+?)(?=\n  - \[|\n\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
                
                foreach ($taskMatch in $taskMatches) {
                    $taskCompleted = $taskMatch.Groups[1].Value -eq "x"
                    $taskContent = $taskMatch.Groups[2].Value
                    
                    # Extraire le titre, le temps estimé et la date de début
                    $taskTitleMatch = [regex]::Match($taskContent, "(.+?)(?:\s+\((.+?)\))?(?:\s+-\s+\*(.+?)\*)?$")
                    
                    $taskTitle = $taskTitleMatch.Groups[1].Value
                    $taskEstimatedTime = if ($taskTitleMatch.Groups[2].Success) { $taskTitleMatch.Groups[2].Value } else { "" }
                    $taskStartDate = if ($taskTitleMatch.Groups[3].Success) { $taskTitleMatch.Groups[3].Value } else { "" }
                    
                    # Créer l'élément de tâche
                    $taskElement = $xmlDoc.CreateElement($config.TaskElementName)
                    $taskElement.SetAttribute("title", $taskTitle)
                    
                    if ($taskEstimatedTime) {
                        $taskElement.SetAttribute("estimatedTime", $taskEstimatedTime)
                    }
                    
                    if ($taskStartDate) {
                        $taskElement.SetAttribute("startDate", $taskStartDate)
                    }
                    
                    $taskElement.SetAttribute("completed", $taskCompleted.ToString().ToLower())
                    
                    # Extraire les sous-tâches
                    $subtaskMatches = [regex]::Matches($phaseContent, "(?s)\n    - \[([ x])\] (.+?)(?=\n    - \[|\n  - \[|\n\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
                    
                    foreach ($subtaskMatch in $subtaskMatches) {
                        $subtaskCompleted = $subtaskMatch.Groups[1].Value -eq "x"
                        $subtaskTitle = $subtaskMatch.Groups[2].Value
                        
                        # Créer l'élément de sous-tâche
                        $subtaskElement = $xmlDoc.CreateElement($config.SubtaskElementName)
                        $subtaskElement.SetAttribute("title", $subtaskTitle)
                        $subtaskElement.SetAttribute("completed", $subtaskCompleted.ToString().ToLower())
                        
                        [void]$taskElement.AppendChild($subtaskElement)
                    }
                    
                    [void]$phaseElement.AppendChild($taskElement)
                }
                
                # Extraire les notes
                $noteMatches = [regex]::Matches($phaseContent, "(?s)\n  > \*Note: (.+?)\*(?=\n  >|\n\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
                
                foreach ($noteMatch in $noteMatches) {
                    $noteText = $noteMatch.Groups[1].Value
                    
                    # Créer l'élément de note
                    $noteElement = $xmlDoc.CreateElement($config.NoteElementName)
                    $noteElement.InnerText = $noteText
                    
                    [void]$phaseElement.AppendChild($noteElement)
                }
                
                [void]$sectionElement.AppendChild($phaseElement)
            }
            
            [void]$rootElement.AppendChild($sectionElement)
        }
        
        # Convertir le document XML en chaîne
        $stringWriter = New-Object System.IO.StringWriter
        $xmlSettings = New-Object System.Xml.XmlWriterSettings
        $xmlSettings.Indent = $config.Indent
        $xmlSettings.IndentChars = $config.IndentChars
        $xmlSettings.Encoding = [System.Text.Encoding]::GetEncoding($config.Encoding)
        
        $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $xmlSettings)
        $xmlDoc.WriteTo($xmlWriter)
        $xmlWriter.Flush()
        $stringWriter.Flush()
        
        return $stringWriter.ToString()
    }
}

# Fonction pour convertir un document XML en chaîne Markdown
function ConvertFrom-XmlToRoadmap {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$XmlContent,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $config = if ($Settings) { 
            $mergedSettings = $RoadmapXmlConfig.DefaultXmlToRoadmapSettings.Clone()
            foreach ($key in $Settings.Keys) {
                $mergedSettings[$key] = $Settings[$key]
            }
            $mergedSettings
        } else { 
            $RoadmapXmlConfig.DefaultXmlToRoadmapSettings.Clone() 
        }
        
        # Charger le document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        
        try {
            $xmlDoc.LoadXml($XmlContent)
        }
        catch {
            throw "Erreur lors du chargement du XML: $_"
        }
        
        # Initialiser la chaîne Markdown
        $markdown = ""
        
        # Extraire le titre
        $rootElement = $xmlDoc.DocumentElement
        
        if ($rootElement.Name -ne $config.RootElementName) {
            throw "L'élément racine doit être '$($config.RootElementName)'"
        }
        
        $title = $rootElement.GetAttribute("title")
        
        if ($title) {
            $markdown += "# $title`n`n"
        }
        
        # Extraire la vue d'ensemble
        $overviewElement = $rootElement.SelectSingleNode("overview")
        
        if ($overviewElement) {
            $markdown += "## Vue d'ensemble des taches par priorite et complexite`n`n"
            $markdown += "$($overviewElement.InnerText)`n`n"
        }
        
        # Extraire les sections
        $sectionElements = $rootElement.SelectNodes($config.SectionElementName)
        
        foreach ($sectionElement in $sectionElements) {
            $sectionId = $sectionElement.GetAttribute("id")
            $sectionTitle = $sectionElement.GetAttribute("title")
            
            $markdown += "## $sectionId. $sectionTitle`n"
            
            # Extraire les métadonnées
            $metadataElement = $sectionElement.SelectSingleNode($config.MetadataElementName)
            
            if ($metadataElement) {
                foreach ($metadataItemElement in $metadataElement.ChildNodes) {
                    if ($metadataItemElement.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                        $metadataKey = ConvertFrom-XmlName $metadataItemElement.Name
                        $metadataValue = $metadataItemElement.InnerText
                        
                        $markdown += "**$metadataKey**: $metadataValue`n"
                    }
                }
            }
            
            $markdown += "`n"
            
            # Extraire les phases
            $phaseElements = $sectionElement.SelectNodes($config.PhaseElementName)
            
            foreach ($phaseElement in $phaseElements) {
                $phaseId = $phaseElement.GetAttribute("id")
                $phaseTitle = $phaseElement.GetAttribute("title")
                $phaseCompleted = [System.Convert]::ToBoolean($phaseElement.GetAttribute("completed"))
                
                $phaseCheckmark = if ($phaseCompleted) { "x" } else { " " }
                
                $markdown += "- [$phaseCheckmark] **Phase $phaseId: $phaseTitle**`n"
                
                # Extraire les tâches
                $taskElements = $phaseElement.SelectNodes($config.TaskElementName)
                
                foreach ($taskElement in $taskElements) {
                    $taskTitle = $taskElement.GetAttribute("title")
                    $taskEstimatedTime = $taskElement.GetAttribute("estimatedTime")
                    $taskStartDate = $taskElement.GetAttribute("startDate")
                    $taskCompleted = [System.Convert]::ToBoolean($taskElement.GetAttribute("completed"))
                    
                    $taskCheckmark = if ($taskCompleted) { "x" } else { " " }
                    
                    $taskLine = "  - [$taskCheckmark] $taskTitle"
                    
                    if ($taskEstimatedTime) {
                        $taskLine += " ($taskEstimatedTime)"
                    }
                    
                    if ($taskStartDate) {
                        $taskLine += " - *$taskStartDate*"
                    }
                    
                    $markdown += "$taskLine`n"
                    
                    # Extraire les sous-tâches
                    $subtaskElements = $taskElement.SelectNodes($config.SubtaskElementName)
                    
                    foreach ($subtaskElement in $subtaskElements) {
                        $subtaskTitle = $subtaskElement.GetAttribute("title")
                        $subtaskCompleted = [System.Convert]::ToBoolean($subtaskElement.GetAttribute("completed"))
                        
                        $subtaskCheckmark = if ($subtaskCompleted) { "x" } else { " " }
                        
                        $markdown += "    - [$subtaskCheckmark] $subtaskTitle`n"
                    }
                }
                
                # Extraire les notes
                $noteElements = $phaseElement.SelectNodes($config.NoteElementName)
                
                foreach ($noteElement in $noteElements) {
                    $noteText = $noteElement.InnerText
                    
                    $markdown += "  > *Note: $noteText*`n"
                }
                
                $markdown += "`n"
            }
        }
        
        return $markdown
    }
}

# Fonction pour convertir un fichier Roadmap en fichier XML
function ConvertFrom-RoadmapFileToXmlFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        throw "Le fichier Roadmap n'existe pas: $RoadmapPath"
    }
    
    # Lire le contenu du fichier Roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw
    
    # Convertir le contenu en XML
    $xmlContent = ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent -Settings $Settings
    
    # Créer le répertoire de destination si nécessaire
    $xmlDir = Split-Path -Path $XmlPath -Parent
    
    if (-not [string]::IsNullOrEmpty($xmlDir) -and -not (Test-Path -Path $xmlDir)) {
        New-Item -Path $xmlDir -ItemType Directory -Force | Out-Null
    }
    
    # Écrire le contenu XML dans le fichier de destination
    Set-Content -Path $XmlPath -Value $xmlContent -Encoding UTF8
    
    return $XmlPath
}

# Fonction pour convertir un fichier XML en fichier Roadmap
function ConvertFrom-XmlFileToRoadmapFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $XmlPath)) {
        throw "Le fichier XML n'existe pas: $XmlPath"
    }
    
    # Lire le contenu du fichier XML
    $xmlContent = Get-Content -Path $XmlPath -Raw
    
    # Convertir le contenu en Roadmap
    $roadmapContent = ConvertFrom-XmlToRoadmap -XmlContent $xmlContent -Settings $Settings
    
    # Créer le répertoire de destination si nécessaire
    $roadmapDir = Split-Path -Path $RoadmapPath -Parent
    
    if (-not [string]::IsNullOrEmpty($roadmapDir) -and -not (Test-Path -Path $roadmapDir)) {
        New-Item -Path $roadmapDir -ItemType Directory -Force | Out-Null
    }
    
    # Écrire le contenu Roadmap dans le fichier de destination
    Set-Content -Path $RoadmapPath -Value $roadmapContent -Encoding UTF8
    
    return $RoadmapPath
}

# Fonction utilitaire pour convertir un nom en nom d'élément XML valide
function ConvertTo-ValidXmlName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Remplacer les espaces par des underscores
    $name = $Name -replace '\s+', '_'
    
    # Supprimer les caractères non valides
    $name = $name -replace '[^a-zA-Z0-9_]', ''
    
    # S'assurer que le nom commence par une lettre ou un underscore
    if ($name -match '^[^a-zA-Z_]') {
        $name = '_' + $name
    }
    
    return $name
}

# Fonction utilitaire pour convertir un nom d'élément XML en nom lisible
function ConvertFrom-XmlName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Remplacer les underscores par des espaces
    $name = $Name -replace '_', ' '
    
    # Mettre en majuscule la première lettre de chaque mot
    $name = (Get-Culture).TextInfo.ToTitleCase($name.ToLower())
    
    return $name
}

# Exporter les fonctions
Export-ModuleMember -Function ConvertFrom-RoadmapToXml, ConvertFrom-XmlToRoadmap
Export-ModuleMember -Function ConvertFrom-RoadmapFileToXmlFile, ConvertFrom-XmlFileToRoadmapFile
