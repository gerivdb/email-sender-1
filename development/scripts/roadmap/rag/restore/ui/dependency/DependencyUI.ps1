# DependencyUI.ps1
# Interface utilisateur pour la visualisation des dépendances
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path $scriptPath -ChildPath "DependencyViewer.ps1"
$restoreViewerPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "RestorePointsViewer.ps1"

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier DependencyViewer.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $restoreViewerPath) {
    . $restoreViewerPath
} else {
    Write-Error "Le fichier RestorePointsViewer.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher le menu principal de visualisation des dépendances
function Show-DependencyMainMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    $exit = $false

    while (-not $exit) {
        Clear-Host

        Write-Host "=== MENU DE VISUALISATION DES DÉPENDANCES ===" -ForegroundColor Cyan
        Write-Host "1. Sélectionner un point de restauration" -ForegroundColor White
        Write-Host "2. Visualiser les dépendances par ID" -ForegroundColor White
        Write-Host "3. Visualiser les dépendances par type" -ForegroundColor White
        Write-Host "4. Visualiser les dépendances par date" -ForegroundColor White
        Write-Host "5. Visualiser les dépendances entre deux points" -ForegroundColor White
        Write-Host "6. Générer un graphe global des dépendances" -ForegroundColor White
        Write-Host "Q. Quitter" -ForegroundColor White
        Write-Host "=============================================" -ForegroundColor Cyan

        $choice = Read-Host "Votre choix"

        switch ($choice) {
            "1" {
                Show-SelectPointMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "2" {
                Show-DependencyByIdMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "3" {
                Show-DependencyByTypeMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "4" {
                Show-DependencyByDateMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "5" {
                Show-DependencyBetweenPointsMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "6" {
                Show-GlobalDependencyGraphMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "Q" {
                $exit = $true
            }
            "q" {
                $exit = $true
            }
            default {
                Write-Host "Choix invalide. Veuillez réessayer." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Fonction pour afficher le menu de sélection d'un point de restauration
function Show-SelectPointMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    Clear-Host

    Write-Host "=== SÉLECTION D'UN POINT DE RESTAURATION ===" -ForegroundColor Cyan

    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache:$UseCache

    if ($null -eq $allPoints -or $allPoints.Count -eq 0) {
        Write-Host "Aucun point de restauration trouvé." -ForegroundColor Yellow
        Read-Host "Appuyez sur Entrée pour continuer"
        return
    }

    # Afficher la liste des points de restauration
    $currentPage = 1
    $pageSize = 10
    $totalPages = [Math]::Ceiling($allPoints.Count / $pageSize)

    $exit = $false

    while (-not $exit) {
        Clear-Host

        Write-Host "=== SÉLECTION D'UN POINT DE RESTAURATION ===" -ForegroundColor Cyan
        Write-Host "Page: $currentPage/$totalPages" -ForegroundColor Yellow

        # Calculer les indices de début et de fin pour la page courante
        $startIndex = ($currentPage - 1) * $pageSize
        $endIndex = [Math]::Min($startIndex + $pageSize - 1, $allPoints.Count - 1)

        # Afficher les points de restauration pour la page courante
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            $point = $allPoints[$i]

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
            Write-Host "$($i - $startIndex + 1). " -NoNewline
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

        # Afficher les options de navigation
        Write-Host "`nOptions:" -ForegroundColor Cyan
        if ($currentPage -gt 1) {
            Write-Host "P: Page précédente" -ForegroundColor White
        }
        if ($currentPage -lt $totalPages) {
            Write-Host "N: Page suivante" -ForegroundColor White
        }
        Write-Host "G: Aller à la page..." -ForegroundColor White
        Write-Host "F: Filtrer les résultats" -ForegroundColor White
        Write-Host "Q: Quitter" -ForegroundColor White

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
                    $totalPages = [Math]::Ceiling($allPoints.Count / $pageSize)
                    $currentPage = 1
                }
            }
            "Q" {
                $exit = $true
            }
            default {
                # Vérifier si l'entrée est un nombre
                if ($choice -match '^\d+$') {
                    $pointNumber = [int]$choice
                    if ($pointNumber -ge 1 -and $pointNumber -le ($endIndex - $startIndex + 1)) {
                        $selectedPoint = $allPoints[$startIndex + $pointNumber - 1]
                        Show-DependencyVisualizationMenu -RestorePoint $selectedPoint -ArchivePath $ArchivePath -UseCache:$UseCache
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
}

# Fonction pour afficher le menu de visualisation des dépendances par ID
function Show-DependencyByIdMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    Clear-Host

    Write-Host "=== VISUALISATION DES DÉPENDANCES PAR ID ===" -ForegroundColor Cyan

    # Demander l'ID du point de restauration
    $pointId = Read-Host "Entrez l'ID du point de restauration"

    if ([string]::IsNullOrWhiteSpace($pointId)) {
        Write-Host "L'ID ne peut pas être vide." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Récupérer le point de restauration
    $allPoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache:$UseCache
    $point = $allPoints | Where-Object { $_.Id -eq $pointId } | Select-Object -First 1

    if ($null -eq $point) {
        Write-Host "Aucun point trouvé avec l'ID: $pointId" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Afficher le menu de visualisation des dépendances
    Show-DependencyVisualizationMenu -RestorePoint $point -ArchivePath $ArchivePath -UseCache:$UseCache
}

# Fonction pour afficher le menu de visualisation des dépendances par type
function Show-DependencyByTypeMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    Clear-Host

    Write-Host "=== VISUALISATION DES DÉPENDANCES PAR TYPE ===" -ForegroundColor Cyan

    # Récupérer les types disponibles
    $types = Get-AvailableTypes -ArchivePath $ArchivePath -IncludeCount -UseCache:$UseCache

    if ($null -eq $types -or $types.Count -eq 0) {
        Write-Host "Aucun type disponible." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Afficher les types disponibles
    Write-Host "Types disponibles:" -ForegroundColor White
    for ($i = 0; $i -lt $types.Count; $i++) {
        Write-Host "  $($i + 1). $($types[$i].Value) ($($types[$i].Count))" -ForegroundColor White
    }

    # Demander le type à visualiser
    $typeIndex = Read-Host "Entrez le numéro du type"

    if (-not ($typeIndex -match '^\d+$') -or [int]$typeIndex -lt 1 -or [int]$typeIndex -gt $types.Count) {
        Write-Host "Numéro de type invalide: $typeIndex" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $selectedType = $types[[int]$typeIndex - 1].Value

    # Récupérer les points de restauration du type sélectionné
    $points = Get-RestorePoints -ArchivePath $ArchivePath -Type $selectedType -UseCache:$UseCache

    if ($null -eq $points -or $points.Count -eq 0) {
        Write-Host "Aucun point trouvé pour le type: $selectedType" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Afficher les points disponibles
    Clear-Host
    Write-Host "=== POINTS DE RESTAURATION DE TYPE $selectedType ===" -ForegroundColor Cyan

    for ($i = 0; $i -lt $points.Count; $i++) {
        $point = $points[$i]
        Write-Host "  $($i + 1). $($point.Name)" -ForegroundColor White

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

    # Demander le point à visualiser
    $pointIndex = Read-Host "Entrez le numéro du point à visualiser"

    if (-not ($pointIndex -match '^\d+$') -or [int]$pointIndex -lt 1 -or [int]$pointIndex -gt $points.Count) {
        Write-Host "Numéro de point invalide: $pointIndex" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $selectedPoint = $points[[int]$pointIndex - 1]

    # Afficher le menu de visualisation des dépendances
    Show-DependencyVisualizationMenu -RestorePoint $selectedPoint -ArchivePath $ArchivePath -UseCache:$UseCache
}

# Fonction pour afficher le menu de visualisation des dépendances par date
function Show-DependencyByDateMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    Clear-Host

    Write-Host "=== VISUALISATION DES DÉPENDANCES PAR DATE ===" -ForegroundColor Cyan

    # Demander la date
    $dateStr = Read-Host "Entrez la date (YYYY-MM-DD)"

    # Valider et convertir la date
    try {
        $date = [DateTime]::Parse($dateStr)
    } catch {
        Write-Host "Format de date invalide: $dateStr" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Récupérer les points de restauration pour la date
    $points = Get-RestorePoints -ArchivePath $ArchivePath -StartDate $date -EndDate $date.AddDays(1) -UseCache:$UseCache

    if ($null -eq $points -or $points.Count -eq 0) {
        Write-Host "Aucun point trouvé pour la date: $dateStr" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Afficher les points disponibles
    Clear-Host
    Write-Host "=== POINTS DE RESTAURATION DU $($date.ToString('yyyy-MM-dd')) ===" -ForegroundColor Cyan

    for ($i = 0; $i -lt $points.Count; $i++) {
        $point = $points[$i]
        Write-Host "  $($i + 1). $($point.Name)" -ForegroundColor White

        # Afficher le type si disponible
        if ($point.PSObject.Properties.Match("Type").Count -and $null -ne $point.Type) {
            Write-Host "     Type: $($point.Type)" -ForegroundColor DarkGray
        }

        # Afficher l'heure si disponible
        if ($point.PSObject.Properties.Match("CreatedAt").Count -and $null -ne $point.CreatedAt) {
            try {
                $createdDate = [DateTime]::Parse($point.CreatedAt)
                Write-Host "     Heure: $($createdDate.ToString('HH:mm:ss'))" -ForegroundColor DarkGray
            } catch {
                # Ignorer les erreurs de parsing de date
            }
        }
    }

    # Demander le point à visualiser
    $pointIndex = Read-Host "Entrez le numéro du point à visualiser"

    if (-not ($pointIndex -match '^\d+$') -or [int]$pointIndex -lt 1 -or [int]$pointIndex -gt $points.Count) {
        Write-Host "Numéro de point invalide: $pointIndex" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $selectedPoint = $points[[int]$pointIndex - 1]

    # Afficher le menu de visualisation des dépendances
    Show-DependencyVisualizationMenu -RestorePoint $selectedPoint -ArchivePath $ArchivePath -UseCache:$UseCache
}

# Fonction pour afficher le menu de visualisation des dépendances entre deux points
function Show-DependencyBetweenPointsMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    Clear-Host

    Write-Host "=== VISUALISATION DES DÉPENDANCES ENTRE DEUX POINTS ===" -ForegroundColor Cyan

    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache:$UseCache

    if ($null -eq $allPoints -or $allPoints.Count -lt 2) {
        Write-Host "Pas assez de points de restauration pour effectuer une comparaison." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Demander les IDs des points à comparer
    $id1 = Read-Host "Entrez l'ID du premier point"
    $id2 = Read-Host "Entrez l'ID du deuxième point"

    if ([string]::IsNullOrWhiteSpace($id1) -or [string]::IsNullOrWhiteSpace($id2)) {
        Write-Host "Les IDs ne peuvent pas être vides." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Trouver les points correspondant aux IDs
    $point1 = $allPoints | Where-Object { $_.Id -eq $id1 } | Select-Object -First 1
    $point2 = $allPoints | Where-Object { $_.Id -eq $id2 } | Select-Object -First 1

    if ($null -eq $point1) {
        Write-Host "Aucun point trouvé avec l'ID: $id1" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    if ($null -eq $point2) {
        Write-Host "Aucun point trouvé avec l'ID: $id2" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Récupérer les dépendances du premier point
    $dependencies1 = Get-RestorePointDependencies -RestorePoint $point1 -ArchivePath $ArchivePath -UseCache:$UseCache -Recursive -MaxDepth 3

    # Vérifier s'il y a des dépendances entre les deux points
    $directDependencies = $dependencies1 | Where-Object { $_.TargetId -eq $point2.Id }

    if ($directDependencies.Count -gt 0) {
        Write-Host "`nDépendances directes trouvées entre les points:" -ForegroundColor Green

        foreach ($dependency in $directDependencies) {
            Write-Host "  Type: $($dependency.Type)" -ForegroundColor White
            Write-Host "  Force: $([Math]::Round($dependency.Strength * 100))%" -ForegroundColor White
        }
    } else {
        Write-Host "`nAucune dépendance directe trouvée entre les points." -ForegroundColor Yellow

        # Chercher des dépendances indirectes
        $indirectDependencies = $dependencies1 | Where-Object { $_.TargetId -ne $point2.Id }
        $pathFound = $false

        foreach ($dependency in $indirectDependencies) {
            $subDependencies = Get-RestorePointDependencies -RestorePoint $dependency.Target -ArchivePath $ArchivePath -UseCache:$UseCache
            $connection = $subDependencies | Where-Object { $_.TargetId -eq $point2.Id }

            if ($connection.Count -gt 0) {
                $pathFound = $true
                Write-Host "`nDépendance indirecte trouvée via $($dependency.Target.Name):" -ForegroundColor Green
                Write-Host "  Chemin: $($point1.Name) -> $($dependency.Target.Name) -> $($point2.Name)" -ForegroundColor White
                break
            }
        }

        if (-not $pathFound) {
            Write-Host "`nAucune dépendance indirecte trouvée entre les points." -ForegroundColor Yellow
        }
    }

    # Proposer de visualiser le graphe des dépendances
    Write-Host "`nVoulez-vous visualiser le graphe des dépendances entre ces points? (O/N)" -ForegroundColor Cyan
    $choice = Read-Host

    if ($choice -eq "O" -or $choice -eq "o") {
        # Créer un graphe combiné des dépendances
        $dependencies1 = Get-RestorePointDependencies -RestorePoint $point1 -ArchivePath $ArchivePath -UseCache:$UseCache -Recursive -MaxDepth 2
        $dependencies2 = Get-RestorePointDependencies -RestorePoint $point2 -ArchivePath $ArchivePath -UseCache:$UseCache -Recursive -MaxDepth 2

        $combinedDependencies = $dependencies1 + $dependencies2

        # Créer et afficher le graphe
        $graph = New-DependencyGraph -Dependencies $combinedDependencies -Layout "Hierarchical" -IncludeStrength -GroupByType
        $dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\dependency_graph.dot"

        # Générer l'image du graphe
        $imageFile = "$env:TEMP\dependency_graph.png"
        & dot -Tpng -o $imageFile $dotFile

        if (Test-Path -Path $imageFile) {
            Write-Host "`nGraphe généré avec succès." -ForegroundColor Green
            Write-Host "Fichier image: $imageFile" -ForegroundColor White

            # Ouvrir l'image avec l'application par défaut
            Start-Process $imageFile
        } else {
            Write-Host "`nÉchec de la génération du graphe." -ForegroundColor Red
        }
    }

    Read-Host "Appuyez sur Entrée pour continuer"
}

# Fonction pour afficher le menu de génération d'un graphe global des dépendances
function Show-GlobalDependencyGraphMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    Clear-Host

    Write-Host "=== GÉNÉRATION D'UN GRAPHE GLOBAL DES DÉPENDANCES ===" -ForegroundColor Cyan

    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache:$UseCache

    if ($null -eq $allPoints -or $allPoints.Count -eq 0) {
        Write-Host "Aucun point de restauration trouvé." -ForegroundColor Yellow
        Read-Host "Appuyez sur Entrée pour continuer"
        return
    }

    # Demander le type de graphe à générer
    Write-Host "`nType de graphe à générer:" -ForegroundColor White
    Write-Host "1. Graphe complet (tous les points et toutes les dépendances)" -ForegroundColor White
    Write-Host "2. Graphe filtré par type" -ForegroundColor White
    Write-Host "3. Graphe filtré par date" -ForegroundColor White
    Write-Host "4. Graphe des points les plus connectés" -ForegroundColor White
    Write-Host "Q. Quitter" -ForegroundColor White

    $choice = Read-Host "Votre choix"

    switch ($choice) {
        "1" {
            # Générer un graphe complet
            Write-Host "`nGénération du graphe complet..." -ForegroundColor Yellow

            # Limiter le nombre de points pour éviter un graphe trop complexe
            $maxPoints = 20
            if ($allPoints.Count -gt $maxPoints) {
                Write-Host "`nAttention: Le nombre de points est limité à $maxPoints pour éviter un graphe trop complexe." -ForegroundColor Yellow
                $selectedPoints = $allPoints | Select-Object -First $maxPoints
            } else {
                $selectedPoints = $allPoints
            }

            # Récupérer les dépendances pour chaque point
            $allDependencies = @()
            foreach ($point in $selectedPoints) {
                $dependencies = Get-RestorePointDependencies -RestorePoint $point -ArchivePath $ArchivePath -UseCache:$UseCache
                $allDependencies += $dependencies
            }

            # Créer et afficher le graphe
            $graph = New-DependencyGraph -Dependencies $allDependencies -Layout "Force" -IncludeStrength -GroupByType
            $dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\global_dependency_graph.dot"

            # Générer l'image du graphe
            $imageFile = "$env:TEMP\global_dependency_graph.png"
            & dot -Tpng -o $imageFile $dotFile

            if (Test-Path -Path $imageFile) {
                Write-Host "`nGraphe généré avec succès." -ForegroundColor Green
                Write-Host "Fichier image: $imageFile" -ForegroundColor White

                # Ouvrir l'image avec l'application par défaut
                Start-Process $imageFile
            } else {
                Write-Host "`nÉchec de la génération du graphe." -ForegroundColor Red
            }
        }
        "2" {
            # Générer un graphe filtré par type
            $types = Get-AvailableTypes -ArchivePath $ArchivePath -IncludeCount -UseCache:$UseCache

            if ($null -eq $types -or $types.Count -eq 0) {
                Write-Host "Aucun type disponible." -ForegroundColor Red
                Start-Sleep -Seconds 2
                return
            }

            # Afficher les types disponibles
            Write-Host "`nTypes disponibles:" -ForegroundColor White
            for ($i = 0; $i -lt $types.Count; $i++) {
                Write-Host "  $($i + 1). $($types[$i].Value) ($($types[$i].Count))" -ForegroundColor White
            }

            # Demander le type à visualiser
            $typeIndex = Read-Host "Entrez le numéro du type"

            if (-not ($typeIndex -match '^\d+$') -or [int]$typeIndex -lt 1 -or [int]$typeIndex -gt $types.Count) {
                Write-Host "Numéro de type invalide: $typeIndex" -ForegroundColor Red
                Start-Sleep -Seconds 2
                return
            }

            $selectedType = $types[[int]$typeIndex - 1].Value

            # Récupérer les points de restauration du type sélectionné
            $filteredPoints = $allPoints | Where-Object { $_.Type -eq $selectedType }

            # Récupérer les dépendances pour chaque point
            $allDependencies = @()
            foreach ($point in $filteredPoints) {
                $dependencies = Get-RestorePointDependencies -RestorePoint $point -ArchivePath $ArchivePath -UseCache:$UseCache
                $allDependencies += $dependencies
            }

            # Créer et afficher le graphe
            $graph = New-DependencyGraph -Dependencies $allDependencies -Layout "Hierarchical" -IncludeStrength -GroupByType
            $dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\type_dependency_graph.dot"

            # Générer l'image du graphe
            $imageFile = "$env:TEMP\type_dependency_graph.png"
            & dot -Tpng -o $imageFile $dotFile

            if (Test-Path -Path $imageFile) {
                Write-Host "`nGraphe généré avec succès." -ForegroundColor Green
                Write-Host "Fichier image: $imageFile" -ForegroundColor White

                # Ouvrir l'image avec l'application par défaut
                Start-Process $imageFile
            } else {
                Write-Host "`nÉchec de la génération du graphe." -ForegroundColor Red
            }
        }
        "3" {
            # Générer un graphe filtré par date
            $dateStr = Read-Host "Entrez la date (YYYY-MM-DD)"

            # Valider et convertir la date
            try {
                $date = [DateTime]::Parse($dateStr)
            } catch {
                Write-Host "Format de date invalide: $dateStr" -ForegroundColor Red
                Start-Sleep -Seconds 2
                return
            }

            # Récupérer les points de restauration pour la date
            $filteredPoints = $allPoints | Where-Object {
                try {
                    $pointDate = [DateTime]::Parse($_.CreatedAt).Date
                    $pointDate -eq $date.Date
                } catch {
                    $false
                }
            }

            if ($filteredPoints.Count -eq 0) {
                Write-Host "Aucun point trouvé pour la date: $dateStr" -ForegroundColor Red
                Start-Sleep -Seconds 2
                return
            }

            # Récupérer les dépendances pour chaque point
            $allDependencies = @()
            foreach ($point in $filteredPoints) {
                $dependencies = Get-RestorePointDependencies -RestorePoint $point -ArchivePath $ArchivePath -UseCache:$UseCache
                $allDependencies += $dependencies
            }

            # Créer et afficher le graphe
            $graph = New-DependencyGraph -Dependencies $allDependencies -Layout "Circular" -IncludeStrength -GroupByType
            $dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\date_dependency_graph.dot"

            # Générer l'image du graphe
            $imageFile = "$env:TEMP\date_dependency_graph.png"
            & dot -Tpng -o $imageFile $dotFile

            if (Test-Path -Path $imageFile) {
                Write-Host "`nGraphe généré avec succès." -ForegroundColor Green
                Write-Host "Fichier image: $imageFile" -ForegroundColor White

                # Ouvrir l'image avec l'application par défaut
                Start-Process $imageFile
            } else {
                Write-Host "`nÉchec de la génération du graphe." -ForegroundColor Red
            }
        }
        "4" {
            # Générer un graphe des points les plus connectés
            Write-Host "`nGénération du graphe des points les plus connectés..." -ForegroundColor Yellow

            # Récupérer les dépendances pour chaque point
            $allDependencies = @()
            foreach ($point in $allPoints) {
                $dependencies = Get-RestorePointDependencies -RestorePoint $point -ArchivePath $ArchivePath -UseCache:$UseCache
                $allDependencies += $dependencies
            }

            # Compter le nombre de connexions pour chaque point
            $connectionCounts = @{}
            foreach ($dependency in $allDependencies) {
                if (-not $connectionCounts.ContainsKey($dependency.SourceId)) {
                    $connectionCounts[$dependency.SourceId] = 0
                }
                if (-not $connectionCounts.ContainsKey($dependency.TargetId)) {
                    $connectionCounts[$dependency.TargetId] = 0
                }

                $connectionCounts[$dependency.SourceId]++
                $connectionCounts[$dependency.TargetId]++
            }

            # Trier les points par nombre de connexions
            $sortedPoints = $connectionCounts.GetEnumerator() | Sort-Object -Property Value -Descending

            # Sélectionner les 10 points les plus connectés
            $topPoints = $sortedPoints | Select-Object -First 10

            # Filtrer les dépendances pour inclure uniquement les points les plus connectés
            $filteredDependencies = $allDependencies | Where-Object {
                $topPoints.Name -contains $_.SourceId -or $topPoints.Name -contains $_.TargetId
            }

            # Créer et afficher le graphe
            $graph = New-DependencyGraph -Dependencies $filteredDependencies -Layout "Force" -IncludeStrength -GroupByType
            $dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\top_dependency_graph.dot"

            # Générer l'image du graphe
            $imageFile = "$env:TEMP\top_dependency_graph.png"
            & dot -Tpng -o $imageFile $dotFile

            if (Test-Path -Path $imageFile) {
                Write-Host "`nGraphe généré avec succès." -ForegroundColor Green
                Write-Host "Fichier image: $imageFile" -ForegroundColor White

                # Ouvrir l'image avec l'application par défaut
                Start-Process $imageFile
            } else {
                Write-Host "`nÉchec de la génération du graphe." -ForegroundColor Red
            }
        }
        "Q" {
            return
        }
        "q" {
            return
        }
        default {
            Write-Host "Choix invalide. Veuillez réessayer." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

    Read-Host "Appuyez sur Entrée pour continuer"
}

# Exporter les fonctions
Export-ModuleMember -Function Show-DependencyMainMenu, Show-SelectPointMenu, Show-DependencyByIdMenu, Show-DependencyByTypeMenu, Show-DependencyByDateMenu, Show-DependencyBetweenPointsMenu, Show-GlobalDependencyGraphMenu
