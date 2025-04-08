# Script d'automatisation Git pour simplifier et standardiser le processus de commit et push
# Ce script combine toutes les étapes : organisation, vérification, ajout, commit et push

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

# Si le script est exécuté depuis un autre répertoire, utiliser le répertoire courant
if (-not (Test-Path "$projectRoot\.git")) {
    $projectRoot = (Get-Location).Path
}

Set-Location $projectRoot

# Créer un fichier de log
$logFile = "$projectRoot\logs\git-smart-commit-$(Get-Date -Format 'yyyy-MM-dd').log"
$logFolder = Split-Path $logFile -Parent

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Add-Content -Path $logFile -Value $logMessage

    # Afficher également dans la console avec des couleurs
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

Write-Log "Début du processus de commit intelligent"

# Vérifier si nous sommes dans un dépôt Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-Log "Ce dossier n'est pas un dépôt Git" -Level "ERROR"
    exit 1
}

# Étape 1: Organisation des fichiers (si non désactivée)
if (-not $SkipOrganize) {
    Write-Log "Étape 1: Organisation des fichiers..."

    try {
        & "..\..\D"
        Write-Log "Organisation des fichiers terminée" -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors de l'organisation des fichiers : $_" -Level "ERROR"
        if (-not $Force) {
            Write-Log "Utilisez -Force pour continuer malgré les erreurs" -Level "WARNING"
            exit 1
        }
    }
}
else {
    Write-Log "Étape 1: Organisation des fichiers ignorée (option -SkipOrganize)"
}

# Étape 2: Vérification de l'état Git
Write-Log "Étape 2: Vérification de l'état Git..."

try {
    $gitStatus = git status --porcelain

    if ([string]::IsNullOrEmpty($gitStatus)) {
        Write-Log "Aucun changement à commiter" -Level "WARNING"
        exit 0
    }

    $modifiedFiles = $gitStatus | Where-Object { $_ -match '^\s*M' } | Measure-Object | Select-Object -ExpandProperty Count
    $addedFiles = $gitStatus | Where-Object { $_ -match '^\s*A' -or $_ -match '^\s*\?\?' } | Measure-Object | Select-Object -ExpandProperty Count
    $deletedFiles = $gitStatus | Where-Object { $_ -match '^\s*D' } | Measure-Object | Select-Object -ExpandProperty Count
    $renamedFiles = $gitStatus | Where-Object { $_ -match '^\s*R' } | Measure-Object | Select-Object -ExpandProperty Count

    Write-Log "Changements détectés: $modifiedFiles modifiés, $addedFiles ajoutés, $deletedFiles supprimés, $renamedFiles renommés" -Level "SUCCESS"

    # Afficher les changements
    Write-Host "`nChangements détectés:" -ForegroundColor Cyan
    $gitStatus | ForEach-Object {
        $status = $_.Substring(0, 2).Trim()
        $file = $_.Substring(3)

        switch -Regex ($status) {
            'M' { Write-Host "  Modifié: $file" -ForegroundColor Yellow }
            'A|(\?\?)' { Write-Host "  Ajouté: $file" -ForegroundColor Green }
            'D' { Write-Host "  Supprimé: $file" -ForegroundColor Red }
            'R' { Write-Host "  Renommé: $file" -ForegroundColor Blue }
            default { Write-Host "  Statut $status : $file" }
        }
    }
    Write-Host ""
}
catch {
    Write-Log "Erreur lors de la vérification de l'état Git : $_" -Level "ERROR"
    exit 1
}

# Étape 3: Ajout des fichiers modifiés
Write-Log "Étape 3: Ajout des fichiers modifiés..."

try {
    if ($AtomicCommit) {
        # Mode commit atomique: demander quels fichiers ajouter
        Write-Host "Mode commit atomique activé. Sélectionnez les types de fichiers à inclure:" -ForegroundColor Cyan
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
                Write-Log "Fichiers de structure ajoutés" -Level "SUCCESS"
            }
            "2" {
                git add *.md
                git add **/*.md
                Write-Log "Fichiers de documentation ajoutés" -Level "SUCCESS"
            }
            "3" {
                git add *.ps1
                git add **/*.ps1
                git add *.py
                git add **/*.py
                Write-Log "Scripts ajoutés" -Level "SUCCESS"
            }
            "4" {
                git add *.json
                git add **/*.json
                Write-Log "Workflows n8n ajoutés" -Level "SUCCESS"
            }
            "5" {
                git add *.config
                git add **/*.config
                git add *.env
                git add **/*.env
                Write-Log "Fichiers de configuration ajoutés" -Level "SUCCESS"
            }
            "6" {
                git add .
                Write-Log "Tous les fichiers ajoutés" -Level "SUCCESS"
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
        Write-Log "Tous les fichiers ajoutés" -Level "SUCCESS"
    }
}
catch {
    Write-Log "Erreur lors de l'ajout des fichiers : $_" -Level "ERROR"
    exit 1
}

