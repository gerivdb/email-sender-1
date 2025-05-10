# Export-VisualizationEmbed.ps1
# Script pour générer des codes d'intégration pour les visualisations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VisualizationPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams")]
    [string]$EmbedType = "Iframe",
    
    [Parameter(Mandatory = $false)]
    [string]$ServerUrl = "http://localhost:8080",
    
    [Parameter(Mandatory = $false)]
    [string]$Width = "100%",
    
    [Parameter(Mandatory = $false)]
    [string]$Height = "600px",
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoResize,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableInteractivity,
    
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

# Fonction pour générer le code d'intégration
function Get-EmbedCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Visualization,
        
        [Parameter(Mandatory = $true)]
        [string]$EmbedType,
        
        [Parameter(Mandatory = $true)]
        [string]$ServerUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$Width,
        
        [Parameter(Mandatory = $true)]
        [string]$Height,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoResize,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableInteractivity
    )
    
    # Générer un ID unique pour la visualisation
    $visualizationId = [Guid]::NewGuid().ToString().Substring(0, 8)
    
    # Construire l'URL de la visualisation
    $visualizationUrl = "$ServerUrl/visualizations/$visualizationId"
    
    if ($EnableInteractivity) {
        $visualizationUrl += "?interactive=true"
    }
    
    # Générer le code d'intégration selon le type demandé
    switch ($EmbedType) {
        "Iframe" {
            $resizeScript = ""
            if ($AutoResize) {
                $resizeScript = @"
<script>
// Script pour ajuster automatiquement la hauteur de l'iframe
window.addEventListener('message', function(event) {
    if (event.data.type === 'resize' && event.data.height) {
        document.getElementById('roadmap-visualization-$visualizationId').style.height = event.data.height + 'px';
    }
});
</script>
"@
            }
            
            $embedCode = @"
<!-- Roadmap Visualization Embed -->
<iframe id="roadmap-visualization-$visualizationId" src="$visualizationUrl" width="$Width" height="$Height" frameborder="0" scrolling="no" allowfullscreen></iframe>
$resizeScript
<!-- End Roadmap Visualization Embed -->
"@
        }
        "JavaScript" {
            $embedCode = @"
<!-- Roadmap Visualization Embed -->
<div id="roadmap-visualization-$visualizationId"></div>
<script>
(function() {
    // Créer un élément script
    var script = document.createElement('script');
    script.src = '$ServerUrl/js/embed.js';
    script.async = true;
    
    // Configurer la visualisation
    script.onload = function() {
        RoadmapVisualization.render({
            container: 'roadmap-visualization-$visualizationId',
            id: '$visualizationId',
            width: '$Width',
            height: '$Height',
            autoResize: $($AutoResize.ToString().ToLower()),
            interactive: $($EnableInteractivity.ToString().ToLower())
        });
    };
    
    // Ajouter le script à la page
    document.head.appendChild(script);
})();
</script>
<!-- End Roadmap Visualization Embed -->
"@
        }
        "WordPress" {
            $embedCode = @"
<!-- Shortcode pour WordPress -->
[roadmap_visualization id="$visualizationId" width="$Width" height="$Height" auto_resize="$($AutoResize.ToString().ToLower())" interactive="$($EnableInteractivity.ToString().ToLower())"]

<!-- Alternative avec bloc HTML -->
<!-- wp:html -->
<iframe id="roadmap-visualization-$visualizationId" src="$visualizationUrl" width="$Width" height="$Height" frameborder="0" scrolling="no" allowfullscreen></iframe>
<!-- /wp:html -->
"@
        }
        "Confluence" {
            $embedCode = @"
<!-- Macro HTML pour Confluence -->
<ac:structured-macro ac:name="html">
    <ac:plain-text-body><![CDATA[
        <iframe id="roadmap-visualization-$visualizationId" src="$visualizationUrl" width="$Width" height="$Height" frameborder="0" scrolling="no" allowfullscreen></iframe>
    ]]></ac:plain-text-body>
</ac:structured-macro>

<!-- Alternative avec macro iframe -->
<ac:structured-macro ac:name="iframe">
    <ac:parameter ac:name="src">$visualizationUrl</ac:parameter>
    <ac:parameter ac:name="width">$Width</ac:parameter>
    <ac:parameter ac:name="height">$Height</ac:parameter>
</ac:structured-macro>
"@
        }
        "SharePoint" {
            $embedCode = @"
<!-- Webpart Embed pour SharePoint -->
<div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0" data-sp-controldata="{&quot;controlType&quot;:3,&quot;webPartId&quot;:&quot;490d7c76-1824-45b2-9de3-676421c997fa&quot;,&quot;webPartData&quot;:{&quot;id&quot;:&quot;490d7c76-1824-45b2-9de3-676421c997fa&quot;,&quot;instanceId&quot;:&quot;$visualizationId&quot;,&quot;title&quot;:&quot;Roadmap Visualization&quot;,&quot;description&quot;:&quot;Embedded roadmap visualization&quot;,&quot;serverProcessedContent&quot;:{&quot;htmlStrings&quot;:{&quot;embedCode&quot;:&quot;&lt;iframe id=\&quot;roadmap-visualization-$visualizationId\&quot; src=\&quot;$visualizationUrl\&quot; width=\&quot;$Width\&quot; height=\&quot;$Height\&quot; frameborder=\&quot;0\&quot; scrolling=\&quot;no\&quot; allowfullscreen&gt;&lt;/iframe&gt;&quot;}},&quot;dataVersion&quot;:&quot;1.0&quot;,&quot;properties&quot;:{&quot;embedCode&quot;:&quot;&lt;iframe id=\&quot;roadmap-visualization-$visualizationId\&quot; src=\&quot;$visualizationUrl\&quot; width=\&quot;$Width\&quot; height=\&quot;$Height\&quot; frameborder=\&quot;0\&quot; scrolling=\&quot;no\&quot; allowfullscreen&gt;&lt;/iframe&gt;&quot;}}}"></div>

<!-- Alternative simplifiée -->
<iframe id="roadmap-visualization-$visualizationId" src="$visualizationUrl" width="$Width" height="$Height" frameborder="0" scrolling="no" allowfullscreen></iframe>
"@
        }
        "Teams" {
            $embedCode = @"
<!-- Tab personnalisé pour Microsoft Teams -->
{
    "entityId": "roadmap-visualization-$visualizationId",
    "contentUrl": "$visualizationUrl",
    "websiteUrl": "$visualizationUrl",
    "name": "Roadmap Visualization",
    "scopes": ["personal", "team"],
    "context": [{
        "name": "canvasUrl",
        "value": "$visualizationUrl"
    }]
}

<!-- Instructions d'intégration -->
1. Dans Teams, accédez au canal où vous souhaitez ajouter la visualisation
2. Cliquez sur le bouton "+" pour ajouter un nouvel onglet
3. Sélectionnez "Website" ou "Custom Tabs"
4. Entrez l'URL: $visualizationUrl
5. Donnez un nom à l'onglet, par exemple "Roadmap Visualization"
6. Cliquez sur "Enregistrer"
"@
        }
    }
    
    return $embedCode
}

