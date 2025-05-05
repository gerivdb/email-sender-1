# Script de test simple pour la fonction Get-AstNodeTypeCount

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test trÃ¨s simple
$sampleCode = @'
function Test-Function {
    "Hello, World!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Get-AstNodeTypeCount
Write-Host "=== Test de Get-AstNodeTypeCount ===" -ForegroundColor Cyan
$functionCount = Get-AstNodeTypeCount -Ast $ast -NodeType "FunctionDefinition" -Recurse
Write-Host "Nombre de fonctions trouvees: $functionCount" -ForegroundColor Yellow

# Obtenir un rapport dÃ©taillÃ©
$detailedReport = Get-AstNodeTypeCount -Ast $ast -Recurse -Detailed
Write-Host "Nombre total de noeuds: $($detailedReport.TotalCount)" -ForegroundColor Yellow
Write-Host "Repartition par type:" -ForegroundColor Yellow
$detailedReport.TypeCounts | Format-Table -AutoSize

Write-Host "Test termine avec succes!" -ForegroundColor Green
