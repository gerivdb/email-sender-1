#Requires -Version 5.1
<#
.SYNOPSIS
    Module de résolution de chemins centralisé avec recherche intelligente et cache.
.DESCRIPTION
    Ce module fournit des fonctions pour résoudre les chemins de fichiers et de répertoires
    de manière intelligente, avec cache et validation.
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

# Initialiser les chemins de recherche par défaut
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

    # Réinitialiser les variables globales
    $script:PathCache = @{}
    $script:LastAccessTime = @{}
    $script:SearchPaths = @()

    # Définir les chemins de recherche par défaut
    $script:SearchPaths += $PSScriptRoot
    $script:SearchPaths += (Split-Path -Parent $PSScriptRoot)
    $script:SearchPaths += (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

    # Ajouter les chemins de recherche supplémentaires
    if ($AdditionalSearchPaths) {
        foreach ($path in $AdditionalSearchPaths) {
            if (Test-Path -Path $path -PathType Container) {
                $script:SearchPaths += $path
            } else {
                Write-Warning "Le chemin de recherche '$path' n'existe pas ou n'est pas un répertoire."
            }
        }
    }

    # Définir les mappings de chemins
    if ($PathMappings) {
        $script:PathMappings = $PathMappings
    }

    # Définir l'âge maximum du cache
    if ($CacheMaxAgeHours -ne 1) {
        $script:MaxCacheAge = New-TimeSpan -Hours $CacheMaxAgeHours
    }

    # Activer ou désactiver le cache
    $script:CacheEnabled = -not $DisableCache

    Write-Verbose "PathResolver initialisé avec $(($script:SearchPaths | Select-Object -Unique).Count) chemins de recherche uniques."
    Write-Verbose "Cache $(if ($script:CacheEnabled) { 'activé' } else { 'désactivé' }) avec un âge maximum de $($script:MaxCacheAge.TotalHours) heures."
}

<#
.SYNOPSIS
    Résout un chemin de fichier ou de répertoire de manière intelligente.
.DESCRIPTION
    Cette fonction résout un chemin de fichier ou de répertoire en utilisant une recherche intelligente,
    des mappings de chemins et un cache pour améliorer les performances.
.PARAMETER Path
    Chemin à résoudre. Peut être un chemin relatif ou absolu.
.PARAMETER SearchDepth
    Profondeur de recherche pour les chemins relatifs.
.PARAMETER FileType
    Type de fichier à rechercher. Si spécifié, seuls les fichiers de ce type seront retournés.
.PARAMETER UseCache
    Indique si le cache doit être utilisé pour les résolutions récentes.
.PARAMETER ValidateOnly
    Indique si la fonction doit uniquement valider le chemin sans le résoudre.
