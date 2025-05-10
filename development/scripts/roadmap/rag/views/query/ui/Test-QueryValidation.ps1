# Test-QueryValidation.ps1
# Script pour la validation en temps réel des requêtes
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Query,
    
    [Parameter(Mandatory = $false)]
    [int]$CursorPosition = -1,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Detailed", "Semantic")]
    [string]$ValidationLevel = "Basic",
    
    [Parameter(Mandatory = $false)]
    [string]$SchemaPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "Object", "JSON")]
    [string]$OutputFormat = "Text"
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

# Fonction pour charger le schéma des champs
function Get-FieldSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SchemaPath
    )
    
    $defaultSchema = @{
        "Fields" = @(
            @{
                "Name" = "status"
                "Type" = "String"
                "AllowedValues" = @("todo", "in_progress", "done", "blocked", "pending", "deferred", "cancelled")
                "Required" = $false
            },
            @{
                "Name" = "priority"
                "Type" = "String"
                "AllowedValues" = @("high", "medium", "low", "critical", "trivial")
                "Required" = $false
            },
            @{
                "Name" = "category"
                "Type" = "String"
                "AllowedValues" = @("development", "documentation", "testing", "design", "research", "planning", "maintenance", "bugfix", "feature", "refactoring")
                "Required" = $false
            },
            @{
                "Name" = "title"
                "Type" = "String"
                "Required" = $false
            },
            @{
                "Name" = "description"
                "Type" = "String"
                "Required" = $false
            },
            @{
                "Name" = "assignee"
                "Type" = "String"
                "Required" = $false
            },
            @{
                "Name" = "due_date"
                "Type" = "DateTime"
                "Required" = $false
            },
            @{
                "Name" = "created_at"
                "Type" = "DateTime"
                "Required" = $false
            },
            @{
                "Name" = "updated_at"
                "Type" = "DateTime"
                "Required" = $false
            },
            @{
                "Name" = "tags"
                "Type" = "Array"
                "Required" = $false
            },
            @{
                "Name" = "id"
                "Type" = "String"
                "Required" = $false
            },
            @{
                "Name" = "parent_id"
                "Type" = "String"
                "Required" = $false
            },
            @{
                "Name" = "indent_level"
                "Type" = "Number"
                "Required" = $false
            },
            @{
                "Name" = "has_children"
                "Type" = "Boolean"
                "AllowedValues" = @("true", "false")
                "Required" = $false
            },
            @{
                "Name" = "has_blockers"
                "Type" = "Boolean"
                "AllowedValues" = @("true", "false")
                "Required" = $false
            },
            @{
                "Name" = "is_milestone"
                "Type" = "Boolean"
                "AllowedValues" = @("true", "false")
                "Required" = $false
            },
            @{
                "Name" = "estimated_hours"
                "Type" = "Number"
                "Required" = $false
            },
            @{
                "Name" = "actual_hours"
                "Type" = "Number"
                "Required" = $false
            },
            @{
                "Name" = "progress"
                "Type" = "Number"
                "Required" = $false
            },
            @{
                "Name" = "start_date"
                "Type" = "DateTime"
                "Required" = $false
            },
            @{
                "Name" = "end_date"
                "Type" = "DateTime"
                "Required" = $false
            }
        )
    }
    
    if (-not $SchemaPath -or -not (Test-Path -Path $SchemaPath)) {
        Write-Log "Schema file not found or not specified, using default schema" -Level "Info"
        return $defaultSchema
    }
    
    try {
        $schema = Get-Content -Path $SchemaPath -Raw | ConvertFrom-Json
        return $schema
    } catch {
        Write-Log "Error loading schema: $_" -Level "Error"
        return $defaultSchema
    }
}

# Fonction pour effectuer une validation syntaxique de base
function Test-BasicValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    $result = @{
        "IsValid" = $true
        "Errors" = @()
        "Warnings" = @()
        "Tokens" = @()
        "AST" = $null
    }
    
    try {
        # Analyser la requête
        $parseResult = Parse-Query -QueryString $Query -ReturnTokens -ReturnAST
        
        $result.Tokens = $parseResult.Tokens
        $result.AST = $parseResult.AST
        
        # Vérifier les erreurs de syntaxe évidentes
        if ($Query -match '\(\s*\)') {
            $result.Warnings += @{
                "Message" = "Empty parentheses detected"
                "Position" = $Query.IndexOf('()')
                "Severity" = "Warning"
            }
        }
        
        if ($Query -match '(AND|OR)\s*(AND|OR)') {
            $result.Warnings += @{
                "Message" = "Consecutive logical operators detected"
                "Position" = $Query.IndexOf($matches[0])
                "Severity" = "Warning"
            }
        }
        
        # Vérifier les parenthèses non équilibrées
        $openCount = ($Query.ToCharArray() | Where-Object { $_ -eq '(' }).Count
        $closeCount = ($Query.ToCharArray() | Where-Object { $_ -eq ')' }).Count
        
        if ($openCount -ne $closeCount) {
            $result.IsValid = $false
            $result.Errors += @{
                "Message" = "Unbalanced parentheses: $openCount opening vs $closeCount closing"
                "Position" = -1
                "Severity" = "Error"
            }
        }
        
        return $result
    } catch {
        $errorMessage = $_.Exception.Message
        $position = -1
        
        # Essayer d'extraire la position de l'erreur
        if ($errorMessage -match 'at position (\d+)') {
            $position = [int]$matches[1]
        }
        
        $result.IsValid = $false
        $result.Errors += @{
            "Message" = $errorMessage
            "Position" = $position
            "Severity" = "Error"
        }
        
        return $result
    }
}

