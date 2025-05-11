# TimelineManager.ps1
# Module de gestion de la timeline des points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "RestorePointsViewer.ps1"

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier RestorePointsViewer.ps1 est introuvable."
    exit 1
}

# Fonction pour obtenir les points de restauration triés par date
function Get-RestorePointsTimeline {
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
        [int]$MaxResults = 100,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Ascending", "Descending")]
        [string]$SortOrder = "Descending"
    )
    
    # Récupérer les points de restauration
    $getParams = @{
        ArchivePath = $ArchivePath
        UseCache = $UseCache
        MaxResults = $MaxResults
    }
    
    if ($null -ne $StartDate) {
        $getParams["StartDate"] = $StartDate
    }
    
    if ($null -ne $EndDate) {
        $getParams["EndDate"] = $EndDate
    }
    
    if (-not [string]::IsNullOrWhiteSpace($Type)) {
        $getParams["Type"] = $Type
    }
    
    if (-not [string]::IsNullOrWhiteSpace($Category)) {
        $getParams["Category"] = $Category
    }
    
    if ($Tags -and $Tags.Count -gt 0) {
        $getParams["Tags"] = $Tags
        $getParams["TagMatchMode"] = $TagMatchMode
    }
    
    $points = Get-RestorePoints @getParams
    
    # Trier les points par date
    $sortedPoints = $points | Where-Object {
        $_.PSObject.Properties.Match("CreatedAt").Count -and $null -ne $_.CreatedAt
    } | ForEach-Object {
        $point = $_
        try {
            $date = [DateTime]::Parse($point.CreatedAt)
            
            # Ajouter la date parsée comme propriété pour faciliter le tri
            $point | Add-Member -NotePropertyName "ParsedDate" -NotePropertyValue $date -Force
            
            return $point
        } catch {
            # Ignorer les points avec des dates invalides
            return $null
        }
    } | Where-Object { $null -ne $_ }
    
    # Trier par date
    if ($SortOrder -eq "Ascending") {
        $sortedPoints = $sortedPoints | Sort-Object -Property ParsedDate
    } else {
        $sortedPoints = $sortedPoints | Sort-Object -Property ParsedDate -Descending
    }
    
    return $sortedPoints
}

# Fonction pour regrouper les points de restauration par période
function Group-RestorePointsByPeriod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$RestorePoints,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Day", "Week", "Month", "Year")]
        [string]$Period = "Day"
    )
    
    # Fonction pour obtenir la clé de période
    function Get-PeriodKey {
        param (
            [Parameter(Mandatory = $true)]
            [DateTime]$Date,
            
            [Parameter(Mandatory = $true)]
            [string]$Period
        )
        
        switch ($Period) {
            "Day" {
                return $Date.ToString("yyyy-MM-dd")
            }
            "Week" {
                # Calculer le début de la semaine (lundi)
                $dayOfWeek = [int]$Date.DayOfWeek
                if ($dayOfWeek -eq 0) { $dayOfWeek = 7 } # Dimanche = 7
                $startOfWeek = $Date.AddDays(1 - $dayOfWeek)
                return $startOfWeek.ToString("yyyy-MM-dd") + " (Semaine)"
            }
            "Month" {
                return $Date.ToString("yyyy-MM") + " (Mois)"
            }
            "Year" {
                return $Date.ToString("yyyy") + " (Année)"
            }
        }
    }
    
    # Regrouper les points par période
    $groupedPoints = @{}
    
    foreach ($point in $RestorePoints) {
        if (-not $point.PSObject.Properties.Match("ParsedDate").Count) {
            continue
        }
        
        $date = $point.ParsedDate
        $key = Get-PeriodKey -Date $date -Period $Period
        
        if (-not $groupedPoints.ContainsKey($key)) {
            $groupedPoints[$key] = @()
        }
        
        $groupedPoints[$key] += $point
    }
    
    # Convertir en tableau de résultats
    $result = @()
    
    foreach ($key in $groupedPoints.Keys | Sort-Object -Descending) {
        $result += [PSCustomObject]@{
            Period = $key
            Points = $groupedPoints[$key]
            Count = $groupedPoints[$key].Count
        }
    }
    
    return $result
}

