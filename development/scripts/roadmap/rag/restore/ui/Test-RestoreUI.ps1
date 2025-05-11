# Test-RestoreUI.ps1
# Script de test pour l'interface utilisateur de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path $scriptPath -ChildPath "RestorePointsViewer.ps1"
$filterPath = Join-Path -Path $scriptPath -ChildPath "FilterManager.ps1"

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier RestorePointsViewer.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $filterPath) {
    . $filterPath
} else {
    Write-Error "Le fichier FilterManager.ps1 est introuvable."
    exit 1
}

# Fonction pour créer des données de test
function New-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    # Créer le répertoire de test s'il n'existe pas
    if (-not (Test-Path -Path $TestPath -PathType Container)) {
        New-Item -Path $TestPath -ItemType Directory -Force | Out-Null
    }
    
    # Créer des sous-répertoires pour les archives
    $archive1Path = Join-Path -Path $TestPath -ChildPath "Archive1"
    $archive2Path = Join-Path -Path $TestPath -ChildPath "Archive2"
    $archive3Path = Join-Path -Path $TestPath -ChildPath "Archive3"
    
    New-Item -Path $archive1Path -ItemType Directory -Force | Out-Null
    New-Item -Path $archive2Path -ItemType Directory -Force | Out-Null
    New-Item -Path $archive3Path -ItemType Directory -Force | Out-Null
    
    # Créer des fichiers d'archive
    $archive1File = Join-Path -Path $archive1Path -ChildPath "archive1.dat"
    $archive2File = Join-Path -Path $archive2Path -ChildPath "archive2.dat"
    $archive3File = Join-Path -Path $archive3Path -ChildPath "archive3.dat"
    
    "Contenu de l'archive 1" | Set-Content -Path $archive1File -Force
    "Contenu de l'archive 2" | Set-Content -Path $archive2File -Force
    "Contenu de l'archive 3" | Set-Content -Path $archive3File -Force
    
    # Créer des fichiers d'index
    $index1 = @{
        Name = "Index 1"
        Description = "Premier index de test"
        CreatedAt = [DateTime]::Now.AddDays(-30).ToString("o")
        Archives = @(
            @{
                Id = "archive1-1"
                Name = "Archive 1-1"
                Description = "Première archive de l'index 1"
                CreatedAt = [DateTime]::Now.AddDays(-30).ToString("o")
                ModifiedAt = [DateTime]::Now.AddDays(-25).ToString("o")
                ArchivedAt = [DateTime]::Now.AddDays(-20).ToString("o")
                ArchivePath = "Archive1\archive1.dat"
                Type = "Document"
                Category = "Test"
                Tags = @("test", "document", "important")
                Status = "Active"
                Version = "1.0"
                Author = "Jean Dupont"
            },
            @{
                Id = "archive1-2"
                Name = "Archive 1-2"
                Description = "Deuxième archive de l'index 1"
                CreatedAt = [DateTime]::Now.AddDays(-28).ToString("o")
                ModifiedAt = [DateTime]::Now.AddDays(-26).ToString("o")
                ArchivedAt = [DateTime]::Now.AddDays(-24).ToString("o")
                ArchivePath = "Archive1\archive1.dat"
                Type = "Image"
                Category = "Test"
                Tags = @("test", "image")
                Status = "Archived"
                Version = "1.1"
                Author = "Marie Martin"
            }
        )
    }
    
    $index2 = @{
        Name = "Index 2"
        Description = "Deuxième index de test"
        CreatedAt = [DateTime]::Now.AddDays(-20).ToString("o")
        Archives = @(
            @{
                Id = "archive2-1"
                Name = "Archive 2-1"
                Description = "Première archive de l'index 2"
                CreatedAt = [DateTime]::Now.AddDays(-20).ToString("o")
                ModifiedAt = [DateTime]::Now.AddDays(-15).ToString("o")
                ArchivedAt = [DateTime]::Now.AddDays(-10).ToString("o")
                ArchivePath = "Archive2\archive2.dat"
                Type = "Document"
                Category = "Production"
                Tags = @("production", "document", "important")
                Status = "Active"
                Version = "2.0"
                Author = "Jean Dupont"
            }
        )
    }
    
    $index3 = @{
        Name = "Index 3"
        Description = "Troisième index de test"
        CreatedAt = [DateTime]::Now.AddDays(-10).ToString("o")
        Archives = @(
            @{
                Id = "archive3-1"
                Name = "Archive 3-1"
                Description = "Première archive de l'index 3"
                CreatedAt = [DateTime]::Now.AddDays(-10).ToString("o")
                ModifiedAt = [DateTime]::Now.AddDays(-5).ToString("o")
                ArchivedAt = [DateTime]::Now.AddDays(-1).ToString("o")
                ArchivePath = "Archive3\archive3.dat"
                Type = "Video"
                Category = "Production"
                Tags = @("production", "video")
                Status = "Active"
                Version = "1.0"
                Author = "Pierre Durand"
            },
            @{
                Id = "archive3-2"
                Name = "Archive 3-2"
                Description = "Deuxième archive de l'index 3"
                CreatedAt = [DateTime]::Now.AddDays(-8).ToString("o")
                ModifiedAt = [DateTime]::Now.AddDays(-6).ToString("o")
                ArchivedAt = [DateTime]::Now.AddDays(-4).ToString("o")
                ArchivePath = "Archive3\archive3.dat"
                Type = "Audio"
                Category = "Test"
                Tags = @("test", "audio")
                Status = "Inactive"
                Version = "1.0"
                Author = "Sophie Lefebvre"
            },
            @{
                Id = "archive3-3"
                Name = "Archive 3-3"
                Description = "Troisième archive de l'index 3"
                CreatedAt = [DateTime]::Now.AddDays(-5).ToString("o")
                ModifiedAt = [DateTime]::Now.AddDays(-3).ToString("o")
                ArchivedAt = [DateTime]::Now.AddDays(-1).ToString("o")
                ArchivePath = "Archive3\archive3.dat"
                Type = "Document"
                Category = "Production"
                Tags = @("production", "document")
                Status = "Active"
                Version = "3.0"
                Author = "Jean Dupont"
            }
        )
    }
    
    $index1 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive1Path -ChildPath "index.index.json") -Force
    $index2 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive2Path -ChildPath "index.index.json") -Force
    $index3 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive3Path -ChildPath "index.index.json") -Force
    
    Write-Host "Données de test créées dans: $TestPath"
    
    # Retourner les chemins créés
    return [PSCustomObject]@{
        TestPath = $TestPath
        Archive1Path = $archive1Path
        Archive2Path = $archive2Path
        Archive3Path = $archive3Path
        Archive1File = $archive1File
        Archive2File = $archive2File
        Archive3File = $archive3File
    }
}

