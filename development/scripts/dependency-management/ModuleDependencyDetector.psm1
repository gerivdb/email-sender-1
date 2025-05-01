#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour la détection des dépendances de modules PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour détecter les dépendances de modules PowerShell
    dans les scripts, en utilisant l'analyse AST (Abstract Syntax Tree) pour une détection
    précise des instructions Import-Module et leurs paramètres.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

#region Private Functions

function Get-ImportModuleAst {
    <#
    .SYNOPSIS
        Détecte les instructions Import-Module dans un script PowerShell en utilisant l'AST.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell en utilisant l'AST (Abstract Syntax Tree)
        pour détecter les instructions Import-Module et extraire les informations sur les modules importés.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .EXAMPLE
        Get-ImportModuleAst -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $content = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Get-ImportModuleAst -ScriptContent $content

    .OUTPUTS
        System.Collections.Generic.List[PSObject]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent
    )

    try {
        # Initialiser les variables pour l'AST
        $tokens = $null
        $parseErrors = $null
        $ast = $null

        # Analyser le script avec l'AST
        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                Write-Error "Le fichier spécifié n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $FilePath,
                [ref]$tokens,
                [ref]$parseErrors
            )
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $ScriptContent,
                [ref]$tokens,
                [ref]$parseErrors
            )
        }

        # Vérifier les erreurs d'analyse
        if ($parseErrors -and $parseErrors.Count -gt 0) {
            Write-Warning "Des erreurs d'analyse ont été détectées dans le script :"
            foreach ($error in $parseErrors) {
                Write-Warning "  Ligne $($error.Extent.StartLineNumber), Colonne $($error.Extent.StartColumnNumber): $($error.Message)"
            }
        }

        # Initialiser la liste des résultats
        $results = [System.Collections.Generic.List[PSObject]]::new()

        # 1. Trouver toutes les instructions Import-Module
        $importModuleCalls = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -gt 0 -and
                $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $node.CommandElements[0].Value -eq 'Import-Module'
            }, $true)

        # Analyser chaque instruction Import-Module
        foreach ($call in $importModuleCalls) {
            # Initialiser les informations sur le module
            $moduleInfo = [PSCustomObject]@{
                Name         = $null
                Path         = $null
                Version      = $null
                Global       = $false
                Force        = $false
                Prefix       = $null
                ArgumentType = "Unknown"
                LineNumber   = $call.Extent.StartLineNumber
                ColumnNumber = $call.Extent.StartColumnNumber
                RawCommand   = $call.Extent.Text
                ImportType   = "Import-Module"
            }

            # Analyser les éléments de la commande
            $namedParameters = @{}
            $positionalParameters = @()

            for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                $element = $call.CommandElements[$i]

                # Vérifier si c'est un paramètre nommé
                if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                    $paramName = $element.ParameterName

                    # Vérifier si le paramètre a une valeur associée
                    if ($i + 1 -lt $call.CommandElements.Count -and
                        -not ($call.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                        $namedParameters[$paramName] = $call.CommandElements[$i + 1]
                        $i++  # Sauter l'élément suivant car c'est la valeur du paramètre
                    } else {
                        # Paramètre switch sans valeur
                        $namedParameters[$paramName] = $true
                    }
                } else {
                    # Paramètre positionnel
                    $positionalParameters += $element
                }
            }

            # Traiter les paramètres nommés
            if ($namedParameters.ContainsKey("Name")) {
                $moduleInfo.Name = GetParameterValue -Parameter $namedParameters["Name"]
                $moduleInfo.ArgumentType = "Named"
            } elseif ($namedParameters.ContainsKey("Path")) {
                $moduleInfo.Path = GetParameterValue -Parameter $namedParameters["Path"]
                $moduleInfo.Name = [System.IO.Path]::GetFileNameWithoutExtension($moduleInfo.Path)
                $moduleInfo.ArgumentType = "Path"
            }

            # Traiter les autres paramètres nommés
            if ($namedParameters.ContainsKey("Global")) {
                $moduleInfo.Global = $true
            }

            if ($namedParameters.ContainsKey("Force")) {
                $moduleInfo.Force = $true
            }

            if ($namedParameters.ContainsKey("Prefix")) {
                $moduleInfo.Prefix = GetParameterValue -Parameter $namedParameters["Prefix"]
            }

            if ($namedParameters.ContainsKey("RequiredVersion") -or
                $namedParameters.ContainsKey("MinimumVersion") -or
                $namedParameters.ContainsKey("MaximumVersion")) {
                if ($namedParameters.ContainsKey("RequiredVersion")) {
                    $moduleInfo.Version = GetParameterValue -Parameter $namedParameters["RequiredVersion"]
                } elseif ($namedParameters.ContainsKey("MinimumVersion")) {
                    $moduleInfo.Version = "≥ " + (GetParameterValue -Parameter $namedParameters["MinimumVersion"])

                    if ($namedParameters.ContainsKey("MaximumVersion")) {
                        $moduleInfo.Version += ", ≤ " + (GetParameterValue -Parameter $namedParameters["MaximumVersion"])
                    }
                } elseif ($namedParameters.ContainsKey("MaximumVersion")) {
                    $moduleInfo.Version = "≤ " + (GetParameterValue -Parameter $namedParameters["MaximumVersion"])
                }
            }

            # Traiter les paramètres positionnels
            if (-not $moduleInfo.Name -and -not $moduleInfo.Path -and $positionalParameters.Count -gt 0) {
                $firstParam = GetParameterValue -Parameter $positionalParameters[0]

                # Déterminer si c'est un nom ou un chemin
                if ($firstParam -match '[/\\]' -or $firstParam -match '^\.\.?[/\\]') {
                    # C'est probablement un chemin
                    $moduleInfo.Path = $firstParam
                    $moduleInfo.Name = [System.IO.Path]::GetFileNameWithoutExtension($moduleInfo.Path)
                    $moduleInfo.ArgumentType = "PositionalPath"
                } else {
                    # C'est probablement un nom de module
                    $moduleInfo.Name = $firstParam
                    $moduleInfo.ArgumentType = "Positional"
                }
            }

            # Ajouter le résultat à la liste
            $results.Add($moduleInfo)
        }

        # 2. Trouver toutes les instructions using module
        # Utiliser uniquement des expressions régulières (plus fiable)
        try {
            # Obtenir le contenu du script
            $scriptText = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
                Get-Content -Path $FilePath -Raw -ErrorAction Stop
            } else {
                $ScriptContent
            }

            if ($scriptText) {
                # Rechercher les instructions using module avec une regex
                $regex = [regex]::new('using\s+module\s+(\S+)')
                $regexMatches = $regex.Matches($scriptText)

                Write-Verbose "Recherche d'instructions using module avec regex dans le script"
                Write-Verbose "Contenu du script (premiers 100 caractères) : $($scriptText.Substring(0, [Math]::Min(100, $scriptText.Length)))"
                Write-Verbose "Nombre de correspondances trouvées : $($regexMatches.Count)"

                foreach ($match in $regexMatches) {
                    $moduleName = $match.Groups[1].Value.Trim()

                    # Déterminer le numéro de ligne
                    $lineNumber = 1
                    $position = $match.Index
                    $lines = $scriptText.Substring(0, $position).Split("`n")
                    $lineNumber = $lines.Count

                    # Initialiser les informations sur le module
                    $moduleInfo = [PSCustomObject]@{
                        Name         = $moduleName
                        Path         = $null
                        Version      = $null
                        Global       = $true  # Les instructions using module ont une portée globale
                        Force        = $false
                        Prefix       = $null
                        ArgumentType = "UsingModule"
                        LineNumber   = $lineNumber
                        ColumnNumber = 1  # Approximation
                        RawCommand   = "using module $moduleName"
                        ImportType   = "using module"
                    }

                    Write-Verbose "Création d'une instruction using module : $moduleName à la ligne $lineNumber"

                    # Déterminer si c'est un nom ou un chemin
                    if ($moduleName -match '[/\\]' -or $moduleName -match '^\.\.?[/\\]') {
                        # C'est probablement un chemin
                        $moduleInfo.Path = $moduleName
                        $moduleInfo.Name = [System.IO.Path]::GetFileNameWithoutExtension($moduleName)
                    }

                    # Ajouter le résultat à la liste
                    $results.Add($moduleInfo)
                    Write-Verbose "Instruction using module trouvée : $moduleName à la ligne $lineNumber"
                }
            } else {
                Write-Warning "Le contenu du script est vide ou null"
            }
        } catch {
            Write-Warning "Erreur lors de la recherche des instructions using module avec regex : $_"
        }

        return $results
    } catch {
        Write-Error "Erreur lors de l'analyse du script : $_"
        return @()
    }
}

