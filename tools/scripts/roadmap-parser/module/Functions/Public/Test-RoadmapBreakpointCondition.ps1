<#
.SYNOPSIS
    Évalue une condition de point d'arrêt.

.DESCRIPTION
    La fonction Test-RoadmapBreakpointCondition évalue une condition de point d'arrêt
    et retourne un booléen indiquant si la condition est vraie ou fausse.
    Elle prend en charge les conditions sous forme de chaîne ou de ScriptBlock.

.PARAMETER Condition
    La condition à évaluer. Peut être une expression PowerShell sous forme de chaîne
    ou un ScriptBlock qui retourne une valeur booléenne.

.PARAMETER Variables
    Un tableau de variables à rendre disponibles dans le contexte d'évaluation de la condition.

.PARAMETER ThrowOnError
    Indique si une exception doit être levée en cas d'erreur lors de l'évaluation de la condition.
    Par défaut : $false.

.EXAMPLE
    Test-RoadmapBreakpointCondition -Condition '$i -gt 10'
    Évalue si la variable $i est supérieure à 10.

.EXAMPLE
    Test-RoadmapBreakpointCondition -Condition { Test-Path $filePath }
    Évalue si le fichier spécifié existe.

.EXAMPLE
    $vars = @{ 'count' = 5; 'threshold' = 10 }
    Test-RoadmapBreakpointCondition -Condition '$count -gt $threshold' -Variables $vars
    Évalue si la variable count est supérieure à threshold en utilisant les variables fournies.

.OUTPUTS
    [bool] Un booléen indiquant si la condition est vraie ou fausse.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>
function Test-RoadmapBreakpointCondition {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Condition,

        [Parameter(Mandatory = $false)]
        [hashtable]$Variables,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError
    )

    # Définir une fonction Write-RoadmapLog locale si elle n'est pas déjà disponible
    if (-not (Get-Command -Name Write-RoadmapLog -ErrorAction SilentlyContinue)) {
        function Write-RoadmapLog {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Message,

                [Parameter(Mandatory = $false)]
                [string]$Level = "Information",

                [Parameter(Mandatory = $false)]
                [string]$Category = "General"
            )

            Write-Verbose "[$Level] [$Category] $Message"
        }
    }

    try {
        # Déterminer le type de condition
        if ($Condition -is [scriptblock]) {
            # Condition sous forme de ScriptBlock
            $result = $false

            # Créer un nouveau contexte d'exécution si des variables sont fournies
            if ($Variables -and $Variables.Count -gt 0) {
                # Créer un nouveau scope pour les variables
                $tempScriptBlock = {
                    param($scriptBlock, $vars)

                    # Définir les variables dans le scope actuel
                    foreach ($key in $vars.Keys) {
                        Set-Variable -Name $key -Value $vars[$key]
                    }

                    # Exécuter le ScriptBlock
                    & $scriptBlock
                }

                $result = & $tempScriptBlock $Condition $Variables
            } else {
                # Exécuter le ScriptBlock directement
                $result = & $Condition
            }

            # Convertir le résultat en booléen
            $result = [bool]$result
        } elseif ($Condition -is [string]) {
            # Condition sous forme de chaîne
            $scriptBlock = [scriptblock]::Create($Condition)

            # Créer un nouveau contexte d'exécution si des variables sont fournies
            if ($Variables -and $Variables.Count -gt 0) {
                # Créer un nouveau scope pour les variables
                $tempScriptBlock = {
                    param($scriptBlock, $vars)

                    # Définir les variables dans le scope actuel
                    foreach ($key in $vars.Keys) {
                        Set-Variable -Name $key -Value $vars[$key]
                    }

                    # Exécuter le ScriptBlock
                    & $scriptBlock
                }

                $result = & $tempScriptBlock $scriptBlock $Variables
            } else {
                # Exécuter le ScriptBlock directement
                $result = & $scriptBlock
            }

            # Convertir le résultat en booléen
            $result = [bool]$result
        } else {
            # Autre type de condition (considérer comme un booléen)
            $result = [bool]$Condition
        }

        return $result
    } catch {
        $errorMessage = "Erreur lors de l'évaluation de la condition : $($_.Exception.Message)"
        Write-RoadmapLog -Message $errorMessage -Level "Error" -Category "Breakpoint"

        if ($ThrowOnError) {
            throw $_
        }

        return $false
    }
}
