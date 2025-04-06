# Script PowerShell pour configurer et démarrer l'application web du journal de bord

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section
function Write-Section {
    param (
        [string]$Title
    )

    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Afficher un message d'introduction
Write-Host "Configuration et démarrage de l'application web du journal de bord" -ForegroundColor Magenta
Write-Host "=============================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Installer les dépendances Python
Write-Section "Installation des dépendances Python"

# Dépendances pour l'API web
Write-Host "Installation des dépendances pour l'API web..." -ForegroundColor Cyan
pip install fastapi uvicorn

# Dépendances pour l'analyse des données
Write-Host "Installation des dépendances pour l'analyse des données..." -ForegroundColor Cyan
pip install numpy pandas matplotlib wordcloud scikit-learn

# 2. Vérifier que les répertoires nécessaires existent
Write-Section "Vérification des répertoires"
$JournalDir = Join-Path $ProjectDir "docs\journal_de_bord"
$EntriesDir = Join-Path $JournalDir "entries"
$AnalysisDir = Join-Path $JournalDir "analysis"
$GithubDir = Join-Path $JournalDir "github"

if (-not (Test-Path $EntriesDir)) {
    New-Item -ItemType Directory -Path $EntriesDir -Force | Out-Null
    Write-Host "Répertoire des entrées créé: $EntriesDir" -ForegroundColor Green
}

if (-not (Test-Path $AnalysisDir)) {
    New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
    Write-Host "Répertoire d'analyse créé: $AnalysisDir" -ForegroundColor Green
}

if (-not (Test-Path $GithubDir)) {
    New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
    Write-Host "Répertoire GitHub créé: $GithubDir" -ForegroundColor Green
}

# 3. Générer les analyses si elles n'existent pas
Write-Section "Génération des analyses"
$TermFreqFile = Join-Path $AnalysisDir "term_frequency.json"
$TagEvolutionFile = Join-Path $AnalysisDir "tag_evolution.png"
$TopicTrendsFile = Join-Path $AnalysisDir "topic_trends.png"
$ClustersFile = Join-Path $AnalysisDir "clusters.json"

if (-not (Test-Path $TermFreqFile) -or -not (Test-Path $TagEvolutionFile) -or -not (Test-Path $TopicTrendsFile) -or -not (Test-Path $ClustersFile)) {
    Write-Host "Exécution des analyses..." -ForegroundColor Cyan
    python "$PythonScriptsDir\journal_analyzer.py" --all
}

# 4. Démarrer l'application web
Write-Section "Démarrage de l'application web"
$Port = 8000
$HostName = "localhost"

Write-Host "L'application web sera accessible à l'adresse: http://${HostName}:$Port" -ForegroundColor Green
Write-Host "Appuyez sur Ctrl+C pour arrêter l'application." -ForegroundColor Yellow
Write-Host ""

# Démarrer l'application web
Set-Location $ProjectDir
python "$PythonScriptsDir\web_app.py"
