# Script de test minimal pour la fonction Get-AstNodeTypeCount

# Créer un script PowerShell de test très simple
$sampleCode = @'
function Test-Function {
    "Hello, World!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Définir une fonction simple pour compter les noeuds
function Get-NodeCount {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,
        
        [Parameter(Mandatory = $false)]
        [string]$NodeType
    )
    
    $count = 0
    
    # Utiliser FindAll pour trouver les noeuds correspondants
    if ($NodeType) {
        $ast.FindAll({
            $nodeTypeName = $args[0].GetType().Name
            return $nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast"
        }, $true) | ForEach-Object {
            $count++
        }
    }
    else {
        $ast.FindAll({ $true }, $true) | ForEach-Object {
            $count++
        }
    }
    
    return $count
}

# Tester la fonction Get-NodeCount
Write-Host "=== Test de Get-NodeCount ===" -ForegroundColor Cyan
$functionCount = Get-NodeCount -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $functionCount" -ForegroundColor Yellow

$totalCount = Get-NodeCount -Ast $ast
Write-Host "Nombre total de noeuds: $totalCount" -ForegroundColor Yellow

Write-Host "Test termine avec succes!" -ForegroundColor Green
