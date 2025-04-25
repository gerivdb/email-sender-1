# Script PowerShell pour configurer et dÃ©marrer l'application web du journal de bord

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section

# Script PowerShell pour configurer et dÃ©marrer l'application web du journal de bord

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section
function Write-Section {
    param (
        [string]$Title
    )

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


    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Afficher un message d'introduction
Write-Host "Configuration et dÃ©marrage de l'application web du journal de bord" -ForegroundColor Magenta
Write-Host "=============================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Installer les dÃ©pendances Python
Write-Section "Installation des dÃ©pendances Python"

# DÃ©pendances pour l'API web
Write-Host "Installation des dÃ©pendances pour l'API web..." -ForegroundColor Cyan
pip install fastapi uvicorn

# DÃ©pendances pour l'analyse des donnÃ©es
Write-Host "Installation des dÃ©pendances pour l'analyse des donnÃ©es..." -ForegroundColor Cyan
pip install numpy pandas matplotlib wordcloud scikit-learn

# 2. VÃ©rifier que les rÃ©pertoires nÃ©cessaires existent
Write-Section "VÃ©rification des rÃ©pertoires"
$JournalDir = Join-Path $ProjectDir "docs\journal_de_bord"
$EntriesDir = Join-Path $JournalDir "entries"
$AnalysisDir = Join-Path $JournalDir "analysis"
$GithubDir = Join-Path $JournalDir "github"

if (-not (Test-Path $EntriesDir)) {
    New-Item -ItemType Directory -Path $EntriesDir -Force | Out-Null
    Write-Host "RÃ©pertoire des entrÃ©es crÃ©Ã©: $EntriesDir" -ForegroundColor Green
}

if (-not (Test-Path $AnalysisDir)) {
    New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
    Write-Host "RÃ©pertoire d'analyse crÃ©Ã©: $AnalysisDir" -ForegroundColor Green
}

if (-not (Test-Path $GithubDir)) {
    New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
    Write-Host "RÃ©pertoire GitHub crÃ©Ã©: $GithubDir" -ForegroundColor Green
}

# 3. GÃ©nÃ©rer les analyses si elles n'existent pas
Write-Section "GÃ©nÃ©ration des analyses"
$TermFreqFile = Join-Path $AnalysisDir "term_frequency.json"
$TagEvolutionFile = Join-Path $AnalysisDir "tag_evolution.png"
$TopicTrendsFile = Join-Path $AnalysisDir "topic_trends.png"
$ClustersFile = Join-Path $AnalysisDir "clusters.json"

if (-not (Test-Path $TermFreqFile) -or -not (Test-Path $TagEvolutionFile) -or -not (Test-Path $TopicTrendsFile) -or -not (Test-Path $ClustersFile)) {
    Write-Host "ExÃ©cution des analyses..." -ForegroundColor Cyan
    python "$PythonScriptsDir\journal_analyzer.py" --all
}

# 4. DÃ©marrer l'application web
Write-Section "DÃ©marrage de l'application web"
$Port = 8000
$HostName = "localhost"

Write-Host "L'application web sera accessible Ã  l'adresse: http://${HostName}:$Port" -ForegroundColor Green
Write-Host "Appuyez sur Ctrl+C pour arrÃªter l'application." -ForegroundColor Yellow
Write-Host ""

# DÃ©marrer l'application web
Set-Location $ProjectDir
python "$PythonScriptsDir\web_app.py"

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
