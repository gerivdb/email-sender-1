# Create-JournalEntry-Enhanced.ps1
# Script ameliore pour creer des entrees de journal avec analyse des erreurs

# Parametres

# Create-JournalEntry-Enhanced.ps1
# Script ameliore pour creer des entrees de journal avec analyse des erreurs

# Parametres
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
    [string]$Title = "Entree de journal",

    [Parameter(Mandatory = $false)]
    [string]$JournalFile = "journal.md",

    [Parameter(Mandatory = $false)]
    [string]$LogDirectory = "logs",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeErrorAnalysis,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRoadmapProgress
)

# Fonction pour obtenir la date et l'heure actuelles
function Get-FormattedDateTime {
    return Get-Date -Format "yyyy-MM-dd HH:mm"
}

# Fonction pour creer un template d'entree de journal
function Get-JournalEntryTemplate {
    param (
        [string]$Title
    )

    $dateTime = Get-FormattedDateTime

    $template = @"
# $Title

*Date: $dateTime*

## Actions realisees

- Action 1
- Action 2
- Action 3

## Resultats obtenus

- Resultat 1
- Resultat 2
- Resultat 3

## Problemes rencontres

- Probleme 1
- Probleme 2
- Probleme 3

## Solutions appliquees

- Solution 1
- Solution 2
- Solution 3

### Lecons apprises

- Lecon 1
- Lecon 2
- Lecon 3

"@

    return $template
}

# Fonction pour ajouter l'analyse des erreurs
function Add-ErrorAnalysis {
    param (
        [string]$Template,
        [string]$LogDirectory
    )

    # Appeler le script d'analyse des erreurs
    $errorAnalysisScript = Join-Path -Path $PSScriptRoot -ChildPath "Add-ErrorAnalysisToJournal.ps1"

    if (Test-Path -Path $errorAnalysisScript) {
        # Creer un fichier temporaire pour le template
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value $Template

        # Executer le script d'analyse des erreurs
        & $errorAnalysisScript -JournalFile $tempFile -LogDirectory $LogDirectory

        # Lire le template mis a jour
        $updatedTemplate = Get-Content -Path $tempFile -Raw

        # Supprimer le fichier temporaire
        Remove-Item -Path $tempFile -Force

        return $updatedTemplate
    }
    else {
        Write-Warning "Script d'analyse des erreurs non trouve: $errorAnalysisScript"
        return $Template
    }
}

# Fonction pour ajouter la progression de la roadmap
function Add-RoadmapProgress {
    param (
        [string]$Template
    )

    # Trouver le fichier roadmap
    $roadmapFile = "Roadmap\roadmap_perso.md"""

    if (Test-Path -Path $roadmapFile) {
        $roadmapContent = Get-Content -Path $roadmapFile -Raw

        # Extraire les sections de la roadmap
        $sections = [regex]::Matches($roadmapContent, "(?m)^## \d+[^#]*?(?=^## |\z)")

        $progressSection = "### Progression de la roadmap`n`n"

        foreach ($section in $sections) {
            $sectionText = $section.Value

            # Extraire le titre de la section
            if ($sectionText -match "^## (\d+\.\w*)\s+(.*)") {
                $sectionNumber = $matches[1]
                $sectionTitle = $matches[2]

                # Extraire la progression
                if ($sectionText -match "\*\*Progression\*\*:\s*(\d+)%") {
                    $progress = $matches[1]
                    $progressSection += "- Section $sectionNumber ($sectionTitle): $progress%`n"
                }
            }
        }

        # Ajouter la section de progression au template
        $Template += "`n$progressSection"
    }
    else {
        Write-Warning "Fichier roadmap non trouve: $roadmapFile"
    }

    return $Template
}

# Fonction principale
function Main {
    # Creer le template d'entree de journal
    $template = Get-JournalEntryTemplate -Title $Title

    # Ajouter l'analyse des erreurs si demande
    if ($IncludeErrorAnalysis) {
        $template = Add-ErrorAnalysis -Template $template -LogDirectory $LogDirectory
    }

    # Ajouter la progression de la roadmap si demande
    if ($IncludeRoadmapProgress) {
        $template = Add-RoadmapProgress -Template $template
    }

    # Enregistrer l'entree de journal
    if ([string]::IsNullOrEmpty($JournalFile)) {
        # Afficher le template
        Write-Host $template
    }
    else {
        # Enregistrer dans un fichier
        Set-Content -Path $JournalFile -Value $template
        Write-Host "Entree de journal creee: $JournalFile" -ForegroundColor Green
    }
}

# Executer la fonction principale
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
