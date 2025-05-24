# Test-MarkdownTemplate.ps1
# Script pour valider les templates markdown
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TemplatePath,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateContent,
    
    [Parameter(Mandatory = $false)]
    [string]$VariablesPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Detailed", "Full")]
    [string]$ValidationLevel = "Detailed",
    
    [Parameter(Mandatory = $false)]
    [switch]$FixSuggestions,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "Object", "JSON")]
    [string]$OutputFormat = "Text",
    
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
    
    Write-Log "No template content or path provided" -Level "Error"
    return $null
}

# Fonction pour charger les variables disponibles
function Get-AvailableVariables {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VariablesPath
    )
    
    # Variables par défaut
    $defaultVariables = @(
        "title", "description", "date", "time", "datetime", "year", "month", "day",
        "username", "computername", "random_id", "random_number", "notes",
        "tasks", "tasks.length", "tasks_todo", "tasks_in_progress", "tasks_done", "tasks_blocked",
        "percentage_todo", "percentage_in_progress", "percentage_done", "percentage_blocked",
        "tasks_high", "tasks_medium", "tasks_low",
        "percentage_high", "percentage_medium", "percentage_low",
        "tasks_by_status.todo", "tasks_by_status.in_progress", "tasks_by_status.done", "tasks_by_status.blocked"
    )
    
    # Variables de tâche
    $taskVariables = @(
        "id", "title", "status", "priority", "assignee", "due_date", "description",
        "created_at", "updated_at", "tags", "parent_id", "indent_level", "has_children",
        "has_blockers", "blockers", "is_milestone", "estimated_hours", "actual_hours",
        "progress", "start_date", "end_date"
    )
    
    $variables = $defaultVariables
    
    # Ajouter les variables de tâche avec le préfixe "each."
    foreach ($var in $taskVariables) {
        $variables += "each.$var"
    }
    
    # Charger les variables personnalisées si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($VariablesPath) -and (Test-Path -Path $VariablesPath)) {
        try {
            $customVariables = Get-Content -Path $VariablesPath -Raw | ConvertFrom-Json
            
            foreach ($key in $customVariables.PSObject.Properties.Name) {
                $variables += $key
            }
        } catch {
            Write-Log "Error loading variables from file: $_" -Level "Error"
        }
    }
    
    return $variables
}

# Fonction pour effectuer une validation syntaxique de base
function Test-BasicValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template
    )
    
    $result = @{
        IsValid = $true
        Errors = @()
        Warnings = @()
        Suggestions = @()
    }
    
    # Vérifier les balises markdown de base
    if (-not ($Template -match "^#\s+")) {
        $result.Warnings += @{
            Message = "Le template ne commence pas par un titre de niveau 1 (# Titre)"
            Line = 1
            Severity = "Warning"
            Suggestion = "Ajouter un titre de niveau 1 au début du template"
        }
    }
    
    # Vérifier les liens cassés
    $linkPattern = "\[([^\]]+)\]\(([^)]+)\)"
    $matches = [regex]::Matches($Template, $linkPattern)
    
    foreach ($match in $matches) {
        $linkText = $match.Groups[1].Value
        $linkUrl = $match.Groups[2].Value
        
        if ([string]::IsNullOrWhiteSpace($linkUrl)) {
            $lineNumber = ($Template.Substring(0, $match.Index) -split "`n").Length
            
            $result.Warnings += @{
                Message = "Lien avec URL vide: [$linkText]()"
                Line = $lineNumber
                Severity = "Warning"
                Suggestion = "Ajouter une URL valide au lien"
            }
        }
    }
    
    # Vérifier les tableaux mal formés
    $tableHeaderPattern = "\|[^|]+\|[^|]+\|"
    $tableSeparatorPattern = "\|[\s-:]+\|[\s-:]+\|"
    
    if ($Template -match $tableHeaderPattern -and -not ($Template -match $tableSeparatorPattern)) {
        $lineNumber = ($Template -split "`n" | Select-String -Pattern $tableHeaderPattern).LineNumber
        
        $result.Errors += @{
            Message = "Tableau mal formé: ligne de séparation manquante après l'en-tête"
            Line = $lineNumber
            Severity = "Error"
            Suggestion = "Ajouter une ligne de séparation (ex: |---|---|) après l'en-tête du tableau"
        }
        
        $result.IsValid = $false
    }
    
    return $result
}

