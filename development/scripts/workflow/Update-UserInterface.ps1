# Script de mise Ã  jour de l'interface utilisateur
# Ce script met Ã  jour l'interface utilisateur pour inclure les formats XML et HTML

# Chemins des modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$uiPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "UI"

# VÃ©rifier si le dossier UI existe
if (-not (Test-Path -Path $uiPath)) {
    Write-Error "Le dossier UI n'existe pas: $uiPath"
    exit 1
}

# CrÃ©er le dossier XML_HTML dans le dossier UI s'il n'existe pas
$xmlHtmlUiPath = Join-Path -Path $uiPath -ChildPath "XML_HTML"
if (-not (Test-Path -Path $xmlHtmlUiPath)) {
    New-Item -Path $xmlHtmlUiPath -ItemType Directory -Force | Out-Null
}

# CrÃ©er le fichier de configuration UI pour XML
$xmlUiConfig = @"
{
    "formatName": "XML",
    "formatDescription": "Format XML structurÃ©",
    "fileExtensions": [".xml"],
    "icon": "xml-icon.png",
    "actions": [
        {
            "name": "Convertir en Roadmap",
            "description": "Convertir le fichier XML en format Roadmap",
            "command": "ConvertFrom-XmlFileToRoadmapFile -XmlPath '{0}' -RoadmapPath '{1}'",
            "outputExtension": ".md",
            "requiresOutput": true
        },
        {
            "name": "Convertir en HTML",
            "description": "Convertir le fichier XML en format HTML",
            "command": "Convert-FormatFile -InputPath '{0}' -OutputPath '{1}' -InputFormat 'xml' -OutputFormat 'html'",
            "outputExtension": ".html",
            "requiresOutput": true
        },
        {
            "name": "Valider",
            "description": "Valider le fichier XML",
            "command": "Test-XmlFileWithReport -XmlPath '{0}' -OutputPath '{1}' -AsHtml",
            "outputExtension": ".html",
            "requiresOutput": true
        },
        {
            "name": "Analyser la structure",
            "description": "Analyser la structure du fichier XML",
            "command": "Get-XmlStructureReportFromFile -XmlPath '{0}' -OutputPath '{1}' -AsHtml",
            "outputExtension": ".html",
            "requiresOutput": true
        },
        {
            "name": "GÃ©nÃ©rer un schÃ©ma XSD",
            "description": "GÃ©nÃ©rer un schÃ©ma XSD Ã  partir du fichier XML",
            "command": "New-XsdSchemaFromXml -XmlPath '{0}' -SchemaPath '{1}'",
            "outputExtension": ".xsd",
            "requiresOutput": true
        }
    ],
    "viewOptions": [
        {
            "name": "Vue arborescente",
            "description": "Afficher le fichier XML sous forme d'arborescence",
            "command": "Show-XmlTree -XmlPath '{0}'",
            "requiresOutput": false
        },
        {
            "name": "Vue formatÃ©e",
            "description": "Afficher le fichier XML formatÃ©",
            "command": "Show-XmlFormatted -XmlPath '{0}'",
            "requiresOutput": false
        }
    ]
}
"@

$xmlUiConfigPath = Join-Path -Path $xmlHtmlUiPath -ChildPath "xml-ui-config.json"
Set-Content -Path $xmlUiConfigPath -Value $xmlUiConfig -Encoding UTF8

# CrÃ©er le fichier de configuration UI pour HTML
$htmlUiConfig = @"
{
    "formatName": "HTML",
    "formatDescription": "Format HTML pour pages web",
    "fileExtensions": [".html", ".htm"],
    "icon": "html-icon.png",
    "actions": [
        {
            "name": "Convertir en XML",
            "description": "Convertir le fichier HTML en format XML",
            "command": "Convert-FormatFile -InputPath '{0}' -OutputPath '{1}' -InputFormat 'html' -OutputFormat 'xml'",
            "outputExtension": ".xml",
            "requiresOutput": true
        },
        {
            "name": "Extraire le texte",
            "description": "Extraire le texte du fichier HTML",
            "command": "ConvertTo-PlainText -HtmlDocument (Import-HtmlFile -FilePath '{0}') | Out-File -FilePath '{1}' -Encoding UTF8",
            "outputExtension": ".txt",
            "requiresOutput": true
        },
        {
            "name": "Sanitiser",
            "description": "Sanitiser le fichier HTML pour supprimer les Ã©lÃ©ments dangereux",
            "command": "Import-HtmlFile -FilePath '{0}' -Sanitize | Export-HtmlFile -FilePath '{1}'",
            "outputExtension": ".html",
            "requiresOutput": true
        }
    ],
    "viewOptions": [
        {
            "name": "Vue navigateur",
            "description": "Afficher le fichier HTML dans le navigateur",
            "command": "Start-Process '{0}'",
            "requiresOutput": false
        },
        {
            "name": "Vue structure",
            "description": "Afficher la structure du fichier HTML",
            "command": "Show-HtmlStructure -HtmlPath '{0}'",
            "requiresOutput": false
        }
    ]
}
"@

