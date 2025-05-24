# Set-QueryLanguageSyntax.ps1
# Script pour définir la syntaxe du langage de requête simplifié
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "YAML")]
    [string]$OutputFormat = "JSON"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour définir la syntaxe du langage de requête
function Set-QueryLanguageSyntax {
    [CmdletBinding()]
    param ()
    
    Write-Log "Définition de la syntaxe du langage de requête..." -Level "Info"
    
    # Définir les opérateurs logiques
    $logicalOperators = @{
        AND = @{
            Symbols = @("AND", "&&", "ET")
            Description = "Opérateur ET logique. Les deux conditions doivent être vraies."
            Examples = @(
                "status:todo AND priority:high",
                "category:development && tags:urgent"
            )
            Precedence = 2
        }
        OR = @{
            Symbols = @("OR", "||", "OU")
            Description = "Opérateur OU logique. Au moins une des conditions doit être vraie."
            Examples = @(
                "status:done OR status:in_progress",
                "priority:high || priority:medium"
            )
            Precedence = 1
        }
        NOT = @{
            Symbols = @("NOT", "!", "NON")
            Description = "Opérateur NON logique. Inverse la condition qui suit."
            Examples = @(
                "NOT status:done",
                "!category:documentation"
            )
            Precedence = 3
        }
    }
    
    # Définir les opérateurs de comparaison
    $comparisonOperators = @{
        EQUALS = @{
            Symbols = @(":", "=", "==")
            Description = "Égalité. La valeur du champ doit être exactement égale à la valeur spécifiée."
            Examples = @(
                "status:todo",
                "priority=high"
            )
        }
        NOT_EQUALS = @{
            Symbols = @("!=", "<>")
            Description = "Inégalité. La valeur du champ doit être différente de la valeur spécifiée."
            Examples = @(
                "status!=done",
                "category<>documentation"
            )
        }
        CONTAINS = @{
            Symbols = @("~", "CONTAINS")
            Description = "Contient. La valeur du champ doit contenir la valeur spécifiée."
            Examples = @(
                "description~api",
                "title CONTAINS interface"
            )
        }
        STARTS_WITH = @{
            Symbols = @("^", "STARTS_WITH")
            Description = "Commence par. La valeur du champ doit commencer par la valeur spécifiée."
            Examples = @(
                "title^Implement",
                "description STARTS_WITH 'Create'"
            )
        }
        ENDS_WITH = @{
            Symbols = @("$", "ENDS_WITH")
            Description = "Termine par. La valeur du champ doit terminer par la valeur spécifiée."
            Examples = @(
                "title$interface",
                "description ENDS_WITH 'functionality'"
            )
        }
        GREATER_THAN = @{
            Symbols = @(">", "GT")
            Description = "Supérieur à. La valeur du champ doit être supérieure à la valeur spécifiée."
            Examples = @(
                "priority>medium",
                "completion_percentage>50"
            )
        }
        LESS_THAN = @{
            Symbols = @("<", "LT")
            Description = "Inférieur à. La valeur du champ doit être inférieure à la valeur spécifiée."
            Examples = @(
                "priority<high",
                "completion_percentage<50"
            )
        }
        GREATER_THAN_OR_EQUAL = @{
            Symbols = @(">=", "GTE")
            Description = "Supérieur ou égal à. La valeur du champ doit être supérieure ou égale à la valeur spécifiée."
            Examples = @(
                "priority>=medium",
                "completion_percentage>=50"
            )
        }
        LESS_THAN_OR_EQUAL = @{
            Symbols = @("<=", "LTE")
            Description = "Inférieur ou égal à. La valeur du champ doit être inférieure ou égale à la valeur spécifiée."
            Examples = @(
                "priority<=medium",
                "completion_percentage<=50"
            )
        }
    }
    
    # Définir les champs disponibles
    $availableFields = @{
        status = @{
            Type = "Enum"
            Values = @("todo", "in_progress", "done", "blocked")
            Description = "Statut de la tâche."
            Examples = @(
                "status:todo",
                "status:in_progress"
            )
        }
        priority = @{
            Type = "Enum"
            Values = @("low", "medium", "high")
            Description = "Priorité de la tâche."
            Examples = @(
                "priority:high",
                "priority:medium"
            )
        }
        category = @{
            Type = "String"
            Description = "Catégorie de la tâche."
            Examples = @(
                "category:development",
                "category:documentation"
            )
        }
        tags = @{
            Type = "Array"
            Description = "Tags associés à la tâche."
            Examples = @(
                "tags:urgent",
                "tags:bug"
            )
        }
        title = @{
            Type = "String"
            Description = "Titre de la tâche."
            Examples = @(
                "title~interface",
                "title^Implement"
            )
        }
        description = @{
            Type = "String"
            Description = "Description de la tâche."
            Examples = @(
                "description~API",
                "description CONTAINS 'user interface'"
            )
        }
        id = @{
            Type = "String"
            Description = "Identifiant de la tâche."
            Examples = @(
                "id:1.2.3",
                "id^2.1"
            )
        }
        section = @{
            Type = "String"
            Description = "Section contenant la tâche."
            Examples = @(
                "section:Development",
                "section~API"
            )
        }
        indent_level = @{
            Type = "Number"
            Description = "Niveau d'indentation de la tâche."
            Examples = @(
                "indent_level>1",
                "indent_level<=3"
            )
        }
        has_children = @{
            Type = "Boolean"
            Description = "Indique si la tâche a des sous-tâches."
            Examples = @(
                "has_children:true",
                "has_children:false"
            )
        }
        has_parent = @{
            Type = "Boolean"
            Description = "Indique si la tâche a une tâche parente."
            Examples = @(
                "has_parent:true",
                "has_parent:false"
            )
        }
        due_date = @{
            Type = "Date"
            Description = "Date d'échéance de la tâche."
            Examples = @(
                "due_date>2025-06-01",
                "due_date<=2025-12-31"
            )
        }
    }
    
    # Définir les règles de syntaxe
    $syntaxRules = @{
        SimpleQuery = @{
            Pattern = "<field><operator><value>"
            Description = "Requête simple avec un champ, un opérateur et une valeur."
            Examples = @(
                "status:todo",
                "priority:high"
            )
        }
        LogicalCombination = @{
            Pattern = "<query> <logical_operator> <query>"
            Description = "Combinaison logique de deux requêtes."
            Examples = @(
                "status:todo AND priority:high",
                "category:development OR category:documentation"
            )
        }
        Negation = @{
            Pattern = "NOT <query>"
            Description = "Négation d'une requête."
            Examples = @(
                "NOT status:done",
                "NOT (category:documentation AND priority:low)"
            )
        }
        Grouping = @{
            Pattern = "(<query>)"
            Description = "Groupement de requêtes pour contrôler la précédence."
            Examples = @(
                "(status:todo OR status:in_progress) AND priority:high",
                "NOT (category:documentation AND priority:low)"
            )
        }
        ValueQuoting = @{
            Pattern = "<field><operator>\"<value with spaces>\""
            Description = "Utilisation de guillemets pour les valeurs contenant des espaces."
            Examples = @(
                "title:\"Implement user interface\"",
                "description~\"API documentation\""
            )
        }
        MultipleValues = @{
            Pattern = "<field><operator>[<value1>,<value2>,...]"
            Description = "Spécification de plusieurs valeurs pour un champ."
            Examples = @(
                "status:[todo,in_progress]",
                "tags:[urgent,bug,critical]"
            )
        }
        Wildcards = @{
            Pattern = "<field><operator><value with * or ?>"
            Description = "Utilisation de caractères jokers (* pour plusieurs caractères, ? pour un seul)."
            Examples = @(
                "title~impl*",
                "description~\"API*documentation\""
            )
        }
    }
    
    # Créer la définition complète de la syntaxe
    $syntaxDefinition = @{
        Name = "Langage de requête simplifié pour les roadmaps"
        Version = "1.0"
        Description = "Langage de requête simplifié pour filtrer les tâches dans les roadmaps."
        LogicalOperators = $logicalOperators
        ComparisonOperators = $comparisonOperators
        AvailableFields = $availableFields
        SyntaxRules = $syntaxRules
        Examples = @{
            Simple = @(
                "status:todo",
                "priority:high",
                "category:development"
            )
            Intermediate = @(
                "status:todo AND priority:high",
                "category:development OR category:documentation",
                "NOT status:done"
            )
            Advanced = @(
                "(status:todo OR status:in_progress) AND priority:high",
                "category:development AND tags:[urgent,critical] AND NOT has_children:true",
                "title~\"interface\" OR description~\"API\" AND due_date>2025-06-01"
            )
        }
    }
    
    Write-Log "Définition de la syntaxe terminée." -Level "Success"
    
    return $syntaxDefinition
}

