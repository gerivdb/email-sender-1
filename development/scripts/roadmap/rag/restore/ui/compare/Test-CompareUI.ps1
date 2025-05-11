# Test-CompareUI.ps1
# Script de test pour l'interface utilisateur de comparaison
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$comparePath = Join-Path -Path $scriptPath -ChildPath "CompareManager.ps1"
$viewerPath = Join-Path -Path $scriptPath -ChildPath "CompareViewer.ps1"
$uiPath = Join-Path -Path $scriptPath -ChildPath "CompareUI.ps1"

# Importer les modules
if (Test-Path -Path $comparePath) {
    . $comparePath
} else {
    Write-Error "Le fichier CompareManager.ps1 est introuvable."
    exit 1
}

# Définir manuellement les fonctions d'affichage pour le test
function Show-SideBySideComparison {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison,

        [Parameter(Mandatory = $false)]
        [int]$ConsoleWidth = 120,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightDifferences,

        [Parameter(Mandatory = $false)]
        [switch]$ShowOnlyDifferences
    )

    Write-Host "Affichage côte à côte des configurations:" -ForegroundColor Cyan

    # Afficher les noms des points
    $point1 = $Comparison.Point1
    $point2 = $Comparison.Point2

    $name1 = if ($point1.PSObject.Properties.Match("Name").Count) { $point1.Name } else { "Point 1" }
    $name2 = if ($point2.PSObject.Properties.Match("Name").Count) { $point2.Name } else { "Point 2" }

    Write-Host "Point 1: $name1" -ForegroundColor Yellow
    Write-Host "Point 2: $name2" -ForegroundColor Yellow

    # Afficher les propriétés différentes
    Write-Host "`nPropriétés différentes:" -ForegroundColor Magenta

    foreach ($diff in $Comparison.DifferentProperties | Sort-Object -Property Property) {
        $property = $diff.Property
        $value1 = $diff.Value1
        $value2 = $diff.Value2

        Write-Host "  Property: $property" -ForegroundColor White
        Write-Host "    Point 1: $value1" -ForegroundColor DarkGray
        Write-Host "    Point 2: $value2" -ForegroundColor DarkGray
    }
}

function Show-DifferenceHighlighting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison,

        [Parameter(Mandatory = $false)]
        [int]$ConsoleWidth = 120,

        [Parameter(Mandatory = $false)]
        [switch]$ShowOnlyDifferences
    )

    Write-Host "Affichage avec mise en évidence des différences:" -ForegroundColor Cyan

    # Afficher les propriétés différentes
    foreach ($diff in $Comparison.DifferentProperties | Sort-Object -Property Property) {
        $property = $diff.Property
        $value1 = $diff.Value1
        $value2 = $diff.Value2

        Write-Host "  Property: $property" -ForegroundColor White
        Write-Host "    Point 1: " -NoNewline -ForegroundColor Yellow
        Write-Host "$value1" -ForegroundColor Red
        Write-Host "    Point 2: " -NoNewline -ForegroundColor Yellow
        Write-Host "$value2" -ForegroundColor Red
    }
}

