# Script PowerShell pour installer toutes les dÃƒÂ©pendances du systÃƒÂ¨me de journal de bord

# VÃƒÂ©rifier si le script est exÃƒÂ©cutÃƒÂ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃƒÂ©pertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts"
$CmdScriptsDir = Join-Path $ScriptsDir "cmd"

# Fonction pour afficher un message de section

# Script PowerShell pour installer toutes les dÃƒÂ©pendances du systÃƒÂ¨me de journal de bord

# VÃƒÂ©rifier si le script est exÃƒÂ©cutÃƒÂ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃƒÂ©pertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts"
$CmdScriptsDir = Join-Path $ScriptsDir "cmd"

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
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal


    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Afficher un message d'introduction
Write-Host "Installation du systÃƒÂ¨me de journal de bord RAG" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va installer toutes les dÃƒÂ©pendances nÃƒÂ©cessaires pour le systÃƒÂ¨me de journal de bord:"
Write-Host "1. DÃƒÂ©pendances Python pour le journal, l'analyse et l'intÃƒÂ©gration GitHub"
Write-Host "2. DÃƒÂ©pendances pour l'application web"
Write-Host "3. Configuration des rÃƒÂ©pertoires nÃƒÂ©cessaires"
Write-Host ""

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exÃƒÂ©cutÃƒÂ© en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalitÃƒÂ©s nÃƒÂ©cessitant des privilÃƒÂ¨ges d'administrateur seront ignorÃƒÂ©es." -ForegroundColor Yellow
    Write-Host ""
}

# 1. Installer les dÃƒÂ©pendances Python
Write-Section "Installation des dÃƒÂ©pendances Python"

# DÃƒÂ©pendances de base
Write-Host "Installation des dÃƒÂ©pendances de base..." -ForegroundColor Cyan
pip install requests python-dotenv

# DÃƒÂ©pendances pour l'analyse
Write-Host "Installation des dÃƒÂ©pendances pour l'analyse..." -ForegroundColor Cyan
pip install numpy pandas matplotlib wordcloud scikit-learn

# DÃƒÂ©pendances pour l'application web
Write-Host "Installation des dÃƒÂ©pendances pour l'application web..." -ForegroundColor Cyan
pip install fastapi uvicorn

# 2. CrÃƒÂ©er les rÃƒÂ©pertoires nÃƒÂ©cessaires
Write-Section "CrÃƒÂ©ation des rÃƒÂ©pertoires"
$JournalDir = Join-Path $ProjectDir "docs\journal_de_bord"
$EntriesDir = Join-Path $JournalDir "entries"
$AnalysisDir = Join-Path $JournalDir "analysis"
$GithubDir = Join-Path $JournalDir "github"
$DocsDir = Join-Path $ProjectDir "docs\documentation"

New-Item -ItemType Directory -Path $EntriesDir -Force | Out-Null
Write-Host "RÃƒÂ©pertoire des entrÃƒÂ©es crÃƒÂ©ÃƒÂ©: $EntriesDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
Write-Host "RÃƒÂ©pertoire d'analyse crÃƒÂ©ÃƒÂ©: $AnalysisDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
Write-Host "RÃƒÂ©pertoire GitHub crÃƒÂ©ÃƒÂ©: $GithubDir" -ForegroundColor Green

New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
Write-Host "RÃƒÂ©pertoire de documentation crÃƒÂ©ÃƒÂ©: $DocsDir" -ForegroundColor Green

# 3. Configurer l'intÃƒÂ©gration GitHub
Write-Section "Configuration de l'intÃƒÂ©gration GitHub"
$ConfigureGitHub = Read-Host "Voulez-vous configurer l'intÃƒÂ©gration GitHub maintenant? (O/N)"

if ($ConfigureGitHub -eq "O" -or $ConfigureGitHub -eq "o") {
    & "..\..\D"
} else {
    Write-Host "Configuration de l'intÃƒÂ©gration GitHub ignorÃƒÂ©e." -ForegroundColor Yellow
    Write-Host "Vous pourrez la configurer plus tard avec: .\development\scripts\cmd\setup-github-integration.ps1" -ForegroundColor Yellow
}

# 4. ExÃƒÂ©cuter les analyses initiales
Write-Section "ExÃƒÂ©cution des analyses initiales"
$RunAnalysis = Read-Host "Voulez-vous exÃƒÂ©cuter les analyses initiales maintenant? (O/N)"

if ($RunAnalysis -eq "O" -or $RunAnalysis -eq "o") {
    & "..\..\D"
} else {
    Write-Host "ExÃƒÂ©cution des analyses ignorÃƒÂ©e." -ForegroundColor Yellow
    Write-Host "Vous pourrez les exÃƒÂ©cuter plus tard avec: .\development\scripts\cmd\setup-journal-analysis.ps1" -ForegroundColor Yellow
}

# 5. Configurer les tÃƒÂ¢ches planifiÃƒÂ©es
Write-Section "Configuration des tÃƒÂ¢ches planifiÃƒÂ©es"

if ($isAdmin) {
    $ConfigureTasks = Read-Host "Voulez-vous configurer les tÃƒÂ¢ches planifiÃƒÂ©es maintenant? (O/N)"

    if ($ConfigureTasks -eq "O" -or $ConfigureTasks -eq "o") {
        & "..\..\D"
        & "..\..\D"
    } else {
        Write-Host "Configuration des tÃƒÂ¢ches planifiÃƒÂ©es ignorÃƒÂ©e." -ForegroundColor Yellow
        Write-Host "Vous pourrez les configurer plus tard avec:" -ForegroundColor Yellow
        Write-Host "  .\development\scripts\cmd\setup-journal-tasks.ps1" -ForegroundColor Yellow
        Write-Host "  .\development\scripts\cmd\setup-journal-sync-task.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "La configuration des tÃƒÂ¢ches planifiÃƒÂ©es nÃƒÂ©cessite des privilÃƒÂ¨ges d'administrateur." -ForegroundColor Yellow
    Write-Host "ExÃƒÂ©cutez les scripts suivants en tant qu'administrateur pour configurer les tÃƒÂ¢ches:" -ForegroundColor Yellow
    Write-Host "  .\development\scripts\cmd\setup-journal-tasks.ps1" -ForegroundColor Yellow
    Write-Host "  .\development\scripts\cmd\setup-journal-sync-task.ps1" -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Installation terminÃƒÂ©e"
Write-Host "Le systÃƒÂ¨me de journal de bord RAG a ÃƒÂ©tÃƒÂ© installÃƒÂ© avec succÃƒÂ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant:"
Write-Host "1. DÃƒÂ©marrer l'application web:" -ForegroundColor Cyan
Write-Host "   .\development\scripts\cmd\start-journal-web.ps1"
Write-Host ""
Write-Host "2. CrÃƒÂ©er des entrÃƒÂ©es de journal:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\journal_entry.py \"Titre de l`'entrÃƒÂ©e\" --tags tag1 tag2"
Write-Host ""
Write-Host "3. Analyser le journal:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\journal_analyzer.py --all"
Write-Host ""
Write-Host "4. IntÃƒÂ©grer avec GitHub:" -ForegroundColor Cyan
Write-Host "   python scripts\python\journal\github_integration.py link-commits"
Write-Host "   python scripts\python\journal\github_integration.py link-issues"
Write-Host "   python scripts\python\journal\github_integration.py create-from-issue --issue NUMERO_ISSUE"
Write-Host ""
Write-Host "Profitez de votre systÃƒÂ¨me de journal de bord RAG!" -ForegroundColor Magenta


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
