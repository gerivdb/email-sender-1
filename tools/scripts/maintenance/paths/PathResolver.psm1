#Requires -Version 5.1
<#
.SYNOPSIS
    Module de rÃ©solution de chemins centralisÃ© avec recherche intelligente et cache.
.DESCRIPTION
    Ce module fournit des fonctions pour rÃ©soudre les chemins de fichiers et de rÃ©pertoires
    de maniÃ¨re intelligente, avec cache et validation.
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

# Variables globales pour le cache des chemins
$script:PathCache = @{}
$script:LastAccessTime = @{}
$script:PathMappings = @{}
$script:SearchPaths = @()
$script:MaxCacheAge = New-TimeSpan -Hours 1
$script:CacheEnabled = $true
$script:DefaultSearchDepth = 3

# Initialiser les chemins de recherche par dÃ©faut
function Initialize-PathResolver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$AdditionalSearchPaths,

        [Parameter(Mandatory = $false)]
        [hashtable]$PathMappings,

        [Parameter(Mandatory = $false)]
        [int]$CacheMaxAgeHours = 1,

        [Parameter(Mandatory = $false)]
        [switch]$DisableCache
    )

    # RÃ©initialiser les variables globales
    $script:PathCache = @{}
    $script:LastAccessTime = @{}
    $script:SearchPaths = @()

    # DÃ©finir les chemins de recherche par dÃ©faut
    $script:SearchPaths += $PSScriptRoot
    $script:SearchPaths += (Split-Path -Parent $PSScriptRoot)
    $script:SearchPaths += (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

    # Ajouter les chemins de recherche supplÃ©mentaires
    if ($AdditionalSearchPaths) {
        foreach ($path in $AdditionalSearchPaths) {
            if (Test-Path -Path $path -PathType Container) {
                $script:SearchPaths += $path
            } else {
                Write-Warning "Le chemin de recherche '$path' n'existe pas ou n'est pas un rÃ©pertoire."
            }
        }
    }

    # DÃ©finir les mappings de chemins
    if ($PathMappings) {
        $script:PathMappings = $PathMappings
    }

    # DÃ©finir l'Ã¢ge maximum du cache
    if ($CacheMaxAgeHours -ne 1) {
        $script:MaxCacheAge = New-TimeSpan -Hours $CacheMaxAgeHours
    }

    # Activer ou dÃ©sactiver le cache
    $script:CacheEnabled = -not $DisableCache

    Write-Verbose "PathResolver initialisÃ© avec $(($script:SearchPaths | Select-Object -Unique).Count) chemins de recherche uniques."
    Write-Verbose "Cache $(if ($script:CacheEnabled) { 'activÃ©' } else { 'dÃ©sactivÃ©' }) avec un Ã¢ge maximum de $($script:MaxCacheAge.TotalHours) heures."
}

<#
.SYNOPSIS
    RÃ©sout un chemin de fichier ou de rÃ©pertoire de maniÃ¨re intelligente.
.DESCRIPTION
    Cette fonction rÃ©sout un chemin de fichier ou de rÃ©pertoire en utilisant une recherche intelligente,
    des mappings de chemins et un cache pour amÃ©liorer les performances.
.PARAMETER Path
    Chemin Ã  rÃ©soudre. Peut Ãªtre un chemin relatif ou absolu.
.PARAMETER SearchDepth
    Profondeur de recherche pour les chemins relatifs.
.PARAMETER FileType
    Type de fichier Ã  rechercher. Si spÃ©cifiÃ©, seuls les fichiers de ce type seront retournÃ©s.
.PARAMETER UseCache
    Indique si le cache doit Ãªtre utilisÃ© pour les rÃ©solutions rÃ©centes.
.PARAMETER ValidateOnly
    Indique si la fonction doit uniquement valider le chemin sans le rÃ©soudre.
.PARAMETER ThrowOnError
    Indique si une exception doit Ãªtre levÃ©e en cas d'erreur.
.EXAMPLE
    Get-ScriptPath -Path "scripts\maintenance\paths\PathResolver.psm1"
.EXAMPLE
    Get-ScriptPath -Path "config.json" -SearchDepth 5
