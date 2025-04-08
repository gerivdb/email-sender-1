# Script pour la conception de l'architecture du système

# Configuration
$ArchitectureConfig = @{
    # Dossier de stockage des documents d'architecture
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ProjectArchitecture"
    
    # Fichier des composants du système
    ComponentsFile = Join-Path -Path $env:TEMP -ChildPath "ProjectArchitecture\components.json"
    
    # Fichier des interfaces entre composants
    InterfacesFile = Join-Path -Path $env:TEMP -ChildPath "ProjectArchitecture\interfaces.json"
    
    # Fichier des standards de code
    StandardsFile = Join-Path -Path $env:TEMP -ChildPath "ProjectArchitecture\standards.json"
}

# Fonction pour initialiser la conception d'architecture
function Initialize-ArchitectureDesign {
    param (
        [string]$OutputFolder = "",
        [string]$ComponentsFile = "",
        [string]$InterfacesFile = "",
        [string]$StandardsFile = ""
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $ArchitectureConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($ComponentsFile)) {
        $ArchitectureConfig.ComponentsFile = $ComponentsFile
    }
    
    if (-not [string]::IsNullOrEmpty($InterfacesFile)) {
        $ArchitectureConfig.InterfacesFile = $InterfacesFile
    }
    
    if (-not [string]::IsNullOrEmpty($StandardsFile)) {
        $ArchitectureConfig.StandardsFile = $StandardsFile
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $ArchitectureConfig.OutputFolder)) {
        New-Item -Path $ArchitectureConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer les fichiers s'ils n'existent pas
    $files = @{
        $ArchitectureConfig.ComponentsFile = @{
            Components = @()
            LastUpdate = Get-Date -Format "o"
        }
        $ArchitectureConfig.InterfacesFile = @{
            Interfaces = @()
            LastUpdate = Get-Date -Format "o"
        }
        $ArchitectureConfig.StandardsFile = @{
            Standards = @()
            LastUpdate = Get-Date -Format "o"
        }
    }
    
    foreach ($file in $files.Keys) {
        if (-not (Test-Path -Path $file)) {
            $files[$file] | ConvertTo-Json -Depth 5 | Set-Content -Path $file
        }
    }
    
    return $ArchitectureConfig
}

# Fonction pour ajouter un composant
function Add-Component {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Module", "Service", "Library", "Database", "UI", "API", "Utility")]
        [string]$Type = "Module",
        
        [Parameter(Mandatory = $false)]
        [string]$Responsibility = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ArchitectureConfig.ComponentsFile)) {
        Initialize-ArchitectureDesign
    }
    
    # Charger les composants existants
    $componentsData = Get-Content -Path $ArchitectureConfig.ComponentsFile -Raw | ConvertFrom-Json
    
    # Vérifier si le composant existe déjà
    $existingComponent = $componentsData.Components | Where-Object { $_.Name -eq $Name }
    
    if ($existingComponent) {
        Write-Warning "Un composant avec ce nom existe déjà."
        return $null
    }
    
    # Créer le composant
    $component = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Description = $Description
        Type = $Type
        Responsibility = $Responsibility
        Dependencies = $Dependencies
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
    }
    
    # Ajouter le composant
    $componentsData.Components += $component
    $componentsData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les composants
    $componentsData | ConvertTo-Json -Depth 5 | Set-Content -Path $ArchitectureConfig.ComponentsFile
    
    return $component
}

# Fonction pour ajouter une interface
function Add-Interface {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceComponent,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetComponent,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Synchronous", "Asynchronous", "Event-Based", "File-Based", "Database")]
        [string]$Type = "Synchronous",
        
        [Parameter(Mandatory = $false)]
        [string]$Protocol = "",
        
        [Parameter(Mandatory = $false)]
        [string]$DataFormat = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ArchitectureConfig.InterfacesFile)) {
        Initialize-ArchitectureDesign
    }
    
    # Charger les interfaces existantes
    $interfacesData = Get-Content -Path $ArchitectureConfig.InterfacesFile -Raw | ConvertFrom-Json
    
    # Vérifier si l'interface existe déjà
    $existingInterface = $interfacesData.Interfaces | Where-Object { 
        $_.Name -eq $Name -or 
        ($_.SourceComponent -eq $SourceComponent -and $_.TargetComponent -eq $TargetComponent)
    }
    
    if ($existingInterface) {
        Write-Warning "Une interface avec ce nom ou entre ces composants existe déjà."
        return $null
    }
    
    # Vérifier si les composants existent
    $componentsData = Get-Content -Path $ArchitectureConfig.ComponentsFile -Raw | ConvertFrom-Json
    $sourceExists = $componentsData.Components | Where-Object { $_.Name -eq $SourceComponent }
    $targetExists = $componentsData.Components | Where-Object { $_.Name -eq $TargetComponent }
    
    if (-not $sourceExists) {
        Write-Warning "Le composant source '$SourceComponent' n'existe pas."
        return $null
    }
    
    if (-not $targetExists) {
        Write-Warning "Le composant cible '$TargetComponent' n'existe pas."
        return $null
    }
    
    # Créer l'interface
    $interface = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        SourceComponent = $SourceComponent
        TargetComponent = $TargetComponent
        Description = $Description
        Type = $Type
        Protocol = $Protocol
        DataFormat = $DataFormat
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
    }
    
    # Ajouter l'interface
    $interfacesData.Interfaces += $interface
    $interfacesData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les interfaces
    $interfacesData | ConvertTo-Json -Depth 5 | Set-Content -Path $ArchitectureConfig.InterfacesFile
    
    return $interface
}

