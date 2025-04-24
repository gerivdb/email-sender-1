<#
.SYNOPSIS
    Teste un chemin de fichier ou de répertoire selon différents critères.

.DESCRIPTION
    La fonction Test-RoadmapPath teste un chemin de fichier ou de répertoire selon différents critères.
    Elle prend en charge différents types de tests et peut être utilisée pour
    valider les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin à tester.

.PARAMETER TestType
    Le type de test à effectuer. Valeurs possibles :
    - Exists : Vérifie si le chemin existe
    - IsFile : Vérifie si le chemin est un fichier
    - IsDirectory : Vérifie si le chemin est un répertoire
    - IsReadable : Vérifie si le chemin est lisible
    - IsWritable : Vérifie si le chemin est modifiable
    - IsHidden : Vérifie si le chemin est caché
    - IsRooted : Vérifie si le chemin est absolu
    - IsRelative : Vérifie si le chemin est relatif
    - IsValid : Vérifie si le chemin est valide
    - HasExtension : Vérifie si le chemin a une extension
    - HasParent : Vérifie si le chemin a un parent
    - MatchesPattern : Vérifie si le chemin correspond à un motif
    - Custom : Utilise un test personnalisé

.PARAMETER CustomTest
    La fonction de test personnalisée à utiliser.
    Utilisé uniquement lorsque TestType est "Custom".

.PARAMETER Pattern
    Le motif à utiliser pour le test de type MatchesPattern.

.PARAMETER Extension
    L'extension à vérifier pour le test de type HasExtension.
    Si non spécifié, vérifie simplement si le chemin a une extension.

.PARAMETER IgnoreCase
    Indique si la casse doit être ignorée lors du test.
    Par défaut, c'est $false.

.PARAMETER Recurse
    Indique si le test doit être récursif pour les répertoires.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec du test.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec du test.

.EXAMPLE
    Test-RoadmapPath -Path "C:\folder\file.txt" -TestType Exists
    Vérifie si le fichier "C:\folder\file.txt" existe.

.EXAMPLE
    Test-RoadmapPath -Path "C:\folder" -TestType IsDirectory
    Vérifie si "C:\folder" est un répertoire.

