#Requires -Version 5.1
<#
.SYNOPSIS
    Installe un hook pre-commit Git pour organiser automatiquement les scripts de maintenance.
.DESCRIPTION
    Ce script installe un hook pre-commit Git qui vÃ©rifie si des scripts PowerShell
    ont Ã©tÃ© ajoutÃ©s Ã  la racine du dossier maintenance et les organise automatiquement.
.PARAMETER Force
    Force l'installation du hook sans demander de confirmation.
.EXAMPLE
    .\Install-PreCommitHook.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour Ã©crire dans le journal
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

# Trouver le rÃ©pertoire .git
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Log "Ce script doit Ãªtre exÃ©cutÃ© dans un dÃ©pÃ´t Git." -Level "ERROR"
    exit 1
}

$hooksDir = Join-Path -Path $repoRoot -ChildPath ".git\hooks"
$preCommitPath = Join-Path -Path $hooksDir -ChildPath "pre-commit"

# VÃ©rifier si le dossier hooks existe
if (-not (Test-Path -Path $hooksDir)) {
    if ($PSCmdlet.ShouldProcess($hooksDir, "CrÃ©er le dossier")) {
        New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null
        Write-Log "Dossier hooks crÃ©Ã©: $hooksDir" -Level "INFO"
    }
}

# Contenu du hook pre-commit
$preCommitContent = @'
#!/bin/sh
#
# Pre-commit hook pour organiser les scripts de maintenance
#

# VÃ©rifier si des fichiers PowerShell ont Ã©tÃ© ajoutÃ©s Ã  la racine du dossier maintenance
MAINTENANCE_DIR="development/scripts/maintenance"
ADDED_PS_FILES=$(git diff --cached --name-only --diff-filter=A | grep -E "^$MAINTENANCE_DIR/[^/]+\.(ps1|psm1|psd1)$")

if [ -n "$ADDED_PS_FILES" ]; then
    echo "Des fichiers PowerShell ont Ã©tÃ© ajoutÃ©s Ã  la racine du dossier maintenance:"
    echo "$ADDED_PS_FILES"
    
    # ExÃ©cuter le script d'organisation
    echo "Organisation automatique des scripts..."
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$MAINTENANCE_DIR/organize/Organize-MaintenanceScripts.ps1" -Force
    
    # Ajouter les fichiers dÃ©placÃ©s au commit
    git add "$MAINTENANCE_DIR/*"
    
    echo "Les scripts ont Ã©tÃ© organisÃ©s automatiquement."
fi

# Continuer avec le commit
exit 0
'@

# Sauvegarder le hook pre-commit existant si nÃ©cessaire
if (Test-Path -Path $preCommitPath) {
    $backupPath = "$preCommitPath.bak"
    if ($PSCmdlet.ShouldProcess($preCommitPath, "Sauvegarder le hook existant")) {
        Copy-Item -Path $preCommitPath -Destination $backupPath -Force
        Write-Log "Hook pre-commit existant sauvegardÃ©: $backupPath" -Level "INFO"
    }
}

# Ã‰crire le nouveau hook pre-commit
if ($PSCmdlet.ShouldProcess($preCommitPath, "Installer le hook pre-commit")) {
    $preCommitContent | Out-File -FilePath $preCommitPath -Encoding utf8 -NoNewline
    Write-Log "Hook pre-commit installÃ©: $preCommitPath" -Level "SUCCESS"
}

# Rendre le hook exÃ©cutable (sous Linux/macOS)
if ($PSCmdlet.ShouldProcess($preCommitPath, "Rendre le hook exÃ©cutable")) {
    # Sous Windows, cette commande ne fait rien, mais sous Linux/macOS elle rend le fichier exÃ©cutable
    git update-index --chmod=+x $preCommitPath 2>$null
    Write-Log "Hook pre-commit rendu exÃ©cutable" -Level "INFO"
}

Write-Log "Installation du hook pre-commit terminÃ©e." -Level "SUCCESS"
Write-Log "Le hook organisera automatiquement les scripts PowerShell ajoutÃ©s Ã  la racine du dossier maintenance." -Level "INFO"
