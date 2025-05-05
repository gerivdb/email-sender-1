# Script de test pour la fonction Invoke-AstTraversalDFS-Recursive

# Charger la fonction
. "$PSScriptRoot\..\Public\Invoke-AstTraversalDFS-Recursive.ps1"

# CrÃ©er un exemple de code PowerShell Ã  analyser
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

# VÃ©rifier s'il y a des erreurs d'analyse
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
Write-Host "Nombre de fonctions trouvÃ©es: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 2: Recherche de toutes les variables avec limite de profondeur
Write-Host "`n=== Test 2: Recherche de toutes les variables avec limite de profondeur 3 ===" -ForegroundColor Cyan
$variables = Invoke-AstTraversalDFS-Recursive -Ast $ast -NodeType "VariableExpression" -MaxDepth 3
Write-Host "Nombre de variables trouvÃ©es: $($variables.Count)" -ForegroundColor Yellow
$uniqueVars = @{}
foreach ($variable in $variables) {
    $varName = $variable.VariablePath.UserPath
    if (-not $uniqueVars.ContainsKey($varName)) {
        $uniqueVars[$varName] = $true
        Write-Host "  Variable: `$$varName (Ligne $($variable.Extent.StartLineNumber))" -ForegroundColor Green
    }
}

# Test 3: Recherche avec prÃ©dicat personnalisÃ©
Write-Host "`n=== Test 3: Recherche avec prÃ©dicat personnalisÃ© ===" -ForegroundColor Cyan
$predicate = {
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -like "Get-*"
}
$getFunctions = Invoke-AstTraversalDFS-Recursive -Ast $ast -Predicate $predicate
Write-Host "Nombre de fonctions 'Get-*' trouvÃ©es: $($getFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $getFunctions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 4: Recherche avec inclusion du nÅ“ud racine
Write-Host "`n=== Test 4: Recherche avec inclusion du nÅ“ud racine ===" -ForegroundColor Cyan
$rootIncluded = Invoke-AstTraversalDFS-Recursive -Ast $ast -IncludeRoot
Write-Host "Type du nÅ“ud racine: $($ast.GetType().Name)" -ForegroundColor Yellow
Write-Host "Nombre de nÅ“uds trouvÃ©s (avec racine): $($rootIncluded.Count)" -ForegroundColor Yellow
Write-Host "Premier nÅ“ud: $($rootIncluded[0].GetType().Name)" -ForegroundColor Green

# Test 5: Comparaison des performances avec la mÃ©thode FindAll native
Write-Host "`n=== Test 5: Comparaison des performances ===" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$nativeResults = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
$stopwatch.Stop()
$nativeTime = $stopwatch.ElapsedMilliseconds
Write-Host "MÃ©thode FindAll native: $nativeTime ms, $($nativeResults.Count) rÃ©sultats" -ForegroundColor Yellow

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$recursiveResults = Invoke-AstTraversalDFS-Recursive -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
$recursiveTime = $stopwatch.ElapsedMilliseconds
Write-Host "MÃ©thode rÃ©cursive: $recursiveTime ms, $($recursiveResults.Count) rÃ©sultats" -ForegroundColor Yellow

Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
