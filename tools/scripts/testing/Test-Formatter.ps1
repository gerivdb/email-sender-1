# Test-Formatter.ps1
# Script de test pour le formatage de texte en format roadmap

# Fonction pour detecter si une ligne est un titre de phase
function Test-PhaseTitle {
    param (
        [string]$Line
    )
    
    # Un titre de phase est generalement en majuscules, contient "Phase" ou est numerote
    # Ou commence par un mot en majuscules suivi de ":" (ex: "ANALYSE:")
    # Ou commence par un mot en majuscules suivi d'un chiffre (ex: "PHASE 1")
    # Ou est entierement en majuscules
    # Ou commence par un symbole de titre (#, ##, ###)
    return $Line -match "^(PHASE|Phase|\d+\.|\*\*|#+ )" -or 
           $Line -match "^[A-Z][A-Z]+:" -or 
           $Line -match "^[A-Z][A-Z]+ \d+" -or 
           $Line -match "^[A-Z][A-Z\s]+$" -or
           $Line -match "^[A-Z][a-zA-Z]+ \d+:" # Format "Phase 1:" ou "Etape 2:"
}

# Fonction pour formater une ligne en fonction de son niveau d'indentation
function Format-LineByIndentation {
    param (
        [string]$Line,
        [int]$Level
    )
    
    # Nettoyer la ligne
    $Line = $Line.Trim()
    
    # Ignorer les lignes vides
    if ([string]::IsNullOrWhiteSpace($Line)) {
        return ""
    }
    
    # Variables pour les metadonnees
    $isPriority = $false
    $timeEstimate = ""
    
    # Detecter si la tache est prioritaire (contient "prioritaire", "urgent", "important", "!" ou "*")
    if ($Line -match "(prioritaire|urgent|important|!|\*)" -and -not (Test-PhaseTitle -Line $Line)) {
        $isPriority = $true
        $Line = $Line -replace "\s*\(?(prioritaire|urgent|important)\)?\s*", ""
        $Line = $Line -replace "\s*[!*]+\s*", ""
    }
    
    # Detecter l'estimation de temps (format: (Xh), (X jours), (X-Y jours), etc.)
    if ($Line -match "\(\s*(\d+(?:-\d+)?\s*(?:h|heure|heures|jour|jours|semaine|semaines|mois))\s*\)") {
        $timeEstimate = $Matches[1]
        $Line = $Line -replace "\s*\(\s*\d+(?:-\d+)?\s*(?:h|heure|heures|jour|jours|semaine|semaines|mois)\s*\)\s*", ""
    }
    
    # Supprimer les puces ou numeros existants
    $Line = $Line -replace "^[-*•]\s*", ""
    $Line = $Line -replace "^\d+\.\s*", ""
    
    # Construire la ligne formatee
    $formattedLine = ""
    $indent = "  " * $Level
    
    # Formater en fonction du niveau
    if ($Level -eq 0 -and (Test-PhaseTitle -Line $Line)) {
        # Niveau 0 : Phase principale
        $formattedLine = "$indent- [ ] **Phase: $Line**"
    } else {
        # Autres niveaux
        if ($isPriority) {
            $formattedLine = "$indent- [ ] **$Line** [PRIORITAIRE]"
        } else {
            $formattedLine = "$indent- [ ] $Line"
        }
        
        # Ajouter l'estimation de temps si presente
        if (-not [string]::IsNullOrWhiteSpace($timeEstimate)) {
            $formattedLine += " ($timeEstimate)"
        }
    }
    
    return $formattedLine
}

# Fonction pour formater le texte en format roadmap
function Format-TextToRoadmap {
    param (
        [string]$InputText,
        [string]$SectionTitle = "Nouvelle section",
        [string]$Complexity = "Moyenne",
        [string]$TimeEstimate = "3-5 jours"
    )
    
    # Initialiser le resultat
    $result = @()
    $result += "## $SectionTitle"
    $result += "**Complexite**: $Complexity"
    $result += "**Temps estime**: $TimeEstimate"
    $result += "**Progression**: 0%"
    $result += ""
    
    # Diviser le texte en lignes
    $lines = $InputText -split "`r?`n"
    
    # Traiter chaque ligne
    foreach ($line in $lines) {
        # Ignorer les lignes vides
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        # Detecter le niveau d'indentation
        $level = 0
        if ($line -match "^(\s*)(.*)$") {
            $indent = $matches[1]
            $content = $matches[2]
            
            # Si la ligne commence par un tiret, c'est deja une liste
            if ($content -match "^[-*]") {
                $level = $indent.Length
            } else {
                # Sinon, on considere que c'est un niveau d'indentation base sur les espaces
                $level = [Math]::Floor($indent.Length / 2)
            }
        }
        
        # Formater la ligne
        $formattedLine = Format-LineByIndentation -Line $line -Level $level
        
        # Ajouter la ligne au resultat
        if (-not [string]::IsNullOrWhiteSpace($formattedLine)) {
            $result += $formattedLine
        }
    }
    
    # Joindre les lignes avec des sauts de ligne
    return $result -join "`n"
}

# Lire le contenu du fichier de test
$testFilePath = Join-Path -Path $PSScriptRoot -ChildPath "test-example.txt"
$testContent = Get-Content -Path $testFilePath -Raw

# Formater le texte
$formattedText = Format-TextToRoadmap -InputText $testContent -SectionTitle "Test des priorites et estimations" -Complexity "Moyenne" -TimeEstimate "2-3 semaines"

# Afficher le resultat
Write-Host "Texte formate:" -ForegroundColor Yellow
Write-Host $formattedText -ForegroundColor Green