function Show-ChangeStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeChart
    )

    Write-Host "Statistiques de changement:" -ForegroundColor Cyan

    # Calculer les statistiques
    $commonCount = $Comparison.CommonProperties.Count
    $differentCount = $Comparison.DifferentProperties.Count
    $uniqueToPoint1Count = $Comparison.UniqueToPoint1.Count
    $uniqueToPoint2Count = $Comparison.UniqueToPoint2.Count
    $totalCount = $commonCount + $differentCount + $uniqueToPoint1Count + $uniqueToPoint2Count

    # Calculer les pourcentages
    $commonPercentage = if ($totalCount -gt 0) { [Math]::Round(($commonCount / $totalCount) * 100, 2) } else { 0 }
    $differentPercentage = if ($totalCount -gt 0) { [Math]::Round(($differentCount / $totalCount) * 100, 2) } else { 0 }

    # Afficher les statistiques
    Write-Host "  Propriétés communes: $commonCount ($commonPercentage%)" -ForegroundColor Green
    Write-Host "  Propriétés différentes: $differentCount ($differentPercentage%)" -ForegroundColor Magenta
    Write-Host "  Propriétés uniques au point 1: $uniqueToPoint1Count" -ForegroundColor Yellow
    Write-Host "  Propriétés uniques au point 2: $uniqueToPoint2Count" -ForegroundColor Yellow
    Write-Host "  Total des propriétés: $totalCount" -ForegroundColor White

    # Afficher un graphique si demandé
    if ($IncludeChart) {
        Write-Host "`nGraphique de répartition:" -ForegroundColor Cyan
        Write-Host "  [" -NoNewline
        Write-Host "=" * [Math]::Round(($commonCount / $totalCount) * 20) -NoNewline -ForegroundColor Green
        Write-Host "=" * [Math]::Round(($differentCount / $totalCount) * 20) -NoNewline -ForegroundColor Magenta
        Write-Host "=" * [Math]::Round(($uniqueToPoint1Count / $totalCount) * 20) -NoNewline -ForegroundColor Yellow
        Write-Host "=" * [Math]::Round(($uniqueToPoint2Count / $totalCount) * 20) -NoNewline -ForegroundColor Cyan
        Write-Host "]" -ForegroundColor White
    }
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

    New-Item -Path $archive1Path -ItemType Directory -Force | Out-Null
    New-Item -Path $archive2Path -ItemType Directory -Force | Out-Null

    # Créer des fichiers d'archive
    $archive1File = Join-Path -Path $archive1Path -ChildPath "archive1.dat"
    $archive2File = Join-Path -Path $archive2Path -ChildPath "archive2.dat"

    "Contenu de l'archive 1" | Set-Content -Path $archive1File -Force
    "Contenu de l'archive 2" | Set-Content -Path $archive2File -Force

    # Créer des fichiers d'index
    $index1 = @{
        Name        = "Index 1"
        Description = "Premier index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-30).ToString("o")
        Archives    = @(
            @{
                Id          = "archive1-1"
                Name        = "Archive 1-1"
                Description = "Première archive de l'index 1"
                CreatedAt   = [DateTime]::Now.AddDays(-30).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-25).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-20).ToString("o")
                ArchivePath = "Archive1\archive1.dat"
                Type        = "Document"
                Category    = "Test"
                Tags        = @("test", "document", "important")
                Status      = "Active"
                Version     = "1.0"
                Author      = "Jean Dupont"
                Size        = 1024
                Checksum    = "abc123"
            },
            @{
                Id          = "archive1-2"
                Name        = "Archive 1-2"
                Description = "Deuxième archive de l'index 1"
                CreatedAt   = [DateTime]::Now.AddDays(-28).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-26).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-24).ToString("o")
                ArchivePath = "Archive1\archive1.dat"
                Type        = "Image"
                Category    = "Test"
                Tags        = @("test", "image")
                Status      = "Archived"
                Version     = "1.1"
                Author      = "Marie Martin"
                Size        = 2048
                Checksum    = "def456"
                Resolution  = "1920x1080"
            }
        )
    }

    $index2 = @{
        Name        = "Index 2"
        Description = "Deuxième index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
        Archives    = @(
            @{
                Id          = "archive2-1"
                Name        = "Archive 2-1"
                Description = "Première archive de l'index 2"
                CreatedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-15).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-10).ToString("o")
                ArchivePath = "Archive2\archive2.dat"
                Type        = "Document"
                Category    = "Production"
                Tags        = @("production", "document", "important")
                Status      = "Active"
                Version     = "2.0"
                Author      = "Jean Dupont"
                Size        = 1536
                Checksum    = "ghi789"
                PageCount   = 42
            }
        )
    }

    $index1 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive1Path -ChildPath "index.index.json") -Force
    $index2 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive2Path -ChildPath "index.index.json") -Force

    Write-Host "Données de test créées dans: $TestPath"

    # Retourner les chemins créés
    return [PSCustomObject]@{
        TestPath     = $TestPath
        Archive1Path = $archive1Path
        Archive2Path = $archive2Path
        Archive1File = $archive1File
        Archive2File = $archive2File
    }
}

