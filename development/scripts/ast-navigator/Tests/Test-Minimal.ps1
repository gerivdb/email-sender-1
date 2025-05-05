# Script de test minimal pour l'AST PowerShell

# CrÃ©er un exemple de code PowerShell Ã  analyser
$sampleCode = @'
function Get-Example {
    param (
        [string]$Name
    )
    
    return "Hello, $Name!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Afficher les informations sur l'AST
Write-Host "=== Informations sur l'AST ===" -ForegroundColor Cyan
Write-Host "Type de l'AST racine: $($ast.GetType().Name)" -ForegroundColor Yellow

# Rechercher manuellement les fonctions
$functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
Write-Host "Nombre de fonctions trouvÃ©es: $($functions.Count)" -ForegroundColor Yellow

foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
