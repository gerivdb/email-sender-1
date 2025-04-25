<#
.SYNOPSIS
    Joint plusieurs chemins en un seul.

.DESCRIPTION
    La fonction Join-RoadmapPath joint plusieurs chemins en un seul.
    Elle prend en charge différentes options de jointure et peut être utilisée pour
    joindre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin de base.

.PARAMETER ChildPath
    Les chemins enfants à joindre au chemin de base.

.PARAMETER JoinType
    Le type de jointure à effectuer. Valeurs possibles :
    - Simple : Jointure simple (utilise [System.IO.Path]::Combine)
    - Normalized : Jointure normalisée (normalise les chemins avant de les joindre)
    - Relative : Jointure relative (crée un chemin relatif)
    - Absolute : Jointure absolue (crée un chemin absolu)
    - Unix : Jointure Unix (utilise des séparateurs Unix)
    - Windows : Jointure Windows (utilise des séparateurs Windows)
    - UNC : Jointure UNC (crée un chemin UNC)
    - URL : Jointure URL (crée un chemin URL)
    - Custom : Jointure personnalisée

.PARAMETER CustomJoin
    La fonction de jointure personnalisée à utiliser.
    Utilisé uniquement lorsque JoinType est "Custom".

.PARAMETER Separator
    Le séparateur à utiliser pour la jointure.
    Par défaut, c'est le séparateur de répertoire du système.

.PARAMETER NormalizePaths
    Indique si les chemins doivent être normalisés avant la jointure.
    Par défaut, c'est $false.

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent être résolus.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la jointure.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la jointure.

.EXAMPLE
    Join-RoadmapPath -Path "C:\folder" -ChildPath "file.txt"
    Joint le chemin "C:\folder" avec "file.txt" pour obtenir "C:\folder\file.txt".

.EXAMPLE
    Join-RoadmapPath -Path "C:\folder" -ChildPath "subfolder", "file.txt" -JoinType Normalized
    Joint le chemin "C:\folder" avec "subfolder" et "file.txt" en normalisant les chemins.

