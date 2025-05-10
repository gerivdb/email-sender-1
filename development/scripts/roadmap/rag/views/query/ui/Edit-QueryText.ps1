# Edit-QueryText.ps1
# Script pour l'éditeur de requête en mode texte
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InitialQuery = "",
    
    [Parameter(Mandatory = $false)]
    [string]$HistoryFilePath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "GUI", "VSCode")]
    [string]$EditorMode = "Console",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSyntaxHighlighting,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableAutoCompletion,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableValidation,
    
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

# Importer le parser
$parserPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "parser\Parse-QueryLanguage.ps1"
if (-not (Test-Path -Path $parserPath)) {
    Write-Log "Parser script not found at: $parserPath" -Level "Error"
    exit 1
}

. $parserPath

# Définir les couleurs pour la coloration syntaxique
$syntaxColors = @{
    "Field" = "Cyan"
    "Operator" = "Yellow"
    "Value" = "Green"
    "LogicalOperator" = "Magenta"
    "Parenthesis" = "White"
    "Error" = "Red"
}

# Définir les mots-clés pour l'autocomplétion
$autoCompleteKeywords = @{
    "LogicalOperators" = @("AND", "OR", "NOT")
    "Fields" = @("status", "priority", "category", "title", "description", "assignee", "due_date", "created_at", "updated_at", "tags")
    "Operators" = @(":", "=", "!=", "<>", ">", "<", ">=", "<=", "~", "^", "$")
    "CommonValues" = @{
        "status" = @("todo", "in_progress", "done", "blocked")
        "priority" = @("high", "medium", "low")
        "category" = @("development", "documentation", "testing", "design")
    }
}

# Fonction pour charger l'historique des requêtes
function Get-QueryHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HistoryFilePath
    )
    
    if (-not (Test-Path -Path $HistoryFilePath)) {
        Write-Log "History file not found, creating new one at: $HistoryFilePath" -Level "Info"
        New-Item -Path $HistoryFilePath -ItemType File -Force | Out-Null
        return @()
    }
    
    try {
        $history = Get-Content -Path $HistoryFilePath -ErrorAction Stop
        return $history
    } catch {
        Write-Log "Error loading query history: $_" -Level "Error"
        return @()
    }
}

# Fonction pour ajouter une requête à l'historique
function Add-QueryToHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $true)]
        [string]$HistoryFilePath,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxHistorySize = 100
    )
    
    if ([string]::IsNullOrWhiteSpace($Query)) {
        return
    }
    
    try {
        $history = Get-QueryHistory -HistoryFilePath $HistoryFilePath
        
        # Supprimer les doublons
        if ($history -contains $Query) {
            $history = $history | Where-Object { $_ -ne $Query }
        }
        
        # Ajouter la nouvelle requête au début
        $history = @($Query) + $history
        
        # Limiter la taille de l'historique
        if ($history.Count -gt $MaxHistorySize) {
            $history = $history[0..($MaxHistorySize - 1)]
        }
        
        # Enregistrer l'historique
        $history | Out-File -FilePath $HistoryFilePath -Force
        
        Write-Log "Query added to history: $Query" -Level "Debug"
    } catch {
        Write-Log "Error adding query to history: $_" -Level "Error"
    }
}

# Fonction pour la coloration syntaxique
function Get-SyntaxHighlightedQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    try {
        # Tokeniser la requête
        $tokens = Parse-Query -QueryString $Query -ReturnTokens
        
        # Trier les tokens par position
        $sortedTokens = $tokens | Sort-Object -Property Position
        
        # Construire la chaîne colorée
        $result = ""
        $position = 0
        
        foreach ($token in $sortedTokens) {
            # Ajouter les caractères entre les tokens
            if ($token.Position -gt $position) {
                $result += $Query.Substring($position, $token.Position - $position)
            }
            
            # Ajouter le token coloré
            $color = $syntaxColors[$token.Type.ToString()]
            $tokenValue = $token.Value
            
            if ($token.Type -eq [TokenType]::Operator -or $token.Type -eq [TokenType]::LogicalOperator) {
                Write-Host -NoNewline $tokenValue -ForegroundColor $color
            } elseif ($token.Type -eq [TokenType]::Field) {
                Write-Host -NoNewline $tokenValue -ForegroundColor $color
            } elseif ($token.Type -eq [TokenType]::Value) {
                Write-Host -NoNewline $tokenValue -ForegroundColor $color
            } else {
                Write-Host -NoNewline $tokenValue -ForegroundColor $color
            }
            
            # Mettre à jour la position
            $position = $token.Position + $tokenValue.Length
        }
        
        # Ajouter les caractères restants
        if ($position -lt $Query.Length) {
            Write-Host -NoNewline $Query.Substring($position)
        }
        
        Write-Host ""
    } catch {
        Write-Host $Query
        Write-Log "Error highlighting query: $_" -Level "Debug"
    }
}

