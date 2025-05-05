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

# Fonction pour afficher un message colorÃƒÂ©
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )

    Write-Host $Message -ForegroundColor $ForegroundColor
}

# VÃƒÂ©rifier si nous sommes dans un dÃƒÂ©pÃƒÂ´t Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-ColorMessage "Ce dossier n'est pas un dÃƒÂ©pÃƒÂ´t Git" -ForegroundColor "Red"
    exit 1
}

Write-ColorMessage "Configuration des hooks Git pour le projet n8n..." -ForegroundColor "Cyan"

# Fonction pour vÃƒÂ©rifier si un fichier est verrouillÃƒÂ©
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

# CrÃƒÂ©er le dossier des hooks Git s'il n'existe pas
$gitHooksDir = "$projectRoot\.git\hooks"
if (-not (Test-Path $gitHooksDir)) {
    try {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
        Write-ColorMessage "Dossier de hooks Git crÃƒÂ©ÃƒÂ©" -ForegroundColor "Green"
    }
    catch {
        Write-ColorMessage "Erreur lors de la crÃƒÂ©ation du dossier de hooks Git : $_" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
}

# Configurer le hook pre-commit
if (-not $SkipPreCommit) {
    Write-ColorMessage "`nConfiguration du hook pre-commit..." -ForegroundColor "Cyan"

    $preCommitHookPath = "$gitHooksDir\pre-commit"

    # VÃƒÂ©rifier si le fichier pre-commit est verrouillÃƒÂ©
    $isLocked = Test-FileLock -Path $preCommitHookPath

    if ($isLocked) {
        Write-ColorMessage "Le fichier pre-commit hook est actuellement verrouillÃƒÂ© ou utilisÃƒÂ© par un autre processus" -ForegroundColor "Yellow"
        if (-not $Force) {
            Write-ColorMessage "Utilisez -Force pour continuer malgrÃƒÂ© le verrouillage" -ForegroundColor "Yellow"
            exit 1
        }
        else {
            Write-ColorMessage "Continuation forcÃƒÂ©e malgrÃƒÂ© le verrouillage" -ForegroundColor "Yellow"
        }
    }

    # DÃƒÂ©terminer le script ÃƒÂ  utiliser
    $organizationScript = if ([string]::IsNullOrEmpty($CustomPreCommitScript)) {
        "development/scripts/maintenance/auto-organize-silent-improved.ps1"
    } else {
        $CustomPreCommitScript
    }

    # Utiliser le wrapper CMD pour le hook pre-commit
    $preCommitWrapperPath = Join-Path $projectRoot "..\..\D"

    if (-not (Test-Path $preCommitWrapperPath)) {
        Write-ColorMessage "Wrapper pre-commit non trouvÃƒÂ© : $preCommitWrapperPath" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }

    # CrÃƒÂ©er un fichier temporaire pour le hook
    $tempHookPath = "$gitHooksDir\pre-commit.tmp"

    # Copier le contenu du wrapper
    $preCommitHookContent = Get-Content $preCommitWrapperPath -Raw

    try {
        # Ãƒâ€°crire d'abord dans un fichier temporaire
        Set-Content -Path $tempHookPath -Value $preCommitHookContent -NoNewline

        # Puis renommer le fichier temporaire (opÃƒÂ©ration atomique)
        if (Test-Path $preCommitHookPath) {
            Remove-Item -Path $preCommitHookPath -Force
        }
        Rename-Item -Path $tempHookPath -NewName (Split-Path $preCommitHookPath -Leaf)

        Write-ColorMessage "Hook pre-commit configurÃƒÂ© avec succÃƒÂ¨s" -ForegroundColor "Green"

        # Rendre le hook exÃƒÂ©cutable sous Unix
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
    Write-ColorMessage "`nConfiguration du hook pre-commit ignorÃƒÂ©e (option -SkipPreCommit)" -ForegroundColor "Yellow"
}

# Configurer le hook pre-push
if (-not $SkipPrePush) {
    Write-ColorMessage "`nConfiguration du hook pre-push..." -ForegroundColor "Cyan"

    $prePushHookPath = "$gitHooksDir\pre-push"

    # VÃƒÂ©rifier si le fichier pre-push est verrouillÃƒÂ©
    $isLocked = Test-FileLock -Path $prePushHookPath

    if ($isLocked) {
        Write-ColorMessage "Le fichier pre-push hook est actuellement verrouillÃƒÂ© ou utilisÃƒÂ© par un autre processus" -ForegroundColor "Yellow"
        if (-not $Force) {
            Write-ColorMessage "Utilisez -Force pour continuer malgrÃƒÂ© le verrouillage" -ForegroundColor "Yellow"
            exit 1
        }
        else {
            Write-ColorMessage "Continuation forcÃƒÂ©e malgrÃƒÂ© le verrouillage" -ForegroundColor "Yellow"
        }
    }

    # DÃƒÂ©terminer le script ÃƒÂ  utiliser
    $verificationScript = if ([string]::IsNullOrEmpty($CustomPrePushScript)) {
        "development/scripts/utils/git/git-pre-push-check.ps1"
    } else {
        $CustomPrePushScript
    }

    # Utiliser le wrapper CMD pour le hook pre-push
    $prePushWrapperPath = Join-Path $projectRoot "..\..\D"

    if (-not (Test-Path $prePushWrapperPath)) {
        Write-ColorMessage "Wrapper pre-push non trouvÃƒÂ© : $prePushWrapperPath" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }

    # CrÃƒÂ©er un fichier temporaire pour le hook
    $tempHookPath = "$gitHooksDir\pre-push.tmp"

    # Copier le contenu du wrapper
    $prePushHookContent = Get-Content $prePushWrapperPath -Raw

    try {
        # Ãƒâ€°crire d'abord dans un fichier temporaire
        Set-Content -Path $tempHookPath -Value $prePushHookContent -NoNewline

        # Puis renommer le fichier temporaire (opÃƒÂ©ration atomique)
        if (Test-Path $prePushHookPath) {
            Remove-Item -Path $prePushHookPath -Force
        }
        Rename-Item -Path $tempHookPath -NewName (Split-Path $prePushHookPath -Leaf)

        Write-ColorMessage "Hook pre-push configurÃƒÂ© avec succÃƒÂ¨s" -ForegroundColor "Green"

        # Rendre le hook exÃƒÂ©cutable sous Unix
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
    Write-ColorMessage "`nConfiguration du hook pre-push ignorÃƒÂ©e (option -SkipPrePush)" -ForegroundColor "Yellow"
}

# Afficher un rÃƒÂ©sumÃƒÂ©
Write-ColorMessage "`nRÃƒÂ©sumÃƒÂ© de la configuration des hooks Git:" -ForegroundColor "Cyan"
Write-ColorMessage "- Hook pre-commit: $(if (-not $SkipPreCommit) { 'ConfigurÃƒÂ©' } else { 'IgnorÃƒÂ©' })" -ForegroundColor $(if (-not $SkipPreCommit) { "Green" } else { "Yellow" })
if (-not $SkipPreCommit) {
    Write-ColorMessage "  Script utilisÃƒÂ©: $organizationScript" -ForegroundColor "White"
}
Write-ColorMessage "- Hook pre-push: $(if (-not $SkipPrePush) { 'ConfigurÃƒÂ©' } else { 'IgnorÃƒÂ©' })" -ForegroundColor $(if (-not $SkipPrePush) { "Green" } else { "Yellow" })
if (-not $SkipPrePush) {
    Write-ColorMessage "  Script utilisÃƒÂ©: $verificationScript" -ForegroundColor "White"
}

# Afficher des instructions d'utilisation
Write-ColorMessage "`nInstructions d'utilisation:" -ForegroundColor "Cyan"
Write-ColorMessage "1. Les hooks Git sont maintenant configurÃƒÂ©s et s'exÃƒÂ©cuteront automatiquement lors des opÃƒÂ©rations Git." -ForegroundColor "White"
Write-ColorMessage "2. Pour dÃƒÂ©sactiver temporairement un hook, utilisez l'option --no-verify:" -ForegroundColor "White"
Write-ColorMessage "   git commit --no-verify -m \"Commit sans vÃƒÂ©rification\"" -ForegroundColor "White"
Write-ColorMessage "   git push --no-verify" -ForegroundColor "White"
Write-ColorMessage "3. Pour plus d'informations, consultez le guide: docs/guides/GUIDE_HOOKS_GIT.md" -ForegroundColor "White"

# Afficher l'aide si demandÃƒÂ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\setup-git-hooks.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force                  Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPreCommit          Ne pas configurer le hook pre-commit" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPrePush            Ne pas configurer le hook pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CustomPreCommitScript  Chemin personnalisÃƒÂ© pour le script pre-commit" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CustomPrePushScript    Chemin personnalisÃƒÂ© pour le script pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1 -SkipPrePush" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\setup-git-hooks.ps1 -CustomPreCommitScript 'development/scripts/custom/my-pre-commit.ps1'" -ForegroundColor "Cyan"
}

