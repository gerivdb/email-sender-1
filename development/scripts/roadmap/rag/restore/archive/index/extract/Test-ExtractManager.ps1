# Test-ExtractManager.ps1
# Script de test pour le module d'extraction selective
# Version: 1.0
# Date: 2025-05-15

# Importer le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "ExtractManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier ExtractManager.ps1 est introuvable."
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
        Name = "Index de test"
        Description = "Index pour les tests d'extraction"
        Archives = @(
            @{
                Id = "archive1"
                Name = "Archive 1"
                Description = "Premiere archive de test"
                ArchivePath = "Archive1\archive1.dat"
                Type = "Document"
                Category = "Test"
                Tags = @("test", "document")
                Status = "Active"
            },
            @{
                Id = "archive2"
                Name = "Archive 2"
                Description = "Deuxieme archive de test"
                ArchivePath = "Archive2\archive2.dat"
                Type = "Document"
                Category = "Test"
                Tags = @("test", "document")
                Status = "Active"
            },
            @{
                Id = "archive3"
                Name = "Archive 3 (inexistante)"
                Description = "Archive inexistante pour les tests d'erreur"
                ArchivePath = "Archive3\archive3.dat"
                Type = "Document"
                Category = "Test"
                Tags = @("test", "document")
                Status = "Active"
            }
        )
    }
    
    $index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexFile -Force
    
    # Creer un repertoire de sortie
    $outputPath = Join-Path -Path $TestPath -ChildPath "Output"
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
    
    # Creer un repertoire cible pour les tests de restauration
    $targetPath = Join-Path -Path $TestPath -ChildPath "Target"
    New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    
    Write-Host "Donnees de test creees dans: $TestPath"
    
    # Retourner les chemins crees
    return [PSCustomObject]@{
        TestPath = $TestPath
        Archive1Path = $archive1Path
        Archive2Path = $archive2Path
        Archive1File = $archive1File
        Archive2File = $archive2File
        IndexFile = $indexFile
        OutputPath = $outputPath
        TargetPath = $targetPath
    }
}

