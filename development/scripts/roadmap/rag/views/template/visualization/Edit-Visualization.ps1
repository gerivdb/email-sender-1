# Edit-Visualization.ps1
# Script principal pour l'éditeur de visualisations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VisualizationPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplatePath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Chart", "DataMapping", "Template", "Preview")]
    [string]$EditMode = "Chart",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
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

# Importer les scripts nécessaires
$chartConfigPath = Join-Path -Path $scriptPath -ChildPath "Edit-ChartConfiguration.ps1"
$dataMappingPath = Join-Path -Path $scriptPath -ChildPath "Edit-DataMapping.ps1"
$htmlTemplatePath = Join-Path -Path $parentPath -ChildPath "Edit-HtmlTemplate.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($chartConfigPath, $dataMappingPath, $htmlTemplatePath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $chartConfigPath
. $dataMappingPath
. $htmlTemplatePath

# Fonction pour charger une visualisation existante
function Get-Visualization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VisualizationPath
    )
    
    if (-not [string]::IsNullOrEmpty($VisualizationPath) -and (Test-Path -Path $VisualizationPath)) {
        try {
            $visualization = Get-Content -Path $VisualizationPath -Raw | ConvertFrom-Json
            return $visualization
        } catch {
            Write-Log "Error loading visualization: $_" -Level "Error"
            return $null
        }
    }
    
    # Visualisation par défaut
    $defaultVisualization = @{
        Version = "1.0"
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ModifiedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Name = "Roadmap Visualization"
        Description = "Visualisation des données de roadmap"
        ChartConfiguration = Get-ChartConfiguration
        DataMapping = Get-DataMapping
        TemplateHtml = $null
    }
    
    return $defaultVisualization
}

