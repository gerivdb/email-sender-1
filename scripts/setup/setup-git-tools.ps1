# Script d'installation des outils Git
# Ce script configure tous les outils Git développés pour le projet

param (
    [Parameter(Mandatory = $false)]
    [switch]$ConfigureGit,
    
    [Parameter(Mandatory = $false)]
    [switch]$SetupHooks,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Vérifier si nous sommes dans un dépôt Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-ColorMessage "Ce dossier n'est pas un dépôt Git" -ForegroundColor "Red"
    exit 1
}

Write-ColorMessage "Configuration des outils Git pour le projet n8n..." -ForegroundColor "Cyan"

# Étape 1: Vérifier que tous les scripts nécessaires existent
$requiredScripts = @(
    "scripts\maintenance\auto-organize-silent-improved.ps1",
    "scripts\utils\git\git-smart-commit.ps1",
    "scripts\utils\git\git-atomic-commit.ps1",
    "scripts\utils\git\git-pre-push-check.ps1"
)

$missingScripts = @()

foreach ($script in $requiredScripts) {
    if (-not (Test-Path "$projectRoot\$script")) {
        $missingScripts += $script
    }
}

if ($missingScripts.Count -gt 0) {
    Write-ColorMessage "Les scripts suivants sont manquants:" -ForegroundColor "Red"
    $missingScripts | ForEach-Object {
        Write-ColorMessage "  - $_" -ForegroundColor "Red"
    }
    
    if (-not $Force) {
        Write-ColorMessage "Installation annulée. Assurez-vous que tous les scripts nécessaires sont présents." -ForegroundColor "Red"
        exit 1
    }
    else {
        Write-ColorMessage "Continuation forcée malgré les scripts manquants" -ForegroundColor "Yellow"
    }
}

