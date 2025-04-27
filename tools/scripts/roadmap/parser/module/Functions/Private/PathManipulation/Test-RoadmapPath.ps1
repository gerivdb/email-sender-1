<#
.SYNOPSIS
    Teste un chemin de fichier ou de rÃ©pertoire selon diffÃ©rents critÃ¨res.

.DESCRIPTION
    La fonction Test-RoadmapPath teste un chemin de fichier ou de rÃ©pertoire selon diffÃ©rents critÃ¨res.
    Elle prend en charge diffÃ©rents types de tests et peut Ãªtre utilisÃ©e pour
    valider les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin Ã  tester.

.PARAMETER TestType
    Le type de test Ã  effectuer. Valeurs possibles :
    - Exists : VÃ©rifie si le chemin existe
    - IsFile : VÃ©rifie si le chemin est un fichier
    - IsDirectory : VÃ©rifie si le chemin est un rÃ©pertoire
    - IsReadable : VÃ©rifie si le chemin est lisible
    - IsWritable : VÃ©rifie si le chemin est modifiable
    - IsHidden : VÃ©rifie si le chemin est cachÃ©
    - IsRooted : VÃ©rifie si le chemin est absolu
    - IsRelative : VÃ©rifie si le chemin est relatif
    - IsValid : VÃ©rifie si le chemin est valide
    - HasExtension : VÃ©rifie si le chemin a une extension
    - HasParent : VÃ©rifie si le chemin a un parent
    - MatchesPattern : VÃ©rifie si le chemin correspond Ã  un motif
    - Custom : Utilise un test personnalisÃ©

.PARAMETER CustomTest
    La fonction de test personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque TestType est "Custom".

.PARAMETER Pattern
    Le motif Ã  utiliser pour le test de type MatchesPattern.

.PARAMETER Extension
    L'extension Ã  vÃ©rifier pour le test de type HasExtension.
    Si non spÃ©cifiÃ©, vÃ©rifie simplement si le chemin a une extension.

.PARAMETER IgnoreCase
    Indique si la casse doit Ãªtre ignorÃ©e lors du test.
    Par dÃ©faut, c'est $false.

.PARAMETER Recurse
    Indique si le test doit Ãªtre rÃ©cursif pour les rÃ©pertoires.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec du test.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec du test.

.EXAMPLE
    Test-RoadmapPath -Path "C:\folder\file.txt" -TestType Exists
    VÃ©rifie si le fichier "C:\folder\file.txt" existe.

.EXAMPLE
    Test-RoadmapPath -Path "C:\folder" -TestType IsDirectory
    VÃ©rifie si "C:\folder" est un rÃ©pertoire.

.OUTPUTS
    [bool] Le rÃ©sultat du test.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
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

    # Initialiser le rÃ©sultat du test
    $result = $false
    $testSucceeded = $false

    # Effectuer le test selon le type
    try {
        # VÃ©rifier si le chemin est vide
        if ([string]::IsNullOrEmpty($Path)) {
            $result = $false
            $testSucceeded = $true
            return $result
        }

        # PrÃ©parer le chemin initial
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
                            # Tester si le rÃ©pertoire est lisible
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
                            # Tester si le rÃ©pertoire est modifiable
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
                    # VÃ©rifier si le chemin contient des caractÃ¨res invalides
                    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
                    $result = -not ($workingPath.IndexOfAny($invalidChars) -ge 0)

                    # VÃ©rifier si le chemin est trop long
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
                    # VÃ©rifier si le chemin a l'extension spÃ©cifiÃ©e
                    $pathExtension = [System.IO.Path]::GetExtension($workingPath)

                    # Normaliser l'extension spÃ©cifiÃ©e
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
                    # VÃ©rifier si le chemin a une extension
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
                    throw "Le paramÃ¨tre Pattern est requis pour le test de type MatchesPattern."
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
                    throw "Le paramÃ¨tre CustomTest est requis lorsque le type de test est Custom."
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

    # GÃ©rer l'Ã©chec du test
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