.OUTPUTS
    [bool] Le résultat du test.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Test-RoadmapPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Exists", "IsFile", "IsDirectory", "IsReadable", "IsWritable", "IsHidden", "IsRooted", "IsRelative", "IsValid", "HasExtension", "HasParent", "MatchesPattern", "Custom")]
        [string]$TestType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomTest,

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string]$Extension,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat du test
    $result = $false
    $testSucceeded = $false

    # Effectuer le test selon le type
    try {
        # Vérifier si le chemin est vide
        if ([string]::IsNullOrEmpty($Path)) {
            $result = $false
            $testSucceeded = $true
            return $result
        }

        # Préparer le chemin initial
        $workingPath = $Path.Trim()

        # Effectuer le test selon le type
        switch ($TestType) {
            "Exists" {
                $result = Test-Path -Path $workingPath -ErrorAction SilentlyContinue
                $testSucceeded = $true
            }
            "IsFile" {
                if (Test-Path -Path $workingPath -ErrorAction SilentlyContinue) {
                    $item = Get-Item -Path $workingPath -ErrorAction SilentlyContinue
                    $result = $item -is [System.IO.FileInfo]
                } else {
                    $result = $false
                }
                $testSucceeded = $true
            }
            "IsDirectory" {
                if (Test-Path -Path $workingPath -ErrorAction SilentlyContinue) {
                    $item = Get-Item -Path $workingPath -ErrorAction SilentlyContinue
                    $result = $item -is [System.IO.DirectoryInfo]
                } else {
                    $result = $false
                }
                $testSucceeded = $true
            }
            "IsReadable" {
                if (Test-Path -Path $workingPath -ErrorAction SilentlyContinue) {
                    try {
                        $item = Get-Item -Path $workingPath -ErrorAction SilentlyContinue
                        if ($item -is [System.IO.FileInfo]) {
                            # Tester si le fichier est lisible
                            $stream = [System.IO.File]::OpenRead($item.FullName)
                            $stream.Close()
                            $result = $true
                        } else {
                            # Tester si le répertoire est lisible
                            $items = Get-ChildItem -Path $item.FullName -ErrorAction SilentlyContinue
                            $result = $true
                        }
                    } catch {
                        $result = $false
                    }
                } else {
                    $result = $false
                }
                $testSucceeded = $true
            }
            "IsWritable" {
                if (Test-Path -Path $workingPath -ErrorAction SilentlyContinue) {
                    try {
                        $item = Get-Item -Path $workingPath -ErrorAction SilentlyContinue
                        if ($item -is [System.IO.FileInfo]) {
                            # Tester si le fichier est modifiable
                            $stream = [System.IO.File]::OpenWrite($item.FullName)
                            $stream.Close()
                            $result = $true
                        } else {
                            # Tester si le répertoire est modifiable
                            $testFile = Join-Path -Path $item.FullName -ChildPath "test_write_$([Guid]::NewGuid().ToString()).tmp"
                            [System.IO.File]::Create($testFile).Close()
                            Remove-Item -Path $testFile -Force
                            $result = $true
                        }
                    } catch {
                        $result = $false
                    }
                } else {
                    $result = $false
                }
                $testSucceeded = $true
            }
            "IsHidden" {
                if (Test-Path -Path $workingPath -ErrorAction SilentlyContinue) {
                    $item = Get-Item -Path $workingPath -ErrorAction SilentlyContinue -Force
                    $result = ($item.Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0
                } else {
                    $result = $false
                }
                $testSucceeded = $true
            }
            "IsRooted" {
                $result = [System.IO.Path]::IsPathRooted($workingPath)
                $testSucceeded = $true
            }
            "IsRelative" {
                $result = -not [System.IO.Path]::IsPathRooted($workingPath)
                $testSucceeded = $true
            }
            "IsValid" {
                try {
                    # Vérifier si le chemin contient des caractères invalides
                    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
                    $result = -not ($workingPath.IndexOfAny($invalidChars) -ge 0)

                    # Vérifier si le chemin est trop long
                    if ($result) {
                        $result = $workingPath.Length -le 260
                    }
                } catch {
                    $result = $false
                }
                $testSucceeded = $true
            }
            "HasExtension" {
                if ($PSBoundParameters.ContainsKey('Extension')) {
                    # Vérifier si le chemin a l'extension spécifiée
                    $pathExtension = [System.IO.Path]::GetExtension($workingPath)

                    # Normaliser l'extension spécifiée
                    $normalizedExtension = $Extension
                    if (-not $normalizedExtension.StartsWith(".")) {
                        $normalizedExtension = ".$normalizedExtension"
                    }

                    if ($IgnoreCase) {
                        $result = $pathExtension -ieq $normalizedExtension
                    } else {
                        $result = $pathExtension -ceq $normalizedExtension
                    }
                } else {
                    # Vérifier si le chemin a une extension
                    $result = [System.IO.Path]::HasExtension($workingPath)
                }
                $testSucceeded = $true
            }
            "HasParent" {
                $parent = [System.IO.Path]::GetDirectoryName($workingPath)
                $result = -not [string]::IsNullOrEmpty($parent)
                $testSucceeded = $true
            }
            "MatchesPattern" {
                if ([string]::IsNullOrEmpty($Pattern)) {
                    throw "Le paramètre Pattern est requis pour le test de type MatchesPattern."
                } else {
                    if ($IgnoreCase) {
                        $result = $workingPath -like $Pattern
                    } else {
                        $result = $workingPath -clike $Pattern
                    }
                }
                $testSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomTest) {
                    throw "Le paramètre CustomTest est requis lorsque le type de test est Custom."
                } else {
                    $result = & $CustomTest $workingPath
                }
                $testSucceeded = $true
            }
        }
    } catch {
        $testSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible d'effectuer le test $TestType sur le chemin '$Path' : $_"
        }
    }

    # Gérer l'échec du test
    if (-not $testSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $false
        }
    }

    return $result
}
