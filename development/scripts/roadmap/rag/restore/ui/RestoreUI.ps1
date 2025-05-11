# RestoreUI.ps1
# Interface utilisateur pour la restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path $scriptPath -ChildPath "RestorePointsViewer.ps1"
$restorePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\restore\RestoreManager.ps1"

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier RestorePointsViewer.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $restorePath) {
    . $restorePath
} else {
    Write-Error "Le fichier RestoreManager.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher le menu principal
function Show-RestoreMainMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    $exit = $false

    while (-not $exit) {
        Clear-Host

        Write-Host "=== MENU PRINCIPAL DE RESTAURATION ===" -ForegroundColor Cyan
        Write-Host "1. Afficher les points de restauration" -ForegroundColor White
        Write-Host "2. Rechercher des points de restauration" -ForegroundColor White
        Write-Host "3. Restaurer un point spécifique" -ForegroundColor White
        Write-Host "4. Comparer des points de restauration" -ForegroundColor White
        Write-Host "5. Visualiser les dépendances" -ForegroundColor White
        Write-Host "6. Afficher la timeline des points" -ForegroundColor White
        Write-Host "7. Configurer les options" -ForegroundColor White
        Write-Host "Q. Quitter" -ForegroundColor White
        Write-Host "=======================================" -ForegroundColor Cyan

        $choice = Read-Host "Votre choix"

        switch ($choice) {
            "1" {
                Show-RestorePointsMenu -ArchivePath $ArchivePath
            }
            "2" {
                Show-SearchRestorePointsMenu -ArchivePath $ArchivePath
            }
            "3" {
                Show-RestoreSpecificPointMenu -ArchivePath $ArchivePath
            }
            "4" {
                Show-CompareRestorePointsMenu -ArchivePath $ArchivePath
            }
            "5" {
                Show-DependenciesMenu -ArchivePath $ArchivePath
            }
            "6" {
                Show-TimelineMenu -ArchivePath $ArchivePath
            }
            "7" {
                Show-ConfigurationMenu -ArchivePath $ArchivePath
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

# Fonction pour afficher le menu des points de restauration
function Show-RestorePointsMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    $exit = $false
    $currentPage = 1
    $pageSize = 10
    $restorePoints = $null
    $paginationInfo = $null

    while (-not $exit) {
        Clear-Host

        Write-Host "=== POINTS DE RESTAURATION ===" -ForegroundColor Cyan

        # Afficher la liste paginée des points de restauration
        $paginationInfo = Show-RestorePointsList -RestorePoints $restorePoints -ArchivePath $ArchivePath -CurrentPage $currentPage -PageSize $pageSize -UseCache

        if ($null -ne $paginationInfo) {
            $restorePoints = $paginationInfo.RestorePoints
            $currentPage = $paginationInfo.CurrentPage
            $totalPages = $paginationInfo.TotalPages
            $pageSize = $paginationInfo.PageSize
        }

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
                $filterParams = Show-FilterMenu
                if ($null -ne $filterParams) {
                    $filterParams["ArchivePath"] = $ArchivePath
                    $restorePoints = Get-RestorePoints @filterParams
                    $currentPage = 1
                }
            }
            "D" {
                $pointNumber = Read-Host "Entrez le numéro du point à afficher (1-$($restorePoints.Count))"
                if ($pointNumber -match '^\d+$' -and [int]$pointNumber -ge 1 -and [int]$pointNumber -le $restorePoints.Count) {
                    Clear-Host
                    Show-RestorePointDetails -RestorePoint $restorePoints[[int]$pointNumber - 1]
                    Read-Host "Appuyez sur Entrée pour continuer"
                } else {
                    Write-Host "Numéro de point invalide." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
            "Q" {
                $exit = $true
            }
            default {
                # Vérifier si l'entrée est un nombre
                if ($choice -match '^\d+$') {
                    $pointNumber = [int]$choice
                    if ($pointNumber -ge 1 -and $pointNumber -le $restorePoints.Count) {
                        Clear-Host
                        Show-RestorePointDetails -RestorePoint $restorePoints[$pointNumber - 1]
                        Read-Host "Appuyez sur Entrée pour continuer"
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

# Fonction pour afficher le menu de recherche des points de restauration
function Show-SearchRestorePointsMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    Clear-Host

    Write-Host "=== RECHERCHE DE POINTS DE RESTAURATION ===" -ForegroundColor Cyan

    $filterParams = Show-FilterMenu

    if ($null -ne $filterParams) {
        $filterParams["ArchivePath"] = $ArchivePath
        $restorePoints = Get-RestorePoints @filterParams

        if ($null -ne $restorePoints -and $restorePoints.Count -gt 0) {
            Show-RestorePointsMenu -ArchivePath $ArchivePath
        } else {
            Write-Host "Aucun point de restauration trouvé avec les critères spécifiés." -ForegroundColor Yellow
            Read-Host "Appuyez sur Entrée pour continuer"
        }
    }
}

# Fonction pour afficher le menu de filtrage
function Show-FilterMenu {
    [CmdletBinding()]
    param ()

    Clear-Host

    Write-Host "=== FILTRAGE DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    Write-Host "Laissez un champ vide pour ne pas appliquer ce filtre." -ForegroundColor DarkGray

    # Demander les critères de filtrage
    $startDateStr = Read-Host "Date de début (YYYY-MM-DD)"
    $endDateStr = Read-Host "Date de fin (YYYY-MM-DD)"
    $type = Read-Host "Type (ex: Document, Image, Video, Audio)"
    $category = Read-Host "Catégorie"
    $tagsStr = Read-Host "Tags (séparés par des virgules)"
    $tagMatchMode = Read-Host "Mode de correspondance des tags (Any, All, None) [Any]"

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

    # Ajouter le type et la catégorie
    if (-not [string]::IsNullOrWhiteSpace($type)) {
        $filterParams["Type"] = $type
    }

    if (-not [string]::IsNullOrWhiteSpace($category)) {
        $filterParams["Category"] = $category
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

# Fonction pour afficher le menu de restauration d'un point spécifique
function Show-RestoreSpecificPointMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    Clear-Host

    Write-Host "=== RESTAURATION D'UN POINT SPÉCIFIQUE ===" -ForegroundColor Cyan

    # Demander l'ID ou le chemin du point à restaurer
    $idOrPath = Read-Host "Entrez l'ID ou le chemin du point à restaurer"

    if ([string]::IsNullOrWhiteSpace($idOrPath)) {
        Write-Host "ID ou chemin invalide." -ForegroundColor Red
        Start-Sleep -Seconds 1
        return
    }

    # Demander le chemin cible
    $targetPath = Read-Host "Entrez le chemin cible pour la restauration"

    if ([string]::IsNullOrWhiteSpace($targetPath)) {
        Write-Host "Chemin cible invalide." -ForegroundColor Red
        Start-Sleep -Seconds 1
        return
    }

    # Demander la stratégie de résolution des conflits
    Write-Host "Stratégie de résolution des conflits:" -ForegroundColor Cyan
    Write-Host "1. Ignorer (Skip)" -ForegroundColor White
    Write-Host "2. Écraser (Overwrite)" -ForegroundColor White
    Write-Host "3. Renommer (Rename)" -ForegroundColor White

    $conflictChoice = Read-Host "Votre choix [1]"

    $conflictResolution = "Skip"

    switch ($conflictChoice) {
        "2" {
            $conflictResolution = "Overwrite"
        }
        "3" {
            $conflictResolution = "Rename"
        }
        default {
            $conflictResolution = "Skip"
        }
    }

    # Demander confirmation
    Write-Host "Vous êtes sur le point de restaurer le point '$idOrPath' vers '$targetPath' avec la stratégie '$conflictResolution'." -ForegroundColor Yellow
    $confirm = Read-Host "Êtes-vous sûr de vouloir continuer? (O/N)"

    if ($confirm -ne "O" -and $confirm -ne "o") {
        Write-Host "Opération annulée." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }

    # Effectuer la restauration
    try {
        $restoreParams = @{
            IndexPath          = (Get-ChildItem -Path $ArchivePath -Filter "*.index.json" -Recurse -File | Select-Object -First 1).FullName
            TargetPath         = $targetPath
            ConflictResolution = $conflictResolution
            CreateTargetPath   = $true
            Force              = $true
        }

        if ($idOrPath -match '^[a-zA-Z0-9\-_]+$') {
            # Si l'entrée ressemble à un ID
            $restoreParams["Id"] = $idOrPath
        } else {
            # Sinon, considérer comme un chemin
            $restoreParams["ArchivePath"] = $idOrPath
        }

        $result = Restore-ToAlternateLocation @restoreParams

        if ($null -ne $result -and $result.Success) {
            Write-Host "Restauration réussie!" -ForegroundColor Green
            Write-Host "Le point a été restauré vers: $($result.TargetPath)" -ForegroundColor Green
        } else {
            Write-Host "La restauration a échoué." -ForegroundColor Red
            if ($null -ne $result -and $result.Skipped) {
                Write-Host "Le fichier cible existe déjà et a été ignoré selon la stratégie de résolution des conflits." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Erreur lors de la restauration: $($_.Exception.Message)" -ForegroundColor Red
    }

    Read-Host "Appuyez sur Entrée pour continuer"
}

# Fonction pour afficher le menu de comparaison des points de restauration
function Show-CompareRestorePointsMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    # Vérifier si le module de comparaison est disponible
    $comparePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "compare\CompareUI.ps1"

    if (Test-Path -Path $comparePath) {
        # Importer le module de comparaison
        . $comparePath

        # Afficher le menu principal de comparaison
        Show-CompareMainMenu -ArchivePath $ArchivePath
    } else {
        Clear-Host

        Write-Host "=== COMPARAISON DE POINTS DE RESTAURATION ===" -ForegroundColor Cyan
        Write-Host "Le module de comparaison n'est pas disponible." -ForegroundColor Yellow
        Write-Host "Chemin recherché: $comparePath" -ForegroundColor Yellow

        Read-Host "Appuyez sur Entrée pour continuer"
    }
}

# Fonction pour afficher le menu de la timeline
function Show-TimelineMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    # Vérifier si le module de timeline est disponible
    $timelinePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "timeline\TimelineUI.ps1"

    if (Test-Path -Path $timelinePath) {
        # Importer le module de timeline
        . $timelinePath

        # Afficher le menu principal de la timeline
        Show-TimelineMainMenu -ArchivePath $ArchivePath -UseCache
    } else {
        Clear-Host

        Write-Host "=== TIMELINE DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
        Write-Host "Le module de timeline n'est pas disponible." -ForegroundColor Yellow
        Write-Host "Chemin recherché: $timelinePath" -ForegroundColor Yellow

        Read-Host "Appuyez sur Entrée pour continuer"
    }
}

# Fonction pour afficher le menu de visualisation des dépendances
function Show-DependenciesMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    # Vérifier si le module de dépendances est disponible
    $dependencyPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "dependency\DependencyUI.ps1"

    if (Test-Path -Path $dependencyPath) {
        # Importer le module de dépendances
        . $dependencyPath

        # Afficher le menu principal de visualisation des dépendances
        Show-DependencyMainMenu -ArchivePath $ArchivePath -UseCache
    } else {
        Clear-Host

        Write-Host "=== VISUALISATION DES DÉPENDANCES ===" -ForegroundColor Cyan
        Write-Host "Le module de visualisation des dépendances n'est pas disponible." -ForegroundColor Yellow
        Write-Host "Chemin recherché: $dependencyPath" -ForegroundColor Yellow

        Read-Host "Appuyez sur Entrée pour continuer"
    }
}

# Fonction pour afficher le menu de configuration
function Show-ConfigurationMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )

    $exit = $false

    while (-not $exit) {
        Clear-Host

        Write-Host "=== CONFIGURATION ===" -ForegroundColor Cyan
        Write-Host "1. Changer le répertoire des archives" -ForegroundColor White
        Write-Host "2. Configurer les options d'affichage" -ForegroundColor White
        Write-Host "3. Gérer le cache" -ForegroundColor White
        Write-Host "Q. Retour au menu principal" -ForegroundColor White
        Write-Host "======================" -ForegroundColor Cyan

        $choice = Read-Host "Votre choix"

        switch ($choice) {
            "1" {
                $newPath = Read-Host "Entrez le nouveau chemin des archives [$ArchivePath]"
                if (-not [string]::IsNullOrWhiteSpace($newPath)) {
                    if (Test-Path -Path $newPath -PathType Container) {
                        $ArchivePath = $newPath
                        Write-Host "Chemin des archives mis à jour: $ArchivePath" -ForegroundColor Green
                    } else {
                        Write-Host "Le chemin spécifié n'existe pas." -ForegroundColor Red
                    }
                    Start-Sleep -Seconds 1
                }
            }
            "2" {
                Write-Host "Cette fonctionnalité n'est pas encore implémentée." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            "3" {
                Show-CacheManagementMenu
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

    return $ArchivePath
}

# Fonction pour afficher le menu de gestion du cache
function Show-CacheManagementMenu {
    [CmdletBinding()]
    param ()

    Clear-Host

    Write-Host "=== GESTION DU CACHE ===" -ForegroundColor Cyan
    Write-Host "1. Vider le cache" -ForegroundColor White
    Write-Host "2. Supprimer uniquement les entrées expirées" -ForegroundColor White
    Write-Host "3. Afficher les informations sur le cache" -ForegroundColor White
    Write-Host "Q. Retour au menu de configuration" -ForegroundColor White
    Write-Host "======================" -ForegroundColor Cyan

    $choice = Read-Host "Votre choix"

    switch ($choice) {
        "1" {
            try {
                $result = Clear-ArchiveCache -RemoveAll
                if ($result) {
                    Write-Host "Cache vidé avec succès." -ForegroundColor Green
                } else {
                    Write-Host "Erreur lors du vidage du cache." -ForegroundColor Red
                }
            } catch {
                Write-Host "Erreur lors du vidage du cache: $($_.Exception.Message)" -ForegroundColor Red
            }
            Start-Sleep -Seconds 1
        }
        "2" {
            try {
                $result = Clear-ArchiveCache -RemoveExpiredOnly
                if ($result) {
                    Write-Host "Entrées expirées supprimées avec succès." -ForegroundColor Green
                } else {
                    Write-Host "Erreur lors de la suppression des entrées expirées." -ForegroundColor Red
                }
            } catch {
                Write-Host "Erreur lors de la suppression des entrées expirées: $($_.Exception.Message)" -ForegroundColor Red
            }
            Start-Sleep -Seconds 1
        }
        "3" {
            try {
                $cachePath = "$env:TEMP\archive_cache"
                $configPath = "$cachePath\config.json"

                if (Test-Path -Path $configPath) {
                    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                    $cacheSize = (Get-ChildItem -Path $cachePath -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

                    Write-Host "Informations sur le cache:" -ForegroundColor Cyan
                    Write-Host "  Chemin: $cachePath" -ForegroundColor White
                    Write-Host "  Taille maximale: $($config.MaxCacheSize) Mo" -ForegroundColor White
                    Write-Host "  Taille actuelle: $([Math]::Round($cacheSize, 2)) Mo" -ForegroundColor White
                    Write-Host "  Expiration: $($config.CacheExpirationHours) heures" -ForegroundColor White
                    Write-Host "  Dernier nettoyage: $($config.LastCleanup)" -ForegroundColor White
                    Write-Host "  Créé le: $($config.CreatedAt)" -ForegroundColor White

                    $fileCount = (Get-ChildItem -Path $cachePath -File -Exclude "config.json").Count
                    Write-Host "  Nombre de fichiers: $fileCount" -ForegroundColor White
                } else {
                    Write-Host "Le cache n'est pas initialisé." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Erreur lors de l'affichage des informations sur le cache: $($_.Exception.Message)" -ForegroundColor Red
            }
            Read-Host "Appuyez sur Entrée pour continuer"
        }
        "Q" {
            # Retour au menu de configuration
        }
        "q" {
            # Retour au menu de configuration
        }
        default {
            Write-Host "Choix invalide. Veuillez réessayer." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Show-CacheManagementMenu
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Show-RestoreMainMenu, Show-RestorePointsMenu, Show-SearchRestorePointsMenu, Show-RestoreSpecificPointMenu, Show-CompareRestorePointsMenu, Show-DependenciesMenu, Show-TimelineMenu, Show-ConfigurationMenu
