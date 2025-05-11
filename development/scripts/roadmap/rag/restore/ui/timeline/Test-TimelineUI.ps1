# Test-TimelineUI.ps1
# Script de test pour l'interface utilisateur de la timeline
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerPath = Join-Path -Path $scriptPath -ChildPath "TimelineManager.ps1"
$viewerPath = Join-Path -Path $scriptPath -ChildPath "TimelineViewer.ps1"
$uiPath = Join-Path -Path $scriptPath -ChildPath "TimelineUI.ps1"

# Fonction pour simuler Get-RestorePoints
function Get-RestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$StartDate,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$EndDate,

        [Parameter(Mandatory = $false)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Any", "All", "None")]
        [string]$TagMatchMode = "Any",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 100
    )

    # Créer des points de restauration de test
    $now = Get-Date
    $points = @()

    # Générer des points pour les 30 derniers jours
    for ($i = 0; $i -lt 30; $i++) {
        $date = $now.AddDays(-$i)

        # Générer un nombre aléatoire de points pour chaque jour
        $numPoints = Get-Random -Minimum 0 -Maximum 5

        for ($j = 0; $j -lt $numPoints; $j++) {
            $hour = Get-Random -Minimum 8 -Maximum 20
            $minute = Get-Random -Minimum 0 -Maximum 60
            $second = Get-Random -Minimum 0 -Maximum 60

            $pointDate = New-Object DateTime($date.Year, $date.Month, $date.Day, $hour, $minute, $second)

            # Déterminer le type aléatoirement
            $types = @("Document", "Image", "Video", "Audio")
            $typeIndex = Get-Random -Minimum 0 -Maximum $types.Count
            $pointType = $types[$typeIndex]

            # Déterminer la catégorie aléatoirement
            $categories = @("Test", "Production", "Development", "Archive")
            $categoryIndex = Get-Random -Minimum 0 -Maximum $categories.Count
            $pointCategory = $categories[$categoryIndex]

            # Générer des tags aléatoires
            $allTags = @("important", "test", "backup", "document", "image", "video", "audio", "production", "development", "archive")
            $numTags = Get-Random -Minimum 1 -Maximum 4
            $pointTags = @()

            for ($k = 0; $k -lt $numTags; $k++) {
                $tagIndex = Get-Random -Minimum 0 -Maximum $allTags.Count
                $tag = $allTags[$tagIndex]
                if ($pointTags -notcontains $tag) {
                    $pointTags += $tag
                }
            }

            # Créer le point de restauration
            $point = [PSCustomObject]@{
                Id          = "point-$i-$j"
                Name        = "Point de restauration $i-$j"
                Description = "Point de restauration de test $i-$j"
                CreatedAt   = $pointDate.ToString("o")
                Type        = $pointType
                Category    = $pointCategory
                Tags        = $pointTags
                Status      = "Active"
                Version     = "1.0"
                Author      = "Test User"
                Size        = Get-Random -Minimum 1024 -Maximum 10240
                Checksum    = "abc123"
            }

            $points += $point
        }
    }

    # Appliquer les filtres
    if ($null -ne $StartDate) {
        $points = $points | Where-Object {
            try {
                $date = [DateTime]::Parse($_.CreatedAt)
                $date -ge $StartDate
            } catch {
                $false
            }
        }
    }

    if ($null -ne $EndDate) {
        $points = $points | Where-Object {
            try {
                $date = [DateTime]::Parse($_.CreatedAt)
                $date -le $EndDate
            } catch {
                $false
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($Type)) {
        $points = $points | Where-Object { $_.Type -eq $Type }
    }

    if (-not [string]::IsNullOrWhiteSpace($Category)) {
        $points = $points | Where-Object { $_.Category -eq $Category }
    }

    if ($Tags -and $Tags.Count -gt 0) {
        switch ($TagMatchMode) {
            "Any" {
                $points = $points | Where-Object {
                    $pointTags = $_.Tags
                    $found = $false

                    foreach ($tag in $Tags) {
                        if ($pointTags -contains $tag) {
                            $found = $true
                            break
                        }
                    }

                    $found
                }
            }
            "All" {
                $points = $points | Where-Object {
                    $pointTags = $_.Tags
                    $allFound = $true

                    foreach ($tag in $Tags) {
                        if ($pointTags -notcontains $tag) {
                            $allFound = $false
                            break
                        }
                    }

                    $allFound
                }
            }
            "None" {
                $points = $points | Where-Object {
                    $pointTags = $_.Tags
                    $noneFound = $true

                    foreach ($tag in $Tags) {
                        if ($pointTags -contains $tag) {
                            $noneFound = $false
                            break
                        }
                    }

                    $noneFound
                }
            }
        }
    }

    # Limiter le nombre de résultats
    if ($points.Count -gt $MaxResults) {
        $points = $points | Select-Object -First $MaxResults
    }

    return $points
}

# Vérifier si les modules existent
if (Test-Path -Path $managerPath) {
    . $managerPath
} else {
    Write-Error "Le fichier TimelineManager.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier TimelineViewer.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $uiPath) {
    . $uiPath
} else {
    Write-Error "Le fichier TimelineUI.ps1 est introuvable."
    exit 1
}

# Fonction pour tester la timeline
function Test-Timeline {
    [CmdletBinding()]
    param ()

    Write-Host "Test de la timeline des points de restauration..." -ForegroundColor Cyan

    # Récupérer les points de restauration
    $points = Get-RestorePointsTimeline

    # Vérifier si des points ont été trouvés
    if ($null -eq $points -or $points.Count -eq 0) {
        Write-Host "Aucun point de restauration trouvé." -ForegroundColor Red
        return
    }

    Write-Host "Points de restauration récupérés: $($points.Count)" -ForegroundColor Green

    # Tester le regroupement par période
    Write-Host "`nTest du regroupement par période..." -ForegroundColor Cyan

    $groupedByDay = Group-RestorePointsByPeriod -RestorePoints $points -Period "Day"
    Write-Host "Groupes par jour: $($groupedByDay.Count)" -ForegroundColor Green

    $groupedByWeek = Group-RestorePointsByPeriod -RestorePoints $points -Period "Week"
    Write-Host "Groupes par semaine: $($groupedByWeek.Count)" -ForegroundColor Green

    $groupedByMonth = Group-RestorePointsByPeriod -RestorePoints $points -Period "Month"
    Write-Host "Groupes par mois: $($groupedByMonth.Count)" -ForegroundColor Green

    $groupedByYear = Group-RestorePointsByPeriod -RestorePoints $points -Period "Year"
    Write-Host "Groupes par année: $($groupedByYear.Count)" -ForegroundColor Green

    # Tester l'analyse des tendances
    Write-Host "`nTest de l'analyse des tendances..." -ForegroundColor Cyan

    $trends = Get-RestorePointsTrends -RestorePoints $points -Period "Month"

    Write-Host "Types trouvés: $($trends.AllTypes.Count)" -ForegroundColor Green
    Write-Host "Catégories trouvées: $($trends.AllCategories.Count)" -ForegroundColor Green
    Write-Host "Tags trouvés: $($trends.AllTags.Count)" -ForegroundColor Green

    # Tester l'affichage de la timeline
    Write-Host "`nTest de l'affichage de la timeline..." -ForegroundColor Cyan

    Write-Host "Affichage de la timeline sous forme de liste..." -ForegroundColor Yellow
    Show-TimelineList -RestorePoints $points -Period "Day"

    Write-Host "Affichage de la timeline sous forme de graphique..." -ForegroundColor Yellow
    Show-TimelineChart -RestorePoints $points -Period "Month"

    Write-Host "Affichage de la timeline sous forme de calendrier..." -ForegroundColor Yellow
    Show-TimelineCalendar -RestorePoints $points

    Write-Host "Test de la timeline terminé." -ForegroundColor Green
}

# Exécuter le test
Test-Timeline
