# CompareManager.ps1
# Module de comparaison entre points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "RestorePointsViewer.ps1"
$filterPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "FilterManager.ps1"

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

# Fonction pour sélectionner des points de restauration à comparer
function Select-RestorePointsToCompare {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxPoints = 2,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowSameType,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache:$UseCache
    
    if ($null -eq $allPoints -or $allPoints.Count -eq 0) {
        Write-Warning "Aucun point de restauration trouvé."
        return $null
    }
    
    # Initialiser la liste des points sélectionnés
    $selectedPoints = @()
    
    # Afficher l'interface de sélection
    $exit = $false
    $currentPage = 1
    $pageSize = 10
    
    while (-not $exit -and $selectedPoints.Count -lt $MaxPoints) {
        Clear-Host
        
        Write-Host "=== SÉLECTION DE POINTS DE RESTAURATION À COMPARER ===" -ForegroundColor Cyan
        Write-Host "Points sélectionnés: $($selectedPoints.Count)/$MaxPoints" -ForegroundColor Yellow
        
        # Afficher les points déjà sélectionnés
        if ($selectedPoints.Count -gt 0) {
            Write-Host "`nPoints sélectionnés:" -ForegroundColor Green
            for ($i = 0; $i -lt $selectedPoints.Count; $i++) {
                $point = $selectedPoints[$i]
                Write-Host "  $($i + 1). $($point.Name)" -ForegroundColor Green
                
                # Afficher le type si disponible
                if ($point.PSObject.Properties.Match("Type").Count -and $null -ne $point.Type) {
                    Write-Host "     Type: $($point.Type)" -ForegroundColor DarkGray
                }
                
                # Afficher la date si disponible
                if ($point.PSObject.Properties.Match("CreatedAt").Count -and $null -ne $point.CreatedAt) {
                    try {
                        $date = [DateTime]::Parse($point.CreatedAt)
                        Write-Host "     Date: $($date.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
                    } catch {
                        # Ignorer les erreurs de parsing de date
                    }
                }
            }
        }
        
        Write-Host "`nSélectionnez un point de restauration à ajouter:" -ForegroundColor White
        
        # Filtrer les points déjà sélectionnés
        $availablePoints = $allPoints | Where-Object {
            $point = $_
            $alreadySelected = $false
            
            foreach ($selectedPoint in $selectedPoints) {
                if ($point.Id -eq $selectedPoint.Id) {
                    $alreadySelected = $true
                    break
                }
            }
            
            # Vérifier si le type est déjà sélectionné (si AllowSameType est désactivé)
            $typeAlreadySelected = $false
            if (-not $AllowSameType -and $point.PSObject.Properties.Match("Type").Count -and $null -ne $point.Type) {
                foreach ($selectedPoint in $selectedPoints) {
                    if ($selectedPoint.PSObject.Properties.Match("Type").Count -and $null -ne $selectedPoint.Type -and 
                        $point.Type -eq $selectedPoint.Type) {
                        $typeAlreadySelected = $true
                        break
                    }
                }
            }
            
            return -not $alreadySelected -and (-not $typeAlreadySelected -or $AllowSameType)
        }
        
        # Calculer le nombre total de pages
        $totalPages = [Math]::Ceiling($availablePoints.Count / $pageSize)
        
        # Vérifier si la page demandée est valide
        if ($currentPage -lt 1) {
            $currentPage = 1
        } elseif ($currentPage -gt $totalPages) {
            $currentPage = $totalPages
        }
        
        # Calculer les indices de début et de fin pour la page courante
        $startIndex = ($currentPage - 1) * $pageSize
        $endIndex = [Math]::Min($startIndex + $pageSize - 1, $availablePoints.Count - 1)
        
        # Afficher les points disponibles pour la page courante
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            $point = $availablePoints[$i]
            
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
        }
        
        # Afficher les contrôles de pagination
        Write-Host "`nPage: $currentPage/$totalPages" -ForegroundColor Cyan
        
        # Afficher les options de navigation
        $options = @()
        if ($currentPage -gt 1) {
            $options += "P: Page précédente"
        }
        if ($currentPage -lt $totalPages) {
            $options += "N: Page suivante"
        }
        $options += "G: Aller à la page..."
        $options += "F: Filtrer les résultats"
        $options += "C: Comparer les points sélectionnés"
        $options += "R: Réinitialiser la sélection"
        $options += "Q: Quitter"
        
        Write-Host "Options: $($options -join ' | ')" -ForegroundColor Cyan
        
        # Demander à l'utilisateur de faire un choix
        $choice = Read-Host "Votre choix"
        
        switch ($choice.ToUpper()) {
            "P" {
                if ($currentPage -gt 1) {
                    $currentPage--
                }
            }
            "N" {
                if ($currentPage -lt $totalPages) {
                    $currentPage++
                }
            }
            "G" {
                $pageNumber = Read-Host "Entrez le numéro de page (1-$totalPages)"
                if ($pageNumber -match '^\d+$' -and [int]$pageNumber -ge 1 -and [int]$pageNumber -le $totalPages) {
                    $currentPage = [int]$pageNumber
                } else {
                    Write-Host "Numéro de page invalide." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
            "F" {
                $filterParams = Show-AdvancedFilterMenu -ArchivePath $ArchivePath
                if ($null -ne $filterParams) {
                    $filterParams["ArchivePath"] = $ArchivePath
                    $allPoints = Get-RestorePoints @filterParams
                    $currentPage = 1
                }
            }
            "C" {
                if ($selectedPoints.Count -gt 0) {
                    return $selectedPoints
                } else {
                    Write-Host "Aucun point sélectionné. Veuillez sélectionner au moins un point." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
            "R" {
                $selectedPoints = @()
            }
            "Q" {
                $exit = $true
            }
            default {
                # Vérifier si l'entrée est un nombre
                if ($choice -match '^\d+$') {
                    $pointNumber = [int]$choice
                    if ($pointNumber -ge 1 -and $pointNumber -le ($endIndex - $startIndex + 1)) {
                        $selectedPoint = $availablePoints[$startIndex + $pointNumber - 1]
                        $selectedPoints += $selectedPoint
                        
                        Write-Host "Point ajouté à la sélection: $($selectedPoint.Name)" -ForegroundColor Green
                        Start-Sleep -Seconds 1
                        
                        # Si le nombre maximum de points est atteint, proposer de comparer
                        if ($selectedPoints.Count -ge $MaxPoints) {
                            Write-Host "Nombre maximum de points atteint. Voulez-vous comparer ces points? (O/N)" -ForegroundColor Yellow
                            $compareNow = Read-Host
                            if ($compareNow -eq "O" -or $compareNow -eq "o") {
                                return $selectedPoints
                            }
                        }
                    } else {
                        Write-Host "Numéro de point invalide." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                } else {
                    Write-Host "Choix invalide. Veuillez réessayer." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    }
    
    # Si l'utilisateur quitte sans sélectionner de points, retourner null
    if ($selectedPoints.Count -eq 0) {
        return $null
    }
    
    return $selectedPoints
}

# Fonction pour comparer deux points de restauration
function Compare-RestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Point1,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Point2,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$StructuralCompare
    )
    
    # Vérifier si les points sont valides
    if ($null -eq $Point1 -or $null -eq $Point2) {
        Write-Error "Les points de restauration sont invalides."
        return $null
    }
    
    # Créer un objet pour stocker les résultats de la comparaison
    $comparison = [PSCustomObject]@{
        Point1 = $Point1
        Point2 = $Point2
        CommonProperties = @()
        DifferentProperties = @()
        UniqueToPoint1 = @()
        UniqueToPoint2 = @()
        ContentDifference = $null
        StructuralDifference = $null
    }
    
    # Comparer les propriétés
    $properties1 = $Point1.PSObject.Properties.Name
    $properties2 = $Point2.PSObject.Properties.Name
    
    # Trouver les propriétés communes
    $commonProperties = $properties1 | Where-Object { $properties2 -contains $_ }
    
    foreach ($property in $commonProperties) {
        $value1 = $Point1.$property
        $value2 = $Point2.$property
        
        # Comparer les valeurs
        if ($null -eq $value1 -and $null -eq $value2) {
            # Les deux valeurs sont null, considérer comme identiques
            $comparison.CommonProperties += $property
        } elseif ($null -eq $value1 -or $null -eq $value2) {
            # Une valeur est null et l'autre non, considérer comme différentes
            $comparison.DifferentProperties += [PSCustomObject]@{
                Property = $property
                Value1 = $value1
                Value2 = $value2
            }
        } elseif ($value1 -is [System.Array] -and $value2 -is [System.Array]) {
            # Comparer les tableaux
            $arrayEqual = $true
            
            if ($value1.Count -ne $value2.Count) {
                $arrayEqual = $false
            } else {
                for ($i = 0; $i -lt $value1.Count; $i++) {
                    if ($value1[$i] -ne $value2[$i]) {
                        $arrayEqual = $false
                        break
                    }
                }
            }
            
            if ($arrayEqual) {
                $comparison.CommonProperties += $property
            } else {
                $comparison.DifferentProperties += [PSCustomObject]@{
                    Property = $property
                    Value1 = $value1
                    Value2 = $value2
                }
            }
        } elseif ($value1 -eq $value2) {
            # Les valeurs sont égales
            $comparison.CommonProperties += $property
        } else {
            # Les valeurs sont différentes
            $comparison.DifferentProperties += [PSCustomObject]@{
                Property = $property
                Value1 = $value1
                Value2 = $value2
            }
        }
    }
    
    # Trouver les propriétés uniques à chaque point
    $comparison.UniqueToPoint1 = $properties1 | Where-Object { $properties2 -notcontains $_ }
    $comparison.UniqueToPoint2 = $properties2 | Where-Object { $properties1 -notcontains $_ }
    
    # Comparer le contenu si demandé
    if ($IncludeContent) {
        # Vérifier si les points ont un chemin d'archive
        if ($Point1.PSObject.Properties.Match("ArchivePath").Count -and $Point2.PSObject.Properties.Match("ArchivePath").Count) {
            # TODO: Implémenter la comparaison de contenu
            $comparison.ContentDifference = "Non implémenté"
        }
    }
    
    # Comparer la structure si demandé
    if ($StructuralCompare) {
        # TODO: Implémenter la comparaison structurelle
        $comparison.StructuralDifference = "Non implémenté"
    }
    
    return $comparison
}

# Exporter les fonctions
Export-ModuleMember -Function Select-RestorePointsToCompare, Compare-RestorePoints
