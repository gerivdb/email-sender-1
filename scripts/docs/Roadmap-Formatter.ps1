# Roadmap-Formatter.ps1
# Script d'interface utilisateur pour le formatage de texte en format roadmap

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "=== Roadmap Formatter ===" -ForegroundColor Cyan
    Write-Host "1. Formater du texte en format roadmap"
    Write-Host "2. Ajouter une section à la roadmap"
    Write-Host "3. Insérer une section entre deux sections existantes"
    Write-Host "4. Quitter"
    Write-Host ""
    $choice = Read-Host "Votre choix"
    
    switch ($choice) {
        "1" { Format-Text }
        "2" { Add-SectionToRoadmap }
        "3" { Insert-SectionBetweenExisting }
        "4" { exit }
        default { Show-MainMenu }
    }
}

# Fonction pour formater du texte
function Format-Text {
    Clear-Host
    Write-Host "=== Formater du texte en format roadmap ===" -ForegroundColor Cyan
    Write-Host "Veuillez saisir le texte à formater (terminez par une ligne vide):" -ForegroundColor Yellow
    
    $lines = @()
    $line = Read-Host
    while (-not [string]::IsNullOrWhiteSpace($line)) {
        $lines += $line
        $line = Read-Host
    }
    
    $text = $lines -join "`n"
    
    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Host "Aucun texte saisi." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour continuer"
        Show-MainMenu
        return
    }
    
    $sectionTitle = Read-Host "Titre de la section (par défaut: Nouvelle section)"
    if ([string]::IsNullOrWhiteSpace($sectionTitle)) {
        $sectionTitle = "Nouvelle section"
    }
    
    $complexity = Read-Host "Complexité (par défaut: Moyenne)"
    if ([string]::IsNullOrWhiteSpace($complexity)) {
        $complexity = "Moyenne"
    }
    
    $timeEstimate = Read-Host "Temps estimé (par défaut: 3-5 jours)"
    if ([string]::IsNullOrWhiteSpace($timeEstimate)) {
        $timeEstimate = "3-5 jours"
    }
    
    $outputFile = Read-Host "Fichier de sortie (laissez vide pour ne pas enregistrer)"
    
    $formatRoadmapScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-RoadmapText.ps1"
    
    $params = @{
        Text = $text
        SectionTitle = $sectionTitle
        Complexity = $complexity
        TimeEstimate = $timeEstimate
    }
    
    if (-not [string]::IsNullOrWhiteSpace($outputFile)) {
        $params.OutputFile = $outputFile
    }
    
    & $formatRoadmapScript @params
    
    Read-Host "Appuyez sur Entrée pour continuer"
    Show-MainMenu
}

# Fonction pour ajouter une section à la roadmap
function Add-SectionToRoadmap {
    Clear-Host
    Write-Host "=== Ajouter une section à la roadmap ===" -ForegroundColor Cyan
    Write-Host "Veuillez saisir le texte à formater (terminez par une ligne vide):" -ForegroundColor Yellow
    
    $lines = @()
    $line = Read-Host
    while (-not [string]::IsNullOrWhiteSpace($line)) {
        $lines += $line
        $line = Read-Host
    }
    
    $text = $lines -join "`n"
    
    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Host "Aucun texte saisi." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour continuer"
        Show-MainMenu
        return
    }
    
    $sectionTitle = Read-Host "Titre de la section (par défaut: Nouvelle section)"
    if ([string]::IsNullOrWhiteSpace($sectionTitle)) {
        $sectionTitle = "Nouvelle section"
    }
    
    $complexity = Read-Host "Complexité (par défaut: Moyenne)"
    if ([string]::IsNullOrWhiteSpace($complexity)) {
        $complexity = "Moyenne"
    }
    
    $timeEstimate = Read-Host "Temps estimé (par défaut: 3-5 jours)"
    if ([string]::IsNullOrWhiteSpace($timeEstimate)) {
        $timeEstimate = "3-5 jours"
    }
    
    $roadmapFile = Read-Host "Fichier roadmap (par défaut: roadmap_perso.md)"
    if ([string]::IsNullOrWhiteSpace($roadmapFile)) {
        $roadmapFile = "roadmap_perso.md"
    }
    
    $formatRoadmapScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-RoadmapText.ps1"
    
    $params = @{
        Text = $text
        SectionTitle = $sectionTitle
        Complexity = $complexity
        TimeEstimate = $timeEstimate
        AppendToRoadmap = $true
        RoadmapFile = $roadmapFile
    }
    
    & $formatRoadmapScript @params
    
    Read-Host "Appuyez sur Entrée pour continuer"
    Show-MainMenu
}

# Fonction pour insérer une section entre deux sections existantes
function Insert-SectionBetweenExisting {
    Clear-Host
    Write-Host "=== Insérer une section entre deux sections existantes ===" -ForegroundColor Cyan
    Write-Host "Veuillez saisir le texte à formater (terminez par une ligne vide):" -ForegroundColor Yellow
    
    $lines = @()
    $line = Read-Host
    while (-not [string]::IsNullOrWhiteSpace($line)) {
        $lines += $line
        $line = Read-Host
    }
    
    $text = $lines -join "`n"
    
    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Host "Aucun texte saisi." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour continuer"
        Show-MainMenu
        return
    }
    
    $sectionTitle = Read-Host "Titre de la section (par défaut: Nouvelle section)"
    if ([string]::IsNullOrWhiteSpace($sectionTitle)) {
        $sectionTitle = "Nouvelle section"
    }
    
    $complexity = Read-Host "Complexité (par défaut: Moyenne)"
    if ([string]::IsNullOrWhiteSpace($complexity)) {
        $complexity = "Moyenne"
    }
    
    $timeEstimate = Read-Host "Temps estimé (par défaut: 3-5 jours)"
    if ([string]::IsNullOrWhiteSpace($timeEstimate)) {
        $timeEstimate = "3-5 jours"
    }
    
    $roadmapFile = Read-Host "Fichier roadmap (par défaut: roadmap_perso.md)"
    if ([string]::IsNullOrWhiteSpace($roadmapFile)) {
        $roadmapFile = "roadmap_perso.md"
    }
    
    $sectionNumber = Read-Host "Numéro de section avant laquelle insérer la nouvelle section"
    if (-not [int]::TryParse($sectionNumber, [ref]$null)) {
        Write-Host "Numéro de section invalide." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour continuer"
        Show-MainMenu
        return
    }
    
    $formatRoadmapScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-RoadmapText.ps1"
    
    $params = @{
        Text = $text
        SectionTitle = $sectionTitle
        Complexity = $complexity
        TimeEstimate = $timeEstimate
        AppendToRoadmap = $true
        RoadmapFile = $roadmapFile
        SectionNumber = $sectionNumber
    }
    
    & $formatRoadmapScript @params
    
    Read-Host "Appuyez sur Entrée pour continuer"
    Show-MainMenu
}

# Démarrer le programme
Show-MainMenu
