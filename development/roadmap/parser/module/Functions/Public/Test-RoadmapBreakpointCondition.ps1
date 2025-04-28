<#
.SYNOPSIS
    Ã‰value une condition de point d'arrÃªt.

.DESCRIPTION
    La fonction Test-RoadmapBreakpointCondition Ã©value une condition de point d'arrÃªt
    et retourne un boolÃ©en indiquant si la condition est vraie ou fausse.
    Elle prend en charge les conditions sous forme de chaÃ®ne ou de ScriptBlock.

.PARAMETER Condition
    La condition Ã  Ã©valuer. Peut Ãªtre une expression PowerShell sous forme de chaÃ®ne
    ou un ScriptBlock qui retourne une valeur boolÃ©enne.

.PARAMETER Variables
    Un tableau de variables Ã  rendre disponibles dans le contexte d'Ã©valuation de la condition.

.PARAMETER ThrowOnError
    Indique si une exception doit Ãªtre levÃ©e en cas d'erreur lors de l'Ã©valuation de la condition.
    Par dÃ©faut : $false.

.EXAMPLE
    Test-RoadmapBreakpointCondition -Condition '$i -gt 10'
    Ã‰value si la variable $i est supÃ©rieure Ã  10.

.EXAMPLE
    Test-RoadmapBreakpointCondition -Condition { Test-Path $filePath }
    Ã‰value si le fichier spÃ©cifiÃ© existe.

.EXAMPLE
    $vars = @{ 'count' = 5; 'threshold' = 10 }
    Test-RoadmapBreakpointCondition -Condition '$count -gt $threshold' -Variables $vars
    Ã‰value si la variable count est supÃ©rieure Ã  threshold en utilisant les variables fournies.

.OUTPUTS
    [bool] Un boolÃ©en indiquant si la condition est vraie ou fausse.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

    # DÃ©finir une fonction Write-RoadmapLog locale si elle n'est pas dÃ©jÃ  disponible
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
        # DÃ©terminer le type de condition
        if ($Condition -is [scriptblock]) {
            # Condition sous forme de ScriptBlock
            $result = $false

            # CrÃ©er un nouveau contexte d'exÃ©cution si des variables sont fournies
            if ($Variables -and $Variables.Count -gt 0) {
                # CrÃ©er un nouveau scope pour les variables
                $tempScriptBlock = {
                    param($scriptBlock, $vars)

                    # DÃ©finir les variables dans le scope actuel
                    foreach ($key in $vars.Keys) {
                        Set-Variable -Name $key -Value $vars[$key]
                    }

                    # ExÃ©cuter le ScriptBlock
                    & $scriptBlock
                }

                $result = & $tempScriptBlock $Condition $Variables
            } else {
                # ExÃ©cuter le ScriptBlock directement
                $result = & $Condition
            }

            # Convertir le rÃ©sultat en boolÃ©en
            $result = [bool]$result
        } elseif ($Condition -is [string]) {
            # Condition sous forme de chaÃ®ne
            $scriptBlock = [scriptblock]::Create($Condition)

            # CrÃ©er un nouveau contexte d'exÃ©cution si des variables sont fournies
            if ($Variables -and $Variables.Count -gt 0) {
                # CrÃ©er un nouveau scope pour les variables
                $tempScriptBlock = {
                    param($scriptBlock, $vars)

                    # DÃ©finir les variables dans le scope actuel
                    foreach ($key in $vars.Keys) {
                        Set-Variable -Name $key -Value $vars[$key]
                    }

                    # ExÃ©cuter le ScriptBlock
                    & $scriptBlock
                }

                $result = & $tempScriptBlock $scriptBlock $Variables
            } else {
                # ExÃ©cuter le ScriptBlock directement
                $result = & $scriptBlock
            }

            # Convertir le rÃ©sultat en boolÃ©en
            $result = [bool]$result
        } else {
            # Autre type de condition (considÃ©rer comme un boolÃ©en)
            $result = [bool]$Condition
        }

        return $result
    } catch {
        $errorMessage = "Erreur lors de l'Ã©valuation de la condition : $($_.Exception.Message)"
        Write-RoadmapLog -Message $errorMessage -Level "Error" -Category "Breakpoint"

        if ($ThrowOnError) {
            throw $_
        }

        return $false
    }
}
