#Requires -Version 5.1
<#
.SYNOPSIS
    Installe un hook pre-commit pour exécuter les tests unitaires avant chaque commit.
.DESCRIPTION
    Ce script installe un hook pre-commit Git qui exécute les tests unitaires simplifiés
    avant chaque commit. Si les tests échouent, le commit est annulé.
.PARAMETER Force
    Force l'installation du hook sans demander de confirmation.
.EXAMPLE
    .\Install-TestPreCommitHook.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
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

# Vérifier si Git est installé
if (-not (Get-Command -Name "git" -ErrorAction SilentlyContinue)) {
    Write-Log "Git n'est pas installé ou n'est pas dans le PATH." -Level "ERROR"
    exit 1
}

# Vérifier si le dépôt Git existe
$gitDir = git rev-parse --git-dir 2>$null
if (-not $gitDir) {
    Write-Log "Le répertoire courant n'est pas un dépôt Git." -Level "ERROR"
    exit 1
}

# Chemin du hook pre-commit
$preCommitPath = Join-Path -Path $gitDir -ChildPath "hooks/pre-commit"

# Contenu du hook pre-commit
$hookContent = @'
#!/bin/sh
# Hook pre-commit pour exécuter les tests unitaires avant chaque commit

# Sauvegarder les fichiers modifiés
git stash -q --keep-index

# Exécuter les tests unitaires simplifiés
echo "Exécution des tests unitaires simplifiés..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "development/scripts/manager/testing/Run-SimplifiedTests.ps1" -OutputPath "development/scripts/manager/testing/reports/tests"

# Récupérer le code de sortie
RESULT=$?

# Restaurer les fichiers modifiés
git stash pop -q

# Si les tests ont échoué, annuler le commit
if [ $RESULT -ne 0 ]; then
    echo "Les tests unitaires ont échoué. Le commit a été annulé."
    echo "Consultez le rapport de test pour plus de détails: development/scripts/manager/testing/reports/tests/SimplifiedTestResults.html"
    exit 1
fi

# Si tout va bien, continuer avec le commit
exit 0
'@

# Vérifier si le hook existe déjà
$hookExists = Test-Path -Path $preCommitPath
if ($hookExists) {
    $currentContent = Get-Content -Path $preCommitPath -Raw
    if ($currentContent -match "Exécution des tests unitaires simplifiés") {
        Write-Log "Le hook pre-commit pour les tests unitaires est déjà installé." -Level "INFO"
        
        if (-not $Force) {
            $confirmation = Read-Host "Voulez-vous remplacer le hook existant? (O/N)"
            if ($confirmation -ne "O") {
                Write-Log "Installation annulée." -Level "WARNING"
                exit 0
            }
        }
    }
    else {
        Write-Log "Un hook pre-commit existe déjà, mais il ne contient pas le code pour exécuter les tests unitaires." -Level "WARNING"
        
        if (-not $Force) {
            $confirmation = Read-Host "Voulez-vous ajouter le code pour exécuter les tests unitaires au hook existant? (O/N)"
            if ($confirmation -ne "O") {
                Write-Log "Installation annulée." -Level "WARNING"
                exit 0
            }
            
            # Ajouter le code au hook existant
            $hookContent = $currentContent + "`n`n" + $hookContent
        }
    }
}

# Créer le dossier hooks s'il n'existe pas
$hooksDir = Join-Path -Path $gitDir -ChildPath "hooks"
if (-not (Test-Path -Path $hooksDir)) {
    if ($PSCmdlet.ShouldProcess($hooksDir, "Créer le dossier")) {
        New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null
    }
}

# Installer le hook
if ($PSCmdlet.ShouldProcess($preCommitPath, "Installer le hook pre-commit")) {
    $hookContent | Out-File -FilePath $preCommitPath -Encoding utf8 -Force
    
    # Rendre le hook exécutable (sous Linux/macOS)
    if ($IsLinux -or $IsMacOS) {
        chmod +x $preCommitPath
    }
    
    Write-Log "Hook pre-commit installé avec succès." -Level "SUCCESS"
    Write-Log "Les tests unitaires simplifiés seront exécutés avant chaque commit." -Level "INFO"
}
else {
    Write-Log "Installation annulée." -Level "WARNING"
}
