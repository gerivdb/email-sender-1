#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'analyse des dÃ©pendances de fonctions dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les dÃ©pendances de fonctions dans les scripts PowerShell,
    notamment la dÃ©tection des appels de fonctions non importÃ©es.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
#>

# Importer les modules requis s'ils ne sont pas dÃ©jÃ  importÃ©s
$moduleRoot = $PSScriptRoot
$functionCallParserPath = Join-Path -Path $moduleRoot -ChildPath 'FunctionCallParser.psm1'
$importedFunctionDetectorPath = Join-Path -Path $moduleRoot -ChildPath 'ImportedFunctionDetector.psm1'

# Liste des fonctions internes de PowerShell qui ne nÃ©cessitent pas d'importation
$script:InternalFunctions = @(
    # Fonctions de flux de contrÃ´le
    'ForEach-Object', 'Where-Object', 'If', 'Else', 'ElseIf', 'Switch', 'For', 'While', 'Do', 'Until', 'Break', 'Continue', 'Return', 'Exit',
    # Fonctions de pipeline
    'Sort-Object', 'Group-Object', 'Select-Object', 'Measure-Object',
    # Fonctions de conversion
    'ConvertTo-Json', 'ConvertFrom-Json', 'ConvertTo-Csv', 'ConvertFrom-Csv', 'ConvertTo-Xml', 'ConvertFrom-Xml',
    # Fonctions de manipulation de chaÃ®nes
    'Split-Path', 'Join-Path', 'Resolve-Path', 'Test-Path',
    # Fonctions de manipulation d'objets
    'New-Object', 'Add-Member', 'Get-Member',
    # Fonctions de manipulation de variables
    'Get-Variable', 'Set-Variable', 'Remove-Variable', 'Clear-Variable',
    # Fonctions de manipulation d'alias
    'Get-Alias', 'Set-Alias', 'Remove-Alias', 'New-Alias',
    # Fonctions de manipulation de fonctions
    'Get-Command', 'Get-Help', 'Get-Module', 'Import-Module', 'Remove-Module',
    # Fonctions de manipulation de fichiers
    'Get-Content', 'Set-Content', 'Add-Content', 'Clear-Content', 'Get-Item', 'Set-Item', 'Remove-Item', 'New-Item',
    # Fonctions de manipulation de rÃ©pertoires
    'Get-ChildItem', 'Set-Location', 'Push-Location', 'Pop-Location',
    # Fonctions de manipulation de processus
    'Start-Process', 'Stop-Process', 'Wait-Process',
    # Fonctions de manipulation de services
    'Get-Service', 'Start-Service', 'Stop-Service', 'Restart-Service',
    # Fonctions de manipulation d'Ã©vÃ©nements
    'Register-ObjectEvent', 'Unregister-Event', 'Wait-Event', 'Get-Event', 'Remove-Event',
    # Fonctions de manipulation de jobs
    'Start-Job', 'Stop-Job', 'Wait-Job', 'Receive-Job', 'Remove-Job',
    # Fonctions de manipulation de sessions
    'New-PSSession', 'Remove-PSSession', 'Enter-PSSession', 'Exit-PSSession',
    # Fonctions de manipulation de scripts
    'Invoke-Command', 'Invoke-Expression', 'Invoke-Item', 'Invoke-WebRequest',
    # Fonctions de manipulation de transactions
    'Start-Transaction', 'Complete-Transaction', 'Undo-Transaction',
    # Fonctions de manipulation de workflows
    'New-PSWorkflowSession', 'New-PSWorkflowExecutionOption',
    # Fonctions de manipulation de DSC
    'Invoke-DscResource', 'Get-DscResource', 'New-DscChecksum',
    # Fonctions de manipulation de certificats
    'Get-PfxCertificate', 'New-SelfSignedCertificate',
    # Fonctions de manipulation de sÃ©curitÃ©
    'ConvertTo-SecureString', 'ConvertFrom-SecureString', 'Get-Credential',
    # Fonctions de manipulation de dates
    'Get-Date', 'Set-Date',
    # Fonctions de manipulation de temps
    'Start-Sleep', 'Measure-Command',
    # Fonctions de manipulation de hÃ´tes
    'Write-Host', 'Write-Output', 'Write-Error', 'Write-Warning', 'Write-Verbose', 'Write-Debug', 'Write-Progress',
    # Fonctions de manipulation de culture
    'Get-Culture', 'Set-Culture',
    # Fonctions de manipulation de formatage
    'Format-List', 'Format-Table', 'Format-Wide', 'Format-Custom',
    # Fonctions de manipulation de clipboard
    'Get-Clipboard', 'Set-Clipboard',
    # Fonctions de manipulation de historique
    'Get-History', 'Invoke-History', 'Clear-History',
    # Fonctions de manipulation de PSSession
    'Get-PSSession', 'New-PSSession', 'Remove-PSSession', 'Enter-PSSession', 'Exit-PSSession',
    # Fonctions de manipulation de PSSessionOption
    'New-PSSessionOption', 'New-PSTransportOption',
    # Fonctions de manipulation de PSSessionConfiguration
    'Register-PSSessionConfiguration', 'Unregister-PSSessionConfiguration', 'Get-PSSessionConfiguration',
    # Fonctions de manipulation de PSSnapin
    'Add-PSSnapin', 'Remove-PSSnapin', 'Get-PSSnapin',
    # Fonctions de manipulation de PSProvider
    'Get-PSProvider', 'Get-PSDrive', 'New-PSDrive', 'Remove-PSDrive',
    # Fonctions de manipulation de PSRepository
    'Register-PSRepository', 'Unregister-PSRepository', 'Get-PSRepository',
    # Fonctions de manipulation de PSResource
    'Find-PSResource', 'Install-PSResource', 'Uninstall-PSResource', 'Update-PSResource',
    # Fonctions de manipulation de PSReadLine
    'Get-PSReadLineOption', 'Set-PSReadLineOption', 'Get-PSReadLineKeyHandler', 'Set-PSReadLineKeyHandler',
    # Fonctions de manipulation de PSScheduledJob
    'Register-ScheduledJob', 'Unregister-ScheduledJob', 'Get-ScheduledJob',
    # Fonctions de manipulation de PSWorkflow
    'New-PSWorkflowSession', 'New-PSWorkflowExecutionOption'
)

