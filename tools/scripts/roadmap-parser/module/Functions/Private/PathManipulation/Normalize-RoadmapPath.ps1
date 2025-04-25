<#
.SYNOPSIS
    Normalise un chemin de fichier ou de répertoire.

.DESCRIPTION
    La fonction Normalize-RoadmapPath normalise un chemin de fichier ou de répertoire.
    Elle prend en charge différentes options de normalisation et peut être utilisée pour
    normaliser les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin à normaliser.

.PARAMETER NormalizationType
    Le type de normalisation à effectuer. Valeurs possibles :
    - FullPath : Convertit le chemin en chemin absolu complet
    - RelativePath : Convertit le chemin en chemin relatif par rapport à un chemin de base
    - UnixPath : Convertit le chemin en format Unix (séparateurs /)
    - WindowsPath : Convertit le chemin en format Windows (séparateurs \)
    - UNCPath : Convertit le chemin en format UNC (\\server\share)
    - URLPath : Convertit le chemin en format URL (file:///)
    - Custom : Utilise une normalisation personnalisée

.PARAMETER BasePath
    Le chemin de base à utiliser pour la normalisation de type RelativePath.
    Par défaut, c'est le répertoire courant.

.PARAMETER CustomNormalization
    La fonction de normalisation personnalisée à utiliser.
    Utilisé uniquement lorsque NormalizationType est "Custom".

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent être résolus.
    Par défaut, c'est $true.

.PARAMETER PreserveDriveLetters
    Indique si les lettres de lecteur doivent être préservées.
    Par défaut, c'est $true.

.PARAMETER RemoveTrailingSlash
    Indique si les barres obliques finales doivent être supprimées.
    Par défaut, c'est $true.

.PARAMETER NormalizeCase
    Indique si la casse du chemin doit être normalisée.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la normalisation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la normalisation.

.EXAMPLE
    Normalize-RoadmapPath -Path ".\folder\file.txt" -NormalizationType FullPath
    Normalise le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    Normalize-RoadmapPath -Path "C:\folder\file.txt" -NormalizationType UnixPath
    Convertit le chemin Windows "C:\folder\file.txt" en format Unix "/c/folder/file.txt".

.OUTPUTS
    [string] Le chemin normalisé.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Normalize-RoadmapPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("FullPath", "RelativePath", "UnixPath", "WindowsPath", "UNCPath", "URLPath", "Custom")]
        [string]$NormalizationType,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomNormalization,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveRelativePaths = $true,

        [Parameter(Mandatory = $false)]
        [switch]$PreserveDriveLetters = $true,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveTrailingSlash = $true,

        [Parameter(Mandatory = $false)]
        [switch]$NormalizeCase = $false,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat de la normalisation
    $result = $null
    $normalizationSucceeded = $false

    # Effectuer la normalisation selon le type
    try {
        # Vérifier si le chemin est vide
        if ([string]::IsNullOrEmpty($Path)) {
            $result = ""
            $normalizationSucceeded = $true
            return $result
        }

        # Préparer le chemin initial
        $workingPath = $Path.Trim()

        # Résoudre les chemins relatifs si demandé, sauf pour le type RelativePath
        if ($ResolveRelativePaths -and -not [System.IO.Path]::IsPathRooted($workingPath) -and $NormalizationType -ne "RelativePath") {
            $workingPath = Join-Path -Path $BasePath -ChildPath $workingPath
        }

        # Effectuer la normalisation selon le type
        switch ($NormalizationType) {
            "FullPath" {
                $result = [System.IO.Path]::GetFullPath($workingPath)
                $normalizationSucceeded = $true
            }
            "RelativePath" {
                # Cas spécial pour les chemins relatifs avec base "."
                if ($BasePath -eq "." -and $workingPath -match '^\.[/\\](.+)$') {
                    $result = $matches[1]
                    $normalizationSucceeded = $true
                    return $result
                }

                # Obtenir les chemins absolus
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)
                $absoluteBasePath = [System.IO.Path]::GetFullPath($BasePath)

                # Vérifier si les chemins sont sur le même lecteur
                $pathDrive = [System.IO.Path]::GetPathRoot($absolutePath)
                $basePathDrive = [System.IO.Path]::GetPathRoot($absoluteBasePath)

                if ($pathDrive -ne $basePathDrive) {
                    if ($PreserveDriveLetters) {
                        # Garder le chemin absolu si les lecteurs sont différents
                        $result = $absolutePath
                    } else {
                        # Essayer de créer un chemin relatif même avec des lecteurs différents
                        $result = $absolutePath.Replace($pathDrive, "")
                        $result = Join-Path -Path $pathDrive -ChildPath $result
                        $result = $result.TrimStart([System.IO.Path]::DirectorySeparatorChar)
                    }
                } else {
                    # Créer un chemin relatif
                    $pathParts = $absolutePath.Substring($pathDrive.Length).Split([System.IO.Path]::DirectorySeparatorChar, [System.StringSplitOptions]::RemoveEmptyEntries)
                    $basePathParts = $absoluteBasePath.Substring($basePathDrive.Length).Split([System.IO.Path]::DirectorySeparatorChar, [System.StringSplitOptions]::RemoveEmptyEntries)

                    # Trouver le préfixe commun
                    $commonPrefixLength = 0
                    $minLength = [Math]::Min($pathParts.Length, $basePathParts.Length)

                    for ($i = 0; $i -lt $minLength; $i++) {
                        if ($pathParts[$i] -eq $basePathParts[$i]) {
                            $commonPrefixLength++
                        } else {
                            break
                        }
                    }

                    # Construire le chemin relatif
                    $relativePathParts = @()

                    # Ajouter les ".." pour remonter au préfixe commun
                    for ($i = 0; $i -lt ($basePathParts.Length - $commonPrefixLength); $i++) {
                        $relativePathParts += ".."
                    }

                    # Ajouter les parties du chemin après le préfixe commun
                    for ($i = $commonPrefixLength; $i -lt $pathParts.Length; $i++) {
                        $relativePathParts += $pathParts[$i]
                    }

                    # Construire le chemin relatif final
                    if ($relativePathParts.Length -eq 0) {
                        $result = "."
                    } else {
                        $result = $relativePathParts -join [System.IO.Path]::DirectorySeparatorChar
                    }
                }

                $normalizationSucceeded = $true
            }
            "UnixPath" {
                # Convertir en chemin absolu d'abord
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)

                # Remplacer les séparateurs Windows par des séparateurs Unix
                $result = $absolutePath.Replace([System.IO.Path]::DirectorySeparatorChar, '/')

                # Gérer la lettre de lecteur pour Windows
                if ($result -match '^([A-Za-z]):') {
                    $driveLetter = $matches[1].ToLower()
                    $result = $result.Substring(2)  # Supprimer "C:"
                    $result = "/$driveLetter$result"  # Ajouter "/c"
                }

                $normalizationSucceeded = $true
            }
            "WindowsPath" {
                # Vérifier si c'est un chemin Unix
                if ($workingPath -match '^/([a-zA-Z])(/|$)') {
                    $driveLetter = $matches[1].ToUpper()
                    $remainingPath = $workingPath.Substring(3)  # Supprimer "/c/"
                    $result = "${driveLetter}:\" + $remainingPath.Replace('/', '\')
                } else {
                    # Convertir en chemin absolu d'abord
                    $absolutePath = [System.IO.Path]::GetFullPath($workingPath)

                    # Remplacer les séparateurs Unix par des séparateurs Windows
                    $result = $absolutePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
                }

                $normalizationSucceeded = $true
            }
            "UNCPath" {
                # Convertir en chemin absolu d'abord
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)

                # Vérifier si c'est déjà un chemin UNC
                if ($absolutePath -match '^\\\\') {
                    $result = $absolutePath
                } else {
                    # Convertir un chemin local en UNC
                    if ($absolutePath -match '^([A-Za-z]):') {
                        $driveLetter = $matches[1].ToLower()
                        $result = $absolutePath.Substring(2)  # Supprimer "C:"
                        $result = "\\localhost\$driveLetter`$$result"  # Ajouter "\\localhost\c$"
                    } else {
                        throw "Impossible de convertir le chemin en format UNC : le chemin n'a pas de lettre de lecteur."
                    }
                }

                $normalizationSucceeded = $true
            }
            "URLPath" {
                # Convertir en chemin absolu d'abord
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)

                # Remplacer les séparateurs Windows par des séparateurs URL
                $result = $absolutePath.Replace([System.IO.Path]::DirectorySeparatorChar, '/')

                # Gérer la lettre de lecteur pour Windows
                if ($result -match '^([A-Za-z]):') {
                    $driveLetter = $matches[1].ToLower()
                    $result = $result.Substring(2)  # Supprimer "C:"
                    $result = "file:///$driveLetter$result"  # Ajouter "file:///c"
                } else {
                    $result = "file:///$result"  # Ajouter "file:///"
                }

                $normalizationSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomNormalization) {
                    throw "Le paramètre CustomNormalization est requis lorsque le type de normalisation est Custom."
                } else {
                    $result = & $CustomNormalization $workingPath
                }

                $normalizationSucceeded = $true
            }
        }

        # Supprimer les barres obliques finales si demandé
        if ($RemoveTrailingSlash -and -not [string]::IsNullOrEmpty($result)) {
            $result = $result.TrimEnd([System.IO.Path]::DirectorySeparatorChar, '/')

            # Préserver la barre oblique pour les chemins racine
            if ($result -match '^[A-Za-z]:$' -or $result -eq "") {
                $result += [System.IO.Path]::DirectorySeparatorChar
            }
        }

        # Normaliser la casse si demandé
        if ($NormalizeCase) {
            if ($NormalizationType -eq "UnixPath" -or $NormalizationType -eq "URLPath") {
                # En Unix, les chemins sont sensibles à la casse
                # Ne rien faire
            } else {
                # En Windows, les chemins ne sont pas sensibles à la casse
                $result = $result.ToLower()
            }
        }
    } catch {
        $normalizationSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de normaliser le chemin '$Path' avec le type de normalisation $NormalizationType : $_"
        }
    }

    # Gérer l'échec de la normalisation
    if (-not $normalizationSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $Path
        }
    }

    return $result
}
