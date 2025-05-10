# Export-InteractiveHtml.ps1
# Script pour exporter les visualisations en HTML interactif
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VisualizationPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Standalone", "Embedded", "Interactive")]
    [string]$ExportType = "Standalone",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeData,
    
    [Parameter(Mandatory = $false)]
    [switch]$MinifyOutput,
    
    [Parameter(Mandatory = $false)]
    [switch]$AddDownloadButton,
    
    [Parameter(Mandatory = $false)]
    [switch]$AddPrintButton,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
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

# Importer le script de visualisation
$visualizationPath = Join-Path -Path $parentPath -ChildPath "Edit-Visualization.ps1"
if (-not (Test-Path -Path $visualizationPath)) {
    Write-Log "Visualization script not found: $visualizationPath" -Level "Error"
    exit 1
}

. $visualizationPath

# Fonction pour charger une visualisation
function Get-VisualizationFromFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VisualizationPath
    )
    
    if (-not (Test-Path -Path $VisualizationPath)) {
        Write-Log "Visualization file not found: $VisualizationPath" -Level "Error"
        return $null
    }
    
    try {
        $visualization = Get-Content -Path $VisualizationPath -Raw | ConvertFrom-Json
        return $visualization
    } catch {
        Write-Log "Error loading visualization: $_" -Level "Error"
        return $null
    }
}

