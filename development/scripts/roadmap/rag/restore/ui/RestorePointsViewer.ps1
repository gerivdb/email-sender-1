# RestorePointsViewer.ps1
# Module de visualisation des points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$archiveSearchPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\search\ArchiveSearch.ps1"
$metadataSearchPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\search\MetadataSearch.ps1"

if (Test-Path -Path $archiveSearchPath) {
    . $archiveSearchPath
} else {
    Write-Error "Le fichier ArchiveSearch.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $metadataSearchPath) {
    . $metadataSearchPath
} else {
    Write-Error "Le fichier MetadataSearch.ps1 est introuvable."
    exit 1
}

# Fonction pour obtenir la liste des points de restauration
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
    
    # Construire les métadonnées pour la recherche
    $metadata = @{}
    
    if (-not [string]::IsNullOrWhiteSpace($Type)) {
        $metadata["Type"] = $Type
    }
    
    if (-not [string]::IsNullOrWhiteSpace($Category)) {
        $metadata["Category"] = $Category
    }
    
    # Rechercher les archives
    $searchParams = @{
        ArchivePath = $ArchivePath
        UseCache = $UseCache
        MaxResults = $MaxResults
    }
    
    if ($null -ne $StartDate) {
        $searchParams["StartDate"] = $StartDate
    }
    
    if ($null -ne $EndDate) {
        $searchParams["EndDate"] = $EndDate
    }
    
    if ($metadata.Count -gt 0) {
        $archives = Find-ArchiveByMetadata -ArchivePath $ArchivePath -Metadata $metadata -UseCache:$UseCache -MaxResults $MaxResults
    } else {
        $archives = Get-ArchivesByDate @searchParams
    }
    
    # Filtrer par tags si spécifié
    if ($Tags -and $Tags.Count -gt 0) {
        $archives = $archives | Where-Object {
            $archive = $_
            
            # Vérifier si l'archive a des tags
            if (-not $archive.PSObject.Properties.Match("Tags").Count -or $null -eq $archive.Tags) {
                return $false
            }
            
            $archiveTags = $archive.Tags
            
            # Convertir en tableau si ce n'est pas déjà le cas
            if ($archiveTags -isnot [System.Array]) {
                $archiveTags = @($archiveTags)
            }
            
            # Appliquer le mode de correspondance
            switch ($TagMatchMode) {
                "Any" {
                    # Au moins un tag doit correspondre
                    foreach ($tag in $Tags) {
                        if ($archiveTags -contains $tag) {
                            return $true
                        }
                    }
                    return $false
                }
                "All" {
                    # Tous les tags doivent correspondre
                    foreach ($tag in $Tags) {
                        if ($archiveTags -notcontains $tag) {
                            return $false
                        }
                    }
                    return $true
                }
                "None" {
                    # Aucun tag ne doit correspondre
                    foreach ($tag in $Tags) {
                        if ($archiveTags -contains $tag) {
                            return $false
                        }
                    }
                    return $true
                }
            }
        }
    }
    
    return $archives
}

