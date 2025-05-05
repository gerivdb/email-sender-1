# Script de test autonome pour la fonction Get-AstNodeTypeCount

# DÃ©finir la fonction Get-AstNodeTypeCount
function Get-AstNodeTypeCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$NodeType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    process {
        try {
            # Initialiser les compteurs
            $totalCount = 0
            $typeCounts = @{}

            # Fonction pour verifier si un noeud correspond au type specifie
            function Test-NodeType {
                param (
                    [Parameter(Mandatory = $true)]
                    [System.Management.Automation.Language.Ast]$Node,

                    [Parameter(Mandatory = $true)]
                    [string]$Type
                )

                $nodeTypeName = $Node.GetType().Name
                return $nodeTypeName -eq $Type -or $nodeTypeName -eq "${Type}Ast"
            }

            # Fonction pour compter les noeuds
            function Get-NodeCount {
                param (
                    [Parameter(Mandatory = $true)]
                    [System.Management.Automation.Language.Ast]$CurrentNode
                )

                # Obtenir le type du noeud
                $currentNodeType = $CurrentNode.GetType().Name

                # Verifier si le noeud correspond au type specifie
                $includeNode = $true
                if ($NodeType) {
                    $includeNode = Test-NodeType -Node $CurrentNode -Type $NodeType
                }

                # Verifier si le noeud correspond au predicat specifie
                if ($includeNode -and $Predicate) {
                    $includeNode = & $Predicate $CurrentNode
                }

                # Incrementer les compteurs si le noeud correspond aux criteres
                if ($includeNode) {
                    $script:totalCount++
                    
                    # Incrementer le compteur pour ce type de noeud
                    if (-not $script:typeCounts.ContainsKey($currentNodeType)) {
                        $script:typeCounts[$currentNodeType] = 0
                    }
                    $script:typeCounts[$currentNodeType]++
                }

                # Parcourir recursivement les noeuds enfants si demande
                if ($Recurse) {
                    foreach ($child in $CurrentNode.FindAll({ $true }, $false)) {
                        Get-NodeCount -CurrentNode $child
                    }
                }
            }

            # Compter les noeuds
            Get-NodeCount -CurrentNode $Ast

            # Retourner les resultats
            if ($Detailed) {
                # Convertir le hashtable en tableau d'objets
                $typeCountsArray = $typeCounts.GetEnumerator() | ForEach-Object {
                    [PSCustomObject]@{
                        Type = $_.Key
                        Count = $_.Value
                    }
                } | Sort-Object -Property Count -Descending

                return [PSCustomObject]@{
                    TotalCount = $totalCount
                    TypeCounts = $typeCountsArray
                }
            }
            else {
                return $totalCount
            }
        }
        catch {
            Write-Error -Message "Erreur lors du comptage des noeuds : $_"
            throw
        }
    }
}

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
