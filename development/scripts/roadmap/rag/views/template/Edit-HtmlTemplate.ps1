# Edit-HtmlTemplate.ps1
# Script pour l'éditeur de template HTML
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TemplatePath,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateContent,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "GUI", "VSCode")]
    [string]$EditorMode = "GUI",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSyntaxHighlighting,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnablePreview,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableComponentInsertion,
    
    [Parameter(Mandatory = $false)]
    [string]$ComponentsPath,
    
    [Parameter(Mandatory = $false)]
    [string]$VariablesPath,
    
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

# Définir les variables disponibles par défaut
$defaultVariables = @{
    "date" = { Get-Date -Format "yyyy-MM-dd" }
    "time" = { Get-Date -Format "HH:mm:ss" }
    "datetime" = { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
    "year" = { Get-Date -Format "yyyy" }
    "month" = { Get-Date -Format "MM" }
    "day" = { Get-Date -Format "dd" }
    "username" = { $env:USERNAME }
    "computername" = { $env:COMPUTERNAME }
    "random_id" = { [Guid]::NewGuid().ToString() }
    "random_number" = { Get-Random -Minimum 1000 -Maximum 9999 }
}

# Fonction pour charger un template
function Get-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplateContent
    )
    
    if (-not [string]::IsNullOrEmpty($TemplateContent)) {
        return $TemplateContent
    }
    
    if (-not [string]::IsNullOrEmpty($TemplatePath) -and (Test-Path -Path $TemplatePath)) {
        try {
            $content = Get-Content -Path $TemplatePath -Raw
            return $content
        } catch {
            Write-Log "Error loading template from file: $_" -Level "Error"
            return $null
        }
    }
    
    # Template HTML par défaut si aucun n'est spécifié
    return @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
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
        .task {
            border: 1px solid #ddd;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
        }
        .task-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .task-title {
            font-weight: bold;
            font-size: 1.2em;
        }
        .task-id {
            color: #7f8c8d;
            font-size: 0.9em;
        }
        .task-details {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 10px;
        }
        .task-detail {
            display: flex;
            flex-direction: column;
        }
        .detail-label {
            font-size: 0.8em;
            color: #7f8c8d;
        }
        .detail-value {
            font-weight: bold;
        }
        .status-todo { color: #f39c12; }
        .status-in_progress { color: #3498db; }
        .status-done { color: #27ae60; }
        .status-blocked { color: #e74c3c; }
        .priority-high { color: #e74c3c; }
        .priority-medium { color: #f39c12; }
        .priority-low { color: #27ae60; }
        .footer {
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #ddd;
            font-size: 0.8em;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>{{title}}</h1>
        
        <div class="description">
            <p>{{description}}</p>
        </div>
        
        <h2>Tâches</h2>
        
        <div class="tasks">
            {{#each tasks}}
            <div class="task">
                <div class="task-header">
                    <div class="task-title">{{title}}</div>
                    <div class="task-id">{{id}}</div>
                </div>
                <div class="task-details">
                    <div class="task-detail">
                        <span class="detail-label">Statut</span>
                        <span class="detail-value status-{{status}}">{{status}}</span>
                    </div>
                    <div class="task-detail">
                        <span class="detail-label">Priorité</span>
                        <span class="detail-value priority-{{priority}}">{{priority}}</span>
                    </div>
                    {{#if assignee}}
                    <div class="task-detail">
                        <span class="detail-label">Assigné à</span>
                        <span class="detail-value">{{assignee}}</span>
                    </div>
                    {{/if}}
                    {{#if due_date}}
                    <div class="task-detail">
                        <span class="detail-label">Échéance</span>
                        <span class="detail-value">{{due_date}}</span>
                    </div>
                    {{/if}}
                </div>
                {{#if description}}
                <div class="task-description">
                    <p>{{description}}</p>
                </div>
                {{/if}}
            </div>
            {{/each}}
        </div>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p>Total des tâches: {{tasks.length}}</p>
            <p>Tâches à faire: {{tasks_todo}}</p>
            <p>Tâches en cours: {{tasks_in_progress}}</p>
            <p>Tâches terminées: {{tasks_done}}</p>
        </div>
        
        <div class="notes">
            <h2>Notes</h2>
            <p>{{notes}}</p>
        </div>
        
        <div class="footer">
            <p>Généré le {{date}} à {{time}} par {{username}}</p>
        </div>
    </div>
</body>
</html>
"@
}

# Fonction pour charger les variables
function Get-Variables {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VariablesPath
    )
    
    $variables = $defaultVariables.Clone()
    
    if (-not [string]::IsNullOrEmpty($VariablesPath) -and (Test-Path -Path $VariablesPath)) {
        try {
            $customVariables = Get-Content -Path $VariablesPath -Raw | ConvertFrom-Json
            
            foreach ($key in $customVariables.PSObject.Properties.Name) {
                $value = $customVariables.$key
                
                # Si la valeur est une chaîne, la stocker directement
                # Sinon, créer un scriptblock qui retourne la valeur
                if ($value -is [string]) {
                    $variables[$key] = $value
                } else {
                    $variables[$key] = { return $value }
                }
            }
        } catch {
            Write-Log "Error loading variables from file: $_" -Level "Error"
        }
    }
    
    return $variables
}

# Fonction pour charger les composants HTML
function Get-HtmlComponents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComponentsPath
    )
    
    $defaultComponentsPath = Join-Path -Path $scriptPath -ChildPath "components"
    $componentsPath = if ($ComponentsPath) { $ComponentsPath } else { $defaultComponentsPath }
    
    $components = @{}
    
    # Composants par défaut
    $components["table"] = @"
<table class="task-table">
    <thead>
        <tr>
            <th>ID</th>
            <th>Titre</th>
            <th>Statut</th>
            <th>Priorité</th>
            <th>Assigné à</th>
            <th>Échéance</th>
        </tr>
    </thead>
    <tbody>
        {{#each tasks}}
        <tr>
            <td>{{id}}</td>
            <td>{{title}}</td>
            <td class="status-{{status}}">{{status}}</td>
            <td class="priority-{{priority}}">{{priority}}</td>
            <td>{{assignee}}</td>
            <td>{{due_date}}</td>
        </tr>
        {{/each}}
    </tbody>
</table>
"@
    
    $components["card"] = @"
<div class="card">
    <div class="card-header">
        <h3>{{title}}</h3>
    </div>
    <div class="card-body">
        <p>{{content}}</p>
    </div>
    <div class="card-footer">
        <p>{{footer}}</p>
    </div>
</div>
"@
    
    $components["progress-bar"] = @"
<div class="progress-container">
    <div class="progress-label">{{label}}</div>
    <div class="progress-bar">
        <div class="progress-value" style="width: {{value}}%"></div>
    </div>
    <div class="progress-text">{{value}}%</div>
</div>
"@
    
    $components["chart"] = @"
<div class="chart-container">
    <canvas id="{{id}}" width="400" height="200"></canvas>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            var ctx = document.getElementById('{{id}}').getContext('2d');
            var chart = new Chart(ctx, {
                type: '{{type}}',
                data: {
                    labels: {{labels}},
                    datasets: [{
                        label: '{{label}}',
                        data: {{data}},
                        backgroundColor: {{colors}},
                        borderColor: {{border_colors}},
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });
        });
    </script>
</div>
"@
    
    # Charger les composants personnalisés si le répertoire existe
    if (Test-Path -Path $componentsPath) {
        $componentFiles = Get-ChildItem -Path $componentsPath -Filter "*.html"
        
        foreach ($file in $componentFiles) {
            try {
                $componentName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                $componentContent = Get-Content -Path $file.FullName -Raw
                $components[$componentName] = $componentContent
            } catch {
                Write-Log "Error loading component $($file.Name): $_" -Level "Error"
            }
        }
    }
    
    return $components
}

# Fonction pour remplacer les variables dans un template
function Expand-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$CustomValues = @{}
    )
    
    $result = $Template
    
    # Remplacer les variables personnalisées
    foreach ($key in $CustomValues.Keys) {
        $value = $CustomValues[$key]
        $result = $result -replace "\{\{$key\}\}", $value
    }
    
    # Remplacer les variables prédéfinies
    foreach ($key in $Variables.Keys) {
        $value = $Variables[$key]
        
        # Si la valeur est un scriptblock, l'exécuter pour obtenir la valeur réelle
        if ($value -is [scriptblock]) {
            $value = & $value
        }
        
        $result = $result -replace "\{\{$key\}\}", $value
    }
    
    # Remplacer les variables non définies par des placeholders vides
    $result = $result -replace "\{\{[^\}]+\}\}", ""
    
    return $result
}

# Fonction pour l'éditeur en mode GUI (Windows Forms)
function Start-GUIEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Components,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePreview,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableComponentInsertion
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "HTML Template Editor"
    $form.Size = New-Object System.Drawing.Size(1200, 800)
    $form.StartPosition = "CenterScreen"
    
    $splitContainer = New-Object System.Windows.Forms.SplitContainer
    $splitContainer.Dock = "Fill"
    $splitContainer.Orientation = "Vertical"
    $splitContainer.SplitterDistance = 500
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ScrollBars = "Both"
    $textBox.Dock = "Fill"
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 12)
    $textBox.Text = $Template
    $textBox.AcceptsTab = $true
    $textBox.WordWrap = $false
    
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
        $preview = Expand-Template -Template $textBox.Text -Variables $Variables
        $browser.DocumentText = $preview
    })
    
    $componentsListBox = New-Object System.Windows.Forms.ListBox
    $componentsListBox.Location = New-Object System.Drawing.Point(10, 10)
    $componentsListBox.Size = New-Object System.Drawing.Size(200, 23)
    $componentsListBox.Height = 100
    
    foreach ($key in ($Components.Keys | Sort-Object)) {
        $componentsListBox.Items.Add($key)
    }
    
    $insertComponentButton = New-Object System.Windows.Forms.Button
    $insertComponentButton.Text = "Insert Component"
    $insertComponentButton.Location = New-Object System.Drawing.Point(220, 10)
    $insertComponentButton.Size = New-Object System.Drawing.Size(120, 23)
    $insertComponentButton.Add_Click({
        if ($componentsListBox.SelectedItem) {
            $componentName = $componentsListBox.SelectedItem
            $componentContent = $Components[$componentName]
            $textBox.SelectedText = $componentContent
        }
    })
    
    $variablesListBox = New-Object System.Windows.Forms.ListBox
    $variablesListBox.Location = New-Object System.Drawing.Point(350, 10)
    $variablesListBox.Size = New-Object System.Drawing.Size(200, 23)
    $variablesListBox.Height = 100
    
    foreach ($key in ($Variables.Keys | Sort-Object)) {
        $variablesListBox.Items.Add("{{$key}}")
    }
    
    $insertVariableButton = New-Object System.Windows.Forms.Button
    $insertVariableButton.Text = "Insert Variable"
    $insertVariableButton.Location = New-Object System.Drawing.Point(560, 10)
    $insertVariableButton.Size = New-Object System.Drawing.Size(100, 23)
    $insertVariableButton.Add_Click({
        if ($variablesListBox.SelectedItem) {
            $textBox.SelectedText = $variablesListBox.SelectedItem
        }
    })
    
    $buttonPanel.Controls.Add($okButton)
    $buttonPanel.Controls.Add($cancelButton)
    $buttonPanel.Controls.Add($previewButton)
    
    if ($EnableComponentInsertion) {
        $buttonPanel.Controls.Add($componentsListBox)
        $buttonPanel.Controls.Add($insertComponentButton)
        $buttonPanel.Controls.Add($variablesListBox)
        $buttonPanel.Controls.Add($insertVariableButton)
        $buttonPanel.Height = 120
    }
    
    $splitContainer.Panel1.Controls.Add($textBox)
    
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
        return $textBox.Text
    } else {
        return $null
    }
}

# Fonction pour l'éditeur en mode VSCode
function Start-VSCodeEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath
    )
    
    # Créer un fichier temporaire si aucun chemin n'est spécifié
    $tempFile = $false
    $filePath = $TemplatePath
    
    if ([string]::IsNullOrEmpty($filePath)) {
        $filePath = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.html'
        $tempFile = $true
    }
    
    # Écrire le template dans le fichier
    $Template | Out-File -FilePath $filePath -Encoding UTF8
    
    # Ouvrir le fichier dans VSCode
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    
    if (-not $vscodePath) {
        Write-Log "VSCode not found in PATH. Falling back to GUI editor." -Level "Warning"
        return Start-GUIEditor -Template $Template -Variables (Get-Variables) -Components (Get-HtmlComponents) -EnablePreview:$EnablePreview -EnableComponentInsertion:$EnableComponentInsertion
    }
    
    # Lancer VSCode et attendre que l'utilisateur ferme le fichier
    Start-Process -FilePath $vscodePath -ArgumentList "`"$filePath`" --wait" -Wait
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $filePath -Raw
    
    # Supprimer le fichier temporaire si nécessaire
    if ($tempFile) {
        Remove-Item -Path $filePath -Force
    }
    
    return $content
}

# Fonction principale
function Edit-HtmlTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "GUI", "VSCode")]
        [string]$EditorMode = "GUI",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSyntaxHighlighting,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePreview,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableComponentInsertion,
        
        [Parameter(Mandatory = $false)]
        [string]$ComponentsPath,
        
        [Parameter(Mandatory = $false)]
        [string]$VariablesPath
    )
    
    # Charger le template
    $template = Get-Template -TemplatePath $TemplatePath -TemplateContent $TemplateContent
    
    if ($null -eq $template) {
        Write-Log "Failed to load template" -Level "Error"
        return $null
    }
    
    # Charger les variables
    $variables = Get-Variables -VariablesPath $VariablesPath
    
    # Charger les composants
    $components = Get-HtmlComponents -ComponentsPath $ComponentsPath
    
    # Ouvrir l'éditeur approprié
    $editedTemplate = $null
    
    switch ($EditorMode) {
        "GUI" {
            $editedTemplate = Start-GUIEditor -Template $template -Variables $variables -Components $components -EnablePreview:$EnablePreview -EnableComponentInsertion:$EnableComponentInsertion
        }
        "VSCode" {
            $editedTemplate = Start-VSCodeEditor -Template $template -TemplatePath $TemplatePath
        }
        "Console" {
            Write-Log "Console mode not supported for HTML editing. Falling back to GUI mode." -Level "Warning"
            $editedTemplate = Start-GUIEditor -Template $template -Variables $variables -Components $components -EnablePreview:$EnablePreview -EnableComponentInsertion:$EnableComponentInsertion
        }
    }
    
    # Si l'utilisateur a annulé, sortir
    if ($null -eq $editedTemplate) {
        Write-Log "Template editing cancelled by user" -Level "Info"
        return $null
    }
    
    # Sauvegarder le template si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $editedTemplate | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Template saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving template: $_" -Level "Error"
        }
    }
    
    return $editedTemplate
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Edit-HtmlTemplate -TemplatePath $TemplatePath -TemplateContent $TemplateContent -OutputPath $OutputPath -EditorMode $EditorMode -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnablePreview:$EnablePreview -EnableComponentInsertion:$EnableComponentInsertion -ComponentsPath $ComponentsPath -VariablesPath $VariablesPath
}