if (-not (Get-Module -Name 'FunctionCallParser')) {
    if (Test-Path -Path $functionCallParserPath) {
        Import-Module -Name $functionCallParserPath -Force
    } else {
        throw "Le module FunctionCallParser est requis mais n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $functionCallParserPath"
    }
}

if (-not (Get-Module -Name 'ImportedFunctionDetector')) {
    if (Test-Path -Path $importedFunctionDetectorPath) {
        Import-Module -Name $importedFunctionDetectorPath -Force
    } else {
        throw "Le module ImportedFunctionDetector est requis mais n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $importedFunctionDetectorPath"
    }
}

<#
.SYNOPSIS
    DÃ©tecte les appels de fonctions non importÃ©es dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et dÃ©tecte tous les appels de fonctions
    qui ne sont pas importÃ©es via Import-Module, using module, #Requires -Modules, etc.

.PARAMETER ScriptPath
    Chemin du script PowerShell Ã  analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell Ã  analyser. Si spÃ©cifiÃ©, ScriptPath est ignorÃ©.

.PARAMETER ImportModulesIfNotLoaded
    Indique si les modules doivent Ãªtre importÃ©s s'ils ne sont pas dÃ©jÃ  chargÃ©s.

.PARAMETER IncludeMethodCalls
    Indique si les appels de mÃ©thodes doivent Ãªtre inclus dans l'analyse.

.PARAMETER IncludeStaticMethodCalls
    Indique si les appels de mÃ©thodes statiques doivent Ãªtre inclus dans l'analyse.

.PARAMETER ExcludeCommonCmdlets
    Indique si les cmdlets communs (comme Get-Item, Set-Location, etc.) doivent Ãªtre exclus de l'analyse.

.EXAMPLE
    $nonImportedFunctions = Get-NonImportedFunctionCalls -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne tous les appels de fonctions non importÃ©es.

.EXAMPLE
    $nonImportedFunctions = Get-NonImportedFunctionCalls -ScriptContent $scriptContent -ImportModulesIfNotLoaded -IncludeMethodCalls
    Analyse le contenu du script fourni et retourne tous les appels de fonctions non importÃ©es, y compris les appels de mÃ©thodes.

.OUTPUTS
    [PSCustomObject[]] Liste des appels de fonctions non importÃ©es.
