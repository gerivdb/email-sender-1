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

Write-ColorMessage "Configuration des hooks Git pour le projet n8n..." -ForegroundColor "Cyan"

# Fonction pour vÃ©rifier si un fichier est verrouillÃ©
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

# CrÃ©er le dossier des hooks Git s'il n'existe pas
$gitHooksDir = "$projectRoot\.git\hooks"
if (-not (Test-Path $gitHooksDir)) {
    try {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
        Write-ColorMessage "Dossier de hooks Git crÃ©Ã©" -ForegroundColor "Green"
    }
    catch {
        Write-ColorMessage "Erreur lors de la crÃ©ation du dossier de hooks Git : $_" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
}

# Configurer le hook pre-commit
if (-not $SkipPreCommit) {
    Write-ColorMessage "`nConfiguration du hook pre-commit..." -ForegroundColor "Cyan"

    $preCommitHookPath = "$gitHooksDir\pre-commit"

    # VÃ©rifier si le fichier pre-commit est verrouillÃ©
    $isLocked = Test-FileLock -Path $preCommitHookPath

    if ($isLocked) {
        Write-ColorMessage "Le fichier pre-commit hook est actuellement verrouillÃ© ou utilisÃ© par un autre processus" -ForegroundColor "Yellow"
        if (-not $Force) {
            Write-ColorMessage "Utilisez -Force pour continuer malgrÃ© le verrouillage" -ForegroundColor "Yellow"
            exit 1
        }
        else {
            Write-ColorMessage "Continuation forcÃ©e malgrÃ© le verrouillage" -ForegroundColor "Yellow"
        }
    }

    # DÃ©terminer le script Ã  utiliser
    $organizationScript = if ([string]::IsNullOrEmpty($CustomPreCommitScript)) {
        "scripts/maintenance/auto-organize-silent-improved.ps1"
    } else {
        $CustomPreCommitScript
    }

    # Utiliser le wrapper CMD pour le hook pre-commit
    $preCommitWrapperPath = Join-Path $projectRoot "..\..\D"

    if (-not (Test-Path $preCommitWrapperPath)) {
        Write-ColorMessage "Wrapper pre-commit non trouvÃ© : $preCommitWrapperPath" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }

    # CrÃ©er un fichier temporaire pour le hook
    $tempHookPath = "$gitHooksDir\pre-commit.tmp"

    # Copier le contenu du wrapper
    $preCommitHookContent = Get-Content $preCommitWrapperPath -Raw

    try {
        # Ã‰crire d'abord dans un fichier temporaire
        Set-Content -Path $tempHookPath -Value $preCommitHookContent -NoNewline

        # Puis renommer le fichier temporaire (opÃ©ration atomique)
        if (Test-Path $preCommitHookPath) {
            Remove-Item -Path $preCommitHookPath -Force
        }
        Rename-Item -Path $tempHookPath -NewName (Split-Path $preCommitHookPath -Leaf)

        Write-ColorMessage "Hook pre-commit configurÃ© avec succÃ¨s" -ForegroundColor "Green"

        # Rendre le hook exÃ©cutable sous Unix
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
    Write-ColorMessage "`nConfiguration du hook pre-commit ignorÃ©e (option -SkipPreCommit)" -ForegroundColor "Yellow"
}

# Configurer le hook pre-push
if (-not $SkipPrePush) {
    Write-ColorMessage "`nConfiguration du hook pre-push..." -ForegroundColor "Cyan"

    $prePushHookPath = "$gitHooksDir\pre-push"

    # VÃ©rifier si le fichier pre-push est verrouillÃ©
    $isLocked = Test-FileLock -Path $prePushHookPath

    if ($isLocked) {
        Write-ColorMessage "Le fichier pre-push hook est actuellement verrouillÃ© ou utilisÃ© par un autre processus" -ForegroundColor "Yellow"
        if (-not $Force) {
            Write-ColorMessage "Utilisez -Force pour continuer malgrÃ© le verrouillage" -ForegroundColor "Yellow"
            exit 1
        }
        else {
            Write-ColorMessage "Continuation forcÃ©e malgrÃ© le verrouillage" -ForegroundColor "Yellow"
        }
    }

    # DÃ©terminer le script Ã  utiliser
    $verificationScript = if ([string]::IsNullOrEmpty($CustomPrePushScript)) {
        "scripts/utils/git/git-pre-push-check.ps1"
    } else {
        $CustomPrePushScript
    }

    # Utiliser le wrapper CMD pour le hook pre-push
    $prePushWrapperPath = Join-Path $projectRoot "..\..\D"

    if (-not (Test-Path $prePushWrapperPath)) {
        Write-ColorMessage "Wrapper pre-push non trouvÃ© : $prePushWrapperPath" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }

    # CrÃ©er un fichier temporaire pour le hook
    $tempHookPath = "$gitHooksDir\pre-push.tmp"

    # Copier le contenu du wrapper
    $prePushHookContent = Get-Content $prePushWrapperPath -Raw

    try {
        # Ã‰crire d'abord dans un fichier temporaire
        Set-Content -Path $tempHookPath -Value $prePushHookContent -NoNewline

        # Puis renommer le fichier temporaire (opÃ©ration atomique)
        if (Test-Path $prePushHookPath) {
            Remove-Item -Path $prePushHookPath -Force
        }
        Rename-Item -Path $tempHookPath -NewName (Split-Path $prePushHookPath -Leaf)

        Write-ColorMessage "Hook pre-push configurÃ© avec succÃ¨s" -ForegroundColor "Green"

        # Rendre le hook exÃ©cutable sous Unix
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
    Write-ColorMessage "`nConfiguration du hook pre-push ignorÃ©e (option -SkipPrePush)" -ForegroundColor "Yellow"
}

# Afficher un rÃ©sumÃ©
Write-ColorMessage "`nRÃ©sumÃ© de la configuration des hooks Git:" -ForegroundColor "Cyan"
Write-ColorMessage "- Hook pre-commit: $(if (-not $SkipPreCommit) { 'ConfigurÃ©' } else { 'IgnorÃ©' })" -ForegroundColor $(if (-not $SkipPreCommit) { "Green" } else { "Yellow" })
if (-not $SkipPreCommit) {
    Write-ColorMessage "  Script utilisÃ©: $organizationScript" -ForegroundColor "White"
}
Write-ColorMessage "- Hook pre-push: $(if (-not $SkipPrePush) { 'ConfigurÃ©' } else { 'IgnorÃ©' })" -ForegroundColor $(if (-not $SkipPrePush) { "Green" } else { "Yellow" })
if (-not $SkipPrePush) {
    Write-ColorMessage "  Script utilisÃ©: $verificationScript" -ForegroundColor "White"
}

# Afficher des instructions d'utilisation
Write-ColorMessage "`nInstructions d'utilisation:" -ForegroundColor "Cyan"
Write-ColorMessage "1. Les hooks Git sont maintenant configurÃ©s et s'exÃ©cuteront automatiquement lors des opÃ©rations Git." -ForegroundColor "White"
Write-ColorMessage "2. Pour dÃ©sactiver temporairement un hook, utilisez l'option --no-verify:" -ForegroundColor "White"
Write-ColorMessage "   git commit --no-verify -m \"Commit sans vÃ©rification\"" -ForegroundColor "White"
Write-ColorMessage "   git push --no-verify" -ForegroundColor "White"
Write-ColorMessage "3. Pour plus d'informations, consultez le guide: docs/guides/GUIDE_HOOKS_GIT.md" -ForegroundColor "White"

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\setup-git-hooks.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force                  Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPreCommit          Ne pas configurer le hook pre-commit" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPrePush            Ne pas configurer le hook pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CustomPreCommitScript  Chemin personnalisÃ© pour le script pre-commit" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CustomPrePushScript    Chemin personnalisÃ© pour le script pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1 -SkipPrePush" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1 -CustomPreCommitScript 'scripts/custom/my-pre-commit.ps1'" -ForegroundColor "Cyan"
}

