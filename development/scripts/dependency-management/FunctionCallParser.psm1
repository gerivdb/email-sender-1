#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'analyse et l'extraction des appels de fonctions dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les scripts PowerShell et extraire
    les appels de fonctions en utilisant l'AST (Abstract Syntax Tree) de PowerShell.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
#>

# Variables globales pour le module
$script:CommonVerbs = @(
    'Add', 'Clear', 'Close', 'Copy', 'Enter', 'Exit', 'Find', 'Format', 'Get', 'Hide',
    'Join', 'Lock', 'Move', 'New', 'Open', 'Optimize', 'Pop', 'Push', 'Redo', 'Remove',
    'Rename', 'Reset', 'Resize', 'Search', 'Select', 'Set', 'Show', 'Skip', 'Split', 'Step',
    'Switch', 'Undo', 'Unlock', 'Watch', 'Backup', 'Checkpoint', 'Compare', 'Compress',
    'Convert', 'ConvertFrom', 'ConvertTo', 'Dismount', 'Edit', 'Expand', 'Export', 'Group',
    'Import', 'Initialize', 'Limit', 'Merge', 'Mount', 'Out', 'Publish', 'Restore', 'Save',
    'Sync', 'Unpublish', 'Update', 'Approve', 'Assert', 'Complete', 'Confirm', 'Deny',
    'Disable', 'Enable', 'Install', 'Invoke', 'Register', 'Request', 'Restart', 'Resume',
    'Start', 'Stop', 'Submit', 'Suspend', 'Uninstall', 'Unregister', 'Wait', 'Debug',
    'Measure', 'Ping', 'Repair', 'Resolve', 'Test', 'Trace', 'Connect', 'Disconnect',
    'Read', 'Receive', 'Send', 'Write', 'Block', 'Grant', 'Protect', 'Revoke', 'Unblock',
    'Unprotect', 'Use', 'ForEach', 'Sort', 'Tee', 'Where'
)

<#
.SYNOPSIS
    Analyse un script PowerShell et extrait tous les appels de fonctions.

.DESCRIPTION
    Cette fonction analyse un script PowerShell en utilisant l'AST (Abstract Syntax Tree)
    et extrait tous les appels de fonctions, y compris les appels directs, les appels
    avec namespace, les appels de mÃ©thodes, etc.

.PARAMETER ScriptPath
    Chemin du script PowerShell Ã  analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell Ã  analyser. Si spÃ©cifiÃ©, ScriptPath est ignorÃ©.

.PARAMETER IncludeMethodCalls
    Indique si les appels de mÃ©thodes doivent Ãªtre inclus dans les rÃ©sultats.

.PARAMETER IncludeStaticMethodCalls
    Indique si les appels de mÃ©thodes statiques doivent Ãªtre inclus dans les rÃ©sultats.

.PARAMETER ExcludeCommonCmdlets
    Indique si les cmdlets communs (comme Get-Item, Set-Location, etc.) doivent Ãªtre exclus des rÃ©sultats.

.EXAMPLE
    $functionCalls = Get-FunctionCalls -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne tous les appels de fonctions.

.EXAMPLE
    $functionCalls = Get-FunctionCalls -ScriptContent $scriptContent -IncludeMethodCalls
    Analyse le contenu du script fourni et retourne tous les appels de fonctions, y compris les appels de mÃ©thodes.

.OUTPUTS
    [PSCustomObject[]] Liste des appels de fonctions dÃ©tectÃ©s.
