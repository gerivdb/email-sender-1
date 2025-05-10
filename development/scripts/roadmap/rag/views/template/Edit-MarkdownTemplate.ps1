# Edit-MarkdownTemplate.ps1
# Script pour l'éditeur de template markdown
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
    [string]$EditorMode = "Console",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSyntaxHighlighting,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnablePreview,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableVariableInsertion,
    
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
    
    # Template par défaut si aucun n'est spécifié
    return @"
# {{title}}

## Description
{{description}}

## Détails
- Date: {{date}}
- Auteur: {{username}}
- ID: {{random_id}}

## Tâches
{{tasks}}

## Notes
{{notes}}
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

# Fonction pour la coloration syntaxique du markdown
function Get-SyntaxHighlightedMarkdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Markdown
    )
    
    $lines = $Markdown -split "`n"
    $result = ""
    
    foreach ($line in $lines) {
        # Titres
        if ($line -match "^(#{1,6})\s+(.+)$") {
            $level = $matches[1].Length
            $title = $matches[2]
            Write-Host "$($matches[1]) " -NoNewline -ForegroundColor Cyan
            Write-Host "$title" -ForegroundColor White
        }
        # Listes à puces
        elseif ($line -match "^(\s*[-*+])\s+(.+)$") {
            $bullet = $matches[1]
            $text = $matches[2]
            Write-Host "$bullet " -NoNewline -ForegroundColor Yellow
            Write-Host "$text" -ForegroundColor White
        }
        # Listes numérotées
        elseif ($line -match "^(\s*\d+\.)\s+(.+)$") {
            $number = $matches[1]
            $text = $matches[2]
            Write-Host "$number " -NoNewline -ForegroundColor Yellow
            Write-Host "$text" -ForegroundColor White
        }
        # Variables
        elseif ($line -match "(\{\{[^\}]+\}\})") {
            $parts = [regex]::Split($line, "(\{\{[^\}]+\}\})")
            foreach ($part in $parts) {
                if ($part -match "^\{\{([^\}]+)\}\}$") {
                    Write-Host $part -NoNewline -ForegroundColor Magenta
                } else {
                    Write-Host $part -NoNewline -ForegroundColor White
                }
            }
            Write-Host ""
        }
        # Texte normal
        else {
            Write-Host $line -ForegroundColor White
        }
    }
}

# Fonction pour l'éditeur en mode console
function Start-ConsoleEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSyntaxHighlighting,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePreview,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableVariableInsertion
    )
    
    $content = $Template
    $customValues = @{}
    $cursorPosition = $content.Length
    $insertMode = $true
    
    Write-Host "Template Editor (Press F1 for help, F5 for preview, Esc to cancel, Ctrl+S to save)" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor Cyan
    
    if ($EnableSyntaxHighlighting) {
        Get-SyntaxHighlightedMarkdown -Markdown $content
    } else {
        Write-Host $content
    }
    
    $continue = $true
    
    while ($continue) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            27 { # Escape
                $result = Read-Host "Do you want to discard changes? (y/n)"
                if ($result -eq "y") {
                    $content = $null
                    $continue = $false
                }
            }
            112 { # F1 (Help)
                Write-Host "`nHelp:" -ForegroundColor Cyan
                Write-Host "  F1: Show this help"
                Write-Host "  F5: Preview template with variables expanded"
                Write-Host "  F8: Insert variable placeholder"
                Write-Host "  Esc: Cancel editing"
                Write-Host "  Ctrl+S: Save and exit"
                Write-Host "  Insert: Toggle insert/overwrite mode"
                Write-Host ""
                if ($EnableSyntaxHighlighting) {
                    Get-SyntaxHighlightedMarkdown -Markdown $content
                } else {
                    Write-Host $content
                }
            }
            116 { # F5 (Preview)
                if ($EnablePreview) {
                    Write-Host "`nPreview:" -ForegroundColor Cyan
                    $preview = Expand-Template -Template $content -Variables $Variables -CustomValues $customValues
                    Write-Host $preview
                    Write-Host "`nPress any key to continue editing..." -ForegroundColor Cyan
                    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    
                    if ($EnableSyntaxHighlighting) {
                        Get-SyntaxHighlightedMarkdown -Markdown $content
                    } else {
                        Write-Host $content
                    }
                }
            }
            119 { # F8 (Insert Variable)
                if ($EnableVariableInsertion) {
                    Write-Host "`nAvailable Variables:" -ForegroundColor Cyan
                    $variableList = $Variables.Keys | Sort-Object
                    foreach ($var in $variableList) {
                        Write-Host "  {{$var}}"
                    }
                    
                    $varName = Read-Host "Enter variable name (without {{ }})"
                    if (-not [string]::IsNullOrWhiteSpace($varName)) {
                        $placeholder = "{{$varName}}"
                        $content = $content.Substring(0, $cursorPosition) + $placeholder + $content.Substring($cursorPosition)
                        $cursorPosition += $placeholder.Length
                        
                        if ($EnableSyntaxHighlighting) {
                            Get-SyntaxHighlightedMarkdown -Markdown $content
                        } else {
                            Write-Host $content
                        }
                    }
                }
            }
            19 { # Ctrl+S (Save)
                $continue = $false
            }
            45 { # Insert (Toggle mode)
                $insertMode = -not $insertMode
                Write-Host "`nMode: " -NoNewline -ForegroundColor Cyan
                Write-Host $(if ($insertMode) { "Insert" } else { "Overwrite" }) -ForegroundColor Yellow
            }
            8 { # Backspace
                if ($cursorPosition -gt 0) {
                    $content = $content.Substring(0, $cursorPosition - 1) + $content.Substring($cursorPosition)
                    $cursorPosition--
                    
                    if ($EnableSyntaxHighlighting) {
                        Get-SyntaxHighlightedMarkdown -Markdown $content
                    } else {
                        Write-Host $content
                    }
                }
            }
            default {
                # Ajouter le caractère à la position du curseur
                if ($key.Character -ge 32 -and $key.Character -le 126) {
                    if ($insertMode) {
                        $content = $content.Substring(0, $cursorPosition) + $key.Character + $content.Substring($cursorPosition)
                    } else {
                        if ($cursorPosition -lt $content.Length) {
                            $content = $content.Substring(0, $cursorPosition) + $key.Character + $content.Substring($cursorPosition + 1)
                        } else {
                            $content = $content + $key.Character
                        }
                    }
                    $cursorPosition++
                    
                    if ($EnableSyntaxHighlighting) {
                        Get-SyntaxHighlightedMarkdown -Markdown $content
                    } else {
                        Write-Host $content
                    }
                }
            }
        }
    }
    
    return $content
}

