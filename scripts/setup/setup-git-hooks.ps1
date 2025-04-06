# Script d'installation des hooks Git
# Ce script configure les hooks Git pour le projet n8n

param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPreCommit,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPrePush,
    
    [Parameter(Mandatory = $false)]
    [string]$CustomPreCommitScript,
    
    [Parameter(Mandatory = $false)]
    [string]$CustomPrePushScript
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

Write-ColorMessage "Configuration des hooks Git pour le projet n8n..." -ForegroundColor "Cyan"

# Fonction pour vérifier si un fichier est verrouillé
function Test-FileLock {
    param (
        [parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $locked = $false
    
    if (Test-Path -Path $Path) {
        try {
            $fileStream = [System.IO.File]::Open($Path, 'Open', 'Write')
            $fileStream.Close()
            $fileStream.Dispose()
            $locked = $false
        }
        catch {
            $locked = $true
        }
    }
    
    return $locked
}

# Créer le dossier des hooks Git s'il n'existe pas
$gitHooksDir = "$projectRoot\.git\hooks"
if (-not (Test-Path $gitHooksDir)) {
    try {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
        Write-ColorMessage "Dossier de hooks Git créé" -ForegroundColor "Green"
    }
    catch {
        Write-ColorMessage "Erreur lors de la création du dossier de hooks Git : $_" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
}

# Configurer le hook pre-commit
if (-not $SkipPreCommit) {
    Write-ColorMessage "`nConfiguration du hook pre-commit..." -ForegroundColor "Cyan"
    
    $preCommitHookPath = "$gitHooksDir\pre-commit"
    
    # Vérifier si le fichier pre-commit est verrouillé
    $isLocked = Test-FileLock -Path $preCommitHookPath
    
    if ($isLocked) {
        Write-ColorMessage "Le fichier pre-commit hook est actuellement verrouillé ou utilisé par un autre processus" -ForegroundColor "Yellow"
        if (-not $Force) {
            Write-ColorMessage "Utilisez -Force pour continuer malgré le verrouillage" -ForegroundColor "Yellow"
            exit 1
        }
        else {
            Write-ColorMessage "Continuation forcée malgré le verrouillage" -ForegroundColor "Yellow"
        }
    }
    
    # Déterminer le script à utiliser
    $organizationScript = if ([string]::IsNullOrEmpty($CustomPreCommitScript)) {
        "scripts/maintenance/auto-organize-silent-improved.ps1"
    } else {
        $CustomPreCommitScript
    }
    
    # Créer un fichier temporaire pour le hook
    $tempHookPath = "$gitHooksDir\pre-commit.tmp"
    
    $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook amélioré pour organiser automatiquement les fichiers

echo "Organisation automatique des fichiers avant commit..."

# Obtenir le chemin du répertoire Git
GIT_DIR=$(git rev-parse --git-dir)
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Définir le chemin relatif du script
SCRIPT_PATH="\$PROJECT_ROOT/$($organizationScript.Replace('\', '/'))"

# Vérifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    # Exécuter le script amélioré qui gère les conflits de fichiers
    powershell -ExecutionPolicy Bypass -File "\$SCRIPT_PATH"
    SCRIPT_EXIT_CODE=\$?
    
    if [ \$SCRIPT_EXIT_CODE -ne 0 ]; then
        echo "Avertissement: Le script d'organisation a rencontré des problèmes, mais le commit continuera."
    fi
else
    echo "Avertissement: Script d'organisation non trouvé à \$SCRIPT_PATH"
    echo "Le commit continuera sans organisation automatique."
fi

# Ajouter les fichiers déplacés au commit
git add .

exit 0
"@

    try {
        # Écrire d'abord dans un fichier temporaire
        Set-Content -Path $tempHookPath -Value $preCommitHookContent -NoNewline
        
        # Puis renommer le fichier temporaire (opération atomique)
        if (Test-Path $preCommitHookPath) {
            Remove-Item -Path $preCommitHookPath -Force
        }
        Rename-Item -Path $tempHookPath -NewName (Split-Path $preCommitHookPath -Leaf)
        
        Write-ColorMessage "Hook pre-commit configuré avec succès" -ForegroundColor "Green"
        
        # Rendre le hook exécutable sous Unix
        if ($IsLinux -or $IsMacOS) {
            & chmod +x $preCommitHookPath
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de la configuration du hook pre-commit : $_" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    Write-ColorMessage "`nConfiguration du hook pre-commit ignorée (option -SkipPreCommit)" -ForegroundColor "Yellow"
}

# Configurer le hook pre-push
if (-not $SkipPrePush) {
    Write-ColorMessage "`nConfiguration du hook pre-push..." -ForegroundColor "Cyan"
    
    $prePushHookPath = "$gitHooksDir\pre-push"
    
    # Vérifier si le fichier pre-push est verrouillé
    $isLocked = Test-FileLock -Path $prePushHookPath
    
    if ($isLocked) {
        Write-ColorMessage "Le fichier pre-push hook est actuellement verrouillé ou utilisé par un autre processus" -ForegroundColor "Yellow"
        if (-not $Force) {
            Write-ColorMessage "Utilisez -Force pour continuer malgré le verrouillage" -ForegroundColor "Yellow"
            exit 1
        }
        else {
            Write-ColorMessage "Continuation forcée malgré le verrouillage" -ForegroundColor "Yellow"
        }
    }
    
    # Déterminer le script à utiliser
    $verificationScript = if ([string]::IsNullOrEmpty($CustomPrePushScript)) {
        "scripts/utils/git/git-pre-push-check.ps1"
    } else {
        $CustomPrePushScript
    }
    
    # Créer un fichier temporaire pour le hook
    $tempHookPath = "$gitHooksDir\pre-push.tmp"
    
    $prePushHookContent = @"
#!/bin/sh
# Pre-push hook amélioré pour vérifier les changements avant push

echo "Vérification des changements avant push..."

# Obtenir le chemin du répertoire Git
GIT_DIR=$(git rev-parse --git-dir)
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Définir le chemin relatif du script
SCRIPT_PATH="\$PROJECT_ROOT/$($verificationScript.Replace('\', '/'))"

# Vérifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    # Exécuter le script de vérification
    powershell -ExecutionPolicy Bypass -File "\$SCRIPT_PATH"
    SCRIPT_EXIT_CODE=\$?
    
    # Vérifier le code de sortie du script
    if [ \$SCRIPT_EXIT_CODE -ne 0 ]; then
        echo "Vérification échouée. Push annulé."
        exit 1
    fi
else
    echo "Avertissement: Script de vérification non trouvé à \$SCRIPT_PATH"
    echo "Le push continuera sans vérification."
fi

exit 0
"@

    try {
        # Écrire d'abord dans un fichier temporaire
        Set-Content -Path $tempHookPath -Value $prePushHookContent -NoNewline
        
        # Puis renommer le fichier temporaire (opération atomique)
        if (Test-Path $prePushHookPath) {
            Remove-Item -Path $prePushHookPath -Force
        }
        Rename-Item -Path $tempHookPath -NewName (Split-Path $prePushHookPath -Leaf)
        
        Write-ColorMessage "Hook pre-push configuré avec succès" -ForegroundColor "Green"
        
        # Rendre le hook exécutable sous Unix
        if ($IsLinux -or $IsMacOS) {
            & chmod +x $prePushHookPath
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de la configuration du hook pre-push : $_" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    Write-ColorMessage "`nConfiguration du hook pre-push ignorée (option -SkipPrePush)" -ForegroundColor "Yellow"
}

# Afficher un résumé
Write-ColorMessage "`nRésumé de la configuration des hooks Git:" -ForegroundColor "Cyan"
Write-ColorMessage "- Hook pre-commit: $(if (-not $SkipPreCommit) { 'Configuré' } else { 'Ignoré' })" -ForegroundColor $(if (-not $SkipPreCommit) { "Green" } else { "Yellow" })
if (-not $SkipPreCommit) {
    Write-ColorMessage "  Script utilisé: $organizationScript" -ForegroundColor "White"
}
Write-ColorMessage "- Hook pre-push: $(if (-not $SkipPrePush) { 'Configuré' } else { 'Ignoré' })" -ForegroundColor $(if (-not $SkipPrePush) { "Green" } else { "Yellow" })
if (-not $SkipPrePush) {
    Write-ColorMessage "  Script utilisé: $verificationScript" -ForegroundColor "White"
}

# Afficher des instructions d'utilisation
Write-ColorMessage "`nInstructions d'utilisation:" -ForegroundColor "Cyan"
Write-ColorMessage "1. Les hooks Git sont maintenant configurés et s'exécuteront automatiquement lors des opérations Git." -ForegroundColor "White"
Write-ColorMessage "2. Pour désactiver temporairement un hook, utilisez l'option --no-verify:" -ForegroundColor "White"
Write-ColorMessage "   git commit --no-verify -m \"Commit sans vérification\"" -ForegroundColor "White"
Write-ColorMessage "   git push --no-verify" -ForegroundColor "White"
Write-ColorMessage "3. Pour plus d'informations, consultez le guide: docs/guides/GUIDE_HOOKS_GIT.md" -ForegroundColor "White"

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\setup-git-hooks.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force                  Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPreCommit          Ne pas configurer le hook pre-commit" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPrePush            Ne pas configurer le hook pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CustomPreCommitScript  Chemin personnalisé pour le script pre-commit" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CustomPrePushScript    Chemin personnalisé pour le script pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1 -SkipPrePush" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1 -CustomPreCommitScript 'scripts/custom/my-pre-commit.ps1'" -ForegroundColor "Cyan"
}