#>
function Get-ScriptPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$SearchDepth = $script:DefaultSearchDepth,

        [Parameter(Mandatory = $false)]
        [string]$FileType,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache,

        [Parameter(Mandatory = $false)]
        [switch]$ValidateOnly,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError
    )

    # Normaliser le chemin
    $normalizedPath = $Path.Replace('/', '\')

    # VÃ©rifier si le chemin est dans le cache
    if ($UseCache -and $script:CacheEnabled -and $script:PathCache.ContainsKey($normalizedPath)) {
        $lastAccess = $script:LastAccessTime[$normalizedPath]
        $cacheAge = (Get-Date) - $lastAccess

        if ($cacheAge -lt $script:MaxCacheAge) {
            Write-Verbose "Utilisation du chemin en cache pour '$normalizedPath' (Ã¢ge: $($cacheAge.TotalMinutes) minutes)"
            $resolvedPath = $script:PathCache[$normalizedPath]

            # Mettre Ã  jour le temps d'accÃ¨s
            $script:LastAccessTime[$normalizedPath] = Get-Date

            # Valider le chemin si nÃ©cessaire
            if ($ValidateOnly) {
                return Test-Path -Path $resolvedPath
            }

            return $resolvedPath
        }
    }

    # VÃ©rifier si le chemin est un chemin absolu
    if ([System.IO.Path]::IsPathRooted($normalizedPath)) {
        if (Test-Path -Path $normalizedPath) {
            # Mettre Ã  jour le cache
            if ($script:CacheEnabled) {
                $script:PathCache[$normalizedPath] = $normalizedPath
                $script:LastAccessTime[$normalizedPath] = Get-Date
            }

            # Valider le chemin si nÃ©cessaire
            if ($ValidateOnly) {
                return $true
            }

            return $normalizedPath
        } else {
            $errorMessage = "Le chemin absolu '$normalizedPath' n'existe pas."

            if ($ThrowOnError) {
                throw $errorMessage
            } else {
                Write-Warning $errorMessage

                # Valider le chemin si nÃ©cessaire
                if ($ValidateOnly) {
                    return $false
                }

                return $null
            }
        }
    }

    # VÃ©rifier si le chemin est dans les mappings
    foreach ($key in $script:PathMappings.Keys) {
        if ($normalizedPath -like "$key*") {
            $mappedPath = $normalizedPath -replace "^$key", $script:PathMappings[$key]

            if (Test-Path -Path $mappedPath) {
                # Mettre Ã  jour le cache
                if ($script:CacheEnabled) {
                    $script:PathCache[$normalizedPath] = $mappedPath
                    $script:LastAccessTime[$normalizedPath] = Get-Date
                }

                # Valider le chemin si nÃ©cessaire
                if ($ValidateOnly) {
                    return $true
                }

                return $mappedPath
            }
        }
    }

    # Rechercher le chemin dans les chemins de recherche
    foreach ($searchPath in ($script:SearchPaths | Select-Object -Unique)) {
        $potentialPath = Join-Path -Path $searchPath -ChildPath $normalizedPath

        if (Test-Path -Path $potentialPath) {
            # Filtrer par type de fichier si nÃ©cessaire
            if ($FileType -and (Get-Item -Path $potentialPath).Extension -ne ".$FileType") {
                continue
            }

            # Mettre Ã  jour le cache
            if ($script:CacheEnabled) {
                $script:PathCache[$normalizedPath] = $potentialPath
                $script:LastAccessTime[$normalizedPath] = Get-Date
            }

            # Valider le chemin si nÃ©cessaire
            if ($ValidateOnly) {
                return $true
            }

            return $potentialPath
        }
    }

    # Recherche rÃ©cursive dans les chemins de recherche
    if ($SearchDepth -gt 0) {
        foreach ($searchPath in ($script:SearchPaths | Select-Object -Unique)) {
            # Obtenir tous les sous-rÃ©pertoires jusqu'Ã  la profondeur spÃ©cifiÃ©e
            $directories = @($searchPath)
            $allDirectories = @($searchPath)

            for ($depth = 1; $depth -le $SearchDepth; $depth++) {
                $newDirectories = @()

                foreach ($dir in $directories) {
                    try {
                        $subDirs = Get-ChildItem -Path $dir -Directory -ErrorAction SilentlyContinue
                        if ($subDirs) {
                            $newDirectories += $subDirs.FullName
                            $allDirectories += $subDirs.FullName
                        }
                    } catch {
                        Write-Verbose "Erreur lors de l'accÃ¨s au rÃ©pertoire '$dir': $($_.Exception.Message)"
                    }
                }

                $directories = $newDirectories
                if ($directories.Count -eq 0) { break }
            }

            $directories = $allDirectories

            # Rechercher le fichier dans tous les rÃ©pertoires
            foreach ($dir in $directories) {
                $potentialPath = Join-Path -Path $dir -ChildPath $normalizedPath

                if (Test-Path -Path $potentialPath) {
                    # Filtrer par type de fichier si nÃ©cessaire
                    if ($FileType -and (Get-Item -Path $potentialPath).Extension -ne ".$FileType") {
                        continue
                    }

                    # Mettre Ã  jour le cache
                    if ($script:CacheEnabled) {
                        $script:PathCache[$normalizedPath] = $potentialPath
                        $script:LastAccessTime[$normalizedPath] = Get-Date
                    }

                    # Valider le chemin si nÃ©cessaire
                    if ($ValidateOnly) {
                        return $true
                    }

                    return $potentialPath
                }
            }
        }
    }

    # Si le chemin n'a pas Ã©tÃ© trouvÃ©
    $errorMessage = "Le chemin '$normalizedPath' n'a pas pu Ãªtre rÃ©solu."

    if ($ThrowOnError) {
        throw $errorMessage
    } else {
        Write-Warning $errorMessage

        # Valider le chemin si nÃ©cessaire
        if ($ValidateOnly) {
            return $false
        }

        return $null
    }
}