$htmlUiConfigPath = Join-Path -Path $xmlHtmlUiPath -ChildPath "html-ui-config.json"
Set-Content -Path $htmlUiConfigPath -Value $htmlUiConfig -Encoding UTF8

# CrÃ©er les icÃ´nes pour XML et HTML
$xmlIconPath = Join-Path -Path $xmlHtmlUiPath -ChildPath "xml-icon.png"
$htmlIconPath = Join-Path -Path $xmlHtmlUiPath -ChildPath "html-icon.png"

# Fonction pour crÃ©er une icÃ´ne simple (en base64)
function Create-SimpleIcon {
    param (
        [string]$IconPath,
        [string]$Base64Icon
    )
    
    $bytes = [Convert]::FromBase64String($Base64Icon)
    [System.IO.File]::WriteAllBytes($IconPath, $bytes)
}

# IcÃ´ne XML en base64 (exemple simple)
$xmlIconBase64 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAHtSURBVDjLjZM9T9tQFIYpQ5eOMBKlW6eWIQPK0q1bF0bQqSNDSnFiR+7H5kNeCNFYcvwRKdRbUxMJhaQkJHaIQ8wSipqyZMnSXzB2iENs6P3AUZQQpJ7p6viec85z3/fqaAAc/OPzUKfT8TQaDQfRtFqtMx5rGo2GXa/XC7Vara/X6z/8fn/M6/W+Fwofu8jRaDSSyKFQKCuqVCpwOp0oFossEAi8yGQyH0Qwjxg0JxIJ9Pt9OBwOVKtVFolEEA6H4fP5Uq+9BmeSyaQNiEQi1xqNBqxWK0qlEgvZbDasVqtgAGbXwYkktVwuY7lcIhaLwWw2o1gsMgYUCgUGYDwZKJfLByqVCgxpauVyGQxZLBbVAMwmjQBKpRJLJ5NJZDIZdeK9zzxAPp9nAIlEQh3A/JwB2WyWpSeTCdbrdZjNZtUAzCaNAFgqnU6zQCAAm82GbrfLAJiDDWA+aVzTND2bzTIAZrfbVQPMJ40A6IY5T8vl8oNqtQoGwODxZKAerDvRtNvtL7VajTVbr9dhtVrZ/csAjB535pMmAXSrXq+/y+VySOg0m80MgMGZ3y+Ax5PBEc9NJtM7l8uFTCbDGGCz2dhd5TUweeZMJpNZwWP8/9PpAMZH7+8+6V8E14/EXzq5dAAAAABJRU5ErkJggg=="
Create-SimpleIcon -IconPath $xmlIconPath -Base64Icon $xmlIconBase64