# Fonction pour afficher l'interface utilisateur de génération de code d'intégration
function Show-EmbedUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Visualization,
        
        [Parameter(Mandatory = $true)]
        [string]$EmbedType,
        
        [Parameter(Mandatory = $true)]
        [string]$ServerUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$Width,
        
        [Parameter(Mandatory = $true)]
        [string]$Height,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoResize,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableInteractivity
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Générateur de code d'intégration"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    
    # Type d'intégration
    $embedTypeLabel = New-Object System.Windows.Forms.Label
    $embedTypeLabel.Text = "Type d'intégration:"
    $embedTypeLabel.Location = New-Object System.Drawing.Point(20, 20)
    $embedTypeLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $embedTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $embedTypeComboBox.Location = New-Object System.Drawing.Point(180, 20)
    $embedTypeComboBox.Size = New-Object System.Drawing.Size(200, 20)
    $embedTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams") | ForEach-Object {
        $embedTypeComboBox.Items.Add($_)
    }
    
    $embedTypeComboBox.SelectedItem = $EmbedType
    
    # URL du serveur
    $serverUrlLabel = New-Object System.Windows.Forms.Label
    $serverUrlLabel.Text = "URL du serveur:"
    $serverUrlLabel.Location = New-Object System.Drawing.Point(20, 60)
    $serverUrlLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $serverUrlTextBox = New-Object System.Windows.Forms.TextBox
    $serverUrlTextBox.Location = New-Object System.Drawing.Point(180, 60)
    $serverUrlTextBox.Size = New-Object System.Drawing.Size(300, 20)
    $serverUrlTextBox.Text = $ServerUrl
    
    # Largeur
    $widthLabel = New-Object System.Windows.Forms.Label
    $widthLabel.Text = "Largeur:"
    $widthLabel.Location = New-Object System.Drawing.Point(20, 100)
    $widthLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $widthTextBox = New-Object System.Windows.Forms.TextBox
    $widthTextBox.Location = New-Object System.Drawing.Point(180, 100)
    $widthTextBox.Size = New-Object System.Drawing.Size(100, 20)
    $widthTextBox.Text = $Width
    
    # Hauteur
    $heightLabel = New-Object System.Windows.Forms.Label
    $heightLabel.Text = "Hauteur:"
    $heightLabel.Location = New-Object System.Drawing.Point(300, 100)
    $heightLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $heightTextBox = New-Object System.Windows.Forms.TextBox
    $heightTextBox.Location = New-Object System.Drawing.Point(380, 100)
    $heightTextBox.Size = New-Object System.Drawing.Size(100, 20)
    $heightTextBox.Text = $Height
    
    # Redimensionnement automatique
    $autoResizeCheckBox = New-Object System.Windows.Forms.CheckBox
    $autoResizeCheckBox.Text = "Redimensionnement automatique"
    $autoResizeCheckBox.Location = New-Object System.Drawing.Point(20, 140)
    $autoResizeCheckBox.Size = New-Object System.Drawing.Size(250, 20)
    $autoResizeCheckBox.Checked = $AutoResize.IsPresent
    
    # Interactivité
    $interactivityCheckBox = New-Object System.Windows.Forms.CheckBox
    $interactivityCheckBox.Text = "Activer l'interactivité"
    $interactivityCheckBox.Location = New-Object System.Drawing.Point(300, 140)
    $interactivityCheckBox.Size = New-Object System.Drawing.Size(200, 20)
    $interactivityCheckBox.Checked = $EnableInteractivity.IsPresent
    
    # Code d'intégration
    $embedCodeLabel = New-Object System.Windows.Forms.Label
    $embedCodeLabel.Text = "Code d'intégration:"
    $embedCodeLabel.Location = New-Object System.Drawing.Point(20, 180)
    $embedCodeLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $embedCodeTextBox = New-Object System.Windows.Forms.TextBox
    $embedCodeTextBox.Location = New-Object System.Drawing.Point(20, 210)
    $embedCodeTextBox.Size = New-Object System.Drawing.Size(750, 300)
    $embedCodeTextBox.Multiline = $true
    $embedCodeTextBox.ScrollBars = "Vertical"
    $embedCodeTextBox.ReadOnly = $true
    $embedCodeTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    
    # Bouton de génération
    $generateButton = New-Object System.Windows.Forms.Button
    $generateButton.Text = "Générer"
    $generateButton.Location = New-Object System.Drawing.Point(20, 520)
    $generateButton.Size = New-Object System.Drawing.Size(100, 30)
    
    $generateButton.Add_Click({
        $embedCode = Get-EmbedCode -Visualization $Visualization -EmbedType $embedTypeComboBox.SelectedItem -ServerUrl $serverUrlTextBox.Text -Width $widthTextBox.Text -Height $heightTextBox.Text -AutoResize:$autoResizeCheckBox.Checked -EnableInteractivity:$interactivityCheckBox.Checked
        $embedCodeTextBox.Text = $embedCode
    })
    
    # Bouton de copie
    $copyButton = New-Object System.Windows.Forms.Button
    $copyButton.Text = "Copier"
    $copyButton.Location = New-Object System.Drawing.Point(130, 520)
    $copyButton.Size = New-Object System.Drawing.Size(100, 30)
    
    $copyButton.Add_Click({
        if (-not [string]::IsNullOrEmpty($embedCodeTextBox.Text)) {
            [System.Windows.Forms.Clipboard]::SetText($embedCodeTextBox.Text)
            [System.Windows.Forms.MessageBox]::Show("Code d'intégration copié dans le presse-papiers", "Copie réussie", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
    
    # Bouton de sauvegarde
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = "Enregistrer"
    $saveButton.Location = New-Object System.Drawing.Point(240, 520)
    $saveButton.Size = New-Object System.Drawing.Size(100, 30)
    
    $saveButton.Add_Click({
        if (-not [string]::IsNullOrEmpty($embedCodeTextBox.Text)) {
            $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveFileDialog.Filter = "Text files (*.txt)|*.txt|HTML files (*.html)|*.html|All files (*.*)|*.*"
            $saveFileDialog.Title = "Save embed code"
            $saveFileDialog.FileName = "embed-code-$($embedTypeComboBox.SelectedItem.ToLower()).txt"
            
            if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $embedCodeTextBox.Text | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
                [System.Windows.Forms.MessageBox]::Show("Code d'intégration enregistré dans: $($saveFileDialog.FileName)", "Enregistrement réussi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
    })
    
    # Boutons OK/Annuler
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(600, 520)
    $okButton.Size = New-Object System.Drawing.Size(75, 30)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Annuler"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(700, 520)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    
    # Ajouter les contrôles au formulaire
    $form.Controls.Add($embedTypeLabel)
    $form.Controls.Add($embedTypeComboBox)
    $form.Controls.Add($serverUrlLabel)
    $form.Controls.Add($serverUrlTextBox)
    $form.Controls.Add($widthLabel)
    $form.Controls.Add($widthTextBox)
    $form.Controls.Add($heightLabel)
    $form.Controls.Add($heightTextBox)
    $form.Controls.Add($autoResizeCheckBox)
    $form.Controls.Add($interactivityCheckBox)
    $form.Controls.Add($embedCodeLabel)
    $form.Controls.Add($embedCodeTextBox)
    $form.Controls.Add($generateButton)
    $form.Controls.Add($copyButton)
    $form.Controls.Add($saveButton)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)
    
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    
    # Générer le code d'intégration initial
    $embedCode = Get-EmbedCode -Visualization $Visualization -EmbedType $EmbedType -ServerUrl $ServerUrl -Width $Width -Height $Height -AutoResize:$AutoResize -EnableInteractivity:$EnableInteractivity
    $embedCodeTextBox.Text = $embedCode
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            EmbedType = $embedTypeComboBox.SelectedItem
            ServerUrl = $serverUrlTextBox.Text
            Width = $widthTextBox.Text
            Height = $heightTextBox.Text
            AutoResize = $autoResizeCheckBox.Checked
            EnableInteractivity = $interactivityCheckBox.Checked
            EmbedCode = $embedCodeTextBox.Text
        }
    } else {
        return $null
    }
}

# Fonction principale pour exporter le code d'intégration
function Export-VisualizationEmbed {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VisualizationPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams")]
        [string]$EmbedType = "Iframe",
        
        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:8080",
        
        [Parameter(Mandatory = $false)]
        [string]$Width = "100%",
        
        [Parameter(Mandatory = $false)]
        [string]$Height = "600px",
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoResize,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableInteractivity
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
    
    # Afficher l'interface utilisateur de génération de code d'intégration
    $embedResult = Show-EmbedUI -Visualization $visualization -EmbedType $EmbedType -ServerUrl $ServerUrl -Width $Width -Height $Height -AutoResize:$AutoResize -EnableInteractivity:$EnableInteractivity
    
    if ($null -eq $embedResult) {
        Write-Log "Embed code generation cancelled by user" -Level "Info"
        return $false
    }
    
    # Sauvegarder le code d'intégration si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $embedResult.EmbedCode | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Embed code saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving embed code: $_" -Level "Error"
            return $false
        }
    }
    
    return $embedResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Export-VisualizationEmbed -VisualizationPath $VisualizationPath -OutputPath $OutputPath -EmbedType $EmbedType -ServerUrl $ServerUrl -Width $Width -Height $Height -AutoResize:$AutoResize -EnableInteractivity:$EnableInteractivity
}