<#
.SYNOPSIS
    Valide un chemin de fichier ou de rÃ©pertoire avant exÃ©cution.
.DESCRIPTION
    Cette fonction valide un chemin de fichier ou de rÃ©pertoire avant exÃ©cution,
    en vÃ©rifiant son existence, ses permissions, et d'autres critÃ¨res de sÃ©curitÃ©.
.PARAMETER Path
    Chemin Ã  valider. Peut Ãªtre un chemin relatif ou absolu.
.PARAMETER RequiredPermissions
    Permissions requises pour le chemin. Valeurs possibles : "Read", "Write", "Execute", "ReadWrite", "ReadExecute", "WriteExecute", "FullControl".
.PARAMETER RequiredAttributes
    Attributs requis pour le chemin. Valeurs possibles : "Archive", "Compressed", "Device", "Directory", "Encrypted", "Hidden", "Normal", "NotContentIndexed", "Offline", "ReadOnly", "ReparsePoint", "SparseFile", "System", "Temporary".
.PARAMETER FileType
    Type de fichier requis. Si spÃ©cifiÃ©, seuls les fichiers de ce type seront validÃ©s.
.PARAMETER MinimumSize
    Taille minimale requise pour le fichier, en octets.
.PARAMETER MaximumSize
    Taille maximale autorisÃ©e pour le fichier, en octets.
.PARAMETER ThrowOnError
    Indique si une exception doit Ãªtre levÃ©e en cas d'erreur.
.EXAMPLE
    Test-ScriptPath -Path "scripts\maintenance\paths\PathResolver.psm1" -RequiredPermissions "Read"
.EXAMPLE
    Test-ScriptPath -Path "config.json" -FileType "json" -ThrowOnError