.OUTPUTS
    [string] Le chemin joint.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Join-RoadmapPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyString()]
        [string[]]$ChildPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("Simple", "Normalized", "Relative", "Absolute", "Unix", "Windows", "UNC", "URL", "Custom")]
        [string]$JoinType = "Simple",

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomJoin,

        [Parameter(Mandatory = $false)]
        [string]$Separator = [System.IO.Path]::DirectorySeparatorChar,

        [Parameter(Mandatory = $false)]
        [switch]$NormalizePaths,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveRelativePaths,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat de la jointure
    $result = $null
    $joinSucceeded = $false

    # Effectuer la jointure selon le type
    try {
        # Préparer le chemin initial
        $workingPath = $Path.Trim()

        # Préparer les chemins enfants
        $workingChildPaths = $ChildPath | ForEach-Object { $_.Trim() }

        # Effectuer la jointure selon le type
        switch ($JoinType) {
            "Simple" {
                $result = $workingPath

                foreach ($childPath in $workingChildPaths) {
                    $result = [System.IO.Path]::Combine($result, $childPath)
                }

                $joinSucceeded = $true
            }
            "Normalized" {
                # Normaliser les chemins
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                $normalizedPath = [System.IO.Path]::GetFullPath($workingPath)
                $normalizedChildPaths = $workingChildPaths | ForEach-Object {
                    if ([string]::IsNullOrEmpty($_)) {
                        return ""
                    } else {
                        return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($normalizedPath, $_))
                    }
                }

                # Joindre les chemins
                $result = $normalizedPath

                foreach ($childPath in $normalizedChildPaths) {
                    if (-not [string]::IsNullOrEmpty($childPath)) {
                        $result = $childPath
                    }
                }

                $joinSucceeded = $true
            }
            "Relative" {
                # Créer un chemin relatif
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                $result = $workingPath

                foreach ($childPath in $workingChildPaths) {
                    if (-not [string]::IsNullOrEmpty($childPath)) {
                        $result = [System.IO.Path]::Combine($result, $childPath)
                    }
                }

                # Normaliser le chemin
                if ($NormalizePaths) {
                    $result = [System.IO.Path]::GetFullPath($result)
                }

                $joinSucceeded = $true
            }
            "Absolute" {
                # Créer un chemin absolu
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = [System.IO.Path]::GetFullPath(".")
                } elseif (-not [System.IO.Path]::IsPathRooted($workingPath)) {
                    $workingPath = [System.IO.Path]::GetFullPath($workingPath)
                }

                $result = $workingPath

                foreach ($childPath in $workingChildPaths) {
                    if (-not [string]::IsNullOrEmpty($childPath)) {
                        $result = [System.IO.Path]::Combine($result, $childPath)
                    }
                }

                # Normaliser le chemin
                $result = [System.IO.Path]::GetFullPath($result)

                $joinSucceeded = $true
            }
            "Unix" {
                # Créer un chemin Unix
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                # Convertir les séparateurs Windows en séparateurs Unix
                $unixPath = $workingPath.Replace([System.IO.Path]::DirectorySeparatorChar, '/')
                $unixChildPaths = $workingChildPaths | ForEach-Object { $_.Replace([System.IO.Path]::DirectorySeparatorChar, '/') }

                # Joindre les chemins
                $result = $unixPath

                foreach ($childPath in $unixChildPaths) {
                    if (-not [string]::IsNullOrEmpty($childPath)) {
                        if ($result.EndsWith('/')) {
                            $result = $result + $childPath
                        } else {
                            $result = $result + '/' + $childPath
                        }
                    }
                }

                $joinSucceeded = $true
            }
            "Windows" {
                # Créer un chemin Windows
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                # Vérifier si c'est un chemin Unix
                if ($workingPath -match '^/([a-zA-Z])(/|$)') {
                    $driveLetter = $matches[1].ToUpper()
                    $remainingPath = $workingPath.Substring(3)  # Supprimer "/c/"
                    $windowsPath = "${driveLetter}:\" + $remainingPath.Replace('/', '\')
                } else {
                    # Convertir les séparateurs Unix en séparateurs Windows
                    $windowsPath = $workingPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
                }

                $windowsChildPaths = $workingChildPaths | ForEach-Object { $_.Replace('/', [System.IO.Path]::DirectorySeparatorChar) }

                # Joindre les chemins
                $result = $windowsPath

                foreach ($childPath in $windowsChildPaths) {
                    if (-not [string]::IsNullOrEmpty($childPath)) {
                        $result = [System.IO.Path]::Combine($result, $childPath)
                    }
                }

                $joinSucceeded = $true
            }
            "UNC" {
                # Créer un chemin UNC
                if ([string]::IsNullOrEmpty($workingPath)) {
                    throw "Le chemin de base ne peut pas être vide pour la jointure UNC."
                }

                # Vérifier si le chemin est déjà un chemin UNC
                if ($workingPath -match '^\\\\') {
                    $uncPath = $workingPath
                } else {
                    # Convertir un chemin local en UNC
                    if ($workingPath -match '^([A-Za-z]):') {
                        $driveLetter = $matches[1].ToLower()
                        $uncPath = "\\localhost\$driveLetter`$" + $workingPath.Substring(2)
                    } else {
                        throw "Impossible de convertir le chemin en format UNC : le chemin n'a pas de lettre de lecteur."
                    }
                }

                # Joindre les chemins
                $result = $uncPath

                foreach ($childPath in $workingChildPaths) {
                    if (-not [string]::IsNullOrEmpty($childPath)) {
                        $result = [System.IO.Path]::Combine($result, $childPath)
                    }
                }

                $joinSucceeded = $true
            }
            "URL" {
                # Créer un chemin URL
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                # Convertir les séparateurs Windows en séparateurs URL
                $urlPath = $workingPath.Replace([System.IO.Path]::DirectorySeparatorChar, '/')
                $urlChildPaths = $workingChildPaths | ForEach-Object { $_.Replace([System.IO.Path]::DirectorySeparatorChar, '/') }

                # Vérifier si le chemin est déjà un chemin URL
                if ($urlPath -match '^(file|http|https|ftp)://') {
                    # Ne rien faire
                } else {
                    # Convertir un chemin local en URL
                    if ($urlPath -match '^([A-Za-z]):') {
                        $driveLetter = $matches[1].ToLower()
                        $urlPath = "file:///$driveLetter" + $urlPath.Substring(2)
                    } else {
                        $urlPath = "file:///$urlPath"
                    }
                }

                # Joindre les chemins
                $result = $urlPath

                foreach ($childPath in $urlChildPaths) {
                    if (-not [string]::IsNullOrEmpty($childPath)) {
                        if ($result.EndsWith('/')) {
                            $result = $result + $childPath
                        } else {
                            $result = $result + '/' + $childPath
                        }
                    }
                }

                $joinSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomJoin) {
                    throw "Le paramètre CustomJoin est requis lorsque le type de jointure est Custom."
                } else {
                    $result = & $CustomJoin $workingPath $workingChildPaths
                }

                $joinSucceeded = $true
            }
        }

        # Normaliser les chemins si demandé
        if ($NormalizePaths -and $JoinType -ne "Normalized" -and $JoinType -ne "Absolute") {
            $result = [System.IO.Path]::GetFullPath($result)
        }

        # Résoudre les chemins relatifs si demandé
        if ($ResolveRelativePaths -and -not [System.IO.Path]::IsPathRooted($result)) {
            $result = [System.IO.Path]::GetFullPath($result)
        }
    } catch {
        $joinSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de joindre les chemins avec le type de jointure $JoinType : $_"
        }
    }

    # Gérer l'échec de la jointure
    if (-not $joinSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $Path
        }
    }

    return $result
}