# Fonction pour générer le HTML complet de la visualisation
function Get-VisualizationHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Visualization,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath
    )
    
    # Utiliser le template HTML fourni ou générer un template par défaut
    $templateHtml = $Visualization.TemplateHtml
    
    if ([string]::IsNullOrEmpty($templateHtml) -and -not [string]::IsNullOrEmpty($TemplatePath) -and (Test-Path -Path $TemplatePath)) {
        try {
            $templateHtml = Get-Content -Path $TemplatePath -Raw
        } catch {
            Write-Log "Error loading template HTML: $_" -Level "Error"
        }
    }
    
    if ([string]::IsNullOrEmpty($templateHtml)) {
        # Template HTML par défaut
        $templateHtml = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .chart-container {
            position: relative;
            height: 400px;
            margin-bottom: 30px;
        }
        .chart-title {
            text-align: center;
            margin-bottom: 20px;
            font-size: 1.5em;
        }
        .chart-description {
            text-align: center;
            margin-bottom: 20px;
            color: #7f8c8d;
        }
        .footer {
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #ddd;
            font-size: 0.8em;
            color: #7f8c8d;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>{{title}}</h1>
        
        <div class="description">
            <p>{{description}}</p>
        </div>
        
        <div class="chart-container">
            <div class="chart-title">Distribution par statut</div>
            <canvas id="statusChart"></canvas>
        </div>
        
        <div class="chart-container">
            <div class="chart-title">Distribution par priorité</div>
            <canvas id="priorityChart"></canvas>
        </div>
        
        <div class="footer">
            <p>Généré le {{date}} à {{time}} par {{username}}</p>
        </div>
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Graphique de statut
            var statusCtx = document.getElementById('statusChart').getContext('2d');
            var statusChart = new Chart(statusCtx, {
                type: 'pie',
                data: {
                    labels: ['À faire', 'En cours', 'Terminé', 'Bloqué'],
                    datasets: [{
                        data: [{{tasks_todo}}, {{tasks_in_progress}}, {{tasks_done}}, {{tasks_blocked}}],
                        backgroundColor: [
                            '#f39c12', // À faire (jaune)
                            '#3498db', // En cours (bleu)
                            '#2ecc71', // Terminé (vert)
                            '#e74c3c'  // Bloqué (rouge)
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    legend: {
                        position: 'right'
                    }
                }
            });
            
            // Graphique de priorité
            var priorityCtx = document.getElementById('priorityChart').getContext('2d');
            var priorityChart = new Chart(priorityCtx, {
                type: 'bar',
                data: {
                    labels: ['Haute', 'Moyenne', 'Basse'],
                    datasets: [{
                        label: 'Nombre de tâches',
                        data: [{{tasks_high}}, {{tasks_medium}}, {{tasks_low}}],
                        backgroundColor: [
                            '#e74c3c', // Haute (rouge)
                            '#f39c12', // Moyenne (jaune)
                            '#2ecc71'  // Basse (vert)
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        yAxes: [{
                            ticks: {
                                beginAtZero: true,
                                stepSize: 1
                            }
                        }]
                    }
                }
            });
        });
    </script>
</body>
</html>
"@
    }
    
    # Générer le code HTML des graphiques
    $chartHtml = Get-ChartHtml -Config $Visualization.ChartConfiguration
    
    # Remplacer les placeholders dans le template
    $html = $templateHtml -replace "{{chart}}", $chartHtml
    
    return $html
}

# Fonction pour afficher l'interface utilisateur principale
function Show-VisualizationUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Visualization,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Éditeur de visualisations"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    
    # Informations générales
    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = "Nom:"
    $nameLabel.Location = New-Object System.Drawing.Point(20, 20)
    $nameLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.Location = New-Object System.Drawing.Point(130, 20)
    $nameTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $nameTextBox.Text = $Visualization.Name
    
    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Text = "Description:"
    $descriptionLabel.Location = New-Object System.Drawing.Point(20, 50)
    $descriptionLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $descriptionTextBox = New-Object System.Windows.Forms.TextBox
    $descriptionTextBox.Location = New-Object System.Drawing.Point(130, 50)
    $descriptionTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $descriptionTextBox.Text = $Visualization.Description
    
    # Boutons d'édition
    $editChartButton = New-Object System.Windows.Forms.Button
    $editChartButton.Text = "Éditer le graphique"
    $editChartButton.Location = New-Object System.Drawing.Point(20, 100)
    $editChartButton.Size = New-Object System.Drawing.Size(150, 30)
    
    $editMappingButton = New-Object System.Windows.Forms.Button
    $editMappingButton.Text = "Éditer le mappage"
    $editMappingButton.Location = New-Object System.Drawing.Point(180, 100)
    $editMappingButton.Size = New-Object System.Drawing.Size(150, 30)
    
    $editTemplateButton = New-Object System.Windows.Forms.Button
    $editTemplateButton.Text = "Éditer le template"
    $editTemplateButton.Location = New-Object System.Drawing.Point(340, 100)
    $editTemplateButton.Size = New-Object System.Drawing.Size(150, 30)
    
    $previewButton = New-Object System.Windows.Forms.Button
    $previewButton.Text = "Prévisualiser"
    $previewButton.Location = New-Object System.Drawing.Point(500, 100)
    $previewButton.Size = New-Object System.Drawing.Size(150, 30)
    
    # Prévisualisation
    $previewLabel = New-Object System.Windows.Forms.Label
    $previewLabel.Text = "Prévisualisation:"
    $previewLabel.Location = New-Object System.Drawing.Point(20, 150)
    $previewLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $browser = New-Object System.Windows.Forms.WebBrowser
    $browser.Location = New-Object System.Drawing.Point(20, 180)
    $browser.Size = New-Object System.Drawing.Size(750, 350)
    $browser.Dock = [System.Windows.Forms.DockStyle]::None
    
    # Boutons OK/Annuler
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(600, 540)
    $okButton.Size = New-Object System.Drawing.Size(75, 30)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Annuler"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(700, 540)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    
    # Événement d'édition du graphique
    $editChartButton.Add_Click({
        $updatedConfig = Edit-ChartConfiguration -ConfigPath $null -OutputPath $null
        
        if ($null -ne $updatedConfig) {
            $Visualization.ChartConfiguration = $updatedConfig.Config
            
            # Mettre à jour la prévisualisation
            $html = Get-VisualizationHtml -Visualization $Visualization -TemplatePath $TemplatePath
            $browser.DocumentText = $html
        }
    })
    
    # Événement d'édition du mappage
    $editMappingButton.Add_Click({
        $updatedMapping = Edit-DataMapping -MappingPath $null -OutputPath $null -RoadmapPath $RoadmapPath
        
        if ($null -ne $updatedMapping) {
            $Visualization.DataMapping = $updatedMapping
            
            # Mettre à jour la prévisualisation
            $html = Get-VisualizationHtml -Visualization $Visualization -TemplatePath $TemplatePath
            $browser.DocumentText = $html
        }
    })
    
    # Événement d'édition du template
    $editTemplateButton.Add_Click({
        $updatedTemplate = Edit-HtmlTemplate -TemplateContent $Visualization.TemplateHtml -OutputPath $null -EditorMode "GUI" -EnablePreview -EnableComponentInsertion
        
        if ($null -ne $updatedTemplate) {
            $Visualization.TemplateHtml = $updatedTemplate
            
            # Mettre à jour la prévisualisation
            $html = Get-VisualizationHtml -Visualization $Visualization -TemplatePath $TemplatePath
            $browser.DocumentText = $html
        }
    })
    
    # Événement de prévisualisation
    $previewButton.Add_Click({
        $html = Get-VisualizationHtml -Visualization $Visualization -TemplatePath $TemplatePath
        
        $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.html'
        $html | Out-File -FilePath $tempFile -Encoding UTF8
        
        Start-Process $tempFile
    })
    
    # Ajouter les contrôles au formulaire
    $form.Controls.Add($nameLabel)
    $form.Controls.Add($nameTextBox)
    $form.Controls.Add($descriptionLabel)
    $form.Controls.Add($descriptionTextBox)
    $form.Controls.Add($editChartButton)
    $form.Controls.Add($editMappingButton)
    $form.Controls.Add($editTemplateButton)
    $form.Controls.Add($previewButton)
    $form.Controls.Add($previewLabel)
    $form.Controls.Add($browser)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)
    
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    
    # Initialiser la prévisualisation
    $html = Get-VisualizationHtml -Visualization $Visualization -TemplatePath $TemplatePath
    $browser.DocumentText = $html
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $Visualization.Name = $nameTextBox.Text
        $Visualization.Description = $descriptionTextBox.Text
        $Visualization.ModifiedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        return $Visualization
    } else {
        return $null
    }
}