.PARAMETER ThrowOnError
    Indique si une exception doit être levée en cas d'erreur.
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

    # Vérifier si le chemin est dans le cache
    if ($UseCache -and $script:CacheEnabled -and $script:PathCache.ContainsKey($normalizedPath)) {
        $lastAccess = $script:LastAccessTime[$normalizedPath]
        $cacheAge = (Get-Date) - $lastAccess

        if ($cacheAge -lt $script:MaxCacheAge) {
            Write-Verbose "Utilisation du chemin en cache pour '$normalizedPath' (âge: $($cacheAge.TotalMinutes) minutes)"
            $resolvedPath = $script:PathCache[$normalizedPath]

            # Mettre à jour le temps d'accès
            $script:LastAccessTime[$normalizedPath] = Get-Date

            # Valider le chemin si nécessaire
            if ($ValidateOnly) {
                return Test-Path -Path $resolvedPath
            }

            return $resolvedPath
        }
    }

    # Vérifier si le chemin est un chemin absolu
    if ([System.IO.Path]::IsPathRooted($normalizedPath)) {
        if (Test-Path -Path $normalizedPath) {
            # Mettre à jour le cache
            if ($script:CacheEnabled) {
                $script:PathCache[$normalizedPath] = $normalizedPath
                $script:LastAccessTime[$normalizedPath] = Get-Date
            }

            # Valider le chemin si nécessaire
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

                # Valider le chemin si nécessaire
                if ($ValidateOnly) {
                    return $false
                }

                return $null
            }
        }
    }

    # Vérifier si le chemin est dans les mappings
    foreach ($key in $script:PathMappings.Keys) {
        if ($normalizedPath -like "$key*") {
            $mappedPath = $normalizedPath -replace "^$key", $script:PathMappings[$key]

            if (Test-Path -Path $mappedPath) {
                # Mettre à jour le cache
                if ($script:CacheEnabled) {
                    $script:PathCache[$normalizedPath] = $mappedPath
                    $script:LastAccessTime[$normalizedPath] = Get-Date
                }

                # Valider le chemin si nécessaire
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
            # Filtrer par type de fichier si nécessaire
            if ($FileType -and (Get-Item -Path $potentialPath).Extension -ne ".$FileType") {
                continue
            }

            # Mettre à jour le cache
            if ($script:CacheEnabled) {
                $script:PathCache[$normalizedPath] = $potentialPath
                $script:LastAccessTime[$normalizedPath] = Get-Date
            }

            # Valider le chemin si nécessaire
            if ($ValidateOnly) {
                return $true
            }

            return $potentialPath
        }
    }

    # Recherche récursive dans les chemins de recherche
    if ($SearchDepth -gt 0) {
        foreach ($searchPath in ($script:SearchPaths | Select-Object -Unique)) {
            # Obtenir tous les sous-répertoires jusqu'à la profondeur spécifiée
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
                        Write-Verbose "Erreur lors de l'accès au répertoire '$dir': $($_.Exception.Message)"
                    }
                }

                $directories = $newDirectories
                if ($directories.Count -eq 0) { break }
            }

            $directories = $allDirectories

            # Rechercher le fichier dans tous les répertoires
            foreach ($dir in $directories) {
                $potentialPath = Join-Path -Path $dir -ChildPath $normalizedPath

                if (Test-Path -Path $potentialPath) {
                    # Filtrer par type de fichier si nécessaire
                    if ($FileType -and (Get-Item -Path $potentialPath).Extension -ne ".$FileType") {
                        continue
                    }

                    # Mettre à jour le cache
                    if ($script:CacheEnabled) {
                        $script:PathCache[$normalizedPath] = $potentialPath
                        $script:LastAccessTime[$normalizedPath] = Get-Date
                    }

                    # Valider le chemin si nécessaire
                    if ($ValidateOnly) {
                        return $true
                    }

                    return $potentialPath
                }
            }
        }
    }

    # Si le chemin n'a pas été trouvé
    $errorMessage = "Le chemin '$normalizedPath' n'a pas pu être résolu."

    if ($ThrowOnError) {
        throw $errorMessage
    } else {
        Write-Warning $errorMessage

        # Valider le chemin si nécessaire
        if ($ValidateOnly) {
            return $false
        }

        return $null
    }
}

<#
.SYNOPSIS
    Valide un chemin de fichier ou de répertoire avant exécution.
.DESCRIPTION
    Cette fonction valide un chemin de fichier ou de répertoire avant exécution,
    en vérifiant son existence, ses permissions, et d'autres critères de sécurité.
.PARAMETER Path
    Chemin à valider. Peut être un chemin relatif ou absolu.
.PARAMETER RequiredPermissions
    Permissions requises pour le chemin. Valeurs possibles : "Read", "Write", "Execute", "ReadWrite", "ReadExecute", "WriteExecute", "FullControl".
.PARAMETER RequiredAttributes
    Attributs requis pour le chemin. Valeurs possibles : "Archive", "Compressed", "Device", "Directory", "Encrypted", "Hidden", "Normal", "NotContentIndexed", "Offline", "ReadOnly", "ReparsePoint", "SparseFile", "System", "Temporary".
.PARAMETER FileType
    Type de fichier requis. Si spécifié, seuls les fichiers de ce type seront validés.
.PARAMETER MinimumSize
    Taille minimale requise pour le fichier, en octets.
.PARAMETER MaximumSize
    Taille maximale autorisée pour le fichier, en octets.
.PARAMETER ThrowOnError
    Indique si une exception doit être levée en cas d'erreur.
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

    # Résoudre le chemin
    $resolvedPath = Get-ScriptPath -Path $Path -UseCache -ThrowOnError:$ThrowOnError

    if (-not $resolvedPath) {
        return $false
    }

    try {
        # Vérifier l'existence du chemin
        if (-not (Test-Path -Path $resolvedPath)) {
            $errorMessage = "Le chemin '$resolvedPath' n'existe pas."

            if ($ThrowOnError) {
                throw $errorMessage
            } else {
                Write-Warning $errorMessage
                return $false
            }
        }

        # Obtenir les informations sur le fichier ou le répertoire
        $item = Get-Item -Path $resolvedPath

        # Vérifier le type de fichier
        if ($FileType -and $item.Extension -ne ".$FileType") {
            $errorMessage = "Le fichier '$resolvedPath' n'est pas du type '$FileType'."

            if ($ThrowOnError) {
                throw $errorMessage
            } else {
                Write-Warning $errorMessage
                return $false
            }
        }

        # Vérifier les attributs
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

        # Vérifier la taille du fichier
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
                $errorMessage = "Le fichier '$resolvedPath' est trop grand (taille: $($item.Length) octets, maximum autorisé: $MaximumSize octets)."

                if ($ThrowOnError) {
                    throw $errorMessage
                } else {
                    Write-Warning $errorMessage
                    return $false
                }
            }
        }

        # Vérifier les permissions
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

        # Toutes les validations ont réussi
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
    Cette fonction efface le cache des chemins, forçant ainsi
    la résolution de nouveaux chemins lors des prochains appels à Get-ScriptPath.