# Fonction pour ajouter un standard de code
function Add-CodeStandard {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Naming", "Formatting", "Documentation", "Testing", "Security", "Performance", "General")]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Examples = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicableLanguages = @("All"),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ArchitectureConfig.StandardsFile)) {
        Initialize-ArchitectureDesign
    }
    
    # Charger les standards existants
    $standardsData = Get-Content -Path $ArchitectureConfig.StandardsFile -Raw | ConvertFrom-Json
    
    # Vérifier si le standard existe déjà
    $existingStandard = $standardsData.Standards | Where-Object { $_.Name -eq $Name }
    
    if ($existingStandard) {
        Write-Warning "Un standard avec ce nom existe déjà."
        return $null
    }
    
    # Créer le standard
    $standard = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Description = $Description
        Category = $Category
        Examples = $Examples
        ApplicableLanguages = $ApplicableLanguages
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
    }
    
    # Ajouter le standard
    $standardsData.Standards += $standard
    $standardsData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les standards
    $standardsData | ConvertTo-Json -Depth 5 | Set-Content -Path $ArchitectureConfig.StandardsFile
    
    return $standard
}

# Fonction pour générer un diagramme d'architecture
function New-ArchitectureDiagram {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Diagramme d'architecture",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Charger les données
    $componentsData = Get-Content -Path $ArchitectureConfig.ComponentsFile -Raw | ConvertFrom-Json
    $interfacesData = Get-Content -Path $ArchitectureConfig.InterfacesFile -Raw | ConvertFrom-Json
    
    $components = $componentsData.Components
    $interfaces = $interfacesData.Interfaces
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ArchitectureDiagram-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Préparer les données pour le diagramme
    $nodes = @()
    $edges = @()
    
    foreach ($component in $components) {
        $color = switch ($component.Type) {
            "Module" { "#4caf50" }
            "Service" { "#2196f3" }
            "Library" { "#9c27b0" }
            "Database" { "#ff9800" }
            "UI" { "#e91e63" }
            "API" { "#00bcd4" }
            "Utility" { "#607d8b" }
            default { "#9e9e9e" }
        }
        
        $nodes += @{
            id = $component.Name
            label = $component.Name
            title = $component.Description
            color = @{
                background = $color
                border = "#333333"
                highlight = @{
                    background = $color
                    border = "#000000"
                }
            }
            font = @{
                color = "#ffffff"
            }
        }
    }
    
    foreach ($interface in $interfaces) {
        $style = switch ($interface.Type) {
            "Synchronous" { "arrow" }
            "Asynchronous" { "dash-line" }
            "Event-Based" { "dot-line" }
            "File-Based" { "dash-dot" }
            "Database" { "dash-dot-dot" }
            default { "arrow" }
        }
        
        $edges += @{
            from = $interface.SourceComponent
            to = $interface.TargetComponent
            label = $interface.Name
            title = $interface.Description
            arrows = "to"
            dashes = if ($style -ne "arrow") { $true } else { $false }
        }
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        .header {
            background-color: #f8f9fa;
            padding: 10px 20px;
            border-bottom: 1px solid #eee;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        #mynetwork {
            flex-grow: 1;
            width: 100%;
        }
        
        .legend {
            position: absolute;
            bottom: 20px;
            right: 20px;
            background-color: rgba(255, 255, 255, 0.8);
            padding: 10px;
            border-radius: 5px;
            border: 1px solid #ddd;
            z-index: 1000;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            margin-bottom: 5px;
        }
        
        .legend-color {
            width: 20px;
            height: 20px;
            margin-right: 10px;
            border-radius: 3px;
        }
        
        .footer {
            background-color: #f8f9fa;
            padding: 10px 20px;
            border-top: 1px solid #eee;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>$Title</h1>
        <div>
            <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
        </div>
    </div>
    
    <div id="mynetwork"></div>
    
    <div class="legend">
        <h3>Légende</h3>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #4caf50;"></div>
            <span>Module</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #2196f3;"></div>
            <span>Service</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #9c27b0;"></div>
            <span>Library</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #ff9800;"></div>
            <span>Database</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #e91e63;"></div>
            <span>UI</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #00bcd4;"></div>
            <span>API</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #607d8b;"></div>
            <span>Utility</span>
        </div>
    </div>
    
    <div class="footer">
        <p>Diagramme généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <script>
        // Données pour le diagramme
        const nodes = $(ConvertTo-Json -InputObject $nodes -Depth 5);
        const edges = $(ConvertTo-Json -InputObject $edges -Depth 5);
        
        // Créer le réseau
        const container = document.getElementById('mynetwork');
        const data = {
            nodes: new vis.DataSet(nodes),
            edges: new vis.DataSet(edges)
        };
        const options = {
            nodes: {
                shape: 'box',
                margin: 10,
                widthConstraint: {
                    minimum: 100,
                    maximum: 200
                },
                shadow: true
            },
            edges: {
                width: 2,
                shadow: true,
                smooth: {
                    type: 'continuous'
                }
            },
            physics: {
                enabled: true,
                hierarchicalRepulsion: {
                    centralGravity: 0.0,
                    springLength: 100,
                    springConstant: 0.01,
                    nodeDistance: 120,
                    damping: 0.09
                },
                solver: 'hierarchicalRepulsion'
            },
            layout: {
                improvedLayout: true
            }
        };
        const network = new vis.Network(container, data, options);
        
        // Ajuster la taille du réseau lors du redimensionnement de la fenêtre
        window.addEventListener('resize', function() {
            network.fit();
        });
    </script>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le diagramme si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour générer un rapport d'architecture
function New-ArchitectureReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport d'architecture",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeStandards,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Charger les données
    $componentsData = Get-Content -Path $ArchitectureConfig.ComponentsFile -Raw | ConvertFrom-Json
    $interfacesData = Get-Content -Path $ArchitectureConfig.InterfacesFile -Raw | ConvertFrom-Json
    
    $components = $componentsData.Components
    $interfaces = $interfacesData.Interfaces
    
    $standards = @()
    if ($IncludeStandards) {
        $standardsData = Get-Content -Path $ArchitectureConfig.StandardsFile -Raw | ConvertFrom-Json
        $standards = $standardsData.Standards
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ArchitectureReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .component-module {
            color: #4caf50;
            font-weight: bold;
        }
        
        .component-service {
            color: #2196f3;
            font-weight: bold;
        }
        
        .component-library {
            color: #9c27b0;
            font-weight: bold;
        }
        
        .component-database {
            color: #ff9800;
            font-weight: bold;
        }
        
        .component-ui {
            color: #e91e63;
            font-weight: bold;
        }
        
        .component-api {
            color: #00bcd4;
            font-weight: bold;
        }
        
        .component-utility {
            color: #607d8b;
            font-weight: bold;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="section">
            <h2>Composants du système</h2>
            <p>Nombre total de composants: $($components.Count)</p>
            
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Type</th>
                        <th>Description</th>
                        <th>Responsabilité</th>
                        <th>Dépendances</th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($component in ($components | Sort-Object -Property Type, Name)) {
                        $typeClass = "component-" + $component.Type.ToLower()
                        $dependencies = if ($component.Dependencies.Count -gt 0) { $component.Dependencies -join ", " } else { "Aucune" }
                        
                        "<tr>
                            <td>$($component.Name)</td>
                            <td class='$typeClass'>$($component.Type)</td>
                            <td>$($component.Description)</td>
                            <td>$($component.Responsibility)</td>
                            <td>$dependencies</td>
                        </tr>"
                    })
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Interfaces entre composants</h2>
            <p>Nombre total d'interfaces: $($interfaces.Count)</p>
            
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Source</th>
                        <th>Cible</th>
                        <th>Type</th>
                        <th>Description</th>
                        <th>Protocole</th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($interface in ($interfaces | Sort-Object -Property SourceComponent, TargetComponent)) {
                        "<tr>
                            <td>$($interface.Name)</td>
                            <td>$($interface.SourceComponent)</td>
                            <td>$($interface.TargetComponent)</td>
                            <td>$($interface.Type)</td>
                            <td>$($interface.Description)</td>
                            <td>$($interface.Protocol)</td>
                        </tr>"
                    })
                </tbody>
            </table>
        </div>
        
        $(if ($IncludeStandards) {
            "<div class='section'>
                <h2>Standards de code</h2>
                <p>Nombre total de standards: $($standards.Count)</p>
                
                <table>
                    <thead>
                        <tr>
                            <th>Nom</th>
                            <th>Catégorie</th>
                            <th>Description</th>
                            <th>Langages applicables</th>
                        </tr>
                    </thead>
                    <tbody>
                        $(foreach ($standard in ($standards | Sort-Object -Property Category, Name)) {
                            $languages = if ($standard.ApplicableLanguages.Count -gt 0) { $standard.ApplicableLanguages -join ", " } else { "Tous" }
                            
                            "<tr>
                                <td>$($standard.Name)</td>
                                <td>$($standard.Category)</td>
                                <td>$($standard.Description)</td>
                                <td>$languages</td>
                            </tr>"
                        })
                    </tbody>
                </table>
            </div>"
        })
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ArchitectureDesign, Add-Component, Add-Interface, Add-CodeStandard
Export-ModuleMember -Function New-ArchitectureDiagram, New-ArchitectureReport