# Fonction pour tester la récupération des points de restauration
function Test-GetRestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    Write-Host "Test de la récupération des points de restauration..." -ForegroundColor Cyan
    
    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $TestPath
    Write-Host "Nombre total de points de restauration: $($allPoints.Count)" -ForegroundColor White
    
    # Récupérer les points de restauration par type
    $documentPoints = Get-RestorePoints -ArchivePath $TestPath -Type "Document"
    Write-Host "Nombre de points de restauration de type Document: $($documentPoints.Count)" -ForegroundColor White
    
    # Récupérer les points de restauration par catégorie
    $productionPoints = Get-RestorePoints -ArchivePath $TestPath -Category "Production"
    Write-Host "Nombre de points de restauration de catégorie Production: $($productionPoints.Count)" -ForegroundColor White
    
    # Récupérer les points de restauration par tag
    $importantPoints = Get-RestorePoints -ArchivePath $TestPath -Tags @("important") -TagMatchMode "Any"
    Write-Host "Nombre de points de restauration avec le tag 'important': $($importantPoints.Count)" -ForegroundColor White
    
    # Récupérer les points de restauration par date
    $recentPoints = Get-RestorePoints -ArchivePath $TestPath -StartDate ([DateTime]::Now.AddDays(-15))
    Write-Host "Nombre de points de restauration des 15 derniers jours: $($recentPoints.Count)" -ForegroundColor White
    
    Write-Host "Test de la récupération des points de restauration terminé." -ForegroundColor Green
}

# Fonction pour tester l'affichage des points de restauration
function Test-ShowRestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    Write-Host "Test de l'affichage des points de restauration..." -ForegroundColor Cyan
    
    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $TestPath
    
    # Afficher la liste paginée des points de restauration
    $paginationInfo = Show-RestorePointsList -RestorePoints $allPoints -PageSize 2
    
    # Afficher les détails d'un point de restauration
    if ($allPoints.Count -gt 0) {
        Show-RestorePointDetails -RestorePoint $allPoints[0]
    }
    
    Write-Host "Test de l'affichage des points de restauration terminé." -ForegroundColor Green
}

# Fonction pour tester les filtres
function Test-Filters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    Write-Host "Test des filtres..." -ForegroundColor Cyan
    
    # Récupérer les types disponibles
    $types = Get-AvailableTypes -ArchivePath $TestPath -IncludeCount
    Write-Host "Types disponibles:" -ForegroundColor White
    foreach ($type in $types) {
        Write-Host "  $($type.Value) ($($type.Count))" -ForegroundColor White
    }
    
    # Récupérer les catégories disponibles
    $categories = Get-AvailableCategories -ArchivePath $TestPath -IncludeCount
    Write-Host "Catégories disponibles:" -ForegroundColor White
    foreach ($category in $categories) {
        Write-Host "  $($category.Value) ($($category.Count))" -ForegroundColor White
    }
    
    # Récupérer les tags disponibles
    $tags = Get-AvailableTags -ArchivePath $TestPath -IncludeCount
    Write-Host "Tags disponibles:" -ForegroundColor White
    foreach ($tag in $tags) {
        Write-Host "  $($tag.Value) ($($tag.Count))" -ForegroundColor White
    }
    
    Write-Host "Test des filtres terminé." -ForegroundColor Green
}

# Fonction principale de test
function Test-RestoreUI {
    [CmdletBinding()]
    param ()
    
    # Créer les données de test
    $testPath = Join-Path -Path $env:TEMP -ChildPath "RestoreUITest"
    $testData = New-TestData -TestPath $testPath
    
    # Exécuter les tests
    Test-GetRestorePoints -TestPath $testPath
    Test-ShowRestorePoints -TestPath $testPath
    Test-Filters -TestPath $testPath
    
    # Nettoyer les données de test
    Remove-Item -Path $testPath -Recurse -Force
    
    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Exécuter les tests
Test-RestoreUI
