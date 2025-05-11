# FilterManager.ps1
# Module de gestion des filtres pour les points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path $scriptPath -ChildPath "RestorePointsViewer.ps1"
$metadataSearchPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\search\MetadataSearch.ps1"

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier RestorePointsViewer.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $metadataSearchPath) {
    . $metadataSearchPath
} else {
    Write-Error "Le fichier MetadataSearch.ps1 est introuvable."
    exit 1
}

# Fonction pour obtenir les types disponibles
function Get-AvailableTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCount,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    $metadata = Get-UniqueArchiveMetadata -ArchivePath $ArchivePath -Properties @("Type") -IncludeCount:$IncludeCount -UseCache:$UseCache

    if ($null -ne $metadata -and $metadata.ContainsKey("Type")) {
        return $metadata["Type"]
    }

    return @()
}

# Fonction pour obtenir les catégories disponibles
function Get-AvailableCategories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCount,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    $metadata = Get-UniqueArchiveMetadata -ArchivePath $ArchivePath -Properties @("Category") -IncludeCount:$IncludeCount -UseCache:$UseCache

    if ($null -ne $metadata -and $metadata.ContainsKey("Category")) {
        return $metadata["Category"]
    }

    return @()
}

# Fonction pour obtenir les tags disponibles
function Get-AvailableTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCount,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    # Récupérer tous les points de restauration
    $restorePoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache:$UseCache

    # Extraire tous les tags uniques
    $allTags = @{}

    foreach ($point in $restorePoints) {
        if ($point.PSObject.Properties.Match("Tags").Count -and $null -ne $point.Tags) {
            $tags = $point.Tags

            # Convertir en tableau si ce n'est pas déjà le cas
            if ($tags -isnot [System.Array]) {
                $tags = @($tags)
            }

            foreach ($tag in $tags) {
                if (-not [string]::IsNullOrWhiteSpace($tag)) {
                    if ($allTags.ContainsKey($tag)) {
                        $allTags[$tag]++
                    } else {
                        $allTags[$tag] = 1
                    }
                }
            }
        }
    }

    # Formater les résultats
    if ($IncludeCount) {
        $result = @()

        foreach ($tag in $allTags.Keys | Sort-Object) {
            $result += [PSCustomObject]@{
                Value = $tag
                Count = $allTags[$tag]
            }
        }

        return $result
    } else {
        return $allTags.Keys | Sort-Object
    }

    return @()
}

# Fonction pour obtenir les auteurs disponibles
function Get-AvailableAuthors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCount,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    $metadata = Get-UniqueArchiveMetadata -ArchivePath $ArchivePath -Properties @("Author") -IncludeCount:$IncludeCount -UseCache:$UseCache

    if ($null -ne $metadata -and $metadata.ContainsKey("Author")) {
        return $metadata["Author"]
    }

    return @()
}

# Fonction pour obtenir les statuts disponibles
function Get-AvailableStatuses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCount,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    $metadata = Get-UniqueArchiveMetadata -ArchivePath $ArchivePath -Properties @("Status") -IncludeCount:$IncludeCount -UseCache:$UseCache

    if ($null -ne $metadata -and $metadata.ContainsKey("Status")) {
        return $metadata["Status"]
    }

    return @()
}

