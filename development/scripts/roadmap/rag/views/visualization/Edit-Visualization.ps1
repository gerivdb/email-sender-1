# Edit-Visualization.ps1
# Script pour l'éditeur de visualisations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigContent,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$DataPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("TreeMap", "Timeline", "Gantt", "Network", "Sunburst", "HeatMap")]
    [string]$VisualizationType = "TreeMap",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "GUI", "VSCode")]
    [string]$EditorMode = "GUI",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnablePreview,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent $rootPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour charger une configuration
function Get-VisualizationConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigContent,
        
        [Parameter(Mandatory = $false)]
        [string]$VisualizationType
    )
    
    if (-not [string]::IsNullOrEmpty($ConfigContent)) {
        try {
            $config = $ConfigContent | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error parsing config content: $_" -Level "Error"
        }
    }
    
    if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading config from file: $_" -Level "Error"
        }
    }
    
    # Configuration par défaut selon le type de visualisation
    $defaultConfig = switch ($VisualizationType) {
        "TreeMap" {
            @{
                type = "TreeMap"
                title = "Roadmap TreeMap"
                description = "Visualisation hiérarchique des tâches de la roadmap"
                options = @{
                    width = 800
                    height = 600
                    colorBy = "status"
                    sizeBy = "complexity"
                    showLabels = $true
                    interactive = $true
                    maxDepth = 3
                }
                mapping = @{
                    id = "id"
                    parent = "parent_id"
                    label = "title"
                    value = "complexity"
                    color = "status"
                    tooltip = "description"
                }
                colorScheme = @{
                    todo = "#f39c12"
                    in_progress = "#3498db"
                    done = "#27ae60"
                    blocked = "#e74c3c"
                }
                libraries = @{
                    main = "d3.js"
                    version = "7.8.0"
                    dependencies = @("d3-hierarchy")
                }
            }
        }
        "Timeline" {
            @{
                type = "Timeline"
                title = "Roadmap Timeline"
                description = "Visualisation chronologique des tâches de la roadmap"
                options = @{
                    width = 1000
                    height = 500
                    showToday = $true
                    groupBy = "category"
                    showLabels = $true
                    interactive = $true
                    zoomable = $true
                }
                mapping = @{
                    id = "id"
                    content = "title"
                    start = "start_date"
                    end = "due_date"
                    group = "category"
                    className = "status"
                    tooltip = "description"
                }
                colorScheme = @{
                    todo = "#f39c12"
                    in_progress = "#3498db"
                    done = "#27ae60"
                    blocked = "#e74c3c"
                }
                libraries = @{
                    main = "vis-timeline"
                    version = "7.7.0"
                    dependencies = @()
                }
            }
        }
        "Gantt" {
            @{
                type = "Gantt"
                title = "Roadmap Gantt"
                description = "Diagramme de Gantt des tâches de la roadmap"
                options = @{
                    width = 1000
                    height = 600
                    showProgress = $true
                    showDependencies = $true
                    showCriticalPath = $true
                    interactive = $true
                    dateFormat = "YYYY-MM-DD"
                }
                mapping = @{
                    id = "id"
                    name = "title"
                    start = "start_date"
                    end = "due_date"
                    progress = "progress"
                    dependencies = "dependencies"
                    style = "status"
                    tooltip = "description"
                }
                colorScheme = @{
                    todo = "#f39c12"
                    in_progress = "#3498db"
                    done = "#27ae60"
                    blocked = "#e74c3c"
                }
                libraries = @{
                    main = "frappe-gantt"
                    version = "0.6.1"
                    dependencies = @("moment")
                }
            }
        }
        "Network" {
            @{
                type = "Network"
                title = "Roadmap Network"
                description = "Graphe de relations entre les tâches de la roadmap"
                options = @{
                    width = 800
                    height = 600
                    physics = $true
                    hierarchical = $false
                    showLabels = $true
                    interactive = $true
                    nodeSize = "complexity"
                }
                mapping = @{
                    id = "id"
                    label = "title"
                    group = "status"
                    value = "complexity"
                    title = "description"
                    edges = "dependencies"
                }
                colorScheme = @{
                    todo = "#f39c12"
                    in_progress = "#3498db"
                    done = "#27ae60"
                    blocked = "#e74c3c"
                }
                libraries = @{
                    main = "vis-network"
                    version = "9.1.2"
                    dependencies = @()
                }
            }
        }
        "Sunburst" {
            @{
                type = "Sunburst"
                title = "Roadmap Sunburst"
                description = "Visualisation hiérarchique circulaire des tâches de la roadmap"
                options = @{
                    width = 700
                    height = 700
                    colorBy = "status"
                    sizeBy = "complexity"
                    showLabels = $true
                    interactive = $true
                    maxDepth = 4
                }
                mapping = @{
                    id = "id"
                    parent = "parent_id"
                    label = "title"
                    value = "complexity"
                    color = "status"
                    tooltip = "description"
                }
                colorScheme = @{
                    todo = "#f39c12"
                    in_progress = "#3498db"
                    done = "#27ae60"
                    blocked = "#e74c3c"
                }
                libraries = @{
                    main = "d3.js"
                    version = "7.8.0"
                    dependencies = @("d3-hierarchy")
                }
            }
        }
        "HeatMap" {
            @{
                type = "HeatMap"
                title = "Roadmap Heat Map"
                description = "Carte de chaleur des tâches de la roadmap"
                options = @{
                    width = 900
                    height = 500
                    xAxis = "due_date"
                    yAxis = "category"
                    colorBy = "priority"
                    showLabels = $true
                    interactive = $true
                    aggregation = "count"
                }
                mapping = @{
                    x = "due_date"
                    y = "category"
                    value = "priority"
                    label = "title"
                    tooltip = "description"
                }
                colorScheme = @{
                    low = "#27ae60"
                    medium = "#f39c12"
                    high = "#e74c3c"
                }
                libraries = @{
                    main = "d3.js"
                    version = "7.8.0"
                    dependencies = @()
                }
            }
        }
        default {
            @{
                type = "TreeMap"
                title = "Roadmap TreeMap"
                description = "Visualisation hiérarchique des tâches de la roadmap"
                options = @{
                    width = 800
                    height = 600
                    colorBy = "status"
                    sizeBy = "complexity"
                    showLabels = $true
                    interactive = $true
                    maxDepth = 3
                }
                mapping = @{
                    id = "id"
                    parent = "parent_id"
                    label = "title"
                    value = "complexity"
                    color = "status"
                    tooltip = "description"
                }
                colorScheme = @{
                    todo = "#f39c12"
                    in_progress = "#3498db"
                    done = "#27ae60"
                    blocked = "#e74c3c"
                }
                libraries = @{
                    main = "d3.js"
                    version = "7.8.0"
                    dependencies = @("d3-hierarchy")
                }
            }
        }
    }
    
    return $defaultConfig
}

