# Script d'automatisation Git pour simplifier et standardiser le processus de commit et push
# Ce script combine toutes les Ã©tapes : organisation, vÃ©rification, ajout, commit et push

param (
    [Parameter(Mandatory = $false)]
    [string]$CommitMessage = "",

    [Parameter(Mandatory = $false)]
    [switch]$AtomicCommit,

    [Parameter(Mandatory = $false)]
    [switch]$SkipOrganize,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPush,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Obtenir le chemin racine du projet
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$projectRoot = (Get-Item $scriptDir).Parent.Parent.FullName

# Si le script est exÃ©cutÃ© depuis un autre rÃ©pertoire, utiliser le rÃ©pertoire courant
if (-not (Test-Path "$projectRoot\.git")) {
    $projectRoot = (Get-Location).Path
}

Set-Location $projectRoot

# CrÃ©er un fichier de log
$logFile = "$projectRoot\logs\git-smart-commit-$(Get-Date -Format 'yyyy-MM-dd').log"
$logFolder = Split-Path $logFile -Parent

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

# Fonction pour Ã©crire dans le log
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Add-Content -Path $logFile -Value $logMessage

    # Afficher Ã©galement dans la console avec des couleurs
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

Write-Log "DÃ©but du processus de commit intelligent"

# VÃ©rifier si nous sommes dans un dÃ©pÃ´t Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-Log "Ce dossier n'est pas un dÃ©pÃ´t Git" -Level "ERROR"
    exit 1
}

# Ã‰tape 1: Organisation des fichiers (si non dÃ©sactivÃ©e)
if (-not $SkipOrganize) {
    Write-Log "Ã‰tape 1: Organisation des fichiers..."

    try {
        & "$projectRoot\scripts\maintenance\auto-organize-silent-improved.ps1"
        Write-Log "Organisation des fichiers terminÃ©e" -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors de l'organisation des fichiers : $_" -Level "ERROR"
        if (-not $Force) {
            Write-Log "Utilisez -Force pour continuer malgrÃ© les erreurs" -Level "WARNING"
            exit 1
        }
    }
}
else {
    Write-Log "Ã‰tape 1: Organisation des fichiers ignorÃ©e (option -SkipOrganize)"
}

# Ã‰tape 2: VÃ©rification de l'Ã©tat Git
Write-Log "Ã‰tape 2: VÃ©rification de l'Ã©tat Git..."

try {
    $gitStatus = git status --porcelain

    if ([string]::IsNullOrEmpty($gitStatus)) {
        Write-Log "Aucun changement Ã  commiter" -Level "WARNING"
        exit 0
    }

    $modifiedFiles = $gitStatus | Where-Object { $_ -match '^\s*M' } | Measure-Object | Select-Object -ExpandProperty Count
    $addedFiles = $gitStatus | Where-Object { $_ -match '^\s*A' -or $_ -match '^\s*\?\?' } | Measure-Object | Select-Object -ExpandProperty Count
    $deletedFiles = $gitStatus | Where-Object { $_ -match '^\s*D' } | Measure-Object | Select-Object -ExpandProperty Count
    $renamedFiles = $gitStatus | Where-Object { $_ -match '^\s*R' } | Measure-Object | Select-Object -ExpandProperty Count

    Write-Log "Changements dÃ©tectÃ©s: $modifiedFiles modifiÃ©s, $addedFiles ajoutÃ©s, $deletedFiles supprimÃ©s, $renamedFiles renommÃ©s" -Level "SUCCESS"

    # Afficher les changements
    Write-Host "`nChangements dÃ©tectÃ©s:" -ForegroundColor Cyan
    $gitStatus | ForEach-Object {
        $status = $_.Substring(0, 2).Trim()
        $file = $_.Substring(3)

        switch -Regex ($status) {
            'M' { Write-Host "  ModifiÃ©: $file" -ForegroundColor Yellow }
            'A|(\?\?)' { Write-Host "  AjoutÃ©: $file" -ForegroundColor Green }
            'D' { Write-Host "  SupprimÃ©: $file" -ForegroundColor Red }
            'R' { Write-Host "  RenommÃ©: $file" -ForegroundColor Blue }
            default { Write-Host "  Statut $status : $file" }
        }
    }
    Write-Host ""
}
catch {
    Write-Log "Erreur lors de la vÃ©rification de l'Ã©tat Git : $_" -Level "ERROR"
    exit 1
}

