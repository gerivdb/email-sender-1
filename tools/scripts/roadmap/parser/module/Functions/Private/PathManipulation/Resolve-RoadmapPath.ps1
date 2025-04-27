<#
.SYNOPSIS
    RÃ©sout un chemin de fichier ou de rÃ©pertoire.

.DESCRIPTION
    La fonction Resolve-RoadmapPath rÃ©sout un chemin de fichier ou de rÃ©pertoire.
    Elle prend en charge diffÃ©rentes options de rÃ©solution et peut Ãªtre utilisÃ©e pour
    rÃ©soudre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin Ã  rÃ©soudre.

.PARAMETER ResolutionType
    Le type de rÃ©solution Ã  effectuer. Valeurs possibles :
    - FullPath : RÃ©sout le chemin en chemin absolu complet
    - RelativePath : RÃ©sout le chemin en chemin relatif par rapport Ã  un chemin de base
    - ParentPath : RÃ©sout le chemin parent
    - FileName : RÃ©sout le nom de fichier
    - FileNameWithoutExtension : RÃ©sout le nom de fichier sans extension
    - Extension : RÃ©sout l'extension du fichier
    - DirectoryName : RÃ©sout le nom du rÃ©pertoire
    - RootPath : RÃ©sout le chemin racine
    - PathRoot : RÃ©sout la racine du chemin
    - TempPath : RÃ©sout un chemin temporaire
    - RandomPath : RÃ©sout un chemin alÃ©atoire
    - EnvironmentPath : RÃ©sout un chemin d'environnement
    - Custom : Utilise une rÃ©solution personnalisÃ©e

.PARAMETER BasePath
    Le chemin de base Ã  utiliser pour la rÃ©solution de type RelativePath.
    Par dÃ©faut, c'est le rÃ©pertoire courant.

.PARAMETER CustomResolution
    La fonction de rÃ©solution personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque ResolutionType est "Custom".

.PARAMETER EnvironmentVariable
    La variable d'environnement Ã  utiliser pour la rÃ©solution de type EnvironmentPath.

.PARAMETER CreateIfNotExists
    Indique si le chemin doit Ãªtre crÃ©Ã© s'il n'existe pas.
    Par dÃ©faut, c'est $false.

.PARAMETER Force
    Indique si la rÃ©solution doit Ãªtre forcÃ©e.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la rÃ©solution.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la rÃ©solution.

.EXAMPLE
    Resolve-RoadmapPath -Path ".\folder\file.txt" -ResolutionType FullPath
    RÃ©sout le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    Resolve-RoadmapPath -Path "C:\folder\file.txt" -ResolutionType FileName
    RÃ©sout le nom de fichier "file.txt" Ã  partir du chemin "C:\folder\file.txt".

