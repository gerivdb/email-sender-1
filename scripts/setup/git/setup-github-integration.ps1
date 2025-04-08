# Script PowerShell pour configurer l'intÃ©gration GitHub avec le journal de bord

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"
$GitHookDir = Join-Path $ProjectDir ".git\hooks"

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
Write-Host "Configuration de l'intÃ©gration GitHub avec le journal de bord" -ForegroundColor Magenta
Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Installer les dÃ©pendances Python
Write-Section "Installation des dÃ©pendances Python"
pip install requests python-dotenv

# 2. CrÃ©er le fichier .env pour les informations GitHub
Write-Section "Configuration des informations GitHub"

$GithubToken = Read-Host "Entrez votre token GitHub (laissez vide pour ignorer)"
$GithubOwner = Read-Host "Entrez le propriÃ©taire du dÃ©pÃ´t GitHub (laissez vide pour ignorer)"
$GithubRepo = Read-Host "Entrez le nom du dÃ©pÃ´t GitHub (laissez vide pour ignorer)"

if ($GithubToken -or $GithubOwner -or $GithubRepo) {
    $EnvContent = @"
# Configuration GitHub pour l'intÃ©gration avec le journal de bord
GITHUB_TOKEN=$GithubToken
GITHUB_OWNER=$GithubOwner
GITHUB_REPO=$GithubRepo
"@

    $EnvPath = Join-Path $ProjectDir ".env"
    Set-Content -Path $EnvPath -Value $EnvContent -Encoding UTF8
    
    Write-Host "Fichier .env crÃ©Ã©: $EnvPath" -ForegroundColor Green
    Write-Host "Note: Ce fichier contient des informations sensibles, ne le partagez pas." -ForegroundColor Yellow
} else {
    Write-Host "Configuration GitHub ignorÃ©e." -ForegroundColor Yellow
}

# 3. Configurer le hook Git pre-commit
Write-Section "Configuration du hook Git pre-commit"

$PreCommitHookPath = Join-Path $GitHookDir "pre-commit"
$PreCommitHookContent = @"
#!/bin/bash
# Hook pre-commit pour l'intÃ©gration GitHub avec le journal de bord

# VÃ©rifier si des fichiers du journal ont Ã©tÃ© modifiÃ©s
JOURNAL_FILES=\$(git diff --cached --name-only | grep "docs/journal_de_bord/")

if [ -n "\$JOURNAL_FILES" ]; then
    echo "Mise Ã  jour des liens GitHub pour le journal..."
    
    # Lier les commits aux entrÃ©es du journal
    python scripts/python/journal/github_integration.py link-commits
    
    # Lier les issues aux entrÃ©es du journal
    python scripts/python/journal/github_integration.py link-issues
    
    # Ajouter les fichiers mis Ã  jour
    git add docs/journal_de_bord/entries/*.md
    git add docs/journal_de_bord/github/*.json
fi

# Continuer avec le commit
exit 0
"@

Set-Content -Path $PreCommitHookPath -Value $PreCommitHookContent -Encoding UTF8

# Rendre le hook exÃ©cutable
if (-not $isAdmin) {
    Write-Host "Note: Le script n'est pas exÃ©cutÃ© en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Vous devrez peut-Ãªtre rendre le hook exÃ©cutable manuellement." -ForegroundColor Yellow
} else {
    # Sous Windows, on ne peut pas facilement rendre un fichier exÃ©cutable comme sous Linux
    # Mais on peut crÃ©er un fichier .bat qui appelle le script bash
    $PreCommitBatPath = Join-Path $GitHookDir "pre-commit.bat"
    $PreCommitBatContent = @"
@echo off
bash "$PreCommitHookPath" %*
"@
    
    Set-Content -Path $PreCommitBatPath -Value $PreCommitBatContent -Encoding ASCII
    
    Write-Host "Hook Git pre-commit configurÃ©: $PreCommitHookPath" -ForegroundColor Green
    Write-Host "Fichier batch crÃ©Ã©: $PreCommitBatPath" -ForegroundColor Green
}

# 4. ExÃ©cuter une premiÃ¨re synchronisation
Write-Section "ExÃ©cution d'une premiÃ¨re synchronisation"

Write-Host "Liaison des commits aux entrÃ©es du journal..." -ForegroundColor Cyan
python "$PythonScriptsDir\github_integration.py" link-commits

Write-Host "Liaison des issues aux entrÃ©es du journal..." -ForegroundColor Cyan
python "$PythonScriptsDir\github_integration.py" link-issues

# Afficher un message de conclusion
Write-Section "Configuration terminÃ©e"
Write-Host "L'intÃ©gration GitHub avec le journal de bord a Ã©tÃ© configurÃ©e avec succÃ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant:"
Write-Host "1. CrÃ©er des entrÃ©es de journal Ã  partir d'issues GitHub:"
Write-Host "   python scripts/python/journal/github_integration.py create-from-issue --issue NUMERO_ISSUE"
Write-Host ""
Write-Host "2. Les commits et issues seront automatiquement liÃ©s aux entrÃ©es du journal lors des commits."
Write-Host ""
Write-Host "3. Pour forcer une mise Ã  jour des liens:"
Write-Host "   python scripts/python/journal/github_integration.py link-commits"
Write-Host "   python scripts/python/journal/github_integration.py link-issues"
