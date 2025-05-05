# Script de test simple pour les fonctions AST

# Charger les fonctions
. "$PSScriptRoot\..\Public\Invoke-AstTraversalDFS.ps1"

# CrÃ©er un exemple de code PowerShell Ã  analyser
$sampleCode = @'
function Get-Example {
    param (
        [string]$Name
    )
    
    return "Hello, $Name!"
}

function Test-Example {
    param (
        [string]$Input
    )
    
    return $Input -eq "Test"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Invoke-AstTraversalDFS
Write-Host "=== Test de Invoke-AstTraversalDFS ===" -ForegroundColor Cyan
Write-Host "Recherche de toutes les fonctions :" -ForegroundColor Yellow

$functions = Invoke-AstTraversalDFS -Ast $ast -NodeType "FunctionDefinitionAst"
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))"
}

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
