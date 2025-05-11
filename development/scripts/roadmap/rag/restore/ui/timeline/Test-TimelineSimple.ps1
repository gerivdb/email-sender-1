# Test-TimelineSimple.ps1
# Script de test simplifié pour la timeline
# Version: 1.0
# Date: 2025-05-15

Write-Host "=== TEST SIMPLIFIÉ DE LA TIMELINE ===" -ForegroundColor Cyan

# Fonction pour créer des points de restauration de test
function New-TestRestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Count = 30
    )
    
    $now = Get-Date
    $points = @()
    
    for ($i = 0; $i -lt $Count; $i++) {
        $date = $now.AddDays(-$i)
        
        $point = [PSCustomObject]@{
            Id = "point-$i"
            Name = "Point de restauration $i"
            Description = "Point de restauration de test $i"
            CreatedAt = $date.ToString("o")
            ParsedDate = $date
            Type = @("Document", "Image", "Video", "Audio")[$i % 4]
            Category = @("Test", "Production", "Development", "Archive")[$i % 4]
            Tags = @("important", "test", "backup")
            Status = "Active"
            Version = "1.0"
            Author = "Test User"
            Size = 1024 + $i * 100
            Checksum = "abc123"
        }
        
        $points += $point
    }
    
    return $points
}

# Fonction pour tester le regroupement par période
function Test-GroupByPeriod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Points
    )
    
    Write-Host "`nTest du regroupement par période..." -ForegroundColor Cyan
    
    # Regrouper par jour
    $byDay = @{}
    foreach ($point in $Points) {
        $key = $point.ParsedDate.ToString("yyyy-MM-dd")
        
        if (-not $byDay.ContainsKey($key)) {
            $byDay[$key] = @()
        }
        
        $byDay[$key] += $point
    }
    
    # Afficher les résultats
    Write-Host "Regroupement par jour:" -ForegroundColor White
    foreach ($key in $byDay.Keys | Sort-Object) {
        Write-Host "  $key : $($byDay[$key].Count) points" -ForegroundColor DarkGray
    }
    
    # Regrouper par mois
    $byMonth = @{}
    foreach ($point in $Points) {
        $key = $point.ParsedDate.ToString("yyyy-MM")
        
        if (-not $byMonth.ContainsKey($key)) {
            $byMonth[$key] = @()
        }
        
        $byMonth[$key] += $point
    }
    
    # Afficher les résultats
    Write-Host "`nRegroupement par mois:" -ForegroundColor White
    foreach ($key in $byMonth.Keys | Sort-Object) {
        Write-Host "  $key : $($byMonth[$key].Count) points" -ForegroundColor DarkGray
    }
}

# Fonction pour tester l'analyse des tendances
function Test-Trends {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Points
    )
    
    Write-Host "`nTest de l'analyse des tendances..." -ForegroundColor Cyan
    
    # Analyser les tendances par type
    $byType = @{}
    foreach ($point in $Points) {
        $type = $point.Type
        
        if (-not $byType.ContainsKey($type)) {
            $byType[$type] = 0
        }
        
        $byType[$type]++
    }
    
    # Afficher les résultats
    Write-Host "Répartition par type:" -ForegroundColor White
    foreach ($type in $byType.Keys | Sort-Object) {
        $percentage = [Math]::Round(($byType[$type] / $Points.Count) * 100, 1)
        Write-Host "  $type : $($byType[$type]) points ($percentage%)" -ForegroundColor DarkGray
    }
    
    # Analyser les tendances par catégorie
    $byCategory = @{}
    foreach ($point in $Points) {
        $category = $point.Category
        
        if (-not $byCategory.ContainsKey($category)) {
            $byCategory[$category] = 0
        }
        
        $byCategory[$category]++
    }
    
    # Afficher les résultats
    Write-Host "`nRépartition par catégorie:" -ForegroundColor White
    foreach ($category in $byCategory.Keys | Sort-Object) {
        $percentage = [Math]::Round(($byCategory[$category] / $Points.Count) * 100, 1)
        Write-Host "  $category : $($byCategory[$category]) points ($percentage%)" -ForegroundColor DarkGray
    }
}

# Fonction pour tester l'affichage de la timeline
function Test-TimelineDisplay {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Points
    )
    
    Write-Host "`nTest de l'affichage de la timeline..." -ForegroundColor Cyan
    
    # Afficher la timeline sous forme de liste
    Write-Host "Timeline sous forme de liste:" -ForegroundColor White
    
    $groupedByDay = @{}
    foreach ($point in $Points) {
        $key = $point.ParsedDate.ToString("yyyy-MM-dd")
        
        if (-not $groupedByDay.ContainsKey($key)) {
            $groupedByDay[$key] = @()
        }
        
        $groupedByDay[$key] += $point
    }
    
    foreach ($key in $groupedByDay.Keys | Sort-Object -Descending) {
        Write-Host "  $key ($($groupedByDay[$key].Count) points)" -ForegroundColor Green
        
        $index = 1
        foreach ($point in $groupedByDay[$key]) {
            Write-Host "    $index. $($point.Name) ($($point.Type))" -ForegroundColor DarkGray
            $index++
        }
    }
    
    # Afficher la timeline sous forme de graphique
    Write-Host "`nTimeline sous forme de graphique:" -ForegroundColor White
    
    $chartWidth = 40
    foreach ($key in $groupedByDay.Keys | Sort-Object -Descending) {
        $count = $groupedByDay[$key].Count
        $barWidth = [Math]::Min($count * 2, $chartWidth)
        
        Write-Host "  $key " -NoNewline -ForegroundColor White
        Write-Host "$("█" * $barWidth) $count" -ForegroundColor Cyan
    }
}

# Fonction principale de test
function Test-Timeline {
    [CmdletBinding()]
    param ()
    
    # Créer des points de restauration de test
    $points = New-TestRestorePoints -Count 30
    
    Write-Host "Points de restauration créés: $($points.Count)" -ForegroundColor Green
    
    # Tester le regroupement par période
    Test-GroupByPeriod -Points $points
    
    # Tester l'analyse des tendances
    Test-Trends -Points $points
    
    # Tester l'affichage de la timeline
    Test-TimelineDisplay -Points $points
    
    Write-Host "`nTest terminé avec succès!" -ForegroundColor Green
}

# Exécuter le test
Test-Timeline
