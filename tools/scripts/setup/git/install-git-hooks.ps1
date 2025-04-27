# Script d'installation robuste pour les hooks Git
# Ce script installe les hooks Git en utilisant des liens symboliques ou des copies directes

param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseSymlinks,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPreCommit,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPrePush
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

Write-ColorMessage "Installation des hooks Git pour le projet n8n..." -ForegroundColor "Cyan"

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

# Fonction pour installer un hook Git
function Install-GitHook {
    param (
        [string]$HookName,
        [string]$SourcePath
    )
    
    $hookPath = Join-Path $gitHooksDir $HookName
    
    # Supprimer le hook existant s'il existe
    if (Test-Path $hookPath) {
        try {
            Remove-Item -Path $hookPath -Force
            Write-ColorMessage "Hook $HookName existant supprimÃ©" -ForegroundColor "Yellow"
        }
        catch {
            Write-ColorMessage "Erreur lors de la suppression du hook $HookName existant : $_" -ForegroundColor "Red"
            if (-not $Force) {
                return $false
            }
        }
    }
    
    # Installer le hook
    try {
        if ($UseSymlinks) {
            # CrÃ©er un lien symbolique
            if ($IsWindows) {
                # Sous Windows, utiliser mklink
                $sourcePath = (Resolve-Path $SourcePath).Path
                $targetPath = (Resolve-Path $gitHooksDir).Path
                $hookFileName = Split-Path $SourcePath -Leaf
                
                # Utiliser cmd pour crÃ©er un lien symbolique
                $result = cmd /c mklink "$targetPath\$HookName" "$sourcePath"
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Erreur lors de la crÃ©ation du lien symbolique : $result"
                }
                
                Write-ColorMessage "Lien symbolique crÃ©Ã© pour le hook $HookName" -ForegroundColor "Green"
            }
            else {
                # Sous Unix, utiliser ln -s
                $sourcePath = (Resolve-Path $SourcePath).Path
                $targetPath = Join-Path $gitHooksDir $HookName
                
                $result = & ln -s $sourcePath $targetPath
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Erreur lors de la crÃ©ation du lien symbolique : $result"
                }
                
                Write-ColorMessage "Lien symbolique crÃ©Ã© pour le hook $HookName" -ForegroundColor "Green"
            }
        }
        else {
            # Copier le fichier
            Copy-Item -Path $SourcePath -Destination $hookPath -Force
            Write-ColorMessage "Hook $HookName installÃ© par copie" -ForegroundColor "Green"
        }
        
        # Rendre le hook exÃ©cutable sous Unix
        if (-not $IsWindows) {
            & chmod +x $hookPath
        }
        
        return $true
    }
    catch {
        Write-ColorMessage "Erreur lors de l'installation du hook $HookName : $_" -ForegroundColor "Red"
        return $false
    }
}

# Installer le hook pre-commit
if (-not $SkipPreCommit) {
    Write-ColorMessage "`nInstallation du hook pre-commit..." -ForegroundColor "Cyan"
    
    $preCommitWrapperPath = Join-Path $projectRoot "..\..\D"
    
    if (-not (Test-Path $preCommitWrapperPath)) {
        Write-ColorMessage "Wrapper pre-commit non trouvÃ© : $preCommitWrapperPath" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
    
    $success = Install-GitHook -HookName "pre-commit" -SourcePath $preCommitWrapperPath
    
    if ($success) {
        Write-ColorMessage "Hook pre-commit installÃ© avec succÃ¨s" -ForegroundColor "Green"
    }
    else {
        Write-ColorMessage "Ã‰chec de l'installation du hook pre-commit" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    Write-ColorMessage "`nInstallation du hook pre-commit ignorÃ©e (option -SkipPreCommit)" -ForegroundColor "Yellow"
}

# Installer le hook pre-push
if (-not $SkipPrePush) {
    Write-ColorMessage "`nInstallation du hook pre-push..." -ForegroundColor "Cyan"
    
    $prePushWrapperPath = Join-Path $projectRoot "..\..\D"
    
    if (-not (Test-Path $prePushWrapperPath)) {
        Write-ColorMessage "Wrapper pre-push non trouvÃ© : $prePushWrapperPath" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
    
    $success = Install-GitHook -HookName "pre-push" -SourcePath $prePushWrapperPath
    
    if ($success) {
        Write-ColorMessage "Hook pre-push installÃ© avec succÃ¨s" -ForegroundColor "Green"
    }
    else {
        Write-ColorMessage "Ã‰chec de l'installation du hook pre-push" -ForegroundColor "Red"
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    Write-ColorMessage "`nInstallation du hook pre-push ignorÃ©e (option -SkipPrePush)" -ForegroundColor "Yellow"
}

# Afficher un rÃ©sumÃ©
Write-ColorMessage "`nRÃ©sumÃ© de l'installation des hooks Git:" -ForegroundColor "Cyan"
Write-ColorMessage "- Hook pre-commit: $(if (-not $SkipPreCommit) { 'InstallÃ©' } else { 'IgnorÃ©' })" -ForegroundColor $(if (-not $SkipPreCommit) { "Green" } else { "Yellow" })
Write-ColorMessage "- Hook pre-push: $(if (-not $SkipPrePush) { 'InstallÃ©' } else { 'IgnorÃ©' })" -ForegroundColor $(if (-not $SkipPrePush) { "Green" } else { "Yellow" })
Write-ColorMessage "- MÃ©thode d'installation: $(if ($UseSymlinks) { 'Liens symboliques' } else { 'Copie directe' })" -ForegroundColor "White"

# Afficher des instructions d'utilisation
Write-ColorMessage "`nInstructions d'utilisation:" -ForegroundColor "Cyan"
Write-ColorMessage "1. Les hooks Git sont maintenant installÃ©s et s'exÃ©cuteront automatiquement lors des opÃ©rations Git." -ForegroundColor "White"
Write-ColorMessage "2. Pour dÃ©sactiver temporairement un hook, utilisez l'option --no-verify:" -ForegroundColor "White"
Write-ColorMessage "   git commit --no-verify -m \"Commit sans vÃ©rification\"" -ForegroundColor "White"
Write-ColorMessage "   git push --no-verify" -ForegroundColor "White"
Write-ColorMessage "3. Pour plus d'informations, consultez le guide: docs/guides/GUIDE_HOOKS_GIT.md" -ForegroundColor "White"

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\install-git-hooks.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force         Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -UseSymlinks   Utiliser des liens symboliques au lieu de copies directes" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPreCommit Ne pas installer le hook pre-commit" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipPrePush   Ne pas installer le hook pre-push" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\install-git-hooks.ps1" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\install-git-hooks.ps1 -UseSymlinks" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\install-git-hooks.ps1 -SkipPrePush" -ForegroundColor "Cyan"
}

