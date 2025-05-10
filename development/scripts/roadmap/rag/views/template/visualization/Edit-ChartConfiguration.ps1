# Edit-ChartConfiguration.ps1
# Script pour l'éditeur de configuration de graphiques
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Pie", "Bar", "Line", "Radar", "Doughnut", "Scatter")]
    [string]$ChartType = "Pie",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Status", "Priority", "Assignee", "DueDate", "Custom")]
    [string]$DataField = "Status",
    
    [Parameter(Mandatory = $false)]
    [string]$Title = "Roadmap Chart",
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowLegend,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableAnimation,
    
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

# Fonction pour charger une configuration existante
function Get-ChartConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )
    
    if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading chart configuration: $_" -Level "Error"
            return $null
        }
    }
    
    # Configuration par défaut
    $defaultConfig = @{
        ChartType = $ChartType
        DataField = $DataField
        Title = $Title
        ShowLegend = $ShowLegend.IsPresent
        EnableAnimation = $EnableAnimation.IsPresent
        Colors = @(
            "#3498db",  # Bleu
            "#2ecc71",  # Vert
            "#e74c3c",  # Rouge
            "#f39c12",  # Jaune
            "#9b59b6",  # Violet
            "#1abc9c",  # Turquoise
            "#34495e",  # Bleu foncé
            "#e67e22",  # Orange
            "#95a5a6",  # Gris
            "#d35400"   # Orange foncé
        )
        Options = @{
            Responsive = $true
            MaintainAspectRatio = $true
            Legend = @{
                Display = $ShowLegend.IsPresent
                Position = "right"
            }
            Animation = @{
                Duration = if ($EnableAnimation.IsPresent) { 1000 } else { 0 }
                Easing = "easeOutQuart"
            }
            Title = @{
                Display = -not [string]::IsNullOrEmpty($Title)
                Text = $Title
                FontSize = 16
                FontColor = "#333"
            }
        }
        DataMapping = @{
            Status = @{
                Labels = @("À faire", "En cours", "Terminé", "Bloqué")
                DataFields = @("tasks_todo", "tasks_in_progress", "tasks_done", "tasks_blocked")
                Colors = @("#f39c12", "#3498db", "#2ecc71", "#e74c3c")
            }
            Priority = @{
                Labels = @("Haute", "Moyenne", "Basse")
                DataFields = @("tasks_high", "tasks_medium", "tasks_low")
                Colors = @("#e74c3c", "#f39c12", "#2ecc71")
            }
            Assignee = @{
                Labels = @("{{assignees}}")
                DataFields = @("{{assignee_counts}}")
                Colors = @("{{assignee_colors}}")
            }
            DueDate = @{
                Labels = @("Cette semaine", "Ce mois", "Prochain mois", "Plus tard")
                DataFields = @("tasks_due_this_week", "tasks_due_this_month", "tasks_due_next_month", "tasks_due_later")
                Colors = @("#e74c3c", "#f39c12", "#3498db", "#2ecc71")
            }
            Custom = @{
                Labels = @("Label 1", "Label 2", "Label 3")
                DataFields = @("value1", "value2", "value3")
                Colors = @("#3498db", "#2ecc71", "#e74c3c")
            }
        }
    }
    
    return $defaultConfig
}

# Fonction pour générer le code HTML/JS du graphique
function Get-ChartHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $chartId = "chart_" + [Guid]::NewGuid().ToString().Substring(0, 8)
    $dataMapping = $Config.DataMapping[$Config.DataField]
    
    $html = @"
<div class="chart-container" style="position: relative; height: 400px; width: 100%;">
    <canvas id="$chartId"></canvas>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    var ctx = document.getElementById('$chartId').getContext('2d');
    var chart = new Chart(ctx, {
        type: '$($Config.ChartType.ToLower())',
        data: {
            labels: $($dataMapping.Labels | ConvertTo-Json -Compress),
            datasets: [{
                label: '$($Config.Title)',
                data: $($dataMapping.DataFields | ConvertTo-Json -Compress),
                backgroundColor: $($dataMapping.Colors | ConvertTo-Json -Compress),
                borderColor: $($dataMapping.Colors | ConvertTo-Json -Compress),
                borderWidth: 1
            }]
        },
        options: $($Config.Options | ConvertTo-Json -Depth 10 -Compress)
    });
});
</script>
"@
    
    return $html
}