# Fonction pour effectuer une validation détaillée
function Test-DetailedValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        [string[]]$AvailableVariables
    )
    
    # Commencer par une validation de base
    $result = Test-BasicValidation -Template $Template
    
    # Vérifier les variables utilisées
    $variablePattern = "\{\{([^}]+)\}\}"
    $matches = [regex]::Matches($Template, $variablePattern)
    
    foreach ($match in $matches) {
        $variable = $match.Groups[1].Value.Trim()
        
        # Ignorer les variables dans les boucles each
        if ($variable -match "^#each\s") {
            continue
        }
        
        # Ignorer les variables de fermeture de boucle
        if ($variable -match "^/each") {
            continue
        }
        
        # Ignorer les variables conditionnelles
        if ($variable -match "^#if\s") {
            continue
        }
        
        # Ignorer les variables de fermeture de condition
        if ($variable -match "^/if") {
            continue
        }
        
        # Vérifier si la variable est disponible
        if ($AvailableVariables -notcontains $variable) {
            $lineNumber = ($Template.Substring(0, $match.Index) -split "`n").Length
            
            $result.Warnings += @{
                Message = "Variable inconnue ou non disponible: $variable"
                Line = $lineNumber
                Severity = "Warning"
                Suggestion = "Remplacer par une variable disponible ou supprimer"
            }
        }
    }
    
    # Vérifier les boucles each
    $eachOpenPattern = "\{\{#each\s+([^}]+)\}\}"
    $eachClosePattern = "\{\{/each\}\}"
    
    $openMatches = [regex]::Matches($Template, $eachOpenPattern)
    $closeMatches = [regex]::Matches($Template, $eachClosePattern)
    
    if ($openMatches.Count -ne $closeMatches.Count) {
        $result.Errors += @{
            Message = "Nombre de balises d'ouverture et de fermeture de boucle each non concordant"
            Line = 0
            Severity = "Error"
            Suggestion = "Vérifier que chaque {{#each ...}} a sa balise {{/each}} correspondante"
        }
        
        $result.IsValid = $false
    }
    
    # Vérifier les conditions if
    $ifOpenPattern = "\{\{#if\s+([^}]+)\}\}"
    $ifClosePattern = "\{\{/if\}\}"
    
    $openMatches = [regex]::Matches($Template, $ifOpenPattern)
    $closeMatches = [regex]::Matches($Template, $ifClosePattern)
    
    if ($openMatches.Count -ne $closeMatches.Count) {
        $result.Errors += @{
            Message = "Nombre de balises d'ouverture et de fermeture de condition if non concordant"
            Line = 0
            Severity = "Error"
            Suggestion = "Vérifier que chaque {{#if ...}} a sa balise {{/if}} correspondante"
        }
        
        $result.IsValid = $false
    }
    
    return $result
}

# Fonction pour effectuer une validation complète
function Test-FullValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        [string[]]$AvailableVariables
    )
    
    # Commencer par une validation détaillée
    $result = Test-DetailedValidation -Template $Template -AvailableVariables $AvailableVariables
    
    # Vérifier la structure du document
    $lines = $Template -split "`n"
    $headingLevels = @()
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        # Vérifier les niveaux de titre
        if ($line -match "^(#+)\s+") {
            $level = $matches[1].Length
            $headingLevels += $level
            
            # Vérifier les sauts de niveau
            if ($headingLevels.Count -gt 1) {
                $prevLevel = $headingLevels[$headingLevels.Count - 2]
                
                if ($level - $prevLevel -gt 1) {
                    $result.Warnings += @{
                        Message = "Saut de niveau de titre: de H$prevLevel à H$level"
                        Line = $i + 1
                        Severity = "Warning"
                        Suggestion = "Utiliser des niveaux de titre consécutifs (H$prevLevel suivi de H$($prevLevel+1))"
                    }
                }
            }
        }
    }
    
    # Vérifier la longueur des lignes
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        if ($line.Length -gt 120) {
            $result.Warnings += @{
                Message = "Ligne trop longue: $($line.Length) caractères"
                Line = $i + 1
                Severity = "Warning"
                Suggestion = "Diviser la ligne en plusieurs lignes plus courtes"
            }
        }
    }
    
    # Vérifier les espaces en fin de ligne
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        if ($line -match "\s+$") {
            $result.Warnings += @{
                Message = "Espaces en fin de ligne"
                Line = $i + 1
                Severity = "Warning"
                Suggestion = "Supprimer les espaces en fin de ligne"
            }
        }
    }
    
    return $result
}

# Fonction pour appliquer les suggestions de correction
function Set-Suggestions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Template,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Suggestions
    )
    
    $lines = $Template -split "`n"
    $correctedLines = $lines.Clone()
    
    # Trier les suggestions par ligne (en ordre décroissant pour éviter les problèmes d'index)
    $sortedSuggestions = $Suggestions | Sort-Object -Property Line -Descending
    
    foreach ($suggestion in $sortedSuggestions) {
        $lineIndex = $suggestion.Line - 1
        
        if ($lineIndex -ge 0 -and $lineIndex -lt $correctedLines.Length) {
            $line = $correctedLines[$lineIndex]
            
            switch -Regex ($suggestion.Message) {
                "Espaces en fin de ligne" {
                    $correctedLines[$lineIndex] = $line -replace "\s+$", ""
                }
                "Ligne trop longue" {
                    # Ne pas corriger automatiquement les lignes trop longues
                }
                "Variable inconnue ou non disponible" {
                    # Ne pas corriger automatiquement les variables inconnues
                }
                "Lien avec URL vide" {
                    $correctedLines[$lineIndex] = $line -replace "\[\s*([^\]]+)\s*\]\(\s*\)", "[$1](https://example.com)"
                }
                "Tableau mal formé" {
                    # Ajouter une ligne de séparation après l'en-tête du tableau
                    $headerParts = $line -split "\|"
                    $separator = "|"
                    
                    for ($i = 1; $i -lt $headerParts.Length; $i++) {
                        $separator += "---|"
                    }
                    
                    $correctedLines[$lineIndex] = $line
                    $correctedLines = $correctedLines[0..$lineIndex] + $separator + $correctedLines[($lineIndex+1)..($correctedLines.Length-1)]
                }
                default {
                    # Ne pas corriger les autres types de problèmes
                }
            }
        }
    }
    
    return $correctedLines -join "`n"
}

