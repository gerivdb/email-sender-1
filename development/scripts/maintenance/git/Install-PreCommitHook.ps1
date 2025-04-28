#Requires -Version 5.1
<#
.SYNOPSIS
    Installe un hook pre-commit Git pour organiser automatiquement les scripts de maintenance.
.DESCRIPTION
    Ce script installe un hook pre-commit Git qui vérifie si des scripts PowerShell
    ont été ajoutés à la racine du dossier maintenance et les organise automatiquement.
.PARAMETER Force
    Force l'installation du hook sans demander de confirmation.
.EXAMPLE
    .\Install-PreCommitHook.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Trouver le répertoire .git
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Log "Ce script doit être exécuté dans un dépôt Git." -Level "ERROR"
    exit 1
}

$hooksDir = Join-Path -Path $repoRoot -ChildPath ".git\hooks"
$preCommitPath = Join-Path -Path $hooksDir -ChildPath "pre-commit"

# Vérifier si le dossier hooks existe
if (-not (Test-Path -Path $hooksDir)) {
    if ($PSCmdlet.ShouldProcess($hooksDir, "Créer le dossier")) {
        New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null
        Write-Log "Dossier hooks créé: $hooksDir" -Level "INFO"
    }
}

# Contenu du hook pre-commit
$preCommitContent = @'
#!/bin/sh
#
# Pre-commit hook pour organiser les scripts de maintenance
#

# Vérifier si des fichiers PowerShell ont été ajoutés à la racine du dossier maintenance
MAINTENANCE_DIR="development/scripts/maintenance"
ADDED_PS_FILES=$(git diff --cached --name-only --diff-filter=A | grep -E "^$MAINTENANCE_DIR/[^/]+\.(ps1|psm1|psd1)$")

if [ -n "$ADDED_PS_FILES" ]; then
    echo "Des fichiers PowerShell ont été ajoutés à la racine du dossier maintenance:"
    echo "$ADDED_PS_FILES"
    
    # Exécuter le script d'organisation
    echo "Organisation automatique des scripts..."
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$MAINTENANCE_DIR/organize/Organize-MaintenanceScripts.ps1" -Force
    
    # Ajouter les fichiers déplacés au commit
    git add "$MAINTENANCE_DIR/*"
    
    echo "Les scripts ont été organisés automatiquement."
fi

# Continuer avec le commit
exit 0
'@

# Sauvegarder le hook pre-commit existant si nécessaire
if (Test-Path -Path $preCommitPath) {
    $backupPath = "$preCommitPath.bak"
    if ($PSCmdlet.ShouldProcess($preCommitPath, "Sauvegarder le hook existant")) {
        Copy-Item -Path $preCommitPath -Destination $backupPath -Force
        Write-Log "Hook pre-commit existant sauvegardé: $backupPath" -Level "INFO"
    }
}

# Écrire le nouveau hook pre-commit
if ($PSCmdlet.ShouldProcess($preCommitPath, "Installer le hook pre-commit")) {
    $preCommitContent | Out-File -FilePath $preCommitPath -Encoding utf8 -NoNewline
    Write-Log "Hook pre-commit installé: $preCommitPath" -Level "SUCCESS"
}

# Rendre le hook exécutable (sous Linux/macOS)
if ($PSCmdlet.ShouldProcess($preCommitPath, "Rendre le hook exécutable")) {
    # Sous Windows, cette commande ne fait rien, mais sous Linux/macOS elle rend le fichier exécutable
    git update-index --chmod=+x $preCommitPath 2>$null
    Write-Log "Hook pre-commit rendu exécutable" -Level "INFO"
}

Write-Log "Installation du hook pre-commit terminée." -Level "SUCCESS"
Write-Log "Le hook organisera automatiquement les scripts PowerShell ajoutés à la racine du dossier maintenance." -Level "INFO"