# Étape 2: Configurer Git (si demandé)
if ($ConfigureGit) {
    Write-ColorMessage "`nConfiguration de Git..." -ForegroundColor "Cyan"
    
    # Configurer les fins de ligne
    git config --global core.autocrlf true
    Write-ColorMessage "core.autocrlf configuré à 'true'" -ForegroundColor "Green"
    
    # Demander le nom d'utilisateur et l'email si non configurés
    $userName = git config --global user.name
    $userEmail = git config --global user.email
    
    if ([string]::IsNullOrEmpty($userName)) {
        $newUserName = Read-Host "Entrez votre nom d'utilisateur Git"
        if (-not [string]::IsNullOrEmpty($newUserName)) {
            git config --global user.name $newUserName
            Write-ColorMessage "user.name configuré à '$newUserName'" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "user.name déjà configuré à '$userName'" -ForegroundColor "Green"
    }
    
    if ([string]::IsNullOrEmpty($userEmail)) {
        $newUserEmail = Read-Host "Entrez votre email Git"
        if (-not [string]::IsNullOrEmpty($newUserEmail)) {
            git config --global user.email $newUserEmail
            Write-ColorMessage "user.email configuré à '$newUserEmail'" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "user.email déjà configuré à '$userEmail'" -ForegroundColor "Green"
    }
}

# Étape 3: Configurer les hooks Git (si demandé)
if ($SetupHooks) {
    Write-ColorMessage "`nConfiguration des hooks Git..." -ForegroundColor "Cyan"
    
    $gitHooksDir = "$projectRoot\.git\hooks"
    
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
    }
    
    # Hook pre-commit
    $preCommitHookPath = "$gitHooksDir\pre-commit"
    $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook pour organiser automatiquement les fichiers

echo "Organisation automatique des fichiers avant commit..."
powershell -ExecutionPolicy Bypass -File "$projectRoot\scripts\maintenance\auto-organize-silent-improved.ps1"

# Ajouter les fichiers déplacés au commit
git add .

exit 0
"@

    try {
        Set-Content -Path $preCommitHookPath -Value $preCommitHookContent -NoNewline
        Write-ColorMessage "Hook pre-commit configuré" -ForegroundColor "Green"
        
        # Rendre le hook exécutable sous Unix
        if ($IsLinux -or $IsMacOS) {
            & chmod +x $preCommitHookPath
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de la configuration du hook pre-commit: $_" -ForegroundColor "Red"
    }
    
    # Hook pre-push
    $prePushHookPath = "$gitHooksDir\pre-push"
    $prePushHookContent = @"
#!/bin/sh
# Pre-push hook pour vérifier les changements avant push

echo "Vérification des changements avant push..."
powershell -ExecutionPolicy Bypass -File "$projectRoot\scripts\utils\git\git-pre-push-check.ps1"

# Si le script de vérification échoue, annuler le push
if [ \$? -ne 0 ]; then
  echo "Vérification échouée. Push annulé."
  exit 1
fi

exit 0
"@

    try {
        Set-Content -Path $prePushHookPath -Value $prePushHookContent -NoNewline
        Write-ColorMessage "Hook pre-push configuré" -ForegroundColor "Green"
        
        # Rendre le hook exécutable sous Unix
        if ($IsLinux -or $IsMacOS) {
            & chmod +x $prePushHookPath
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de la configuration du hook pre-push: $_" -ForegroundColor "Red"
    }
}

# Étape 4: Créer des alias pour les scripts
Write-ColorMessage "`nCréation d'alias pour les scripts..." -ForegroundColor "Cyan"

$profilePath = $PROFILE
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$aliasContent = @"

# Alias pour les outils Git du projet n8n
function git-smart-commit { & "$projectRoot\scripts\utils\git\git-smart-commit.ps1" @args }
function git-atomic-commit { & "$projectRoot\scripts\utils\git\git-atomic-commit.ps1" @args }
function git-pre-push-check { & "$projectRoot\scripts\utils\git\git-pre-push-check.ps1" @args }
function auto-organize { & "$projectRoot\scripts\maintenance\auto-organize-silent-improved.ps1" @args }

"@

$currentProfile = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

if (-not $currentProfile -or -not $currentProfile.Contains("git-smart-commit")) {
    Add-Content -Path $profilePath -Value $aliasContent
    Write-ColorMessage "Alias ajoutés au profil PowerShell" -ForegroundColor "Green"
}
else {
    Write-ColorMessage "Les alias sont déjà présents dans le profil PowerShell" -ForegroundColor "Green"
}

# Étape 5: Afficher un résumé
Write-ColorMessage "`nRésumé de l'installation:" -ForegroundColor "Cyan"
Write-ColorMessage "- Scripts vérifiés: $(if ($missingScripts.Count -eq 0) { 'Tous présents' } else { "$($requiredScripts.Count - $missingScripts.Count)/$($requiredScripts.Count) présents" })" -ForegroundColor $(if ($missingScripts.Count -eq 0) { "Green" } else { "Yellow" })
Write-ColorMessage "- Configuration Git: $(if ($ConfigureGit) { 'Effectuée' } else { 'Ignorée' })" -ForegroundColor $(if ($ConfigureGit) { "Green" } else { "Yellow" })
Write-ColorMessage "- Hooks Git: $(if ($SetupHooks) { 'Configurés' } else { 'Ignorés' })" -ForegroundColor $(if ($SetupHooks) { "Green" } else { "Yellow" })
Write-ColorMessage "- Alias PowerShell: Configurés" -ForegroundColor "Green"

# Étape 6: Instructions d'utilisation
Write-ColorMessage "`nInstructions d'utilisation:" -ForegroundColor "Cyan"
Write-ColorMessage "1. Redémarrez votre terminal PowerShell pour activer les alias" -ForegroundColor "White"
Write-ColorMessage "2. Utilisez les commandes suivantes:" -ForegroundColor "White"
Write-ColorMessage "   - git-smart-commit : Pour un commit complet avec organisation automatique" -ForegroundColor "White"
Write-ColorMessage "   - git-atomic-commit : Pour un commit ciblé par catégorie de fichiers" -ForegroundColor "White"
Write-ColorMessage "   - git-pre-push-check : Pour vérifier les changements avant push" -ForegroundColor "White"
Write-ColorMessage "   - auto-organize : Pour organiser les fichiers manuellement" -ForegroundColor "White"
Write-ColorMessage "3. Consultez le guide des bonnes pratiques Git: docs/guides/GUIDE_BONNES_PRATIQUES_GIT.md" -ForegroundColor "White"

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\setup-git-tools.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -ConfigureGit  Configurer les paramètres globaux de Git" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SetupHooks    Configurer les hooks Git pre-commit et pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force         Ignorer les erreurs et continuer l'installation" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-tools.ps1 -ConfigureGit -SetupHooks" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-tools.ps1 -SetupHooks" -ForegroundColor "Cyan"
}
