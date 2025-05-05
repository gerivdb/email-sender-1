# Script de test simple pour la fonction Invoke-AstTraversalDFS-Optimized

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test trÃ¨s simple
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
    
    if ($Input -eq "Test") {
        return $true
    }
    else {
        return $false
    }
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Invoke-AstTraversalDFS-Optimized
Write-Host "=== Test de Invoke-AstTraversalDFS-Optimized ===" -ForegroundColor Cyan
Write-Host "Recherche de toutes les fonctions :" -ForegroundColor Yellow

$functions = Invoke-AstTraversalDFS-Optimized -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow

foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Comparer avec la version prÃ©cÃ©dente
Write-Host "`n=== Comparaison avec Invoke-AstTraversalDFS-Enhanced ===" -ForegroundColor Cyan

$functions = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow

foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

Write-Host "`nTest termine avec succes!" -ForegroundColor Green
