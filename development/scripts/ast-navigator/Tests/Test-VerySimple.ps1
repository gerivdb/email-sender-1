# Script de test tres simple

# Creer un script PowerShell de test tres simple
$sampleCode = @'
function Test-Function {
    param (
        [string]$Name,
        [int]$Count = 0
    )
    
    "Hello, $Name!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Rechercher les fonctions
$functions = $ast.FindAll({
    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true)

# Afficher les fonctions trouvees
Write-Host "=== Fonctions trouvees ===" -ForegroundColor Cyan
Write-Host "Nombre de fonctions: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  $($function.Name) (Lignes $($function.Extent.StartLineNumber)-$($function.Extent.EndLineNumber))" -ForegroundColor Green
}

# Rechercher les parametres de la fonction
$function = $functions[0]
$paramBlock = $function.Body.ParamBlock
$parameters = $paramBlock.Parameters

# Afficher les parametres trouves
Write-Host "`n=== Parametres trouves ===" -ForegroundColor Cyan
Write-Host "Nombre de parametres: $($parameters.Count)" -ForegroundColor Yellow
foreach ($param in $parameters) {
    $paramName = $param.Name.VariablePath.UserPath
    $paramType = if ($param.StaticType) { $param.StaticType.Name } else { "object" }
    $defaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { "N/A" }
    
    Write-Host "  $paramName ($paramType) = $defaultValue" -ForegroundColor Green
}

Write-Host "`nTest termine avec succes!" -ForegroundColor Green
