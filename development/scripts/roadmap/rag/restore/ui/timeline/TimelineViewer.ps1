# TimelineViewer.ps1
# Module de visualisation de la timeline des points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerPath = Join-Path -Path $scriptPath -ChildPath "TimelineManager.ps1"

if (Test-Path -Path $managerPath) {
    . $managerPath
} else {
    Write-Error "Le fichier TimelineManager.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher la timeline des points de restauration
function Show-RestorePointsTimeline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSObject[]]$RestorePoints,
        
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Day", "Week", "Month", "Year")]
        [string]$Period = "Day",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Ascending", "Descending")]
        [string]$SortOrder = "Descending",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("List", "Chart", "Calendar")]
        [string]$ViewMode = "List"
    )
    
    # Récupérer les points de restauration si non fournis
    if ($null -eq $RestorePoints -or $RestorePoints.Count -eq 0) {
        $getParams = @{
            ArchivePath = $ArchivePath
            UseCache = $UseCache
            SortOrder = $SortOrder
        }
        
        if ($null -ne $StartDate) {
            $getParams["StartDate"] = $StartDate
        }
        
        if ($null -ne $EndDate) {
            $getParams["EndDate"] = $EndDate
        }
        
        $RestorePoints = Get-RestorePointsTimeline @getParams
    }
    
    # Vérifier si des points ont été trouvés
    if ($null -eq $RestorePoints -or $RestorePoints.Count -eq 0) {
        Write-Host "Aucun point de restauration trouvé." -ForegroundColor Yellow
        return
    }
    
    # Afficher la timeline selon le mode de visualisation
    switch ($ViewMode) {
        "List" {
            Show-TimelineList -RestorePoints $RestorePoints -Period $Period
        }
        "Chart" {
            Show-TimelineChart -RestorePoints $RestorePoints -Period $Period
        }
        "Calendar" {
            Show-TimelineCalendar -RestorePoints $RestorePoints
        }
    }
}

