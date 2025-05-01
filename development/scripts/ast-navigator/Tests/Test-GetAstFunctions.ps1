# Script de test pour la fonction Get-AstFunctions

# Importer la fonction
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"

# Creer un script PowerShell de test tres simple
$sampleCode = @'
function Test-Function {
    "Hello, World!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Get-AstFunctions
Write-Host "=== Test de Get-AstFunctions ===" -ForegroundColor Cyan
$functions = Get-AstFunctions -Ast $ast
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Green
}

Write-Host "Test termine avec succes!" -ForegroundColor Green
