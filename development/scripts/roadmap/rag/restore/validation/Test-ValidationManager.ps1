# Test-ValidationManager.ps1
# Script de test pour le module de validation de cohérence post-restauration
# Version: 1.0
# Date: 2025-05-15

# Importer le module de validation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$validationPath = Join-Path -Path $scriptPath -ChildPath "ValidationManager.ps1"

if (Test-Path -Path $validationPath) {
    . $validationPath
} else {
    Write-Error "Le fichier ValidationManager.ps1 est introuvable."
    exit 1
}

# Fonction pour simuler Get-RestorePoints
function Get-RestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    # Créer des points de restauration de test
    $points = @(
        [PSCustomObject]@{
            Id = "point-1"
            Name = "Point de restauration 1"
            Description = "Premier point de restauration de test"
            CreatedAt = [DateTime]::Now.AddDays(-10).ToString("o")
            Type = "Document"
            Category = "Test"
            Tags = @("test", "document", "important")
            Status = "Active"
            Version = "1.0"
            Author = "Test User"
            Size = 1024
            Checksum = "abc123"
            Files = @(
                [PSCustomObject]@{
                    Path = "file1.txt"
                    Size = 100
                    Checksum = "abc123"
                    Version = "1.0"
                },
                [PSCustomObject]@{
                    Path = "file2.txt"
                    Size = 200
                    Checksum = "def456"
                    Version = "1.0"
                }
            )
            Dependencies = @(
                [PSCustomObject]@{
                    TargetId = "point-2"
                    Type = "Direct"
                    Strength = 1.0
                }
            )
            Structure = [PSCustomObject]@{
                Directories = @(
                    "dir1",
                    "dir2"
                )
            }
            Checksums = @(
                [PSCustomObject]@{
                    Path = "file1.txt"
                    Checksum = "abc123"
                },
                [PSCustomObject]@{
                    Path = "file2.txt"
                    Checksum = "def456"
                }
            )
        },
        [PSCustomObject]@{
            Id = "point-2"
            Name = "Point de restauration 2"
            Description = "Deuxième point de restauration de test"
            CreatedAt = [DateTime]::Now.AddDays(-5).ToString("o")
            Type = "Image"
            Category = "Test"
            Tags = @("test", "image")
            Status = "Active"
            Version = "1.0"
            Author = "Test User"
            Size = 2048
            Checksum = "def456"
            Files = @(
                [PSCustomObject]@{
                    Path = "image1.jpg"
                    Size = 1000
                    Checksum = "ghi789"
                    Version = "1.0"
                }
            )
            Dependencies = @(
                [PSCustomObject]@{
                    TargetId = "point-1"
                    Type = "Direct"
                    Strength = 0.8
                }
            )
            Structure = [PSCustomObject]@{
                Directories = @(
                    "images"
                )
            }
            Checksums = @(
                [PSCustomObject]@{
                    Path = "image1.jpg"
                    Checksum = "ghi789"
                }
            )
        }
    )
    
    return $points
}

# Fonction pour créer un environnement de test
function New-TestEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestPath = "$env:TEMP\ValidationTest"
    )
    
    # Créer le répertoire de test
    if (Test-Path -Path $TestPath) {
        Remove-Item -Path $TestPath -Recurse -Force
    }
    
    New-Item -Path $TestPath -ItemType Directory -Force | Out-Null
    
    # Créer les sous-répertoires
    New-Item -Path "$TestPath\dir1" -ItemType Directory -Force | Out-Null
    New-Item -Path "$TestPath\dir2" -ItemType Directory -Force | Out-Null
    New-Item -Path "$TestPath\images" -ItemType Directory -Force | Out-Null
    
    # Créer les fichiers
    "Contenu du fichier 1" | Set-Content -Path "$TestPath\file1.txt" -Force
    "Contenu du fichier 2" | Set-Content -Path "$TestPath\file2.txt" -Force
    
    # Créer un fichier image simulé
    $dummyImageContent = [byte[]]::new(1000)
    [System.IO.File]::WriteAllBytes("$TestPath\images\image1.jpg", $dummyImageContent)
    
    return $TestPath
}

