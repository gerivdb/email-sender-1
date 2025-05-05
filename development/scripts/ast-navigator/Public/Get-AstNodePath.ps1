<#
.SYNOPSIS
    Obtient le chemin complet d'un noeud depuis la racine de l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction retourne le chemin complet d'un noeud depuis la racine de l'arbre syntaxique PowerShell (AST).
    Le chemin est reprÃ©sentÃ© sous forme d'une liste de noeuds, du noeud racine au noeud spÃ©cifiÃ©.

.PARAMETER Node
    Le noeud AST pour lequel on souhaite obtenir le chemin.

.PARAMETER IncludeTypes
    Si spÃ©cifiÃ©, inclut les types de noeuds dans le chemin.

.PARAMETER Separator
    SÃ©parateur Ã  utiliser pour la reprÃ©sentation textuelle du chemin. Par dÃ©faut, c'est "/".

.PARAMETER AsString
    Si spÃ©cifiÃ©, retourne le chemin sous forme de chaÃ®ne de caractÃ¨res plutÃ´t que sous forme de liste de noeuds.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    Get-AstNodePath -Node $functionNode

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $variableNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)[0]
    Get-AstNodePath -Node $variableNode -IncludeTypes -AsString

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstNodePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Node,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTypes,

        [Parameter(Mandatory = $false)]
        [string]$Separator = "/",

        [Parameter(Mandatory = $false)]
        [switch]$AsString
    )

    process {
        try {
            # Initialiser la liste des noeuds du chemin
            $path = New-Object System.Collections.ArrayList

            # Ajouter le noeud courant au chemin
            [void]$path.Add($Node)

            # Remonter l'arbre jusqu'Ã  la racine
            $currentNode = $Node
            while ($null -ne $currentNode.Parent) {
                $currentNode = $currentNode.Parent
                [void]$path.Add($currentNode)
            }

            # Inverser le chemin pour qu'il commence par la racine
            [array]::Reverse($path)

            # Si on veut une reprÃ©sentation textuelle du chemin
            if ($AsString) {
                $pathString = ""
                foreach ($pathNode in $path) {
                    $nodeName = ""

                    # Obtenir le nom du noeud
                    if ($pathNode.PSObject.Properties.Name -contains 'Name' -and $null -ne $pathNode.Name) {
                        $nodeName = $pathNode.Name
                    }
                    elseif ($pathNode -is [System.Management.Automation.Language.VariableExpressionAst]) {
                        $nodeName = $pathNode.VariablePath.UserPath
                    }
                    elseif ($pathNode -is [System.Management.Automation.Language.CommandAst]) {
                        $nodeName = $pathNode.CommandElements[0].Value
                    }
                    else {
                        $nodeName = $pathNode.Extent.Text.Substring(0, [Math]::Min(20, $pathNode.Extent.Text.Length))
                        if ($nodeName.Length -eq 20) {
                            $nodeName += "..."
                        }
                    }

                    # Ajouter le type du noeud si demandÃ©
                    if ($IncludeTypes) {
                        $nodeType = $pathNode.GetType().Name
                        $pathString += "$nodeType($nodeName)$Separator"
                    }
                    else {
                        $pathString += "$nodeName$Separator"
                    }
                }

                # Supprimer le dernier sÃ©parateur
                if ($pathString.EndsWith($Separator)) {
                    $pathString = $pathString.Substring(0, $pathString.Length - $Separator.Length)
                }

                return $pathString
            }

            # Sinon, retourner la liste des noeuds
            return $path
        }
        catch {
            Write-Error -Message "Erreur lors de la recherche du chemin du noeud : $_"
            throw
        }
    }
}