# Fonction pour formater les résultats de validation
function Format-ValidationResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ValidationResult,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "Object", "JSON")]
        [string]$OutputFormat = "Text"
    )
    
    switch ($OutputFormat) {
        "Text" {
            $output = "Résultats de validation du template`n"
            $output += "Statut: " + $(if ($ValidationResult.IsValid) { "Valide" } else { "Invalide" }) + "`n"
            
            if ($ValidationResult.Errors.Count -gt 0) {
                $output += "`nErreurs:`n"
                foreach ($error in $ValidationResult.Errors) {
                    $line = if ($error.Line -gt 0) { " (ligne $($error.Line))" } else { "" }
                    $output += "- $($error.Message)$line`n"
                    
                    if ($error.Suggestion) {
                        $output += "  Suggestion: $($error.Suggestion)`n"
                    }
                }
            }
            
            if ($ValidationResult.Warnings.Count -gt 0) {
                $output += "`nAvertissements:`n"
                foreach ($warning in $ValidationResult.Warnings) {
                    $line = if ($warning.Line -gt 0) { " (ligne $($warning.Line))" } else { "" }
                    $output += "- $($warning.Message)$line`n"
                    
                    if ($warning.Suggestion) {
                        $output += "  Suggestion: $($warning.Suggestion)`n"
                    }
                }
            }
            
            return $output
        }
        "Object" {
            return $ValidationResult
        }
        "JSON" {
            return $ValidationResult | ConvertTo-Json -Depth 10
        }
    }
}

# Fonction principale pour valider un template
function Test-MarkdownTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory = $false)]
        [string]$VariablesPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Detailed", "Full")]
        [string]$ValidationLevel = "Detailed",
        
        [Parameter(Mandatory = $false)]
        [switch]$FixSuggestions,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "Object", "JSON")]
        [string]$OutputFormat = "Text"
    )
    
    # Charger le template
    $template = Get-Template -TemplatePath $TemplatePath -TemplateContent $TemplateContent
    
    if ($null -eq $template) {
        Write-Log "Failed to load template" -Level "Error"
        return $null
    }
    
    # Charger les variables disponibles
    $availableVariables = Get-AvailableVariables -VariablesPath $VariablesPath
    
    # Effectuer la validation selon le niveau demandé
    $validationResult = switch ($ValidationLevel) {
        "Basic" {
            Test-BasicValidation -Template $template
        }
        "Detailed" {
            Test-DetailedValidation -Template $template -AvailableVariables $availableVariables
        }
        "Full" {
            Test-FullValidation -Template $template -AvailableVariables $availableVariables
        }
    }
    
    # Appliquer les suggestions si demandé
    if ($FixSuggestions -and ($validationResult.Warnings.Count -gt 0 -or $validationResult.Errors.Count -gt 0)) {
        $suggestions = @()
        $suggestions += $validationResult.Warnings
        $suggestions += $validationResult.Errors
        
        $correctedTemplate = Set-Suggestions -Template $template -Suggestions $suggestions
        
        # Sauvegarder le template corrigé si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($TemplatePath)) {
            try {
                $correctedTemplate | Out-File -FilePath $TemplatePath -Encoding UTF8
                Write-Log "Corrected template saved to: $TemplatePath" -Level "Info"
            } catch {
                Write-Log "Error saving corrected template: $_" -Level "Error"
            }
        }
        
        # Ajouter le template corrigé au résultat
        $validationResult.CorrectedTemplate = $correctedTemplate
    }
    
    # Formater les résultats
    $formattedResult = Format-ValidationResults -ValidationResult $validationResult -OutputFormat $OutputFormat
    
    return $formattedResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $result = Test-MarkdownTemplate -TemplatePath $TemplatePath -TemplateContent $TemplateContent -VariablesPath $VariablesPath -ValidationLevel $ValidationLevel -FixSuggestions:$FixSuggestions -OutputFormat $OutputFormat
    
    if ($OutputFormat -eq "Text") {
        Write-Host $result
    } else {
        return $result
    }
}

