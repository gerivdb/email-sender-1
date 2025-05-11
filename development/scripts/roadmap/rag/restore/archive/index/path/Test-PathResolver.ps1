# Test-PathResolver.ps1
# Script de test pour le module de resolution des chemins d'archives
# Version: 1.0
# Date: 2025-05-15

# Importer le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "PathResolver.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier PathResolver.ps1 est introuvable."
    exit 1
}

# Fonction pour executer un test et verifier le resultat
function Test-Function {
    param (
        [string]$TestName,
        [scriptblock]$TestScript,
        [scriptblock]$ValidationScript
    )

    Write-Host "Test: $TestName" -ForegroundColor Cyan

    try {
        # Executer le test
        $result = & $TestScript

        # Valider le resultat
        $isValid = & $ValidationScript $result

        if ($isValid) {
            Write-Host "  Resultat: SUCCES" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Resultat: ECHEC" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Resultat: ERREUR - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Write-Host ""
    }
}

# Fonction pour creer des donnees de test
function New-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )

    # Creer le repertoire de test s'il n'existe pas
    if (-not (Test-Path -Path $TestPath -PathType Container)) {
        New-Item -Path $TestPath -ItemType Directory -Force | Out-Null
    }

    # Creer des sous-repertoires pour les archives
    $archive1Path = Join-Path -Path $TestPath -ChildPath "Archive1"
    $archive2Path = Join-Path -Path $TestPath -ChildPath "Archive2"

    New-Item -Path $archive1Path -ItemType Directory -Force | Out-Null
    New-Item -Path $archive2Path -ItemType Directory -Force | Out-Null

    # Creer des fichiers d'archive
    $archive1File = Join-Path -Path $archive1Path -ChildPath "archive1.dat"
    $archive2File = Join-Path -Path $archive2Path -ChildPath "archive2.dat"

    "Contenu de l'archive 1" | Set-Content -Path $archive1File -Force
    "Contenu de l'archive 2" | Set-Content -Path $archive2File -Force

    # Creer un fichier d'index
    $indexFile = Join-Path -Path $TestPath -ChildPath "index.json"

    $index = @{
        Name        = "Index de test"
        Description = "Index pour les tests de resolution de chemins"
        Archives    = @(
            @{
                Id          = "archive1"
                Name        = "Archive 1"
                ArchivePath = "Archive1\archive1.dat"
            },
            @{
                Id          = "archive2"
                Name        = "Archive 2"
                ArchivePath = "Archive2\archive2.dat"
            },
            @{
                Id          = "archive3"
                Name        = "Archive 3 (inexistante)"
                ArchivePath = "Archive3\archive3.dat"
            }
        )
    }

    $index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexFile -Force

    Write-Host "Donnees de test creees dans: $TestPath"

    # Retourner les chemins crees
    return [PSCustomObject]@{
        TestPath     = $TestPath
        Archive1Path = $archive1Path
        Archive2Path = $archive2Path
        Archive1File = $archive1File
        Archive2File = $archive2File
        IndexFile    = $indexFile
    }
}