# Fonction pour charger les données de la roadmap
function Get-RoadmapData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DataPath
    )
    
    if (-not [string]::IsNullOrEmpty($DataPath) -and (Test-Path -Path $DataPath)) {
        try {
            $extension = [System.IO.Path]::GetExtension($DataPath).ToLower()
            
            switch ($extension) {
                ".json" {
                    $data = Get-Content -Path $DataPath -Raw | ConvertFrom-Json
                    return $data
                }
                ".md" {
                    Write-Log "Loading from Markdown is not yet implemented" -Level "Warning"
                    return $null
                }
                default {
                    Write-Log "Unsupported data file format: $extension" -Level "Error"
                    return $null
                }
            }
        } catch {
            Write-Log "Error loading data from file: $_" -Level "Error"
            return $null
        }
    }
    
    # Données d'exemple si aucun chemin n'est spécifié
    return @(
        [PSCustomObject]@{
            id = "1"
            title = "Développer le système RAG"
            status = "in_progress"
            priority = "high"
            category = "development"
            start_date = "2025-05-01"
            due_date = "2025-06-30"
            progress = 60
            complexity = 8
            parent_id = $null
            dependencies = @()
            description = "Développer le système de Retrieval Augmented Generation pour la roadmap"
        },
        [PSCustomObject]@{
            id = "1.1"
            title = "Concevoir l'architecture"
            status = "done"
            priority = "high"
            category = "design"
            start_date = "2025-05-01"
            due_date = "2025-05-15"
            progress = 100
            complexity = 5
            parent_id = "1"
            dependencies = @()
            description = "Concevoir l'architecture du système RAG"
        },
        [PSCustomObject]@{
            id = "1.2"
            title = "Implémenter l'indexation"
            status = "done"
            priority = "high"
            category = "development"
            start_date = "2025-05-16"
            due_date = "2025-05-31"
            progress = 100
            complexity = 7
            parent_id = "1"
            dependencies = @("1.1")
            description = "Implémenter le système d'indexation des documents"
        },
        [PSCustomObject]@{
            id = "1.3"
            title = "Développer les requêtes"
            status = "in_progress"
            priority = "medium"
            category = "development"
            start_date = "2025-06-01"
            due_date = "2025-06-15"
            progress = 70
            complexity = 6
            parent_id = "1"
            dependencies = @("1.2")
            description = "Développer le système de requêtes vectorielles"
        },
        [PSCustomObject]@{
            id = "1.4"
            title = "Intégrer avec l'interface"
            status = "todo"
            priority = "medium"
            category = "integration"
            start_date = "2025-06-16"
            due_date = "2025-06-30"
            progress = 0
            complexity = 4
            parent_id = "1"
            dependencies = @("1.3")
            description = "Intégrer le système RAG avec l'interface utilisateur"
        },
        [PSCustomObject]@{
            id = "2"
            title = "Développer les visualisations"
            status = "todo"
            priority = "high"
            category = "development"
            start_date = "2025-07-01"
            due_date = "2025-08-15"
            progress = 0
            complexity = 9
            parent_id = $null
            dependencies = @("1")
            description = "Développer les visualisations graphiques pour la roadmap"
        }
    )
}