function GetParameterValue {
    <#
    .SYNOPSIS
        Extrait la valeur d'un paramètre AST.

    .DESCRIPTION
        Cette fonction interne extrait la valeur d'un paramètre AST en fonction de son type.

    .PARAMETER Parameter
        Le paramètre AST à analyser.

    .OUTPUTS
        System.Object
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Parameter
    )

    if ($Parameter -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
        return $Parameter.Value
    } elseif ($Parameter -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
        return $Parameter.Value
    } elseif ($Parameter -is [System.Management.Automation.Language.VariableExpressionAst]) {
        return "$" + $Parameter.VariablePath.UserPath
    } elseif ($Parameter -is [bool]) {
        return $Parameter
    } else {
        return $Parameter.Extent.Text
    }
}

function Resolve-ModulePath {
    <#
    .SYNOPSIS
        Résout le chemin complet d'un module PowerShell.

    .DESCRIPTION
        Cette fonction tente de résoudre le chemin complet d'un module PowerShell
        en fonction de son nom ou de son chemin relatif.

    .PARAMETER Name
        Nom du module à résoudre.

    .PARAMETER Path
        Chemin relatif ou absolu du module à résoudre.

    .PARAMETER BaseDirectory
        Répertoire de base pour résoudre les chemins relatifs.
        Par défaut, utilise le répertoire courant.

    .PARAMETER SearchDepth
        Profondeur de recherche pour trouver les modules dans les sous-répertoires.
        Par défaut, la valeur est 3.

    .EXAMPLE
        Resolve-ModulePath -Name "PSScriptAnalyzer"

    .EXAMPLE
        Resolve-ModulePath -Path "..\Modules\MyModule.psm1" -BaseDirectory "C:\Scripts"

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$BaseDirectory = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [int]$SearchDepth = 3
    )

    try {
        if ($PSCmdlet.ParameterSetName -eq "ByName") {
            # 1. Rechercher le module dans les chemins de modules standard
            $module = Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue

            if ($module) {
                return $module[0].Path
            }

            # 2. Rechercher dans les chemins de modules personnalisés
            $psModulePaths = $env:PSModulePath -split [System.IO.Path]::PathSeparator
            foreach ($modulePath in $psModulePaths) {
                if (Test-Path -Path $modulePath) {
                    $moduleFiles = Get-ChildItem -Path $modulePath -Recurse -Include "$Name.psm1", "$Name.psd1" -File -ErrorAction SilentlyContinue -Depth $SearchDepth

                    if ($moduleFiles) {
                        return $moduleFiles[0].FullName
                    }
                }
            }

            # 3. Rechercher dans le répertoire de base et ses sous-répertoires
            $moduleFiles = Get-ChildItem -Path $BaseDirectory -Recurse -Include "$Name.psm1", "$Name.psd1" -File -ErrorAction SilentlyContinue -Depth $SearchDepth

            if ($moduleFiles) {
                return $moduleFiles[0].FullName
            }

            # 4. Rechercher dans les répertoires communs de modules
            $commonModulePaths = @(
                # Répertoires communs pour les modules PowerShell
                (Join-Path -Path $BaseDirectory -ChildPath "modules"),
                (Join-Path -Path $BaseDirectory -ChildPath "Modules"),
                (Join-Path -Path (Split-Path -Parent $BaseDirectory) -ChildPath "modules"),
                (Join-Path -Path (Split-Path -Parent $BaseDirectory) -ChildPath "Modules"),
                (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $BaseDirectory)) -ChildPath "modules"),
                (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $BaseDirectory)) -ChildPath "Modules"),
                (Join-Path -Path $BaseDirectory -ChildPath "lib"),
                (Join-Path -Path $BaseDirectory -ChildPath "libs"),
                (Join-Path -Path $BaseDirectory -ChildPath "library"),
                (Join-Path -Path $BaseDirectory -ChildPath "dependencies")
            )

            foreach ($modulePath in $commonModulePaths) {
                if (Test-Path -Path $modulePath) {
                    $moduleFiles = Get-ChildItem -Path $modulePath -Recurse -Include "$Name.psm1", "$Name.psd1" -File -ErrorAction SilentlyContinue -Depth $SearchDepth

                    if ($moduleFiles) {
                        return $moduleFiles[0].FullName
                    }
                }
            }

            return $null
        } else {
            # Résoudre le chemin relatif ou absolu
            if ([System.IO.Path]::IsPathRooted($Path)) {
                # Chemin absolu
                if (Test-Path -Path $Path -PathType Leaf) {
                    return $Path
                }

                # Essayer d'ajouter les extensions courantes si elles sont manquantes
                if (-not [System.IO.Path]::HasExtension($Path)) {
                    foreach ($ext in @('.psm1', '.psd1', '.ps1')) {
                        $pathWithExt = $Path + $ext
                        if (Test-Path -Path $pathWithExt -PathType Leaf) {
                            return $pathWithExt
                        }
                    }
                }
            } else {
                # Chemin relatif
                $resolvedPath = Join-Path -Path $BaseDirectory -ChildPath $Path

                if (Test-Path -Path $resolvedPath -PathType Leaf) {
                    return $resolvedPath
                }

                # Essayer d'ajouter les extensions courantes si elles sont manquantes
                if (-not [System.IO.Path]::HasExtension($resolvedPath)) {
                    foreach ($ext in @('.psm1', '.psd1', '.ps1')) {
                        $pathWithExt = $resolvedPath + $ext
                        if (Test-Path -Path $pathWithExt -PathType Leaf) {
                            return $pathWithExt
                        }
                    }
                }

                # Essayer de résoudre le chemin en utilisant des chemins relatifs courants
                $commonRelativePaths = @(
                    $Path,
                    "modules\$Path",
                    "Modules\$Path",
                    "lib\$Path",
                    "libs\$Path",
                    "library\$Path",
                    "dependencies\$Path",
                    "..\modules\$Path",
                    "..\Modules\$Path",
                    "..\..\modules\$Path",
                    "..\..\Modules\$Path"
                )

                foreach ($relativePath in $commonRelativePaths) {
                    $fullPath = Join-Path -Path $BaseDirectory -ChildPath $relativePath

                    if (Test-Path -Path $fullPath -PathType Leaf) {
                        return $fullPath
                    }

                    # Essayer d'ajouter les extensions courantes si elles sont manquantes
                    if (-not [System.IO.Path]::HasExtension($fullPath)) {
                        foreach ($ext in @('.psm1', '.psd1', '.ps1')) {
                            $pathWithExt = $fullPath + $ext
                            if (Test-Path -Path $pathWithExt -PathType Leaf) {
                                return $pathWithExt
                            }
                        }
                    }
                }
            }

            return $null
        }
    } catch {
        Write-Error "Erreur lors de la résolution du chemin du module : $_"
        return $null
    }
}