# Fonction pour exporter la définition de la syntaxe
function Export-SyntaxDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$SyntaxDefinition,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFormat
    )
    
    Write-Log "Exportation de la définition de la syntaxe au format $OutputFormat..." -Level "Info"
    
    # Créer le répertoire de sortie si nécessaire
    $outputDir = Split-Path -Parent $OutputPath
    
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Exporter selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            $json = $SyntaxDefinition | ConvertTo-Json -Depth 10
            $json | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "YAML" {
            # Utiliser un module YAML si disponible, sinon simuler
            if (Get-Module -ListAvailable -Name "powershell-yaml") {
                Import-Module -Name "powershell-yaml"
                $yaml = $SyntaxDefinition | ConvertTo-Yaml
                $yaml | Set-Content -Path $OutputPath -Encoding UTF8
            } else {
                Write-Log "Module YAML non disponible. Utilisation d'un format YAML simplifié." -Level "Warning"
                
                # Fonction récursive pour convertir en YAML simplifié
                function ConvertTo-SimpleYaml {
                    param (
                        [Parameter(Mandatory = $true)]
                        $InputObject,
                        
                        [Parameter(Mandatory = $false)]
                        [int]$Indent = 0
                    )
                    
                    $indentString = " " * $Indent
                    $result = ""
                    
                    if ($InputObject -is [hashtable]) {
                        foreach ($key in $InputObject.Keys) {
                            $value = $InputObject[$key]
                            
                            if ($value -is [hashtable] -or $value -is [array]) {
                                $result += "$indentString$key:`n"
                                $result += ConvertTo-SimpleYaml -InputObject $value -Indent ($Indent + 2)
                            } else {
                                $result += "$indentString$key: $value`n"
                            }
                        }
                    } elseif ($InputObject -is [array]) {
                        foreach ($item in $InputObject) {
                            if ($item -is [hashtable] -or $item -is [array]) {
                                $result += "$indentString- `n"
                                $result += ConvertTo-SimpleYaml -InputObject $item -Indent ($Indent + 2)
                            } else {
                                $result += "$indentString- $item`n"
                            }
                        }
                    } else {
                        $result += "$indentString$InputObject`n"
                    }
                    
                    return $result
                }
                
                $yaml = ConvertTo-SimpleYaml -InputObject $SyntaxDefinition
                $yaml | Set-Content -Path $OutputPath -Encoding UTF8
            }
        }
        "Markdown" {
            $markdown = "# $($SyntaxDefinition.Name)`n`n"
            $markdown += "Version: $($SyntaxDefinition.Version)`n`n"
            $markdown += "$($SyntaxDefinition.Description)`n`n"
            
            # Opérateurs logiques
            $markdown += "## Opérateurs logiques`n`n"
            $markdown += "| Opérateur | Symboles | Description | Précédence |`n"
            $markdown += "|-----------|----------|-------------|------------|`n"
            
            foreach ($opName in $SyntaxDefinition.LogicalOperators.Keys) {
                $op = $SyntaxDefinition.LogicalOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $markdown += "| $opName | $symbols | $($op.Description) | $($op.Precedence) |`n"
            }
            
            $markdown += "`n"
            
            # Opérateurs de comparaison
            $markdown += "## Opérateurs de comparaison`n`n"
            $markdown += "| Opérateur | Symboles | Description |`n"
            $markdown += "|-----------|----------|-------------|`n"
            
            foreach ($opName in $SyntaxDefinition.ComparisonOperators.Keys) {
                $op = $SyntaxDefinition.ComparisonOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $markdown += "| $opName | $symbols | $($op.Description) |`n"
            }
            
            $markdown += "`n"
            
            # Champs disponibles
            $markdown += "## Champs disponibles`n`n"
            $markdown += "| Champ | Type | Description |`n"
            $markdown += "|-------|------|-------------|`n"
            
            foreach ($fieldName in $SyntaxDefinition.AvailableFields.Keys) {
                $field = $SyntaxDefinition.AvailableFields[$fieldName]
                $markdown += "| $fieldName | $($field.Type) | $($field.Description) |`n"
            }
            
            $markdown += "`n"
            
            # Règles de syntaxe
            $markdown += "## Règles de syntaxe`n`n"
            $markdown += "| Règle | Pattern | Description |`n"
            $markdown += "|-------|---------|-------------|`n"
            
            foreach ($ruleName in $SyntaxDefinition.SyntaxRules.Keys) {
                $rule = $SyntaxDefinition.SyntaxRules[$ruleName]
                $markdown += "| $ruleName | `$($rule.Pattern)` | $($rule.Description) |`n"
            }
            
            $markdown += "`n"
            
            # Exemples
            $markdown += "## Exemples`n`n"
            
            $markdown += "### Requêtes simples`n`n"
            foreach ($example in $SyntaxDefinition.Examples.Simple) {
                $markdown += "- `$example``n"
            }
            
            $markdown += "`n### Requêtes intermédiaires`n`n"
            foreach ($example in $SyntaxDefinition.Examples.Intermediate) {
                $markdown += "- `$example``n"
            }
            
            $markdown += "`n### Requêtes avancées`n`n"
            foreach ($example in $SyntaxDefinition.Examples.Advanced) {
                $markdown += "- `$example``n"
            }
            
            $markdown | Set-Content -Path $OutputPath -Encoding UTF8
        }
    }
    
    Write-Log "Définition de la syntaxe exportée dans : $OutputPath" -Level "Success"
    
    return $OutputPath
}

# Fonction principale
function Set-QueryLanguageSyntax {
    [CmdletBinding()]
    param (
        [string]$OutputPath,
        [string]$OutputFormat
    )
    
    Write-Log "Démarrage de la définition de la syntaxe du langage de requête..." -Level "Info"
    
    # Définir la syntaxe
    $syntaxDefinition = Set-QueryLanguageSyntax
    
    # Exporter la définition si demandé
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        Export-SyntaxDefinition -SyntaxDefinition $syntaxDefinition -OutputPath $OutputPath -OutputFormat $OutputFormat
    }
    
    return $syntaxDefinition
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-QueryLanguageSyntax -OutputPath $OutputPath -OutputFormat $OutputFormat
}

