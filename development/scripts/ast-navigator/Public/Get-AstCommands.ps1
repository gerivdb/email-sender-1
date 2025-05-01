<#
.SYNOPSIS
    Extrait les appels de commandes d'un script PowerShell.

.DESCRIPTION
    Cette fonction extrait les appels de commandes d'un script PowerShell en utilisant l'arbre syntaxique (AST).
    Elle permet de filtrer les commandes par nom et d'obtenir des informations détaillées sur chaque commande.

.PARAMETER Ast
    L'arbre syntaxique PowerShell à analyser. Peut être obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER Name
    Nom de la commande à rechercher. Peut contenir des caractères génériques.

.PARAMETER CommandType
    Type de commande à rechercher (Cmdlet, Function, ExternalScript, Application, etc.).

.PARAMETER IncludeArguments
    Si spécifié, inclut les arguments passés à chaque commande.

.PARAMETER IncludePipelines
    Si spécifié, inclut les informations sur les pipelines de commandes.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstCommands -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstCommands -Ast $ast -Name "Get-*" -IncludeArguments

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstCommands {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Cmdlet", "Function", "ExternalScript", "Application", "All")]
        [string]$CommandType = "All",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeArguments,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePipelines
    )

    process {
        try {
            # Rechercher tous les appels de commandes dans l'AST
            $commands = $Ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst]
            }, $true)

            # Filtrer par nom si spécifié
            if ($Name) {
                $commands = $commands | Where-Object { 
                    $commandName = $_.CommandElements[0].Value
                    $commandName -like $Name 
                }
            }

            # Rechercher les pipelines si demandé
            $pipelines = @{}
            if ($IncludePipelines) {
                $pipelineAsts = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.PipelineAst]
                }, $true)

                foreach ($pipeline in $pipelineAsts) {
                    foreach ($pipelineElement in $pipeline.PipelineElements) {
                        if ($pipelineElement -is [System.Management.Automation.Language.CommandAst]) {
                            $commandId = $pipelineElement.Extent.StartOffset
                            $pipelineId = $pipeline.Extent.StartOffset
                            
                            if (-not $pipelines.ContainsKey($commandId)) {
                                $pipelines[$commandId] = @{
                                    PipelineId = $pipelineId
                                    Position = [array]::IndexOf($pipeline.PipelineElements, $pipelineElement)
                                    TotalCommands = $pipeline.PipelineElements.Count
                                }
                            }
                        }
                    }
                }
            }

            # Préparer les résultats
            $results = @()

            # Traiter chaque commande
            foreach ($command in $commands) {
                # Extraire le nom de la commande
                $commandName = $command.CommandElements[0].Value

                # Extraire les arguments si demandé
                $arguments = @()
                if ($IncludeArguments -and $command.CommandElements.Count -gt 1) {
                    for ($i = 1; $i -lt $command.CommandElements.Count; $i++) {
                        $element = $command.CommandElements[$i]
                        
                        # Déterminer si c'est un paramètre ou une valeur
                        $isParameter = $false
                        $parameterName = $null
                        $value = $null
                        
                        if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                            $isParameter = $true
                            $parameterName = $element.ParameterName
                            if ($element.Argument) {
                                $value = $element.Argument.Extent.Text
                            }
                        }
                        else {
                            $value = $element.Extent.Text
                        }
                        
                        $argumentInfo = [PSCustomObject]@{
                            IsParameter = $isParameter
                            ParameterName = $parameterName
                            Value = $value
                            Position = $i - 1  # Position 0-based par rapport au premier argument
                        }
                        
                        $arguments += $argumentInfo
                    }
                }

                # Extraire les informations de pipeline si demandé
                $pipelineInfo = $null
                if ($IncludePipelines) {
                    $commandId = $command.Extent.StartOffset
                    if ($pipelines.ContainsKey($commandId)) {
                        $pipelineInfo = [PSCustomObject]@{
                            PipelineId = $pipelines[$commandId].PipelineId
                            Position = $pipelines[$commandId].Position
                            TotalCommands = $pipelines[$commandId].TotalCommands
                            IsFirst = $pipelines[$commandId].Position -eq 0
                            IsLast = $pipelines[$commandId].Position -eq ($pipelines[$commandId].TotalCommands - 1)
                        }
                    }
                }

                # Créer l'objet résultat
                $commandInfo = [PSCustomObject]@{
                    Name = $commandName
                    StartLine = $command.Extent.StartLineNumber
                    EndLine = $command.Extent.EndLineNumber
                    Arguments = if ($IncludeArguments) { $arguments } else { $null }
                    Pipeline = $pipelineInfo
                }

                $results += $commandInfo
            }

            return $results
        }
        catch {
            Write-Error -Message "Erreur lors de l'extraction des commandes : $_"
            throw
        }
    }
}
