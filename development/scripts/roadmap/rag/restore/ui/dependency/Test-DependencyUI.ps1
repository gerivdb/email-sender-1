# Test-DependencyUI.ps1
# Script de test simplifié pour la visualisation des dépendances
# Version: 1.0
# Date: 2025-05-15

Write-Host "=== TEST DE VISUALISATION DES DÉPENDANCES ===" -ForegroundColor Cyan

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
            Id           = "archive1-1"
            Name         = "Archive 1-1"
            Description  = "Première archive de test"
            CreatedAt    = [DateTime]::Now.AddDays(-30).ToString("o")
            ModifiedAt   = [DateTime]::Now.AddDays(-25).ToString("o")
            ArchivedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
            Type         = "Document"
            Category     = "Test"
            Tags         = @("test", "document", "important")
            Status       = "Active"
            Version      = "1.0"
            Author       = "Jean Dupont"
            Size         = 1024
            Checksum     = "abc123"
            References   = @("archive1-2", "archive2-1")
            Dependencies = @("archive1-2")
        },
        [PSCustomObject]@{
            Id           = "archive1-2"
            Name         = "Archive 1-2"
            Description  = "Deuxième archive de test"
            CreatedAt    = [DateTime]::Now.AddDays(-28).ToString("o")
            ModifiedAt   = [DateTime]::Now.AddDays(-26).ToString("o")
            ArchivedAt   = [DateTime]::Now.AddDays(-24).ToString("o")
            Type         = "Image"
            Category     = "Test"
            Tags         = @("test", "image")
            Status       = "Archived"
            Version      = "1.1"
            Author       = "Marie Martin"
            Size         = 2048
            Checksum     = "def456"
            Resolution   = "1920x1080"
            References   = @("archive2-1")
            Dependencies = @("archive2-1")
        },
        [PSCustomObject]@{
            Id           = "archive2-1"
            Name         = "Archive 2-1"
            Description  = "Troisième archive de test"
            CreatedAt    = [DateTime]::Now.AddDays(-20).ToString("o")
            ModifiedAt   = [DateTime]::Now.AddDays(-15).ToString("o")
            ArchivedAt   = [DateTime]::Now.AddDays(-10).ToString("o")
            Type         = "Document"
            Category     = "Production"
            Tags         = @("production", "document", "important")
            Status       = "Active"
            Version      = "2.0"
            Author       = "Jean Dupont"
            Size         = 1536
            Checksum     = "ghi789"
            PageCount    = 42
            References   = @("archive3-1")
            Dependencies = @("archive3-1")
        }
    )

    return $points
}

