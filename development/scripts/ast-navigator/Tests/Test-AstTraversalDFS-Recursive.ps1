# Script de test pour la fonction Invoke-AstTraversalDFS-Recursive

# Charger la fonction
. "$PSScriptRoot\..\Public\Invoke-AstTraversalDFS-Recursive.ps1"

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

# Test 1: Recherche de toutes les fonctions sans limite de profondeur
Write-Host "`n=== Test 1: Recherche de toutes les fonctions sans limite de profondeur ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalDFS-Recursive -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvées: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 2: Recherche de toutes les variables avec limite de profondeur
Write-Host "`n=== Test 2: Recherche de toutes les variables avec limite de profondeur 3 ===" -ForegroundColor Cyan
$variables = Invoke-AstTraversalDFS-Recursive -Ast $ast -NodeType "VariableExpression" -MaxDepth 3
Write-Host "Nombre de variables trouvées: $($variables.Count)" -ForegroundColor Yellow
$uniqueVars = @{}
foreach ($variable in $variables) {
    $varName = $variable.VariablePath.UserPath
    if (-not $uniqueVars.ContainsKey($varName)) {
        $uniqueVars[$varName] = $true
        Write-Host "  Variable: `$$varName (Ligne $($variable.Extent.StartLineNumber))" -ForegroundColor Green
    }
}

# Test 3: Recherche avec prédicat personnalisé
Write-Host "`n=== Test 3: Recherche avec prédicat personnalisé ===" -ForegroundColor Cyan
$predicate = {
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -like "Get-*"
}
$getFunctions = Invoke-AstTraversalDFS-Recursive -Ast $ast -Predicate $predicate
Write-Host "Nombre de fonctions 'Get-*' trouvées: $($getFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $getFunctions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 4: Recherche avec inclusion du nœud racine
Write-Host "`n=== Test 4: Recherche avec inclusion du nœud racine ===" -ForegroundColor Cyan
$rootIncluded = Invoke-AstTraversalDFS-Recursive -Ast $ast -IncludeRoot
Write-Host "Type du nœud racine: $($ast.GetType().Name)" -ForegroundColor Yellow
Write-Host "Nombre de nœuds trouvés (avec racine): $($rootIncluded.Count)" -ForegroundColor Yellow
Write-Host "Premier nœud: $($rootIncluded[0].GetType().Name)" -ForegroundColor Green

# Test 5: Comparaison des performances avec la méthode FindAll native
Write-Host "`n=== Test 5: Comparaison des performances ===" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$nativeResults = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
$stopwatch.Stop()
$nativeTime = $stopwatch.ElapsedMilliseconds
Write-Host "Méthode FindAll native: $nativeTime ms, $($nativeResults.Count) résultats" -ForegroundColor Yellow

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$recursiveResults = Invoke-AstTraversalDFS-Recursive -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
$recursiveTime = $stopwatch.ElapsedMilliseconds
Write-Host "Méthode récursive: $recursiveTime ms, $($recursiveResults.Count) résultats" -ForegroundColor Yellow

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
