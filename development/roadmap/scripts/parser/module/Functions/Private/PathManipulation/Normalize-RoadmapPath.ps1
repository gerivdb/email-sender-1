<#
.SYNOPSIS
    Normalise un chemin de fichier ou de rÃ©pertoire.

.DESCRIPTION
    La fonction ConvertTo-RoadmapPath normalise un chemin de fichier ou de rÃ©pertoire.
    Elle prend en charge diffÃ©rentes options de normalisation et peut Ãªtre utilisÃ©e pour
    normaliser les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin Ã  normaliser.

.PARAMETER NormalizationType
    Le type de normalisation Ã  effectuer. Valeurs possibles :
    - FullPath : Convertit le chemin en chemin absolu complet
    - RelativePath : Convertit le chemin en chemin relatif par rapport Ã  un chemin de base
    - UnixPath : Convertit le chemin en format Unix (sÃ©parateurs /)
    - WindowsPath : Convertit le chemin en format Windows (sÃ©parateurs \)
    - UNCPath : Convertit le chemin en format UNC (\\server\share)
    - URLPath : Convertit le chemin en format URL (file:///)
    - Custom : Utilise une normalisation personnalisÃ©e

.PARAMETER BasePath
    Le chemin de base Ã  utiliser pour la normalisation de type RelativePath.
    Par dÃ©faut, c'est le rÃ©pertoire courant.

.PARAMETER CustomNormalization
    La fonction de normalisation personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque NormalizationType est "Custom".

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent Ãªtre rÃ©solus.
    Par dÃ©faut, c'est $true.

.PARAMETER PreserveDriveLetters
    Indique si les lettres de lecteur doivent Ãªtre prÃ©servÃ©es.
    Par dÃ©faut, c'est $true.

.PARAMETER RemoveTrailingSlash
    Indique si les barres obliques finales doivent Ãªtre supprimÃ©es.
    Par dÃ©faut, c'est $true.

.PARAMETER NormalizeCase
    Indique si la casse du chemin doit Ãªtre normalisÃ©e.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la normalisation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la normalisation.

.EXAMPLE
    ConvertTo-RoadmapPath -Path ".\folder\file.txt" -NormalizationType FullPath
    Normalise le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    ConvertTo-RoadmapPath -Path "C:\folder\file.txt" -NormalizationType UnixPath
    Convertit le chemin Windows "C:\folder\file.txt" en format Unix "/c/folder/file.txt".

.OUTPUTS
    [string] Le chemin normalisÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function ConvertTo-RoadmapPath {
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

    # Initialiser le rÃ©sultat de la normalisation
    $result = $null
    $normalizationSucceeded = $false

    # Effectuer la normalisation selon le type
    try {
        # VÃ©rifier si le chemin est vide
        if ([string]::IsNullOrEmpty($Path)) {
            $result = ""
            $normalizationSucceeded = $true
            return $result
        }

        # PrÃ©parer le chemin initial
        $workingPath = $Path.Trim()

        # RÃ©soudre les chemins relatifs si demandÃ©, sauf pour le type RelativePath
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
                # Cas spÃ©cial pour les chemins relatifs avec base "."
                if ($BasePath -eq "." -and $workingPath -match '^\.[/\\](.+)$') {
                    $result = $matches[1]
                    $normalizationSucceeded = $true
                    return $result
                }

                # Obtenir les chemins absolus
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)
                $absoluteBasePath = [System.IO.Path]::GetFullPath($BasePath)

                # VÃ©rifier si les chemins sont sur le mÃªme lecteur
                $pathDrive = [System.IO.Path]::GetPathRoot($absolutePath)
                $basePathDrive = [System.IO.Path]::GetPathRoot($absoluteBasePath)

                if ($pathDrive -ne $basePathDrive) {
                    if ($PreserveDriveLetters) {
                        # Garder le chemin absolu si les lecteurs sont diffÃ©rents
                        $result = $absolutePath
                    } else {
                        # Essayer de crÃ©er un chemin relatif mÃªme avec des lecteurs diffÃ©rents
                        $result = $absolutePath.Replace($pathDrive, "")
                        $result = Join-Path -Path $pathDrive -ChildPath $result
                        $result = $result.TrimStart([System.IO.Path]::DirectorySeparatorChar)
                    }
                } else {
                    # CrÃ©er un chemin relatif
                    $pathParts = $absolutePath.Substring($pathDrive.Length).Split([System.IO.Path]::DirectorySeparatorChar, [System.StringSplitOptions]::RemoveEmptyEntries)
                    $basePathParts = $absoluteBasePath.Substring($basePathDrive.Length).Split([System.IO.Path]::DirectorySeparatorChar, [System.StringSplitOptions]::RemoveEmptyEntries)

                    # Trouver le prÃ©fixe commun
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

                    # Ajouter les ".." pour remonter au prÃ©fixe commun
                    for ($i = 0; $i -lt ($basePathParts.Length - $commonPrefixLength); $i++) {
                        $relativePathParts += ".."
                    }

                    # Ajouter les parties du chemin aprÃ¨s le prÃ©fixe commun
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

                # Remplacer les sÃ©parateurs Windows par des sÃ©parateurs Unix
                $result = $absolutePath.Replace([System.IO.Path]::DirectorySeparatorChar, '/')

                # GÃ©rer la lettre de lecteur pour Windows
                if ($result -match '^([A-Za-z]):') {
                    $driveLetter = $matches[1].ToLower()
                    $result = $result.Substring(2)  # Supprimer "C:"
                    $result = "/$driveLetter$result"  # Ajouter "/c"
                }

                $normalizationSucceeded = $true
            }
            "WindowsPath" {
                # VÃ©rifier si c'est un chemin Unix
                if ($workingPath -match '^/([a-zA-Z])(/|$)') {
                    $driveLetter = $matches[1].ToUpper()
                    $remainingPath = $workingPath.Substring(3)  # Supprimer "/c/"
                    $result = "${driveLetter}:\" + $remainingPath.Replace('/', '\')
                } else {
                    # Convertir en chemin absolu d'abord
                    $absolutePath = [System.IO.Path]::GetFullPath($workingPath)

                    # Remplacer les sÃ©parateurs Unix par des sÃ©parateurs Windows
                    $result = $absolutePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
                }

                $normalizationSucceeded = $true
            }
            "UNCPath" {
                # Convertir en chemin absolu d'abord
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)

                # VÃ©rifier si c'est dÃ©jÃ  un chemin UNC
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

                # Remplacer les sÃ©parateurs Windows par des sÃ©parateurs URL
                $result = $absolutePath.Replace([System.IO.Path]::DirectorySeparatorChar, '/')

                # GÃ©rer la lettre de lecteur pour Windows
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
                    throw "Le paramÃ¨tre CustomNormalization est requis lorsque le type de normalisation est Custom."
                } else {
                    $result = & $CustomNormalization $workingPath
                }

                $normalizationSucceeded = $true
            }
        }

        # Supprimer les barres obliques finales si demandÃ©
        if ($RemoveTrailingSlash -and -not [string]::IsNullOrEmpty($result)) {
            $result = $result.TrimEnd([System.IO.Path]::DirectorySeparatorChar, '/')

            # PrÃ©server la barre oblique pour les chemins racine
            if ($result -match '^[A-Za-z]:$' -or $result -eq "") {
                $result += [System.IO.Path]::DirectorySeparatorChar
            }
        }

        # Normaliser la casse si demandÃ©
        if ($NormalizeCase) {
            if ($NormalizationType -eq "UnixPath" -or $NormalizationType -eq "URLPath") {
                # En Unix, les chemins sont sensibles Ã  la casse
                # Ne rien faire
            } else {
                # En Windows, les chemins ne sont pas sensibles Ã  la casse
                $result = $result.ToLower()
            }
        }
    } catch {
        $normalizationSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de normaliser le chemin '$Path' avec le type de normalisation $NormalizationType : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la normalisation
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

