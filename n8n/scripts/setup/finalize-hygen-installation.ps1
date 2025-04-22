<#
.SYNOPSIS
    Script de finalisation de l'installation de Hygen.

.DESCRIPTION
    Ce script exécute toutes les vérifications nécessaires pour finaliser l'installation de Hygen
    et corrige les problèmes détectés si possible.

.PARAMETER Fix
    Si spécifié, le script tentera de corriger les problèmes détectés.

.PARAMETER SkipCleanTest
    Si spécifié, le script ne testera pas l'installation dans un environnement propre.

.EXAMPLE
    .\finalize-hygen-installation.ps1
    Vérifie l'installation de Hygen sans corriger les problèmes.

.EXAMPLE
    .\finalize-hygen-installation.ps1 -Fix
    Vérifie l'installation de Hygen et tente de corriger les problèmes.

.EXAMPLE
    .\finalize-hygen-installation.ps1 -Fix -SkipCleanTest
    Vérifie l'installation de Hygen, tente de corriger les problèmes, mais ne teste pas l'installation dans un environnement propre.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-08
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Fix = $false,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCleanTest = $false
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour vérifier si Hygen est installé
function Test-HygenInstallation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()
    try {
        $output = npx hygen --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Hygen est installé (version: $output)"
            return $true
        } else {
            Write-Error "Hygen n'est pas installé ou n'est pas accessible"

            if ($Fix) {
                Write-Info "Installation de Hygen..."
                if ($PSCmdlet.ShouldProcess("Hygen", "Installer")) {
                    try {
                        npm install --save-dev hygen
                        $output = npx hygen --version 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Success "Hygen a été installé avec succès (version: $output)"
                            return $true
                        } else {
                            Write-Error "L'installation de Hygen a échoué"
                            return $false
                        }
                    } catch {
                        Write-Error "Erreur lors de l'installation de Hygen: $_"
                        return $false
                    }
                }
            }

            return $false
        }
    } catch {
        Write-Error "Erreur lors de la vérification de l'installation de Hygen: $_"
        return $false
    }
}

# Fonction pour exécuter un script
function Invoke-Script {
    [CmdletBinding(SupportsShouldProcess = $true)]

    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $false
    }

    try {
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Exécuter")) {
            $scriptCommand = "& '$ScriptPath'"
            if ($Arguments.Count -gt 0) {
                $scriptCommand += " " + ($Arguments -join " ")
            }

            Write-Info "Exécution du script: $scriptCommand"
            Invoke-Expression $scriptCommand

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script exécuté avec succès: $ScriptPath"
                return $true
            } else {
                Write-Error "Erreur lors de l'exécution du script: $ScriptPath (code: $LASTEXITCODE)"
                return $false
            }
        } else {
            return $true
        }
    } catch {
        Write-Error "Erreur lors de l'exécution du script: $ScriptPath - $_"
        return $false
    }
}

# Fonction principale
function Start-Finalization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()
    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $setupPath = Join-Path -Path $n8nRoot -ChildPath "scripts\setup"

    Write-Info "Finalisation de l'installation de Hygen..."

    # Étape 1: Vérifier si Hygen est installé
    $hygenInstalled = Test-HygenInstallation
    if (-not $hygenInstalled) {
        Write-Error "Impossible de continuer sans Hygen"
        return $false
    }

    # Étape 2: Vérifier et corriger la structure de dossiers
    $validateStructureScript = Join-Path -Path $setupPath -ChildPath "validate-hygen-structure.ps1"
    $validateArgs = @()
    if ($Fix) {
        $validateArgs += "-Fix"
    }

    $structureValid = Invoke-Script -ScriptPath $validateStructureScript -Arguments $validateArgs
    if (-not $structureValid) {
        Write-Error "La structure de dossiers n'est pas valide"
        return $false
    }

    # Étape 3: Vérifier l'installation
    $verifyScript = Join-Path -Path $setupPath -ChildPath "verify-hygen-installation.ps1"
    $installationValid = Invoke-Script -ScriptPath $verifyScript
    if (-not $installationValid) {
        Write-Error "L'installation n'est pas valide"
        return $false
    }

    # Étape 4: Tester l'installation dans un environnement propre
    if (-not $SkipCleanTest) {
        $testScript = Join-Path -Path $setupPath -ChildPath "test-hygen-clean-install.ps1"
        $testValid = Invoke-Script -ScriptPath $testScript
        if (-not $testValid) {
            Write-Error "Le test d'installation dans un environnement propre a échoué"
            return $false
        }
    } else {
        Write-Warning "Test d'installation dans un environnement propre ignoré"
    }

    # Étape 5: Générer un rapport de finalisation
    $reportPath = Join-Path -Path $n8nRoot -ChildPath "docs\hygen-installation-report.md"
    if ($PSCmdlet.ShouldProcess($reportPath, "Générer le rapport")) {
        $report = @"
# Rapport de finalisation de l'installation de Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Statut
- Hygen installé: $hygenInstalled
- Structure de dossiers valide: $structureValid
- Installation valide: $installationValid
- Test d'installation propre: $(if (-not $SkipCleanTest) { $testValid } else { "Ignoré" })

## Résultat global
$(if ($hygenInstalled -and $structureValid -and $installationValid -and ($SkipCleanTest -or $testValid)) { "✓ Installation finalisée avec succès" } else { "✗ Installation incomplète" })

## Prochaines étapes
1. Tester les templates Hygen
2. Valider les scripts d'utilitaires
3. Finaliser les tests et la documentation
4. Valider les bénéfices et l'utilité
"@

        Set-Content -Path $reportPath -Value $report
        Write-Success "Rapport de finalisation généré: $reportPath"
    }

    # Afficher le résultat global
    Write-Host "`nRésultat de la finalisation:" -ForegroundColor $infoColor
    if ($hygenInstalled -and $structureValid -and $installationValid -and ($SkipCleanTest -or $testValid)) {
        Write-Success "Installation finalisée avec succès"

        # Afficher les prochaines étapes
        Write-Info "`nProchaines étapes:"
        Write-Info "1. Tester les templates Hygen"
        Write-Info "2. Valider les scripts d'utilitaires"
        Write-Info "3. Finaliser les tests et la documentation"
        Write-Info "4. Valider les bénéfices et l'utilité"

        return $true
    } else {
        Write-Error "Installation incomplète"

        # Afficher les recommandations
        Write-Info "`nRecommandations:"
        if (-not $hygenInstalled) {
            Write-Info "- Installez Hygen avec 'npm install --save-dev hygen'"
        }
        if (-not $structureValid) {
            Write-Info "- Corrigez la structure de dossiers avec 'n8n\scripts\setup\validate-hygen-structure.ps1 -Fix'"
        }
        if (-not $installationValid) {
            Write-Info "- Vérifiez l'installation avec 'n8n\scripts\setup\verify-hygen-installation.ps1'"
        }
        if (-not $SkipCleanTest -and -not $testValid) {
            Write-Info "- Vérifiez le test d'installation propre avec 'n8n\scripts\setup\test-hygen-clean-install.ps1'"
        }

        return $false
    }
}

# Exécuter la finalisation
Start-Finalization