# Fonction pour valider la requête
function Test-QuerySyntax {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    try {
        # Analyser la requête
        $parseResult = Parse-Query -QueryString $Query
        return $true
    } catch {
        return $false
    }
}

# Fonction pour obtenir des suggestions d'autocomplétion
function Get-QueryCompletions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PartialQuery,
        
        [Parameter(Mandatory = $true)]
        [int]$CursorPosition
    )
    
    # Extraire le texte jusqu'à la position du curseur
    $textBeforeCursor = $PartialQuery.Substring(0, $CursorPosition)
    
    # Déterminer le contexte d'autocomplétion
    $suggestions = @()
    
    # Vérifier si nous sommes après un opérateur de comparaison
    if ($textBeforeCursor -match '(status|priority|category)[\s]*[:=][\s]*$') {
        $field = $matches[1]
        $suggestions = $autoCompleteKeywords.CommonValues[$field]
    }
    # Vérifier si nous sommes au début d'un champ
    elseif ($textBeforeCursor -match '(^|\s+|\()([a-zA-Z]*)$') {
        $partialField = $matches[2]
        $suggestions = $autoCompleteKeywords.Fields | Where-Object { $_ -like "$partialField*" }
    }
    # Vérifier si nous sommes après un espace (potentiellement un opérateur logique)
    elseif ($textBeforeCursor -match '\s+([A-Z]*)$') {
        $partialOperator = $matches[1]
        $suggestions = $autoCompleteKeywords.LogicalOperators | Where-Object { $_ -like "$partialOperator*" }
    }
    
    return $suggestions
}

