#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour la détection des fonctions importées dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour détecter les modules importés et les fonctions
    exportées par ces modules dans les scripts PowerShell.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-06-15
#>

# Importer le module FunctionCallParser s'il n'est pas déjà importé
$functionCallParserPath = Join-Path -Path $PSScriptRoot -ChildPath 'FunctionCallParser.psm1'
if (-not (Get-Module -Name 'FunctionCallParser')) {
    if (Test-Path -Path $functionCallParserPath) {
        Import-Module -Name $functionCallParserPath -Force
    }
    else {
        throw "Le module FunctionCallParser est requis mais n'a pas été trouvé à l'emplacement: $functionCallParserPath"
    }
}

<#
.SYNOPSIS
    Détecte les modules importés dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et détecte tous les modules importés
    via Import-Module, using module, #Requires -Modules, etc.

.PARAMETER ScriptPath
    Chemin du script PowerShell à analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell à analyser. Si spécifié, ScriptPath est ignoré.

.PARAMETER IncludeRequiresDirectives
    Indique si les directives #Requires -Modules doivent être incluses dans les résultats.

.PARAMETER IncludeUsingStatements
    Indique si les instructions using module doivent être incluses dans les résultats.

.EXAMPLE
    $importedModules = Get-ImportedModules -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne tous les modules importés.

.EXAMPLE
    $importedModules = Get-ImportedModules -ScriptContent $scriptContent -IncludeRequiresDirectives
    Analyse le contenu du script fourni et retourne tous les modules importés, y compris ceux spécifiés dans les directives #Requires.

.OUTPUTS
    [PSCustomObject[]] Liste des modules importés.
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
        # Vérifier si au moins un des paramètres ScriptPath ou ScriptContent est spécifié
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spécifier soit ScriptPath, soit ScriptContent.'
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

            # Initialiser la liste des modules importés
            $importedModules = [System.Collections.ArrayList]::new()

            # Trouver tous les appels à Import-Module
            $importModuleCalls = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -gt 0 -and
                $node.CommandElements[0].Extent.Text -eq 'Import-Module'
            }, $true)

            # Traiter les appels à Import-Module
            foreach ($call in $importModuleCalls) {
                $moduleName = $null
                $moduleVersion = $null
                $prefix = $null
                $alias = $null

                # Parcourir les éléments de la commande
                for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                    $element = $call.CommandElements[$i]

                    # Vérifier si c'est un paramètre nommé
                    if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                        $paramName = $element.ParameterName.ToLower()

                        # Vérifier s'il y a une valeur associée
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
                            
                            $i++ # Sauter la valeur du paramètre
                        }
                    }
                    # Sinon, c'est un paramètre positionnel (probablement le nom du module)
                    elseif (-not $moduleName) {
                        $moduleName = $element.Extent.Text.Trim("'`"")
                    }
                }

                # Ajouter le module à la liste
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

            # Trouver toutes les instructions using module si demandé
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

            # Trouver toutes les directives #Requires -Modules si demandé
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
            Write-Error "Erreur lors de la détection des modules importés: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Obtient les fonctions exportées par un module PowerShell.

.DESCRIPTION
    Cette fonction obtient la liste des fonctions exportées par un module PowerShell
    en important le module et en interrogeant ses fonctions exportées.

.PARAMETER ModuleName
    Nom du module PowerShell.

.PARAMETER ModuleVersion
    Version du module PowerShell. Si non spécifié, la dernière version disponible est utilisée.

.PARAMETER ImportIfNotLoaded
    Indique si le module doit être importé s'il n'est pas déjà chargé.

.PARAMETER IncludeCmdlets
    Indique si les cmdlets doivent être inclus dans les résultats.

.PARAMETER IncludeAliases
    Indique si les alias doivent être inclus dans les résultats.

.EXAMPLE
    $exportedFunctions = Get-ModuleExportedFunctions -ModuleName 'Microsoft.PowerShell.Management'
    Obtient les fonctions exportées par le module Microsoft.PowerShell.Management.

.EXAMPLE
    $exportedFunctions = Get-ModuleExportedFunctions -ModuleName 'Az.Storage' -ModuleVersion '2.0.0' -IncludeCmdlets -IncludeAliases
    Obtient les fonctions, cmdlets et alias exportés par le module Az.Storage version 2.0.0.

.OUTPUTS
    [PSCustomObject[]] Liste des fonctions exportées par le module.
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
            # Vérifier si le module est déjà chargé
            $moduleInfo = $null
            if ($ModuleVersion) {
                $moduleInfo = Get-Module -Name $ModuleName -RequiredVersion $ModuleVersion -ErrorAction SilentlyContinue
            }
            else {
                $moduleInfo = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
            }

            # Importer le module s'il n'est pas déjà chargé et si demandé
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

            # Vérifier si le module est chargé
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
                    Write-Warning "Le module '$ModuleName' n'est pas chargé et n'a pas été trouvé. Utilisez ImportIfNotLoaded pour l'importer automatiquement."
                    return @()
                }
            }

            # Initialiser la liste des fonctions exportées
            $exportedFunctions = [System.Collections.ArrayList]::new()

            # Obtenir les fonctions exportées
            $functions = $moduleInfo.ExportedFunctions.Values
            foreach ($function in $functions) {
                [void]$exportedFunctions.Add([PSCustomObject]@{
                    Name = $function.Name
                    Type = 'Function'
                    Module = $moduleInfo.Name
                    ModuleVersion = $moduleInfo.Version
                })
            }

            # Obtenir les cmdlets exportés si demandé
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

            # Obtenir les alias exportés si demandé
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
            Write-Error "Erreur lors de l'obtention des fonctions exportées par le module '$ModuleName': $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Détecte les fonctions importées dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et détecte toutes les fonctions importées
    via les modules importés dans le script.

.PARAMETER ScriptPath
    Chemin du script PowerShell à analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell à analyser. Si spécifié, ScriptPath est ignoré.

.PARAMETER ImportModulesIfNotLoaded
    Indique si les modules doivent être importés s'ils ne sont pas déjà chargés.

.PARAMETER IncludeCmdlets
    Indique si les cmdlets doivent être inclus dans les résultats.

.PARAMETER IncludeAliases
    Indique si les alias doivent être inclus dans les résultats.

.EXAMPLE
    $importedFunctions = Get-ImportedFunctions -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne toutes les fonctions importées.

.EXAMPLE
    $importedFunctions = Get-ImportedFunctions -ScriptContent $scriptContent -ImportModulesIfNotLoaded -IncludeCmdlets
    Analyse le contenu du script fourni et retourne toutes les fonctions importées, y compris les cmdlets.

.OUTPUTS
    [PSCustomObject[]] Liste des fonctions importées.
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
        # Vérifier si au moins un des paramètres ScriptPath ou ScriptContent est spécifié
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spécifier soit ScriptPath, soit ScriptContent.'
        }
    }

    process {
        try {
            # Obtenir les modules importés
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

            # Initialiser la liste des fonctions importées
            $importedFunctions = [System.Collections.ArrayList]::new()

            # Obtenir les fonctions exportées par chaque module
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

                # Ajouter les fonctions exportées à la liste des fonctions importées
                foreach ($function in $exportedFunctions) {
                    # Ajouter le préfixe si spécifié
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
            Write-Error "Erreur lors de la détection des fonctions importées: $_"
            return @()
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ImportedModules, Get-ModuleExportedFunctions, Get-ImportedFunctions