# Fonction pour afficher la timeline sous forme de liste
function Show-TimelineList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$RestorePoints,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Day", "Week", "Month", "Year")]
        [string]$Period = "Day"
    )
    
    # Regrouper les points par période
    $groupedPoints = Group-RestorePointsByPeriod -RestorePoints $RestorePoints -Period $Period
    
    Clear-Host
    
    Write-Host "=== TIMELINE DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    Write-Host "Période: $Period" -ForegroundColor Yellow
    Write-Host "Nombre total de points: $($RestorePoints.Count)" -ForegroundColor Yellow
    
    # Afficher les points regroupés par période
    foreach ($group in $groupedPoints) {
        Write-Host "`n$($group.Period) ($($group.Count) points)" -ForegroundColor Green
        
        $index = 1
        foreach ($point in $group.Points) {
            # Déterminer la couleur en fonction du type
            $color = "White"
            if ($point.PSObject.Properties.Match("Type").Count -and $null -ne $point.Type) {
                switch ($point.Type) {
                    "Document" { $color = "Green" }
                    "Image" { $color = "Cyan" }
                    "Video" { $color = "Magenta" }
                    "Audio" { $color = "Yellow" }
                    default { $color = "White" }
                }
            }
            
            # Afficher les informations de base
            Write-Host "  $index. " -NoNewline
            Write-Host "$($point.Name)" -ForegroundColor $color -NoNewline
            
            # Afficher l'heure si disponible
            if ($point.PSObject.Properties.Match("ParsedDate").Count) {
                Write-Host " ($($point.ParsedDate.ToString('HH:mm')))" -NoNewline
            }
            
            Write-Host ""
            
            # Afficher le type et la catégorie si disponibles
            $typeCategory = ""
            if ($point.PSObject.Properties.Match("Type").Count -and $null -ne $point.Type) {
                $typeCategory += "Type: $($point.Type)"
            }
            if ($point.PSObject.Properties.Match("Category").Count -and $null -ne $point.Category) {
                if ($typeCategory -ne "") {
                    $typeCategory += ", "
                }
                $typeCategory += "Catégorie: $($point.Category)"
            }
            if ($typeCategory -ne "") {
                Write-Host "     $typeCategory" -ForegroundColor DarkGray
            }
            
            $index++
        }
    }
    
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fonction pour afficher la timeline sous forme de graphique
function Show-TimelineChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$RestorePoints,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Day", "Week", "Month", "Year")]
        [string]$Period = "Day"
    )
    
    # Regrouper les points par période
    $groupedPoints = Group-RestorePointsByPeriod -RestorePoints $RestorePoints -Period $Period
    
    # Analyser les tendances
    $trends = Get-RestorePointsTrends -RestorePoints $RestorePoints -Period $Period
    
    Clear-Host
    
    Write-Host "=== GRAPHIQUE DE LA TIMELINE DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    Write-Host "Période: $Period" -ForegroundColor Yellow
    Write-Host "Nombre total de points: $($RestorePoints.Count)" -ForegroundColor Yellow
    
    # Afficher le graphique des points par période
    Write-Host "`nNombre de points par période:" -ForegroundColor Green
    
    # Trouver la valeur maximale pour dimensionner le graphique
    $maxCount = ($groupedPoints | Measure-Object -Property Count -Maximum).Maximum
    $chartWidth = 50
    
    foreach ($group in $groupedPoints) {
        $barWidth = [Math]::Round(($group.Count / $maxCount) * $chartWidth)
        if ($barWidth -lt 1) { $barWidth = 1 }
        
        Write-Host "$($group.Period.PadRight(20)) " -NoNewline -ForegroundColor White
        Write-Host "$("█" * $barWidth) $($group.Count)" -ForegroundColor Cyan
    }
    
    # Afficher la répartition par type
    Write-Host "`nRépartition par type:" -ForegroundColor Green
    
    $allTypes = $trends.AllTypes
    $totalTypes = ($allTypes.Values | Measure-Object -Sum).Sum
    
    foreach ($type in $allTypes.GetEnumerator() | Sort-Object -Property Value -Descending) {
        $percentage = [Math]::Round(($type.Value / $totalTypes) * 100, 1)
        $barWidth = [Math]::Round(($type.Value / $totalTypes) * $chartWidth)
        if ($barWidth -lt 1) { $barWidth = 1 }
        
        Write-Host "$($type.Key.PadRight(15)) " -NoNewline -ForegroundColor White
        Write-Host "$("█" * $barWidth) $($type.Value) ($percentage%)" -ForegroundColor Magenta
    }
    
    # Afficher les catégories les plus fréquentes
    Write-Host "`nCatégories les plus fréquentes:" -ForegroundColor Green
    
    foreach ($category in $trends.TopCategories) {
        $percentage = [Math]::Round(($category.Value / $RestorePoints.Count) * 100, 1)
        $barWidth = [Math]::Round(($category.Value / $RestorePoints.Count) * $chartWidth)
        if ($barWidth -lt 1) { $barWidth = 1 }
        
        Write-Host "$($category.Key.PadRight(15)) " -NoNewline -ForegroundColor White
        Write-Host "$("█" * $barWidth) $($category.Value) ($percentage%)" -ForegroundColor Yellow
    }
    
    # Afficher les tags les plus fréquents
    Write-Host "`nTags les plus fréquents:" -ForegroundColor Green
    
    foreach ($tag in $trends.TopTags) {
        $percentage = [Math]::Round(($tag.Value / $RestorePoints.Count) * 100, 1)
        $barWidth = [Math]::Round(($tag.Value / $RestorePoints.Count) * $chartWidth)
        if ($barWidth -lt 1) { $barWidth = 1 }
        
        Write-Host "$($tag.Key.PadRight(15)) " -NoNewline -ForegroundColor White
        Write-Host "$("█" * $barWidth) $($tag.Value) ($percentage%)" -ForegroundColor Green
    }
    
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fonction pour afficher la timeline sous forme de calendrier
function Show-TimelineCalendar {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$RestorePoints,
        
        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$Month = $null
    )
    
    # Déterminer le mois à afficher
    if ($null -eq $Month) {
        # Utiliser le mois du point le plus récent
        $latestPoint = $RestorePoints | Where-Object { $_.PSObject.Properties.Match("ParsedDate").Count } | Sort-Object -Property ParsedDate -Descending | Select-Object -First 1
        
        if ($null -ne $latestPoint) {
            $Month = $latestPoint.ParsedDate
        } else {
            $Month = Get-Date
        }
    }
    
    # Créer un dictionnaire des points par jour
    $pointsByDay = @{}
    
    foreach ($point in $RestorePoints) {
        if ($point.PSObject.Properties.Match("ParsedDate").Count) {
            $date = $point.ParsedDate
            
            # Vérifier si le point est dans le mois sélectionné
            if ($date.Year -eq $Month.Year -and $date.Month -eq $Month.Month) {
                $day = $date.Day
                
                if (-not $pointsByDay.ContainsKey($day)) {
                    $pointsByDay[$day] = @()
                }
                
                $pointsByDay[$day] += $point
            }
        }
    }
    
    Clear-Host
    
    Write-Host "=== CALENDRIER DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    Write-Host "Mois: $($Month.ToString('MMMM yyyy'))" -ForegroundColor Yellow
    
    # Afficher l'en-tête du calendrier
    Write-Host "`n Lu  Ma  Me  Je  Ve  Sa  Di" -ForegroundColor White
    
    # Déterminer le premier jour du mois
    $firstDay = New-Object DateTime($Month.Year, $Month.Month, 1)
    $dayOfWeek = [int]$firstDay.DayOfWeek
    if ($dayOfWeek -eq 0) { $dayOfWeek = 7 } # Dimanche = 7
    
    # Déterminer le nombre de jours dans le mois
    $daysInMonth = [DateTime]::DaysInMonth($Month.Year, $Month.Month)
    
    # Afficher les espaces pour les jours avant le début du mois
    $line = ""
    for ($i = 1; $i -lt $dayOfWeek; $i++) {
        $line += "    "
    }
    
    # Afficher les jours du mois
    for ($day = 1; $day -le $daysInMonth; $day++) {
        $dayOfWeek = ($dayOfWeek % 7) + 1
        
        # Déterminer la couleur en fonction du nombre de points
        $color = "White"
        if ($pointsByDay.ContainsKey($day)) {
            $count = $pointsByDay[$day].Count
            
            if ($count -ge 10) {
                $color = "Red"
            } elseif ($count -ge 5) {
                $color = "Yellow"
            } elseif ($count -ge 1) {
                $color = "Green"
            }
        }
        
        # Ajouter le jour au calendrier
        $dayStr = $day.ToString().PadLeft(2)
        $line += "$dayStr  "
        
        # Passer à la ligne suivante si c'est dimanche
        if ($dayOfWeek -eq 7) {
            Write-Host $line -ForegroundColor White
            $line = ""
        }
    }
    
    # Afficher la dernière ligne si nécessaire
    if ($line -ne "") {
        Write-Host $line -ForegroundColor White
    }
    
    # Afficher la légende
    Write-Host "`nLégende:" -ForegroundColor White
    Write-Host "  Blanc: Aucun point" -ForegroundColor White
    Write-Host "  Vert: 1-4 points" -ForegroundColor Green
    Write-Host "  Jaune: 5-9 points" -ForegroundColor Yellow
    Write-Host "  Rouge: 10+ points" -ForegroundColor Red
    
    # Afficher les statistiques du mois
    $totalPoints = ($pointsByDay.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    $daysWithPoints = $pointsByDay.Count
    
    Write-Host "`nStatistiques du mois:" -ForegroundColor White
    Write-Host "  Total des points: $totalPoints" -ForegroundColor White
    Write-Host "  Jours avec des points: $daysWithPoints / $daysInMonth" -ForegroundColor White
    
    if ($totalPoints -gt 0) {
        $avgPointsPerDay = [Math]::Round($totalPoints / $daysWithPoints, 1)
        Write-Host "  Moyenne de points par jour actif: $avgPointsPerDay" -ForegroundColor White
    }
    
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Exporter les fonctions
Export-ModuleMember -Function Show-RestorePointsTimeline, Show-TimelineList, Show-TimelineChart, Show-TimelineCalendar