#>
function Test-ScriptPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Read", "Write", "Execute", "ReadWrite", "ReadExecute", "WriteExecute", "FullControl")]
        [string]$RequiredPermissions,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Archive", "Compressed", "Device", "Directory", "Encrypted", "Hidden", "Normal", "NotContentIndexed", "Offline", "ReadOnly", "ReparsePoint", "SparseFile", "System", "Temporary")]
        [string[]]$RequiredAttributes,

        [Parameter(Mandatory = $false)]
        [string]$FileType,

        [Parameter(Mandatory = $false)]
        [long]$MinimumSize,

        [Parameter(Mandatory = $false)]
        [long]$MaximumSize,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError
    )

    # RÃ©soudre le chemin
    $resolvedPath = Get-ScriptPath -Path $Path -UseCache -ThrowOnError:$ThrowOnError

    if (-not $resolvedPath) {
        return $false
    }

    try {
        # VÃ©rifier l'existence du chemin
        if (-not (Test-Path -Path $resolvedPath)) {
            $errorMessage = "Le chemin '$resolvedPath' n'existe pas."

            if ($ThrowOnError) {
                throw $errorMessage
            } else {
                Write-Warning $errorMessage
                return $false
            }
        }

        # Obtenir les informations sur le fichier ou le rÃ©pertoire
        $item = Get-Item -Path $resolvedPath

        # VÃ©rifier le type de fichier
        if ($FileType -and $item.Extension -ne ".$FileType") {
            $errorMessage = "Le fichier '$resolvedPath' n'est pas du type '$FileType'."

            if ($ThrowOnError) {
                throw $errorMessage
            } else {
                Write-Warning $errorMessage
                return $false
            }
        }

        # VÃ©rifier les attributs
        if ($RequiredAttributes) {
            foreach ($attr in $RequiredAttributes) {
                if (-not ($item.Attributes -band [System.IO.FileAttributes]::$attr)) {
                    $errorMessage = "Le chemin '$resolvedPath' n'a pas l'attribut '$attr'."

                    if ($ThrowOnError) {
                        throw $errorMessage
                    } else {
                        Write-Warning $errorMessage
                        return $false
                    }
                }
            }
        }

        # VÃ©rifier la taille du fichier
        if ($item -is [System.IO.FileInfo]) {
            if ($MinimumSize -and $item.Length -lt $MinimumSize) {
                $errorMessage = "Le fichier '$resolvedPath' est trop petit (taille: $($item.Length) octets, minimum requis: $MinimumSize octets)."

                if ($ThrowOnError) {
                    throw $errorMessage
                } else {
                    Write-Warning $errorMessage
                    return $false
                }
            }

            if ($MaximumSize -and $item.Length -gt $MaximumSize) {
                $errorMessage = "Le fichier '$resolvedPath' est trop grand (taille: $($item.Length) octets, maximum autorisÃ©: $MaximumSize octets)."

                if ($ThrowOnError) {
                    throw $errorMessage
                } else {
                    Write-Warning $errorMessage
                    return $false
                }
            }
        }

        # VÃ©rifier les permissions
        if ($RequiredPermissions) {
            $acl = Get-Acl -Path $resolvedPath
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $userRights = $null

            foreach ($accessRule in $acl.Access) {
                if ($accessRule.IdentityReference.Value -eq $currentUser) {
                    $userRights = $accessRule.FileSystemRights
                    break
                }
            }

            if (-not $userRights) {
                $errorMessage = "L'utilisateur actuel n'a pas de droits explicites sur le chemin '$resolvedPath'."

                if ($ThrowOnError) {
                    throw $errorMessage
                } else {
                    Write-Warning $errorMessage
                    return $false
                }
            }

            $requiredRight = switch ($RequiredPermissions) {
                "Read" { [System.Security.AccessControl.FileSystemRights]::Read }
                "Write" { [System.Security.AccessControl.FileSystemRights]::Write }
                "Execute" { [System.Security.AccessControl.FileSystemRights]::ExecuteFile }
                "ReadWrite" { [System.Security.AccessControl.FileSystemRights]::Read -bor [System.Security.AccessControl.FileSystemRights]::Write }
                "ReadExecute" { [System.Security.AccessControl.FileSystemRights]::Read -bor [System.Security.AccessControl.FileSystemRights]::ExecuteFile }
                "WriteExecute" { [System.Security.AccessControl.FileSystemRights]::Write -bor [System.Security.AccessControl.FileSystemRights]::ExecuteFile }
                "FullControl" { [System.Security.AccessControl.FileSystemRights]::FullControl }
            }

            if (-not ($userRights -band $requiredRight)) {
                $errorMessage = "L'utilisateur actuel n'a pas les permissions '$RequiredPermissions' requises sur le chemin '$resolvedPath'."

                if ($ThrowOnError) {
                    throw $errorMessage
                } else {
                    Write-Warning $errorMessage
                    return $false
                }
            }
        }

        # Toutes les validations ont rÃ©ussi
        return $true
    } catch {
        if ($ThrowOnError) {
            throw $_
        } else {
            Write-Warning "Erreur lors de la validation du chemin '$resolvedPath': $($_.Exception.Message)"
            return $false
        }
    }
}

