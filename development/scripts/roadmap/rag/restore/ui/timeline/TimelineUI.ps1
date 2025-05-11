# TimelineUI.ps1
# Interface utilisateur pour la timeline des points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path $scriptPath -ChildPath "TimelineViewer.ps1"

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier TimelineViewer.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher le menu principal de la timeline
function Show-TimelineMainMenu {
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
        
        Write-Host "=== MENU DE LA TIMELINE DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
        Write-Host "1. Afficher la timeline par jour" -ForegroundColor White
        Write-Host "2. Afficher la timeline par semaine" -ForegroundColor White
        Write-Host "3. Afficher la timeline par mois" -ForegroundColor White
        Write-Host "4. Afficher la timeline par année" -ForegroundColor White
        Write-Host "5. Afficher le calendrier des points" -ForegroundColor White
        Write-Host "6. Afficher les graphiques de tendances" -ForegroundColor White
        Write-Host "7. Rechercher dans la timeline" -ForegroundColor White
        Write-Host "Q. Quitter" -ForegroundColor White
        Write-Host "======================================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Votre choix"
        
        switch ($choice) {
            "1" {
                Show-TimelineByPeriod -ArchivePath $ArchivePath -UseCache:$UseCache -Period "Day"
            }
            "2" {
                Show-TimelineByPeriod -ArchivePath $ArchivePath -UseCache:$UseCache -Period "Week"
            }
            "3" {
                Show-TimelineByPeriod -ArchivePath $ArchivePath -UseCache:$UseCache -Period "Month"
            }
            "4" {
                Show-TimelineByPeriod -ArchivePath $ArchivePath -UseCache:$UseCache -Period "Year"
            }
            "5" {
                Show-TimelineCalendarMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "6" {
                Show-TimelineTrendsMenu -ArchivePath $ArchivePath -UseCache:$UseCache
            }
            "7" {
                Show-TimelineSearchMenu -ArchivePath $ArchivePath -UseCache:$UseCache
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

# Fonction pour afficher la timeline par période
function Show-TimelineByPeriod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Day", "Week", "Month", "Year")]
        [string]$Period = "Day"
    )
    
    Clear-Host
    
    Write-Host "=== TIMELINE DES POINTS DE RESTAURATION PAR $Period ===" -ForegroundColor Cyan
    
    # Demander la plage de dates
    $useCustomRange = $false
    Write-Host "`nVoulez-vous spécifier une plage de dates? (O/N)" -ForegroundColor Yellow
    $choice = Read-Host
    
    $startDate = $null
    $endDate = $null
    
    if ($choice -eq "O" -or $choice -eq "o") {
        $useCustomRange = $true
        
        # Demander la date de début
        $startDateStr = Read-Host "Date de début (YYYY-MM-DD, laisser vide pour aucune limite)"
        
        if (-not [string]::IsNullOrWhiteSpace($startDateStr)) {
            try {
                $startDate = [DateTime]::Parse($startDateStr)
            } catch {
                Write-Host "Format de date invalide. Utilisation de la date par défaut." -ForegroundColor Red
                Start-Sleep -Seconds 1
                $startDate = $null
            }
        }
        
        # Demander la date de fin
        $endDateStr = Read-Host "Date de fin (YYYY-MM-DD, laisser vide pour aucune limite)"
        
        if (-not [string]::IsNullOrWhiteSpace($endDateStr)) {
            try {
                $endDate = [DateTime]::Parse($endDateStr)
            } catch {
                Write-Host "Format de date invalide. Utilisation de la date par défaut." -ForegroundColor Red
                Start-Sleep -Seconds 1
                $endDate = $null
            }
        }
    }
    
    # Demander le mode de visualisation
    Write-Host "`nMode de visualisation:" -ForegroundColor Yellow
    Write-Host "1. Liste" -ForegroundColor White
    Write-Host "2. Graphique" -ForegroundColor White
    
    $viewMode = "List"
    $viewChoice = Read-Host "Votre choix (1-2)"
    
    if ($viewChoice -eq "2") {
        $viewMode = "Chart"
    }
    
    # Récupérer et afficher la timeline
    $params = @{
        ArchivePath = $ArchivePath
        UseCache = $UseCache
        Period = $Period
        ViewMode = $viewMode
    }
    
    if ($useCustomRange) {
        if ($null -ne $startDate) {
            $params["StartDate"] = $startDate
        }
        
        if ($null -ne $endDate) {
            $params["EndDate"] = $endDate
        }
    }
    
    Show-RestorePointsTimeline @params
}

# Fonction pour afficher le calendrier des points de restauration
function Show-TimelineCalendarMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    Clear-Host
    
    Write-Host "=== CALENDRIER DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    
    # Demander le mois à afficher
    $useCustomMonth = $false
    Write-Host "`nVoulez-vous spécifier un mois particulier? (O/N)" -ForegroundColor Yellow
    $choice = Read-Host
    
    $month = $null
    
    if ($choice -eq "O" -or $choice -eq "o") {
        $useCustomMonth = $true
        
        # Demander l'année et le mois
        $yearStr = Read-Host "Année (YYYY, laisser vide pour l'année en cours)"
        $monthStr = Read-Host "Mois (1-12, laisser vide pour le mois en cours)"
        
        $year = if ([string]::IsNullOrWhiteSpace($yearStr)) { (Get-Date).Year } else { [int]$yearStr }
        $monthNum = if ([string]::IsNullOrWhiteSpace($monthStr)) { (Get-Date).Month } else { [int]$monthStr }
        
        try {
            $month = New-Object DateTime($year, $monthNum, 1)
        } catch {
            Write-Host "Date invalide. Utilisation de la date par défaut." -ForegroundColor Red
            Start-Sleep -Seconds 1
            $month = $null
        }
    }
    
    # Récupérer les points de restauration
    $points = Get-RestorePointsTimeline -ArchivePath $ArchivePath -UseCache:$UseCache
    
    # Afficher le calendrier
    $params = @{
        RestorePoints = $points
    }
    
    if ($useCustomMonth -and $null -ne $month) {
        $params["Month"] = $month
    }
    
    Show-TimelineCalendar @params
}

# Fonction pour afficher les tendances de la timeline
function Show-TimelineTrendsMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    Clear-Host
    
    Write-Host "=== TENDANCES DE LA TIMELINE DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    
    # Demander la période d'analyse
    Write-Host "`nPériode d'analyse:" -ForegroundColor Yellow
    Write-Host "1. Jour" -ForegroundColor White
    Write-Host "2. Semaine" -ForegroundColor White
    Write-Host "3. Mois" -ForegroundColor White
    Write-Host "4. Année" -ForegroundColor White
    
    $period = "Month"
    $periodChoice = Read-Host "Votre choix (1-4)"
    
    switch ($periodChoice) {
        "1" { $period = "Day" }
        "2" { $period = "Week" }
        "3" { $period = "Month" }
        "4" { $period = "Year" }
    }
    
    # Récupérer les points de restauration
    $points = Get-RestorePointsTimeline -ArchivePath $ArchivePath -UseCache:$UseCache
    
    # Afficher les tendances
    Show-RestorePointsTimeline -RestorePoints $points -Period $period -ViewMode "Chart"
}

