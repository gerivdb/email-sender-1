#Requires -Version 5.1
<#
.SYNOPSIS
    Extrait les gestionnaires d'Ã©vÃ©nements d'un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell pour dÃ©tecter les gestionnaires d'Ã©vÃ©nements,
    y compris les appels Ã  Register-Event, les Ã©vÃ©nements Add-Type et les gestionnaires WMI.
    Elle retourne des informations dÃ©taillÃ©es sur chaque gestionnaire trouvÃ©.

.PARAMETER Ast
    L'arbre syntaxique PowerShell Ã  analyser. Peut Ãªtre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() 
    ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER Type
    Type de gestionnaire d'Ã©vÃ©nements Ã  rechercher. Les valeurs possibles sont:
    - RegisterEvent: DÃ©tecte les appels Ã  Register-Event et Register-ObjectEvent
    - AddType: DÃ©tecte les Ã©vÃ©nements dÃ©finis via Add-Type
    - WMI: DÃ©tecte les gestionnaires WMI (Register-WmiEvent, Get-WmiObject avec Ã©vÃ©nements)
    - All: DÃ©tecte tous les types de gestionnaires (valeur par dÃ©faut)

.PARAMETER IncludeContent
    Si spÃ©cifiÃ©, inclut le contenu complet de chaque gestionnaire d'Ã©vÃ©nements.