# Fonction pour afficher l'interface utilisateur de configuration
function Show-ConfigurationUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Éditeur de configuration de graphiques"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    
    # Type de graphique
    $chartTypeLabel = New-Object System.Windows.Forms.Label
    $chartTypeLabel.Text = "Type de graphique:"
    $chartTypeLabel.Location = New-Object System.Drawing.Point(20, 20)
    $chartTypeLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $chartTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $chartTypeComboBox.Location = New-Object System.Drawing.Point(180, 20)
    $chartTypeComboBox.Size = New-Object System.Drawing.Size(200, 20)
    $chartTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("Pie", "Bar", "Line", "Radar", "Doughnut", "Scatter") | ForEach-Object {
        $chartTypeComboBox.Items.Add($_)
    }
    
    $chartTypeComboBox.SelectedItem = $Config.ChartType
    
    # Champ de données
    $dataFieldLabel = New-Object System.Windows.Forms.Label
    $dataFieldLabel.Text = "Champ de données:"
    $dataFieldLabel.Location = New-Object System.Drawing.Point(20, 60)
    $dataFieldLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $dataFieldComboBox = New-Object System.Windows.Forms.ComboBox
    $dataFieldComboBox.Location = New-Object System.Drawing.Point(180, 60)
    $dataFieldComboBox.Size = New-Object System.Drawing.Size(200, 20)
    $dataFieldComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("Status", "Priority", "Assignee", "DueDate", "Custom") | ForEach-Object {
        $dataFieldComboBox.Items.Add($_)
    }
    
    $dataFieldComboBox.SelectedItem = $Config.DataField
    
    # Titre
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Titre:"
    $titleLabel.Location = New-Object System.Drawing.Point(20, 100)
    $titleLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $titleTextBox = New-Object System.Windows.Forms.TextBox
    $titleTextBox.Location = New-Object System.Drawing.Point(180, 100)
    $titleTextBox.Size = New-Object System.Drawing.Size(200, 20)
    $titleTextBox.Text = $Config.Title
    
    # Afficher la légende
    $showLegendCheckBox = New-Object System.Windows.Forms.CheckBox
    $showLegendCheckBox.Text = "Afficher la légende"
    $showLegendCheckBox.Location = New-Object System.Drawing.Point(20, 140)
    $showLegendCheckBox.Size = New-Object System.Drawing.Size(200, 20)
    $showLegendCheckBox.Checked = $Config.ShowLegend
    
    # Activer l'animation
    $enableAnimationCheckBox = New-Object System.Windows.Forms.CheckBox
    $enableAnimationCheckBox.Text = "Activer l'animation"
    $enableAnimationCheckBox.Location = New-Object System.Drawing.Point(20, 180)
    $enableAnimationCheckBox.Size = New-Object System.Drawing.Size(200, 20)
    $enableAnimationCheckBox.Checked = $Config.EnableAnimation
    
    # Prévisualisation
    $previewButton = New-Object System.Windows.Forms.Button
    $previewButton.Text = "Prévisualiser"
    $previewButton.Location = New-Object System.Drawing.Point(20, 220)
    $previewButton.Size = New-Object System.Drawing.Size(100, 30)
    
    $previewButton.Add_Click({
        $Config.ChartType = $chartTypeComboBox.SelectedItem
        $Config.DataField = $dataFieldComboBox.SelectedItem
        $Config.Title = $titleTextBox.Text
        $Config.ShowLegend = $showLegendCheckBox.Checked
        $Config.EnableAnimation = $enableAnimationCheckBox.Checked
        
        $Config.Options.Legend.Display = $showLegendCheckBox.Checked
        $Config.Options.Animation.Duration = if ($enableAnimationCheckBox.Checked) { 1000 } else { 0 }
        $Config.Options.Title.Display = -not [string]::IsNullOrEmpty($titleTextBox.Text)
        $Config.Options.Title.Text = $titleTextBox.Text
        
        $html = Get-ChartHtml -Config $Config
        
        $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.html'
        
        $fullHtml = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Prévisualisation du graphique</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Prévisualisation du graphique</h1>
    $html
</body>
</html>
"@
        
        $fullHtml | Out-File -FilePath $tempFile -Encoding UTF8
        Start-Process $tempFile
    })
    
    # Boutons OK/Annuler
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(600, 500)
    $okButton.Size = New-Object System.Drawing.Size(75, 30)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Annuler"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(700, 500)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    
    # Ajouter les contrôles au formulaire
    $form.Controls.Add($chartTypeLabel)
    $form.Controls.Add($chartTypeComboBox)
    $form.Controls.Add($dataFieldLabel)
    $form.Controls.Add($dataFieldComboBox)
    $form.Controls.Add($titleLabel)
    $form.Controls.Add($titleTextBox)
    $form.Controls.Add($showLegendCheckBox)
    $form.Controls.Add($enableAnimationCheckBox)
    $form.Controls.Add($previewButton)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)
    
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $Config.ChartType = $chartTypeComboBox.SelectedItem
        $Config.DataField = $dataFieldComboBox.SelectedItem
        $Config.Title = $titleTextBox.Text
        $Config.ShowLegend = $showLegendCheckBox.Checked
        $Config.EnableAnimation = $enableAnimationCheckBox.Checked
        
        $Config.Options.Legend.Display = $showLegendCheckBox.Checked
        $Config.Options.Animation.Duration = if ($enableAnimationCheckBox.Checked) { 1000 } else { 0 }
        $Config.Options.Title.Display = -not [string]::IsNullOrEmpty($titleTextBox.Text)
        $Config.Options.Title.Text = $titleTextBox.Text
        
        return $Config
    } else {
        return $null
    }
}