# Fonction principale
function Edit-Visualization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VisualizationPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Chart", "DataMapping", "Template", "Preview")]
        [string]$EditMode = "Chart"
    )
    
    # Charger la visualisation existante ou créer une nouvelle
    $visualization = Get-Visualization -VisualizationPath $VisualizationPath
    
    if ($null -eq $visualization) {
        Write-Log "Creating new visualization" -Level "Info"
        $visualization = Get-Visualization
    } else {
        Write-Log "Loaded existing visualization" -Level "Info"
    }
    
    # Éditer directement un composant spécifique si demandé
    switch ($EditMode) {
        "Chart" {
            $updatedConfig = Edit-ChartConfiguration -ConfigPath $null -OutputPath $null
            
            if ($null -ne $updatedConfig) {
                $visualization.ChartConfiguration = $updatedConfig.Config
            } else {
                return $null
            }
        }
        "DataMapping" {
            $updatedMapping = Edit-DataMapping -MappingPath $null -OutputPath $null -RoadmapPath $RoadmapPath
            
            if ($null -ne $updatedMapping) {
                $visualization.DataMapping = $updatedMapping
            } else {
                return $null
            }
        }
        "Template" {
            $updatedTemplate = Edit-HtmlTemplate -TemplateContent $visualization.TemplateHtml -OutputPath $null -EditorMode "GUI" -EnablePreview -EnableComponentInsertion
            
            if ($null -ne $updatedTemplate) {
                $visualization.TemplateHtml = $updatedTemplate
            } else {
                return $null
            }
        }
        "Preview" {
            $html = Get-VisualizationHtml -Visualization $visualization -TemplatePath $TemplatePath
            
            $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.html'
            $html | Out-File -FilePath $tempFile -Encoding UTF8
            
            Start-Process $tempFile
            return $visualization
        }
        default {
            # Afficher l'interface utilisateur principale
            $updatedVisualization = Show-VisualizationUI -Visualization $visualization -RoadmapPath $RoadmapPath -TemplatePath $TemplatePath
            
            if ($null -eq $updatedVisualization) {
                Write-Log "Visualization editing cancelled by user" -Level "Info"
                return $null
            }
            
            $visualization = $updatedVisualization
        }
    }
    
    # Sauvegarder la visualisation
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $visualization | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Visualization saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving visualization: $_" -Level "Error"
        }
    }
    
    return $visualization
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Edit-Visualization -VisualizationPath $VisualizationPath -OutputPath $OutputPath -RoadmapPath $RoadmapPath -TemplatePath $TemplatePath -EditMode $EditMode
}