# Ã‰tape 3: Ajout des fichiers modifiÃ©s
Write-Log "Ã‰tape 3: Ajout des fichiers modifiÃ©s..."

try {
    if ($AtomicCommit) {
        # Mode commit atomique: demander quels fichiers ajouter
        Write-Host "Mode commit atomique activÃ©. SÃ©lectionnez les types de fichiers Ã  inclure:" -ForegroundColor Cyan
        Write-Host "1. Fichiers de structure (dossiers, organisation)" -ForegroundColor Cyan
        Write-Host "2. Documentation (fichiers .md)" -ForegroundColor Cyan
        Write-Host "3. Scripts (PowerShell, Python)" -ForegroundColor Cyan
        Write-Host "4. Workflows n8n (fichiers .json)" -ForegroundColor Cyan
        Write-Host "5. Configuration (fichiers .config, .env)" -ForegroundColor Cyan
        Write-Host "6. Tous les fichiers" -ForegroundColor Cyan

        $choice = Read-Host "Entrez votre choix (1-6)"

        switch ($choice) {
            "1" {
                git add **/*/
                Write-Log "Fichiers de structure ajoutÃ©s" -Level "SUCCESS"
            }
            "2" {
                git add *.md
                git add **/*.md
                Write-Log "Fichiers de documentation ajoutÃ©s" -Level "SUCCESS"
            }
            "3" {
                git add *.ps1
                git add **/*.ps1
                git add *.py
                git add **/*.py
                Write-Log "Scripts ajoutÃ©s" -Level "SUCCESS"
            }
            "4" {
                git add *.json
                git add **/*.json
                Write-Log "Workflows n8n ajoutÃ©s" -Level "SUCCESS"
            }
            "5" {
                git add *.config
                git add **/*.config
                git add *.env
                git add **/*.env
                Write-Log "Fichiers de configuration ajoutÃ©s" -Level "SUCCESS"
            }
            "6" {
                git add .
                Write-Log "Tous les fichiers ajoutÃ©s" -Level "SUCCESS"
            }
            default {
                Write-Log "Choix invalide, ajout de tous les fichiers" -Level "WARNING"
                git add .
            }
        }
    }
    else {
        # Mode standard: ajouter tous les fichiers
        git add .
        Write-Log "Tous les fichiers ajoutÃ©s" -Level "SUCCESS"
    }
}
catch {
    Write-Log "Erreur lors de l'ajout des fichiers : $_" -Level "ERROR"
    exit 1
}

# Ã‰tape 4: Affichage des changements pour validation
Write-Log "Ã‰tape 4: Affichage des changements pour validation..."

try {
    $stagedChanges = git diff --staged --stat

    if ([string]::IsNullOrEmpty($stagedChanges)) {
        Write-Log "Aucun changement n'a Ã©tÃ© ajoutÃ© Ã  l'index" -Level "WARNING"
        exit 0
    }

    Write-Host "`nChangements qui seront commitÃ©s:" -ForegroundColor Cyan
    Write-Host $stagedChanges
    Write-Host ""

    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous continuer avec le commit? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Commit annulÃ© par l'utilisateur" -Level "WARNING"
            exit 0
        }
    }
}
catch {
    Write-Log "Erreur lors de l'affichage des changements : $_" -Level "ERROR"
    exit 1
}

# Ã‰tape 5: CrÃ©ation du commit avec message descriptif
Write-Log "Ã‰tape 5: CrÃ©ation du commit..."

try {
    # Si aucun message de commit n'est fourni, demander Ã  l'utilisateur
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        Write-Host "`nEntrez un message de commit descriptif:" -ForegroundColor Cyan

        if ($AtomicCommit) {
            # Suggestions pour les commits atomiques
            Write-Host "Suggestions pour les commits atomiques:" -ForegroundColor Yellow
            Write-Host "- 'docs: Mise Ã  jour de la documentation sur...'" -ForegroundColor Yellow
            Write-Host "- 'feat: Ajout de la fonctionnalitÃ©...'" -ForegroundColor Yellow
            Write-Host "- 'fix: Correction du problÃ¨me...'" -ForegroundColor Yellow
            Write-Host "- 'refactor: RÃ©organisation de...'" -ForegroundColor Yellow
            Write-Host "- 'chore: Maintenance de...'" -ForegroundColor Yellow
        }

        $CommitMessage = Read-Host "Message de commit"

        if ([string]::IsNullOrEmpty($CommitMessage)) {
            $CommitMessage = "Commit automatique via git-smart-commit.ps1"
            Write-Log "Aucun message fourni, utilisation du message par dÃ©faut" -Level "WARNING"
        }
    }

    git commit -m $CommitMessage
    Write-Log "Commit crÃ©Ã© avec le message: $CommitMessage" -Level "SUCCESS"
}
catch {
    Write-Log "Erreur lors de la crÃ©ation du commit : $_" -Level "ERROR"
    exit 1
}

# Ã‰tape 6: Push vers le dÃ©pÃ´t distant (si non dÃ©sactivÃ©)
if (-not $SkipPush) {
    Write-Log "Ã‰tape 6: Push vers le dÃ©pÃ´t distant..."

    try {
        git push
        Write-Log "Push terminÃ© avec succÃ¨s" -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors du push : $_" -Level "ERROR"
        exit 1
    }
}
else {
    Write-Log "Ã‰tape 6: Push ignorÃ© (option -SkipPush)"
}

Write-Log "Processus de commit intelligent terminÃ© avec succÃ¨s" -Level "SUCCESS"

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© du commit:" -ForegroundColor Cyan
Write-Host "- Message: $CommitMessage" -ForegroundColor Cyan
Write-Host "- Mode: $(if ($AtomicCommit) { 'Atomique' } else { 'Standard' })" -ForegroundColor Cyan
Write-Host "- Organisation: $(if ($SkipOrganize) { 'IgnorÃ©e' } else { 'EffectuÃ©e' })" -ForegroundColor Cyan
Write-Host "- Push: $(if ($SkipPush) { 'IgnorÃ©' } else { 'EffectuÃ©' })" -ForegroundColor Cyan

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-Host "`nUtilisation: .\git-smart-commit.ps1 [options]" -ForegroundColor Cyan
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-Host "  -CommitMessage 'message'  Message de commit (si non fourni, sera demandÃ©)" -ForegroundColor Cyan
    Write-Host "  -AtomicCommit             Active le mode de commit atomique (sÃ©lection des fichiers par type)" -ForegroundColor Cyan
    Write-Host "  -SkipOrganize             Ignore l'Ã©tape d'organisation des fichiers" -ForegroundColor Cyan
    Write-Host "  -SkipPush                 Ne pas effectuer de push aprÃ¨s le commit" -ForegroundColor Cyan
    Write-Host "  -Force                    Ne pas demander de confirmation" -ForegroundColor Cyan
    Write-Host "`nExemples:" -ForegroundColor Cyan
    Write-Host "  .\git-smart-commit.ps1 -CommitMessage 'Ajout de nouvelles fonctionnalitÃ©s'" -ForegroundColor Cyan
    Write-Host "  .\git-smart-commit.ps1 -AtomicCommit -SkipPush" -ForegroundColor Cyan
}
