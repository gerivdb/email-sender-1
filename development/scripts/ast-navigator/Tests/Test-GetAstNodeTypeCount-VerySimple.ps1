# Script de test très simple pour la fonction Get-AstNodeTypeCount

# Définir la fonction Get-AstNodeTypeCount
function Get-AstNodeTypeCount {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,
        
        [Parameter(Mandatory = $false)]
        [string]$NodeType,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )
    
    $count = 0
    
    # Fonction récursive pour parcourir l'AST
    function Process-Node {
        param (
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.Language.Ast]$Node
        )
        
        # Vérifier si le noeud correspond au type spécifié
        if ($NodeType) {
            $nodeTypeName = $Node.GetType().Name
            if ($nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast") {
                $script:count++
            }
        }
        else {
            $script:count++
        }
        
        # Parcourir les noeuds enfants si demandé
        if ($Recurse) {
            foreach ($child in $Node.FindAll({ $true }, $false)) {
                Process-Node -Node $child
            }
        }
    }
    
    # Compter les noeuds
    Process-Node -Node $Ast
    
    return $count
}

# Créer un script PowerShell de test très simple
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

$totalCount = Get-AstNodeTypeCount -Ast $ast -Recurse
Write-Host "Nombre total de noeuds: $totalCount" -ForegroundColor Yellow

Write-Host "Test termine avec succes!" -ForegroundColor Green