# Fonction pour effectuer une validation détaillée
function Test-DetailedValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Schema
    )
    
    # Commencer par une validation de base
    $result = Test-BasicValidation -Query $Query
    
    # Si la validation de base a échoué, ne pas continuer
    if (-not $result.IsValid) {
        return $result
    }
    
    # Vérifier les champs utilisés dans la requête
    $validFields = $Schema.Fields | ForEach-Object { $_.Name }
    
    foreach ($token in $result.Tokens) {
        if ($token.Type -eq [TokenType]::Field) {
            $fieldName = $token.Value
            
            if ($validFields -notcontains $fieldName) {
                $result.Warnings += @{
                    "Message" = "Unknown field: $fieldName"
                    "Position" = $token.Position
                    "Severity" = "Warning"
                }
            }
        }
    }
    
    # Vérifier les valeurs pour les champs avec des valeurs autorisées
    $fieldTokens = $result.Tokens | Where-Object { $_.Type -eq [TokenType]::Field }
    
    foreach ($fieldToken in $fieldTokens) {
        $fieldName = $fieldToken.Value
        $fieldSchema = $Schema.Fields | Where-Object { $_.Name -eq $fieldName }
        
        if ($fieldSchema -and $fieldSchema.AllowedValues) {
            # Trouver l'opérateur et la valeur associés à ce champ
            $fieldPosition = $fieldToken.Position
            $operatorToken = $result.Tokens | Where-Object { 
                $_.Type -eq [TokenType]::Operator -and $_.Position -gt $fieldPosition 
            } | Select-Object -First 1
            
            if ($operatorToken) {
                $operatorPosition = $operatorToken.Position
                $valueToken = $result.Tokens | Where-Object { 
                    $_.Type -eq [TokenType]::Value -and $_.Position -gt $operatorPosition 
                } | Select-Object -First 1
                
                if ($valueToken) {
                    $value = $valueToken.Value
                    
                    # Vérifier si la valeur est autorisée
                    if ($fieldSchema.AllowedValues -notcontains $value) {
                        $result.Warnings += @{
                            "Message" = "Invalid value for field '$fieldName': $value. Allowed values: $($fieldSchema.AllowedValues -join ', ')"
                            "Position" = $valueToken.Position
                            "Severity" = "Warning"
                        }
                    }
                }
            }
        }
    }
    
    return $result
}

