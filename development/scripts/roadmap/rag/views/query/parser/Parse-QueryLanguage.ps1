# Parse-QueryLanguage.ps1
# Script pour analyser et interpréter les requêtes dans le langage de requête personnalisé
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$QueryString,
    
    [Parameter(Mandatory = $false)]
    [switch]$ReturnTokens,
    
    [Parameter(Mandatory = $false)]
    [switch]$ReturnAST,
    
    [Parameter(Mandatory = $false)]
    [switch]$ReturnFilterFunction,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "Object"
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

# Définition des types de tokens
enum TokenType {
    Field
    Operator
    Value
    LogicalOperator
    LeftParenthesis
    RightParenthesis
    Unknown
}

# Définition des opérateurs
$operators = @{
    ":" = "Equality"
    "=" = "Equality"
    "==" = "Equality"
    "!=" = "Inequality"
    "<>" = "Inequality"
    ">" = "GreaterThan"
    "<" = "LessThan"
    ">=" = "GreaterThanOrEqual"
    "<=" = "LessThanOrEqual"
    "~" = "Contains"
    "^" = "StartsWith"
    "$" = "EndsWith"
}

# Définition des opérateurs logiques
$logicalOperators = @{
    "AND" = "And"
    "&&" = "And"
    "OR" = "Or"
    "||" = "Or"
    "NOT" = "Not"
    "!" = "Not"
}

# Classe pour représenter un token
class Token {
    [TokenType]$Type
    [string]$Value
    [int]$Position
    [string]$OperatorType
    
    Token([TokenType]$type, [string]$value, [int]$position) {
        $this.Type = $type
        $this.Value = $value
        $this.Position = $position
        $this.OperatorType = ""
    }
    
    Token([TokenType]$type, [string]$value, [int]$position, [string]$operatorType) {
        $this.Type = $type
        $this.Value = $value
        $this.Position = $position
        $this.OperatorType = $operatorType
    }
    
    [string] ToString() {
        return "Token { Type: $($this.Type), Value: '$($this.Value)', Position: $($this.Position), OperatorType: '$($this.OperatorType)' }"
    }
}

# Classe pour représenter un nœud dans l'arbre syntaxique abstrait (AST)
class ASTNode {
    [string]$Type
    [object]$Value
    [ASTNode[]]$Children
    
    ASTNode([string]$type, [object]$value) {
        $this.Type = $type
        $this.Value = $value
        $this.Children = @()
    }
    
    [void] AddChild([ASTNode]$child) {
        $this.Children += $child
    }
    
    [string] ToString() {
        return $this.ToStringWithIndent(0)
    }
    
    [string] ToStringWithIndent([int]$indent) {
        $indentStr = " " * ($indent * 2)
        $result = "$indentStr$($this.Type): $($this.Value)`n"
        
        foreach ($child in $this.Children) {
            $result += $child.ToStringWithIndent($indent + 1)
        }
        
        return $result
    }
}

