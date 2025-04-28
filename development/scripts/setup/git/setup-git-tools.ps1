# Script d'installation des outils Git
# Ce script configure tous les outils Git dÃ©veloppÃ©s pour le projet

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

# Fonction pour afficher un message colorÃ©
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# VÃ©rifier si nous sommes dans un dÃ©pÃ´t Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-ColorMessage "Ce dossier n'est pas un dÃ©pÃ´t Git" -ForegroundColor "Red"
    exit 1
}

Write-ColorMessage "Configuration des outils Git pour le projet n8n..." -ForegroundColor "Cyan"

# Ã‰tape 1: VÃ©rifier que tous les scripts nÃ©cessaires existent
$requiredScripts = @(
    "..\..\D",
    "..\..\D",
    "..\..\D",
    "..\..\D"
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
        Write-ColorMessage "Installation annulÃ©e. Assurez-vous que tous les scripts nÃ©cessaires sont prÃ©sents." -ForegroundColor "Red"
        exit 1
    }
    else {
        Write-ColorMessage "Continuation forcÃ©e malgrÃ© les scripts manquants" -ForegroundColor "Yellow"
    }
}

# Ã‰tape 2: Configurer Git (si demandÃ©)
if ($ConfigureGit) {
    Write-ColorMessage "`nConfiguration de Git..." -ForegroundColor "Cyan"
    
    # Configurer les fins de ligne
    git config --global core.autocrlf true
    Write-ColorMessage "core.autocrlf configurÃ© Ã  'true'" -ForegroundColor "Green"
    
    # Demander le nom d'utilisateur et l'email si non configurÃ©s
    $userName = git config --global user.name
    $userEmail = git config --global user.email
    
    if ([string]::IsNullOrEmpty($userName)) {
        $newUserName = Read-Host "Entrez votre nom d'utilisateur Git"
        if (-not [string]::IsNullOrEmpty($newUserName)) {
            git config --global user.name $newUserName
            Write-ColorMessage "user.name configurÃ© Ã  '$newUserName'" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "user.name dÃ©jÃ  configurÃ© Ã  '$userName'" -ForegroundColor "Green"
    }
    
    if ([string]::IsNullOrEmpty($userEmail)) {
        $newUserEmail = Read-Host "Entrez votre email Git"
        if (-not [string]::IsNullOrEmpty($newUserEmail)) {
            git config --global user.email $newUserEmail
            Write-ColorMessage "user.email configurÃ© Ã  '$newUserEmail'" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "user.email dÃ©jÃ  configurÃ© Ã  '$userEmail'" -ForegroundColor "Green"
    }
}

# Ã‰tape 3: Configurer les hooks Git (si demandÃ©)
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
powershell -ExecutionPolicy Bypass -File "$projectRoot\..\..\D"

# Ajouter les fichiers dÃ©placÃ©s au commit
git add .

exit 0
"@

    try {
        Set-Content -Path $preCommitHookPath -Value $preCommitHookContent -NoNewline
        Write-ColorMessage "Hook pre-commit configurÃ©" -ForegroundColor "Green"
        
        # Rendre le hook exÃ©cutable sous Unix
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
# Pre-push hook pour vÃ©rifier les changements avant push

echo "VÃ©rification des changements avant push..."
powershell -ExecutionPolicy Bypass -File "$projectRoot\..\..\D"

# Si le script de vÃ©rification Ã©choue, annuler le push
if [ \$? -ne 0 ]; then
  echo "VÃ©rification Ã©chouÃ©e. Push annulÃ©."
  exit 1
fi

exit 0
"@

    try {
        Set-Content -Path $prePushHookPath -Value $prePushHookContent -NoNewline
        Write-ColorMessage "Hook pre-push configurÃ©" -ForegroundColor "Green"
        
        # Rendre le hook exÃ©cutable sous Unix
        if ($IsLinux -or $IsMacOS) {
            & chmod +x $prePushHookPath
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de la configuration du hook pre-push: $_" -ForegroundColor "Red"
    }
}

# Ã‰tape 4: CrÃ©er des alias pour les scripts
Write-ColorMessage "`nCrÃ©ation d'alias pour les scripts..." -ForegroundColor "Cyan"

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
function git-smart-commit { & "$projectRoot\..\..\D" @args }
function git-atomic-commit { & "$projectRoot\..\..\D" @args }
function git-pre-push-check { & "$projectRoot\..\..\D" @args }
function auto-organize { & "$projectRoot\..\..\D" @args }

"@

$currentProfile = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

if (-not $currentProfile -or -not $currentProfile.Contains("git-smart-commit")) {
    Add-Content -Path $profilePath -Value $aliasContent
    Write-ColorMessage "Alias ajoutÃ©s au profil PowerShell" -ForegroundColor "Green"
}
else {
    Write-ColorMessage "Les alias sont dÃ©jÃ  prÃ©sents dans le profil PowerShell" -ForegroundColor "Green"
}

# Ã‰tape 5: Afficher un rÃ©sumÃ©
Write-ColorMessage "`nRÃ©sumÃ© de l'installation:" -ForegroundColor "Cyan"
Write-ColorMessage "- Scripts vÃ©rifiÃ©s: $(if ($missingScripts.Count -eq 0) { 'Tous prÃ©sents' } else { "$($requiredScripts.Count - $missingScripts.Count)/$($requiredScripts.Count) prÃ©sents" })" -ForegroundColor $(if ($missingScripts.Count -eq 0) { "Green" } else { "Yellow" })
Write-ColorMessage "- Configuration Git: $(if ($ConfigureGit) { 'EffectuÃ©e' } else { 'IgnorÃ©e' })" -ForegroundColor $(if ($ConfigureGit) { "Green" } else { "Yellow" })
Write-ColorMessage "- Hooks Git: $(if ($SetupHooks) { 'ConfigurÃ©s' } else { 'IgnorÃ©s' })" -ForegroundColor $(if ($SetupHooks) { "Green" } else { "Yellow" })
Write-ColorMessage "- Alias PowerShell: ConfigurÃ©s" -ForegroundColor "Green"

# Ã‰tape 6: Instructions d'utilisation
Write-ColorMessage "`nInstructions d'utilisation:" -ForegroundColor "Cyan"
Write-ColorMessage "1. RedÃ©marrez votre terminal PowerShell pour activer les alias" -ForegroundColor "White"
Write-ColorMessage "2. Utilisez les commandes suivantes:" -ForegroundColor "White"
Write-ColorMessage "   - git-smart-commit : Pour un commit complet avec organisation automatique" -ForegroundColor "White"
Write-ColorMessage "   - git-atomic-commit : Pour un commit ciblÃ© par catÃ©gorie de fichiers" -ForegroundColor "White"
Write-ColorMessage "   - git-pre-push-check : Pour vÃ©rifier les changements avant push" -ForegroundColor "White"
Write-ColorMessage "   - auto-organize : Pour organiser les fichiers manuellement" -ForegroundColor "White"
Write-ColorMessage "3. Consultez le guide des bonnes pratiques Git: docs/guides/GUIDE_BONNES_PRATIQUES_GIT.md" -ForegroundColor "White"

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\setup-git-tools.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -ConfigureGit  Configurer les paramÃ¨tres globaux de Git" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SetupHooks    Configurer les hooks Git pre-commit et pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force         Ignorer les erreurs et continuer l'installation" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-tools.ps1 -ConfigureGit -SetupHooks" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-tools.ps1 -SetupHooks" -ForegroundColor "Cyan"
}

