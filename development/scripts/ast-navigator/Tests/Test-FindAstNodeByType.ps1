# Script de test pour la fonction Find-AstNodeByType

# Charger la fonction
. "$PSScriptRoot\..\Public\Find-AstNodeByType.ps1"

# Créer un exemple de code PowerShell complexe à analyser
$sampleCode = @'
function Get-Example {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [int]$Count = 0
    )

    begin {
        Write-Verbose "Starting Get-Example with Name=$Name and Count=$Count"
        $result = @()
    }

    process {
        for ($i = 0; $i -lt $Count; $i++) {
            $item = [PSCustomObject]@{
                Name = $Name
                Index = $i
                Value = "Value-$i"
            }
            $result += $item
        }
    }

    end {
        return $result
    }
}

function Test-Example {
    param (
        [string]$Input
    )

    if ($Input -eq "Test") {
        return $true
    }
    elseif ($Input -eq "Debug") {
        Write-Debug "Debug mode activated"
        return $null
    }
    else {
        switch ($Input) {
            "Info" { Write-Information "Information mode" }
            "Warning" { Write-Warning "Warning mode" }
            "Error" { Write-Error "Error mode" }
            default { Write-Output "Default mode" }
        }
        return $false
    }
}

# Appeler la fonction
$result = Get-Example -Name "Sample" -Count 5
$result | ForEach-Object {
    Write-Output "Item: $($_.Name) - $($_.Index) - $($_.Value)"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Vérifier s'il y a des erreurs d'analyse
if ($errors.Count -gt 0) {
    Write-Error "Erreurs d'analyse du code :"
    foreach ($error in $errors) {
        Write-Error "  $($error.Extent.StartLineNumber):$($error.Extent.StartColumnNumber) - $($error.Message)"
    }
    exit 1
}

# Test 1: Recherche par type unique
Write-Host "`n=== Test 1: Recherche par type unique ===" -ForegroundColor Cyan
$functions = Find-AstNodeByType -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 2: Recherche par plusieurs types
Write-Host "`n=== Test 2: Recherche par plusieurs types ===" -ForegroundColor Cyan
$statements = Find-AstNodeByType -Ast $ast -NodeType @("IfStatement", "ForStatement")
Write-Host "Nombre de structures de controle trouvees: $($statements.Count)" -ForegroundColor Yellow
foreach ($statement in $statements) {
    $typeName = $statement.GetType().Name
    $lineNumber = $statement.Extent.StartLineNumber
    Write-Host "  $typeName (Ligne $lineNumber)" -ForegroundColor Green
}

# Test 3: Recherche par expression régulière
Write-Host "`n=== Test 3: Recherche par expression reguliere ===" -ForegroundColor Cyan
$expressionNodes = Find-AstNodeByType -Ast $ast -RegexPattern ".*Expression"
Write-Host "Nombre d'expressions trouvees: $($expressionNodes.Count)" -ForegroundColor Yellow
$uniqueTypes = @{}
foreach ($node in $expressionNodes) {
    $typeName = $node.GetType().Name
    if (-not $uniqueTypes.ContainsKey($typeName)) {
        $uniqueTypes[$typeName] = 0
    }
    $uniqueTypes[$typeName]++
}
foreach ($type in $uniqueTypes.Keys | Sort-Object) {
    Write-Host "  ${type}: $($uniqueTypes[$type])" -ForegroundColor Green
}

# Test 4: Recherche avec exclusion de types
Write-Host "`n=== Test 4: Recherche avec exclusion de types ===" -ForegroundColor Cyan
$statementsExcluded = Find-AstNodeByType -Ast $ast -RegexPattern ".*Statement" -ExcludeType "IfStatement"
Write-Host "Nombre de statements (sauf If) trouves: $($statementsExcluded.Count)" -ForegroundColor Yellow
$uniqueTypes = @{}
foreach ($node in $statementsExcluded) {
    $typeName = $node.GetType().Name
    if (-not $uniqueTypes.ContainsKey($typeName)) {
        $uniqueTypes[$typeName] = 0
    }
    $uniqueTypes[$typeName]++
}
foreach ($type in $uniqueTypes.Keys | Sort-Object) {
    Write-Host "  ${type}: $($uniqueTypes[$type])" -ForegroundColor Green
}

# Test 5: Recherche avec limite de profondeur
Write-Host "`n=== Test 5: Recherche avec limite de profondeur ===" -ForegroundColor Cyan
$variablesDepth2 = Find-AstNodeByType -Ast $ast -NodeType "VariableExpression" -MaxDepth 2
Write-Host "Nombre de variables (profondeur <= 2) trouvees: $($variablesDepth2.Count)" -ForegroundColor Yellow
$uniqueVars = @{}
foreach ($variable in $variablesDepth2) {
    $varName = $variable.VariablePath.UserPath
    if (-not $uniqueVars.ContainsKey($varName)) {
        $uniqueVars[$varName] = $true
        Write-Host "  Variable: `$$varName (Ligne $($variable.Extent.StartLineNumber))" -ForegroundColor Green
    }
}

# Test 6: Recherche avec prédicat personnalisé
Write-Host "`n=== Test 6: Recherche avec predicat personnalise ===" -ForegroundColor Cyan
$predicate = {
    param($node)
    if ($node -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
        return $node.Value -like "*mode*"
    }
    return $false
}
$stringConstants = Find-AstNodeByType -Ast $ast -NodeType "StringConstantExpression" -Predicate $predicate
Write-Host "Nombre de chaines contenant 'mode' trouvees: $($stringConstants.Count)" -ForegroundColor Yellow
foreach ($constant in $stringConstants) {
    Write-Host "  Chaine: '$($constant.Value)' (Ligne $($constant.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 7: Recherche avec types de base
Write-Host "`n=== Test 7: Recherche avec types de base ===" -ForegroundColor Cyan
$expressions = Find-AstNodeByType -Ast $ast -NodeType "ExpressionAst" -IncludeBaseTypes
Write-Host "Nombre d'expressions (incluant les types derives) trouvees: $($expressions.Count)" -ForegroundColor Yellow
$uniqueTypes = @{}
foreach ($node in $expressions) {
    $typeName = $node.GetType().Name
    if (-not $uniqueTypes.ContainsKey($typeName)) {
        $uniqueTypes[$typeName] = 0
    }
    $uniqueTypes[$typeName]++
}
foreach ($type in $uniqueTypes.Keys | Sort-Object) {
    Write-Host "  ${type}: $($uniqueTypes[$type])" -ForegroundColor Green
}

Write-Host "`nTous les tests sont termines." -ForegroundColor Green
