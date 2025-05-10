# Get-QuerySuggestions.ps1
# Script pour l'assistance à la saisie des requêtes (suggestions)
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PartialQuery,
    
    [Parameter(Mandatory = $false)]
    [int]$CursorPosition = -1,
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [string]$SchemaPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Fields", "Operators", "Values", "LogicalOperators")]
    [string]$SuggestionType = "All",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxSuggestions = 10,
    
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

# Définir les mots-clés statiques pour l'autocomplétion
$staticKeywords = @{
    "LogicalOperators" = @("AND", "OR", "NOT")
    "Fields" = @("status", "priority", "category", "title", "description", "assignee", "due_date", "created_at", "updated_at", "tags", "id", "parent_id", "indent_level", "has_children", "has_blockers", "is_milestone", "estimated_hours", "actual_hours", "progress", "start_date", "end_date")
    "Operators" = @(":", "=", "!=", "<>", ">", "<", ">=", "<=", "~", "^", "$", "CONTAINS", "STARTSWITH", "ENDSWITH")
    "CommonValues" = @{
        "status" = @("todo", "in_progress", "done", "blocked", "pending", "deferred", "cancelled")
        "priority" = @("high", "medium", "low", "critical", "trivial")
        "category" = @("development", "documentation", "testing", "design", "research", "planning", "maintenance", "bugfix", "feature", "refactoring")
        "is_milestone" = @("true", "false")
        "has_children" = @("true", "false")
        "has_blockers" = @("true", "false")
    }
}

# Fonction pour charger le schéma des champs
function Get-FieldSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SchemaPath
    )
    
    if (-not $SchemaPath -or -not (Test-Path -Path $SchemaPath)) {
        Write-Log "Schema file not found or not specified, using static schema" -Level "Info"
        return $staticKeywords
    }
    
    try {
        $schema = Get-Content -Path $SchemaPath -Raw | ConvertFrom-Json
        
        # Convertir le schéma en format utilisable
        $result = @{
            "LogicalOperators" = $staticKeywords.LogicalOperators
            "Operators" = $staticKeywords.Operators
            "Fields" = @()
            "CommonValues" = @{}
        }
        
        # Extraire les champs et leurs valeurs possibles
        foreach ($field in $schema.fields) {
            $result.Fields += $field.name
            
            if ($field.possibleValues -and $field.possibleValues.Count -gt 0) {
                $result.CommonValues[$field.name] = $field.possibleValues
            }
        }
        
        return $result
    } catch {
        Write-Log "Error loading schema: $_" -Level "Error"
        return $staticKeywords
    }
}

# Fonction pour extraire les valeurs uniques des champs à partir d'un fichier de roadmap
function Get-FieldValuesFromRoadmap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )
    
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Roadmap file not found: $RoadmapPath" -Level "Warning"
        return @()
    }
    
    try {
        $extension = [System.IO.Path]::GetExtension($RoadmapPath).ToLower()
        
        switch ($extension) {
            ".json" {
                $data = Get-Content -Path $RoadmapPath -Raw | ConvertFrom-Json
                
                # Extraire les valeurs uniques du champ spécifié
                $values = $data | ForEach-Object { $_.$FieldName } | Where-Object { $_ } | Select-Object -Unique
                return $values
            }
            ".md" {
                # Pour les fichiers markdown, nous devons extraire les métadonnées des tâches
                # Cette implémentation est simplifiée et pourrait nécessiter une analyse plus sophistiquée
                $content = Get-Content -Path $RoadmapPath -Raw
                
                # Rechercher des patterns comme "status:todo" ou "priority:high"
                $pattern = "$FieldName\s*[:=]\s*(\w+)"
                $matches = [regex]::Matches($content, $pattern)
                
                $values = $matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
                return $values
            }
            default {
                Write-Log "Unsupported roadmap file format: $extension" -Level "Warning"
                return @()
            }
        }
    } catch {
        Write-Log "Error extracting field values from roadmap: $_" -Level "Error"
        return @()
    }
}

# Fonction pour analyser le contexte de la requête
function Get-QueryContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PartialQuery,
        
        [Parameter(Mandatory = $true)]
        [int]$CursorPosition
    )
    
    # Si la position du curseur n'est pas spécifiée, utiliser la fin de la requête
    if ($CursorPosition -lt 0) {
        $CursorPosition = $PartialQuery.Length
    }
    
    # Extraire le texte jusqu'à la position du curseur
    $textBeforeCursor = $PartialQuery.Substring(0, $CursorPosition)
    
    # Déterminer le contexte
    $context = @{
        "Type" = "Unknown"
        "PartialText" = ""
        "Field" = $null
    }
    
    # Vérifier si nous sommes après un opérateur de comparaison (suggérer des valeurs)
    if ($textBeforeCursor -match '(\w+)\s*[:=><~\^\$]\s*(\w*)$') {
        $context.Type = "Value"
        $context.Field = $matches[1]
        $context.PartialText = $matches[2]
    }
    # Vérifier si nous sommes au début d'un champ (suggérer des champs)
    elseif ($textBeforeCursor -match '(^|\s+|\()([a-zA-Z]*)$') {
        $context.Type = "Field"
        $context.PartialText = $matches[2]
    }
    # Vérifier si nous sommes après un espace (potentiellement un opérateur logique)
    elseif ($textBeforeCursor -match '\s+([A-Z]*)$') {
        $context.Type = "LogicalOperator"
        $context.PartialText = $matches[1]
    }
    # Vérifier si nous sommes après un champ (suggérer des opérateurs)
    elseif ($textBeforeCursor -match '(\w+)\s*$') {
        $context.Type = "Operator"
        $context.PartialText = ""
        $context.Field = $matches[1]
    }
    
    return $context
}