# IcÃ´ne HTML en base64 (exemple simple)
$htmlIconBase64 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAHtSURBVDjLjZM9T9tQFIYpQ5eOMBKlW6eWIQPK0q1bF0bQqSNDSnFiR+7H5kNeCNFYcvwRKdRbUxMJhaQkJHaIQ8wSipqyZMnSXzB2iENs6P3AUZQQpJ7p6viec85z3/fqaAAc/OPzUKfT8TQaDQfRtFqtMx5rGo2GXa/XC7Vara/X6z/8fn/M6/W+Fwofu8jRaDSSyKFQKCuqVCpwOp0oFossEAi8yGQyH0Qwjxg0JxIJ9Pt9OBwOVKtVFolEEA6H4fP5Uq+9BmeSyaQNiEQi1xqNBqxWK0qlEgvZbDasVqtgAGbXwYkktVwuY7lcIhaLwWw2o1gsMgYUCgUGYDwZKJfLByqVCgxpauVyGQxZLBbVAMwmjQBKpRJLJ5NJZDIZdeK9zzxAPp9nAIlEQh3A/JwB2WyWpSeTCdbrdZjNZtUAzCaNAFgqnU6zQCAAm82GbrfLAJiDDWA+aVzTND2bzTIAZrfbVQPMJ40A6IY5T8vl8oNqtQoGwODxZKAerDvRtNvtL7VajTVbr9dhtVrZ/csAjB535pMmAXSrXq+/y+VySOg0m80MgMGZ3y+Ax5PBEc9NJtM7l8uFTCbDGGCz2dhd5TUweeZMJpNZwWP8/9PpAMZH7+8+6V8E14/EXzq5dAAAAABJRU5ErkJggg=="
Create-SimpleIcon -IconPath $htmlIconPath -Base64Icon $htmlIconBase64

# CrÃ©er le script d'intÃ©gration UI
$uiIntegrationScript = @"
# Script d'intÃ©gration UI pour les formats XML et HTML
# Ce script est exÃ©cutÃ© au dÃ©marrage de l'interface utilisateur

