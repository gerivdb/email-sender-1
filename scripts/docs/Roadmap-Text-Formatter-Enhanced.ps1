# Roadmap-Text-Formatter-Enhanced.ps1
# Interface utilisateur améliorée pour le formatage de texte en format roadmap

# Fonction pour afficher le menu principal avec des couleurs et une mise en page améliorée
function Show-MainMenu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  ROADMAP TEXT FORMATTER                      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] " -ForegroundColor Yellow -NoNewline; Write-Host "Formater du texte en format roadmap"
    Write-Host "  [2] " -ForegroundColor Yellow -NoNewline; Write-Host "Ajouter une section à la roadmap"
    Write-Host "  [3] " -ForegroundColor Yellow -NoNewline; Write-Host "Insérer une section entre deux sections existantes"
    Write-Host "  [4] " -ForegroundColor Yellow -NoNewline; Write-Host "Aide et exemples"
    Write-Host "  [5] " -ForegroundColor Yellow -NoNewline; Write-Host "Quitter"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "║  Astuce: Utilisez 'prioritaire', '!' ou '*' pour marquer     ║" -ForegroundColor DarkGray
    Write-Host "║  une tâche comme prioritaire. Utilisez (2h) ou (3 jours)     ║" -ForegroundColor DarkGray
    Write-Host "║  pour ajouter une estimation de temps.                       ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "Votre choix"
    
    switch ($choice) {
        "1" { Format-Text }
        "2" { Add-SectionToRoadmap }
        "3" { Insert-SectionBetweenExisting }
        "4" { Show-Help }
        "5" { exit }
        default { Show-MainMenu }
    }
}

# Fonction pour afficher l'aide et les exemples
function Show-Help {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  AIDE ET EXEMPLES                            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "FORMATS DE TEXTE PRIS EN CHARGE:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Liste simple:" -ForegroundColor Green
    Write-Host "   Analyse des besoins"
    Write-Host "   Conception"
    Write-Host "   Développement"
    Write-Host "   Tests"
    Write-Host "   Déploiement"
    Write-Host ""
    Write-Host "2. Liste avec indentation:" -ForegroundColor Green
    Write-Host "   Analyse des besoins"
    Write-Host "     Identifier les exigences"
    Write-Host "     Documenter les cas d'utilisation"
    Write-Host "   Conception"
    Write-Host "     Créer les maquettes"
    Write-Host "     Définir l'architecture"
    Write-Host ""
    Write-Host "3. Liste avec phases:" -ForegroundColor Green
    Write-Host "   PHASE 1: Analyse des besoins"
    Write-Host "   Identifier les exigences"
    Write-Host "   Documenter les cas d'utilisation"
    Write-Host ""
    Write-Host "   PHASE 2: Conception"
    Write-Host "   Créer les maquettes"
    Write-Host "   Définir l'architecture"
    Write-Host ""
    Write-Host "4. Tâches prioritaires et estimations de temps:" -ForegroundColor Green
    Write-Host "   Analyse des besoins (3 jours)"
    Write-Host "   Conception prioritaire (5 jours)"
    Write-Host "   Développement ! (2 semaines)"
    Write-Host "   Tests * (3 jours)"
    Write-Host "   Déploiement (urgent) (1 jour)"
    Write-Host ""
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-MainMenu
}

# Fonction pour formater du texte
function Format-Text {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              FORMATER DU TEXTE EN FORMAT ROADMAP             ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
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
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "║                  PARAMÈTRES DE FORMATAGE                     ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    
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
    
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                      TEXTE FORMATÉ                           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $formattedText -ForegroundColor Green
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "║                         OPTIONS                              ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [1] " -ForegroundColor Yellow -NoNewline; Write-Host "Enregistrer dans un fichier"
    Write-Host "  [2] " -ForegroundColor Yellow -NoNewline; Write-Host "Ajouter à la roadmap"
    Write-Host "  [3] " -ForegroundColor Yellow -NoNewline; Write-Host "Copier dans le presse-papiers"
    Write-Host "  [4] " -ForegroundColor Yellow -NoNewline; Write-Host "Retour au menu principal"
    Write-Host ""
    $option = Read-Host "Votre choix"
    
    switch ($option) {
        "1" {
            $outputFile = Read-Host "Nom du fichier"
            if (-not [string]::IsNullOrWhiteSpace($outputFile)) {
                Set-Content -Path $outputFile -Value $formattedText
                Write-Host "Le texte formaté a été enregistré dans le fichier $outputFile" -ForegroundColor Green
            }
            Read-Host "Appuyez sur Entrée pour continuer"
            Show-MainMenu
        }
        "2" {
            $roadmapFile = Read-Host "Fichier roadmap (par défaut: roadmap_perso.md)"
            if ([string]::IsNullOrWhiteSpace($roadmapFile)) {
                $roadmapFile = "roadmap_perso.md"
            }
            
            $addScript = Join-Path -Path $PSScriptRoot -ChildPath "Add-FormattedTextToRoadmap.ps1"
            & $addScript -Text $text -SectionTitle $sectionTitle -Complexity $complexity -TimeEstimate $timeEstimate -RoadmapFile $roadmapFile
            
            Read-Host "Appuyez sur Entrée pour continuer"
            Show-MainMenu
        }
        "3" {
            # Copier dans le presse-papiers
            $formattedText | Set-Clipboard
            Write-Host "Le texte formaté a été copié dans le presse-papiers" -ForegroundColor Green
            Read-Host "Appuyez sur Entrée pour continuer"
            Show-MainMenu
        }
        "4" {
            Show-MainMenu
        }
        default {
            Read-Host "Option invalide. Appuyez sur Entrée pour continuer"
            Show-MainMenu
        }
    }
}

# Fonction pour ajouter une section à la roadmap
function Add-SectionToRoadmap {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              AJOUTER UNE SECTION À LA ROADMAP                ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
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
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "║                  PARAMÈTRES DE LA SECTION                    ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    
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
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        INSÉRER UNE SECTION ENTRE DEUX SECTIONS EXISTANTES    ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
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
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
    Write-Host "║                  PARAMÈTRES DE LA SECTION                    ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    
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
    
    # Afficher les sections existantes
    $roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath $roadmapFile
    if (Test-Path -Path $roadmapPath) {
        $roadmapContent = Get-Content -Path $roadmapPath -Raw
        $roadmapLines = $roadmapContent -split "`r?`n"
        
        $sections = @()
        for ($i = 0; $i -lt $roadmapLines.Count; $i++) {
            if ($roadmapLines[$i] -match "^## (\d+(?:\.\w+)?)(.*)") {
                $sectionNumber = $Matches[1]
                $sectionName = $Matches[2].Trim()
                $sections += [PSCustomObject]@{
                    Number = $sectionNumber
                    Name = $sectionName
                    Index = $i
                }
            }
        }
        
        Write-Host ""
        Write-Host "Sections existantes:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $sections.Count; $i++) {
            Write-Host "  [$($i + 1)] " -ForegroundColor Green -NoNewline
            Write-Host "$($sections[$i].Number)$($sections[$i].Name)"
        }
        Write-Host ""
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

# Vérifier si le module Set-Clipboard est disponible
if (-not (Get-Command Set-Clipboard -ErrorAction SilentlyContinue)) {
    # Si non disponible, créer une fonction de remplacement
    function Set-Clipboard {
        param (
            [Parameter(ValueFromPipeline = $true)]
            [string]$Text
        )
        
        try {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.Clipboard]::SetText($Text)
        } catch {
            Write-Warning "Impossible de copier dans le presse-papiers: $_"
        }
    }
}

# Démarrer le programme
Show-MainMenu
