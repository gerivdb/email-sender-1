#Requires -Version 5.1
<#
.SYNOPSIS
    Installe un hook pre-commit pour exÃ©cuter les tests unitaires avant chaque commit.
.DESCRIPTION
    Ce script installe un hook pre-commit Git qui exÃ©cute les tests unitaires simplifiÃ©s
    avant chaque commit. Si les tests Ã©chouent, le commit est annulÃ©.
.PARAMETER Force
    Force l'installation du hook sans demander de confirmation.
.EXAMPLE
    .\Install-TestPreCommitHook.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
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

# VÃ©rifier si Git est installÃ©
if (-not (Get-Command -Name "git" -ErrorAction SilentlyContinue)) {
    Write-Log "Git n'est pas installÃ© ou n'est pas dans le PATH." -Level "ERROR"
    exit 1
}

# VÃ©rifier si le dÃ©pÃ´t Git existe
$gitDir = git rev-parse --git-dir 2>$null
if (-not $gitDir) {
    Write-Log "Le rÃ©pertoire courant n'est pas un dÃ©pÃ´t Git." -Level "ERROR"
    exit 1
}

# Chemin du hook pre-commit
$preCommitPath = Join-Path -Path $gitDir -ChildPath "hooks/pre-commit"

# Contenu du hook pre-commit
$hookContent = @'
#!/bin/sh
# Hook pre-commit pour exÃ©cuter les tests unitaires avant chaque commit

# Sauvegarder les fichiers modifiÃ©s
git stash -q --keep-index

# ExÃ©cuter les tests unitaires simplifiÃ©s
echo "ExÃ©cution des tests unitaires simplifiÃ©s..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "development/scripts/mode-manager/testing/Run-SimplifiedTests.ps1" -OutputPath "development/scripts/mode-manager/testing/reports/tests"

# RÃ©cupÃ©rer le code de sortie
RESULT=$?

# Restaurer les fichiers modifiÃ©s
git stash pop -q

# Si les tests ont Ã©chouÃ©, annuler le commit
if [ $RESULT -ne 0 ]; then
    echo "Les tests unitaires ont Ã©chouÃ©. Le commit a Ã©tÃ© annulÃ©."
    echo "Consultez le rapport de test pour plus de dÃ©tails: development/scripts/mode-manager/testing/reports/tests/SimplifiedTestResults.html"
    exit 1
fi

# Si tout va bien, continuer avec le commit
exit 0
'@

# VÃ©rifier si le hook existe dÃ©jÃ 
$hookExists = Test-Path -Path $preCommitPath
if ($hookExists) {
    $currentContent = Get-Content -Path $preCommitPath -Raw
    if ($currentContent -match "ExÃ©cution des tests unitaires simplifiÃ©s") {
        Write-Log "Le hook pre-commit pour les tests unitaires est dÃ©jÃ  installÃ©." -Level "INFO"
        
        if (-not $Force) {
            $confirmation = Read-Host "Voulez-vous remplacer le hook existant? (O/N)"
            if ($confirmation -ne "O") {
                Write-Log "Installation annulÃ©e." -Level "WARNING"
                exit 0
            }
        }
    }
    else {
        Write-Log "Un hook pre-commit existe dÃ©jÃ , mais il ne contient pas le code pour exÃ©cuter les tests unitaires." -Level "WARNING"
        
        if (-not $Force) {
            $confirmation = Read-Host "Voulez-vous ajouter le code pour exÃ©cuter les tests unitaires au hook existant? (O/N)"
            if ($confirmation -ne "O") {
                Write-Log "Installation annulÃ©e." -Level "WARNING"
                exit 0
            }
            
            # Ajouter le code au hook existant
            $hookContent = $currentContent + "`n`n" + $hookContent
        }
    }
}

# CrÃ©er le dossier hooks s'il n'existe pas
$hooksDir = Join-Path -Path $gitDir -ChildPath "hooks"
if (-not (Test-Path -Path $hooksDir)) {
    if ($PSCmdlet.ShouldProcess($hooksDir, "CrÃ©er le dossier")) {
        New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null
    }
}

# Installer le hook
if ($PSCmdlet.ShouldProcess($preCommitPath, "Installer le hook pre-commit")) {
    $hookContent | Out-File -FilePath $preCommitPath -Encoding utf8 -Force
    
    # Rendre le hook exÃ©cutable (sous Linux/macOS)
    if ($IsLinux -or $IsMacOS) {
        chmod +x $preCommitPath
    }
    
    Write-Log "Hook pre-commit installÃ© avec succÃ¨s." -Level "SUCCESS"
    Write-Log "Les tests unitaires simplifiÃ©s seront exÃ©cutÃ©s avant chaque commit." -Level "INFO"
}
else {
    Write-Log "Installation annulÃ©e." -Level "WARNING"
}

