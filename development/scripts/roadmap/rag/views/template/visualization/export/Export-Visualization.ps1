# Export-Visualization.ps1
# Script principal pour l'export et le partage des visualisations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VisualizationPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Image", "HTML", "Embed", "All")]
    [string]$ExportType = "All",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("PNG", "JPEG", "SVG", "PDF")]
    [string]$ImageFormat = "PNG",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Standalone", "Embedded", "Interactive")]
    [string]$HtmlType = "Interactive",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams")]
    [string]$EmbedType = "Iframe",
    
    [Parameter(Mandatory = $false)]
    [string]$ServerUrl = "http://localhost:8080",
    
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

# Importer les scripts d'export
$imageExportPath = Join-Path -Path $scriptPath -ChildPath "Export-VisualizationImage.ps1"
$htmlExportPath = Join-Path -Path $scriptPath -ChildPath "Export-InteractiveHtml.ps1"
$embedExportPath = Join-Path -Path $scriptPath -ChildPath "Export-VisualizationEmbed.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($imageExportPath, $htmlExportPath, $embedExportPath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $imageExportPath
. $htmlExportPath
. $embedExportPath

# Fonction pour afficher l'interface utilisateur principale d'export
function Show-ExportUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VisualizationPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Image", "HTML", "Embed", "All")]
        [string]$ExportType = "All",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("PNG", "JPEG", "SVG", "PDF")]
        [string]$ImageFormat = "PNG",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standalone", "Embedded", "Interactive")]
        [string]$HtmlType = "Interactive",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams")]
        [string]$EmbedType = "Iframe",
        
        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:8080"
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Export de visualisation"
    $form.Size = New-Object System.Drawing.Size(600, 500)
    $form.StartPosition = "CenterScreen"
    
    # Sélection du fichier de visualisation
    $visualizationLabel = New-Object System.Windows.Forms.Label
    $visualizationLabel.Text = "Fichier de visualisation:"
    $visualizationLabel.Location = New-Object System.Drawing.Point(20, 20)
    $visualizationLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $visualizationTextBox = New-Object System.Windows.Forms.TextBox
    $visualizationTextBox.Location = New-Object System.Drawing.Point(180, 20)
    $visualizationTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $visualizationTextBox.Text = $VisualizationPath
    
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = "..."
    $browseButton.Location = New-Object System.Drawing.Point(490, 20)
    $browseButton.Size = New-Object System.Drawing.Size(30, 20)
    
    $browseButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "Visualization files (*.json)|*.json|All files (*.*)|*.*"
        $openFileDialog.Title = "Select a visualization file"
        
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $visualizationTextBox.Text = $openFileDialog.FileName
        }
    })
    
    # Répertoire de sortie
    $outputLabel = New-Object System.Windows.Forms.Label
    $outputLabel.Text = "Répertoire de sortie:"
    $outputLabel.Location = New-Object System.Drawing.Point(20, 60)
    $outputLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(180, 60)
    $outputTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $outputTextBox.Text = $OutputPath
    
    $outputBrowseButton = New-Object System.Windows.Forms.Button
    $outputBrowseButton.Text = "..."
    $outputBrowseButton.Location = New-Object System.Drawing.Point(490, 60)
    $outputBrowseButton.Size = New-Object System.Drawing.Size(30, 20)
    
    $outputBrowseButton.Add_Click({
        $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowserDialog.Description = "Select output directory"
        
        if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $outputTextBox.Text = $folderBrowserDialog.SelectedPath
        }
    })
    
    # Options d'export
    $exportOptionsGroupBox = New-Object System.Windows.Forms.GroupBox
    $exportOptionsGroupBox.Text = "Options d'export"
    $exportOptionsGroupBox.Location = New-Object System.Drawing.Point(20, 100)
    $exportOptionsGroupBox.Size = New-Object System.Drawing.Size(550, 300)
    
    # Type d'export
    $exportTypeLabel = New-Object System.Windows.Forms.Label
    $exportTypeLabel.Text = "Type d'export:"
    $exportTypeLabel.Location = New-Object System.Drawing.Point(20, 30)
    $exportTypeLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $exportTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $exportTypeComboBox.Location = New-Object System.Drawing.Point(180, 30)
    $exportTypeComboBox.Size = New-Object System.Drawing.Size(200, 20)
    $exportTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("Image", "HTML", "Embed", "All") | ForEach-Object {
        $exportTypeComboBox.Items.Add($_)
    }
    
    $exportTypeComboBox.SelectedItem = $ExportType
    
    # Options d'image
    $imageOptionsPanel = New-Object System.Windows.Forms.Panel
    $imageOptionsPanel.Location = New-Object System.Drawing.Point(20, 70)
    $imageOptionsPanel.Size = New-Object System.Drawing.Size(510, 60)
    
    $imageFormatLabel = New-Object System.Windows.Forms.Label
    $imageFormatLabel.Text = "Format d'image:"
    $imageFormatLabel.Location = New-Object System.Drawing.Point(0, 10)
    $imageFormatLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $imageFormatComboBox = New-Object System.Windows.Forms.ComboBox
    $imageFormatComboBox.Location = New-Object System.Drawing.Point(160, 10)
    $imageFormatComboBox.Size = New-Object System.Drawing.Size(100, 20)
    $imageFormatComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("PNG", "JPEG", "SVG", "PDF") | ForEach-Object {
        $imageFormatComboBox.Items.Add($_)
    }
    
    $imageFormatComboBox.SelectedItem = $ImageFormat
    
    $includeTimestampCheckBox = New-Object System.Windows.Forms.CheckBox
    $includeTimestampCheckBox.Text = "Inclure horodatage"
    $includeTimestampCheckBox.Location = New-Object System.Drawing.Point(280, 10)
    $includeTimestampCheckBox.Size = New-Object System.Drawing.Size(150, 20)
    
    $includeWatermarkCheckBox = New-Object System.Windows.Forms.CheckBox
    $includeWatermarkCheckBox.Text = "Inclure filigrane"
    $includeWatermarkCheckBox.Location = New-Object System.Drawing.Point(0, 40)
    $includeWatermarkCheckBox.Size = New-Object System.Drawing.Size(150, 20)
    
    $imageOptionsPanel.Controls.Add($imageFormatLabel)
    $imageOptionsPanel.Controls.Add($imageFormatComboBox)
    $imageOptionsPanel.Controls.Add($includeTimestampCheckBox)
    $imageOptionsPanel.Controls.Add($includeWatermarkCheckBox)
    
    # Options HTML
    $htmlOptionsPanel = New-Object System.Windows.Forms.Panel
    $htmlOptionsPanel.Location = New-Object System.Drawing.Point(20, 140)
    $htmlOptionsPanel.Size = New-Object System.Drawing.Size(510, 60)
    
    $htmlTypeLabel = New-Object System.Windows.Forms.Label
    $htmlTypeLabel.Text = "Type HTML:"
    $htmlTypeLabel.Location = New-Object System.Drawing.Point(0, 10)
    $htmlTypeLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $htmlTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $htmlTypeComboBox.Location = New-Object System.Drawing.Point(160, 10)
    $htmlTypeComboBox.Size = New-Object System.Drawing.Size(150, 20)
    $htmlTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("Standalone", "Embedded", "Interactive") | ForEach-Object {
        $htmlTypeComboBox.Items.Add($_)
    }
    
    $htmlTypeComboBox.SelectedItem = $HtmlType
    
    $includeDataCheckBox = New-Object System.Windows.Forms.CheckBox
    $includeDataCheckBox.Text = "Inclure les données"
    $includeDataCheckBox.Location = New-Object System.Drawing.Point(0, 40)
    $includeDataCheckBox.Size = New-Object System.Drawing.Size(150, 20)
    
    $minifyOutputCheckBox = New-Object System.Windows.Forms.CheckBox
    $minifyOutputCheckBox.Text = "Minifier la sortie"
    $minifyOutputCheckBox.Location = New-Object System.Drawing.Point(160, 40)
    $minifyOutputCheckBox.Size = New-Object System.Drawing.Size(150, 20)
    
    $htmlOptionsPanel.Controls.Add($htmlTypeLabel)
    $htmlOptionsPanel.Controls.Add($htmlTypeComboBox)
    $htmlOptionsPanel.Controls.Add($includeDataCheckBox)
    $htmlOptionsPanel.Controls.Add($minifyOutputCheckBox)
    
    # Options d'intégration
    $embedOptionsPanel = New-Object System.Windows.Forms.Panel
    $embedOptionsPanel.Location = New-Object System.Drawing.Point(20, 210)
    $embedOptionsPanel.Size = New-Object System.Drawing.Size(510, 80)
    
    $embedTypeLabel = New-Object System.Windows.Forms.Label
    $embedTypeLabel.Text = "Type d'intégration:"
    $embedTypeLabel.Location = New-Object System.Drawing.Point(0, 10)
    $embedTypeLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $embedTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $embedTypeComboBox.Location = New-Object System.Drawing.Point(160, 10)
    $embedTypeComboBox.Size = New-Object System.Drawing.Size(150, 20)
    $embedTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams") | ForEach-Object {
        $embedTypeComboBox.Items.Add($_)
    }
    
    $embedTypeComboBox.SelectedItem = $EmbedType
    
    $serverUrlLabel = New-Object System.Windows.Forms.Label
    $serverUrlLabel.Text = "URL du serveur:"
    $serverUrlLabel.Location = New-Object System.Drawing.Point(0, 40)
    $serverUrlLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $serverUrlTextBox = New-Object System.Windows.Forms.TextBox
    $serverUrlTextBox.Location = New-Object System.Drawing.Point(160, 40)
    $serverUrlTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $serverUrlTextBox.Text = $ServerUrl
    
    $embedOptionsPanel.Controls.Add($embedTypeLabel)
    $embedOptionsPanel.Controls.Add($embedTypeComboBox)
    $embedOptionsPanel.Controls.Add($serverUrlLabel)
    $embedOptionsPanel.Controls.Add($serverUrlTextBox)
    
    $exportOptionsGroupBox.Controls.Add($exportTypeLabel)
    $exportOptionsGroupBox.Controls.Add($exportTypeComboBox)
    $exportOptionsGroupBox.Controls.Add($imageOptionsPanel)
    $exportOptionsGroupBox.Controls.Add($htmlOptionsPanel)
    $exportOptionsGroupBox.Controls.Add($embedOptionsPanel)
    
    # Événement de changement de type d'export
    $exportTypeComboBox.Add_SelectedIndexChanged({
        $selectedType = $exportTypeComboBox.SelectedItem
        
        $imageOptionsPanel.Visible = ($selectedType -eq "Image" -or $selectedType -eq "All")
        $htmlOptionsPanel.Visible = ($selectedType -eq "HTML" -or $selectedType -eq "All")
        $embedOptionsPanel.Visible = ($selectedType -eq "Embed" -or $selectedType -eq "All")
    })
    
    # Déclencher l'événement pour initialiser l'état
    $exportTypeComboBox.SelectedItem = $ExportType
    
    # Boutons OK/Annuler
    $exportButton = New-Object System.Windows.Forms.Button
    $exportButton.Text = "Exporter"
    $exportButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $exportButton.Location = New-Object System.Drawing.Point(400, 420)
    $exportButton.Size = New-Object System.Drawing.Size(75, 30)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Annuler"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(490, 420)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    
    # Ajouter les contrôles au formulaire
    $form.Controls.Add($visualizationLabel)
    $form.Controls.Add($visualizationTextBox)
    $form.Controls.Add($browseButton)
    $form.Controls.Add($outputLabel)
    $form.Controls.Add($outputTextBox)
    $form.Controls.Add($outputBrowseButton)
    $form.Controls.Add($exportOptionsGroupBox)
    $form.Controls.Add($exportButton)
    $form.Controls.Add($cancelButton)
    
    $form.AcceptButton = $exportButton
    $form.CancelButton = $cancelButton
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            VisualizationPath = $visualizationTextBox.Text
            OutputPath = $outputTextBox.Text
            ExportType = $exportTypeComboBox.SelectedItem
            ImageFormat = $imageFormatComboBox.SelectedItem
            IncludeTimestamp = $includeTimestampCheckBox.Checked
            IncludeWatermark = $includeWatermarkCheckBox.Checked
            HtmlType = $htmlTypeComboBox.SelectedItem
            IncludeData = $includeDataCheckBox.Checked
            MinifyOutput = $minifyOutputCheckBox.Checked
            EmbedType = $embedTypeComboBox.SelectedItem
            ServerUrl = $serverUrlTextBox.Text
        }
    } else {
        return $null
    }
}

