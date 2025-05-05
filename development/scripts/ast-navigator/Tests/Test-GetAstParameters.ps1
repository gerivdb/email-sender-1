# Script de test pour la fonction Get-AstParameters

# Importer la fonction
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"

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

# Tester la fonction Get-AstParameters
Write-Host "=== Test de Get-AstParameters ===" -ForegroundColor Cyan
$parameters = Get-AstParameters -Ast $ast -FunctionName "Test-Function"
Write-Host "Nombre de parametres trouves: $($parameters.Count)" -ForegroundColor Yellow
foreach ($param in $parameters) {
    Write-Host "  $($param.Name) ($($param.Type))" -ForegroundColor Green
    if ($param.DefaultValue) {
        Write-Host "    Valeur par defaut: $($param.DefaultValue)" -ForegroundColor Green
    }
}

Write-Host "Test termine avec succes!" -ForegroundColor Green
