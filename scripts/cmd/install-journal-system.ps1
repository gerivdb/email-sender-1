# Script PowerShell pour installer toutes les dépendances du système de journal de bord

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts"
$CmdScriptsDir = Join-Path $ScriptsDir "cmd"

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
Write-Host "Installation du système de journal de bord RAG" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va installer toutes les dépendances nécessaires pour le système de journal de bord:"
Write-Host "1. Dépendances Python pour le journal, l'analyse et l'intégration GitHub"
Write-Host "2. Dépendances pour l'application web"
Write-Host "3. Configuration des répertoires nécessaires"
Write-Host ""

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exécuté en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalités nécessitant des privilèges d'administrateur seront ignorées." -ForegroundColor Yellow
    Write-Host ""
}

# 1. Installer les dépendances Python
Write-Section "Installation des dépendances Python"

# Dépendances de base
Write-Host "Installation des dépendances de base..." -ForegroundColor Cyan
pip install requests python-dotenv

# Dépendances pour l'analyse
Write-Host "Installation des dépendances pour l'analyse..." -ForegroundColor Cyan
pip install numpy pandas matplotlib wordcloud scikit-learn

# Dépendances pour l'application web
Write-Host "Installation des dépendances pour l'application web..." -ForegroundColor Cyan
pip install fastapi uvicorn

# 2. Créer les répertoires nécessaires
Write-Section "Création des répertoires"
$JournalDir = Join-Path $ProjectDir "docs\journal_de_bord"
$EntriesDir = Join-Path $JournalDir "entries"
$AnalysisDir = Join-Path $JournalDir "analysis"
$GithubDir = Join-Path $JournalDir "github"
$DocsDir = Join-Path $ProjectDir "docs\documentation"

New-Item -ItemType Directory -Path $EntriesDir -Force | Out-Null
Write-Host "Répertoire des entrées créé: $EntriesDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
Write-Host "Répertoire d'analyse créé: $AnalysisDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
Write-Host "Répertoire GitHub créé: $GithubDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
Write-Host "Répertoire de documentation créé: $DocsDir" -ForegroundColor Green

# 3. Configurer l'intégration GitHub
Write-Section "Configuration de l'intégration GitHub"
$ConfigureGitHub = Read-Host "Voulez-vous configurer l'intégration GitHub maintenant? (O/N)"

if ($ConfigureGitHub -eq "O" -or $ConfigureGitHub -eq "o") {
    & "$CmdScriptsDir\setup-github-integration.ps1"
} else {
    Write-Host "Configuration de l'intégration GitHub ignorée." -ForegroundColor Yellow
    Write-Host "Vous pourrez la configurer plus tard avec: .\scripts\cmd\setup-github-integration.ps1" -ForegroundColor Yellow
}

# 4. Exécuter les analyses initiales
Write-Section "Exécution des analyses initiales"
$RunAnalysis = Read-Host "Voulez-vous exécuter les analyses initiales maintenant? (O/N)"

if ($RunAnalysis -eq "O" -or $RunAnalysis -eq "o") {
    & "$CmdScriptsDir\setup-journal-analysis.ps1"
} else {
    Write-Host "Exécution des analyses ignorée." -ForegroundColor Yellow
    Write-Host "Vous pourrez les exécuter plus tard avec: .\scripts\cmd\setup-journal-analysis.ps1" -ForegroundColor Yellow
}

# 5. Configurer les tâches planifiées
Write-Section "Configuration des tâches planifiées"

if ($isAdmin) {
    $ConfigureTasks = Read-Host "Voulez-vous configurer les tâches planifiées maintenant? (O/N)"

    if ($ConfigureTasks -eq "O" -or $ConfigureTasks -eq "o") {
        & "$CmdScriptsDir\setup-journal-tasks.ps1"
        & "$CmdScriptsDir\setup-journal-sync-task.ps1"
    } else {
        Write-Host "Configuration des tâches planifiées ignorée." -ForegroundColor Yellow
        Write-Host "Vous pourrez les configurer plus tard avec:" -ForegroundColor Yellow
        Write-Host "  .\scripts\cmd\setup-journal-tasks.ps1" -ForegroundColor Yellow
        Write-Host "  .\scripts\cmd\setup-journal-sync-task.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "La configuration des tâches planifiées nécessite des privilèges d'administrateur." -ForegroundColor Yellow
    Write-Host "Exécutez les scripts suivants en tant qu'administrateur pour configurer les tâches:" -ForegroundColor Yellow
    Write-Host "  .\scripts\cmd\setup-journal-tasks.ps1" -ForegroundColor Yellow
    Write-Host "  .\scripts\cmd\setup-journal-sync-task.ps1" -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Installation terminée"
Write-Host "Le système de journal de bord RAG a été installé avec succès!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant:"
Write-Host "1. Démarrer l'application web:" -ForegroundColor Cyan
Write-Host "   .\scripts\cmd\start-journal-web.ps1"
Write-Host ""
Write-Host "2. Créer des entrées de journal:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\journal_entry.py \"Titre de l`'entrée\" --tags tag1 tag2"
Write-Host ""
Write-Host "3. Analyser le journal:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\journal_analyzer.py --all"
Write-Host ""
Write-Host "4. Intégrer avec GitHub:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\github_integration.py link-commits"
Write-Host "   python scripts\python\journal\github_integration.py link-issues"
Write-Host "   python scripts\python\journal\github_integration.py create-from-issue --issue NUMERO_ISSUE"
Write-Host ""
Write-Host "Profitez de votre système de journal de bord RAG!" -ForegroundColor Magenta