# Fonction pour tester la comparaison de points de restauration
function Test-CompareRestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )

    Write-Host "Test de la comparaison de points de restauration..." -ForegroundColor Cyan

    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $TestPath

    if ($null -eq $allPoints -or $allPoints.Count -lt 2) {
        Write-Host "Pas assez de points de restauration pour effectuer une comparaison." -ForegroundColor Red
        return
    }

    # Sélectionner deux points à comparer
    $point1 = $allPoints[0]
    $point2 = $allPoints[1]

    # Effectuer la comparaison
    $comparison = Compare-RestorePoints -Point1 $point1 -Point2 $point2

    # Afficher les résultats de la comparaison
    Write-Host "Résultats de la comparaison:" -ForegroundColor White
    Write-Host "  Propriétés communes: $($comparison.CommonProperties.Count)" -ForegroundColor White
    Write-Host "  Propriétés différentes: $($comparison.DifferentProperties.Count)" -ForegroundColor White
    Write-Host "  Propriétés uniques au point 1: $($comparison.UniqueToPoint1.Count)" -ForegroundColor White
    Write-Host "  Propriétés uniques au point 2: $($comparison.UniqueToPoint2.Count)" -ForegroundColor White

    # Afficher les propriétés différentes
    if ($comparison.DifferentProperties.Count -gt 0) {
        Write-Host "`nPropriétés différentes:" -ForegroundColor Magenta
        foreach ($diff in $comparison.DifferentProperties) {
            Write-Host "  $($diff.Property):" -ForegroundColor White
            Write-Host "    Point 1: $($diff.Value1)" -ForegroundColor DarkGray
            Write-Host "    Point 2: $($diff.Value2)" -ForegroundColor DarkGray
        }
    }

    Write-Host "Test de la comparaison de points de restauration terminé." -ForegroundColor Green

    return $comparison
}

# Fonction pour tester l'affichage de la comparaison
function Test-ComparisonDisplay {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison
    )

    Write-Host "Test de l'affichage de la comparaison..." -ForegroundColor Cyan

    # Vérifier si les fonctions d'affichage sont disponibles
    if (Get-Command -Name "Show-SideBySideComparison" -ErrorAction SilentlyContinue) {
        # Afficher la comparaison côte à côte
        Write-Host "`nAffichage côte à côte:" -ForegroundColor Yellow
        Show-SideBySideComparison -Comparison $Comparison

        # Afficher la comparaison avec mise en évidence des différences
        Write-Host "`nAffichage avec mise en évidence des différences:" -ForegroundColor Yellow
        Show-DifferenceHighlighting -Comparison $Comparison

        # Afficher les statistiques de changement
        Write-Host "`nAffichage des statistiques de changement:" -ForegroundColor Yellow
        Show-ChangeStatistics -Comparison $Comparison -IncludeChart
    } else {
        Write-Host "`nLes fonctions d'affichage ne sont pas disponibles." -ForegroundColor Yellow
        Write-Host "Vérifiez que le fichier CompareViewer.ps1 est correctement importé." -ForegroundColor Yellow

        # Afficher manuellement quelques informations de comparaison
        Write-Host "`nRésumé de la comparaison:" -ForegroundColor Cyan
        Write-Host "  Point 1: $($Comparison.Point1.Name)" -ForegroundColor White
        Write-Host "  Point 2: $($Comparison.Point2.Name)" -ForegroundColor White
        Write-Host "  Propriétés communes: $($Comparison.CommonProperties.Count)" -ForegroundColor White
        Write-Host "  Propriétés différentes: $($Comparison.DifferentProperties.Count)" -ForegroundColor White
    }

    Write-Host "Test de l'affichage de la comparaison terminé." -ForegroundColor Green
}

# Fonction principale de test
function Test-CompareUI {
    [CmdletBinding()]
    param ()

    # Créer les données de test
    $testPath = Join-Path -Path $env:TEMP -ChildPath "CompareUITest"
    $testData = New-TestData -TestPath $testPath

    # Tester la comparaison de points de restauration
    $comparison = Test-CompareRestorePoints -TestPath $testPath

    # Tester l'affichage de la comparaison
    if ($null -ne $comparison) {
        Test-ComparisonDisplay -Comparison $comparison
    }

    # Nettoyer les données de test
    Remove-Item -Path $testPath -Recurse -Force

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Exécuter les tests
Test-CompareUI