# Fonction pour rechercher dans la timeline
function Show-TimelineSearchMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    Clear-Host
    
    Write-Host "=== RECHERCHE DANS LA TIMELINE DES POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    
    # Demander les critères de recherche
    Write-Host "`nCritères de recherche:" -ForegroundColor Yellow
    
    # Type
    $type = Read-Host "Type (laisser vide pour tous)"
    
    # Catégorie
    $category = Read-Host "Catégorie (laisser vide pour toutes)"
    
    # Tags
    $tagsStr = Read-Host "Tags (séparés par des virgules, laisser vide pour tous)"
    $tags = if ([string]::IsNullOrWhiteSpace($tagsStr)) { @() } else { $tagsStr -split ',' | ForEach-Object { $_.Trim() } }
    
    # Plage de dates
    $startDate = $null
    $endDate = $null
    
    $useDateRange = $false
    Write-Host "`nVoulez-vous spécifier une plage de dates? (O/N)" -ForegroundColor Yellow
    $choice = Read-Host
    
    if ($choice -eq "O" -or $choice -eq "o") {
        $useDateRange = $true
        
        # Date de début
        $startDateStr = Read-Host "Date de début (YYYY-MM-DD, laisser vide pour aucune limite)"
        
        if (-not [string]::IsNullOrWhiteSpace($startDateStr)) {
            try {
                $startDate = [DateTime]::Parse($startDateStr)
            } catch {
                Write-Host "Format de date invalide. Aucune limite de date de début." -ForegroundColor Red
                Start-Sleep -Seconds 1
                $startDate = $null
            }
        }
        
        # Date de fin
        $endDateStr = Read-Host "Date de fin (YYYY-MM-DD, laisser vide pour aucune limite)"
        
        if (-not [string]::IsNullOrWhiteSpace($endDateStr)) {
            try {
                $endDate = [DateTime]::Parse($endDateStr)
            } catch {
                Write-Host "Format de date invalide. Aucune limite de date de fin." -ForegroundColor Red
                Start-Sleep -Seconds 1
                $endDate = $null
            }
        }
    }
    
    # Récupérer les points de restauration
    $params = @{
        ArchivePath = $ArchivePath
        UseCache = $UseCache
    }
    
    if (-not [string]::IsNullOrWhiteSpace($type)) {
        $params["Type"] = $type
    }
    
    if (-not [string]::IsNullOrWhiteSpace($category)) {
        $params["Category"] = $category
    }
    
    if ($tags.Count -gt 0) {
        $params["Tags"] = $tags
    }
    
    if ($useDateRange) {
        if ($null -ne $startDate) {
            $params["StartDate"] = $startDate
        }
        
        if ($null -ne $endDate) {
            $params["EndDate"] = $endDate
        }
    }
    
    $points = Get-RestorePointsTimeline @params
    
    # Demander le mode de visualisation
    Write-Host "`nMode de visualisation:" -ForegroundColor Yellow
    Write-Host "1. Liste" -ForegroundColor White
    Write-Host "2. Graphique" -ForegroundColor White
    Write-Host "3. Calendrier" -ForegroundColor White
    
    $viewMode = "List"
    $viewChoice = Read-Host "Votre choix (1-3)"
    
    switch ($viewChoice) {
        "2" { $viewMode = "Chart" }
        "3" { $viewMode = "Calendar" }
    }
    
    # Afficher les résultats
    Show-RestorePointsTimeline -RestorePoints $points -ViewMode $viewMode
}

# Exporter les fonctions
Export-ModuleMember -Function Show-TimelineMainMenu, Show-TimelineByPeriod, Show-TimelineCalendarMenu, Show-TimelineTrendsMenu, Show-TimelineSearchMenu