# Fonction pour tokenizer la chaîne de requête
function Get-QueryTokens {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QueryString
    )
    
    Write-Log "Tokenizing query: $QueryString" -Level "Debug"
    
    $tokens = [System.Collections.ArrayList]::new()
    $position = 0
    $length = $QueryString.Length
    
    while ($position -lt $length) {
        # Ignorer les espaces
        if ([char]::IsWhiteSpace($QueryString[$position])) {
            $position++
            continue
        }
        
        # Parenthèses
        if ($QueryString[$position] -eq '(') {
            $null = $tokens.Add([Token]::new([TokenType]::LeftParenthesis, "(", $position))
            $position++
            continue
        }
        
        if ($QueryString[$position] -eq ')') {
            $null = $tokens.Add([Token]::new([TokenType]::RightParenthesis, ")", $position))
            $position++
            continue
        }
        
        # Opérateurs logiques
        $logicalOperatorMatch = $null
        foreach ($op in $logicalOperators.Keys | Sort-Object -Property Length -Descending) {
            if ($position + $op.Length -le $length -and $QueryString.Substring($position, $op.Length) -eq $op) {
                $logicalOperatorMatch = $op
                break
            }
        }
        
        if ($logicalOperatorMatch) {
            $null = $tokens.Add([Token]::new([TokenType]::LogicalOperator, $logicalOperatorMatch, $position, $logicalOperators[$logicalOperatorMatch]))
            $position += $logicalOperatorMatch.Length
            continue
        }
        
        # Valeurs entre guillemets
        if ($QueryString[$position] -eq '"' -or $QueryString[$position] -eq "'") {
            $quoteChar = $QueryString[$position]
            $startPos = $position
            $position++ # Passer le guillemet ouvrant
            
            $value = ""
            $escaped = $false
            
            while ($position -lt $length) {
                $char = $QueryString[$position]
                
                if ($escaped) {
                    $value += $char
                    $escaped = $false
                } elseif ($char -eq '\') {
                    $escaped = $true
                } elseif ($char -eq $quoteChar) {
                    break
                } else {
                    $value += $char
                }
                
                $position++
            }
            
            if ($position -lt $length) {
                $position++ # Passer le guillemet fermant
            } else {
                Write-Log "Unterminated quote at position $startPos" -Level "Warning"
            }
            
            # Déterminer si c'est une valeur ou un champ basé sur le contexte
            $tokenType = [TokenType]::Value
            
            $null = $tokens.Add([Token]::new($tokenType, $value, $startPos))
            continue
        }
        
        # Champs et opérateurs
        $fieldOrOperator = ""
        $startPos = $position
        
        while ($position -lt $length -and -not [char]::IsWhiteSpace($QueryString[$position]) -and $QueryString[$position] -ne '(' -and $QueryString[$position] -ne ')') {
            $fieldOrOperator += $QueryString[$position]
            $position++
            
            # Vérifier si nous avons un opérateur
            $operatorMatch = $null
            foreach ($op in $operators.Keys | Sort-Object -Property Length -Descending) {
                if ($fieldOrOperator.EndsWith($op)) {
                    $operatorMatch = $op
                    break
                }
            }
            
            if ($operatorMatch) {
                $field = $fieldOrOperator.Substring(0, $fieldOrOperator.Length - $operatorMatch.Length)
                
                if ($field) {
                    $null = $tokens.Add([Token]::new([TokenType]::Field, $field, $startPos))
                }
                
                $null = $tokens.Add([Token]::new([TokenType]::Operator, $operatorMatch, $startPos + $field.Length, $operators[$operatorMatch]))
                $fieldOrOperator = ""
                $startPos = $position
                break
            }
        }
        
        # Si nous avons encore du texte, c'est soit un champ, soit une valeur
        if ($fieldOrOperator) {
            # Déterminer si c'est une valeur ou un champ basé sur le contexte
            $tokenType = [TokenType]::Value
            
            # Si le token précédent est un opérateur, alors c'est une valeur
            if ($tokens.Count -gt 0 -and $tokens[-1].Type -eq [TokenType]::Operator) {
                $tokenType = [TokenType]::Value
            }
            # Si le token suivant est un opérateur, alors c'est un champ
            elseif ($position -lt $length -and $operators.ContainsKey($QueryString[$position].ToString())) {
                $tokenType = [TokenType]::Field
            }
            # Sinon, c'est probablement un opérateur logique ou une valeur
            else {
                if ($logicalOperators.ContainsKey($fieldOrOperator.ToUpper())) {
                    $tokenType = [TokenType]::LogicalOperator
                    $null = $tokens.Add([Token]::new($tokenType, $fieldOrOperator, $startPos, $logicalOperators[$fieldOrOperator.ToUpper()]))
                    continue
                } else {
                    $tokenType = [TokenType]::Value
                }
            }
            
            $null = $tokens.Add([Token]::new($tokenType, $fieldOrOperator, $startPos))
        }
    }
    
    Write-Log "Tokenization complete. Found $($tokens.Count) tokens." -Level "Debug"
    
    return $tokens
}