# Fonction pour afficher la liste paginée des points de restauration
function Show-RestorePointsList {
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
        [int]$PageSize = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$CurrentPage = 1
    )
    
    # Si aucun point de restauration n'est fourni, les récupérer
    if (-not $RestorePoints -or $RestorePoints.Count -eq 0) {
        $getParams = @{
            ArchivePath = $ArchivePath
            UseCache = $UseCache
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
        
        $RestorePoints = Get-RestorePoints @getParams
    }
    
    # Vérifier s'il y a des points de restauration
    if (-not $RestorePoints -or $RestorePoints.Count -eq 0) {
        Write-Host "Aucun point de restauration trouvé." -ForegroundColor Yellow
        return
    }
    
    # Calculer le nombre total de pages
    $totalPages = [Math]::Ceiling($RestorePoints.Count / $PageSize)
    
    # Vérifier si la page demandée est valide
    if ($CurrentPage -lt 1) {
        $CurrentPage = 1
    } elseif ($CurrentPage -gt $totalPages) {
        $CurrentPage = $totalPages
    }
    
    # Calculer les indices de début et de fin pour la page courante
    $startIndex = ($CurrentPage - 1) * $PageSize
    $endIndex = [Math]::Min($startIndex + $PageSize - 1, $RestorePoints.Count - 1)
    
    # Afficher l'en-tête
    Write-Host "Points de restauration ($($RestorePoints.Count) au total, page $CurrentPage/$totalPages):" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
    
    # Afficher les points de restauration pour la page courante
    for ($i = $startIndex; $i -le $endIndex; $i++) {
        $point = $RestorePoints[$i]
        
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
        Write-Host "$($i + 1). " -NoNewline
        Write-Host "$($point.Name)" -ForegroundColor $color -NoNewline
        
        # Afficher la date si disponible
        if ($point.PSObject.Properties.Match("CreatedAt").Count -and $null -ne $point.CreatedAt) {
            try {
                $date = [DateTime]::Parse($point.CreatedAt)
                Write-Host " ($($date.ToString('yyyy-MM-dd HH:mm')))" -NoNewline
            } catch {
                # Ignorer les erreurs de parsing de date
            }
        }
        
        Write-Host ""
        
        # Afficher la description si disponible
        if ($point.PSObject.Properties.Match("Description").Count -and $null -ne $point.Description) {
            Write-Host "   $($point.Description)" -ForegroundColor DarkGray
        }
        
        # Afficher les tags si disponibles
        if ($point.PSObject.Properties.Match("Tags").Count -and $null -ne $point.Tags) {
            $tags = $point.Tags
            if ($tags -is [System.Array] -and $tags.Count -gt 0) {
                Write-Host "   Tags: " -NoNewline -ForegroundColor DarkGray
                Write-Host "$($tags -join ', ')" -ForegroundColor DarkYellow
            }
        }
        
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
            Write-Host "   $typeCategory" -ForegroundColor DarkGray
        }
        
        # Afficher un séparateur entre les points
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    }
    
    # Afficher les contrôles de pagination
    Write-Host "Page: $CurrentPage/$totalPages" -ForegroundColor Cyan
    
    # Afficher les options de navigation
    $options = @()
    if ($CurrentPage -gt 1) {
        $options += "P: Page précédente"
    }
    if ($CurrentPage -lt $totalPages) {
        $options += "N: Page suivante"
    }
    $options += "G: Aller à la page..."
    $options += "F: Filtrer les résultats"
    $options += "D: Afficher les détails d'un point"
    $options += "Q: Quitter"
    
    Write-Host "Options: $($options -join ' | ')" -ForegroundColor Cyan
    
    # Retourner les informations sur la pagination
    return [PSCustomObject]@{
        RestorePoints = $RestorePoints
        CurrentPage = $CurrentPage
        TotalPages = $totalPages
        PageSize = $PageSize
    }
}

