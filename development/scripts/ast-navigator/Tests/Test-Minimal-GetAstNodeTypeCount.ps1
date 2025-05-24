# Script de test minimal pour la fonction Get-AstNodeTypeCount

# CrÃ©er un script PowerShell de test trÃ¨s simple
$sampleCode = @'
function Test-Function {
    "Hello, World!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# DÃ©finir une fonction simple pour compter les noeuds
function Measure-Nodes {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,
        
        [Parameter(Mandatory = $false)]
        [string]$NodeType
    )
    
    $count = 0
    
    # Fonction rÃ©cursive pour parcourir l'AST
    function Invoke-Node {
        param (
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.Language.Ast]$Node
        )
        
        # VÃ©rifier si le noeud correspond au type spÃ©cifiÃ©
        if ($NodeType) {
            $nodeTypeName = $Node.GetType().Name
            if ($nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast") {
                $script:count++
            }
        }
        else {
            $script:count++
        }
        
        # Parcourir les noeuds enfants
        foreach ($child in $Node.FindAll({ $true }, $false)) {
            Invoke-Node -Node $child
        }
    }
    
    # Compter les noeuds
    Invoke-Node -Node $Ast
    
    return $count
}

# Tester la fonction Measure-Nodes
Write-Host "=== Test de Measure-Nodes ===" -ForegroundColor Cyan
$functionCount = Measure-Nodes -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $functionCount" -ForegroundColor Yellow

$totalCount = Measure-Nodes -Ast $ast
Write-Host "Nombre total de noeuds: $totalCount" -ForegroundColor Yellow

Write-Host "Test termine avec succes!" -ForegroundColor Green


