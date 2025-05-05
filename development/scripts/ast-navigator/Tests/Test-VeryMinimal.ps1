# Script de test trÃ¨s minimal

# CrÃ©er un script PowerShell de test trÃ¨s simple
$sampleCode = @'
function Test-Function {
    "Hello, World!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Compter les fonctions
$functionCount = 0
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) | ForEach-Object {
    $functionCount++
}

# Afficher les rÃ©sultats
Write-Host "Nombre de fonctions trouvees: $functionCount" -ForegroundColor Yellow

# Compter tous les noeuds
$totalCount = 0
$ast.FindAll({ $true }, $true) | ForEach-Object {
    $totalCount++
}

Write-Host "Nombre total de noeuds: $totalCount" -ForegroundColor Yellow

Write-Host "Test termine avec succes!" -ForegroundColor Green