#>
function Get-NonImportedFunctionCalls {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$ImportModulesIfNotLoaded,

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
    }

    process {
        try {
            # PrÃ©parer les paramÃ¨tres pour Get-FunctionCalls
            $functionCallsParams = @{
                IncludeMethodCalls       = $IncludeMethodCalls
                IncludeStaticMethodCalls = $IncludeStaticMethodCalls
                ExcludeCommonCmdlets     = $ExcludeCommonCmdlets
            }

            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $functionCallsParams['ScriptPath'] = $ScriptPath
            } else {
                $functionCallsParams['ScriptContent'] = $ScriptContent
            }

            # Obtenir tous les appels de fonctions
            $functionCalls = Get-FunctionCalls @functionCallsParams

            # Obtenir les fonctions dÃ©finies localement
            $localFunctionsParams = @{}
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $localFunctionsParams['ScriptPath'] = $ScriptPath
            } else {
                $localFunctionsParams['ScriptContent'] = $ScriptContent
            }

            $localFunctions = Get-LocalFunctions @localFunctionsParams

            # Obtenir les fonctions importÃ©es
            $importedFunctionsParams = @{
                ImportModulesIfNotLoaded = $ImportModulesIfNotLoaded
                IncludeCmdlets           = $true
                IncludeAliases           = $true
            }

            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $importedFunctionsParams['ScriptPath'] = $ScriptPath
            } else {
                $importedFunctionsParams['ScriptContent'] = $ScriptContent
            }

            $importedFunctions = Get-ImportedFunctions @importedFunctionsParams

            # Filtrer les appels de fonctions pour ne garder que ceux qui ne sont pas importÃ©s
            $nonImportedFunctionCalls = [System.Collections.ArrayList]::new()

            foreach ($call in $functionCalls) {
                # Ignorer les appels de mÃ©thodes et de mÃ©thodes statiques
                if ($call.Type -eq 'Method' -or $call.Type -eq 'StaticMethod') {
                    continue
                }

                $functionName = $call.Name

                # VÃ©rifier si la fonction est dÃ©finie localement
                $isLocalFunction = $localFunctions | Where-Object { $_.Name -eq $functionName }
                if ($isLocalFunction) {
                    continue
                }

                # VÃ©rifier si la fonction est importÃ©e
                $isImportedFunction = $importedFunctions | Where-Object { $_.Name -eq $functionName }
                if ($isImportedFunction) {
                    continue
                }

                # VÃ©rifier si la fonction est une fonction interne de PowerShell
                if ($script:InternalFunctions -contains $functionName) {
                    continue
                }

                # VÃ©rifier si la fonction est un alias d'une fonction interne
                $alias = Get-Alias -Name $functionName -ErrorAction SilentlyContinue
                if ($alias -and ($script:InternalFunctions -contains $alias.ResolvedCommand.Name)) {
                    continue
                }

                # Ajouter l'appel de fonction Ã  la liste des appels non importÃ©s
                [void]$nonImportedFunctionCalls.Add([PSCustomObject]@{
                        Name       = $functionName
                        Type       = $call.Type
                        Line       = $call.Line
                        Column     = $call.Column
                        Text       = $call.Text
                        Parameters = $call.Parameters
                    })
            }

            return $nonImportedFunctionCalls
        } catch {
            Write-Error "Erreur lors de la dÃ©tection des appels de fonctions non importÃ©es: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    RÃ©sout les modules pour les fonctions non importÃ©es.

.DESCRIPTION
    Cette fonction rÃ©sout les modules pour les fonctions non importÃ©es en recherchant
    les modules qui exportent ces fonctions.

.PARAMETER FunctionNames
    Liste des noms de fonctions Ã  rÃ©soudre.

.PARAMETER SearchInInstalledModules
    Indique si la recherche doit Ãªtre effectuÃ©e dans les modules installÃ©s.

.PARAMETER SearchInLoadedModules
    Indique si la recherche doit Ãªtre effectuÃ©e dans les modules chargÃ©s.

.PARAMETER ExcludeSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus des rÃ©sultats.

.EXAMPLE
    $resolvedModules = Resolve-ModulesForFunctions -FunctionNames @('Get-Process', 'Get-Service')
    RÃ©sout les modules pour les fonctions Get-Process et Get-Service.

.EXAMPLE
    $resolvedModules = Resolve-ModulesForFunctions -FunctionNames $nonImportedFunctions.Name -SearchInInstalledModules -ExcludeSystemModules
    RÃ©sout les modules pour les fonctions non importÃ©es en recherchant dans les modules installÃ©s, en excluant les modules systÃ¨me.

.OUTPUTS
    [PSCustomObject[]] Liste des modules rÃ©solus pour les fonctions.
#>
function Resolve-ModulesForFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$FunctionNames,

        [Parameter(Mandatory = $false)]
        [switch]$SearchInInstalledModules,

        [Parameter(Mandatory = $false)]
        [switch]$SearchInLoadedModules,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeSystemModules
    )

    process {
        try {
            # Initialiser la liste des modules rÃ©solus
            $resolvedModules = [System.Collections.ArrayList]::new()

            # DÃ©finir la valeur par dÃ©faut de SearchInLoadedModules
            if (-not $PSBoundParameters.ContainsKey('SearchInLoadedModules') -and -not $PSBoundParameters.ContainsKey('SearchInInstalledModules')) {
                $SearchInLoadedModules = $true
            }

            # Obtenir les modules Ã  rechercher
            $modulesToSearch = @()

            if ($SearchInLoadedModules) {
                $modulesToSearch += Get-Module
            }

            if ($SearchInInstalledModules) {
                $modulesToSearch += Get-Module -ListAvailable
            }

            # Filtrer les modules systÃ¨me si demandÃ©
            if ($ExcludeSystemModules) {
                $systemModules = @(
                    'Microsoft.PowerShell.Archive',
                    'Microsoft.PowerShell.Core',
                    'Microsoft.PowerShell.Diagnostics',
                    'Microsoft.PowerShell.Host',
                    'Microsoft.PowerShell.Management',
                    'Microsoft.PowerShell.Security',
                    'Microsoft.PowerShell.Utility',
                    'Microsoft.WSMan.Management',
                    'PSDesiredStateConfiguration',
                    'PSScheduledJob',
                    'PSWorkflow',
                    'PSWorkflowUtility',
                    'CimCmdlets',
                    'ISE',
                    'PSReadLine'
                )

                $modulesToSearch = $modulesToSearch | Where-Object { $systemModules -notcontains $_.Name }
            }

            # Rechercher les fonctions dans les modules
            foreach ($functionName in $FunctionNames) {
                $foundModules = @()

                # Rechercher dans les fonctions exportÃ©es
                $foundModules += $modulesToSearch | Where-Object { $_.ExportedFunctions.Keys -contains $functionName }

                # Rechercher dans les cmdlets exportÃ©s
                $foundModules += $modulesToSearch | Where-Object { $_.ExportedCmdlets.Keys -contains $functionName }

                # Rechercher dans les alias exportÃ©s
                $foundModules += $modulesToSearch | Where-Object { $_.ExportedAliases.Keys -contains $functionName }

                # Ajouter les modules trouvÃ©s Ã  la liste des modules rÃ©solus
                foreach ($module in $foundModules) {
                    [void]$resolvedModules.Add([PSCustomObject]@{
                            FunctionName  = $functionName
                            ModuleName    = $module.Name
                            ModuleVersion = $module.Version
                            ModulePath    = $module.Path
                        })
                }
            }

            return $resolvedModules
        } catch {
            Write-Error "Erreur lors de la rÃ©solution des modules pour les fonctions: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Analyse les dÃ©pendances de fonctions dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et dÃ©tecte les dÃ©pendances de fonctions,
    notamment les appels de fonctions non importÃ©es et les modules requis.

.PARAMETER ScriptPath
    Chemin du script PowerShell Ã  analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell Ã  analyser. Si spÃ©cifiÃ©, ScriptPath est ignorÃ©.

.PARAMETER ImportModulesIfNotLoaded
    Indique si les modules doivent Ãªtre importÃ©s s'ils ne sont pas dÃ©jÃ  chargÃ©s.

.PARAMETER IncludeMethodCalls
    Indique si les appels de mÃ©thodes doivent Ãªtre inclus dans l'analyse.

.PARAMETER IncludeStaticMethodCalls
    Indique si les appels de mÃ©thodes statiques doivent Ãªtre inclus dans l'analyse.

.PARAMETER ExcludeCommonCmdlets
    Indique si les cmdlets communs (comme Get-Item, Set-Location, etc.) doivent Ãªtre exclus de l'analyse.

.PARAMETER ResolveModules
    Indique si les modules pour les fonctions non importÃ©es doivent Ãªtre rÃ©solus.

.PARAMETER SearchInInstalledModules
    Indique si la recherche des modules doit Ãªtre effectuÃ©e dans les modules installÃ©s.

.PARAMETER ExcludeSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus des rÃ©sultats.

.EXAMPLE
    $dependencies = Get-FunctionDependencies -ScriptPath 'C:\Scripts\MyScript.ps1' -ResolveModules
    Analyse le script MyScript.ps1 et retourne les dÃ©pendances de fonctions, en rÃ©solvant les modules pour les fonctions non importÃ©es.

.EXAMPLE
    $dependencies = Get-FunctionDependencies -ScriptContent $scriptContent -ImportModulesIfNotLoaded -IncludeMethodCalls -ResolveModules -SearchInInstalledModules
    Analyse le contenu du script fourni et retourne les dÃ©pendances de fonctions, en rÃ©solvant les modules pour les fonctions non importÃ©es.

.OUTPUTS
    [PSCustomObject] RÃ©sultat de l'analyse des dÃ©pendances de fonctions.
#>
function Get-FunctionDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$ImportModulesIfNotLoaded,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMethodCalls,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStaticMethodCalls,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeCommonCmdlets,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModules,

        [Parameter(Mandatory = $false)]
        [switch]$SearchInInstalledModules,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeSystemModules
    )

    begin {
        # VÃ©rifier si au moins un des paramÃ¨tres ScriptPath ou ScriptContent est spÃ©cifiÃ©
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spÃ©cifier soit ScriptPath, soit ScriptContent.'
        }
    }

    process {
        try {
            # PrÃ©parer les paramÃ¨tres pour Get-NonImportedFunctionCalls
            $nonImportedFunctionCallsParams = @{
                ImportModulesIfNotLoaded = $ImportModulesIfNotLoaded
                IncludeMethodCalls       = $IncludeMethodCalls
                IncludeStaticMethodCalls = $IncludeStaticMethodCalls
                ExcludeCommonCmdlets     = $ExcludeCommonCmdlets
            }

            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $nonImportedFunctionCallsParams['ScriptPath'] = $ScriptPath
            } else {
                $nonImportedFunctionCallsParams['ScriptContent'] = $ScriptContent
            }

            # Obtenir les appels de fonctions non importÃ©es
            $nonImportedFunctionCalls = Get-NonImportedFunctionCalls @nonImportedFunctionCallsParams

            # RÃ©soudre les modules pour les fonctions non importÃ©es si demandÃ©
            $resolvedModules = @()
            if ($ResolveModules -and $nonImportedFunctionCalls.Count -gt 0) {
                $resolveModulesParams = @{
                    FunctionNames            = $nonImportedFunctionCalls.Name
                    SearchInLoadedModules    = $true
                    SearchInInstalledModules = $SearchInInstalledModules
                    ExcludeSystemModules     = $ExcludeSystemModules
                }

                $resolvedModules = Resolve-ModulesForFunctions @resolveModulesParams
            }

            # Obtenir les modules importÃ©s
            $importedModulesParams = @{
                IncludeRequiresDirectives = $true
                IncludeUsingStatements    = $true
            }

            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $importedModulesParams['ScriptPath'] = $ScriptPath
            } else {
                $importedModulesParams['ScriptContent'] = $ScriptContent
            }

            $importedModules = Get-ImportedModules @importedModulesParams

            # CrÃ©er le rÃ©sultat de l'analyse
            $result = [PSCustomObject]@{
                ImportedModules          = $importedModules
                NonImportedFunctionCalls = $nonImportedFunctionCalls
                ResolvedModules          = $resolvedModules
                MissingModules           = @()
            }

            # Identifier les modules manquants
            if ($ResolveModules -and $nonImportedFunctionCalls.Count -gt 0) {
                $missingModules = [System.Collections.ArrayList]::new()

                foreach ($functionCall in $nonImportedFunctionCalls) {
                    $functionName = $functionCall.Name
                    $resolvedModulesForFunction = $resolvedModules | Where-Object { $_.FunctionName -eq $functionName }

                    if ($resolvedModulesForFunction.Count -eq 0) {
                        # Aucun module trouvÃ© pour cette fonction
                        [void]$missingModules.Add([PSCustomObject]@{
                                FunctionName    = $functionName
                                Line            = $functionCall.Line
                                Column          = $functionCall.Column
                                Text            = $functionCall.Text
                                ResolvedModules = @()
                            })
                    } else {
                        # VÃ©rifier si les modules rÃ©solus sont dÃ©jÃ  importÃ©s
                        $modulesNotImported = $resolvedModulesForFunction | Where-Object {
                            $moduleName = $_.ModuleName
                            -not ($importedModules | Where-Object { $_.Name -eq $moduleName })
                        }

                        if ($modulesNotImported.Count -gt 0) {
                            [void]$missingModules.Add([PSCustomObject]@{
                                    FunctionName    = $functionName
                                    Line            = $functionCall.Line
                                    Column          = $functionCall.Column
                                    Text            = $functionCall.Text
                                    ResolvedModules = $modulesNotImported
                                })
                        }
                    }
                }

                $result.MissingModules = $missingModules
            }

            return $result
        } catch {
            Write-Error "Erreur lors de l'analyse des dÃ©pendances de fonctions: $_"
            return $null
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-NonImportedFunctionCalls, Resolve-ModulesForFunctions, Get-FunctionDependencies