#>
function Get-FunctionCalls {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMethodCalls,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStaticMethodCalls,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeCommonCmdlets
    )

    begin {
        # VÃ©rifier si au moins un des paramÃ¨tres ScriptPath ou ScriptContent est spÃ©cifiÃ©
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spÃ©cifier soit ScriptPath, soit ScriptContent.'
        }

        # Fonction interne pour vÃ©rifier si une commande est un cmdlet commun
        function Test-CommonCmdlet {
            param (
                [Parameter(Mandatory = $true)]
                [string]$CommandName
            )

            if ($CommandName -match '^([a-zA-Z]+)-([a-zA-Z]+)$') {
                $verb = $matches[1]
                return $script:CommonVerbs -contains $verb
            }

            return $false
        }
    }

    process {
        try {
            # Obtenir l'AST du script
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
                    throw "Le fichier script n'existe pas: $ScriptPath"
                }
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
            }
            else {
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$null, [ref]$null)
            }

            # Initialiser la liste des appels de fonctions
            $functionCalls = [System.Collections.ArrayList]::new()

            # Trouver tous les appels de commandes
            $commandCalls = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst]
            }, $true)

            # Traiter les appels de commandes
            foreach ($command in $commandCalls) {
                $commandName = $null
                $commandElements = $command.CommandElements

                # Obtenir le nom de la commande
                if ($commandElements.Count -gt 0 -and $commandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $commandName = $commandElements[0].Value
                }

                # VÃ©rifier si la commande est un cmdlet commun Ã  exclure
                if ($ExcludeCommonCmdlets -and $commandName -and (Test-CommonCmdlet -CommandName $commandName)) {
                    continue
                }

                # Ajouter l'appel de fonction Ã  la liste
                if ($commandName) {
                    [void]$functionCalls.Add([PSCustomObject]@{
                        Name = $commandName
                        Type = 'Command'
                        Line = $command.Extent.StartLineNumber
                        Column = $command.Extent.StartColumnNumber
                        Text = $command.Extent.Text
                        Parameters = Get-CommandParameters -Command $command
                    })
                }
            }

            # Trouver tous les appels de mÃ©thodes si demandÃ©
            if ($IncludeMethodCalls) {
                $methodCalls = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
                    $node.Member -is [System.Management.Automation.Language.StringConstantExpressionAst]
                }, $true)

                # Traiter les appels de mÃ©thodes
                foreach ($method in $methodCalls) {
                    $methodName = $method.Member.Value
                    $expression = $method.Expression.Extent.Text

                    [void]$functionCalls.Add([PSCustomObject]@{
                        Name = $methodName
                        Type = 'Method'
                        Line = $method.Extent.StartLineNumber
                        Column = $method.Extent.StartColumnNumber
                        Text = $method.Extent.Text
                        Expression = $expression
                        Parameters = Get-MethodParameters -Method $method
                    })
                }
            }

            # Trouver tous les appels de mÃ©thodes statiques si demandÃ©
            if ($IncludeStaticMethodCalls) {
                $staticMethodCalls = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
                    $node.Expression -is [System.Management.Automation.Language.TypeExpressionAst] -and
                    $node.Member -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                    $node.Static
                }, $true)

                # Traiter les appels de mÃ©thodes statiques
                foreach ($method in $staticMethodCalls) {
                    $methodName = $method.Member.Value
                    $typeName = $method.Expression.TypeName.Name

                    [void]$functionCalls.Add([PSCustomObject]@{
                        Name = $methodName
                        Type = 'StaticMethod'
                        Line = $method.Extent.StartLineNumber
                        Column = $method.Extent.StartColumnNumber
                        Text = $method.Extent.Text
                        TypeName = $typeName
                        Parameters = Get-MethodParameters -Method $method
                    })
                }
            }

            return $functionCalls
        }
        catch {
            Write-Error "Erreur lors de l'analyse du script: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Extrait les paramÃ¨tres d'un appel de commande.

.DESCRIPTION
    Cette fonction interne extrait les paramÃ¨tres d'un appel de commande Ã  partir de l'AST.

.PARAMETER Command
    L'AST de la commande Ã  analyser.

.OUTPUTS
    [PSCustomObject[]] Liste des paramÃ¨tres de la commande.
#>
function Get-CommandParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]$Command
    )

    $parameters = [System.Collections.ArrayList]::new()
    $commandElements = $Command.CommandElements

    # Ignorer le premier Ã©lÃ©ment (nom de la commande)
    for ($i = 1; $i -lt $commandElements.Count; $i++) {
        $element = $commandElements[$i]

        # VÃ©rifier si c'est un paramÃ¨tre nommÃ©
        if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
            $paramName = $element.ParameterName

            # VÃ©rifier s'il y a une valeur associÃ©e
            if ($i + 1 -lt $commandElements.Count -and 
                -not ($commandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                $paramValue = $commandElements[$i + 1].Extent.Text
                $i++ # Sauter la valeur du paramÃ¨tre
            }
            else {
                $paramValue = $true # ParamÃ¨tre switch
            }

            [void]$parameters.Add([PSCustomObject]@{
                Name = $paramName
                Value = $paramValue
                Type = 'Named'
            })
        }
        # Sinon, c'est un paramÃ¨tre positionnel
        else {
            [void]$parameters.Add([PSCustomObject]@{
                Name = $null
                Value = $element.Extent.Text
                Type = 'Positional'
            })
        }
    }

    return $parameters
}