<#
.SYNOPSIS
    Efface le cache des chemins.
.DESCRIPTION
    Cette fonction efface le cache des chemins, forÃ§ant ainsi
    la rÃ©solution de nouveaux chemins lors des prochains appels Ã  Get-ScriptPath.
.PARAMETER Path
    Chemin Ã  effacer du cache. Si non spÃ©cifiÃ©, tout le cache est effacÃ©.
.EXAMPLE
    Clear-PathCache
.EXAMPLE
    Clear-PathCache -Path "scripts\maintenance\paths\PathResolver.psm1"
#>
function Clear-PathCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    if ($Path) {
        # Normaliser le chemin
        $normalizedPath = $Path.Replace('/', '\')

        # Effacer un chemin spÃ©cifique du cache
        if ($script:PathCache.ContainsKey($normalizedPath)) {
            $script:PathCache.Remove($normalizedPath)
            $script:LastAccessTime.Remove($normalizedPath)
            Write-Verbose "Cache effacÃ© pour '$normalizedPath'"
        } else {
            Write-Verbose "Aucune entrÃ©e de cache trouvÃ©e pour '$normalizedPath'"
        }
    } else {
        # Effacer tout le cache
        $script:PathCache.Clear()
        $script:LastAccessTime.Clear()
        Write-Verbose "Cache entiÃ¨rement effacÃ©"
    }
}

<#
.SYNOPSIS
    Obtient des statistiques sur le cache des chemins.
.DESCRIPTION
    Cette fonction retourne des statistiques sur le cache des chemins,
    comme le nombre d'entrÃ©es, l'Ã¢ge moyen, et les chemins les plus utilisÃ©s.
.PARAMETER Path
    Chemin pour lequel obtenir des statistiques.
    Si non spÃ©cifiÃ©, des statistiques pour tous les chemins sont retournÃ©es.
.EXAMPLE
    Get-PathStatistics
.EXAMPLE
    Get-PathStatistics -Path "scripts\maintenance\paths\PathResolver.psm1"
#>
function Get-PathStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    if ($Path) {
        # Normaliser le chemin
        $normalizedPath = $Path.Replace('/', '\')

        # CrÃ©er un objet de statistiques par dÃ©faut pour Ã©viter les erreurs de test
        $result = [PSCustomObject]@{
            Path            = $normalizedPath
            ResolvedPath    = $null
            LastAccessTime  = $null
            CacheAge        = $null
            CacheAgeMinutes = 0
        }

        # Obtenir des statistiques pour un chemin spÃ©cifique
        if ($script:PathCache.ContainsKey($normalizedPath)) {
            $lastAccess = $script:LastAccessTime[$normalizedPath]
            $cacheAge = (Get-Date) - $lastAccess

            $result.ResolvedPath = $script:PathCache[$normalizedPath]
            $result.LastAccessTime = $lastAccess
            $result.CacheAge = $cacheAge
            $result.CacheAgeMinutes = [math]::Round($cacheAge.TotalMinutes, 2)
        } else {
            Write-Warning "Aucune entrÃ©e de cache trouvÃ©e pour '$normalizedPath'"
        }

        return $result
    } else {
        # Obtenir des statistiques globales
        $cacheEntries = $script:PathCache.Count
        $averageAge = if ($cacheEntries -gt 0) {
            $totalAge = 0
            foreach ($path in $script:PathCache.Keys) {
                $lastAccess = $script:LastAccessTime[$path]
                $cacheAge = (Get-Date) - $lastAccess
                $totalAge += $cacheAge.TotalMinutes
            }
            [math]::Round($totalAge / $cacheEntries, 2)
        } else {
            0
        }

        # Obtenir les chemins les plus rÃ©cemment utilisÃ©s
        $recentPaths = @()
        foreach ($path in $script:PathCache.Keys) {
            $recentPaths += [PSCustomObject]@{
                Path            = $path
                ResolvedPath    = $script:PathCache[$path]
                LastAccessTime  = $script:LastAccessTime[$path]
                CacheAge        = (Get-Date) - $script:LastAccessTime[$path]
                CacheAgeMinutes = [math]::Round(((Get-Date) - $script:LastAccessTime[$path]).TotalMinutes, 2)
            }
        }
        $recentPaths = $recentPaths | Sort-Object -Property LastAccessTime -Descending

        return [PSCustomObject]@{
            CacheEntries      = $cacheEntries
            AverageAgeMinutes = $averageAge
            CacheEnabled      = $script:CacheEnabled
            MaxCacheAgeHours  = $script:MaxCacheAge.TotalHours
            SearchPaths       = $script:SearchPaths | Select-Object -Unique
            PathMappings      = $script:PathMappings
            RecentPaths       = $recentPaths
        }
    }
}

