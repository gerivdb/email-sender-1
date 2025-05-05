#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour la dÃ©tection des fonctions importÃ©es dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour dÃ©tecter les modules importÃ©s et les fonctions
    exportÃ©es par ces modules dans les scripts PowerShell.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
#>

# Importer le module FunctionCallParser s'il n'est pas dÃ©jÃ  importÃ©
$functionCallParserPath = Join-Path -Path $PSScriptRoot -ChildPath 'FunctionCallParser.psm1'
if (-not (Get-Module -Name 'FunctionCallParser')) {
    if (Test-Path -Path $functionCallParserPath) {
        Import-Module -Name $functionCallParserPath -Force
    }
    else {
        throw "Le module FunctionCallParser est requis mais n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $functionCallParserPath"
    }
}

<#
.SYNOPSIS
    DÃ©tecte les modules importÃ©s dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et dÃ©tecte tous les modules importÃ©s
    via Import-Module, using module, #Requires -Modules, etc.

.PARAMETER ScriptPath
    Chemin du script PowerShell Ã  analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell Ã  analyser. Si spÃ©cifiÃ©, ScriptPath est ignorÃ©.

.PARAMETER IncludeRequiresDirectives
    Indique si les directives #Requires -Modules doivent Ãªtre incluses dans les rÃ©sultats.

.PARAMETER IncludeUsingStatements
    Indique si les instructions using module doivent Ãªtre incluses dans les rÃ©sultats.

.EXAMPLE
    $importedModules = Get-ImportedModules -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne tous les modules importÃ©s.

.EXAMPLE
    $importedModules = Get-ImportedModules -ScriptContent $scriptContent -IncludeRequiresDirectives
    Analyse le contenu du script fourni et retourne tous les modules importÃ©s, y compris ceux spÃ©cifiÃ©s dans les directives #Requires.

.OUTPUTS
    [PSCustomObject[]] Liste des modules importÃ©s.
