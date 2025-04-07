# Script PowerShell pour installer toutes les dÃ©pendances du systÃ¨me de journal de bord

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃ©pertoire du projet
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
Write-Host "Installation du systÃ¨me de journal de bord RAG" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va installer toutes les dÃ©pendances nÃ©cessaires pour le systÃ¨me de journal de bord:"
Write-Host "1. DÃ©pendances Python pour le journal, l'analyse et l'intÃ©gration GitHub"
Write-Host "2. DÃ©pendances pour l'application web"
Write-Host "3. Configuration des rÃ©pertoires nÃ©cessaires"
Write-Host ""

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exÃ©cutÃ© en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalitÃ©s nÃ©cessitant des privilÃ¨ges d'administrateur seront ignorÃ©es." -ForegroundColor Yellow
    Write-Host ""
}

# 1. Installer les dÃ©pendances Python
Write-Section "Installation des dÃ©pendances Python"

# DÃ©pendances de base
Write-Host "Installation des dÃ©pendances de base..." -ForegroundColor Cyan
pip install requests python-dotenv

# DÃ©pendances pour l'analyse
Write-Host "Installation des dÃ©pendances pour l'analyse..." -ForegroundColor Cyan
pip install numpy pandas matplotlib wordcloud scikit-learn

# DÃ©pendances pour l'application web
Write-Host "Installation des dÃ©pendances pour l'application web..." -ForegroundColor Cyan
pip install fastapi uvicorn

# 2. CrÃ©er les rÃ©pertoires nÃ©cessaires
Write-Section "CrÃ©ation des rÃ©pertoires"
$JournalDir = Join-Path $ProjectDir "docs\journal_de_bord"
$EntriesDir = Join-Path $JournalDir "entries"
$AnalysisDir = Join-Path $JournalDir "analysis"
$GithubDir = Join-Path $JournalDir "github"
$DocsDir = Join-Path $ProjectDir "docs\documentation"

New-Item -ItemType Directory -Path $EntriesDir -Force | Out-Null
Write-Host "RÃ©pertoire des entrÃ©es crÃ©Ã©: $EntriesDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
Write-Host "RÃ©pertoire d'analyse crÃ©Ã©: $AnalysisDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
Write-Host "RÃ©pertoire GitHub crÃ©Ã©: $GithubDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
Write-Host "RÃ©pertoire de documentation crÃ©Ã©: $DocsDir" -ForegroundColor Green

# 3. Configurer l'intÃ©gration GitHub
Write-Section "Configuration de l'intÃ©gration GitHub"
$ConfigureGitHub = Read-Host "Voulez-vous configurer l'intÃ©gration GitHub maintenant? (O/N)"

if ($ConfigureGitHub -eq "O" -or $ConfigureGitHub -eq "o") {
    & "$CmdScriptsDir\setup-github-integration.ps1"
} else {
    Write-Host "Configuration de l'intÃ©gration GitHub ignorÃ©e." -ForegroundColor Yellow
    Write-Host "Vous pourrez la configurer plus tard avec: .\scripts\cmd\setup-github-integration.ps1" -ForegroundColor Yellow
}

# 4. ExÃ©cuter les analyses initiales
Write-Section "ExÃ©cution des analyses initiales"
$RunAnalysis = Read-Host "Voulez-vous exÃ©cuter les analyses initiales maintenant? (O/N)"

if ($RunAnalysis -eq "O" -or $RunAnalysis -eq "o") {
    & "$CmdScriptsDir\setup-journal-analysis.ps1"
} else {
    Write-Host "ExÃ©cution des analyses ignorÃ©e." -ForegroundColor Yellow
    Write-Host "Vous pourrez les exÃ©cuter plus tard avec: .\scripts\cmd\setup-journal-analysis.ps1" -ForegroundColor Yellow
}

# 5. Configurer les tÃ¢ches planifiÃ©es
Write-Section "Configuration des tÃ¢ches planifiÃ©es"

if ($isAdmin) {
    $ConfigureTasks = Read-Host "Voulez-vous configurer les tÃ¢ches planifiÃ©es maintenant? (O/N)"

    if ($ConfigureTasks -eq "O" -or $ConfigureTasks -eq "o") {
        & "$CmdScriptsDir\setup-journal-tasks.ps1"
        & "$CmdScriptsDir\setup-journal-sync-task.ps1"
    } else {
        Write-Host "Configuration des tÃ¢ches planifiÃ©es ignorÃ©e." -ForegroundColor Yellow
        Write-Host "Vous pourrez les configurer plus tard avec:" -ForegroundColor Yellow
        Write-Host "  .\scripts\cmd\setup-journal-tasks.ps1" -ForegroundColor Yellow
        Write-Host "  .\scripts\cmd\setup-journal-sync-task.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "La configuration des tÃ¢ches planifiÃ©es nÃ©cessite des privilÃ¨ges d'administrateur." -ForegroundColor Yellow
    Write-Host "ExÃ©cutez les scripts suivants en tant qu'administrateur pour configurer les tÃ¢ches:" -ForegroundColor Yellow
    Write-Host "  .\scripts\cmd\setup-journal-tasks.ps1" -ForegroundColor Yellow
    Write-Host "  .\scripts\cmd\setup-journal-sync-task.ps1" -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Installation terminÃ©e"
Write-Host "Le systÃ¨me de journal de bord RAG a Ã©tÃ© installÃ© avec succÃ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant:"
Write-Host "1. DÃ©marrer l'application web:" -ForegroundColor Cyan
Write-Host "   .\scripts\cmd\start-journal-web.ps1"
Write-Host ""
Write-Host "2. CrÃ©er des entrÃ©es de journal:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\journal_entry.py \"Titre de l`'entrÃ©e\" --tags tag1 tag2"
Write-Host ""
Write-Host "3. Analyser le journal:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\journal_analyzer.py --all"
Write-Host ""
Write-Host "4. IntÃ©grer avec GitHub:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\github_integration.py link-commits"
Write-Host "   python scripts\python\journal\github_integration.py link-issues"
Write-Host "   python scripts\python\journal\github_integration.py create-from-issue --issue NUMERO_ISSUE"
Write-Host ""
Write-Host "Profitez de votre systÃ¨me de journal de bord RAG!" -ForegroundColor Magenta