# Fonction pour l'éditeur en mode GUI (Windows Forms)
function Start-GUIEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePreview
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Visualization Editor"
    $form.Size = New-Object System.Drawing.Size(1200, 800)
    $form.StartPosition = "CenterScreen"
    
    $splitContainer = New-Object System.Windows.Forms.SplitContainer
    $splitContainer.Dock = "Fill"
    $splitContainer.Orientation = "Vertical"
    $splitContainer.SplitterDistance = 500
    
    $configTextBox = New-Object System.Windows.Forms.TextBox
    $configTextBox.Multiline = $true
    $configTextBox.ScrollBars = "Both"
    $configTextBox.Dock = "Fill"
    $configTextBox.Font = New-Object System.Drawing.Font("Consolas", 12)
    $configTextBox.Text = ($Config | ConvertTo-Json -Depth 10)
    $configTextBox.AcceptsTab = $true
    $configTextBox.WordWrap = $false
    
    $browser = New-Object System.Windows.Forms.WebBrowser
    $browser.Dock = "Fill"
    
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Dock = "Bottom"
    $buttonPanel.Height = 40
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Save"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(1020, 10)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(1100, 10)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    
    $previewButton = New-Object System.Windows.Forms.Button
    $previewButton.Text = "Preview"
    $previewButton.Location = New-Object System.Drawing.Point(940, 10)
    $previewButton.Size = New-Object System.Drawing.Size(75, 23)
    $previewButton.Add_Click({
        try {
            $config = $configTextBox.Text | ConvertFrom-Json
            $previewHtml = Get-VisualizationPreview -Config $config -Data $Data
            $browser.DocumentText = $previewHtml
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error generating preview: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    
    $buttonPanel.Controls.Add($okButton)
    $buttonPanel.Controls.Add($cancelButton)
    $buttonPanel.Controls.Add($previewButton)
    
    $splitContainer.Panel1.Controls.Add($configTextBox)
    
    if ($EnablePreview) {
        $splitContainer.Panel2.Controls.Add($browser)
    } else {
        $splitContainer.Panel2Collapsed = $true
    }
    
    $form.Controls.Add($splitContainer)
    $form.Controls.Add($buttonPanel)
    
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $config = $configTextBox.Text | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error parsing JSON configuration: $_" -Level "Error"
            return $null
        }
    } else {
        return $null
    }
}