#>
function Get-ImportedModules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRequiresDirectives,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeUsingStatements
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

            # Initialiser la liste des modules importÃ©s
            $importedModules = [System.Collections.ArrayList]::new()

            # Trouver tous les appels Ã  Import-Module
            $importModuleCalls = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -gt 0 -and
                $node.CommandElements[0].Extent.Text -eq 'Import-Module'
            }, $true)

            # Traiter les appels Ã  Import-Module
            foreach ($call in $importModuleCalls) {
                $moduleName = $null
                $moduleVersion = $null
                $prefix = $null
                $alias = $null

                # Parcourir les Ã©lÃ©ments de la commande
                for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                    $element = $call.CommandElements[$i]

                    # VÃ©rifier si c'est un paramÃ¨tre nommÃ©
                    if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                        $paramName = $element.ParameterName.ToLower()

                        # VÃ©rifier s'il y a une valeur associÃ©e
                        if ($i + 1 -lt $call.CommandElements.Count -and 
                            -not ($call.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                            $paramValue = $call.CommandElements[$i + 1].Extent.Text.Trim("'`"")
                            
                            switch ($paramName) {
                                'name' { $moduleName = $paramValue; break }
                                'modulename' { $moduleName = $paramValue; break }
                                'version' { $moduleVersion = $paramValue; break }
                                'prefix' { $prefix = $paramValue; break }
                                'alias' { $alias = $paramValue; break }
                            }
                            
                            $i++ # Sauter la valeur du paramÃ¨tre
                        }
                    }
                    # Sinon, c'est un paramÃ¨tre positionnel (probablement le nom du module)
                    elseif (-not $moduleName) {
                        $moduleName = $element.Extent.Text.Trim("'`"")
                    }
                }

                # Ajouter le module Ã  la liste
                if ($moduleName) {
                    [void]$importedModules.Add([PSCustomObject]@{
                        Name = $moduleName
                        Version = $moduleVersion
                        Prefix = $prefix
                        Alias = $alias
                        Type = 'ImportModule'
                        Line = $call.Extent.StartLineNumber
                        Column = $call.Extent.StartColumnNumber
                        Text = $call.Extent.Text
                    })
                }
            }

            # Trouver toutes les instructions using module si demandÃ©
            if ($IncludeUsingStatements) {
                $usingStatements = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.UsingStatementAst] -and
                    $node.UsingStatementKind -eq [System.Management.Automation.Language.UsingStatementKind]::Module
                }, $true)

                # Traiter les instructions using module
                foreach ($statement in $usingStatements) {
                    $moduleName = $statement.Name.Value

                    [void]$importedModules.Add([PSCustomObject]@{
                        Name = $moduleName
                        Version = $null
                        Prefix = $null
                        Alias = $null
                        Type = 'UsingModule'
                        Line = $statement.Extent.StartLineNumber
                        Column = $statement.Extent.StartColumnNumber
                        Text = $statement.Extent.Text
                    })
                }
            }

            # Trouver toutes les directives #Requires -Modules si demandÃ©
            if ($IncludeRequiresDirectives -and $ast.ScriptRequirements -and $ast.ScriptRequirements.RequiredModules) {
                foreach ($requiredModule in $ast.ScriptRequirements.RequiredModules) {
                    $moduleName = $requiredModule.Name
                    $moduleVersion = $requiredModule.Version

                    [void]$importedModules.Add([PSCustomObject]@{
                        Name = $moduleName
                        Version = $moduleVersion
                        Prefix = $null
                        Alias = $null
                        Type = 'RequiresModule'
                        Line = $ast.ScriptRequirements.Extent.StartLineNumber
                        Column = $ast.ScriptRequirements.Extent.StartColumnNumber
                        Text = "#Requires -Modules $moduleName"
                    })
                }
            }

            return $importedModules
        }
        catch {
            Write-Error "Erreur lors de la dÃ©tection des modules importÃ©s: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Obtient les fonctions exportÃ©es par un module PowerShell.

.DESCRIPTION
    Cette fonction obtient la liste des fonctions exportÃ©es par un module PowerShell
    en important le module et en interrogeant ses fonctions exportÃ©es.

.PARAMETER ModuleName
    Nom du module PowerShell.

.PARAMETER ModuleVersion
    Version du module PowerShell. Si non spÃ©cifiÃ©, la derniÃ¨re version disponible est utilisÃ©e.

.PARAMETER ImportIfNotLoaded
    Indique si le module doit Ãªtre importÃ© s'il n'est pas dÃ©jÃ  chargÃ©.

.PARAMETER IncludeCmdlets
    Indique si les cmdlets doivent Ãªtre inclus dans les rÃ©sultats.

.PARAMETER IncludeAliases
    Indique si les alias doivent Ãªtre inclus dans les rÃ©sultats.

.EXAMPLE
    $exportedFunctions = Get-ModuleExportedFunctions -ModuleName 'Microsoft.PowerShell.Management'
    Obtient les fonctions exportÃ©es par le module Microsoft.PowerShell.Management.

.EXAMPLE
    $exportedFunctions = Get-ModuleExportedFunctions -ModuleName 'Az.Storage' -ModuleVersion '2.0.0' -IncludeCmdlets -IncludeAliases
    Obtient les fonctions, cmdlets et alias exportÃ©s par le module Az.Storage version 2.0.0.

.OUTPUTS
    [PSCustomObject[]] Liste des fonctions exportÃ©es par le module.
#>
function Get-ModuleExportedFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$ModuleVersion,

        [Parameter(Mandatory = $false)]
        [switch]$ImportIfNotLoaded,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCmdlets,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAliases
    )

    process {
        try {
            # VÃ©rifier si le module est dÃ©jÃ  chargÃ©
            $moduleInfo = $null
            if ($ModuleVersion) {
                $moduleInfo = Get-Module -Name $ModuleName -RequiredVersion $ModuleVersion -ErrorAction SilentlyContinue
            }
            else {
                $moduleInfo = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
            }

            # Importer le module s'il n'est pas dÃ©jÃ  chargÃ© et si demandÃ©
            if (-not $moduleInfo -and $ImportIfNotLoaded) {
                $importParams = @{
                    Name = $ModuleName
                    ErrorAction = 'Stop'
                    PassThru = $true
                }

                if ($ModuleVersion) {
                    $importParams['RequiredVersion'] = $ModuleVersion
                }

                $moduleInfo = Import-Module @importParams
            }

            # VÃ©rifier si le module est chargÃ©
            if (-not $moduleInfo) {
                # Essayer de trouver le module sans l'importer
                $moduleParams = @{
                    Name = $ModuleName
                    ListAvailable = $true
                    ErrorAction = 'SilentlyContinue'
                }

                if ($ModuleVersion) {
                    $moduleParams['RequiredVersion'] = $ModuleVersion
                }

                $moduleInfo = Get-Module @moduleParams | Select-Object -First 1

                if (-not $moduleInfo) {
                    Write-Warning "Le module '$ModuleName' n'est pas chargÃ© et n'a pas Ã©tÃ© trouvÃ©. Utilisez ImportIfNotLoaded pour l'importer automatiquement."
                    return @()
                }
            }

            # Initialiser la liste des fonctions exportÃ©es
            $exportedFunctions = [System.Collections.ArrayList]::new()

            # Obtenir les fonctions exportÃ©es
            $functions = $moduleInfo.ExportedFunctions.Values
            foreach ($function in $functions) {
                [void]$exportedFunctions.Add([PSCustomObject]@{
                    Name = $function.Name
                    Type = 'Function'
                    Module = $moduleInfo.Name
                    ModuleVersion = $moduleInfo.Version
                })
            }

            # Obtenir les cmdlets exportÃ©s si demandÃ©
            if ($IncludeCmdlets) {
                $cmdlets = $moduleInfo.ExportedCmdlets.Values
                foreach ($cmdlet in $cmdlets) {
                    [void]$exportedFunctions.Add([PSCustomObject]@{
                        Name = $cmdlet.Name
                        Type = 'Cmdlet'
                        Module = $moduleInfo.Name
                        ModuleVersion = $moduleInfo.Version
                    })
                }
            }

            # Obtenir les alias exportÃ©s si demandÃ©
            if ($IncludeAliases) {
                $aliases = $moduleInfo.ExportedAliases.Values
                foreach ($alias in $aliases) {
                    [void]$exportedFunctions.Add([PSCustomObject]@{
                        Name = $alias.Name
                        Type = 'Alias'
                        ResolvedCommand = $alias.ResolvedCommand.Name
                        Module = $moduleInfo.Name
                        ModuleVersion = $moduleInfo.Version
                    })
                }
            }

            return $exportedFunctions
        }
        catch {
            Write-Error "Erreur lors de l'obtention des fonctions exportÃ©es par le module '$ModuleName': $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    DÃ©tecte les fonctions importÃ©es dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et dÃ©tecte toutes les fonctions importÃ©es
    via les modules importÃ©s dans le script.

.PARAMETER ScriptPath
    Chemin du script PowerShell Ã  analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell Ã  analyser. Si spÃ©cifiÃ©, ScriptPath est ignorÃ©.

.PARAMETER ImportModulesIfNotLoaded
    Indique si les modules doivent Ãªtre importÃ©s s'ils ne sont pas dÃ©jÃ  chargÃ©s.

.PARAMETER IncludeCmdlets
    Indique si les cmdlets doivent Ãªtre inclus dans les rÃ©sultats.

.PARAMETER IncludeAliases
    Indique si les alias doivent Ãªtre inclus dans les rÃ©sultats.

.EXAMPLE
    $importedFunctions = Get-ImportedFunctions -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne toutes les fonctions importÃ©es.

.EXAMPLE
    $importedFunctions = Get-ImportedFunctions -ScriptContent $scriptContent -ImportModulesIfNotLoaded -IncludeCmdlets
    Analyse le contenu du script fourni et retourne toutes les fonctions importÃ©es, y compris les cmdlets.

.OUTPUTS
    [PSCustomObject[]] Liste des fonctions importÃ©es.
#>
function Get-ImportedFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$ImportModulesIfNotLoaded,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCmdlets,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAliases
    )

    begin {
        # VÃ©rifier si au moins un des paramÃ¨tres ScriptPath ou ScriptContent est spÃ©cifiÃ©
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spÃ©cifier soit ScriptPath, soit ScriptContent.'
        }
    }

    process {
        try {
            # Obtenir les modules importÃ©s
            $importedModulesParams = @{
                IncludeRequiresDirectives = $true
                IncludeUsingStatements = $true
            }

            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $importedModulesParams['ScriptPath'] = $ScriptPath
            }
            else {
                $importedModulesParams['ScriptContent'] = $ScriptContent
            }

            $importedModules = Get-ImportedModules @importedModulesParams

            # Initialiser la liste des fonctions importÃ©es
            $importedFunctions = [System.Collections.ArrayList]::new()

            # Obtenir les fonctions exportÃ©es par chaque module
            foreach ($module in $importedModules) {
                $moduleExportedFunctionsParams = @{
                    ModuleName = $module.Name
                    ImportIfNotLoaded = $ImportModulesIfNotLoaded
                    IncludeCmdlets = $IncludeCmdlets
                    IncludeAliases = $IncludeAliases
                }

                if ($module.Version) {
                    $moduleExportedFunctionsParams['ModuleVersion'] = $module.Version
                }

                $exportedFunctions = Get-ModuleExportedFunctions @moduleExportedFunctionsParams

                # Ajouter les fonctions exportÃ©es Ã  la liste des fonctions importÃ©es
                foreach ($function in $exportedFunctions) {
                    # Ajouter le prÃ©fixe si spÃ©cifiÃ©
                    $functionName = $function.Name
                    if ($module.Prefix) {
                        $functionName = $module.Prefix + '-' + $functionName
                    }

                    [void]$importedFunctions.Add([PSCustomObject]@{
                        Name = $functionName
                        Type = $function.Type
                        Module = $function.Module
                        ModuleVersion = $function.ModuleVersion
                        ImportType = $module.Type
                        ImportLine = $module.Line
                        ImportColumn = $module.Column
                        ImportText = $module.Text
                    })
                }
            }

            return $importedFunctions
        }
        catch {
            Write-Error "Erreur lors de la dÃ©tection des fonctions importÃ©es: $_"
            return @()
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ImportedModules, Get-ModuleExportedFunctions, Get-ImportedFunctions
