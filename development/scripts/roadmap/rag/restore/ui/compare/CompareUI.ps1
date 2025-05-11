# CompareUI.ps1
# Interface utilisateur pour la comparaison de points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$comparePath = Join-Path -Path $scriptPath -ChildPath "CompareManager.ps1"
$viewerPath = Join-Path -Path $scriptPath -ChildPath "CompareViewer.ps1"

if (Test-Path -Path $comparePath) {
    . $comparePath
} else {
    Write-Error "Le fichier CompareManager.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier CompareViewer.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher le menu principal de comparaison
function Show-CompareMainMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )
    
    $exit = $false
    
    while (-not $exit) {
        Clear-Host
        
        Write-Host "=== MENU DE COMPARAISON DE POINTS DE RESTAURATION ===" -ForegroundColor Cyan
        Write-Host "1. Sélectionner des points à comparer" -ForegroundColor White
        Write-Host "2. Comparer des points spécifiques par ID" -ForegroundColor White
        Write-Host "3. Comparer des points par date" -ForegroundColor White
        Write-Host "4. Comparer des points par type" -ForegroundColor White
        Write-Host "5. Afficher l'historique des comparaisons" -ForegroundColor White
        Write-Host "Q. Quitter" -ForegroundColor White
        Write-Host "======================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Votre choix"
        
        switch ($choice) {
            "1" {
                Show-SelectPointsMenu -ArchivePath $ArchivePath
            }
            "2" {
                Show-CompareByIdMenu -ArchivePath $ArchivePath
            }
            "3" {
                Show-CompareByDateMenu -ArchivePath $ArchivePath
            }
            "4" {
                Show-CompareByTypeMenu -ArchivePath $ArchivePath
            }
            "5" {
                Show-ComparisonHistoryMenu -ArchivePath $ArchivePath
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

# Fonction pour afficher le menu de sélection de points
function Show-SelectPointsMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )
    
    # Sélectionner les points à comparer
    $selectedPoints = Select-RestorePointsToCompare -ArchivePath $ArchivePath -MaxPoints 2 -UseCache
    
    if ($null -eq $selectedPoints -or $selectedPoints.Count -lt 2) {
        Write-Host "Vous devez sélectionner au moins 2 points pour effectuer une comparaison." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    # Effectuer la comparaison
    $comparison = Compare-RestorePoints -Point1 $selectedPoints[0] -Point2 $selectedPoints[1]
    
    # Afficher le menu de visualisation de la comparaison
    Show-ComparisonViewMenu -Comparison $comparison
}

# Fonction pour afficher le menu de comparaison par ID
function Show-CompareByIdMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )
    
    Clear-Host
    
    Write-Host "=== COMPARAISON PAR ID ===" -ForegroundColor Cyan
    
    # Demander les IDs des points à comparer
    $id1 = Read-Host "Entrez l'ID du premier point"
    $id2 = Read-Host "Entrez l'ID du deuxième point"
    
    if ([string]::IsNullOrWhiteSpace($id1) -or [string]::IsNullOrWhiteSpace($id2)) {
        Write-Host "Les IDs ne peuvent pas être vides." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache
    
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
    
    # Effectuer la comparaison
    $comparison = Compare-RestorePoints -Point1 $point1 -Point2 $point2
    
    # Afficher le menu de visualisation de la comparaison
    Show-ComparisonViewMenu -Comparison $comparison
}

# Fonction pour afficher le menu de comparaison par date
function Show-CompareByDateMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )
    
    Clear-Host
    
    Write-Host "=== COMPARAISON PAR DATE ===" -ForegroundColor Cyan
    
    # Demander les dates des points à comparer
    $date1Str = Read-Host "Entrez la première date (YYYY-MM-DD)"
    $date2Str = Read-Host "Entrez la deuxième date (YYYY-MM-DD)"
    
    # Valider et convertir les dates
    try {
        $date1 = [DateTime]::Parse($date1Str)
    } catch {
        Write-Host "Format de date invalide: $date1Str" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    try {
        $date2 = [DateTime]::Parse($date2Str)
    } catch {
        Write-Host "Format de date invalide: $date2Str" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Récupérer les points de restauration pour chaque date
    $points1 = Get-RestorePoints -ArchivePath $ArchivePath -StartDate $date1 -EndDate $date1.AddDays(1) -UseCache
    $points2 = Get-RestorePoints -ArchivePath $ArchivePath -StartDate $date2 -EndDate $date2.AddDays(1) -UseCache
    
    if ($null -eq $points1 -or $points1.Count -eq 0) {
        Write-Host "Aucun point trouvé pour la date: $date1Str" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    if ($null -eq $points2 -or $points2.Count -eq 0) {
        Write-Host "Aucun point trouvé pour la date: $date2Str" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Sélectionner le premier point de chaque date
    $point1 = $points1[0]
    $point2 = $points2[0]
    
    # Effectuer la comparaison
    $comparison = Compare-RestorePoints -Point1 $point1 -Point2 $point2
    
    # Afficher le menu de visualisation de la comparaison
    Show-ComparisonViewMenu -Comparison $comparison
}

# Fonction pour afficher le menu de comparaison par type
function Show-CompareByTypeMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )
    
    Clear-Host
    
    Write-Host "=== COMPARAISON PAR TYPE ===" -ForegroundColor Cyan
    
    # Récupérer les types disponibles
    $types = Get-AvailableTypes -ArchivePath $ArchivePath -IncludeCount -UseCache
    
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
    
    # Demander les types à comparer
    $type1Index = Read-Host "Entrez le numéro du premier type"
    $type2Index = Read-Host "Entrez le numéro du deuxième type"
    
    if (-not ($type1Index -match '^\d+$') -or [int]$type1Index -lt 1 -or [int]$type1Index -gt $types.Count) {
        Write-Host "Numéro de type invalide: $type1Index" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    if (-not ($type2Index -match '^\d+$') -or [int]$type2Index -lt 1 -or [int]$type2Index -gt $types.Count) {
        Write-Host "Numéro de type invalide: $type2Index" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    $type1 = $types[[int]$type1Index - 1].Value
    $type2 = $types[[int]$type2Index - 1].Value
    
    # Récupérer les points de restauration pour chaque type
    $points1 = Get-RestorePoints -ArchivePath $ArchivePath -Type $type1 -UseCache
    $points2 = Get-RestorePoints -ArchivePath $ArchivePath -Type $type2 -UseCache
    
    if ($null -eq $points1 -or $points1.Count -eq 0) {
        Write-Host "Aucun point trouvé pour le type: $type1" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    if ($null -eq $points2 -or $points2.Count -eq 0) {
        Write-Host "Aucun point trouvé pour le type: $type2" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Sélectionner le premier point de chaque type
    $point1 = $points1[0]
    $point2 = $points2[0]
    
    # Effectuer la comparaison
    $comparison = Compare-RestorePoints -Point1 $point1 -Point2 $point2
    
    # Afficher le menu de visualisation de la comparaison
    Show-ComparisonViewMenu -Comparison $comparison
}

# Fonction pour afficher le menu de l'historique des comparaisons
function Show-ComparisonHistoryMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )
    
    Clear-Host
    
    Write-Host "=== HISTORIQUE DES COMPARAISONS ===" -ForegroundColor Cyan
    Write-Host "Cette fonctionnalité n'est pas encore implémentée." -ForegroundColor Yellow
    
    Read-Host "Appuyez sur Entrée pour continuer"
}

# Fonction pour afficher le menu de visualisation de la comparaison
function Show-ComparisonViewMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison
    )
    
    $exit = $false
    
    while (-not $exit) {
        Clear-Host
        
        Write-Host "=== VISUALISATION DE LA COMPARAISON ===" -ForegroundColor Cyan
        Write-Host "1. Affichage côte à côte" -ForegroundColor White
        Write-Host "2. Affichage avec mise en évidence des différences" -ForegroundColor White
        Write-Host "3. Affichage des statistiques de changement" -ForegroundColor White
        Write-Host "4. Affichage des statistiques avec graphique" -ForegroundColor White
        Write-Host "5. Affichage des différences uniquement" -ForegroundColor White
        Write-Host "Q. Quitter" -ForegroundColor White
        Write-Host "=========================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Votre choix"
        
        switch ($choice) {
            "1" {
                Show-SideBySideComparison -Comparison $Comparison
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "2" {
                Show-DifferenceHighlighting -Comparison $Comparison
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "3" {
                Show-ChangeStatistics -Comparison $Comparison
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "4" {
                Show-ChangeStatistics -Comparison $Comparison -IncludeChart
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "5" {
                Show-SideBySideComparison -Comparison $Comparison -ShowOnlyDifferences
                Read-Host "Appuyez sur Entrée pour continuer"
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

# Exporter les fonctions
Export-ModuleMember -Function Show-CompareMainMenu, Show-SelectPointsMenu, Show-CompareByIdMenu, Show-CompareByDateMenu, Show-CompareByTypeMenu, Show-ComparisonHistoryMenu, Show-ComparisonViewMenu