# Fonction pour l'éditeur en mode console
function Start-ConsoleEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InitialQuery = "",
        
        [Parameter(Mandatory = $false)]
        [string]$HistoryFilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSyntaxHighlighting,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAutoCompletion,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableValidation
    )
    
    $query = $InitialQuery
    $history = @()
    $historyIndex = -1
    $cursorPosition = $query.Length
    
    if ($HistoryFilePath) {
        $history = Get-QueryHistory -HistoryFilePath $HistoryFilePath
    }
    
    Write-Host "Query Editor (Press Enter to submit, Esc to cancel, F1 for help)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    
    if ($EnableSyntaxHighlighting) {
        Get-SyntaxHighlightedQuery -Query $query
    } else {
        Write-Host $query
    }
    
    $continue = $true
    
    while ($continue) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            13 { # Enter
                $continue = $false
                Write-Host ""
            }
            27 { # Escape
                $query = ""
                $continue = $false
                Write-Host ""
            }
            112 { # F1
                Write-Host "`nHelp:" -ForegroundColor Cyan
                Write-Host "  Enter: Submit query"
                Write-Host "  Escape: Cancel"
                Write-Host "  Up/Down: Navigate history"
                Write-Host "  Tab: Autocomplete"
                Write-Host "  F1: Show this help"
                Write-Host "  F5: Validate query"
                Write-Host ""
                if ($EnableSyntaxHighlighting) {
                    Get-SyntaxHighlightedQuery -Query $query
                } else {
                    Write-Host $query
                }
            }
            116 { # F5
                if ($EnableValidation) {
                    Write-Host ""
                    $isValid = Test-QuerySyntax -Query $query
                    if ($isValid) {
                        Write-Host "Query syntax is valid." -ForegroundColor Green
                    } else {
                        Write-Host "Query syntax is invalid." -ForegroundColor Red
                    }
                    Write-Host ""
                    if ($EnableSyntaxHighlighting) {
                        Get-SyntaxHighlightedQuery -Query $query
                    } else {
                        Write-Host $query
                    }
                }
            }
            38 { # Up arrow
                if ($history.Count -gt 0 -and $historyIndex -lt ($history.Count - 1)) {
                    $historyIndex++
                    $query = $history[$historyIndex]
                    $cursorPosition = $query.Length
                    Write-Host "`r" + (" " * 100) + "`r" -NoNewline
                    if ($EnableSyntaxHighlighting) {
                        Get-SyntaxHighlightedQuery -Query $query
                    } else {
                        Write-Host $query
                    }
                }
            }
            40 { # Down arrow
                if ($historyIndex -gt 0) {
                    $historyIndex--
                    $query = $history[$historyIndex]
                } elseif ($historyIndex -eq 0) {
                    $historyIndex = -1
                    $query = ""
                }
                $cursorPosition = $query.Length
                Write-Host "`r" + (" " * 100) + "`r" -NoNewline
                if ($EnableSyntaxHighlighting) {
                    Get-SyntaxHighlightedQuery -Query $query
                } else {
                    Write-Host $query
                }
            }
            9 { # Tab
                if ($EnableAutoCompletion) {
                    $suggestions = Get-QueryCompletions -PartialQuery $query -CursorPosition $cursorPosition
                    if ($suggestions.Count -gt 0) {
                        # Trouver le texte à remplacer
                        $textBeforeCursor = $query.Substring(0, $cursorPosition)
                        $lastWord = ""
                        if ($textBeforeCursor -match '(^|\s+|\()([a-zA-Z]*)$') {
                            $lastWord = $matches[2]
                        } elseif ($textBeforeCursor -match '(status|priority|category)[\s]*[:=][\s]*([a-zA-Z]*)$') {
                            $lastWord = $matches[2]
                        }
                        
                        # Remplacer le dernier mot par la suggestion
                        $suggestion = $suggestions[0]
                        $query = $textBeforeCursor.Substring(0, $textBeforeCursor.Length - $lastWord.Length) + $suggestion + $query.Substring($cursorPosition)
                        $cursorPosition = $textBeforeCursor.Length - $lastWord.Length + $suggestion.Length
                        
                        Write-Host "`r" + (" " * 100) + "`r" -NoNewline
                        if ($EnableSyntaxHighlighting) {
                            Get-SyntaxHighlightedQuery -Query $query
                        } else {
                            Write-Host $query
                        }
                    }
                }
            }
            8 { # Backspace
                if ($cursorPosition -gt 0) {
                    $query = $query.Substring(0, $cursorPosition - 1) + $query.Substring($cursorPosition)
                    $cursorPosition--
                    Write-Host "`r" + (" " * 100) + "`r" -NoNewline
                    if ($EnableSyntaxHighlighting) {
                        Get-SyntaxHighlightedQuery -Query $query
                    } else {
                        Write-Host $query
                    }
                }
            }
            default {
                # Ajouter le caractère à la position du curseur
                if ($key.Character -ge 32 -and $key.Character -le 126) {
                    $query = $query.Substring(0, $cursorPosition) + $key.Character + $query.Substring($cursorPosition)
                    $cursorPosition++
                    Write-Host "`r" + (" " * 100) + "`r" -NoNewline
                    if ($EnableSyntaxHighlighting) {
                        Get-SyntaxHighlightedQuery -Query $query
                    } else {
                        Write-Host $query
                    }
                }
            }
        }
    }
    
    # Ajouter la requête à l'historique si elle n'est pas vide
    if ($HistoryFilePath -and -not [string]::IsNullOrWhiteSpace($query)) {
        Add-QueryToHistory -Query $query -HistoryFilePath $HistoryFilePath
    }
    
    return $query
}