# Fonction pour obtenir des suggestions basées sur le contexte
function Get-ContextualSuggestions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Keywords,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Fields", "Operators", "Values", "LogicalOperators")]
        [string]$SuggestionType = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSuggestions = 10
    )
    
    $suggestions = @()
    
    switch ($Context.Type) {
        "Field" {
            if ($SuggestionType -in @("All", "Fields")) {
                $partialField = $Context.PartialText
                $suggestions = $Keywords.Fields | Where-Object { $_ -like "$partialField*" } | Sort-Object
            }
        }
        "Operator" {
            if ($SuggestionType -in @("All", "Operators")) {
                $suggestions = $Keywords.Operators | Sort-Object
            }
        }
        "LogicalOperator" {
            if ($SuggestionType -in @("All", "LogicalOperators")) {
                $partialOperator = $Context.PartialText
                $suggestions = $Keywords.LogicalOperators | Where-Object { $_ -like "$partialOperator*" } | Sort-Object
            }
        }
        "Value" {
            if ($SuggestionType -in @("All", "Values")) {
                $field = $Context.Field
                $partialValue = $Context.PartialText
                
                # Vérifier si nous avons des valeurs prédéfinies pour ce champ
                if ($Keywords.CommonValues.ContainsKey($field)) {
                    $suggestions = $Keywords.CommonValues[$field] | Where-Object { $_ -like "$partialValue*" } | Sort-Object
                }
                
                # Si un fichier de roadmap est spécifié, extraire les valeurs réelles
                if ($RoadmapPath -and (Test-Path -Path $RoadmapPath) -and $suggestions.Count -eq 0) {
                    $roadmapValues = Get-FieldValuesFromRoadmap -RoadmapPath $RoadmapPath -FieldName $field
                    $suggestions += $roadmapValues | Where-Object { $_ -like "$partialValue*" } | Sort-Object
                }
            }
        }
    }
    
    # Éliminer les doublons et limiter le nombre de suggestions
    $suggestions = $suggestions | Select-Object -Unique | Select-Object -First $MaxSuggestions
    
    return $suggestions
}

# Fonction principale pour obtenir des suggestions
function Get-QuerySuggestions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$PartialQuery,
        
        [Parameter(Mandatory = $false)]
        [int]$CursorPosition = -1,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [string]$SchemaPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Fields", "Operators", "Values", "LogicalOperators")]
        [string]$SuggestionType = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSuggestions = 10
    )
    
    # Si la position du curseur n'est pas spécifiée, utiliser la fin de la requête
    if ($CursorPosition -lt 0) {
        $CursorPosition = $PartialQuery.Length
    }
    
    # Charger le schéma des champs
    $keywords = Get-FieldSchema -SchemaPath $SchemaPath
    
    # Analyser le contexte de la requête
    $context = Get-QueryContext -PartialQuery $PartialQuery -CursorPosition $CursorPosition
    
    Write-Log "Query context: $($context.Type), Field: $($context.Field), PartialText: $($context.PartialText)" -Level "Debug"
    
    # Obtenir des suggestions basées sur le contexte
    $suggestions = Get-ContextualSuggestions -Context $context -Keywords $keywords -RoadmapPath $RoadmapPath -SuggestionType $SuggestionType -MaxSuggestions $MaxSuggestions
    
    # Retourner les suggestions avec des métadonnées
    $result = @{
        "Suggestions" = $suggestions
        "Context" = $context
        "ReplacementStart" = $CursorPosition - $context.PartialText.Length
        "ReplacementLength" = $context.PartialText.Length
    }
    
    return $result
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $result = Get-QuerySuggestions -PartialQuery $PartialQuery -CursorPosition $CursorPosition -RoadmapPath $RoadmapPath -SchemaPath $SchemaPath -SuggestionType $SuggestionType -MaxSuggestions $MaxSuggestions
    
    # Afficher les suggestions
    Write-Host "Suggestions for: $PartialQuery" -ForegroundColor Cyan
    Write-Host "Context: $($result.Context.Type)" -ForegroundColor Cyan
    if ($result.Context.Field) {
        Write-Host "Field: $($result.Context.Field)" -ForegroundColor Cyan
    }
    Write-Host "--------------------" -ForegroundColor Cyan
    
    if ($result.Suggestions.Count -eq 0) {
        Write-Host "No suggestions available." -ForegroundColor Yellow
    } else {
        foreach ($suggestion in $result.Suggestions) {
            Write-Host $suggestion
        }
    }
}