# Fonction pour effectuer une validation sémantique
function Test-SemanticValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Schema
    )
    
    # Commencer par une validation détaillée
    $result = Test-DetailedValidation -Query $Query -Schema $Schema
    
    # Si la validation détaillée a échoué, ne pas continuer
    if (-not $result.IsValid) {
        return $result
    }
    
    # Vérifier la cohérence des types de données
    $fieldTokens = $result.Tokens | Where-Object { $_.Type -eq [TokenType]::Field }
    
    foreach ($fieldToken in $fieldTokens) {
        $fieldName = $fieldToken.Value
        $fieldSchema = $Schema.Fields | Where-Object { $_.Name -eq $fieldName }
        
        if ($fieldSchema) {
            # Trouver l'opérateur et la valeur associés à ce champ
            $fieldPosition = $fieldToken.Position
            $operatorToken = $result.Tokens | Where-Object { 
                $_.Type -eq [TokenType]::Operator -and $_.Position -gt $fieldPosition 
            } | Select-Object -First 1
            
            if ($operatorToken) {
                $operatorPosition = $operatorToken.Position
                $valueToken = $result.Tokens | Where-Object { 
                    $_.Type -eq [TokenType]::Value -and $_.Position -gt $operatorPosition 
                } | Select-Object -First 1
                
                if ($valueToken) {
                    $value = $valueToken.Value
                    $operator = $operatorToken.Value
                    
                    # Vérifier la cohérence des types
                    switch ($fieldSchema.Type) {
                        "Number" {
                            if ($operator -in @("~", "^", "$") -or (-not [double]::TryParse($value, [ref]$null))) {
                                $result.Warnings += @{
                                    "Message" = "Type mismatch: field '$fieldName' is numeric but value '$value' is not a valid number or operator '$operator' is not appropriate for numeric fields"
                                    "Position" = $valueToken.Position
                                    "Severity" = "Warning"
                                }
                            }
                        }
                        "Boolean" {
                            if ($value -notin @("true", "false") -or $operator -notin @(":", "=", "!=", "<>")) {
                                $result.Warnings += @{
                                    "Message" = "Type mismatch: field '$fieldName' is boolean but value '$value' is not a valid boolean or operator '$operator' is not appropriate for boolean fields"
                                    "Position" = $valueToken.Position
                                    "Severity" = "Warning"
                                }
                            }
                        }
                        "DateTime" {
                            # Vérification simplifiée des dates
                            if ($operator -in @("~", "^", "$") -or (-not ($value -match '^\d{4}-\d{2}-\d{2}' -or $value -match '^\d{2}/\d{2}/\d{4}'))) {
                                $result.Warnings += @{
                                    "Message" = "Type mismatch: field '$fieldName' is a date but value '$value' is not in a recognized date format or operator '$operator' is not appropriate for date fields"
                                    "Position" = $valueToken.Position
                                    "Severity" = "Warning"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    # Vérifier la complexité de la requête
    $logicalOperatorCount = ($result.Tokens | Where-Object { $_.Type -eq [TokenType]::LogicalOperator }).Count
    $conditionCount = ($result.Tokens | Where-Object { $_.Type -eq [TokenType]::Field }).Count
    
    if ($logicalOperatorCount > 5) {
        $result.Warnings += @{
            "Message" = "Complex query: contains $logicalOperatorCount logical operators. Consider simplifying for better performance."
            "Position" = -1
            "Severity" = "Warning"
        }
    }
    
    if ($conditionCount > 10) {
        $result.Warnings += @{
            "Message" = "Complex query: contains $conditionCount conditions. Consider simplifying for better performance."
            "Position" = -1
            "Severity" = "Warning"
        }
    }
    
    return $result
}

# Fonction pour formater les résultats de validation
function Format-ValidationResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ValidationResult,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "Object", "JSON")]
        [string]$OutputFormat = "Text"
    )
    
    switch ($OutputFormat) {
        "Text" {
            $output = "Validation Results for: $Query`n"
            $output += "Status: " + $(if ($ValidationResult.IsValid) { "Valid" } else { "Invalid" }) + "`n"
            
            if ($ValidationResult.Errors.Count -gt 0) {
                $output += "`nErrors:`n"
                foreach ($error in $ValidationResult.Errors) {
                    $position = if ($error.Position -ge 0) { " at position $($error.Position)" } else { "" }
                    $output += "- $($error.Message)$position`n"
                }
            }
            
            if ($ValidationResult.Warnings.Count -gt 0) {
                $output += "`nWarnings:`n"
                foreach ($warning in $ValidationResult.Warnings) {
                    $position = if ($warning.Position -ge 0) { " at position $($warning.Position)" } else { "" }
                    $output += "- $($warning.Message)$position`n"
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

# Fonction principale pour valider une requête
function Test-QueryValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [int]$CursorPosition = -1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Detailed", "Semantic")]
        [string]$ValidationLevel = "Basic",
        
        [Parameter(Mandatory = $false)]
        [string]$SchemaPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "Object", "JSON")]
        [string]$OutputFormat = "Text"
    )
    
    # Charger le schéma
    $schema = Get-FieldSchema -SchemaPath $SchemaPath
    
    # Effectuer la validation selon le niveau demandé
    $validationResult = switch ($ValidationLevel) {
        "Basic" {
            Test-BasicValidation -Query $Query
        }
        "Detailed" {
            Test-DetailedValidation -Query $Query -Schema $schema
        }
        "Semantic" {
            Test-SemanticValidation -Query $Query -Schema $schema
        }
    }
    
    # Formater les résultats
    $formattedResult = Format-ValidationResults -ValidationResult $validationResult -Query $Query -OutputFormat $OutputFormat
    
    return $formattedResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $result = Test-QueryValidation -Query $Query -CursorPosition $CursorPosition -ValidationLevel $ValidationLevel -SchemaPath $SchemaPath -OutputFormat $OutputFormat
    
    if ($OutputFormat -eq "Text") {
        Write-Host $result
    } else {
        return $result
    }
}