<#
.SYNOPSIS
    Ajoute un mapping de chemin.
.DESCRIPTION
    Cette fonction ajoute un mapping de chemin, qui sera utilisÃ© pour rÃ©soudre les chemins.
.PARAMETER Prefix
    PrÃ©fixe du chemin Ã  mapper.
.PARAMETER Target
    Cible du mapping.
.EXAMPLE
    Add-PathMapping -Prefix "scripts" -Target "C:\Projects\MyProject\scripts"
#>
function Add-PathMapping {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prefix,

        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    # Normaliser les chemins
    $normalizedPrefix = $Prefix.Replace('/', '\').TrimEnd('\')
    $normalizedTarget = $Target.Replace('/', '\').TrimEnd('\')

    # VÃ©rifier si la cible existe
    if (-not (Test-Path -Path $normalizedTarget -PathType Container)) {
        Write-Warning "La cible du mapping '$normalizedTarget' n'existe pas ou n'est pas un rÃ©pertoire."
    }

    # Ajouter le mapping
    $script:PathMappings[$normalizedPrefix] = $normalizedTarget

    Write-Verbose "Mapping ajoutÃ©: '$normalizedPrefix' -> '$normalizedTarget'"

    # Effacer le cache pour les chemins qui commencent par le prÃ©fixe
    $pathsToRemove = @()
    foreach ($path in $script:PathCache.Keys) {
        if ($path -like "$normalizedPrefix*") {
            $pathsToRemove += $path
        }
    }

    foreach ($path in $pathsToRemove) {
        $script:PathCache.Remove($path)
        $script:LastAccessTime.Remove($path)
    }

    Write-Verbose "$($pathsToRemove.Count) entrÃ©es de cache effacÃ©es pour le prÃ©fixe '$normalizedPrefix'"
}

<#
.SYNOPSIS
    Supprime un mapping de chemin.
.DESCRIPTION
    Cette fonction supprime un mapping de chemin.
.PARAMETER Prefix
    PrÃ©fixe du chemin Ã  supprimer.
.EXAMPLE
    Remove-PathMapping -Prefix "scripts"
#>
function Remove-PathMapping {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    # Normaliser le prÃ©fixe
    $normalizedPrefix = $Prefix.Replace('/', '\').TrimEnd('\')

    # Supprimer le mapping
    if ($script:PathMappings.ContainsKey($normalizedPrefix)) {
        $script:PathMappings.Remove($normalizedPrefix)
        Write-Verbose "Mapping supprimÃ©: '$normalizedPrefix'"

        # Effacer le cache pour les chemins qui commencent par le prÃ©fixe
        $pathsToRemove = @()
        foreach ($path in $script:PathCache.Keys) {
            if ($path -like "$normalizedPrefix*") {
                $pathsToRemove += $path
            }
        }

        foreach ($path in $pathsToRemove) {
            $script:PathCache.Remove($path)
            $script:LastAccessTime.Remove($path)
        }

        Write-Verbose "$($pathsToRemove.Count) entrÃ©es de cache effacÃ©es pour le prÃ©fixe '$normalizedPrefix'"
    } else {
        Write-Warning "Aucun mapping trouvÃ© pour le prÃ©fixe '$normalizedPrefix'"
    }
}

# Initialiser le module
Initialize-PathResolver

# Exporter les fonctions du module
Export-ModuleMember -Function Get-ScriptPath, Test-ScriptPath, Clear-PathCache, Get-PathStatistics, Add-PathMapping, Remove-PathMapping, Initialize-PathResolver
