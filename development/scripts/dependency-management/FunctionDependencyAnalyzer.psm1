#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'analyse des dépendances de fonctions dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les dépendances de fonctions dans les scripts PowerShell,
    notamment la détection des appels de fonctions non importées.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-06-15
#>

# Importer les modules requis s'ils ne sont pas déjà importés
$moduleRoot = $PSScriptRoot
$functionCallParserPath = Join-Path -Path $moduleRoot -ChildPath 'FunctionCallParser.psm1'
$importedFunctionDetectorPath = Join-Path -Path $moduleRoot -ChildPath 'ImportedFunctionDetector.psm1'

# Liste des fonctions internes de PowerShell qui ne nécessitent pas d'importation
$script:InternalFunctions = @(
    # Fonctions de flux de contrôle
    'ForEach-Object', 'Where-Object', 'If', 'Else', 'ElseIf', 'Switch', 'For', 'While', 'Do', 'Until', 'Break', 'Continue', 'Return', 'Exit',
    # Fonctions de pipeline
    'Sort-Object', 'Group-Object', 'Select-Object', 'Measure-Object',
    # Fonctions de conversion
    'ConvertTo-Json', 'ConvertFrom-Json', 'ConvertTo-Csv', 'ConvertFrom-Csv', 'ConvertTo-Xml', 'ConvertFrom-Xml',
    # Fonctions de manipulation de chaînes
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
    # Fonctions de manipulation de répertoires
    'Get-ChildItem', 'Set-Location', 'Push-Location', 'Pop-Location',
    # Fonctions de manipulation de processus
    'Start-Process', 'Stop-Process', 'Wait-Process',
    # Fonctions de manipulation de services
    'Get-Service', 'Start-Service', 'Stop-Service', 'Restart-Service',
    # Fonctions de manipulation d'événements
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
    # Fonctions de manipulation de sécurité
    'ConvertTo-SecureString', 'ConvertFrom-SecureString', 'Get-Credential',
    # Fonctions de manipulation de dates
    'Get-Date', 'Set-Date',
    # Fonctions de manipulation de temps
    'Start-Sleep', 'Measure-Command',
    # Fonctions de manipulation de hôtes
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
        throw "Le module FunctionCallParser est requis mais n'a pas été trouvé à l'emplacement: $functionCallParserPath"
    }
}

if (-not (Get-Module -Name 'ImportedFunctionDetector')) {
    if (Test-Path -Path $importedFunctionDetectorPath) {
        Import-Module -Name $importedFunctionDetectorPath -Force
    } else {
        throw "Le module ImportedFunctionDetector est requis mais n'a pas été trouvé à l'emplacement: $importedFunctionDetectorPath"
    }
}

<#
.SYNOPSIS
    Détecte les appels de fonctions non importées dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et détecte tous les appels de fonctions
    qui ne sont pas importées via Import-Module, using module, #Requires -Modules, etc.

.PARAMETER ScriptPath
    Chemin du script PowerShell à analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell à analyser. Si spécifié, ScriptPath est ignoré.

.PARAMETER ImportModulesIfNotLoaded
    Indique si les modules doivent être importés s'ils ne sont pas déjà chargés.

.PARAMETER IncludeMethodCalls
    Indique si les appels de méthodes doivent être inclus dans l'analyse.

.PARAMETER IncludeStaticMethodCalls
    Indique si les appels de méthodes statiques doivent être inclus dans l'analyse.

.PARAMETER ExcludeCommonCmdlets
    Indique si les cmdlets communs (comme Get-Item, Set-Location, etc.) doivent être exclus de l'analyse.

.EXAMPLE
    $nonImportedFunctions = Get-NonImportedFunctionCalls -ScriptPath 'C:\Scripts\MyScript.ps1'
    Analyse le script MyScript.ps1 et retourne tous les appels de fonctions non importées.

.EXAMPLE
    $nonImportedFunctions = Get-NonImportedFunctionCalls -ScriptContent $scriptContent -ImportModulesIfNotLoaded -IncludeMethodCalls
    Analyse le contenu du script fourni et retourne tous les appels de fonctions non importées, y compris les appels de méthodes.

