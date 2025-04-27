<#
.SYNOPSIS
    Joint plusieurs chemins en un seul.

.DESCRIPTION
    La fonction Join-RoadmapPath joint plusieurs chemins en un seul.
    Elle prend en charge diffÃ©rentes options de jointure et peut Ãªtre utilisÃ©e pour
    joindre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin de base.

.PARAMETER ChildPath
    Les chemins enfants Ã  joindre au chemin de base.

.PARAMETER JoinType
    Le type de jointure Ã  effectuer. Valeurs possibles :
    - Simple : Jointure simple (utilise [System.IO.Path]::Combine)
    - Normalized : Jointure normalisÃ©e (normalise les chemins avant de les joindre)
    - Relative : Jointure relative (crÃ©e un chemin relatif)
    - Absolute : Jointure absolue (crÃ©e un chemin absolu)
    - Unix : Jointure Unix (utilise des sÃ©parateurs Unix)
    - Windows : Jointure Windows (utilise des sÃ©parateurs Windows)
    - UNC : Jointure UNC (crÃ©e un chemin UNC)
    - URL : Jointure URL (crÃ©e un chemin URL)
    - Custom : Jointure personnalisÃ©e

.PARAMETER CustomJoin
    La fonction de jointure personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque JoinType est "Custom".

.PARAMETER Separator
    Le sÃ©parateur Ã  utiliser pour la jointure.
    Par dÃ©faut, c'est le sÃ©parateur de rÃ©pertoire du systÃ¨me.

.PARAMETER NormalizePaths
    Indique si les chemins doivent Ãªtre normalisÃ©s avant la jointure.
    Par dÃ©faut, c'est $false.

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent Ãªtre rÃ©solus.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la jointure.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la jointure.

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
    Date de crÃ©ation: 2023-07-21
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

    # Initialiser le rÃ©sultat de la jointure
    $result = $null
    $joinSucceeded = $false

    # Effectuer la jointure selon le type
    try {
        # PrÃ©parer le chemin initial
        $workingPath = $Path.Trim()

        # PrÃ©parer les chemins enfants
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
                # CrÃ©er un chemin relatif
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
                # CrÃ©er un chemin absolu
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
                # CrÃ©er un chemin Unix
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                # Convertir les sÃ©parateurs Windows en sÃ©parateurs Unix
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
                # CrÃ©er un chemin Windows
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                # VÃ©rifier si c'est un chemin Unix
                if ($workingPath -match '^/([a-zA-Z])(/|$)') {
                    $driveLetter = $matches[1].ToUpper()
                    $remainingPath = $workingPath.Substring(3)  # Supprimer "/c/"
                    $windowsPath = "${driveLetter}:\" + $remainingPath.Replace('/', '\')
                } else {
                    # Convertir les sÃ©parateurs Unix en sÃ©parateurs Windows
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
                # CrÃ©er un chemin UNC
                if ([string]::IsNullOrEmpty($workingPath)) {
                    throw "Le chemin de base ne peut pas Ãªtre vide pour la jointure UNC."
                }

                # VÃ©rifier si le chemin est dÃ©jÃ  un chemin UNC
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
                # CrÃ©er un chemin URL
                if ([string]::IsNullOrEmpty($workingPath)) {
                    $workingPath = "."
                }

                # Convertir les sÃ©parateurs Windows en sÃ©parateurs URL
                $urlPath = $workingPath.Replace([System.IO.Path]::DirectorySeparatorChar, '/')
                $urlChildPaths = $workingChildPaths | ForEach-Object { $_.Replace([System.IO.Path]::DirectorySeparatorChar, '/') }

                # VÃ©rifier si le chemin est dÃ©jÃ  un chemin URL
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
                    throw "Le paramÃ¨tre CustomJoin est requis lorsque le type de jointure est Custom."
                } else {
                    $result = & $CustomJoin $workingPath $workingChildPaths
                }

                $joinSucceeded = $true
            }
        }

        # Normaliser les chemins si demandÃ©
        if ($NormalizePaths -and $JoinType -ne "Normalized" -and $JoinType -ne "Absolute") {
            $result = [System.IO.Path]::GetFullPath($result)
        }

        # RÃ©soudre les chemins relatifs si demandÃ©
        if ($ResolveRelativePaths -and -not [System.IO.Path]::IsPathRooted($result)) {
            $result = [System.IO.Path]::GetFullPath($result)
        }
    } catch {
        $joinSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de joindre les chemins avec le type de jointure $JoinType : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la jointure
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
