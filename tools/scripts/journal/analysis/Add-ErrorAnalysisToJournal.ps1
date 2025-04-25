# Add-ErrorAnalysisToJournal.ps1
# Script pour ajouter l'analyse des erreurs recurrentes au processus de creation d'entrees de journal

# Parametres

# Add-ErrorAnalysisToJournal.ps1
# Script pour ajouter l'analyse des erreurs recurrentes au processus de creation d'entrees de journal

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
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$JournalFile = "journal.md",

    [Parameter(Mandatory = $false)]
    [string]$LogDirectory = "logs",

    [Parameter(Mandatory = $false)]
    [int]$MaxErrorsToShow = 5,

    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeScripts
)

# Fonction pour extraire les erreurs des logs recents
function Get-RecentErrors {
    param (
        [string]$LogDirectory,
        [int]$DaysToLookBack = 7
    )

    if (-not (Test-Path -Path $LogDirectory)) {
        Write-Warning "Le repertoire de logs $LogDirectory n'existe pas."
        return @{}
    }

    $cutoffDate = (Get-Date).AddDays(-$DaysToLookBack)
    $errorPatterns = @{}

    # Trouver les fichiers de log recents
    $logFiles = Get-ChildItem -Path $LogDirectory -Filter "*.log" -Recurse |
                Where-Object { $_.LastWriteTime -ge $cutoffDate }

    if ($logFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de log recent trouve."
        return @{}
    }

    # Patterns d'erreur a rechercher
    $patterns = @(
        "Exception",
        "Error",
        "Failed",
        "Cannot find",
        "Access denied",
        "is not recognized",
        "Unexpected",
        "Invalid",
        "Timeout",
        "Not found",
        "Encoding",
        "Character",
        "Unicode",
        "UTF",
        "Process",
        "Dependency"
    )

    # Analyser chaque fichier de log
    foreach ($logFile in $logFiles) {
        $content = Get-Content -Path $logFile.FullName -Raw

        foreach ($pattern in $patterns) {
            $regexMatches = [regex]::Matches($content, "(?i).*$pattern.*")

            foreach ($match in $regexMatches) {
                $errorLine = $match.Value.Trim()

                # Categoriser l'erreur
                $errorType = "Autre"

                if ($errorLine -match "Encoding|Character|Unicode|UTF") {
                    $errorType = "Encodage"
                }
                elseif ($errorLine -match "Exception|Error|Failed") {
                    $errorType = "Exception"
                }
                elseif ($errorLine -match "Cannot find|Not found") {
                    $errorType = "Fichier manquant"
                }
                elseif ($errorLine -match "Access denied") {
                    $errorType = "Permission"
                }
                elseif ($errorLine -match "Timeout") {
                    $errorType = "Timeout"
                }
                elseif ($errorLine -match "Process") {
                    $errorType = "Processus"
                }
                elseif ($errorLine -match "Dependency") {
                    $errorType = "Dependance"
                }

                # Ajouter au dictionnaire
                if (-not $errorPatterns.ContainsKey($errorType)) {
                    $errorPatterns[$errorType] = @()
                }

                if (-not $errorPatterns[$errorType].Contains($errorLine)) {
                    $errorPatterns[$errorType] += $errorLine
                }
            }
        }
    }

    return $errorPatterns
}

# Fonction pour generer la section d'analyse des erreurs
function Get-ErrorAnalysisSection {
    param (
        [hashtable]$ErrorPatterns,
        [int]$MaxErrorsToShow
    )

    if ($ErrorPatterns.Count -eq 0) {
        return "Aucune erreur recurrente identifiee."
    }

    $analysisText = "### Analyse des erreurs recurrentes`n`n"

    foreach ($errorType in $ErrorPatterns.Keys) {
        $analysisText += "#### $errorType`n`n"

        $errors = $ErrorPatterns[$errorType]
        $errorCount = [Math]::Min($errors.Count, $MaxErrorsToShow)

        for ($i = 0; $i -lt $errorCount; $i++) {
            $analysisText += "- $($errors[$i])\n"
        }

        if ($errors.Count -gt $MaxErrorsToShow) {
            $analysisText += "- ... et $($errors.Count - $MaxErrorsToShow) autres erreurs similaires`n"
        }

        $analysisText += "`n"
    }

    # Ajouter des recommandations basees sur les types d'erreurs
    $analysisText += "#### Recommandations`n`n"

    if ($ErrorPatterns.ContainsKey("Encodage")) {
        $analysisText += "- **Problemes d'encodage**: Standardiser l'encodage UTF-8 avec BOM pour tous les scripts`n"
    }

    if ($ErrorPatterns.ContainsKey("Exception") -or $ErrorPatterns.ContainsKey("Autre")) {
        $analysisText += "- **Gestion d'erreurs**: Ameliorer la gestion des exceptions avec des blocs try/catch`n"
    }

    if ($ErrorPatterns.ContainsKey("Fichier manquant")) {
        $analysisText += "- **Fichiers manquants**: Verifier l'existence des fichiers avant de les utiliser`n"
    }

    if ($ErrorPatterns.ContainsKey("Permission")) {
        $analysisText += "- **Problemes de permission**: Verifier les droits d'acces avant les operations sur les fichiers`n"
    }

    if ($ErrorPatterns.ContainsKey("Timeout")) {
        $analysisText += "- **Timeouts**: Implementer des mecanismes de timeout et de retry`n"
    }

    if ($ErrorPatterns.ContainsKey("Processus")) {
        $analysisText += "- **Gestion des processus**: Ameliorer la gestion des processus avec des timeouts et nettoyage`n"
    }

    if ($ErrorPatterns.ContainsKey("Dependance")) {
        $analysisText += "- **Gestion des dependances**: Verifier les dependances avant de les utiliser`n"
    }

    return $analysisText
}

# Fonction pour ajouter l'analyse au template de journal
function Add-AnalysisToJournalTemplate {
    param (
        [string]$TemplateContent,
        [string]$AnalysisSection
    )

    # Verifier si le template contient deja une section d'analyse
    if ($TemplateContent -match "### Analyse des erreurs recurrentes") {
        # Remplacer la section existante
        $TemplateContent = $TemplateContent -replace "### Analyse des erreurs recurrentes[\s\S]*?(?=###|$)", $AnalysisSection
    }
    else {
        # Ajouter la section apres "### Lecons apprises"
        $TemplateContent = $TemplateContent -replace "(### Lecons apprises[\s\S]*?)(?=###|$)", "`$1`n`n$AnalysisSection"
    }

    return $TemplateContent
}

# Fonction principale
function Main {
    # Verifier si le fichier journal existe
    if (-not (Test-Path -Path $JournalFile)) {
        Write-Error "Fichier journal non trouve: $JournalFile"
        exit 1
    }

    # Obtenir les erreurs recentes
    Write-Host "Analyse des erreurs recentes..." -ForegroundColor Cyan
    $errorPatterns = Get-RecentErrors -LogDirectory $LogDirectory

    # Generer la section d'analyse
    $analysisSection = Get-ErrorAnalysisSection -ErrorPatterns $errorPatterns -MaxErrorsToShow $MaxErrorsToShow

    # Lire le contenu du journal
    $journalContent = Get-Content -Path $JournalFile -Raw

    # Ajouter l'analyse au journal
    $updatedContent = Add-AnalysisToJournalTemplate -TemplateContent $journalContent -AnalysisSection $analysisSection

    # Enregistrer le journal mis a jour
    Set-Content -Path $JournalFile -Value $updatedContent

    Write-Host "Analyse des erreurs ajoutee au journal: $JournalFile" -ForegroundColor Green
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
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
