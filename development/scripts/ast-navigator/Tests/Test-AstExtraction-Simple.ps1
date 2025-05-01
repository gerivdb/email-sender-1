# Script de test simple pour les fonctions d'extraction d'elements specifiques

# Importer les fonctions individuellement
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"
. "$PSScriptRoot\..\Public\Get-AstVariables.ps1"

# Creer un script PowerShell de test tres simple
$sampleCode = @'
function Test-Function {
    param (
        [string]$Name,
        [int]$Count = 0
    )
    
    $result = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $item = [PSCustomObject]@{
            Name = "$Name-$i"
            Value = $i
        }
        $result += $item
    }
    
    return $result
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Test 1: Extraire les fonctions
Write-Host "Test 1: Extraire les fonctions" -ForegroundColor Cyan
$functions = Get-AstFunctions -Ast $ast
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Green
}

# Test 2: Extraire les parametres d'une fonction specifique
Write-Host "`nTest 2: Extraire les parametres d'une fonction specifique" -ForegroundColor Cyan
$functionParams = Get-AstParameters -Ast $ast -FunctionName "Test-Function"
Write-Host "  Nombre de parametres trouves: $($functionParams.Count)" -ForegroundColor Yellow
foreach ($param in $functionParams) {
    Write-Host "    $($param.Name) ($($param.Type))" -ForegroundColor Green
    if ($param.DefaultValue) {
        Write-Host "      Valeur par defaut: $($param.DefaultValue)" -ForegroundColor Green
    }
}

# Test 3: Extraire les variables
Write-Host "`nTest 3: Extraire les variables" -ForegroundColor Cyan
$variables = Get-AstVariables -Ast $ast -ExcludeAutomaticVariables
Write-Host "  Nombre de variables trouvees: $($variables.Count)" -ForegroundColor Yellow
foreach ($var in $variables) {
    $scope = if ($var.Scope) { $var.Scope } else { "Local" }
    Write-Host "    $($scope)`:$($var.Name) (Premiere utilisation: ligne $($var.FirstUsage.Line))" -ForegroundColor Green
}

Write-Host "`nTests termines avec succes!" -ForegroundColor Green
