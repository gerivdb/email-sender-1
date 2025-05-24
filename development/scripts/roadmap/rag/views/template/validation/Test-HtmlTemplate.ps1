# Test-HtmlTemplate.ps1
# Script pour valider les templates HTML
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
    
    # Vérifier la structure HTML de base
    if (-not ($Template -match "<!DOCTYPE html>")) {
        $result.Warnings += @{
            Message = "Le template ne commence pas par <!DOCTYPE html>"
            Line = 1
            Severity = "Warning"
            Suggestion = "Ajouter <!DOCTYPE html> au début du template"
        }
    }
    
    if (-not ($Template -match "<html")) {
        $result.Errors += @{
            Message = "Balise <html> manquante"
            Line = 1
            Severity = "Error"
            Suggestion = "Ajouter une balise <html> après le doctype"
        }
        
        $result.IsValid = $false
    }
    
    if (-not ($Template -match "<head")) {
        $result.Errors += @{
            Message = "Balise <head> manquante"
            Line = 1
            Severity = "Error"
            Suggestion = "Ajouter une section <head> avec au moins un titre"
        }
        
        $result.IsValid = $false
    }
    
    if (-not ($Template -match "<body")) {
        $result.Errors += @{
            Message = "Balise <body> manquante"
            Line = 1
            Severity = "Error"
            Suggestion = "Ajouter une section <body> pour le contenu"
        }
        
        $result.IsValid = $false
    }
    
    # Vérifier les balises non fermées
    $openTags = @()
    $lines = $Template -split "`n"
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        # Trouver les balises ouvrantes (ignorer les balises auto-fermantes et les commentaires)
        $openMatches = [regex]::Matches($line, "<([a-zA-Z][a-zA-Z0-9]*)[^>]*(?<!/)>")
        
        foreach ($match in $openMatches) {
            $tagName = $match.Groups[1].Value
            
            # Ignorer les balises qui n'ont pas besoin d'être fermées
            if ($tagName -notin @("meta", "link", "br", "hr", "img", "input")) {
                $openTags += $tagName
            }
        }
        
        # Trouver les balises fermantes
        $closeMatches = [regex]::Matches($line, "</([a-zA-Z][a-zA-Z0-9]*)>")
        
        foreach ($match in $closeMatches) {
            $tagName = $match.Groups[1].Value
            
            if ($openTags.Count -gt 0 -and $openTags[-1] -eq $tagName) {
                # La balise correspond à la dernière balise ouverte
                $openTags = $openTags[0..($openTags.Count - 2)]
            } else {
                # Balise fermante sans balise ouvrante correspondante
                $result.Errors += @{
                    Message = "Balise fermante </`$tagName> sans balise ouvrante correspondante"
                    Line = $i + 1
                    Severity = "Error"
                    Suggestion = "Supprimer la balise fermante ou ajouter la balise ouvrante correspondante"
                }
                
                $result.IsValid = $false
            }
        }
    }
    
    # Vérifier s'il reste des balises non fermées
    if ($openTags.Count -gt 0) {
        foreach ($tag in $openTags) {
            $result.Errors += @{
                Message = "Balise <$tag> non fermée"
                Line = 0
                Severity = "Error"
                Suggestion = "Ajouter la balise fermante </$tag>"
            }
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
        
        # Ignorer les inclusions de composants
        if ($variable -match "^>\s") {
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
    
    # Vérifier les attributs HTML
    $attributePattern = "<[^>]+\s([a-zA-Z]+)=([^\"\']\S*|\"[^\"]*\"|\'[^\']*\')"
    $matches = [regex]::Matches($Template, $attributePattern)
    
    foreach ($match in $matches) {
        $attribute = $match.Groups[1].Value
        $value = $match.Groups[2].Value
        
        # Vérifier si la valeur est entourée de guillemets
        if (-not ($value -match "^[\"'].*[\"']$")) {
            $lineNumber = ($Template.Substring(0, $match.Index) -split "`n").Length
            
            $result.Warnings += @{
                Message = "Attribut HTML sans guillemets: $attribute=$value"
                Line = $lineNumber
                Severity = "Warning"
                Suggestion = "Entourer la valeur de guillemets: $attribute=\"$value\""
            }
        }
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
    
    # Vérifier les ressources externes (CSS, JS)
    $cssPattern = "<link[^>]+rel=[\"']stylesheet[\"'][^>]*>"
    $jsPattern = "<script[^>]+src=[\"'][^\"']+[\"'][^>]*>"
    
    $cssMatches = [regex]::Matches($Template, $cssPattern)
    $jsMatches = [regex]::Matches($Template, $jsPattern)
    
    if ($cssMatches.Count -eq 0) {
        $result.Warnings += @{
            Message = "Aucune feuille de style CSS externe détectée"
            Line = 0
            Severity = "Warning"
            Suggestion = "Ajouter une feuille de style CSS pour améliorer l'apparence"
        }
    }
    
    # Vérifier les balises meta importantes
    $charsetPattern = "<meta[^>]+charset=[\"'][^\"']+[\"'][^>]*>"
    $viewportPattern = "<meta[^>]+name=[\"']viewport[\"'][^>]*>"
    
    $charsetMatches = [regex]::Matches($Template, $charsetPattern)
    $viewportMatches = [regex]::Matches($Template, $viewportPattern)
    
    if ($charsetMatches.Count -eq 0) {
        $result.Warnings += @{
            Message = "Balise meta charset manquante"
            Line = 0
            Severity = "Warning"
            Suggestion = "Ajouter <meta charset=\"UTF-8\"> dans la section head"
        }
    }
    
    if ($viewportMatches.Count -eq 0) {
        $result.Warnings += @{
            Message = "Balise meta viewport manquante"
            Line = 0
            Severity = "Warning"
            Suggestion = "Ajouter <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> dans la section head"
        }
    }
    
    # Vérifier l'accessibilité de base
    $imgAltPattern = "<img[^>]+alt=[\"'][^\"']*[\"'][^>]*>"
    $imgNoAltPattern = "<img[^>]+(?!alt=)[^>]*>"
    
    $imgNoAltMatches = [regex]::Matches($Template, $imgNoAltPattern)
    
    foreach ($match in $imgNoAltMatches) {
        $lineNumber = ($Template.Substring(0, $match.Index) -split "`n").Length
        
        $result.Warnings += @{
            Message = "Image sans attribut alt"
            Line = $lineNumber
            Severity = "Warning"
            Suggestion = "Ajouter un attribut alt descriptif à l'image pour l'accessibilité"
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
                "Le template ne commence pas par <!DOCTYPE html>" {
                    if ($lineIndex -eq 0) {
                        $correctedLines[0] = "<!DOCTYPE html>`n" + $correctedLines[0]
                    }
                }
                "Attribut HTML sans guillemets" {
                    if ($suggestion.Message -match "Attribut HTML sans guillemets: ([a-zA-Z]+)=([^\s\"\']+)") {
                        $attribute = $matches[1]
                        $value = $matches[2]
                        $correctedLines[$lineIndex] = $line -replace "$attribute=$value", "$attribute=`"$value`""
                    }
                }
                "Image sans attribut alt" {
                    $correctedLines[$lineIndex] = $line -replace "<img([^>]+)>", "<img`$1 alt=`"Image`">"
                }
                default {
                    # Ne pas corriger les autres types de problèmes
                }
            }
        }
    }
    
    # Corrections globales
    $correctedTemplate = $correctedLines -join "`n"
    
    # Ajouter les balises HTML de base si manquantes
    if (-not ($correctedTemplate -match "<html")) {
        $correctedTemplate = $correctedTemplate -replace "<!DOCTYPE html>", "<!DOCTYPE html>`n<html lang=`"fr`">"
        $correctedTemplate += "`n</html>"
    }
    
    if (-not ($correctedTemplate -match "<head")) {
        $correctedTemplate = $correctedTemplate -replace "<html([^>]*)>", "<html`$1>`n<head>`n  <meta charset=`"UTF-8`">`n  <title>{{title}}</title>`n</head>"
    }
    
    if (-not ($correctedTemplate -match "<body")) {
        $correctedTemplate = $correctedTemplate -replace "</head>", "</head>`n<body>"
        $correctedTemplate = $correctedTemplate -replace "</html>", "</body>`n</html>"
    }
    
    return $correctedTemplate
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
            $output = "Résultats de validation du template HTML`n"
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
function Test-HtmlTemplate {
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
    $result = Test-HtmlTemplate -TemplatePath $TemplatePath -TemplateContent $TemplateContent -VariablesPath $VariablesPath -ValidationLevel $ValidationLevel -FixSuggestions:$FixSuggestions -OutputFormat $OutputFormat
    
    if ($OutputFormat -eq "Text") {
        Write-Host $result
    } else {
        return $result
    }
}