# Étape 4: Affichage des changements pour validation
Write-Log "Étape 4: Affichage des changements pour validation..."

try {
    $stagedChanges = git diff --staged --stat

    if ([string]::IsNullOrEmpty($stagedChanges)) {
        Write-Log "Aucun changement n'a été ajouté à l'index" -Level "WARNING"
        exit 0
    }

    Write-Host "`nChangements qui seront commités:" -ForegroundColor Cyan
    Write-Host $stagedChanges
    Write-Host ""

    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous continuer avec le commit? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Commit annulé par l'utilisateur" -Level "WARNING"
            exit 0
        }
    }
}
catch {
    Write-Log "Erreur lors de l'affichage des changements : $_" -Level "ERROR"
    exit 1
}

# Étape 5: Création du commit avec message descriptif
Write-Log "Étape 5: Création du commit..."

try {
    # Si aucun message de commit n'est fourni, demander à l'utilisateur
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        Write-Host "`nEntrez un message de commit descriptif:" -ForegroundColor Cyan

        if ($AtomicCommit) {
            # Suggestions pour les commits atomiques
            Write-Host "Suggestions pour les commits atomiques:" -ForegroundColor Yellow
            Write-Host "- 'docs: Mise à jour de la documentation sur...'" -ForegroundColor Yellow
            Write-Host "- 'feat: Ajout de la fonctionnalité...'" -ForegroundColor Yellow
            Write-Host "- 'fix: Correction du problème...'" -ForegroundColor Yellow
            Write-Host "- 'refactor: Réorganisation de...'" -ForegroundColor Yellow
            Write-Host "- 'chore: Maintenance de...'" -ForegroundColor Yellow
        }

        $CommitMessage = Read-Host "Message de commit"

        if ([string]::IsNullOrEmpty($CommitMessage)) {
            $CommitMessage = "Commit automatique via git-smart-commit.ps1"
            Write-Log "Aucun message fourni, utilisation du message par défaut" -Level "WARNING"
        }
    }

    git commit -m $CommitMessage
    Write-Log "Commit créé avec le message: $CommitMessage" -Level "SUCCESS"
}
catch {
    Write-Log "Erreur lors de la création du commit : $_" -Level "ERROR"
    exit 1
}

# Étape 6: Push vers le dépôt distant (si non désactivé)
if (-not $SkipPush) {
    Write-Log "Étape 6: Push vers le dépôt distant..."

    try {
        git push
        Write-Log "Push terminé avec succès" -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors du push : $_" -Level "ERROR"
        exit 1
    }
}
else {
    Write-Log "Étape 6: Push ignoré (option -SkipPush)"
}

Write-Log "Processus de commit intelligent terminé avec succès" -Level "SUCCESS"

# Afficher un résumé
Write-Host "`nRésumé du commit:" -ForegroundColor Cyan
Write-Host "- Message: $CommitMessage" -ForegroundColor Cyan
Write-Host "- Mode: $(if ($AtomicCommit) { 'Atomique' } else { 'Standard' })" -ForegroundColor Cyan
Write-Host "- Organisation: $(if ($SkipOrganize) { 'Ignorée' } else { 'Effectuée' })" -ForegroundColor Cyan
Write-Host "- Push: $(if ($SkipPush) { 'Ignoré' } else { 'Effectué' })" -ForegroundColor Cyan

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-Host "`nUtilisation: .\git-smart-commit.ps1 [options]" -ForegroundColor Cyan
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-Host "  -CommitMessage 'message'  Message de commit (si non fourni, sera demandé)" -ForegroundColor Cyan
    Write-Host "  -AtomicCommit             Active le mode de commit atomique (sélection des fichiers par type)" -ForegroundColor Cyan
    Write-Host "  -SkipOrganize             Ignore l'étape d'organisation des fichiers" -ForegroundColor Cyan
    Write-Host "  -SkipPush                 Ne pas effectuer de push après le commit" -ForegroundColor Cyan
    Write-Host "  -Force                    Ne pas demander de confirmation" -ForegroundColor Cyan
    Write-Host "`nExemples:" -ForegroundColor Cyan
    Write-Host "  .\git-smart-commit.ps1 -CommitMessage 'Ajout de nouvelles fonctionnalités'" -ForegroundColor Cyan
    Write-Host "  .\git-smart-commit.ps1 -AtomicCommit -SkipPush" -ForegroundColor Cyan
}