<#
.SYNOPSIS
    Extrait les paramÃ¨tres d'un appel de mÃ©thode.

.DESCRIPTION
    Cette fonction interne extrait les paramÃ¨tres d'un appel de mÃ©thode Ã  partir de l'AST.

.PARAMETER Method
    L'AST de la mÃ©thode Ã  analyser.

.OUTPUTS
    [PSCustomObject[]] Liste des paramÃ¨tres de la mÃ©thode.
#>
function Get-MethodParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.InvokeMemberExpressionAst]$Method
    )

    $parameters = [System.Collections.ArrayList]::new()
    $arguments = $Method.Arguments

    # Traiter tous les arguments
    for ($i = 0; $i -lt $arguments.Count; $i++) {
        $argument = $arguments[$i]

        [void]$parameters.Add([PSCustomObject]@{
            Name = $null
            Value = $argument.Extent.Text
            Type = 'Positional'
        })
    }

    return $parameters
}

<#
.SYNOPSIS
    Analyse un script PowerShell et extrait les fonctions dÃ©finies localement.

.DESCRIPTION
    Cette fonction analyse un script PowerShell en utilisant l'AST (Abstract Syntax Tree)
    et extrait toutes les fonctions dÃ©finies localement dans le script.

.PARAMETER ScriptPath
    Chemin du script PowerShell Ã  analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell Ã  analyser. Si spÃ©cifiÃ©, ScriptPath est ignorÃ©.

.EXAMPLE
    $localFunctions = Get-LocalFunctions -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne toutes les fonctions dÃ©finies localement.

.EXAMPLE
    $localFunctions = Get-LocalFunctions -ScriptContent $scriptContent
    Analyse le contenu du script fourni et retourne toutes les fonctions dÃ©finies localement.

.OUTPUTS
    [PSCustomObject[]] Liste des fonctions dÃ©finies localement.
