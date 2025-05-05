# Script de test pour la fonction Invoke-AstTraversalDFS

# Charger la fonction
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

$functions = Invoke-AstTraversalDFS -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvÃ©es: $($functions.Count)" -ForegroundColor Yellow

foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