.OUTPUTS
    [string] Le chemin rÃ©solu.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Resolve-RoadmapPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("FullPath", "RelativePath", "ParentPath", "FileName", "FileNameWithoutExtension", "Extension", "DirectoryName", "RootPath", "PathRoot", "TempPath", "RandomPath", "EnvironmentPath", "Custom")]
        [string]$ResolutionType,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomResolution,

        [Parameter(Mandatory = $false)]
        [string]$EnvironmentVariable,

        [Parameter(Mandatory = $false)]
        [switch]$CreateIfNotExists,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la rÃ©solution
    $result = $null
    $resolutionSucceeded = $false

    # Effectuer la rÃ©solution selon le type
    try {
        # VÃ©rifier si le chemin est vide
        if ([string]::IsNullOrEmpty($Path)) {
            $result = ""
            $resolutionSucceeded = $true
            return $result
        }

        # PrÃ©parer le chemin initial
        $workingPath = $Path.Trim()

        # Effectuer la rÃ©solution selon le type
        switch ($ResolutionType) {
            "FullPath" {
                $result = [System.IO.Path]::GetFullPath($workingPath)
                $resolutionSucceeded = $true
            }
            "RelativePath" {
                # Obtenir les chemins absolus
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)
                $absoluteBasePath = [System.IO.Path]::GetFullPath($BasePath)
                
                # VÃ©rifier si les chemins sont sur le mÃªme lecteur
                $pathDrive = [System.IO.Path]::GetPathRoot($absolutePath)
                $basePathDrive = [System.IO.Path]::GetPathRoot($absoluteBasePath)
                
                if ($pathDrive -ne $basePathDrive) {
                    # Garder le chemin absolu si les lecteurs sont diffÃ©rents
                    $result = $absolutePath
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
                
                $resolutionSucceeded = $true
            }
            "ParentPath" {
                $result = [System.IO.Path]::GetDirectoryName($workingPath)
                $resolutionSucceeded = $true
            }
            "FileName" {
                $result = [System.IO.Path]::GetFileName($workingPath)
                $resolutionSucceeded = $true
            }
            "FileNameWithoutExtension" {
                $result = [System.IO.Path]::GetFileNameWithoutExtension($workingPath)
                $resolutionSucceeded = $true
            }
            "Extension" {
                $result = [System.IO.Path]::GetExtension($workingPath)
                $resolutionSucceeded = $true
            }
            "DirectoryName" {
                $result = [System.IO.Path]::GetDirectoryName($workingPath)
                $resolutionSucceeded = $true
            }
            "RootPath" {
                $result = [System.IO.Path]::GetPathRoot($workingPath)
                $resolutionSucceeded = $true
            }
            "PathRoot" {
                $result = [System.IO.Path]::GetPathRoot($workingPath)
                $resolutionSucceeded = $true
            }
            "TempPath" {
                $result = [System.IO.Path]::GetTempPath()
                
                if (-not [string]::IsNullOrEmpty($workingPath)) {
                    $result = Join-Path -Path $result -ChildPath $workingPath
                }
                
                $resolutionSucceeded = $true
            }
            "RandomPath" {
                $tempPath = [System.IO.Path]::GetTempPath()
                $randomFileName = [System.IO.Path]::GetRandomFileName()
                
                if (-not [string]::IsNullOrEmpty($workingPath)) {
                    $result = Join-Path -Path $tempPath -ChildPath $workingPath
                    $result = Join-Path -Path $result -ChildPath $randomFileName
                } else {
                    $result = Join-Path -Path $tempPath -ChildPath $randomFileName
                }
                
                $resolutionSucceeded = $true
            }
            "EnvironmentPath" {
                if ([string]::IsNullOrEmpty($EnvironmentVariable)) {
                    throw "Le paramÃ¨tre EnvironmentVariable est requis pour la rÃ©solution de type EnvironmentPath."
                } else {
                    $envPath = [System.Environment]::GetEnvironmentVariable($EnvironmentVariable)
                    
                    if ([string]::IsNullOrEmpty($envPath)) {
                        throw "La variable d'environnement '$EnvironmentVariable' n'existe pas ou est vide."
                    } else {
                        if (-not [string]::IsNullOrEmpty($workingPath)) {
                            $result = Join-Path -Path $envPath -ChildPath $workingPath
                        } else {
                            $result = $envPath
                        }
                    }
                }
                
                $resolutionSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomResolution) {
                    throw "Le paramÃ¨tre CustomResolution est requis lorsque le type de rÃ©solution est Custom."
                } else {
                    $result = & $CustomResolution $workingPath
                }
                
                $resolutionSucceeded = $true
            }
        }

        # CrÃ©er le chemin si demandÃ©
        if ($CreateIfNotExists -and -not [string]::IsNullOrEmpty($result)) {
            if (-not (Test-Path -Path $result -ErrorAction SilentlyContinue)) {
                if ($result.EndsWith([System.IO.Path]::DirectorySeparatorChar) -or $result.EndsWith('/') -or (-not [System.IO.Path]::HasExtension($result))) {
                    # CrÃ©er un rÃ©pertoire
                    New-Item -Path $result -ItemType Directory -Force:$Force -ErrorAction Stop | Out-Null
                } else {
                    # CrÃ©er un fichier
                    $parentPath = [System.IO.Path]::GetDirectoryName($result)
                    
                    if (-not (Test-Path -Path $parentPath -ErrorAction SilentlyContinue)) {
                        New-Item -Path $parentPath -ItemType Directory -Force:$Force -ErrorAction Stop | Out-Null
                    }
                    
                    New-Item -Path $result -ItemType File -Force:$Force -ErrorAction Stop | Out-Null
                }
            }
        }
    } catch {
        $resolutionSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de rÃ©soudre le chemin '$Path' avec le type de rÃ©solution $ResolutionType : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la rÃ©solution
    if (-not $resolutionSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $Path
        }
    }

    return $result
}