# Fonction pour afficher le menu de filtrage avancé
function Show-AdvancedFilterMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    Clear-Host

    Write-Host "=== FILTRAGE AVANCÉ DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan

    # Récupérer les métadonnées disponibles
    Write-Host "Récupération des métadonnées disponibles..." -ForegroundColor White

    $types = Get-AvailableTypes -ArchivePath $ArchivePath -IncludeCount -UseCache
    $categories = Get-AvailableCategories -ArchivePath $ArchivePath -IncludeCount -UseCache
    $tags = Get-AvailableTags -ArchivePath $ArchivePath -IncludeCount -UseCache
    $authors = Get-AvailableAuthors -ArchivePath $ArchivePath -IncludeCount -UseCache
    $statuses = Get-AvailableStatuses -ArchivePath $ArchivePath -IncludeCount -UseCache

    # Afficher les options de filtrage
    Write-Host "`nTypes disponibles:" -ForegroundColor Cyan
    if ($types.Count -gt 0) {
        foreach ($type in $types) {
            Write-Host "  $($type.Value) ($($type.Count))" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucun type disponible." -ForegroundColor DarkGray
    }

    Write-Host "`nCatégories disponibles:" -ForegroundColor Cyan
    if ($categories.Count -gt 0) {
        foreach ($category in $categories) {
            Write-Host "  $($category.Value) ($($category.Count))" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucune catégorie disponible." -ForegroundColor DarkGray
    }

    Write-Host "`nTags disponibles:" -ForegroundColor Cyan
    if ($tags.Count -gt 0) {
        foreach ($tag in $tags) {
            Write-Host "  $($tag.Value) ($($tag.Count))" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucun tag disponible." -ForegroundColor DarkGray
    }

    Write-Host "`nAuteurs disponibles:" -ForegroundColor Cyan
    if ($authors.Count -gt 0) {
        foreach ($author in $authors) {
            Write-Host "  $($author.Value) ($($author.Count))" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucun auteur disponible." -ForegroundColor DarkGray
    }

    Write-Host "`nStatuts disponibles:" -ForegroundColor Cyan
    if ($statuses.Count -gt 0) {
        foreach ($status in $statuses) {
            Write-Host "  $($status.Value) ($($status.Count))" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucun statut disponible." -ForegroundColor DarkGray
    }

    # Demander les critères de filtrage
    Write-Host "`nEntrez les critères de filtrage (laissez vide pour ignorer):" -ForegroundColor Cyan

    $startDateStr = Read-Host "Date de début (YYYY-MM-DD)"
    $endDateStr = Read-Host "Date de fin (YYYY-MM-DD)"
    $type = Read-Host "Type"
    $category = Read-Host "Catégorie"
    $tagsStr = Read-Host "Tags (séparés par des virgules)"
    $tagMatchMode = Read-Host "Mode de correspondance des tags (Any, All, None) [Any]"
    $author = Read-Host "Auteur"
    $status = Read-Host "Statut"

    # Valider et convertir les entrées
    $filterParams = @{}

    # Convertir les dates
    if (-not [string]::IsNullOrWhiteSpace($startDateStr)) {
        try {
            $startDate = [DateTime]::Parse($startDateStr)
            $filterParams["StartDate"] = $startDate
        } catch {
            Write-Host "Format de date de début invalide. Utilisation du format YYYY-MM-DD." -ForegroundColor Red
            Start-Sleep -Seconds 1
            return $null
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($endDateStr)) {
        try {
            $endDate = [DateTime]::Parse($endDateStr)
            $filterParams["EndDate"] = $endDate
        } catch {
            Write-Host "Format de date de fin invalide. Utilisation du format YYYY-MM-DD." -ForegroundColor Red
            Start-Sleep -Seconds 1
            return $null
        }
    }

    # Ajouter les autres critères
    $metadata = @{}

    if (-not [string]::IsNullOrWhiteSpace($type)) {
        $metadata["Type"] = $type
    }

    if (-not [string]::IsNullOrWhiteSpace($category)) {
        $metadata["Category"] = $category
    }

    if (-not [string]::IsNullOrWhiteSpace($author)) {
        $metadata["Author"] = $author
    }

    if (-not [string]::IsNullOrWhiteSpace($status)) {
        $metadata["Status"] = $status
    }

    if ($metadata.Count -gt 0) {
        $filterParams["Metadata"] = $metadata
    }

    # Convertir les tags
    if (-not [string]::IsNullOrWhiteSpace($tagsStr)) {
        $tags = $tagsStr -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        if ($tags.Count -gt 0) {
            $filterParams["Tags"] = $tags
        }
    }

    # Valider le mode de correspondance des tags
    if (-not [string]::IsNullOrWhiteSpace($tagMatchMode)) {
        $validModes = @("Any", "All", "None")
        $normalizedMode = $tagMatchMode.Trim()

        if ($validModes -contains $normalizedMode) {
            $filterParams["TagMatchMode"] = $normalizedMode
        } else {
            Write-Host "Mode de correspondance des tags invalide. Utilisation de 'Any'." -ForegroundColor Yellow
            $filterParams["TagMatchMode"] = "Any"
            Start-Sleep -Seconds 1
        }
    } else {
        $filterParams["TagMatchMode"] = "Any"
    }

    # Ajouter l'utilisation du cache
    $filterParams["UseCache"] = $true

    return $filterParams
}

# Fonction pour sauvegarder un filtre
function Save-Filter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$FilterParams,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    # Créer le répertoire de filtres s'il n'existe pas
    $filtersDir = "$env:USERPROFILE\Documents\RestoreFilters"
    if (-not (Test-Path -Path $filtersDir -PathType Container)) {
        New-Item -Path $filtersDir -ItemType Directory -Force | Out-Null
    }

    # Créer le fichier de filtre
    $filterFile = Join-Path -Path $filtersDir -ChildPath "$Name.json"

    # Sauvegarder le filtre
    $FilterParams | ConvertTo-Json -Depth 10 | Set-Content -Path $filterFile -Force

    return $filterFile
}

# Fonction pour charger un filtre
function Import-Filter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    # Vérifier si le répertoire de filtres existe
    $filtersDir = "$env:USERPROFILE\Documents\RestoreFilters"
    if (-not (Test-Path -Path $filtersDir -PathType Container)) {
        Write-Error "Le répertoire de filtres n'existe pas."
        return $null
    }

    # Vérifier si le fichier de filtre existe
    $filterFile = Join-Path -Path $filtersDir -ChildPath "$Name.json"
    if (-not (Test-Path -Path $filterFile -PathType Leaf)) {
        Write-Error "Le filtre '$Name' n'existe pas."
        return $null
    }

    # Charger le filtre
    $filter = Get-Content -Path $filterFile -Raw | ConvertFrom-Json

    # Convertir en hashtable
    $filterParams = @{}
    foreach ($property in $filter.PSObject.Properties) {
        $filterParams[$property.Name] = $property.Value
    }

    return $filterParams
}

# Fonction pour obtenir la liste des filtres disponibles
function Get-AvailableFilters {
    [CmdletBinding()]
    param ()

    # Vérifier si le répertoire de filtres existe
    $filtersDir = "$env:USERPROFILE\Documents\RestoreFilters"
    if (-not (Test-Path -Path $filtersDir -PathType Container)) {
        return @()
    }

    # Récupérer les fichiers de filtre
    $filterFiles = Get-ChildItem -Path $filtersDir -Filter "*.json" -File

    # Extraire les noms des filtres
    $filters = $filterFiles | ForEach-Object {
        [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    }

    return $filters
}

# Exporter les fonctions
Export-ModuleMember -Function Get-AvailableTypes, Get-AvailableCategories, Get-AvailableTags, Get-AvailableAuthors, Get-AvailableStatuses, Show-AdvancedFilterMenu, Save-Filter, Import-Filter, Get-AvailableFilters
