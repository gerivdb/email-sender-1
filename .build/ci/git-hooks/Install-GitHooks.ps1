<#
.SYNOPSIS
    Installe les hooks Git dans le dépôt local.
.DESCRIPTION
    Ce script installe les hooks Git dans le dépôt local en créant des liens symboliques
    vers les scripts dans le répertoire git-hooks.
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter()]
    [switch]$Force
)

# Obtenir le chemin du dépôt Git
$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    Write-Error "Ce script doit être exécuté dans un dépôt Git."
    exit 1
}

# Chemins des répertoires
$hooksDir = Join-Path -Path $repoRoot -ChildPath ".git\hooks"
$sourceDir = Join-Path -Path $repoRoot -ChildPath "git-hooks"

# Vérifier si le répertoire des hooks existe
if (-not (Test-Path -Path $hooksDir)) {
    Write-Error "Répertoire des hooks Git non trouvé: $hooksDir"
    exit 1
}

# Vérifier si le répertoire source existe
if (-not (Test-Path -Path $sourceDir)) {
    Write-Error "Répertoire source des hooks non trouvé: $sourceDir"
    exit 1
}

# Liste des hooks à installer
$hooks = @(
    "pre-commit",
    "post-commit"
)

# Installer chaque hook
foreach ($hook in $hooks) {
    $sourcePath = Join-Path -Path $sourceDir -ChildPath $hook
    $targetPath = Join-Path -Path $hooksDir -ChildPath $hook

    # Vérifier si le hook source existe
    if (-not (Test-Path -Path $sourcePath)) {
        Write-Warning "Hook source non trouvé: $sourcePath"
        continue
    }

    # Vérifier si le hook cible existe déjà
    if (Test-Path -Path $targetPath) {
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($targetPath, "Supprimer")) {
                Remove-Item -Path $targetPath -Force
            }
        } else {
            Write-Warning "Hook cible existe déjà: $targetPath. Utilisez -Force pour remplacer."
            continue
        }
    }

    # Créer un script wrapper pour le hook
    $wrapperContent = @"
#!/bin/sh
# Hook wrapper généré automatiquement
# Redirige vers le script PowerShell correspondant

# Chemin vers le script PowerShell
SCRIPT_PATH="$(git rev-parse --show-toplevel)/git-hooks/$hook"

# Vérifier si le script existe
if [ ! -f "\$SCRIPT_PATH" ]; then
    echo "Erreur: Script non trouvé: \$SCRIPT_PATH"
    exit 1
fi

# Exécuter le script
exec "\$SCRIPT_PATH" "\$@"
"@

    if ($PSCmdlet.ShouldProcess($targetPath, "Créer")) {
        $wrapperContent | Out-File -FilePath $targetPath -Encoding ascii

        # Rendre le script exécutable (sous Unix/Linux)
        if ($IsLinux -or $IsMacOS) {
            chmod +x $targetPath
        }

        Write-Host "Hook installé: $hook" -ForegroundColor Green
    }
}

Write-Host "Installation des hooks Git terminée." -ForegroundColor Green