.OUTPUTS
    [PSCustomObject[]] Liste des appels de fonctions non importées.
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
        # Vérifier si au moins un des paramètres ScriptPath ou ScriptContent est spécifié
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spécifier soit ScriptPath, soit ScriptContent.'
        }
    }

    process {
        try {
            # Préparer les paramètres pour Get-FunctionCalls
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

            # Obtenir les fonctions définies localement
            $localFunctionsParams = @{}
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $localFunctionsParams['ScriptPath'] = $ScriptPath
            } else {
                $localFunctionsParams['ScriptContent'] = $ScriptContent
            }

            $localFunctions = Get-LocalFunctions @localFunctionsParams

            # Obtenir les fonctions importées
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

            # Filtrer les appels de fonctions pour ne garder que ceux qui ne sont pas importés
            $nonImportedFunctionCalls = [System.Collections.ArrayList]::new()

            foreach ($call in $functionCalls) {
                # Ignorer les appels de méthodes et de méthodes statiques
                if ($call.Type -eq 'Method' -or $call.Type -eq 'StaticMethod') {
                    continue
                }

                $functionName = $call.Name

                # Vérifier si la fonction est définie localement
                $isLocalFunction = $localFunctions | Where-Object { $_.Name -eq $functionName }
                if ($isLocalFunction) {
                    continue
                }

                # Vérifier si la fonction est importée
                $isImportedFunction = $importedFunctions | Where-Object { $_.Name -eq $functionName }
                if ($isImportedFunction) {
                    continue
                }

                # Vérifier si la fonction est une fonction interne de PowerShell
                if ($script:InternalFunctions -contains $functionName) {
                    continue
                }

                # Vérifier si la fonction est un alias d'une fonction interne
                $alias = Get-Alias -Name $functionName -ErrorAction SilentlyContinue
                if ($alias -and ($script:InternalFunctions -contains $alias.ResolvedCommand.Name)) {
                    continue
                }

                # Ajouter l'appel de fonction à la liste des appels non importés
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
            Write-Error "Erreur lors de la détection des appels de fonctions non importées: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Résout les modules pour les fonctions non importées.

.DESCRIPTION
    Cette fonction résout les modules pour les fonctions non importées en recherchant
    les modules qui exportent ces fonctions.

.PARAMETER FunctionNames
    Liste des noms de fonctions à résoudre.

.PARAMETER SearchInInstalledModules
    Indique si la recherche doit être effectuée dans les modules installés.

.PARAMETER SearchInLoadedModules
    Indique si la recherche doit être effectuée dans les modules chargés.

.PARAMETER ExcludeSystemModules
    Indique si les modules système doivent être exclus des résultats.

.EXAMPLE
    $resolvedModules = Resolve-ModulesForFunctions -FunctionNames @('Get-Process', 'Get-Service')
    Résout les modules pour les fonctions Get-Process et Get-Service.

.EXAMPLE
    $resolvedModules = Resolve-ModulesForFunctions -FunctionNames $nonImportedFunctions.Name -SearchInInstalledModules -ExcludeSystemModules
    Résout les modules pour les fonctions non importées en recherchant dans les modules installés, en excluant les modules système.

.OUTPUTS
    [PSCustomObject[]] Liste des modules résolus pour les fonctions.
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
            # Initialiser la liste des modules résolus
            $resolvedModules = [System.Collections.ArrayList]::new()

            # Définir la valeur par défaut de SearchInLoadedModules
            if (-not $PSBoundParameters.ContainsKey('SearchInLoadedModules') -and -not $PSBoundParameters.ContainsKey('SearchInInstalledModules')) {
                $SearchInLoadedModules = $true
            }

            # Obtenir les modules à rechercher
            $modulesToSearch = @()

            if ($SearchInLoadedModules) {
                $modulesToSearch += Get-Module
            }

            if ($SearchInInstalledModules) {
                $modulesToSearch += Get-Module -ListAvailable
            }

            # Filtrer les modules système si demandé
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

                # Rechercher dans les fonctions exportées
                $foundModules += $modulesToSearch | Where-Object { $_.ExportedFunctions.Keys -contains $functionName }

                # Rechercher dans les cmdlets exportés
                $foundModules += $modulesToSearch | Where-Object { $_.ExportedCmdlets.Keys -contains $functionName }

                # Rechercher dans les alias exportés
                $foundModules += $modulesToSearch | Where-Object { $_.ExportedAliases.Keys -contains $functionName }

                # Ajouter les modules trouvés à la liste des modules résolus
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
            Write-Error "Erreur lors de la résolution des modules pour les fonctions: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Analyse les dépendances de fonctions dans un script PowerShell.

.DESCRIPTION
    Cette fonction analyse un script PowerShell et détecte les dépendances de fonctions,
    notamment les appels de fonctions non importées et les modules requis.

.PARAMETER ScriptPath
    Chemin du script PowerShell à analyser.

.PARAMETER ScriptContent
    Contenu du script PowerShell à analyser. Si spécifié, ScriptPath est ignoré.

.PARAMETER ImportModulesIfNotLoaded
    Indique si les modules doivent être importés s'ils ne sont pas déjà chargés.

.PARAMETER IncludeMethodCalls
    Indique si les appels de méthodes doivent être inclus dans l'analyse.

.PARAMETER IncludeStaticMethodCalls
    Indique si les appels de méthodes statiques doivent être inclus dans l'analyse.

.PARAMETER ExcludeCommonCmdlets
    Indique si les cmdlets communs (comme Get-Item, Set-Location, etc.) doivent être exclus de l'analyse.

.PARAMETER ResolveModules
    Indique si les modules pour les fonctions non importées doivent être résolus.

.PARAMETER SearchInInstalledModules
    Indique si la recherche des modules doit être effectuée dans les modules installés.

.PARAMETER ExcludeSystemModules
    Indique si les modules système doivent être exclus des résultats.

.EXAMPLE
    $dependencies = Get-FunctionDependencies -ScriptPath 'C:\Scripts\MyScript.ps1' -ResolveModules
    Analyse le script MyScript.ps1 et retourne les dépendances de fonctions, en résolvant les modules pour les fonctions non importées.

.EXAMPLE
    $dependencies = Get-FunctionDependencies -ScriptContent $scriptContent -ImportModulesIfNotLoaded -IncludeMethodCalls -ResolveModules -SearchInInstalledModules
    Analyse le contenu du script fourni et retourne les dépendances de fonctions, en résolvant les modules pour les fonctions non importées.

.OUTPUTS
    [PSCustomObject] Résultat de l'analyse des dépendances de fonctions.
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
        # Vérifier si au moins un des paramètres ScriptPath ou ScriptContent est spécifié
        if (-not $ScriptPath -and -not $ScriptContent) {
            throw 'Vous devez spécifier soit ScriptPath, soit ScriptContent.'
        }
    }

    process {
        try {
            # Préparer les paramètres pour Get-NonImportedFunctionCalls
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

            # Obtenir les appels de fonctions non importées
            $nonImportedFunctionCalls = Get-NonImportedFunctionCalls @nonImportedFunctionCallsParams

            # Résoudre les modules pour les fonctions non importées si demandé
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

            # Obtenir les modules importés
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

            # Créer le résultat de l'analyse
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
                        # Aucun module trouvé pour cette fonction
                        [void]$missingModules.Add([PSCustomObject]@{
                                FunctionName    = $functionName
                                Line            = $functionCall.Line
                                Column          = $functionCall.Column
                                Text            = $functionCall.Text
                                ResolvedModules = @()
                            })
                    } else {
                        # Vérifier si les modules résolus sont déjà importés
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
            Write-Error "Erreur lors de l'analyse des dépendances de fonctions: $_"
            return $null
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-NonImportedFunctionCalls, Resolve-ModulesForFunctions, Get-FunctionDependencies
