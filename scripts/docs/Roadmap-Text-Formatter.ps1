# Roadmap-Text-Formatter.ps1
# Script d'interface utilisateur pour le formatage de texte en format roadmap

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "=== Roadmap Text Formatter ===" -ForegroundColor Cyan
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
    
    $formatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap.ps1"
    $formattedText = & $formatScript -Text $text -SectionTitle $sectionTitle -Complexity $complexity -TimeEstimate $timeEstimate
    
    Write-Host "`nTexte formaté:" -ForegroundColor Yellow
    Write-Host $formattedText
    
    $saveToFile = Read-Host "Voulez-vous enregistrer le texte formaté dans un fichier? (O/N)"
    if ($saveToFile -eq "O" -or $saveToFile -eq "o") {
        $outputFile = Read-Host "Nom du fichier"
        if (-not [string]::IsNullOrWhiteSpace($outputFile)) {
            Set-Content -Path $outputFile -Value $formattedText
            Write-Host "Le texte formaté a été enregistré dans le fichier $outputFile" -ForegroundColor Green
        }
    }
    
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
    
    $addScript = Join-Path -Path $PSScriptRoot -ChildPath "Add-FormattedTextToRoadmap.ps1"
    & $addScript -Text $text -SectionTitle $sectionTitle -Complexity $complexity -TimeEstimate $timeEstimate -RoadmapFile $roadmapFile
    
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
    
    $addScript = Join-Path -Path $PSScriptRoot -ChildPath "Add-FormattedTextToRoadmap.ps1"
    & $addScript -Text $text -SectionTitle $sectionTitle -Complexity $complexity -TimeEstimate $timeEstimate -RoadmapFile $roadmapFile -SectionNumber $sectionNumber
    
    Read-Host "Appuyez sur Entrée pour continuer"
    Show-MainMenu
}

# Démarrer le programme
Show-MainMenu