# Fonction pour générer le HTML interactif
function Get-InteractiveHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Visualization,
        
        [Parameter(Mandatory = $true)]
        [string]$ExportType,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeData,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddDownloadButton,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddPrintButton
    )
    
    # Générer le HTML de base de la visualisation
    $html = Get-VisualizationHtml -Visualization $Visualization
    
    # Ajouter les fonctionnalités interactives selon le type d'export
    switch ($ExportType) {
        "Standalone" {
            # Aucune modification supplémentaire nécessaire
        }
        "Embedded" {
            # Supprimer les balises DOCTYPE, html, head et body pour faciliter l'intégration
            $html = $html -replace "<!DOCTYPE html>", ""
            $html = $html -replace "<html[^>]*>", ""
            $html = $html -replace "</html>", ""
            $html = $html -replace "<head>.*?</head>", ""
            $html = $html -replace "<body>", ""
            $html = $html -replace "</body>", ""
            
            # Ajouter les styles et scripts nécessaires
            $html = @"
<div class="roadmap-visualization-embedded">
    <style>
        .roadmap-visualization-embedded {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            padding: 20px;
            box-sizing: border-box;
        }
        .roadmap-visualization-embedded h1, 
        .roadmap-visualization-embedded h2, 
        .roadmap-visualization-embedded h3 {
            color: #2c3e50;
        }
        .roadmap-visualization-embedded .chart-container {
            position: relative;
            height: 400px;
            margin-bottom: 30px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    $html
</div>
"@
        }
        "Interactive" {
            # Ajouter des contrôles interactifs pour filtrer et manipuler les graphiques
            $interactiveControls = @"
<div class="interactive-controls">
    <style>
        .interactive-controls {
            margin-bottom: 20px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
            border: 1px solid #e9ecef;
        }
        .control-group {
            margin-bottom: 10px;
        }
        .control-group label {
            display: inline-block;
            width: 120px;
            font-weight: bold;
        }
        .control-group select, .control-group input {
            padding: 5px;
            border-radius: 3px;
            border: 1px solid #ced4da;
        }
        .control-buttons {
            margin-top: 15px;
            text-align: right;
        }
        .control-buttons button {
            padding: 5px 10px;
            margin-left: 10px;
            border-radius: 3px;
            border: 1px solid #ced4da;
            background-color: #f8f9fa;
            cursor: pointer;
        }
        .control-buttons button:hover {
            background-color: #e9ecef;
        }
    </style>
    
    <h3>Contrôles interactifs</h3>
    
    <div class="control-group">
        <label for="chart-type">Type de graphique:</label>
        <select id="chart-type">
            <option value="pie">Camembert</option>
            <option value="bar">Barres</option>
            <option value="line">Lignes</option>
            <option value="radar">Radar</option>
            <option value="doughnut">Anneau</option>
            <option value="polarArea">Aire polaire</option>
        </select>
    </div>
    
    <div class="control-group">
        <label for="data-group">Regrouper par:</label>
        <select id="data-group">
            <option value="status">Statut</option>
            <option value="priority">Priorité</option>
            <option value="assignee">Assigné</option>
            <option value="due_date">Échéance</option>
        </select>
    </div>
    
    <div class="control-group">
        <label for="color-scheme">Schéma de couleurs:</label>
        <select id="color-scheme">
            <option value="default">Par défaut</option>
            <option value="pastel">Pastel</option>
            <option value="bright">Vif</option>
            <option value="monochrome">Monochrome</option>
        </select>
    </div>
    
    <div class="control-buttons">
        <button id="reset-controls">Réinitialiser</button>
        <button id="apply-controls">Appliquer</button>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // Référence aux contrôles
    const chartTypeSelect = document.getElementById('chart-type');
    const dataGroupSelect = document.getElementById('data-group');
    const colorSchemeSelect = document.getElementById('color-scheme');
    const resetButton = document.getElementById('reset-controls');
    const applyButton = document.getElementById('apply-controls');
    
    // Schémas de couleurs
    const colorSchemes = {
        default: ['#3498db', '#2ecc71', '#e74c3c', '#f39c12', '#9b59b6', '#1abc9c', '#34495e', '#e67e22'],
        pastel: ['#a8d8ea', '#aa96da', '#fcbad3', '#ffffd2', '#a6e4d0', '#e8c1a0', '#f1e3cb', '#cdf1af'],
        bright: ['#ff3838', '#ffb8b8', '#c56cf0', '#ff9f1a', '#fff200', '#32ff7e', '#7efff5', '#18dcff'],
        monochrome: ['#000000', '#333333', '#666666', '#999999', '#cccccc', '#eeeeee', '#f5f5f5', '#ffffff']
    };
    
    // Fonction pour mettre à jour les graphiques
    function updateCharts() {
        const chartType = chartTypeSelect.value;
        const dataGroup = dataGroupSelect.value;
        const colorScheme = colorSchemeSelect.value;
        
        // Récupérer tous les graphiques
        const charts = document.querySelectorAll('canvas');
        
        charts.forEach(function(canvas) {
            const chart = Chart.getChart(canvas);
            
            if (chart) {
                // Sauvegarder les données actuelles
                const data = chart.data.datasets[0].data;
                const labels = chart.data.labels;
                
                // Mettre à jour le type de graphique
                chart.config.type = chartType;
                
                // Mettre à jour les couleurs
                chart.data.datasets[0].backgroundColor = colorSchemes[colorScheme].slice(0, data.length);
                
                // Mettre à jour les options selon le type de graphique
                if (chartType === 'line' || chartType === 'bar') {
                    chart.options.scales = {
                        y: {
                            beginAtZero: true
                        }
                    };
                } else {
                    chart.options.scales = {};
                }
                
                // Appliquer les changements
                chart.update();
            }
        });
    }
    
    // Événements
    applyButton.addEventListener('click', updateCharts);
    
    resetButton.addEventListener('click', function() {
        chartTypeSelect.value = 'pie';
        dataGroupSelect.value = 'status';
        colorSchemeSelect.value = 'default';
        updateCharts();
    });
});
</script>
"@
            
            # Insérer les contrôles interactifs après la balise <body>
            $html = $html -replace "<body>", "<body>$interactiveControls"
        }
    }
    
    # Ajouter les boutons de téléchargement et d'impression si demandé
    if ($AddDownloadButton -or $AddPrintButton) {
        $buttons = @"
<div class="export-buttons">
    <style>
        .export-buttons {
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 1000;
        }
        .export-button {
            display: inline-block;
            padding: 10px 15px;
            margin-left: 10px;
            background-color: #3498db;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        .export-button:hover {
            background-color: #2980b9;
        }
    </style>
"@
        
        if ($AddDownloadButton) {
            $buttons += @"
    <button class="export-button" id="download-button">Télécharger</button>
    <script>
        document.getElementById('download-button').addEventListener('click', function() {
            html2canvas(document.querySelector('.container'), {
                scale: 2,
                useCORS: true,
                allowTaint: true,
                backgroundColor: '#ffffff'
            }).then(function(canvas) {
                canvas.toBlob(function(blob) {
                    saveAs(blob, 'visualization.png');
                });
            });
        });
    </script>
"@
        }
        
        if ($AddPrintButton) {
            $buttons += @"
    <button class="export-button" id="print-button">Imprimer</button>
    <script>
        document.getElementById('print-button').addEventListener('click', function() {
            window.print();
        });
    </script>
"@
        }
        
        $buttons += "</div>"
        
        # Ajouter les scripts nécessaires pour le téléchargement
        if ($AddDownloadButton) {
            $downloadScripts = @"
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/2.0.5/FileSaver.min.js"></script>
"@
            
            # Insérer les scripts dans la section head
            $html = $html -replace "</head>", "$downloadScripts</head>"
        }
        
        # Insérer les boutons avant la balise </body>
        $html = $html -replace "</body>", "$buttons</body>"
    }
    
    # Inclure les données si demandé
    if ($IncludeData) {
        # Convertir les données de visualisation en JSON
        $dataJson = $Visualization | ConvertTo-Json -Depth 10 -Compress
        
        # Échapper les guillemets pour l'inclusion dans le script
        $dataJson = $dataJson -replace '"', '\"'
        
        $dataScript = @"
<script>
    // Données de visualisation
    const visualizationData = JSON.parse("$dataJson");
    
    // Fonction pour accéder aux données
    function getVisualizationData() {
        return visualizationData;
    }
</script>
"@
        
        # Insérer le script de données avant la balise </body>
        $html = $html -replace "</body>", "$dataScript</body>"
    }
    
    return $html
}