# Fonction pour analyser les tendances dans la timeline
function Get-RestorePointsTrends {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$RestorePoints,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Day", "Week", "Month", "Year")]
        [string]$Period = "Month",
        
        [Parameter(Mandatory = $false)]
        [int]$TopCategories = 5,
        
        [Parameter(Mandatory = $false)]
        [int]$TopTags = 5
    )
    
    # Regrouper les points par période
    $groupedPoints = Group-RestorePointsByPeriod -RestorePoints $RestorePoints -Period $Period
    
    # Analyser les tendances par type
    $typesByPeriod = @{}
    $allTypes = @{}
    
    foreach ($group in $groupedPoints) {
        $typesByPeriod[$group.Period] = @{}
        
        foreach ($point in $group.Points) {
            if ($point.PSObject.Properties.Match("Type").Count -and $null -ne $point.Type) {
                $type = $point.Type
                
                if (-not $typesByPeriod[$group.Period].ContainsKey($type)) {
                    $typesByPeriod[$group.Period][$type] = 0
                }
                
                $typesByPeriod[$group.Period][$type]++
                
                if (-not $allTypes.ContainsKey($type)) {
                    $allTypes[$type] = 0
                }
                
                $allTypes[$type]++
            }
        }
    }
    
    # Analyser les tendances par catégorie
    $categoriesByPeriod = @{}
    $allCategories = @{}
    
    foreach ($group in $groupedPoints) {
        $categoriesByPeriod[$group.Period] = @{}
        
        foreach ($point in $group.Points) {
            if ($point.PSObject.Properties.Match("Category").Count -and $null -ne $point.Category) {
                $category = $point.Category
                
                if (-not $categoriesByPeriod[$group.Period].ContainsKey($category)) {
                    $categoriesByPeriod[$group.Period][$category] = 0
                }
                
                $categoriesByPeriod[$group.Period][$category]++
                
                if (-not $allCategories.ContainsKey($category)) {
                    $allCategories[$category] = 0
                }
                
                $allCategories[$category]++
            }
        }
    }
    
    # Analyser les tendances par tag
    $tagsByPeriod = @{}
    $allTags = @{}
    
    foreach ($group in $groupedPoints) {
        $tagsByPeriod[$group.Period] = @{}
        
        foreach ($point in $group.Points) {
            if ($point.PSObject.Properties.Match("Tags").Count -and $null -ne $point.Tags) {
                $tags = $point.Tags
                
                # Convertir en tableau si ce n'est pas déjà le cas
                if ($tags -isnot [System.Array]) {
                    $tags = @($tags)
                }
                
                foreach ($tag in $tags) {
                    if (-not $tagsByPeriod[$group.Period].ContainsKey($tag)) {
                        $tagsByPeriod[$group.Period][$tag] = 0
                    }
                    
                    $tagsByPeriod[$group.Period][$tag]++
                    
                    if (-not $allTags.ContainsKey($tag)) {
                        $allTags[$tag] = 0
                    }
                    
                    $allTags[$tag]++
                }
            }
        }
    }
    
    # Obtenir les catégories les plus fréquentes
    $topCategoriesList = $allCategories.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $TopCategories
    
    # Obtenir les tags les plus fréquents
    $topTagsList = $allTags.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $TopTags
    
    # Créer l'objet de résultat
    $trends = [PSCustomObject]@{
        Periods = $groupedPoints
        TypesByPeriod = $typesByPeriod
        CategoriesByPeriod = $categoriesByPeriod
        TagsByPeriod = $tagsByPeriod
        AllTypes = $allTypes
        AllCategories = $allCategories
        AllTags = $allTags
        TopCategories = $topCategoriesList
        TopTags = $topTagsList
    }
    
    return $trends
}

# Exporter les fonctions
Export-ModuleMember -Function Get-RestorePointsTimeline, Group-RestorePointsByPeriod, Get-RestorePointsTrends