# Fonction pour executer les tests
function Test-PathResolverFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$TestData
    )

    Write-Host "Test des fonctions de resolution des chemins d'archives..." -ForegroundColor Cyan

    # Compteurs de tests
    $totalTests = 0
    $passedTests = 0

    # Test 1: Resolution d'un chemin absolu
    $totalTests++
    $testResult = Test-Function -TestName "Resolution d'un chemin absolu" -TestScript {
        return Resolve-ArchivePath -Path $TestData.Archive1File
    } -ValidationScript {
        param($result)
        Write-Host "  Chemin resolu: $($result.ResolvedPath)" -ForegroundColor DarkGray
        return $result -ne $null -and
        $result.ResolvedPath -eq $TestData.Archive1File -and
        $result.IsAbsolute -eq $true -and
        $result.Exists -eq $true -and
        $result.Type -eq "File"
    }
    if ($testResult) { $passedTests++ }

    # Test 2: Resolution d'un chemin relatif
    $totalTests++
    $testResult = Test-Function -TestName "Resolution d'un chemin relatif" -TestScript {
        $relativePath = "Archive1\archive1.dat"
        return Resolve-ArchivePath -Path $relativePath -BasePath $TestData.TestPath
    } -ValidationScript {
        param($result)
        Write-Host "  Chemin resolu: $($result.ResolvedPath)" -ForegroundColor DarkGray
        return $result -ne $null -and
        $result.ResolvedPath -eq $TestData.Archive1File -and
        $result.IsAbsolute -eq $false -and
        $result.Exists -eq $true -and
        $result.Type -eq "File"
    }
    if ($testResult) { $passedTests++ }

    # Test 3: Resolution d'un chemin relatif avec IndexPath
    $totalTests++
    $testResult = Test-Function -TestName "Resolution d'un chemin relatif avec IndexPath" -TestScript {
        $relativePath = "Archive1\archive1.dat"
        return Resolve-ArchivePath -Path $relativePath -IndexPath $TestData.IndexFile
    } -ValidationScript {
        param($result)
        Write-Host "  Chemin resolu: $($result.ResolvedPath)" -ForegroundColor DarkGray
        return $result -ne $null -and
        $result.ResolvedPath -eq $TestData.Archive1File -and
        $result.IsAbsolute -eq $false -and
        $result.Exists -eq $true -and
        $result.Type -eq "File"
    }
    if ($testResult) { $passedTests++ }

    # Test 4: Resolution d'un chemin inexistant
    $totalTests++
    $testResult = Test-Function -TestName "Resolution d'un chemin inexistant" -TestScript {
        $nonExistentPath = "Archive3\archive3.dat"
        return Resolve-ArchivePath -Path $nonExistentPath -BasePath $TestData.TestPath
    } -ValidationScript {
        param($result)
        Write-Host "  Chemin resolu: $($result.ResolvedPath)" -ForegroundColor DarkGray
        return $result -ne $null -and
        $result.Exists -eq $false -and
        $result.Type -eq "Unknown"
    }
    if ($testResult) { $passedTests++ }

    # Test 5: Resolution d'un chemin avec validation d'existence
    $totalTests++
    $testResult = Test-Function -TestName "Resolution d'un chemin avec validation d'existence" -TestScript {
        $nonExistentPath = "Archive3\archive3.dat"
        $result = Resolve-ArchivePath -Path $nonExistentPath -BasePath $TestData.TestPath -ValidateExists -ErrorAction SilentlyContinue
        return $result -eq $null
    } -ValidationScript {
        param($result)
        return $result -eq $true
    }
    if ($testResult) { $passedTests++ }

    # Test 6: Resolution d'un chemin avec creation
    $totalTests++
    $testResult = Test-Function -TestName "Resolution d'un chemin avec creation" -TestScript {
        $newPath = "Archive4\archive4.dat"
        $result = Resolve-ArchivePath -Path $newPath -BasePath $TestData.TestPath -CreateIfNotExists
        $exists = Test-Path -Path (Join-Path -Path $TestData.TestPath -ChildPath $newPath)
        return [PSCustomObject]@{
            Result = $result
            Exists = $exists
        }
    } -ValidationScript {
        param($result)
        Write-Host "  Chemin resolu: $($result.Result.ResolvedPath)" -ForegroundColor DarkGray
        Write-Host "  Existe: $($result.Exists)" -ForegroundColor DarkGray
        return $result.Result -ne $null -and
        $result.Result.Exists -eq $true -and
        $result.Result.Type -eq "File" -and
        $result.Exists -eq $true
    }
    if ($testResult) { $passedTests++ }

    # Test 7: Test d'un chemin valide
    $totalTests++
    $testResult = Test-Function -TestName "Test d'un chemin valide" -TestScript {
        return Test-ArchivePath -Path $TestData.Archive1File
    } -ValidationScript {
        param($result)
        return $result -eq $true
    }
    if ($testResult) { $passedTests++ }

    # Test 8: Test d'un chemin invalide
    $totalTests++
    $testResult = Test-Function -TestName "Test d'un chemin invalide" -TestScript {
        $nonExistentPath = "Archive3\archive3.dat"
        return Test-ArchivePath -Path $nonExistentPath -BasePath $TestData.TestPath -ErrorAction SilentlyContinue
    } -ValidationScript {
        param($result)
        return $result -eq $false
    }
    if ($testResult) { $passedTests++ }

    # Test 9: Test d'un chemin avec verification du type
    $totalTests++
    $testResult = Test-Function -TestName "Test d'un chemin avec verification du type" -TestScript {
        $result1 = Test-ArchivePath -Path $TestData.Archive1File -PathType "File"
        $result2 = Test-ArchivePath -Path $TestData.Archive1File -PathType "Directory" -ErrorAction SilentlyContinue
        return [PSCustomObject]@{
            Result1 = $result1
            Result2 = $result2
        }
    } -ValidationScript {
        param($result)
        return $result.Result1 -eq $true -and $result.Result2 -eq $false
    }
    if ($testResult) { $passedTests++ }

    # Test 10: Obtention des erreurs de chemin
    $totalTests++
    $testResult = Test-Function -TestName "Obtention des erreurs de chemin" -TestScript {
        $nonExistentPath = "Archive3\archive3.dat"
        return Get-ArchivePathError -Path $nonExistentPath -BasePath $TestData.TestPath
    } -ValidationScript {
        param($result)
        Write-Host "  Erreur: $($result.Error)" -ForegroundColor DarkGray
        Write-Host "  Type d'erreur: $($result.ErrorType)" -ForegroundColor DarkGray
        return $result -ne $null -and
        $result.ErrorType -eq "NotFound"
    }
    if ($testResult) { $passedTests++ }

    # Test 11: Conversion d'un chemin relatif en absolu
    $totalTests++
    $testResult = Test-Function -TestName "Conversion d'un chemin relatif en absolu" -TestScript {
        $relativePath = "Archive1\archive1.dat"
        return Convert-ArchivePath -Path $relativePath -ConversionType "ToAbsolute" -BasePath $TestData.TestPath
    } -ValidationScript {
        param($result)
        Write-Host "  Chemin converti: $result" -ForegroundColor DarkGray
        return $result -eq $TestData.Archive1File
    }
    if ($testResult) { $passedTests++ }

    # Test 12: Conversion d'un chemin absolu en relatif
    $totalTests++
    $testResult = Test-Function -TestName "Conversion d'un chemin absolu en relatif" -TestScript {
        return Convert-ArchivePath -Path $TestData.Archive1File -ConversionType "ToRelative" -BasePath $TestData.TestPath
    } -ValidationScript {
        param($result)
        Write-Host "  Chemin converti: $result" -ForegroundColor DarkGray
        return $result -eq "Archive1\archive1.dat"
    }
    if ($testResult) { $passedTests++ }

    # Afficher le resume des tests
    Write-Host "Resume des tests:" -ForegroundColor Yellow
    Write-Host "  Tests executes: $totalTests" -ForegroundColor Yellow
    Write-Host "  Tests reussis: $passedTests" -ForegroundColor Yellow
    Write-Host "  Taux de reussite: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Yellow

    # Verifier si tous les tests ont reussi
    if ($passedTests -eq $totalTests) {
        Write-Host "`nTous les tests ont reussi!" -ForegroundColor Green
    } else {
        Write-Host "`nCertains tests ont echoue." -ForegroundColor Red
    }

    return [PSCustomObject]@{
        TotalTests  = $totalTests
        PassedTests = $passedTests
        SuccessRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
    }
}

# Creer les donnees de test
$testPath = Join-Path -Path $env:TEMP -ChildPath "PathResolverTest"
$testData = New-TestData -TestPath $testPath

# Executer les tests
$testResults = Test-PathResolverFunctions -TestData $testData

# Nettoyer les donnees de test
Remove-Item -Path $testPath -Recurse -Force

# Afficher les resultats des tests
Write-Host "`nResultats des tests:" -ForegroundColor Magenta
Write-Host "  Taux de reussite: $($testResults.SuccessRate)%" -ForegroundColor Magenta
