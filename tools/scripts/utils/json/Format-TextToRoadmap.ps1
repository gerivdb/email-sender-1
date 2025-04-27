# Format-TextToRoadmap.ps1
# Script simple pour reformater du texte en format roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$Text,

    [Parameter(Mandatory = $false)]
    [string]$SectionTitle = "Nouvelle section",

    [Parameter(Mandatory = $false)]
    [string]$Complexity = "Moyenne",

    [Parameter(Mandatory = $false)]
    [string]$TimeEstimate = "3-5 jours"
)

# Fonction pour dÃ©tecter le niveau d'indentation d'une ligne
function Get-IndentationLevel {
    param (
        [string]$Line
    )

    # Compter le nombre d'espaces ou de tabulations au dÃ©but de la ligne
    if ($Line -match "^(\s*)(.*)$") {
        $indent = $matches[1]
        $content = $matches[2]

        # Si la ligne commence par un tiret, c'est dÃ©jÃ  une liste
        if ($content -match "^[-*]") {
            return $indent.Length
        }

        # Sinon, on considÃ¨re que c'est un niveau d'indentation basÃ© sur les espaces
        return [Math]::Floor($indent.Length / 2)
    }

    return 0
}

# Fonction pour dÃ©tecter si une ligne est un titre de phase
function Test-PhaseTitle {
    param (
        [string]$Line
    )

    # Un titre de phase est gÃ©nÃ©ralement en majuscules, contient "Phase" ou est numÃ©rotÃ©
    # Ou commence par un mot en majuscules suivi de ":" (ex: "ANALYSE:")
    # Ou commence par un mot en majuscules suivi d'un chiffre (ex: "PHASE 1")
    # Ou est entiÃ¨rement en majuscules
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

    # Variables pour les mÃ©tadonnÃ©es
    $isPriority = $false
    $timeEstimate = ""

    # DÃ©tecter si la tÃ¢che est prioritaire (contient "prioritaire", "urgent", "important", "!" ou "*")
    if ($Line -match "(prioritaire|urgent|important|!|\*)" -and -not (Test-PhaseTitle -Line $Line)) {
        $isPriority = $true
        $Line = $Line -replace "\s*\(?(prioritaire|urgent|important)\)?\s*", ""
        $Line = $Line -replace "\s*[!*]+\s*", ""
    }

    # DÃ©tecter l'estimation de temps (format: (Xh), (X jours), (X-Y jours), etc.)
    if ($Line -match "\(\s*(\d+(?:-\d+)?\s*(?:h|heure|heures|jour|jours|semaine|semaines|mois))\s*\)") {
        $timeEstimate = $Matches[1]
        $Line = $Line -replace "\s*\(\s*\d+(?:-\d+)?\s*(?:h|heure|heures|jour|jours|semaine|semaines|mois)\s*\)\s*", ""
    }

    # Supprimer les puces ou numÃ©ros existants
    $Line = $Line -replace "^[-*â€¢]\s*", ""
    $Line = $Line -replace "^\d+\.\s*", ""

    # Construire la ligne formatÃ©e
    $formattedLine = ""
    $indent = "  " * $Level

    # Formater en fonction du niveau
    if ($Level -eq 0 -and (Test-PhaseTitle -Line $Line)) {
        # Niveau 0 : Phase principale
        $formattedLine = "$indent- [ ] **Phase: $Line**"
    } else {
        # Autres niveaux
        if ($isPriority) {
            $formattedLine = "$indent- [ ] **$Line** ðŸ”´"
        } else {
            $formattedLine = "$indent- [ ] $Line"
        }

        # Ajouter l'estimation de temps si prÃ©sente
        if (-not [string]::IsNullOrWhiteSpace($timeEstimate)) {
            $formattedLine += " ($timeEstimate)"
        }
    }

    return $formattedLine
}

# Initialiser le rÃ©sultat
$result = @()
$result += "## $SectionTitle"
$result += "**Complexite**: $Complexity"
$result += "**Temps estime**: $TimeEstimate"
$result += "**Progression**: 0%"
$result += ""

# Diviser le texte en lignes
$lines = $Text -split "`r?`n"

# Traiter chaque ligne
foreach ($line in $lines) {
    # Ignorer les lignes vides
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    # DÃ©tecter le niveau d'indentation
    $level = Get-IndentationLevel -Line $line

    # Formater la ligne
    $formattedLine = Format-LineByIndentation -Line $line -Level $level

    # Ajouter la ligne au rÃ©sultat
    if (-not [string]::IsNullOrWhiteSpace($formattedLine)) {
        $result += $formattedLine
    }
}

# Afficher le rÃ©sultat
$result -join "`n"
