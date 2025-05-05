<#
.SYNOPSIS
    Convertit un chemin de noeuds en reprÃ©sentation textuelle.

.DESCRIPTION
    Cette fonction convertit un chemin de noeuds (obtenu via Get-AstNodePath) en reprÃ©sentation textuelle.
    Elle permet de personnaliser le format de la reprÃ©sentation textuelle.

.PARAMETER Path
    Le chemin de noeuds Ã  convertir. Peut Ãªtre un tableau de noeuds AST ou un noeud AST unique.

.PARAMETER IncludeTypes
    Si spÃ©cifiÃ©, inclut les types de noeuds dans la reprÃ©sentation textuelle.

.PARAMETER IncludePositions
    Si spÃ©cifiÃ©, inclut les positions (ligne, colonne) des noeuds dans la reprÃ©sentation textuelle.

.PARAMETER Separator
    SÃ©parateur Ã  utiliser pour la reprÃ©sentation textuelle du chemin. Par dÃ©faut, c'est "/".

.PARAMETER Format
    Format Ã  utiliser pour chaque noeud dans la reprÃ©sentation textuelle. Les placeholders suivants sont disponibles :
    - {name} : Nom du noeud
    - {type} : Type du noeud
    - {line} : Ligne du noeud
    - {column} : Colonne du noeud
    - {text} : Texte du noeud

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    $path = Get-AstNodePath -Node $functionNode
    ConvertTo-AstNodePath -Path $path -IncludeTypes

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $variableNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)[0]
    ConvertTo-AstNodePath -Path $variableNode -IncludePositions -Format "{name} ({line},{column})"

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function ConvertTo-AstNodePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTypes,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePositions,

        [Parameter(Mandatory = $false)]
        [string]$Separator = "/",

        [Parameter(Mandatory = $false)]
        [string]$Format = "{name}"
    )

    process {
        try {
            # Initialiser la liste des noeuds du chemin
            $nodes = @()

            # Si le chemin est un noeud unique, obtenir son chemin complet
            if ($Path -is [System.Management.Automation.Language.Ast]) {
                $nodes = Get-AstNodePath -Node $Path
            }
            # Si le chemin est dÃ©jÃ  une liste de noeuds, l'utiliser directement
            elseif ($Path -is [System.Collections.IEnumerable] -and $Path -isnot [string]) {
                $nodes = $Path
            }
            else {
                throw "Le paramÃ¨tre Path doit Ãªtre un noeud AST ou un tableau de noeuds AST."
            }

            # Initialiser la reprÃ©sentation textuelle du chemin
            $pathString = ""

            # Parcourir les noeuds du chemin
            foreach ($node in $nodes) {
                # Obtenir les informations du noeud
                $nodeName = ""
                $nodeType = $node.GetType().Name
                $nodeLine = $node.Extent.StartLineNumber
                $nodeColumn = $node.Extent.StartColumnNumber
                $nodeText = $node.Extent.Text

                # Obtenir le nom du noeud
                if ($node.PSObject.Properties.Name -contains 'Name' -and $null -ne $node.Name) {
                    $nodeName = $node.Name
                }
                elseif ($node -is [System.Management.Automation.Language.VariableExpressionAst]) {
                    $nodeName = $node.VariablePath.UserPath
                }
                elseif ($node -is [System.Management.Automation.Language.CommandAst]) {
                    $nodeName = $node.CommandElements[0].Value
                }
                else {
                    $nodeName = $nodeText.Substring(0, [Math]::Min(20, $nodeText.Length))
                    if ($nodeName.Length -eq 20) {
                        $nodeName += "..."
                    }
                }

                # CrÃ©er la reprÃ©sentation du noeud en fonction du format spÃ©cifiÃ©
                $nodeString = $Format

                # Remplacer les placeholders par les valeurs correspondantes
                $nodeString = $nodeString.Replace("{name}", $nodeName)
                $nodeString = $nodeString.Replace("{type}", $nodeType)
                $nodeString = $nodeString.Replace("{line}", $nodeLine)
                $nodeString = $nodeString.Replace("{column}", $nodeColumn)
                $nodeString = $nodeString.Replace("{text}", $nodeText)

                # Ajouter les types si demandÃ©
                if ($IncludeTypes -and -not $Format.Contains("{type}")) {
                    $nodeString = "$nodeType($nodeString)"
                }

                # Ajouter les positions si demandÃ©
                if ($IncludePositions -and -not ($Format.Contains("{line}") -or $Format.Contains("{column}"))) {
                    $nodeString = "$nodeString ($nodeLine,$nodeColumn)"
                }

                # Ajouter le noeud Ã  la reprÃ©sentation textuelle du chemin
                $pathString += "$nodeString$Separator"
            }

            # Supprimer le dernier sÃ©parateur
            if ($pathString.EndsWith($Separator)) {
                $pathString = $pathString.Substring(0, $pathString.Length - $Separator.Length)
            }

            return $pathString
        }
        catch {
            Write-Error -Message "Erreur lors de la conversion du chemin en reprÃ©sentation textuelle : $_"
            throw
        }
    }
}