# Fonction pour créer des données de test
function New-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )

    Write-Host "Création des données de test..." -ForegroundColor Cyan
    Write-Host "Chemin de test: $TestPath" -ForegroundColor DarkGray

    # Créer le répertoire de test s'il n'existe pas
    if (-not (Test-Path -Path $TestPath -PathType Container)) {
        Write-Host "Création du répertoire de test..." -ForegroundColor DarkGray
        New-Item -Path $TestPath -ItemType Directory -Force | Out-Null
    }

    # Créer des sous-répertoires pour les archives
    Write-Host "Création des sous-répertoires..." -ForegroundColor DarkGray
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

    # Créer des fichiers d'index avec des dépendances
    $index1 = @{
        Name        = "Index 1"
        Description = "Premier index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-30).ToString("o")
        Archives    = @(
            @{
                Id           = "archive1-1"
                Name         = "Archive 1-1"
                Description  = "Première archive de l'index 1"
                CreatedAt    = [DateTime]::Now.AddDays(-30).ToString("o")
                ModifiedAt   = [DateTime]::Now.AddDays(-25).ToString("o")
                ArchivedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
                ArchivePath  = "Archive1\archive1.dat"
                Type         = "Document"
                Category     = "Test"
                Tags         = @("test", "document", "important")
                Status       = "Active"
                Version      = "1.0"
                Author       = "Jean Dupont"
                Size         = 1024
                Checksum     = "abc123"
                References   = @("archive1-2", "archive2-1")
                Dependencies = @("archive1-2")
            },
            @{
                Id           = "archive1-2"
                Name         = "Archive 1-2"
                Description  = "Deuxième archive de l'index 1"
                CreatedAt    = [DateTime]::Now.AddDays(-28).ToString("o")
                ModifiedAt   = [DateTime]::Now.AddDays(-26).ToString("o")
                ArchivedAt   = [DateTime]::Now.AddDays(-24).ToString("o")
                ArchivePath  = "Archive1\archive1.dat"
                Type         = "Image"
                Category     = "Test"
                Tags         = @("test", "image")
                Status       = "Archived"
                Version      = "1.1"
                Author       = "Marie Martin"
                Size         = 2048
                Checksum     = "def456"
                Resolution   = "1920x1080"
                References   = @("archive2-1")
                Dependencies = @("archive2-1")
            }
        )
    }

    $index2 = @{
        Name        = "Index 2"
        Description = "Deuxième index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
        Archives    = @(
            @{
                Id           = "archive2-1"
                Name         = "Archive 2-1"
                Description  = "Première archive de l'index 2"
                CreatedAt    = [DateTime]::Now.AddDays(-20).ToString("o")
                ModifiedAt   = [DateTime]::Now.AddDays(-15).ToString("o")
                ArchivedAt   = [DateTime]::Now.AddDays(-10).ToString("o")
                ArchivePath  = "Archive2\archive2.dat"
                Type         = "Document"
                Category     = "Production"
                Tags         = @("production", "document", "important")
                Status       = "Active"
                Version      = "2.0"
                Author       = "Jean Dupont"
                Size         = 1536
                Checksum     = "ghi789"
                PageCount    = 42
                References   = @("archive3-1")
                Dependencies = @("archive3-1")
            }
        )
    }

    $index3 = @{
        Name        = "Index 3"
        Description = "Troisième index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-10).ToString("o")
        Archives    = @(
            @{
                Id           = "archive3-1"
                Name         = "Archive 3-1"
                Description  = "Première archive de l'index 3"
                CreatedAt    = [DateTime]::Now.AddDays(-10).ToString("o")
                ModifiedAt   = [DateTime]::Now.AddDays(-5).ToString("o")
                ArchivedAt   = [DateTime]::Now.AddDays(-1).ToString("o")
                ArchivePath  = "Archive3\archive3.dat"
                Type         = "Video"
                Category     = "Production"
                Tags         = @("production", "video", "important")
                Status       = "Active"
                Version      = "1.0"
                Author       = "Pierre Durand"
                Size         = 10240
                Checksum     = "jkl012"
                Duration     = "00:10:30"
                Resolution   = "1920x1080"
                References   = @("archive1-1")
                Dependencies = @()
            }
        )
    }

    $index1 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive1Path -ChildPath "index.index.json") -Force
    $index2 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive2Path -ChildPath "index.index.json") -Force
    $index3 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive3Path -ChildPath "index.index.json") -Force

    Write-Host "Données de test créées dans: $TestPath"

    # Retourner les chemins créés
    return [PSCustomObject]@{
        TestPath     = $TestPath
        Archive1Path = $archive1Path
        Archive2Path = $archive2Path
        Archive3Path = $archive3Path
        Archive1File = $archive1File
        Archive2File = $archive2File
        Archive3File = $archive3File
    }
}