# Importer les configurations UI
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$xmlUiConfigPath = Join-Path -Path `$scriptPath -ChildPath "xml-ui-config.json"
`$htmlUiConfigPath = Join-Path -Path `$scriptPath -ChildPath "html-ui-config.json"

# Fonction pour enregistrer les formats dans l'interface utilisateur
function Register-XmlHtmlFormatsInUI {
    param (
        [Parameter(Mandatory = `$true)]
        [hashtable]`$UiRegistry
    )
    
    # Charger les configurations
    `$xmlUiConfig = Get-Content -Path `$xmlUiConfigPath -Raw | ConvertFrom-Json
    `$htmlUiConfig = Get-Content -Path `$htmlUiConfigPath -Raw | ConvertFrom-Json
    
    # Enregistrer le format XML
    `$UiRegistry["xml"] = @{
        Name = `$xmlUiConfig.formatName
        Description = `$xmlUiConfig.formatDescription
        FileExtensions = `$xmlUiConfig.fileExtensions
        Icon = Join-Path -Path `$scriptPath -ChildPath `$xmlUiConfig.icon
        Actions = `$xmlUiConfig.actions
        ViewOptions = `$xmlUiConfig.viewOptions
    }
    
    # Enregistrer le format HTML
    `$UiRegistry["html"] = @{
        Name = `$htmlUiConfig.formatName
        Description = `$htmlUiConfig.formatDescription
        FileExtensions = `$htmlUiConfig.fileExtensions
        Icon = Join-Path -Path `$scriptPath -ChildPath `$htmlUiConfig.icon
        Actions = `$htmlUiConfig.actions
        ViewOptions = `$htmlUiConfig.viewOptions
    }
    
    return `$UiRegistry
}

# Exporter les fonctions
Export-ModuleMember -Function Register-XmlHtmlFormatsInUI
"@

$uiIntegrationScriptPath = Join-Path -Path $xmlHtmlUiPath -ChildPath "XML_HTML_UI_Integration.ps1"
Set-Content -Path $uiIntegrationScriptPath -Value $uiIntegrationScript -Encoding UTF8

# CrÃ©er les fonctions d'affichage pour XML et HTML
$viewFunctionsScript = @"
# Fonctions d'affichage pour XML et HTML
# Ce script fournit des fonctions pour afficher les fichiers XML et HTML

# Fonction pour afficher un fichier XML sous forme d'arborescence
function Show-XmlTree {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$XmlPath
    )
    
    if (-not (Test-Path -Path `$XmlPath)) {
        Write-Error "Le fichier XML n'existe pas: `$XmlPath"
        return
    }
    
    try {
        # Charger le fichier XML
        `$xmlDoc = New-Object System.Xml.XmlDocument
        `$xmlDoc.Load(`$XmlPath)
        
        # CrÃ©er une fenÃªtre pour afficher l'arborescence
        Add-Type -AssemblyName System.Windows.Forms
        
        `$form = New-Object System.Windows.Forms.Form
        `$form.Text = "Vue arborescente XML - `$XmlPath"
        `$form.Size = New-Object System.Drawing.Size(800, 600)
        `$form.StartPosition = "CenterScreen"
        
        `$treeView = New-Object System.Windows.Forms.TreeView
        `$treeView.Dock = "Fill"
        `$treeView.PathSeparator = "/"
        
        # Fonction rÃ©cursive pour ajouter des nÅ“uds Ã  l'arborescence
        function Add-XmlNodeToTree {
            param (
                [System.Xml.XmlNode]`$XmlNode,
                [System.Windows.Forms.TreeNode]`$TreeNode
            )
            
            foreach (`$childNode in `$XmlNode.ChildNodes) {
                `$nodeName = `$childNode.Name
                
                if (`$childNode.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                    if (`$childNode.HasAttributes) {
                        `$attributes = @()
                        foreach (`$attr in `$childNode.Attributes) {
                            `$attributes += "`$(`$attr.Name)=`$(`$attr.Value)"
                        }
                        `$nodeName += " [" + (`$attributes -join ", ") + "]"
                    }
                    
                    `$newNode = New-Object System.Windows.Forms.TreeNode(`$nodeName)
                    [void]`$TreeNode.Nodes.Add(`$newNode)
                    
                    if (`$childNode.HasChildNodes) {
                        Add-XmlNodeToTree -XmlNode `$childNode -TreeNode `$newNode
                    }
                }
                elseif (`$childNode.NodeType -eq [System.Xml.XmlNodeType]::Text) {
                    `$textValue = `$childNode.Value.Trim()
                    if (`$textValue) {
                        `$newNode = New-Object System.Windows.Forms.TreeNode("Text: `$textValue")
                        [void]`$TreeNode.Nodes.Add(`$newNode)
                    }
                }
            }
        }
        
        # Ajouter le nÅ“ud racine
        `$rootNode = New-Object System.Windows.Forms.TreeNode(`$xmlDoc.DocumentElement.Name)
        [void]`$treeView.Nodes.Add(`$rootNode)
        
        # Ajouter les nÅ“uds enfants
        Add-XmlNodeToTree -XmlNode `$xmlDoc.DocumentElement -TreeNode `$rootNode
        
        # DÃ©velopper le nÅ“ud racine
        `$rootNode.Expand()
        
        # Ajouter l'arborescence Ã  la fenÃªtre
        `$form.Controls.Add(`$treeView)
        
        # Afficher la fenÃªtre
        [void]`$form.ShowDialog()
    }
    catch {
        Write-Error "Erreur lors de l'affichage du fichier XML: `$_"
    }
}

# Fonction pour afficher un fichier XML formatÃ©
function Show-XmlFormatted {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$XmlPath
    )
    
    if (-not (Test-Path -Path `$XmlPath)) {
        Write-Error "Le fichier XML n'existe pas: `$XmlPath"
        return
    }
    
    try {
        # Charger le fichier XML
        `$xmlDoc = New-Object System.Xml.XmlDocument
        `$xmlDoc.Load(`$XmlPath)
        
        # Formater le XML
        `$stringWriter = New-Object System.IO.StringWriter
        `$xmlSettings = New-Object System.Xml.XmlWriterSettings
        `$xmlSettings.Indent = `$true
        `$xmlSettings.IndentChars = "  "
        
        `$xmlWriter = [System.Xml.XmlWriter]::Create(`$stringWriter, `$xmlSettings)
        `$xmlDoc.WriteTo(`$xmlWriter)
        `$xmlWriter.Flush()
        `$stringWriter.Flush()
        
        `$formattedXml = `$stringWriter.ToString()
        
        # CrÃ©er une fenÃªtre pour afficher le XML formatÃ©
        Add-Type -AssemblyName System.Windows.Forms
        
        `$form = New-Object System.Windows.Forms.Form
        `$form.Text = "Vue formatÃ©e XML - `$XmlPath"
        `$form.Size = New-Object System.Drawing.Size(800, 600)
        `$form.StartPosition = "CenterScreen"
        
        `$textBox = New-Object System.Windows.Forms.TextBox
        `$textBox.Multiline = `$true
        `$textBox.ScrollBars = "Both"
        `$textBox.WordWrap = `$false
        `$textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        `$textBox.Text = `$formattedXml
        `$textBox.Dock = "Fill"
        
        # Ajouter la zone de texte Ã  la fenÃªtre
        `$form.Controls.Add(`$textBox)
        
        # Afficher la fenÃªtre
        [void]`$form.ShowDialog()
    }
    catch {
        Write-Error "Erreur lors de l'affichage du fichier XML: `$_"
    }
}

# Fonction pour afficher la structure d'un fichier HTML
function Show-HtmlStructure {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$HtmlPath
    )
    
    if (-not (Test-Path -Path `$HtmlPath)) {
        Write-Error "Le fichier HTML n'existe pas: `$HtmlPath"
        return
    }
    
    try {
        # Importer le fichier HTML
        `$htmlDoc = Import-HtmlFile -FilePath `$HtmlPath
        
        # CrÃ©er une fenÃªtre pour afficher la structure
        Add-Type -AssemblyName System.Windows.Forms
        
        `$form = New-Object System.Windows.Forms.Form
        `$form.Text = "Structure HTML - `$HtmlPath"
        `$form.Size = New-Object System.Drawing.Size(800, 600)
        `$form.StartPosition = "CenterScreen"
        
        `$treeView = New-Object System.Windows.Forms.TreeView
        `$treeView.Dock = "Fill"
        `$treeView.PathSeparator = "/"
        
        # Fonction rÃ©cursive pour ajouter des nÅ“uds Ã  l'arborescence
        function Add-HtmlNodeToTree {
            param (
                [HtmlAgilityPack.HtmlNode]`$HtmlNode,
                [System.Windows.Forms.TreeNode]`$TreeNode
            )
            
            foreach (`$childNode in `$HtmlNode.ChildNodes) {
                if (`$childNode.NodeType -eq [HtmlAgilityPack.HtmlNodeType]::Element) {
                    `$nodeName = `$childNode.Name
                    
                    if (`$childNode.HasAttributes) {
                        `$attributes = @()
                        foreach (`$attr in `$childNode.Attributes) {
                            `$attributes += "`$(`$attr.Name)=`$(`$attr.Value)"
                        }
                        `$nodeName += " [" + (`$attributes -join ", ") + "]"
                    }
                    
                    `$newNode = New-Object System.Windows.Forms.TreeNode(`$nodeName)
                    [void]`$TreeNode.Nodes.Add(`$newNode)
                    
                    if (`$childNode.HasChildNodes) {
                        Add-HtmlNodeToTree -HtmlNode `$childNode -TreeNode `$newNode
                    }
                }
                elseif (`$childNode.NodeType -eq [HtmlAgilityPack.HtmlNodeType]::Text) {
                    `$textValue = `$childNode.InnerText.Trim()
                    if (`$textValue) {
                        `$newNode = New-Object System.Windows.Forms.TreeNode("Text: `$textValue")
                        [void]`$TreeNode.Nodes.Add(`$newNode)
                    }
                }
            }
        }
        
        # Ajouter le nÅ“ud racine
        `$rootNode = New-Object System.Windows.Forms.TreeNode("html")
        [void]`$treeView.Nodes.Add(`$rootNode)
        
        # Ajouter les nÅ“uds enfants
        Add-HtmlNodeToTree -HtmlNode `$htmlDoc.DocumentNode -TreeNode `$rootNode
        
        # DÃ©velopper le nÅ“ud racine
        `$rootNode.Expand()
        
        # Ajouter l'arborescence Ã  la fenÃªtre
        `$form.Controls.Add(`$treeView)
        
        # Afficher la fenÃªtre
        [void]`$form.ShowDialog()
    }
    catch {
        Write-Error "Erreur lors de l'affichage de la structure HTML: `$_"
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Show-XmlTree, Show-XmlFormatted, Show-HtmlStructure
"@

$viewFunctionsScriptPath = Join-Path -Path $xmlHtmlUiPath -ChildPath "XML_HTML_ViewFunctions.ps1"
Set-Content -Path $viewFunctionsScriptPath -Value $viewFunctionsScript -Encoding UTF8

Write-Host "Mise Ã  jour de l'interface utilisateur terminÃ©e avec succÃ¨s!" -ForegroundColor Green
Write-Host "Les formats XML et HTML sont maintenant disponibles dans l'interface utilisateur." -ForegroundColor Green
Write-Host "Chemin d'intÃ©gration UI: $xmlHtmlUiPath" -ForegroundColor Cyan