# Fonction pour executer les tests
function Test-ExtractManagerFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$TestData
    )
    
    Write-Host "Test des fonctions d'extraction selective..." -ForegroundColor Cyan
    
    # Compteurs de tests
    $totalTests = 0
    $passedTests = 0
    
    # Test 1: Extraction d'un element par ID
    $totalTests++
    $testResult = Test-Function -TestName "Extraction d'un element par ID" -TestScript {
        $outputFile = Join-Path -Path $TestData.OutputPath -ChildPath "extracted_by_id.dat"
        if (Test-Path -Path $outputFile) {
            Remove-Item -Path $outputFile -Force
        }
        
        return Extract-ArchiveItem -Id "archive1" -IndexPath $TestData.IndexFile -OutputPath $TestData.OutputPath -CreateOutputPath
    } -ValidationScript {
        param($result)
        $outputFile = Join-Path -Path $TestData.OutputPath -ChildPath "archive1.dat"
        $exists = Test-Path -Path $outputFile -PathType Leaf
        
        Write-Host "  Archive extraite: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Chemin de sortie: $($result.OutputPath)" -ForegroundColor DarkGray
        Write-Host "  Fichier existe: $exists" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive1" -and 
               $result.SourcePath -eq $TestData.Archive1File -and 
               $result.Success -eq $true -and 
               $exists
    }
    if ($testResult) { $passedTests++ }
    
    # Test 2: Extraction d'un element par chemin
    $totalTests++
    $testResult = Test-Function -TestName "Extraction d'un element par chemin" -TestScript {
        return Extract-ArchiveItem -ArchivePath "Archive2\archive2.dat" -IndexPath $TestData.IndexFile -OutputPath $TestData.OutputPath -CreateOutputPath
    } -ValidationScript {
        param($result)
        $outputFile = Join-Path -Path $TestData.OutputPath -ChildPath "archive2.dat"
        $exists = Test-Path -Path $outputFile -PathType Leaf
        
        Write-Host "  Archive extraite: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Chemin de sortie: $($result.OutputPath)" -ForegroundColor DarkGray
        Write-Host "  Fichier existe: $exists" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive2" -and 
               $result.SourcePath -eq $TestData.Archive2File -and 
               $result.Success -eq $true -and 
               $exists
    }
    if ($testResult) { $passedTests++ }
    
    # Test 3: Extraction d'un element avec preservation de la structure
    $totalTests++
    $testResult = Test-Function -TestName "Extraction d'un element avec preservation de la structure" -TestScript {
        $structurePath = Join-Path -Path $TestData.OutputPath -ChildPath "Structure"
        if (Test-Path -Path $structurePath) {
            Remove-Item -Path $structurePath -Recurse -Force
        }
        New-Item -Path $structurePath -ItemType Directory -Force | Out-Null
        
        return Extract-ArchiveItem -Id "archive1" -IndexPath $TestData.IndexFile -OutputPath $structurePath -CreateOutputPath -PreserveStructure
    } -ValidationScript {
        param($result)
        $outputFile = Join-Path -Path (Join-Path -Path $TestData.OutputPath -ChildPath "Structure") -ChildPath "Archive1\archive1.dat"
        $exists = Test-Path -Path $outputFile -PathType Leaf
        
        Write-Host "  Archive extraite: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Chemin de sortie: $($result.OutputPath)" -ForegroundColor DarkGray
        Write-Host "  Fichier existe: $exists" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive1" -and 
               $result.Success -eq $true -and 
               $exists
    }
    if ($testResult) { $passedTests++ }
    
    # Test 4: Extraction d'un element inexistant
    $totalTests++
    $testResult = Test-Function -TestName "Extraction d'un element inexistant" -TestScript {
        $result = Extract-ArchiveItem -Id "archive3" -IndexPath $TestData.IndexFile -OutputPath $TestData.OutputPath -CreateOutputPath -ErrorAction SilentlyContinue
        return $result -eq $null
    } -ValidationScript {
        param($result)
        return $result -eq $true
    }
    if ($testResult) { $passedTests++ }
    
    # Test 5: Extraction avec ecrasement
    $totalTests++
    $testResult = Test-Function -TestName "Extraction avec ecrasement" -TestScript {
        # Creer un fichier existant
        $existingFile = Join-Path -Path $TestData.OutputPath -ChildPath "archive1.dat"
        "Contenu existant" | Set-Content -Path $existingFile -Force
        
        # Extraire avec ecrasement
        return Extract-ArchiveItem -Id "archive1" -IndexPath $TestData.IndexFile -OutputPath $TestData.OutputPath -Overwrite
    } -ValidationScript {
        param($result)
        $outputFile = Join-Path -Path $TestData.OutputPath -ChildPath "archive1.dat"
        $content = Get-Content -Path $outputFile -Raw
        
        Write-Host "  Archive extraite: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Contenu du fichier: $content" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive1" -and 
               $result.Success -eq $true -and 
               $content -eq "Contenu de l'archive 1"
    }
    if ($testResult) { $passedTests++ }
    
    # Test 6: Validation de restauration
    $totalTests++
    $testResult = Test-Function -TestName "Validation de restauration" -TestScript {
        $targetFile = Join-Path -Path $TestData.TargetPath -ChildPath "archive1.dat"
        if (Test-Path -Path $targetFile) {
            Remove-Item -Path $targetFile -Force
        }
        
        return Test-RestoreValidity -Id "archive1" -IndexPath $TestData.IndexFile -TargetPath $targetFile
    } -ValidationScript {
        param($result)
        Write-Host "  Archive a restaurer: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Chemin cible: $($result.TargetPath)" -ForegroundColor DarkGray
        Write-Host "  Chemin final: $($result.FinalPath)" -ForegroundColor DarkGray
        Write-Host "  Cible existe: $($result.TargetExists)" -ForegroundColor DarkGray
        Write-Host "  Est valide: $($result.IsValid)" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive1" -and 
               $result.SourcePath -eq $TestData.Archive1File -and 
               $result.TargetExists -eq $false -and 
               $result.IsValid -eq $true
    }
    if ($testResult) { $passedTests++ }
    
    # Test 7: Validation de restauration avec conflit (Skip)
    $totalTests++
    $testResult = Test-Function -TestName "Validation de restauration avec conflit (Skip)" -TestScript {
        $targetFile = Join-Path -Path $TestData.TargetPath -ChildPath "archive1.dat"
        "Contenu existant" | Set-Content -Path $targetFile -Force
        
        return Test-RestoreValidity -Id "archive1" -IndexPath $TestData.IndexFile -TargetPath $targetFile -ConflictResolution "Skip"
    } -ValidationScript {
        param($result)
        Write-Host "  Archive a restaurer: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Chemin cible: $($result.TargetPath)" -ForegroundColor DarkGray
        Write-Host "  Chemin final: $($result.FinalPath)" -ForegroundColor DarkGray
        Write-Host "  Cible existe: $($result.TargetExists)" -ForegroundColor DarkGray
        Write-Host "  Est valide: $($result.IsValid)" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive1" -and 
               $result.TargetExists -eq $true -and 
               $result.FinalPath -eq $null -and 
               $result.IsValid -eq $false
    }
    if ($testResult) { $passedTests++ }
    
    # Test 8: Validation de restauration avec conflit (Rename)
    $totalTests++
    $testResult = Test-Function -TestName "Validation de restauration avec conflit (Rename)" -TestScript {
        $targetFile = Join-Path -Path $TestData.TargetPath -ChildPath "archive1.dat"
        "Contenu existant" | Set-Content -Path $targetFile -Force
        
        return Test-RestoreValidity -Id "archive1" -IndexPath $TestData.IndexFile -TargetPath $targetFile -ConflictResolution "Rename"
    } -ValidationScript {
        param($result)
        $renamedFile = Join-Path -Path $TestData.TargetPath -ChildPath "archive1_1.dat"
        
        Write-Host "  Archive a restaurer: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Chemin cible: $($result.TargetPath)" -ForegroundColor DarkGray
        Write-Host "  Chemin final: $($result.FinalPath)" -ForegroundColor DarkGray
        Write-Host "  Cible existe: $($result.TargetExists)" -ForegroundColor DarkGray
        Write-Host "  Est valide: $($result.IsValid)" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive1" -and 
               $result.TargetExists -eq $true -and 
               $result.FinalPath -eq $renamedFile -and 
               $result.IsValid -eq $true
    }
    if ($testResult) { $passedTests++ }
    
    # Test 9: Validation de restauration avec conflit (Overwrite)
    $totalTests++
    $testResult = Test-Function -TestName "Validation de restauration avec conflit (Overwrite)" -TestScript {
        $targetFile = Join-Path -Path $TestData.TargetPath -ChildPath "archive1.dat"
        "Contenu existant" | Set-Content -Path $targetFile -Force
        
        return Test-RestoreValidity -Id "archive1" -IndexPath $TestData.IndexFile -TargetPath $targetFile -ConflictResolution "Overwrite"
    } -ValidationScript {
        param($result)
        Write-Host "  Archive a restaurer: $($result.Archive.Name)" -ForegroundColor DarkGray
        Write-Host "  Chemin cible: $($result.TargetPath)" -ForegroundColor DarkGray
        Write-Host "  Chemin final: $($result.FinalPath)" -ForegroundColor DarkGray
        Write-Host "  Cible existe: $($result.TargetExists)" -ForegroundColor DarkGray
        Write-Host "  Est valide: $($result.IsValid)" -ForegroundColor DarkGray
        
        return $result -ne $null -and 
               $result.Archive.Id -eq "archive1" -and 
               $result.TargetExists -eq $true -and 
               $result.FinalPath -eq $result.TargetPath -and 
               $result.IsValid -eq $true
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
        TotalTests = $totalTests
        PassedTests = $passedTests
        SuccessRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
    }
}

# Creer les donnees de test
$testPath = Join-Path -Path $env:TEMP -ChildPath "ExtractManagerTest"
$testData = New-TestData -TestPath $testPath

# Executer les tests
$testResults = Test-ExtractManagerFunctions -TestData $testData

# Nettoyer les donnees de test
Remove-Item -Path $testPath -Recurse -Force

# Afficher les resultats des tests
Write-Host "`nResultats des tests:" -ForegroundColor Magenta
Write-Host "  Taux de reussite: $($testResults.SuccessRate)%" -ForegroundColor Magenta