# Fonction pour afficher les détails d'un point de restauration
function Show-RestorePointDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint
    )
    
    # Vérifier si le point de restauration est valide
    if ($null -eq $RestorePoint) {
        Write-Error "Le point de restauration est invalide."
        return
    }
    
    # Afficher l'en-tête
    Write-Host "Détails du point de restauration:" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
    
    # Afficher les informations de base
    Write-Host "Nom: " -NoNewline -ForegroundColor White
    Write-Host "$($RestorePoint.Name)" -ForegroundColor Green
    
    # Afficher l'ID si disponible
    if ($RestorePoint.PSObject.Properties.Match("Id").Count -and $null -ne $RestorePoint.Id) {
        Write-Host "ID: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.Id)" -ForegroundColor Yellow
    }
    
    # Afficher la description si disponible
    if ($RestorePoint.PSObject.Properties.Match("Description").Count -and $null -ne $RestorePoint.Description) {
        Write-Host "Description: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.Description)" -ForegroundColor DarkGray
    }
    
    # Afficher les dates si disponibles
    Write-Host "Dates:" -ForegroundColor White
    if ($RestorePoint.PSObject.Properties.Match("CreatedAt").Count -and $null -ne $RestorePoint.CreatedAt) {
        try {
            $date = [DateTime]::Parse($RestorePoint.CreatedAt)
            Write-Host "  Création: " -NoNewline -ForegroundColor White
            Write-Host "$($date.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor DarkGray
        } catch {
            # Ignorer les erreurs de parsing de date
        }
    }
    if ($RestorePoint.PSObject.Properties.Match("ModifiedAt").Count -and $null -ne $RestorePoint.ModifiedAt) {
        try {
            $date = [DateTime]::Parse($RestorePoint.ModifiedAt)
            Write-Host "  Modification: " -NoNewline -ForegroundColor White
            Write-Host "$($date.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor DarkGray
        } catch {
            # Ignorer les erreurs de parsing de date
        }
    }
    if ($RestorePoint.PSObject.Properties.Match("ArchivedAt").Count -and $null -ne $RestorePoint.ArchivedAt) {
        try {
            $date = [DateTime]::Parse($RestorePoint.ArchivedAt)
            Write-Host "  Archivage: " -NoNewline -ForegroundColor White
            Write-Host "$($date.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor DarkGray
        } catch {
            # Ignorer les erreurs de parsing de date
        }
    }
    
    # Afficher le type et la catégorie si disponibles
    Write-Host "Classification:" -ForegroundColor White
    if ($RestorePoint.PSObject.Properties.Match("Type").Count -and $null -ne $RestorePoint.Type) {
        Write-Host "  Type: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.Type)" -ForegroundColor DarkGray
    }
    if ($RestorePoint.PSObject.Properties.Match("Category").Count -and $null -ne $RestorePoint.Category) {
        Write-Host "  Catégorie: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.Category)" -ForegroundColor DarkGray
    }
    if ($RestorePoint.PSObject.Properties.Match("Status").Count -and $null -ne $RestorePoint.Status) {
        Write-Host "  Statut: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.Status)" -ForegroundColor DarkGray
    }
    
    # Afficher les tags si disponibles
    if ($RestorePoint.PSObject.Properties.Match("Tags").Count -and $null -ne $RestorePoint.Tags) {
        $tags = $RestorePoint.Tags
        if ($tags -is [System.Array] -and $tags.Count -gt 0) {
            Write-Host "Tags: " -NoNewline -ForegroundColor White
            Write-Host "$($tags -join ', ')" -ForegroundColor DarkYellow
        }
    }
    
    # Afficher l'auteur si disponible
    if ($RestorePoint.PSObject.Properties.Match("Author").Count -and $null -ne $RestorePoint.Author) {
        Write-Host "Auteur: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.Author)" -ForegroundColor DarkGray
    }
    
    # Afficher la version si disponible
    if ($RestorePoint.PSObject.Properties.Match("Version").Count -and $null -ne $RestorePoint.Version) {
        Write-Host "Version: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.Version)" -ForegroundColor DarkGray
    }
    
    # Afficher le chemin de l'archive si disponible
    if ($RestorePoint.PSObject.Properties.Match("ArchivePath").Count -and $null -ne $RestorePoint.ArchivePath) {
        Write-Host "Chemin de l'archive: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.ArchivePath)" -ForegroundColor DarkGray
    }
    
    # Afficher le chemin de l'index si disponible
    if ($RestorePoint.PSObject.Properties.Match("IndexPath").Count -and $null -ne $RestorePoint.IndexPath) {
        Write-Host "Chemin de l'index: " -NoNewline -ForegroundColor White
        Write-Host "$($RestorePoint.IndexPath)" -ForegroundColor DarkGray
    }
    
    # Afficher les propriétés supplémentaires
    $standardProps = @("Id", "Name", "Description", "CreatedAt", "ModifiedAt", "ArchivedAt", "Type", "Category", "Status", "Tags", "Author", "Version", "ArchivePath", "IndexPath")
    $additionalProps = $RestorePoint.PSObject.Properties | Where-Object { $standardProps -notcontains $_.Name }
    
    if ($additionalProps.Count -gt 0) {
        Write-Host "Propriétés supplémentaires:" -ForegroundColor White
        foreach ($prop in $additionalProps) {
            if ($null -ne $prop.Value) {
                Write-Host "  $($prop.Name): " -NoNewline -ForegroundColor White
                Write-Host "$($prop.Value)" -ForegroundColor DarkGray
            }
        }
    }
    
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

# Exporter les fonctions
Export-ModuleMember -Function Get-RestorePoints, Show-RestorePointsList, Show-RestorePointDetails