.PARAMETER IncludeScriptBlocks
    Si spÃ©cifiÃ©, inclut les blocs de script associÃ©s aux gestionnaires d'Ã©vÃ©nements.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstEventHandlers -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstEventHandlers -Ast $ast -Type RegisterEvent -IncludeScriptBlocks

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-05-01
#>
function Get-AstEventHandlers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [ValidateSet("RegisterEvent", "AddType", "WMI", "All")]
        [string]$Type = "All",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeScriptBlocks
    )

    process {
        try {
            # Initialiser les rÃ©sultats
            $results = @()

            # Fonction pour extraire les informations d'un bloc de script
            function Get-ScriptBlockInfo {
                param (
                    [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
                )

                if ($null -eq $ScriptBlockAst) {
                    return $null
                }

                return [PSCustomObject]@{
                    Content = $ScriptBlockAst.Extent.Text
                    StartLine = $ScriptBlockAst.Extent.StartLineNumber
                    EndLine = $ScriptBlockAst.Extent.EndLineNumber
                    Variables = $ScriptBlockAst.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) | 
                        Select-Object -ExpandProperty VariablePath | 
                        Select-Object -ExpandProperty UserPath -Unique
                    Commands = $ScriptBlockAst.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) | 
                        Select-Object -ExpandProperty CommandElements | 
                        Where-Object { $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] } | 
                        Select-Object -First 1 -ExpandProperty Value -Unique
                }
            }

            # 1. DÃ©tecter les appels Ã  Register-Event et Register-ObjectEvent
            if ($Type -in @("RegisterEvent", "All")) {
                $registerEventCalls = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].CommandElements.Count -gt 0 -and
                    $args[0].CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                    $args[0].CommandElements[0].Value -in @("Register-Event", "Register-ObjectEvent", "Register-EngineEvent", "Register-CimIndicationEvent")
                }, $true)

                foreach ($call in $registerEventCalls) {
                    $eventHandler = [PSCustomObject]@{
                        Type = "RegisterEvent"
                        Command = $call.CommandElements[0].Value
                        StartLine = $call.Extent.StartLineNumber
                        EndLine = $call.Extent.EndLineNumber
                        Content = if ($IncludeContent) { $call.Extent.Text } else { $null }
                    }

                    # Extraire les paramÃ¨tres
                    $parameters = @{}
                    $currentParam = $null

                    for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                        $element = $call.CommandElements[$i]

                        if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                            $currentParam = $element.ParameterName
                            $parameters[$currentParam] = $true
                        }
                        elseif ($null -ne $currentParam) {
                            $parameters[$currentParam] = $element.Extent.Text
                            $currentParam = $null
                        }
                        elseif ($element -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
                            $parameters["Action"] = $element.Extent.Text
                        }
                    }

                    # Ajouter les paramÃ¨tres Ã  l'objet rÃ©sultat
                    $eventHandler | Add-Member -MemberType NoteProperty -Name "Parameters" -Value $parameters

                    # Extraire le bloc de script si demandÃ©
                    if ($IncludeScriptBlocks) {
                        $scriptBlockParam = $call.CommandElements | 
                            Where-Object { $_ -is [System.Management.Automation.Language.ScriptBlockExpressionAst] } | 
                            Select-Object -First 1

                        if ($scriptBlockParam) {
                            $scriptBlockInfo = Get-ScriptBlockInfo -ScriptBlockAst $scriptBlockParam.ScriptBlock
                            $eventHandler | Add-Member -MemberType NoteProperty -Name "ScriptBlock" -Value $scriptBlockInfo
                        }
                    }

                    $results += $eventHandler
                }
            }

            # 2. DÃ©tecter les Ã©vÃ©nements dÃ©finis via Add-Type
            if ($Type -in @("AddType", "All")) {
                $addTypeCalls = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].CommandElements.Count -gt 0 -and
                    $args[0].CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                    $args[0].CommandElements[0].Value -eq "Add-Type"
                }, $true)

                foreach ($call in $addTypeCalls) {
                    # VÃ©rifier si le code contient des Ã©vÃ©nements
                    $typeDefinition = $null
                    $hasEvents = $false

                    # Extraire la dÃ©finition de type
                    foreach ($element in $call.CommandElements) {
                        if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and 
                            $element.ParameterName -eq "TypeDefinition") {
                            $index = $call.CommandElements.IndexOf($element)
                            if ($index + 1 -lt $call.CommandElements.Count) {
                                $typeDefinition = $call.CommandElements[$index + 1].Extent.Text
                                # VÃ©rifier si la dÃ©finition contient des Ã©vÃ©nements
                                $hasEvents = $typeDefinition -match "event\s+\w+|EventHandler|delegate\s+void"
                            }
                        }
                    }

                    if ($hasEvents) {
                        $eventHandler = [PSCustomObject]@{
                            Type = "AddType"
                            Command = "Add-Type"
                            StartLine = $call.Extent.StartLineNumber
                            EndLine = $call.Extent.EndLineNumber
                            Content = if ($IncludeContent) { $call.Extent.Text } else { $null }
                            TypeDefinition = $typeDefinition
                            EventTypes = [regex]::Matches($typeDefinition, "event\s+(\w+)") | 
                                ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
                        }

                        $results += $eventHandler
                    }
                }
            }

            # 3. DÃ©tecter les gestionnaires WMI
            if ($Type -in @("WMI", "All")) {
                # Rechercher les appels Ã  Register-WmiEvent
                $wmiEventCalls = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].CommandElements.Count -gt 0 -and
                    $args[0].CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                    $args[0].CommandElements[0].Value -in @("Register-WmiEvent", "Register-CimEvent")
                }, $true)

                foreach ($call in $wmiEventCalls) {
                    $eventHandler = [PSCustomObject]@{
                        Type = "WMI"
                        Command = $call.CommandElements[0].Value
                        StartLine = $call.Extent.StartLineNumber
                        EndLine = $call.Extent.EndLineNumber
                        Content = if ($IncludeContent) { $call.Extent.Text } else { $null }
                    }

                    # Extraire les paramÃ¨tres
                    $parameters = @{}
                    $currentParam = $null

                    for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                        $element = $call.CommandElements[$i]

                        if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                            $currentParam = $element.ParameterName
                            $parameters[$currentParam] = $true
                        }
                        elseif ($null -ne $currentParam) {
                            $parameters[$currentParam] = $element.Extent.Text
                            $currentParam = $null
                        }
                        elseif ($element -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
                            $parameters["Action"] = $element.Extent.Text
                        }
                    }

                    # Ajouter les paramÃ¨tres Ã  l'objet rÃ©sultat
                    $eventHandler | Add-Member -MemberType NoteProperty -Name "Parameters" -Value $parameters

                    # Extraire le bloc de script si demandÃ©
                    if ($IncludeScriptBlocks) {
                        $scriptBlockParam = $call.CommandElements | 
                            Where-Object { $_ -is [System.Management.Automation.Language.ScriptBlockExpressionAst] } | 
                            Select-Object -First 1

                        if ($scriptBlockParam) {
                            $scriptBlockInfo = Get-ScriptBlockInfo -ScriptBlockAst $scriptBlockParam.ScriptBlock
                            $eventHandler | Add-Member -MemberType NoteProperty -Name "ScriptBlock" -Value $scriptBlockInfo
                        }
                    }

                    $results += $eventHandler
                }

                # Rechercher les appels Ã  Get-WmiObject avec Ã©vÃ©nements
                $getWmiCalls = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].CommandElements.Count -gt 0 -and
                    $args[0].CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                    $args[0].CommandElements[0].Value -in @("Get-WmiObject", "Get-CimInstance")
                }, $true)

                foreach ($call in $getWmiCalls) {
                    # VÃ©rifier si l'appel contient des paramÃ¨tres liÃ©s aux Ã©vÃ©nements
                    $hasEvents = $false
                    $eventParameters = @{}

                    foreach ($element in $call.CommandElements) {
                        if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and 
                            $element.ParameterName -in @("EnableAllPrivileges", "AsJob")) {
                            $hasEvents = $true
                            $eventParameters[$element.ParameterName] = $true
                        }
                    }

                    # VÃ©rifier si l'appel est utilisÃ© dans un contexte d'Ã©vÃ©nement
                    if (-not $hasEvents) {
                        # VÃ©rifier si l'appel est assignÃ© Ã  une variable utilisÃ©e plus tard avec Register-Event
                        $parent = $call.Parent
                        if ($parent -is [System.Management.Automation.Language.AssignmentStatementAst]) {
                            $variableName = $null
                            if ($parent.Left -is [System.Management.Automation.Language.VariableExpressionAst]) {
                                $variableName = $parent.Left.VariablePath.UserPath
                            }

                            if ($variableName) {
                                # Rechercher les utilisations de cette variable avec Register-Event
                                $registerCalls = $Ast.FindAll({
                                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                                    $args[0].CommandElements.Count -gt 0 -and
                                    $args[0].CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                                    $args[0].CommandElements[0].Value -in @("Register-Event", "Register-ObjectEvent")
                                }, $true)

                                foreach ($registerCall in $registerCalls) {
                                    foreach ($element in $registerCall.CommandElements) {
                                        if ($element -is [System.Management.Automation.Language.VariableExpressionAst] -and
                                            $element.VariablePath.UserPath -eq $variableName) {
                                            $hasEvents = $true
                                            break
                                        }
                                    }
                                    if ($hasEvents) { break }
                                }
                            }
                        }
                    }

                    if ($hasEvents) {
                        $eventHandler = [PSCustomObject]@{
                            Type = "WMI"
                            Command = $call.CommandElements[0].Value
                            StartLine = $call.Extent.StartLineNumber
                            EndLine = $call.Extent.EndLineNumber
                            Content = if ($IncludeContent) { $call.Extent.Text } else { $null }
                            EventParameters = $eventParameters
                        }

                        $results += $eventHandler
                    }
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'extraction des gestionnaires d'Ã©vÃ©nements: $_"
            throw
        }
    }
}
