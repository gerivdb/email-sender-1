<#
.SYNOPSIS
    Résout un chemin de fichier ou de répertoire.

.DESCRIPTION
    La fonction Resolve-RoadmapPath résout un chemin de fichier ou de répertoire.
    Elle prend en charge différentes options de résolution et peut être utilisée pour
    résoudre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin à résoudre.

.PARAMETER ResolutionType
    Le type de résolution à effectuer. Valeurs possibles :
    - FullPath : Résout le chemin en chemin absolu complet
    - RelativePath : Résout le chemin en chemin relatif par rapport à un chemin de base
    - ParentPath : Résout le chemin parent
    - FileName : Résout le nom de fichier
    - FileNameWithoutExtension : Résout le nom de fichier sans extension
    - Extension : Résout l'extension du fichier
    - DirectoryName : Résout le nom du répertoire
    - RootPath : Résout le chemin racine
    - PathRoot : Résout la racine du chemin
    - TempPath : Résout un chemin temporaire
    - RandomPath : Résout un chemin aléatoire
    - EnvironmentPath : Résout un chemin d'environnement
    - Custom : Utilise une résolution personnalisée

.PARAMETER BasePath
    Le chemin de base à utiliser pour la résolution de type RelativePath.
    Par défaut, c'est le répertoire courant.

.PARAMETER CustomResolution
    La fonction de résolution personnalisée à utiliser.
    Utilisé uniquement lorsque ResolutionType est "Custom".

.PARAMETER EnvironmentVariable
    La variable d'environnement à utiliser pour la résolution de type EnvironmentPath.

.PARAMETER CreateIfNotExists
    Indique si le chemin doit être créé s'il n'existe pas.
    Par défaut, c'est $false.

.PARAMETER Force
    Indique si la résolution doit être forcée.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la résolution.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la résolution.

.EXAMPLE
    Resolve-RoadmapPath -Path ".\folder\file.txt" -ResolutionType FullPath
    Résout le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    Resolve-RoadmapPath -Path "C:\folder\file.txt" -ResolutionType FileName
    Résout le nom de fichier "file.txt" à partir du chemin "C:\folder\file.txt".

.OUTPUTS
    [string] Le chemin résolu.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
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

    # Initialiser le résultat de la résolution
    $result = $null
    $resolutionSucceeded = $false

    # Effectuer la résolution selon le type
    try {
        # Vérifier si le chemin est vide
        if ([string]::IsNullOrEmpty($Path)) {
            $result = ""
            $resolutionSucceeded = $true
            return $result
        }

        # Préparer le chemin initial
        $workingPath = $Path.Trim()

        # Effectuer la résolution selon le type
        switch ($ResolutionType) {
            "FullPath" {
                $result = [System.IO.Path]::GetFullPath($workingPath)
                $resolutionSucceeded = $true
            }
            "RelativePath" {
                # Obtenir les chemins absolus
                $absolutePath = [System.IO.Path]::GetFullPath($workingPath)
                $absoluteBasePath = [System.IO.Path]::GetFullPath($BasePath)
                
                # Vérifier si les chemins sont sur le même lecteur
                $pathDrive = [System.IO.Path]::GetPathRoot($absolutePath)
                $basePathDrive = [System.IO.Path]::GetPathRoot($absoluteBasePath)
                
                if ($pathDrive -ne $basePathDrive) {
                    # Garder le chemin absolu si les lecteurs sont différents
                    $result = $absolutePath
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
                    throw "Le paramètre EnvironmentVariable est requis pour la résolution de type EnvironmentPath."
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
                    throw "Le paramètre CustomResolution est requis lorsque le type de résolution est Custom."
                } else {
                    $result = & $CustomResolution $workingPath
                }
                
                $resolutionSucceeded = $true
            }
        }

        # Créer le chemin si demandé
        if ($CreateIfNotExists -and -not [string]::IsNullOrEmpty($result)) {
            if (-not (Test-Path -Path $result -ErrorAction SilentlyContinue)) {
                if ($result.EndsWith([System.IO.Path]::DirectorySeparatorChar) -or $result.EndsWith('/') -or (-not [System.IO.Path]::HasExtension($result))) {
                    # Créer un répertoire
                    New-Item -Path $result -ItemType Directory -Force:$Force -ErrorAction Stop | Out-Null
                } else {
                    # Créer un fichier
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
            $ErrorMessage = "Impossible de résoudre le chemin '$Path' avec le type de résolution $ResolutionType : $_"
        }
    }

    # Gérer l'échec de la résolution
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
