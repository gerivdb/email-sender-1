# Script PowerShell pour configurer l'intÃƒÂ©gration GitHub avec le journal de bord

# VÃƒÂ©rifier si le script est exÃƒÂ©cutÃƒÂ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃƒÂ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"
$GitHookDir = Join-Path $ProjectDir ".git\hooks"

# Fonction pour afficher un message de section

# Script PowerShell pour configurer l'intÃƒÂ©gration GitHub avec le journal de bord

# VÃƒÂ©rifier si le script est exÃƒÂ©cutÃƒÂ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃƒÂ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"
$GitHookDir = Join-Path $ProjectDir ".git\hooks"

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
Write-Host "Configuration de l'intÃƒÂ©gration GitHub avec le journal de bord" -ForegroundColor Magenta
Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Installer les dÃƒÂ©pendances Python
Write-Section "Installation des dÃƒÂ©pendances Python"
pip install requests python-dotenv

# 2. CrÃƒÂ©er le fichier .env pour les informations GitHub
Write-Section "Configuration des informations GitHub"

$GithubToken = Read-Host "Entrez votre token GitHub (laissez vide pour ignorer)"
$GithubOwner = Read-Host "Entrez le propriÃƒÂ©taire du dÃƒÂ©pÃƒÂ´t GitHub (laissez vide pour ignorer)"
$GithubRepo = Read-Host "Entrez le nom du dÃƒÂ©pÃƒÂ´t GitHub (laissez vide pour ignorer)"

if ($GithubToken -or $GithubOwner -or $GithubRepo) {
    $EnvContent = @"
# Configuration GitHub pour l'intÃƒÂ©gration avec le journal de bord
GITHUB_TOKEN=$GithubToken
GITHUB_OWNER=$GithubOwner
GITHUB_REPO=$GithubRepo
"@

    $EnvPath = Join-Path $ProjectDir ".env"
    Set-Content -Path $EnvPath -Value $EnvContent -Encoding UTF8
    
    Write-Host "Fichier .env crÃƒÂ©ÃƒÂ©: $EnvPath" -ForegroundColor Green
    Write-Host "Note: Ce fichier contient des informations sensibles, ne le partagez pas." -ForegroundColor Yellow
} else {
    Write-Host "Configuration GitHub ignorÃƒÂ©e." -ForegroundColor Yellow
}

# 3. Configurer le hook Git pre-commit
Write-Section "Configuration du hook Git pre-commit"

$PreCommitHookPath = Join-Path $GitHookDir "pre-commit"
$PreCommitHookContent = @"
#!/bin/bash
# Hook pre-commit pour l'intÃƒÂ©gration GitHub avec le journal de bord

# VÃƒÂ©rifier si des fichiers du journal ont ÃƒÂ©tÃƒÂ© modifiÃƒÂ©s
JOURNAL_FILES=\$(git diff --cached --name-only | grep "docs/journal_de_bord/")

if [ -n "\$JOURNAL_FILES" ]; then
    echo "Mise ÃƒÂ  jour des liens GitHub pour le journal..."
    
    # Lier les commits aux entrÃƒÂ©es du journal
    python development/scripts/python/journal/github_integration.py link-commits
    
    # Lier les issues aux entrÃƒÂ©es du journal
    python development/scripts/python/journal/github_integration.py link-issues
    
    # Ajouter les fichiers mis ÃƒÂ  jour
    git add docs/journal_de_bord/entries/*.md
    git add docs/journal_de_bord/github/*.json
fi

# Continuer avec le commit
exit 0
"@

Set-Content -Path $PreCommitHookPath -Value $PreCommitHookContent -Encoding UTF8

# Rendre le hook exÃƒÂ©cutable
if (-not $isAdmin) {
    Write-Host "Note: Le script n'est pas exÃƒÂ©cutÃƒÂ© en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Vous devrez peut-ÃƒÂªtre rendre le hook exÃƒÂ©cutable manuellement." -ForegroundColor Yellow
} else {
    # Sous Windows, on ne peut pas facilement rendre un fichier exÃƒÂ©cutable comme sous Linux
    # Mais on peut crÃƒÂ©er un fichier .bat qui appelle le script bash
    $PreCommitBatPath = Join-Path $GitHookDir "pre-commit.bat"
    $PreCommitBatContent = @"
@echo off
bash "$PreCommitHookPath" %*
"@
    
    Set-Content -Path $PreCommitBatPath -Value $PreCommitBatContent -Encoding ASCII
    
    Write-Host "Hook Git pre-commit configurÃƒÂ©: $PreCommitHookPath" -ForegroundColor Green
    Write-Host "Fichier batch crÃƒÂ©ÃƒÂ©: $PreCommitBatPath" -ForegroundColor Green
}

# 4. ExÃƒÂ©cuter une premiÃƒÂ¨re synchronisation
Write-Section "ExÃƒÂ©cution d'une premiÃƒÂ¨re synchronisation"

Write-Host "Liaison des commits aux entrÃƒÂ©es du journal..." -ForegroundColor Cyan
python "$PythonScriptsDir\github_integration.py" link-commits

Write-Host "Liaison des issues aux entrÃƒÂ©es du journal..." -ForegroundColor Cyan
python "$PythonScriptsDir\github_integration.py" link-issues

# Afficher un message de conclusion
Write-Section "Configuration terminÃƒÂ©e"
Write-Host "L'intÃƒÂ©gration GitHub avec le journal de bord a ÃƒÂ©tÃƒÂ© configurÃƒÂ©e avec succÃƒÂ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant:"
Write-Host "1. CrÃƒÂ©er des entrÃƒÂ©es de journal ÃƒÂ  partir d'issues GitHub:"
Write-Host "   python development/scripts/python/journal/github_integration.py create-from-issue --issue NUMERO_ISSUE"
Write-Host ""
Write-Host "2. Les commits et issues seront automatiquement liÃƒÂ©s aux entrÃƒÂ©es du journal lors des commits."
Write-Host ""
Write-Host "3. Pour forcer une mise ÃƒÂ  jour des liens:"
Write-Host "   python development/scripts/python/journal/github_integration.py link-commits"
Write-Host "   python development/scripts/python/journal/github_integration.py link-issues"

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