# Fonction pour l'éditeur en mode GUI (Windows Forms)
function Start-GUIEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InitialQuery = "",
        
        [Parameter(Mandatory = $false)]
        [string]$HistoryFilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSyntaxHighlighting,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAutoCompletion,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableValidation
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Query Editor"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ScrollBars = "Vertical"
    $textBox.Dock = "Fill"
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 12)
    $textBox.Text = $InitialQuery
    
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text = "Ready"
    $statusStrip.Items.Add($statusLabel)
    
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Dock = "Bottom"
    $buttonPanel.Height = 40
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(620, 10)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(700, 10)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    
    $validateButton = New-Object System.Windows.Forms.Button
    $validateButton.Text = "Validate"
    $validateButton.Location = New-Object System.Drawing.Point(540, 10)
    $validateButton.Size = New-Object System.Drawing.Size(75, 23)
    $validateButton.Add_Click({
        if ($EnableValidation) {
            $isValid = Test-QuerySyntax -Query $textBox.Text
            if ($isValid) {
                $statusLabel.Text = "Query syntax is valid."
                $statusLabel.ForeColor = [System.Drawing.Color]::Green
            } else {
                $statusLabel.Text = "Query syntax is invalid."
                $statusLabel.ForeColor = [System.Drawing.Color]::Red
            }
        }
    })
    
    $historyComboBox = New-Object System.Windows.Forms.ComboBox
    $historyComboBox.Location = New-Object System.Drawing.Point(10, 10)
    $historyComboBox.Size = New-Object System.Drawing.Size(520, 23)
    $historyComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    if ($HistoryFilePath) {
        $history = Get-QueryHistory -HistoryFilePath $HistoryFilePath
        foreach ($item in $history) {
            $historyComboBox.Items.Add($item)
        }
    }
    
    $historyComboBox.Add_SelectedIndexChanged({
        $textBox.Text = $historyComboBox.SelectedItem
    })
    
    $buttonPanel.Controls.Add($okButton)
    $buttonPanel.Controls.Add($cancelButton)
    $buttonPanel.Controls.Add($validateButton)
    $buttonPanel.Controls.Add($historyComboBox)
    
    $form.Controls.Add($textBox)
    $form.Controls.Add($buttonPanel)
    $form.Controls.Add($statusStrip)
    
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $query = $textBox.Text
        
        # Ajouter la requête à l'historique si elle n'est pas vide
        if ($HistoryFilePath -and -not [string]::IsNullOrWhiteSpace($query)) {
            Add-QueryToHistory -Query $query -HistoryFilePath $HistoryFilePath
        }
        
        return $query
    } else {
        return ""
    }
}

# Fonction pour l'éditeur en mode VSCode
function Start-VSCodeEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InitialQuery = "",
        
        [Parameter(Mandatory = $false)]
        [string]$HistoryFilePath
    )
    
    # Créer un fichier temporaire
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.query'
    $InitialQuery | Out-File -FilePath $tempFile -Encoding UTF8
    
    # Ouvrir le fichier dans VSCode
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    
    if (-not $vscodePath) {
        Write-Log "VSCode not found in PATH. Falling back to console editor." -Level "Warning"
        return Start-ConsoleEditor -InitialQuery $InitialQuery -HistoryFilePath $HistoryFilePath -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnableAutoCompletion:$EnableAutoCompletion -EnableValidation:$EnableValidation
    }
    
    # Lancer VSCode et attendre que l'utilisateur ferme le fichier
    Start-Process -FilePath $vscodePath -ArgumentList "`"$tempFile`" --wait" -Wait
    
    # Lire le contenu du fichier
    $query = Get-Content -Path $tempFile -Raw
    
    # Supprimer le fichier temporaire
    Remove-Item -Path $tempFile -Force
    
    # Ajouter la requête à l'historique si elle n'est pas vide
    if ($HistoryFilePath -and -not [string]::IsNullOrWhiteSpace($query)) {
        Add-QueryToHistory -Query $query -HistoryFilePath $HistoryFilePath
    }
    
    return $query
}

# Fonction principale
function Edit-QueryText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InitialQuery = "",
        
        [Parameter(Mandatory = $false)]
        [string]$HistoryFilePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "GUI", "VSCode")]
        [string]$EditorMode = "Console",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSyntaxHighlighting,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAutoCompletion,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableValidation
    )
    
    # Définir le chemin par défaut pour l'historique si non spécifié
    if (-not $HistoryFilePath) {
        $HistoryFilePath = Join-Path -Path $scriptPath -ChildPath "query_history.txt"
    }
    
    # Lancer l'éditeur approprié
    switch ($EditorMode) {
        "Console" {
            return Start-ConsoleEditor -InitialQuery $InitialQuery -HistoryFilePath $HistoryFilePath -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnableAutoCompletion:$EnableAutoCompletion -EnableValidation:$EnableValidation
        }
        "GUI" {
            return Start-GUIEditor -InitialQuery $InitialQuery -HistoryFilePath $HistoryFilePath -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnableAutoCompletion:$EnableAutoCompletion -EnableValidation:$EnableValidation
        }
        "VSCode" {
            return Start-VSCodeEditor -InitialQuery $InitialQuery -HistoryFilePath $HistoryFilePath
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Edit-QueryText -InitialQuery $InitialQuery -HistoryFilePath $HistoryFilePath -EditorMode $EditorMode -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnableAutoCompletion:$EnableAutoCompletion -EnableValidation:$EnableValidation
}