# Fonction pour tester l'analyse des dépendances
function Test-DependencyAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )

    Write-Host "Test de l'analyse des dépendances..." -ForegroundColor Cyan
    Write-Host "Chemin de test: $TestPath" -ForegroundColor DarkGray

    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $TestPath -PathType Container)) {
        Write-Host "Le répertoire de test n'existe pas: $TestPath" -ForegroundColor Red
        return
    }

    # Vérifier le contenu du répertoire
    $files = Get-ChildItem -Path $TestPath -Recurse
    Write-Host "Contenu du répertoire de test:" -ForegroundColor DarkGray
    foreach ($file in $files) {
        Write-Host "  $($file.FullName)" -ForegroundColor DarkGray
    }

    # Récupérer tous les points de restauration
    Write-Host "Récupération des points de restauration..." -ForegroundColor DarkGray
    try {
        $allPoints = Get-RestorePoints -ArchivePath $TestPath
        Write-Host "Nombre de points trouvés: $($allPoints.Count)" -ForegroundColor DarkGray
    } catch {
        Write-Host "Erreur lors de la récupération des points de restauration: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    if ($null -eq $allPoints -or $allPoints.Count -eq 0) {
        Write-Host "Aucun point de restauration trouvé." -ForegroundColor Red
        return
    }

    # Sélectionner un point pour l'analyse
    $point = $allPoints[0]

    # Analyser les dépendances
    $dependencies = Get-RestorePointDependencies -RestorePoint $point -ArchivePath $TestPath

    # Afficher les résultats
    Write-Host "Dépendances du point $($point.Name) (ID: $($point.Id)):" -ForegroundColor White
    Write-Host "  Nombre de dépendances: $($dependencies.Count)" -ForegroundColor White

    foreach ($dependency in $dependencies) {
        Write-Host "  Dépendance: $($dependency.TargetId)" -ForegroundColor White
        Write-Host "    Type: $($dependency.Type)" -ForegroundColor DarkGray
        Write-Host "    Force: $([Math]::Round($dependency.Strength * 100))%" -ForegroundColor DarkGray
    }

    Write-Host "Test de l'analyse des dépendances terminé." -ForegroundColor Green

    return $dependencies
}

# Fonction pour tester la création de graphes
function Test-DependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Dependencies
    )

    Write-Host "Test de la création de graphes..." -ForegroundColor Cyan

    # Créer un graphe
    $graph = New-DependencyGraph -Dependencies $Dependencies -Layout "Hierarchical" -IncludeStrength -GroupByType

    # Afficher les informations du graphe
    Write-Host "Graphe créé:" -ForegroundColor White
    Write-Host "  Nombre de nœuds: $($graph.Nodes.Count)" -ForegroundColor White
    Write-Host "  Nombre d'arêtes: $($graph.Edges.Count)" -ForegroundColor White
    Write-Host "  Layout: $($graph.Layout)" -ForegroundColor White

    # Exporter le graphe au format DOT
    $dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\test_dependency_graph.dot"

    Write-Host "Graphe exporté au format DOT: $dotFile" -ForegroundColor White

    # Vérifier si Graphviz est installé
    $graphvizInstalled = $false
    try {
        $graphvizVersion = & dot -V 2>&1
        $graphvizInstalled = $true
    } catch {
        $graphvizInstalled = $false
    }

    if ($graphvizInstalled) {
        # Générer l'image du graphe
        $imageFile = "$env:TEMP\test_dependency_graph.png"
        & dot -Tpng -o $imageFile $dotFile

        if (Test-Path -Path $imageFile) {
            Write-Host "Image du graphe générée: $imageFile" -ForegroundColor Green

            # Ouvrir l'image avec l'application par défaut
            Start-Process $imageFile
        } else {
            Write-Host "Échec de la génération de l'image du graphe." -ForegroundColor Red
        }
    } else {
        Write-Host "Graphviz n'est pas installé. Impossible de générer l'image du graphe." -ForegroundColor Yellow
    }

    Write-Host "Test de la création de graphes terminé." -ForegroundColor Green
}

# Fonction principale de test
function Test-DependencyUI {
    [CmdletBinding()]
    param ()

    # Créer les données de test
    $testPath = Join-Path -Path $env:TEMP -ChildPath "DependencyUITest"
    $testData = New-TestData -TestPath $testPath

    # Tester l'analyse des dépendances
    $dependencies = Test-DependencyAnalysis -TestPath $testPath

    # Tester la création de graphes
    if ($null -ne $dependencies -and $dependencies.Count -gt 0) {
        Test-DependencyGraph -Dependencies $dependencies
    }

    # Nettoyer les données de test
    Remove-Item -Path $testPath -Recurse -Force

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Exécuter les tests
Test-DependencyUI
