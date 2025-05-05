#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'analyse des dÃ©pendances dans le code source PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser le code source PowerShell
    et dÃ©tecter les dÃ©pendances via les appels Import-Module, etc.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
#>

function Get-ModuleDependenciesFromCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Warning "Path does not exist: $ModulePath"
        return $dependencies
    }

    # DÃ©terminer les fichiers Ã  analyser
    $filesToAnalyze = @()
    if (Test-Path -Path $ModulePath -PathType Leaf) {
        # C'est un fichier unique
        $filesToAnalyze += $ModulePath
    } else {
        # C'est un rÃ©pertoire
        $filter = "*.ps1", "*.psm1", "*.psd1"
        $filesToAnalyze += Get-ChildItem -Path $ModulePath -Include $filter -File -Recurse:$Recurse
    }

    # Analyser chaque fichier
    foreach ($file in $filesToAnalyze) {
        Write-Verbose "Analyzing file: $($file.FullName)"

        # Lire le contenu du fichier
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        } catch {
            Write-Warning "Error reading file $($file.FullName): $_"
            continue
        }

        # DÃ©tecter les Import-Module avec diffÃ©rents formats
        # Format 1: Import-Module ModuleName
        # Format 2: Import-Module -Name ModuleName
        # Format 3: Import-Module -Name "ModuleName"
        # Format 4: Import-Module -Name 'ModuleName'
        # Format 5: Import-Module -Path "C:\Path\To\Module.psd1"
        $importMatches = [regex]::Matches($content, '(?m)^\s*Import-Module\s+(?:-Name\s+)?([''"]?)([^''"\s,;]+)\1|^\s*Import-Module\s+-Name\s+([''"]?)([^''"\s,;]+)\3|^\s*Import-Module\s+-Path\s+([''"]?)([^''"\s,;]+)\5')

        foreach ($match in $importMatches) {
            # Extraire le nom du module en fonction du format dÃ©tectÃ©
            $moduleName = $null
            $isPath = $false
            
            if ($match.Groups[2].Success) {
                # Format 1: Import-Module ModuleName ou Format 2: Import-Module -Name ModuleName
                $moduleName = $match.Groups[2].Value
            } elseif ($match.Groups[4].Success) {
                # Format 3/4: Import-Module -Name "ModuleName" ou Import-Module -Name 'ModuleName'
                $moduleName = $match.Groups[4].Value
            } elseif ($match.Groups[6].Success) {
                # Format 5: Import-Module -Path "C:\Path\To\Module.psd1"
                $modulePath = $match.Groups[6].Value
                $isPath = $true
                
                # Extraire le nom du module Ã  partir du chemin
                if ($modulePath -match '\.ps[md]1$') {
                    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
                } else {
                    $moduleName = [System.IO.Path]::GetFileName($modulePath)
                }
            }
            
            # VÃ©rifier si un nom de module a Ã©tÃ© trouvÃ©
            if (-not $moduleName) {
                continue
            }

            # Ignorer les modules systÃ¨me si demandÃ©
            if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                Write-Verbose "System module ignored: $moduleName"
                continue
            }

            # RÃ©soudre le chemin du module si demandÃ©
            if (-not $isPath) {
                $modulePath = $null
                if ($ResolveModulePaths) {
                    $modulePath = Find-ModulePath -ModuleName $moduleName
                }
            } else {
                # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du module
                if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                    $moduleDir = [System.IO.Path]::GetDirectoryName($file.FullName)
                    $modulePath = Join-Path -Path $moduleDir -ChildPath $modulePath
                }
            }

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    GUID    = $null
                    Path    = $modulePath
                    Type    = "ImportModule"
                    Source  = $file.FullName
                })
        }

        # DÃ©tecter les Using module
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+module\s+([''"]?)([^''"\s,;]+)\1')

        foreach ($match in $usingMatches) {
            $moduleName = $match.Groups[2].Value
            $isPath = $false

            # VÃ©rifier si c'est un chemin ou un nom de module
            if ($moduleName -match '\.ps[md]1$' -or $moduleName -match '[\\/]') {
                $isPath = $true
                $modulePath = $moduleName

                # Extraire le nom du module Ã  partir du chemin
                if ($modulePath -match '\.ps[md]1$') {
                    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
                } else {
                    $moduleName = [System.IO.Path]::GetFileName($modulePath)
                }

                # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du module
                if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                    $moduleDir = [System.IO.Path]::GetDirectoryName($file.FullName)
                    $modulePath = Join-Path -Path $moduleDir -ChildPath $modulePath
                }
            } else {
                # C'est un nom de module
                $modulePath = $null
                if ($ResolveModulePaths) {
                    $modulePath = Find-ModulePath -ModuleName $moduleName
                }
            }

            # Ignorer les modules systÃ¨me si demandÃ©
            if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                Write-Verbose "System module ignored: $moduleName"
                continue
            }

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    GUID    = $null
                    Path    = $modulePath
                    Type    = "UsingModule"
                    Source  = $file.FullName
                })
        }
    }

    return $dependencies
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ModuleDependenciesFromCode