# Fonction pour minifier le HTML
function Get-MinifiedHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Html
    )
    
    # Supprimer les commentaires HTML
    $html = $html -replace "<!--.*?-->", ""
    
    # Supprimer les commentaires JavaScript
    $html = $html -replace "//.*?[\r\n]", ""
    $html = $html -replace "/\*.*?\*/", ""
    
    # Supprimer les espaces inutiles
    $html = $html -replace "\s+", " "
    $html = $html -replace "> <", "><"
    
    # Supprimer les espaces autour des balises
    $html = $html -replace "\s+<", "<"
    $html = $html -replace ">\s+", ">"
    
    # Supprimer les espaces autour des attributs
    $html = $html -replace "\s+=\s+", "="
    
    return $html
}

# Fonction principale pour exporter en HTML interactif
function Export-InteractiveHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VisualizationPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standalone", "Embedded", "Interactive")]
        [string]$ExportType = "Standalone",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeData,
        
        [Parameter(Mandatory = $false)]
        [switch]$MinifyOutput,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddDownloadButton,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddPrintButton
    )
    
    # Vérifier si le chemin de visualisation est spécifié
    if ([string]::IsNullOrEmpty($VisualizationPath)) {
        # Afficher une boîte de dialogue pour sélectionner un fichier
        Add-Type -AssemblyName System.Windows.Forms
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "Visualization files (*.json)|*.json|All files (*.*)|*.*"
        $openFileDialog.Title = "Select a visualization file"
        
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $VisualizationPath = $openFileDialog.FileName
        } else {
            Write-Log "No visualization file selected" -Level "Warning"
            return $false
        }
    }
    
    # Charger la visualisation
    $visualization = Get-VisualizationFromFile -VisualizationPath $VisualizationPath
    
    if ($null -eq $visualization) {
        return $false
    }
    
    # Générer le HTML interactif
    $html = Get-InteractiveHtml -Visualization $visualization -ExportType $ExportType -IncludeData:$IncludeData -AddDownloadButton:$AddDownloadButton -AddPrintButton:$AddPrintButton
    
    # Minifier le HTML si demandé
    if ($MinifyOutput) {
        $html = Get-MinifiedHtml -Html $html
    }
    
    # Déterminer le chemin de sortie si non spécifié
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $suffix = $ExportType.ToLower()
        $OutputPath = [System.IO.Path]::ChangeExtension($VisualizationPath, ".$suffix.html")
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Sauvegarder le HTML
    try {
        $html | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Interactive HTML exported successfully to: $OutputPath" -Level "Info"
        
        # Ouvrir le fichier HTML dans le navigateur par défaut
        Start-Process $OutputPath
        
        return $true
    } catch {
        Write-Log "Error saving HTML: $_" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Export-InteractiveHtml -VisualizationPath $VisualizationPath -OutputPath $OutputPath -ExportType $ExportType -IncludeData:$IncludeData -MinifyOutput:$MinifyOutput -AddDownloadButton:$AddDownloadButton -AddPrintButton:$AddPrintButton
}