# Fonction pour construire l'arbre syntaxique abstrait (AST)
function Get-QueryAST {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Tokens
    )
    
    Write-Log "Building AST from $($Tokens.Count) tokens" -Level "Debug"
    
    $position = 0
    
    # Fonction récursive pour analyser une expression
    function ConvertFrom-Expression {
        $left = ConvertFrom-Term
        
        while ($position -lt $Tokens.Count -and 
               $Tokens[$position].Type -eq [TokenType]::LogicalOperator -and 
               $Tokens[$position].OperatorType -eq "Or") {
            $operator = $Tokens[$position]
            $position++
            $right = ConvertFrom-Term
            
            $node = [ASTNode]::new("LogicalExpression", $operator.OperatorType)
            $node.AddChild($left)
            $node.AddChild($right)
            $left = $node
        }
        
        return $left
    }
    
    # Fonction pour analyser un terme
    function ConvertFrom-Term {
        $left = ConvertFrom-Factor
        
        while ($position -lt $Tokens.Count -and 
               $Tokens[$position].Type -eq [TokenType]::LogicalOperator -and 
               $Tokens[$position].OperatorType -eq "And") {
            $operator = $Tokens[$position]
            $position++
            $right = ConvertFrom-Factor
            
            $node = [ASTNode]::new("LogicalExpression", $operator.OperatorType)
            $node.AddChild($left)
            $node.AddChild($right)
            $left = $node
        }
        
        return $left
    }
    
    # Fonction pour analyser un facteur
    function ConvertFrom-Factor {
        if ($position -lt $Tokens.Count -and 
            $Tokens[$position].Type -eq [TokenType]::LogicalOperator -and 
            $Tokens[$position].OperatorType -eq "Not") {
            $operator = $Tokens[$position]
            $position++
            $operand = ConvertFrom-Factor
            
            $node = [ASTNode]::new("UnaryExpression", $operator.OperatorType)
            $node.AddChild($operand)
            return $node
        }
        
        return ConvertFrom-Primary
    }
    
    # Fonction pour analyser une expression primaire
    function ConvertFrom-Primary {
        if ($position -lt $Tokens.Count) {
            $token = $Tokens[$position]
            
            # Parenthèses
            if ($token.Type -eq [TokenType]::LeftParenthesis) {
                $position++
                $node = ConvertFrom-Expression
                
                if ($position -lt $Tokens.Count -and $Tokens[$position].Type -eq [TokenType]::RightParenthesis) {
                    $position++
                    return $node
                } else {
                    Write-Log "Expected closing parenthesis" -Level "Error"
                    throw "Syntax error: Expected closing parenthesis"
                }
            }
            
            # Condition (field operator value)
            if ($token.Type -eq [TokenType]::Field) {
                $field = $token
                $position++
                
                if ($position -lt $Tokens.Count -and $Tokens[$position].Type -eq [TokenType]::Operator) {
                    $operator = $Tokens[$position]
                    $position++
                    
                    if ($position -lt $Tokens.Count -and $Tokens[$position].Type -eq [TokenType]::Value) {
                        $value = $Tokens[$position]
                        $position++
                        
                        $node = [ASTNode]::new("Condition", $operator.OperatorType)
                        $node.AddChild([ASTNode]::new("Field", $field.Value))
                        $node.AddChild([ASTNode]::new("Value", $value.Value))
                        return $node
                    } else {
                        Write-Log "Expected value after operator" -Level "Error"
                        throw "Syntax error: Expected value after operator"
                    }
                } else {
                    Write-Log "Expected operator after field" -Level "Error"
                    throw "Syntax error: Expected operator after field"
                }
            }
            
            Write-Log "Unexpected token: $($token.ToString())" -Level "Error"
            throw "Syntax error: Unexpected token: $($token.ToString())"
        }
        
        Write-Log "Unexpected end of input" -Level "Error"
        throw "Syntax error: Unexpected end of input"
    }
    
    # Commencer l'analyse
    $ast = ConvertFrom-Expression
    
    if ($position -lt $Tokens.Count) {
        Write-Log "Unexpected tokens after parsing: $($Tokens[$position].ToString())" -Level "Warning"
    }
    
    Write-Log "AST building complete" -Level "Debug"
    
    return $ast
}

