<#
.SYNOPSIS
    Fonctions utilitaires pour résoudre les chemins d'accès.

.DESCRIPTION
    Ce script contient des fonctions pour résoudre les chemins d'accès
    relatifs et absolus dans le système de fichiers.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Fonction pour résoudre un chemin relatif en chemin absolu
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
        # Si le chemin est déjà absolu, le retourner tel quel
        if ([System.IO.Path]::IsPathRooted($Path)) {
            $resolvedPath = $Path
        } else {
            # Résoudre le chemin relatif par rapport au chemin de base
            $resolvedPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($BasePath, $Path))
        }

        # Vérifier si le chemin existe si demandé
        if ($VerifyExists -and -not (Test-Path -Path $resolvedPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin résolu '$resolvedPath' n'existe pas."
            return $null
        }

        return $resolvedPath
    } catch {
        Write-Warning "Erreur lors de la résolution du chemin relatif '$Path': $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour résoudre un chemin absolu en chemin relatif
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
        # Vérifier si le chemin existe si demandé
        if ($VerifyExists -and -not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin '$Path' n'existe pas."
            return $null
        }

        # Convertir les chemins en chemins absolus
        $absolutePath = [System.IO.Path]::GetFullPath($Path)
        $absoluteBasePath = [System.IO.Path]::GetFullPath($BasePath)

        # Vérifier si le chemin est sous le chemin de base
        if (-not $absolutePath.StartsWith($absoluteBasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            # Si le chemin n'est pas sous le chemin de base, retourner le chemin absolu
            return $absolutePath
        }

        # Calculer le chemin relatif
        $relativePath = $absolutePath.Substring($absoluteBasePath.Length)

        # Supprimer le séparateur de chemin initial si présent
        if ($relativePath.StartsWith([System.IO.Path]::DirectorySeparatorChar) -or $relativePath.StartsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
            $relativePath = $relativePath.Substring(1)
        }

        return $relativePath
    } catch {
        Write-Warning "Erreur lors de la résolution du chemin absolu '$Path': $($_.Exception.Message)"
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

        # Supprimer les barres obliques inverses consécutives
        while ($normalizedPath -match '\\\\') {
            $normalizedPath = $normalizedPath -replace '\\\\', '\'
        }

        # Supprimer les points simples (.)
        $normalizedPath = $normalizedPath -replace '\\\.\\', '\'

        # Traiter les points doubles (..)
        while ($normalizedPath -match '\\[^\\]+\\\.\.') {
            $normalizedPath = $normalizedPath -replace '\\[^\\]+\\\.\.', ''
        }

        # Supprimer la barre oblique inverse finale si présente
        if ($normalizedPath.EndsWith('\')) {
            $normalizedPath = $normalizedPath.Substring(0, $normalizedPath.Length - 1)
        }

        # Vérifier si le chemin existe si demandé
        if ($VerifyExists -and -not (Test-Path -Path $normalizedPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin normalisé '$normalizedPath' n'existe pas."
            return $null
        }

        return $normalizedPath
    } catch {
        Write-Warning "Erreur lors de la normalisation du chemin '$Path': $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour trouver un fichier dans un répertoire et ses sous-répertoires
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
        # Vérifier si le répertoire de base existe
        if (-not (Test-Path -Path $BasePath -PathType Container)) {
            Write-Warning "Le répertoire de base '$BasePath' n'existe pas."
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

        # Retourner le premier résultat si demandé
        if ($FirstMatch -and $files.Count -gt 0) {
            return $files[0].FullName
        }

        # Retourner tous les résultats
        return $files.FullName
    } catch {
        Write-Warning "Erreur lors de la recherche du fichier '$FileName': $($_.Exception.Message)"
        return @()
    }
}

# Fonction pour trouver un répertoire dans un répertoire et ses sous-répertoires
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
        # Vérifier si le répertoire de base existe
        if (-not (Test-Path -Path $BasePath -PathType Container)) {
            Write-Warning "Le répertoire de base '$BasePath' n'existe pas."
            return @()
        }

        # Rechercher le répertoire
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

        # Retourner le premier résultat si demandé
        if ($FirstMatch -and $directories.Count -gt 0) {
            return $directories[0].FullName
        }

        # Retourner tous les résultats
        return $directories.FullName
    } catch {
        Write-Warning "Erreur lors de la recherche du répertoire '$DirectoryName': $($_.Exception.Message)"
        return @()
    }
}

# Fonction pour trouver le répertoire racine d'un projet
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
        # Vérifier si le chemin de départ existe
        if (-not (Test-Path -Path $StartPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin de départ '$StartPath' n'existe pas."
            return $null
        }

        # Convertir le chemin de départ en chemin absolu
        $currentPath = [System.IO.Path]::GetFullPath($StartPath)

        # Parcourir les répertoires parents
        $depth = 0

        while ($depth -lt $MaxDepth) {
            # Vérifier si l'un des marqueurs existe dans le répertoire courant
            foreach ($marker in $Markers) {
                $markerPath = Join-Path -Path $currentPath -ChildPath $marker

                if (Test-Path -Path $markerPath -ErrorAction SilentlyContinue) {
                    return $currentPath
                }
            }

            # Passer au répertoire parent
            $parentPath = [System.IO.Path]::GetDirectoryName($currentPath)

            # Si on est à la racine, arrêter la recherche
            if ($parentPath -eq $currentPath) {
                break
            }

            $currentPath = $parentPath
            $depth++
        }

        # Si aucun marqueur n'a été trouvé, retourner le chemin de départ
        return $StartPath
    } catch {
        Write-Warning "Erreur lors de la recherche du répertoire racine du projet: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour résoudre un chemin avec des variables d'environnement
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

        # Vérifier si le chemin existe si demandé
        if ($VerifyExists -and -not (Test-Path -Path $resolvedPath -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin résolu '$resolvedPath' n'existe pas."
            return $null
        }

        return $resolvedPath
    } catch {
        Write-Warning "Erreur lors de la résolution du chemin avec variables d'environnement '$Path': $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour résoudre un chemin avec des caractères génériques
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
        # Résoudre le chemin de base
        $resolvedBasePath = Resolve-RelativePath -Path $BasePath

        # Vérifier si le chemin contient des caractères génériques
        if (-not ($Path -match '\*|\?')) {
            # Si le chemin ne contient pas de caractères génériques, le résoudre normalement
            return Resolve-RelativePath -Path $Path -BasePath $resolvedBasePath
        }

        # Séparer le chemin en parties
        $pathParts = $Path -split '[\\/]'
        $currentPath = $resolvedBasePath
        $results = @()

        # Parcourir les parties du chemin
        for ($i = 0; $i -lt $pathParts.Count; $i++) {
            $part = $pathParts[$i]

            # Si la partie contient des caractères génériques
            if ($part -match '\*|\?') {
                # Rechercher les correspondances
                $matches = Get-ChildItem -Path $currentPath -Filter $part -ErrorAction SilentlyContinue

                # Si aucune correspondance n'est trouvée, retourner un tableau vide
                if ($matches.Count -eq 0) {
                    return @()
                }

                # Si c'est la dernière partie du chemin
                if ($i -eq $pathParts.Count - 1) {
                    # Retourner les correspondances
                    $results = $matches.FullName
                } else {
                    # Pour chaque correspondance, continuer la recherche
                    $newResults = @()

                    foreach ($match in $matches) {
                        # Construire le reste du chemin
                        $remainingPath = $pathParts[($i + 1)..($pathParts.Count - 1)] -join '\'

                        # Résoudre le reste du chemin
                        $resolvedPaths = Resolve-WildcardPath -Path $remainingPath -BasePath $match.FullName

                        # Ajouter les résultats
                        $newResults += $resolvedPaths
                    }

                    $results = $newResults
                }

                # Sortir de la boucle
                break
            } else {
                # Si la partie ne contient pas de caractères génériques, l'ajouter au chemin courant
                $currentPath = Join-Path -Path $currentPath -ChildPath $part

                # Vérifier si le chemin existe
                if (-not (Test-Path -Path $currentPath -ErrorAction SilentlyContinue)) {
                    return @()
                }
            }
        }

        # Retourner le premier résultat si demandé
        if ($FirstMatch -and $results.Count -gt 0) {
            return $results[0]
        }

        # Retourner tous les résultats
        return $results
    } catch {
        Write-Warning "Erreur lors de la résolution du chemin avec caractères génériques '$Path': $($_.Exception.Message)"
        return @()
    }
}

# Les fonctions seront exportées par le module principal