# Fonction pour l'éditeur en mode VSCode
function Start-VSCodeEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )
    
    # Créer un fichier temporaire si aucun chemin n'est spécifié
    $tempFile = $false
    $filePath = $ConfigPath
    
    if ([string]::IsNullOrEmpty($filePath)) {
        $filePath = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
        $tempFile = $true
    }
    
    # Écrire la configuration dans le fichier
    $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
    
    # Ouvrir le fichier dans VSCode
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    
    if (-not $vscodePath) {
        Write-Log "VSCode not found in PATH. Falling back to GUI editor." -Level "Warning"
        return Start-GUIEditor -Config $Config -Data (Get-RoadmapData) -EnablePreview:$EnablePreview
    }
    
    # Lancer VSCode et attendre que l'utilisateur ferme le fichier
    Start-Process -FilePath $vscodePath -ArgumentList "`"$filePath`" --wait" -Wait
    
    # Lire le contenu du fichier
    try {
        $content = Get-Content -Path $filePath -Raw | ConvertFrom-Json
    } catch {
        Write-Log "Error parsing JSON configuration: $_" -Level "Error"
        $content = $null
    }
    
    # Supprimer le fichier temporaire si nécessaire
    if ($tempFile) {
        Remove-Item -Path $filePath -Force
    }
    
    return $content
}

# Fonction principale
function Edit-Visualization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigContent,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$DataPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("TreeMap", "Timeline", "Gantt", "Network", "Sunburst", "HeatMap")]
        [string]$VisualizationType = "TreeMap",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "GUI", "VSCode")]
        [string]$EditorMode = "GUI",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePreview
    )
    
    # Charger la configuration
    $config = Get-VisualizationConfig -ConfigPath $ConfigPath -ConfigContent $ConfigContent -VisualizationType $VisualizationType
    
    if ($null -eq $config) {
        Write-Log "Failed to load configuration" -Level "Error"
        return $null
    }
    
    # Charger les données
    $data = Get-RoadmapData -DataPath $DataPath
    
    if ($null -eq $data) {
        Write-Log "Failed to load data" -Level "Warning"
    }
    
    # Ouvrir l'éditeur approprié
    $editedConfig = $null
    
    switch ($EditorMode) {
        "GUI" {
            $editedConfig = Start-GUIEditor -Config $config -Data $data -EnablePreview:$EnablePreview
        }
        "VSCode" {
            $editedConfig = Start-VSCodeEditor -Config $config -ConfigPath $ConfigPath
        }
        "Console" {
            Write-Log "Console mode not supported for visualization editing. Falling back to GUI mode." -Level "Warning"
            $editedConfig = Start-GUIEditor -Config $config -Data $data -EnablePreview:$EnablePreview
        }
    }
    
    # Si l'utilisateur a annulé, sortir
    if ($null -eq $editedConfig) {
        Write-Log "Visualization editing cancelled by user" -Level "Info"
        return $null
    }
    
    # Sauvegarder la configuration si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $editedConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Configuration saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving configuration: $_" -Level "Error"
        }
    }
    
    return $editedConfig
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Edit-Visualization -ConfigPath $ConfigPath -ConfigContent $ConfigContent -OutputPath $OutputPath -DataPath $DataPath -VisualizationType $VisualizationType -EditorMode $EditorMode -EnablePreview:$EnablePreview
}