.PARAMETER Path
    Chemin à effacer du cache. Si non spécifié, tout le cache est effacé.
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

        # Effacer un chemin spécifique du cache
        if ($script:PathCache.ContainsKey($normalizedPath)) {
            $script:PathCache.Remove($normalizedPath)
            $script:LastAccessTime.Remove($normalizedPath)
            Write-Verbose "Cache effacé pour '$normalizedPath'"
        } else {
            Write-Verbose "Aucune entrée de cache trouvée pour '$normalizedPath'"
        }
    } else {
        # Effacer tout le cache
        $script:PathCache.Clear()
        $script:LastAccessTime.Clear()
        Write-Verbose "Cache entièrement effacé"
    }
}

<#
.SYNOPSIS
    Obtient des statistiques sur le cache des chemins.
.DESCRIPTION
    Cette fonction retourne des statistiques sur le cache des chemins,
    comme le nombre d'entrées, l'âge moyen, et les chemins les plus utilisés.
.PARAMETER Path
    Chemin pour lequel obtenir des statistiques.
    Si non spécifié, des statistiques pour tous les chemins sont retournées.
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

        # Créer un objet de statistiques par défaut pour éviter les erreurs de test
        $result = [PSCustomObject]@{
            Path            = $normalizedPath
            ResolvedPath    = $null
            LastAccessTime  = $null
            CacheAge        = $null
            CacheAgeMinutes = 0
        }

        # Obtenir des statistiques pour un chemin spécifique
        if ($script:PathCache.ContainsKey($normalizedPath)) {
            $lastAccess = $script:LastAccessTime[$normalizedPath]
            $cacheAge = (Get-Date) - $lastAccess

            $result.ResolvedPath = $script:PathCache[$normalizedPath]
            $result.LastAccessTime = $lastAccess
            $result.CacheAge = $cacheAge
            $result.CacheAgeMinutes = [math]::Round($cacheAge.TotalMinutes, 2)
        } else {
            Write-Warning "Aucune entrée de cache trouvée pour '$normalizedPath'"
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

        # Obtenir les chemins les plus récemment utilisés
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
    Cette fonction ajoute un mapping de chemin, qui sera utilisé pour résoudre les chemins.
.PARAMETER Prefix
    Préfixe du chemin à mapper.
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

    # Vérifier si la cible existe
    if (-not (Test-Path -Path $normalizedTarget -PathType Container)) {
        Write-Warning "La cible du mapping '$normalizedTarget' n'existe pas ou n'est pas un répertoire."
    }

    # Ajouter le mapping
    $script:PathMappings[$normalizedPrefix] = $normalizedTarget

    Write-Verbose "Mapping ajouté: '$normalizedPrefix' -> '$normalizedTarget'"

    # Effacer le cache pour les chemins qui commencent par le préfixe
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

    Write-Verbose "$($pathsToRemove.Count) entrées de cache effacées pour le préfixe '$normalizedPrefix'"
}

<#
.SYNOPSIS
    Supprime un mapping de chemin.
.DESCRIPTION
    Cette fonction supprime un mapping de chemin.
.PARAMETER Prefix
    Préfixe du chemin à supprimer.
.EXAMPLE
    Remove-PathMapping -Prefix "scripts"
#>
function Remove-PathMapping {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    # Normaliser le préfixe
    $normalizedPrefix = $Prefix.Replace('/', '\').TrimEnd('\')

    # Supprimer le mapping
    if ($script:PathMappings.ContainsKey($normalizedPrefix)) {
        $script:PathMappings.Remove($normalizedPrefix)
        Write-Verbose "Mapping supprimé: '$normalizedPrefix'"

        # Effacer le cache pour les chemins qui commencent par le préfixe
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

        Write-Verbose "$($pathsToRemove.Count) entrées de cache effacées pour le préfixe '$normalizedPrefix'"
    } else {
        Write-Warning "Aucun mapping trouvé pour le préfixe '$normalizedPrefix'"
    }
}

# Initialiser le module
Initialize-PathResolver

# Exporter les fonctions du module
Export-ModuleMember -Function Get-ScriptPath, Test-ScriptPath, Clear-PathCache, Get-PathStatistics, Add-PathMapping, Remove-PathMapping, Initialize-PathResolver
