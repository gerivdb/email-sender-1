<#
.SYNOPSIS
    Script de validation des scripts d'utilitaires Hygen.

.DESCRIPTION
    Ce script exécute tous les tests des scripts d'utilitaires Hygen pour vérifier qu'ils sont valides et conformes aux attentes.

.PARAMETER Interactive
    Si spécifié, le script sera exécuté en mode interactif, permettant à l'utilisateur de répondre aux prompts.

.PARAMETER PerformanceTest
    Si spécifié, des tests de performance seront exécutés.

.PARAMETER Iterations
    Nombre d'itérations pour les tests de performance. Par défaut, 5.

.PARAMETER OutputFolder
    Dossier de sortie pour les composants générés. Par défaut, les composants seront générés dans un dossier temporaire.

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.EXAMPLE
    .\validate-hygen-utilities.ps1
    Teste tous les scripts d'utilitaires Hygen en mode non interactif.

.EXAMPLE
    .\validate-hygen-utilities.ps1 -Interactive
    Teste tous les scripts d'utilitaires Hygen en mode interactif.

.EXAMPLE
    .\validate-hygen-utilities.ps1 -PerformanceTest -Iterations 10
    Teste tous les scripts d'utilitaires Hygen et exécute des tests de performance avec 10 itérations.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-10
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Interactive = $false,

    [Parameter(Mandatory = $false)]
    [switch]$PerformanceTest = $false,

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "",

    [Parameter(Mandatory = $false)]
    [switch]$KeepGeneratedFiles = $false
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

# Fonction pour exécuter un script de test
function Invoke-TestScript {
    [CmdletBinding(SupportsShouldProcess = $true)]

    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script de test n'existe pas: $ScriptPath"
        return $false
    }

    try {
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Exécuter")) {
            $scriptCommand = "& '$ScriptPath'"
            if ($Arguments.Count -gt 0) {
                $scriptCommand += " " + ($Arguments -join " ")
            }

            Write-Info "Exécution du script de test: $scriptCommand"
            Invoke-Expression $scriptCommand

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script de test exécuté avec succès: $ScriptPath"
                return $true
            } else {
                Write-Error "Erreur lors de l'exécution du script de test: $ScriptPath (code: $LASTEXITCODE)"
                return $false
            }
        } else {
            return $true
        }
    } catch {
        Write-Error "Erreur lors de l'exécution du script de test: $ScriptPath - $_"
        return $false
    }
}

# Fonction principale
function Start-UtilitiesValidation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()
    $projectRoot = Get-ProjectPath
    $setupPath = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\setup"

    Write-Info "Validation des scripts d'utilitaires Hygen..."

    # Préparer les arguments communs
    $commonArgs = @()
    if ($KeepGeneratedFiles) {
        $commonArgs += "-KeepGeneratedFiles"
    }
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $commonArgs += "-OutputFolder '$OutputFolder'"
    }

    $results = @{}

    # Tester le script Generate-N8nComponent.ps1
    $generateComponentTestScript = Join-Path -Path $setupPath -ChildPath "test-generate-component.ps1"
    Write-Info "`nTest du script Generate-N8nComponent.ps1..."
    $generateComponentArgs = $commonArgs.Clone()
    if ($Interactive) {
        $generateComponentArgs += "-Interactive"
    }
    $results["Generate-N8nComponent"] = Invoke-TestScript -ScriptPath $generateComponentTestScript -Arguments $generateComponentArgs

    # Tester les scripts CMD
    $cmdScriptsTestScript = Join-Path -Path $setupPath -ChildPath "test-cmd-scripts.ps1"
    Write-Info "`nTest des scripts CMD..."
    $cmdScriptsArgs = @()
    if ($Interactive) {
        $cmdScriptsArgs += "-Interactive"
    }
    $results["CMD Scripts"] = Invoke-TestScript -ScriptPath $cmdScriptsTestScript -Arguments $cmdScriptsArgs

    # Tester les performances si demandé
    if ($PerformanceTest) {
        $performanceTestScript = Join-Path -Path $setupPath -ChildPath "test-performance.ps1"
        Write-Info "`nTest de performance..."
        $performanceArgs = $commonArgs.Clone()
        $performanceArgs += "-Iterations $Iterations"
        $results["Performance"] = Invoke-TestScript -ScriptPath $performanceTestScript -Arguments $performanceArgs
    } else {
        Write-Info "`nTest de performance ignoré (utilisez -PerformanceTest pour l'activer)"
    }

    # Générer un rapport de validation
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $reportPath = Join-Path -Path $n8nRoot -ChildPath "docs\hygen-utilities-validation-report.md"

    if ($PSCmdlet.ShouldProcess($reportPath, "Générer le rapport")) {
        $report = @"
# Rapport de validation des scripts d'utilitaires Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résultats des tests

| Script | Statut |
|--------|--------|
"@

        foreach ($key in $results.Keys) {
            $status = if ($results[$key]) { "✓ Valide" } else { "✗ Invalide" }
            $report += "`n| $key | $status |"
        }

        $report += @"

## Résultat global
$(if ($results.Values -notcontains $false) { "✓ Tous les scripts d'utilitaires testés sont valides" } else { "✗ Certains scripts d'utilitaires sont invalides" })

## Prochaines étapes
1. Corriger les scripts d'utilitaires invalides
2. Finaliser les tests et la documentation
3. Valider les bénéfices et l'utilité
"@

        Set-Content -Path $reportPath -Value $report
        Write-Success "Rapport de validation généré: $reportPath"
    }

    # Afficher le résultat global
    Write-Host "`nRésultat de la validation:" -ForegroundColor $infoColor
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "Valide" } else { "Invalide" }
        Write-Host "- Script $key : $status" -ForegroundColor $(if ($results[$key]) { $successColor } else { $errorColor })
    }

    if ($results.Values -notcontains $false) {
        Write-Success "`nTous les scripts d'utilitaires testés sont valides"
        return $true
    } else {
        Write-Error "`nCertains scripts d'utilitaires sont invalides"

        # Afficher les recommandations
        Write-Info "`nRecommandations:"
        foreach ($key in $results.Keys) {
            if (-not $results[$key]) {
                Write-Info "- Corriger le script $key"
            }
        }

        return $false
    }
}

# Exécuter la validation
Start-UtilitiesValidation
