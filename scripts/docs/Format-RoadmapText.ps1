# Format-RoadmapText.ps1
# Script pour reformater du texte en format roadmap avec phases, tâches et sous-tâches

# Paramètres du script

# Format-RoadmapText.ps1
# Script pour reformater du texte en format roadmap avec phases, tâches et sous-tâches

# Paramètres du script
param (
    [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}
try {
    # Script principal
]
    [string]$InputFile = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "",

    [Parameter(Mandatory = $false)]
    [string]$Text = "",

    [Parameter(Mandatory = $false)]
    [string]$SectionTitle = "Nouvelle section",

    [Parameter(Mandatory = $false)]
    [string]$Complexity = "Moyenne",

    [Parameter(Mandatory = $false)]
    [string]$TimeEstimate = "3-5 jours",

    [Parameter(Mandatory = $false)]
    [switch]$AppendToRoadmap,

    [Parameter(Mandatory = $false)]
    [string]$RoadmapFile = ""Roadmap\roadmap_perso.md"",

    [Parameter(Mandatory = $false)]
    [int]$SectionNumber = 0,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

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

# Fonction pour détecter le niveau d'indentation d'une ligne
function Get-IndentationLevel {
    param (
        [string]$Line
    )

    # Compter le nombre d'espaces ou de tabulations au début de la ligne
    if ($Line -match "^(\s*)(.*)$") {
        $indent = $matches[1]
        $content = $matches[2]

        # Si la ligne commence par un tiret, c'est déjà une liste
        if ($content -match "^[-*]") {
            return $indent.Length
        }

        # Sinon, on considère que c'est un niveau d'indentation basé sur les espaces
        return [Math]::Floor($indent.Length / 2)
    }

    return 0
}

# Fonction pour détecter si une ligne est un titre de phase
function Test-PhaseTitle {
    param (
        [string]$Line
    )

    # Un titre de phase est généralement en majuscules, contient "Phase" ou est numéroté
    return $Line -match "^(PHASE|Phase|\d+\.|\*\*)" -or $Line -match "^[A-Z][A-Z\s]+$"
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

    # Supprimer les puces ou numéros existants
    $Line = $Line -replace "^[-*•]\s*", ""
    $Line = $Line -replace "^\d+\.\s*", ""

    # Formater en fonction du niveau
    switch ($Level) {
        0 {
            # Niveau 0 : Phase principale
            if (Test-PhaseTitle -Line $Line) {
                return "- [ ] **Phase: $Line**"
            } else {
                return "- [ ] $Line"
            }
        }
        1 { return "  - [ ] $Line" }
        2 { return "    - [ ] $Line" }
        3 { return "      - [ ] $Line" }
        default { return ("  " * $Level) + "- [ ] $Line" }
    }
}

# Fonction pour reformater le texte en format roadmap
function Format-TextToRoadmap {
    param (
        [string]$InputText,
        [string]$SectionTitle,
        [string]$Complexity,
        [string]$TimeEstimate
    )

    # Initialiser le résultat
    $result = @()
    $result += "## $SectionTitle"
    $result += "**Complexite**: $Complexity"
    $result += "**Temps estime**: $TimeEstimate"
    $result += "**Progression**: 0%"

    # Diviser le texte en lignes
    $lines = $InputText -split "`r?`n"

    # Traiter chaque ligne
    foreach ($line in $lines) {
        # Ignorer les lignes vides
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Détecter le niveau d'indentation
        $level = Get-IndentationLevel -Line $line

        # Formater la ligne
        $formattedLine = Format-LineByIndentation -Line $line -Level $level

        # Ajouter la ligne au résultat
        if (-not [string]::IsNullOrWhiteSpace($formattedLine)) {
            $result += $formattedLine
        }
    }

    # Ajouter une ligne vide à la fin
    $result += ""

    return $result -join "`n"
}

# Fonction pour insérer une section dans la roadmap
function Insert-SectionInRoadmap {
    param (
        [string]$RoadmapPath,
        [string]$SectionContent,
        [int]$SectionNumber,
        [switch]$WhatIf
    )

    # Vérifier que le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Fichier roadmap non trouve: $RoadmapPath"
        return $false
    }

    # Lire le contenu de la roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw

    # Diviser le contenu en lignes
    $roadmapLines = $roadmapContent -split "`r?`n"

    # Trouver les sections existantes
    $sectionIndices = @()
    for ($i = 0; $i -lt $roadmapLines.Count; $i++) {
        if ($roadmapLines[$i] -match "^## \d+") {
            $sectionIndices += $i
        }
    }

    # Si aucune section n'est trouvée, ajouter à la fin
    if ($sectionIndices.Count -eq 0) {
        $newContent = $roadmapContent + "`n`n" + $SectionContent

        if ($WhatIf) {
            Write-Host "WhatIf: Le contenu serait ajouté à la fin du fichier roadmap" -ForegroundColor Yellow
            return $true
        } else {
            Set-Content -Path $RoadmapPath -Value $newContent
            Write-Host "Le contenu a été ajouté à la fin du fichier roadmap" -ForegroundColor Green
            return $true
        }
    }

    # Si le numéro de section est 0 ou supérieur au nombre de sections, ajouter à la fin
    if ($SectionNumber -le 0 -or $SectionNumber -gt $sectionIndices.Count) {
        $lastSectionIndex = $sectionIndices[-1]

        # Trouver la fin de la dernière section
        $endOfLastSection = $roadmapLines.Count - 1
        for ($i = $lastSectionIndex + 1; $i -lt $roadmapLines.Count; $i++) {
            if ($roadmapLines[$i] -match "^## ") {
                $endOfLastSection = $i - 1
                break
            }
        }

        # Insérer la nouvelle section après la dernière section
        $newRoadmapLines = $roadmapLines[0..$endOfLastSection]
        $newRoadmapLines += ""
        $newRoadmapLines += $SectionContent -split "`r?`n"
        $newRoadmapLines += $roadmapLines[($endOfLastSection + 1)..($roadmapLines.Count - 1)]

        $newContent = $newRoadmapLines -join "`n"

        if ($WhatIf) {
            Write-Host "WhatIf: La nouvelle section serait ajoutée après la section $($sectionIndices.Count)" -ForegroundColor Yellow
            return $true
        } else {
            Set-Content -Path $RoadmapPath -Value $newContent
            Write-Host "La nouvelle section a été ajoutée après la section $($sectionIndices.Count)" -ForegroundColor Green
            return $true
        }
    }

    # Insérer la nouvelle section à la position spécifiée
    $insertIndex = $sectionIndices[$SectionNumber - 1]

    # Trouver la fin de la section précédente
    $endOfPrevSection = $insertIndex - 1

    # Insérer la nouvelle section
    $newRoadmapLines = $roadmapLines[0..$endOfPrevSection]
    $newRoadmapLines += ""
    $newRoadmapLines += $SectionContent -split "`r?`n"
    $newRoadmapLines += $roadmapLines[$insertIndex..($roadmapLines.Count - 1)]

    $newContent = $newRoadmapLines -join "`n"

    if ($WhatIf) {
        Write-Host "WhatIf: La nouvelle section serait insérée avant la section $SectionNumber" -ForegroundColor Yellow
        return $true
    } else {
        Set-Content -Path $RoadmapPath -Value $newContent
        Write-Host "La nouvelle section a été insérée avant la section $SectionNumber" -ForegroundColor Green
        return $true
    }
}