# Fonction principale pour exporter les visualisations
function Export-Visualization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VisualizationPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Image", "HTML", "Embed", "All")]
        [string]$ExportType = "All",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("PNG", "JPEG", "SVG", "PDF")]
        [string]$ImageFormat = "PNG",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standalone", "Embedded", "Interactive")]
        [string]$HtmlType = "Interactive",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams")]
        [string]$EmbedType = "Iframe",
        
        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:8080"
    )
    
    # Afficher l'interface utilisateur d'export
    $exportOptions = Show-ExportUI -VisualizationPath $VisualizationPath -OutputPath $OutputPath -ExportType $ExportType -ImageFormat $ImageFormat -HtmlType $HtmlType -EmbedType $EmbedType -ServerUrl $ServerUrl
    
    if ($null -eq $exportOptions) {
        Write-Log "Export cancelled by user" -Level "Info"
        return $false
    }
    
    # Vérifier si le fichier de visualisation existe
    if (-not (Test-Path -Path $exportOptions.VisualizationPath)) {
        Write-Log "Visualization file not found: $($exportOptions.VisualizationPath)" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not [string]::IsNullOrEmpty($exportOptions.OutputPath) -and -not (Test-Path -Path $exportOptions.OutputPath)) {
        New-Item -Path $exportOptions.OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Exporter selon le type demandé
    $results = @{}
    
    if ($exportOptions.ExportType -eq "Image" -or $exportOptions.ExportType -eq "All") {
        Write-Log "Exporting visualization as image..." -Level "Info"
        
        $imageOutputPath = ""
        if (-not [string]::IsNullOrEmpty($exportOptions.OutputPath)) {
            $imageOutputPath = Join-Path -Path $exportOptions.OutputPath -ChildPath "visualization.$($exportOptions.ImageFormat.ToLower())"
        }
        
        $imageResult = Export-VisualizationImage -VisualizationPath $exportOptions.VisualizationPath -OutputPath $imageOutputPath -Format $exportOptions.ImageFormat -IncludeTimestamp:$exportOptions.IncludeTimestamp -IncludeWatermark:$exportOptions.IncludeWatermark
        $results["Image"] = $imageResult
    }
    
    if ($exportOptions.ExportType -eq "HTML" -or $exportOptions.ExportType -eq "All") {
        Write-Log "Exporting visualization as HTML..." -Level "Info"
        
        $htmlOutputPath = ""
        if (-not [string]::IsNullOrEmpty($exportOptions.OutputPath)) {
            $htmlOutputPath = Join-Path -Path $exportOptions.OutputPath -ChildPath "visualization.$($exportOptions.HtmlType.ToLower()).html"
        }
        
        $htmlResult = Export-InteractiveHtml -VisualizationPath $exportOptions.VisualizationPath -OutputPath $htmlOutputPath -ExportType $exportOptions.HtmlType -IncludeData:$exportOptions.IncludeData -MinifyOutput:$exportOptions.MinifyOutput
        $results["HTML"] = $htmlResult
    }
    
    if ($exportOptions.ExportType -eq "Embed" -or $exportOptions.ExportType -eq "All") {
        Write-Log "Generating embed code..." -Level "Info"
        
        $embedOutputPath = ""
        if (-not [string]::IsNullOrEmpty($exportOptions.OutputPath)) {
            $embedOutputPath = Join-Path -Path $exportOptions.OutputPath -ChildPath "embed-code-$($exportOptions.EmbedType.ToLower()).txt"
        }
        
        $embedResult = Export-VisualizationEmbed -VisualizationPath $exportOptions.VisualizationPath -OutputPath $embedOutputPath -EmbedType $exportOptions.EmbedType -ServerUrl $exportOptions.ServerUrl
        $results["Embed"] = $embedResult
    }
    
    Write-Log "Export completed" -Level "Info"
    return $results
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Export-Visualization -VisualizationPath $VisualizationPath -OutputPath $OutputPath -ExportType $ExportType -ImageFormat $ImageFormat -HtmlType $HtmlType -EmbedType $EmbedType -ServerUrl $ServerUrl
}