# Fonction pour tester la validation de cohérence
function Test-ValidationCoherence {
    [CmdletBinding()]
    param ()
    
    Write-Host "=== TEST DE VALIDATION DE COHÉRENCE ===" -ForegroundColor Cyan
    
    # Créer l'environnement de test
    $testPath = New-TestEnvironment
    Write-Host "Environnement de test créé : $testPath" -ForegroundColor Green
    
    # Récupérer un point de restauration
    $points = Get-RestorePoints
    $point = $points[0]
    
    Write-Host "Point de restauration à valider : $($point.Name) (ID: $($point.Id))" -ForegroundColor White
    
    # Tester la validation complète
    Write-Host "`nTest de validation complète..." -ForegroundColor Yellow
    $result = Test-RestorePointCoherence -RestorePoint $point -RestorePath $testPath -ShowDetails
    
    Write-Host "Résultat de la validation : $($result.IsValid)" -ForegroundColor $(if ($result.IsValid) { "Green" } else { "Red" })
    Write-Host "Nombre d'erreurs : $($result.Errors.Count)" -ForegroundColor $(if ($result.Errors.Count -eq 0) { "Green" } else { "Red" })
    Write-Host "Nombre d'avertissements : $($result.Warnings.Count)" -ForegroundColor $(if ($result.Warnings.Count -eq 0) { "Green" } else { "Yellow" })
    
    # Tester la validation du contenu
    Write-Host "`nTest de validation du contenu..." -ForegroundColor Yellow
    $contentResult = Test-RestoredContent -RestorePoint $point -RestorePath $testPath -ShowDetails
    
    Write-Host "Résultat de la validation du contenu : $($contentResult.IsValid)" -ForegroundColor $(if ($contentResult.IsValid) { "Green" } else { "Red" })
    
    # Tester la validation des dépendances
    Write-Host "`nTest de validation des dépendances..." -ForegroundColor Yellow
    $dependencyResult = Test-RestoredDependencies -RestorePoint $point -RestorePath $testPath -ShowDetails
    
    Write-Host "Résultat de la validation des dépendances : $($dependencyResult.IsValid)" -ForegroundColor $(if ($dependencyResult.IsValid) { "Green" } else { "Red" })
    
    # Tester la validation de l'intégrité
    Write-Host "`nTest de validation de l'intégrité..." -ForegroundColor Yellow
    $integrityResult = Test-RestoredIntegrity -RestorePoint $point -RestorePath $testPath -ShowDetails
    
    Write-Host "Résultat de la validation de l'intégrité : $($integrityResult.IsValid)" -ForegroundColor $(if ($integrityResult.IsValid) { "Green" } else { "Red" })
    
    # Simuler des erreurs
    Write-Host "`nTest de validation avec erreurs simulées..." -ForegroundColor Yellow
    
    # Supprimer un fichier
    Remove-Item -Path "$testPath\file1.txt" -Force
    Write-Host "Fichier supprimé : $testPath\file1.txt" -ForegroundColor Red
    
    # Modifier un fichier
    "Contenu modifié" | Set-Content -Path "$testPath\file2.txt" -Force
    Write-Host "Fichier modifié : $testPath\file2.txt" -ForegroundColor Red
    
    # Tester à nouveau la validation
    $resultWithErrors = Test-RestorePointCoherence -RestorePoint $point -RestorePath $testPath -ShowDetails
    
    Write-Host "Résultat de la validation avec erreurs : $($resultWithErrors.IsValid)" -ForegroundColor $(if ($resultWithErrors.IsValid) { "Green" } else { "Red" })
    Write-Host "Nombre d'erreurs : $($resultWithErrors.Errors.Count)" -ForegroundColor $(if ($resultWithErrors.Errors.Count -eq 0) { "Green" } else { "Red" })
    
    # Nettoyer l'environnement de test
    Remove-Item -Path $testPath -Recurse -Force
    Write-Host "`nEnvironnement de test nettoyé." -ForegroundColor Green
    
    Write-Host "`nTest de validation terminé." -ForegroundColor Cyan
}

# Exécuter le test
Test-ValidationCoherence
