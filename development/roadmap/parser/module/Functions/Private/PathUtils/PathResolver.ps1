<#
.SYNOPSIS
    Fonctions utilitaires pour rÃ©soudre les chemins d'accÃ¨s.

.DESCRIPTION
    Ce script contient des fonctions pour rÃ©soudre les chemins d'accÃ¨s
    relatifs et absolus dans le systÃ¨me de fichiers.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Fonction pour rÃ©soudre un chemin relatif en chemin absolu
function Resolve-RelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyExists
    )

    try {
        # Si le chemin est dÃ©jÃ  absolu, le retourner tel quel
        if ([System.IO.Path]::IsPathRooted($Path)) {
            $resolvedPath = $Path
        } else {
            # RÃ©soudre le chemin relatif par rapport au chemin de base
            $resolvedPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($BasePath, $Path))
        }

        # VÃ©rifier si le chemin existe si demandÃ©
        if ($VerifyExists -and -not (Test-Path -Path $resolvedPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin rÃ©solu '$resolvedPath' n'existe pas."
            return $null
        }

        return $resolvedPath
    } catch {
        Write-Warning "Erreur lors de la rÃ©solution du chemin relatif '$Path': $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour rÃ©soudre un chemin absolu en chemin relatif
function Resolve-AbsolutePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyExists
    )

    try {
        # VÃ©rifier si le chemin existe si demandÃ©
        if ($VerifyExists -and -not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin '$Path' n'existe pas."
            return $null
        }

        # Convertir les chemins en chemins absolus
        $absolutePath = [System.IO.Path]::GetFullPath($Path)
        $absoluteBasePath = [System.IO.Path]::GetFullPath($BasePath)

        # VÃ©rifier si le chemin est sous le chemin de base
        if (-not $absolutePath.StartsWith($absoluteBasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            # Si le chemin n'est pas sous le chemin de base, retourner le chemin absolu
            return $absolutePath
        }

        # Calculer le chemin relatif
        $relativePath = $absolutePath.Substring($absoluteBasePath.Length)

        # Supprimer le sÃ©parateur de chemin initial si prÃ©sent
        if ($relativePath.StartsWith([System.IO.Path]::DirectorySeparatorChar) -or $relativePath.StartsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
            $relativePath = $relativePath.Substring(1)
        }

        return $relativePath
    } catch {
        Write-Warning "Erreur lors de la rÃ©solution du chemin absolu '$Path': $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour normaliser un chemin
function Normalize-Path {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyExists
    )

    try {
        # Remplacer les barres obliques par des barres obliques inverses
        $normalizedPath = $Path.Replace('/', '\')

        # Supprimer les barres obliques inverses consÃ©cutives
        while ($normalizedPath -match '\\\\') {
            $normalizedPath = $normalizedPath -replace '\\\\', '\'
        }

        # Supprimer les points simples (.)
        $normalizedPath = $normalizedPath -replace '\\\.\\', '\'

        # Traiter les points doubles (..)
        while ($normalizedPath -match '\\[^\\]+\\\.\.') {
            $normalizedPath = $normalizedPath -replace '\\[^\\]+\\\.\.', ''
        }

        # Supprimer la barre oblique inverse finale si prÃ©sente
        if ($normalizedPath.EndsWith('\')) {
            $normalizedPath = $normalizedPath.Substring(0, $normalizedPath.Length - 1)
        }

        # VÃ©rifier si le chemin existe si demandÃ©
        if ($VerifyExists -and -not (Test-Path -Path $normalizedPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin normalisÃ© '$normalizedPath' n'existe pas."
            return $null
        }

        return $normalizedPath
    } catch {
        Write-Warning "Erreur lors de la normalisation du chemin '$Path': $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour trouver un fichier dans un rÃ©pertoire et ses sous-rÃ©pertoires
function Find-File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1,

        [Parameter(Mandatory = $false)]
        [switch]$FirstMatch
    )

    try {
        # VÃ©rifier si le rÃ©pertoire de base existe
        if (-not (Test-Path -Path $BasePath -PathType Container)) {
            Write-Warning "Le rÃ©pertoire de base '$BasePath' n'existe pas."
            return @()
        }

        # Rechercher le fichier
        $searchParams = @{
            Path        = $BasePath
            Filter      = $FileName
            File        = $true
            ErrorAction = 'SilentlyContinue'
        }

        if ($MaxDepth -ge 0) {
            $searchParams['Depth'] = $MaxDepth
        }

        $files = Get-ChildItem @searchParams

        # Retourner le premier rÃ©sultat si demandÃ©
        if ($FirstMatch -and $files.Count -gt 0) {
            return $files[0].FullName
        }

        # Retourner tous les rÃ©sultats
        return $files.FullName
    } catch {
        Write-Warning "Erreur lors de la recherche du fichier '$FileName': $($_.Exception.Message)"
        return @()
    }
}

# Fonction pour trouver un rÃ©pertoire dans un rÃ©pertoire et ses sous-rÃ©pertoires
function Find-Directory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryName,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1,

        [Parameter(Mandatory = $false)]
        [switch]$FirstMatch
    )

    try {
        # VÃ©rifier si le rÃ©pertoire de base existe
        if (-not (Test-Path -Path $BasePath -PathType Container)) {
            Write-Warning "Le rÃ©pertoire de base '$BasePath' n'existe pas."
            return @()
        }

        # Rechercher le rÃ©pertoire
        $searchParams = @{
            Path        = $BasePath
            Filter      = $DirectoryName
            Directory   = $true
            ErrorAction = 'SilentlyContinue'
        }

        if ($MaxDepth -ge 0) {
            $searchParams['Depth'] = $MaxDepth
        }

        $directories = Get-ChildItem @searchParams

        # Retourner le premier rÃ©sultat si demandÃ©
        if ($FirstMatch -and $directories.Count -gt 0) {
            return $directories[0].FullName
        }

        # Retourner tous les rÃ©sultats
        return $directories.FullName
    } catch {
        Write-Warning "Erreur lors de la recherche du rÃ©pertoire '$DirectoryName': $($_.Exception.Message)"
        return @()
    }
}

# Fonction pour trouver le rÃ©pertoire racine d'un projet
function Find-ProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$StartPath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Markers = @('.git', '.svn', '.hg', 'package.json', 'setup.py', 'pom.xml', 'build.gradle', 'Makefile', 'README.md'),

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10
    )

    try {
        # VÃ©rifier si le chemin de dÃ©part existe
        if (-not (Test-Path -Path $StartPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin de dÃ©part '$StartPath' n'existe pas."
            return $null
        }

        # Convertir le chemin de dÃ©part en chemin absolu
        $currentPath = [System.IO.Path]::GetFullPath($StartPath)

        # Parcourir les rÃ©pertoires parents
        $depth = 0

        while ($depth -lt $MaxDepth) {
            # VÃ©rifier si l'un des marqueurs existe dans le rÃ©pertoire courant
            foreach ($marker in $Markers) {
                $markerPath = Join-Path -Path $currentPath -ChildPath $marker

                if (Test-Path -Path $markerPath -ErrorAction SilentlyContinue) {
                    return $currentPath
                }
            }

            # Passer au rÃ©pertoire parent
            $parentPath = [System.IO.Path]::GetDirectoryName($currentPath)

            # Si on est Ã  la racine, arrÃªter la recherche
            if ($parentPath -eq $currentPath) {
                break
            }

            $currentPath = $parentPath
            $depth++
        }

        # Si aucun marqueur n'a Ã©tÃ© trouvÃ©, retourner le chemin de dÃ©part
        return $StartPath
    } catch {
        Write-Warning "Erreur lors de la recherche du rÃ©pertoire racine du projet: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour rÃ©soudre un chemin avec des variables d'environnement
function Resolve-EnvironmentPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyExists
    )

    try {
        # Remplacer les variables d'environnement
        $resolvedPath = [System.Environment]::ExpandEnvironmentVariables($Path)

        # VÃ©rifier si le chemin existe si demandÃ©
        if ($VerifyExists -and -not (Test-Path -Path $resolvedPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin rÃ©solu '$resolvedPath' n'existe pas."
            return $null
        }

        return $resolvedPath
    } catch {
        Write-Warning "Erreur lors de la rÃ©solution du chemin avec variables d'environnement '$Path': $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour rÃ©soudre un chemin avec des caractÃ¨res gÃ©nÃ©riques
function Resolve-WildcardPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [switch]$FirstMatch
    )

    try {
        # RÃ©soudre le chemin de base
        $resolvedBasePath = Resolve-RelativePath -Path $BasePath

        # VÃ©rifier si le chemin contient des caractÃ¨res gÃ©nÃ©riques
        if (-not ($Path -match '\*|\?')) {
            # Si le chemin ne contient pas de caractÃ¨res gÃ©nÃ©riques, le rÃ©soudre normalement
            return Resolve-RelativePath -Path $Path -BasePath $resolvedBasePath
        }

        # SÃ©parer le chemin en parties
        $pathParts = $Path -split '[\\/]'
        $currentPath = $resolvedBasePath
        $results = @()

        # Parcourir les parties du chemin
        for ($i = 0; $i -lt $pathParts.Count; $i++) {
            $part = $pathParts[$i]

            # Si la partie contient des caractÃ¨res gÃ©nÃ©riques
            if ($part -match '\*|\?') {
                # Rechercher les correspondances
                $matches = Get-ChildItem -Path $currentPath -Filter $part -ErrorAction SilentlyContinue

                # Si aucune correspondance n'est trouvÃ©e, retourner un tableau vide
                if ($matches.Count -eq 0) {
                    return @()
                }

                # Si c'est la derniÃ¨re partie du chemin
                if ($i -eq $pathParts.Count - 1) {
                    # Retourner les correspondances
                    $results = $matches.FullName
                } else {
                    # Pour chaque correspondance, continuer la recherche
                    $newResults = @()

                    foreach ($match in $matches) {
                        # Construire le reste du chemin
                        $remainingPath = $pathParts[($i + 1)..($pathParts.Count - 1)] -join '\'

                        # RÃ©soudre le reste du chemin
                        $resolvedPaths = Resolve-WildcardPath -Path $remainingPath -BasePath $match.FullName

                        # Ajouter les rÃ©sultats
                        $newResults += $resolvedPaths
                    }

                    $results = $newResults
                }

                # Sortir de la boucle
                break
            } else {
                # Si la partie ne contient pas de caractÃ¨res gÃ©nÃ©riques, l'ajouter au chemin courant
                $currentPath = Join-Path -Path $currentPath -ChildPath $part

                # VÃ©rifier si le chemin existe
                if (-not (Test-Path -Path $currentPath -ErrorAction SilentlyContinue)) {
                    return @()
                }
            }
        }

        # Retourner le premier rÃ©sultat si demandÃ©
        if ($FirstMatch -and $results.Count -gt 0) {
            return $results[0]
        }

        # Retourner tous les rÃ©sultats
        return $results
    } catch {
        Write-Warning "Erreur lors de la rÃ©solution du chemin avec caractÃ¨res gÃ©nÃ©riques '$Path': $($_.Exception.Message)"
        return @()
    }
}

# Les fonctions seront exportÃ©es par le module principal