# Fonction principale
function Main {
    # Afficher les paramètres
    Write-Host "=== Formatage de texte en format roadmap ===" -ForegroundColor Cyan
    Write-Host "Fichier d'entrée: $InputFile"
    Write-Host "Fichier de sortie: $OutputFile"
    Write-Host "Titre de la section: $SectionTitle"
    Write-Host "Complexité: $Complexity"
    Write-Host "Temps estimé: $TimeEstimate"
    Write-Host "Ajouter à la roadmap: $AppendToRoadmap"
    Write-Host "Fichier roadmap: $RoadmapFile"
    Write-Host "Numéro de section: $SectionNumber"
    Write-Host "WhatIf: $WhatIf"
    Write-Host ""

    # Obtenir le texte à formater
    $textToFormat = ""

    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        $textToFormat = $Text
    } elseif (-not [string]::IsNullOrWhiteSpace($InputFile) -and (Test-Path -Path $InputFile)) {
        $textToFormat = Get-Content -Path $InputFile -Raw
    } else {
        # Demander à l'utilisateur de saisir le texte
        Write-Host "Veuillez saisir le texte à formater (terminez par une ligne vide):" -ForegroundColor Yellow
        $lines = @()
        $line = Read-Host
        while (-not [string]::IsNullOrWhiteSpace($line)) {
            $lines += $line
            $line = Read-Host
        }
        $textToFormat = $lines -join "`n"
    }

    # Vérifier que le texte n'est pas vide
    if ([string]::IsNullOrWhiteSpace($textToFormat)) {
        Write-Error "Aucun texte à formater"
        return
    }

    # Formater le texte
    $formattedText = Format-TextToRoadmap -InputText $textToFormat -SectionTitle $SectionTitle -Complexity $Complexity -TimeEstimate $TimeEstimate

    # Afficher le texte formaté
    Write-Host "Texte formaté:" -ForegroundColor Yellow
    Write-Host $formattedText

    # Enregistrer le texte formaté dans un fichier
    if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
        if ($WhatIf) {
            Write-Host "WhatIf: Le texte formaté serait enregistré dans le fichier $OutputFile" -ForegroundColor Yellow
        } else {
            Set-Content -Path $OutputFile -Value $formattedText
            Write-Host "Le texte formaté a été enregistré dans le fichier $OutputFile" -ForegroundColor Green
        }
    }

    # Ajouter le texte formaté à la roadmap
    if ($AppendToRoadmap) {
        $roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath $RoadmapFile

        if (Insert-SectionInRoadmap -RoadmapPath $roadmapPath -SectionContent $formattedText -SectionNumber $SectionNumber -WhatIf:$WhatIf) {
            if (-not $WhatIf) {
                Write-Host "Le texte formaté a été ajouté à la roadmap" -ForegroundColor Green
            }
        } else {
            Write-Error "Erreur lors de l'ajout du texte formaté à la roadmap"
        }
    }
}

# Exécuter la fonction principale
Main

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
