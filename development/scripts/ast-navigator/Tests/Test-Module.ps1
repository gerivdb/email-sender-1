# Script de test pour le module AstNavigator

# Charger directement les fonctions
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Public"

# Charger toutes les fonctions publiques
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath -Filter "*.ps1"
Write-Host "`n=== Chargement des fonctions ===" -ForegroundColor Cyan
Write-Host "Nombre de fonctions trouvées: $($publicFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $publicFunctions) {
    Write-Host "  Chargement de la fonction: $($function.Name)" -ForegroundColor Green
    . $function.FullName
}

# Créer un exemple de code PowerShell à analyser
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
Write-Host "`n=== Test de Invoke-AstTraversalDFS ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalDFS -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvées: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester la fonction Invoke-AstTraversalDFS-Simple
Write-Host "`n=== Test de Invoke-AstTraversalDFS-Simple ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalDFS-Simple -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvées: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