# Fonction pour l'éditeur en mode GUI (Windows Forms)
function Start-GUIEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePreview,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableVariableInsertion
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Markdown Template Editor"
    $form.Size = New-Object System.Drawing.Size(1000, 700)
    $form.StartPosition = "CenterScreen"
    
    $splitContainer = New-Object System.Windows.Forms.SplitContainer
    $splitContainer.Dock = "Fill"
    $splitContainer.Orientation = "Vertical"
    $splitContainer.SplitterDistance = 400
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ScrollBars = "Vertical"
    $textBox.Dock = "Fill"
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 12)
    $textBox.Text = $Template
    $textBox.AcceptsTab = $true
    
    $previewBox = New-Object System.Windows.Forms.RichTextBox
    $previewBox.ReadOnly = $true
    $previewBox.Dock = "Fill"
    $previewBox.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Dock = "Bottom"
    $buttonPanel.Height = 40
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Save"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(820, 10)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(900, 10)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    
    $previewButton = New-Object System.Windows.Forms.Button
    $previewButton.Text = "Preview"
    $previewButton.Location = New-Object System.Drawing.Point(740, 10)
    $previewButton.Size = New-Object System.Drawing.Size(75, 23)
    $previewButton.Add_Click({
        $preview = Expand-Template -Template $textBox.Text -Variables $Variables
        $previewBox.Text = $preview
    })
    
    $variablesListBox = New-Object System.Windows.Forms.ListBox
    $variablesListBox.Location = New-Object System.Drawing.Point(10, 10)
    $variablesListBox.Size = New-Object System.Drawing.Size(200, 23)
    $variablesListBox.Height = 100
    
    foreach ($key in ($Variables.Keys | Sort-Object)) {
        $variablesListBox.Items.Add("{{$key}}")
    }
    
    $insertVariableButton = New-Object System.Windows.Forms.Button
    $insertVariableButton.Text = "Insert Variable"
    $insertVariableButton.Location = New-Object System.Drawing.Point(220, 10)
    $insertVariableButton.Size = New-Object System.Drawing.Size(100, 23)
    $insertVariableButton.Add_Click({
        if ($variablesListBox.SelectedItem) {
            $textBox.SelectedText = $variablesListBox.SelectedItem
        }
    })
    
    $buttonPanel.Controls.Add($okButton)
    $buttonPanel.Controls.Add($cancelButton)
    $buttonPanel.Controls.Add($previewButton)
    
    if ($EnableVariableInsertion) {
        $buttonPanel.Controls.Add($variablesListBox)
        $buttonPanel.Controls.Add($insertVariableButton)
        $buttonPanel.Height = 120
    }
    
    $splitContainer.Panel1.Controls.Add($textBox)
    
    if ($EnablePreview) {
        $splitContainer.Panel2.Controls.Add($previewBox)
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
        $filePath = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.md'
        $tempFile = $true
    }
    
    # Écrire le template dans le fichier
    $Template | Out-File -FilePath $filePath -Encoding UTF8
    
    # Ouvrir le fichier dans VSCode
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    
    if (-not $vscodePath) {
        Write-Log "VSCode not found in PATH. Falling back to console editor." -Level "Warning"
        return Start-ConsoleEditor -Template $Template -Variables (Get-Variables) -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnablePreview:$EnablePreview -EnableVariableInsertion:$EnableVariableInsertion
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
function Edit-MarkdownTemplate {
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
        [string]$EditorMode = "Console",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSyntaxHighlighting,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePreview,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableVariableInsertion,
        
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
    
    # Ouvrir l'éditeur approprié
    $editedTemplate = $null
    
    switch ($EditorMode) {
        "Console" {
            $editedTemplate = Start-ConsoleEditor -Template $template -Variables $variables -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnablePreview:$EnablePreview -EnableVariableInsertion:$EnableVariableInsertion
        }
        "GUI" {
            $editedTemplate = Start-GUIEditor -Template $template -Variables $variables -EnablePreview:$EnablePreview -EnableVariableInsertion:$EnableVariableInsertion
        }
        "VSCode" {
            $editedTemplate = Start-VSCodeEditor -Template $template -TemplatePath $TemplatePath
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
    Edit-MarkdownTemplate -TemplatePath $TemplatePath -TemplateContent $TemplateContent -OutputPath $OutputPath -EditorMode $EditorMode -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnablePreview:$EnablePreview -EnableVariableInsertion:$EnableVariableInsertion -VariablesPath $VariablesPath
}