# Fonction principale
function Edit-ChartConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Pie", "Bar", "Line", "Radar", "Doughnut", "Scatter")]
        [string]$ChartType = "Pie",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Status", "Priority", "Assignee", "DueDate", "Custom")]
        [string]$DataField = "Status",
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Roadmap Chart",
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowLegend,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAnimation
    )
    
    # Charger la configuration existante ou créer une nouvelle
    $config = Get-ChartConfiguration -ConfigPath $ConfigPath
    
    if ($null -eq $config) {
        Write-Log "Creating new chart configuration" -Level "Info"
        $config = Get-ChartConfiguration
    } else {
        Write-Log "Loaded existing chart configuration" -Level "Info"
    }
    
    # Mettre à jour la configuration avec les paramètres fournis
    if ($PSBoundParameters.ContainsKey('ChartType')) {
        $config.ChartType = $ChartType
    }
    
    if ($PSBoundParameters.ContainsKey('DataField')) {
        $config.DataField = $DataField
    }
    
    if ($PSBoundParameters.ContainsKey('Title')) {
        $config.Title = $Title
        $config.Options.Title.Text = $Title
        $config.Options.Title.Display = -not [string]::IsNullOrEmpty($Title)
    }
    
    if ($PSBoundParameters.ContainsKey('ShowLegend')) {
        $config.ShowLegend = $ShowLegend.IsPresent
        $config.Options.Legend.Display = $ShowLegend.IsPresent
    }
    
    if ($PSBoundParameters.ContainsKey('EnableAnimation')) {
        $config.EnableAnimation = $EnableAnimation.IsPresent
        $config.Options.Animation.Duration = if ($EnableAnimation.IsPresent) { 1000 } else { 0 }
    }
    
    # Afficher l'interface utilisateur de configuration
    $updatedConfig = Show-ConfigurationUI -Config $config
    
    if ($null -eq $updatedConfig) {
        Write-Log "Chart configuration cancelled by user" -Level "Info"
        return $null
    }
    
    # Sauvegarder la configuration
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $updatedConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Chart configuration saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving chart configuration: $_" -Level "Error"
        }
    }
    
    # Générer le code HTML/JS du graphique
    $html = Get-ChartHtml -Config $updatedConfig
    
    return @{
        Config = $updatedConfig
        Html = $html
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Edit-ChartConfiguration -ConfigPath $ConfigPath -OutputPath $OutputPath -ChartType $ChartType -DataField $DataField -Title $Title -ShowLegend:$ShowLegend -EnableAnimation:$EnableAnimation
}