# Fonction pour générer une fonction de filtre à partir de l'AST
function Get-FilterFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ASTNode]$AST
    )
    
    Write-Log "Generating filter function from AST" -Level "Debug"
    
    # Fonction récursive pour générer le code de la fonction de filtre
    function New-FilterCode {
        param (
            [Parameter(Mandatory = $true)]
            [ASTNode]$Node
        )
        
        switch ($Node.Type) {
            "LogicalExpression" {
                $left = New-FilterCode -Node $Node.Children[0]
                $right = New-FilterCode -Node $Node.Children[1]
                
                switch ($Node.Value) {
                    "And" { return "($left -and $right)" }
                    "Or" { return "($left -or $right)" }
                    default { throw "Unknown logical operator: $($Node.Value)" }
                }
            }
            "UnaryExpression" {
                $operand = New-FilterCode -Node $Node.Children[0]
                
                switch ($Node.Value) {
                    "Not" { return "(-not $operand)" }
                    default { throw "Unknown unary operator: $($Node.Value)" }
                }
            }
            "Condition" {
                $field = $Node.Children[0].Value
                $value = $Node.Children[1].Value
                
                # Échapper les guillemets dans la valeur
                $value = $value -replace '"', '\"'
                
                switch ($Node.Value) {
                    "Equality" { return "`$_.'$field' -eq '$value'" }
                    "Inequality" { return "`$_.'$field' -ne '$value'" }
                    "GreaterThan" { return "`$_.'$field' -gt '$value'" }
                    "LessThan" { return "`$_.'$field' -lt '$value'" }
                    "GreaterThanOrEqual" { return "`$_.'$field' -ge '$value'" }
                    "LessThanOrEqual" { return "`$_.'$field' -le '$value'" }
                    "Contains" { return "`$_.'$field' -like '*$value*'" }
                    "StartsWith" { return "`$_.'$field' -like '$value*'" }
                    "EndsWith" { return "`$_.'$field' -like '*$value'" }
                    default { throw "Unknown operator: $($Node.Value)" }
                }
            }
            default {
                throw "Unknown node type: $($Node.Type)"
            }
        }
    }
    
    $filterCode = New-FilterCode -Node $AST
    $scriptBlock = [ScriptBlock]::Create("param(`$_) $filterCode")
    
    Write-Log "Filter function generation complete" -Level "Debug"
    
    return $scriptBlock
}

# Fonction principale pour analyser la requête
function ConvertFrom-Query {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QueryString,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnTokens,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnAST,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnFilterFunction,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFormat = "Object"
    )
    
    Write-Log "Parsing query: $QueryString" -Level "Info"
    
    try {
        # Tokenizer la requête
        $tokens = Get-QueryTokens -QueryString $QueryString
        
        if ($ReturnTokens) {
            return $tokens
        }
        
        # Construire l'AST
        $ast = Get-QueryAST -Tokens $tokens
        
        if ($ReturnAST) {
            return $ast
        }
        
        # Générer la fonction de filtre
        $filterFunction = Get-FilterFunction -AST $ast
        
        if ($ReturnFilterFunction) {
            return $filterFunction
        }
        
        # Retourner le résultat complet
        $result = [PSCustomObject]@{
            QueryString = $QueryString
            Tokens = $tokens
            AST = $ast
            FilterFunction = $filterFunction
        }
        
        # Formater la sortie selon le format demandé
        switch ($OutputFormat) {
            "Object" { return $result }
            "JSON" { return $result | ConvertTo-Json -Depth 10 }
            "XML" { return $result | ConvertTo-Xml -As String -Depth 10 }
            default { return $result }
        }
    } catch {
        Write-Log "Error parsing query: $_" -Level "Error"
        throw $_
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    ConvertFrom-Query -QueryString $QueryString -ReturnTokens:$ReturnTokens -ReturnAST:$ReturnAST -ReturnFilterFunction:$ReturnFilterFunction -OutputFormat $OutputFormat
}