#>
function Get-LocalFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
        [string]$ScriptContent
    )

    begin {
        # VÃ©rifier si au moins un des paramÃ¨tres ScriptPath ou ScriptContent est spÃ©cifiÃ©
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spÃ©cifier soit ScriptPath, soit ScriptContent.'
        }
    }

    process {
        try {
            # Obtenir l'AST du script
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
                    throw "Le fichier script n'existe pas: $ScriptPath"
                }
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
            }
            else {
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$null, [ref]$null)
            }

            # Initialiser la liste des fonctions locales
            $localFunctions = [System.Collections.ArrayList]::new()

            # Trouver toutes les dÃ©finitions de fonctions
            $functionDefinitions = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

            # Traiter les dÃ©finitions de fonctions
            foreach ($function in $functionDefinitions) {
                $functionName = $function.Name
                $functionParameters = $function.Parameters

                # Extraire les paramÃ¨tres de la fonction
                $parameters = [System.Collections.ArrayList]::new()
                foreach ($param in $functionParameters) {
                    [void]$parameters.Add([PSCustomObject]@{
                        Name = $param.Name.VariablePath.UserPath
                        Type = if ($param.StaticType) { $param.StaticType.Name } else { $null }
                        DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
                        Mandatory = $param.Attributes.NamedArguments | Where-Object { $_.ArgumentName -eq 'Mandatory' } | ForEach-Object { $_.Argument.Value }
                    })
                }

                # Ajouter la fonction Ã  la liste
                [void]$localFunctions.Add([PSCustomObject]@{
                    Name = $functionName
                    Line = $function.Extent.StartLineNumber
                    Column = $function.Extent.StartColumnNumber
                    Parameters = $parameters
                    Body = $function.Body.Extent.Text
                })
            }

            return $localFunctions
        }
        catch {
            Write-Error "Erreur lors de l'analyse du script: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Analyse un script PowerShell et extrait les fichiers dot-sourcÃ©s.

.DESCRIPTION
    Cette fonction analyse un script PowerShell en utilisant l'AST (Abstract Syntax Tree)
    et extrait tous les fichiers dot-sourcÃ©s dans le script.

.PARAMETER ScriptPath
    Chemin du script PowerShell Ã  analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell Ã  analyser. Si spÃ©cifiÃ©, ScriptPath est ignorÃ©.

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent Ãªtre rÃ©solus par rapport au rÃ©pertoire du script.

.EXAMPLE
    $dotSourcedFiles = Get-DotSourcedFiles -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne tous les fichiers dot-sourcÃ©s.

.EXAMPLE
    $dotSourcedFiles = Get-DotSourcedFiles -ScriptContent $scriptContent -ResolveRelativePaths
    Analyse le contenu du script fourni et retourne tous les fichiers dot-sourcÃ©s avec les chemins relatifs rÃ©solus.

.OUTPUTS
    [PSCustomObject[]] Liste des fichiers dot-sourcÃ©s.
#>
function Get-DotSourcedFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveRelativePaths
    )

    begin {
        # VÃ©rifier si au moins un des paramÃ¨tres ScriptPath ou ScriptContent est spÃ©cifiÃ©
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spÃ©cifier soit ScriptPath, soit ScriptContent.'
        }
    }

    process {
        try {
            # Obtenir l'AST du script
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
                    throw "Le fichier script n'existe pas: $ScriptPath"
                }
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
                $scriptDir = Split-Path -Path $ScriptPath -Parent
            }
            else {
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$null, [ref]$null)
                $scriptDir = $null
            }

            # Initialiser la liste des fichiers dot-sourcÃ©s
            $dotSourcedFiles = [System.Collections.ArrayList]::new()

            # Trouver tous les appels de commandes
            $commandCalls = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -gt 0 -and
                $node.CommandElements[0].Extent.Text -eq '.'
            }, $true)

            # Traiter les appels de commandes
            foreach ($command in $commandCalls) {
                if ($command.CommandElements.Count -gt 1) {
                    $filePath = $command.CommandElements[1].Extent.Text.Trim("'`"")

                    # RÃ©soudre les chemins relatifs si demandÃ©
                    if ($ResolveRelativePaths -and $scriptDir -and -not [System.IO.Path]::IsPathRooted($filePath)) {
                        $filePath = Join-Path -Path $scriptDir -ChildPath $filePath
                    }

                    [void]$dotSourcedFiles.Add([PSCustomObject]@{
                        Path = $filePath
                        Line = $command.Extent.StartLineNumber
                        Column = $command.Extent.StartColumnNumber
                        Text = $command.Extent.Text
                    })
                }
            }

            return $dotSourcedFiles
        }
        catch {
            Write-Error "Erreur lors de l'analyse du script: $_"
            return @()
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-FunctionCalls, Get-LocalFunctions, Get-DotSourcedFiles
