# Script de test pour toutes les fonctions du module AstNavigator

# Charger toutes les fonctions
$publicFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Public"
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath -Filter "*.ps1"
foreach ($function in $publicFunctions) {
    Write-Host "Chargement de la fonction : $($function.Name)" -ForegroundColor Yellow
    . $function.FullName
}

# Créer un exemple de code PowerShell à analyser
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
    else {
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

# Tester la fonction Invoke-AstTraversalDFS
Write-Host "`n=== Test de Invoke-AstTraversalDFS ===" -ForegroundColor Cyan
Write-Host "Recherche de toutes les fonctions :" -ForegroundColor Yellow
$functions = Invoke-AstTraversalDFS -Ast $ast -NodeType "FunctionDefinition"
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester la fonction Invoke-AstTraversalBFS
Write-Host "`n=== Test de Invoke-AstTraversalBFS ===" -ForegroundColor Cyan
Write-Host "Recherche de toutes les variables :" -ForegroundColor Yellow
$variables = Invoke-AstTraversalDFS -Ast $ast -NodeType "VariableExpression"
$uniqueVars = @{}
foreach ($variable in $variables) {
    $varName = $variable.VariablePath.UserPath
    if (-not $uniqueVars.ContainsKey($varName)) {
        $uniqueVars[$varName] = $true
        Write-Host "  Variable: `$$varName (Ligne $($variable.Extent.StartLineNumber))" -ForegroundColor Green
    }
}

# Tester la fonction Find-AstNode
Write-Host "`n=== Test de Find-AstNode ===" -ForegroundColor Cyan
Write-Host "Recherche de la fonction 'Get-Example' :" -ForegroundColor Yellow
$getExampleFunction = Find-AstNode -Ast $ast -NodeType "FunctionDefinition" -Name "Get-Example" -First
if ($getExampleFunction) {
    Write-Host "  Fonction trouvée: $($getExampleFunction.Name) (Ligne $($getExampleFunction.Extent.StartLineNumber))" -ForegroundColor Green
    
    # Tester la fonction Get-AstNodeParent
    Write-Host "`n=== Test de Get-AstNodeParent ===" -ForegroundColor Cyan
    $parent = Get-AstNodeParent -Node $getExampleFunction
    Write-Host "  Parent de 'Get-Example': $($parent.GetType().Name) (Ligne $($parent.Extent.StartLineNumber))" -ForegroundColor Green
    
    # Tester la fonction Get-AstNodeSiblings
    Write-Host "`n=== Test de Get-AstNodeSiblings ===" -ForegroundColor Cyan
    $siblings = Get-AstNodeSiblings -Node $getExampleFunction
    Write-Host "  Frères de 'Get-Example':" -ForegroundColor Yellow
    foreach ($sibling in $siblings) {
        if ($sibling -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            Write-Host "    Fonction: $($sibling.Name) (Ligne $($sibling.Extent.StartLineNumber))" -ForegroundColor Green
        }
        else {
            Write-Host "    $($sibling.GetType().Name) (Ligne $($sibling.Extent.StartLineNumber))" -ForegroundColor Green
        }
    }
    
    # Tester la fonction Get-AstNodePath
    Write-Host "`n=== Test de Get-AstNodePath ===" -ForegroundColor Cyan
    $path = Get-AstNodePath -Node $getExampleFunction -AsString -IncludeTypes
    Write-Host "  Chemin de 'Get-Example': $path" -ForegroundColor Green
    
    # Tester la fonction Get-AstNodeDepth
    Write-Host "`n=== Test de Get-AstNodeDepth ===" -ForegroundColor Cyan
    $depth = Get-AstNodeDepth -Node $getExampleFunction
    Write-Host "  Profondeur de 'Get-Example': $depth" -ForegroundColor Green
    
    # Tester la fonction Test-AstNodeIsDescendant
    Write-Host "`n=== Test de Test-AstNodeIsDescendant ===" -ForegroundColor Cyan
    $forStatement = Find-AstNode -Ast $getExampleFunction -NodeType "ForStatement" -First
    if ($forStatement) {
        $isDescendant = Test-AstNodeIsDescendant -Node $forStatement -Ancestor $getExampleFunction
        Write-Host "  La boucle for est-elle descendante de 'Get-Example'? $isDescendant" -ForegroundColor Green
    }
    
    # Tester la fonction Get-AstNodeComplexity
    Write-Host "`n=== Test de Get-AstNodeComplexity ===" -ForegroundColor Cyan
    $complexity = Get-AstNodeComplexity -Node $getExampleFunction -IncludeChildren -Detailed
    Write-Host "  Complexité de 'Get-Example':" -ForegroundColor Yellow
    Write-Host "    Complexité totale: $($complexity.TotalComplexity)" -ForegroundColor Green
    Write-Host "    Nombre d'enfants: $($complexity.ChildCount)" -ForegroundColor Green
    Write-Host "    Profondeur maximale: $($complexity.MaxDepth)" -ForegroundColor Green
    Write-Host "    Structures de contrôle: $($complexity.ControlStructures)" -ForegroundColor Green
    Write-Host "    Opérateurs: $($complexity.Operators)" -ForegroundColor Green
    Write-Host "    Expressions: $($complexity.Expressions)" -ForegroundColor Green
    
    # Tester la fonction ConvertTo-AstNodePath
    Write-Host "`n=== Test de ConvertTo-AstNodePath ===" -ForegroundColor Cyan
    $nodePath = Get-AstNodePath -Node $getExampleFunction
    $pathString = ConvertTo-AstNodePath -Path $nodePath -IncludeTypes -IncludePositions
    Write-Host "  Chemin formaté de 'Get-Example': $pathString" -ForegroundColor Green
}
else {
    Write-Error "Fonction 'Get-Example' non trouvée."
}

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