#endregion

#region Public Functions

function Find-ImportModuleInstruction {
    <#
    .SYNOPSIS
        Détecte les instructions Import-Module dans un script PowerShell.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour détecter les instructions Import-Module
        et extraire les informations sur les modules importés, en utilisant l'analyse AST pour
        une détection précise.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER ResolveModulePaths
        Indique si les chemins des modules doivent être résolus.

    .PARAMETER BaseDirectory
        Répertoire de base pour résoudre les chemins relatifs des modules.
        Par défaut, utilise le répertoire du script ou le répertoire courant.

    .EXAMPLE
        Find-ImportModuleInstruction -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $content = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Find-ImportModuleInstruction -ScriptContent $content -ResolveModulePaths

    .OUTPUTS
        System.Collections.Generic.List[PSObject]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [string]$BaseDirectory
    )

    try {
        # Déterminer le répertoire de base
        if (-not $BaseDirectory) {
            if ($PSCmdlet.ParameterSetName -eq "ByPath") {
                $BaseDirectory = Split-Path -Path $FilePath -Parent
            } else {
                $BaseDirectory = (Get-Location).Path
            }
        }

        # Obtenir les instructions Import-Module
        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            $importModules = Get-ImportModuleAst -FilePath $FilePath
        } else {
            $importModules = Get-ImportModuleAst -ScriptContent $ScriptContent
        }

        # Résoudre les chemins des modules si demandé
        if ($ResolveModulePaths) {
            foreach ($module in $importModules) {
                if ($module.Path) {
                    $module.Path = Resolve-ModulePath -Path $module.Path -BaseDirectory $BaseDirectory
                } elseif ($module.Name) {
                    $resolvedPath = Resolve-ModulePath -Name $module.Name -BaseDirectory $BaseDirectory
                    if ($resolvedPath) {
                        $module.Path = $resolvedPath
                    }
                }
            }
        }

        return $importModules
    } catch {
        Write-Error "Erreur lors de la recherche des instructions Import-Module : $_"
        return @()
    }
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Find-ImportModuleInstruction
