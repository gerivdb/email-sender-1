<#
.SYNOPSIS
    Script de validation des templates Hygen.

.DESCRIPTION
    Ce script exécute tous les tests de templates Hygen pour vérifier qu'ils sont valides et conformes aux attentes.

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après les tests.

.PARAMETER TestPowerShell
    Si spécifié, seul le template pour les scripts PowerShell sera testé.

.PARAMETER TestWorkflow
    Si spécifié, seul le template pour les workflows n8n sera testé.

.PARAMETER TestDocumentation
    Si spécifié, seul le template pour la documentation sera testé.

.PARAMETER TestIntegration
    Si spécifié, seul le template pour les intégrations sera testé.

.PARAMETER OutputFolder
    Dossier de sortie pour les fichiers générés. Par défaut, les fichiers seront générés dans les dossiers standard.

.EXAMPLE
    .\validate-hygen-templates.ps1
    Teste tous les templates Hygen.

.EXAMPLE
    .\validate-hygen-templates.ps1 -TestPowerShell -KeepGeneratedFiles
    Teste uniquement le template pour les scripts PowerShell et conserve les fichiers générés.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-09
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [switch]$KeepGeneratedFiles = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestPowerShell = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestWorkflow = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestDocumentation = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestIntegration = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = ""
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
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
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$false)]
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
    }
    catch {
        Write-Error "Erreur lors de l'exécution du script de test: $ScriptPath - $_"
        return $false
    }
}

# Fonction principale
function Start-TemplateValidation {
    $projectRoot = Get-ProjectPath
    $setupPath = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\setup"
    
    Write-Info "Validation des templates Hygen..."
    
    # Déterminer quels templates tester
    $testAll = -not ($TestPowerShell -or $TestWorkflow -or $TestDocumentation -or $TestIntegration)
    
    # Préparer les arguments communs
    $commonArgs = @()
    if ($KeepGeneratedFiles) {
        $commonArgs += "-KeepGeneratedFiles"
    }
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $commonArgs += "-OutputFolder '$OutputFolder'"
    }
    
    $results = @{}
    
    # Tester le template pour les scripts PowerShell
    if ($testAll -or $TestPowerShell) {
        $powerShellTestScript = Join-Path -Path $setupPath -ChildPath "test-powershell-template.ps1"
        Write-Info "`nTest du template pour les scripts PowerShell..."
        $results["PowerShell"] = Invoke-TestScript -ScriptPath $powerShellTestScript -Arguments $commonArgs
    }
    
    # Tester le template pour les workflows n8n
    if ($testAll -or $TestWorkflow) {
        $workflowTestScript = Join-Path -Path $setupPath -ChildPath "test-workflow-template.ps1"
        Write-Info "`nTest du template pour les workflows n8n..."
        $results["Workflow"] = Invoke-TestScript -ScriptPath $workflowTestScript -Arguments $commonArgs
    }
    
    # Tester le template pour la documentation
    if ($testAll -or $TestDocumentation) {
        $documentationTestScript = Join-Path -Path $setupPath -ChildPath "test-documentation-template.ps1"
        Write-Info "`nTest du template pour la documentation..."
        $results["Documentation"] = Invoke-TestScript -ScriptPath $documentationTestScript -Arguments $commonArgs
    }
    
    # Tester le template pour les intégrations
    if ($testAll -or $TestIntegration) {
        $integrationTestScript = Join-Path -Path $setupPath -ChildPath "test-integration-template.ps1"
        Write-Info "`nTest du template pour les intégrations..."
        $results["Integration"] = Invoke-TestScript -ScriptPath $integrationTestScript -Arguments $commonArgs
    }
    
    # Générer un rapport de validation
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $reportPath = Join-Path -Path $n8nRoot -ChildPath "docs\hygen-templates-validation-report.md"
    
    if ($PSCmdlet.ShouldProcess($reportPath, "Générer le rapport")) {
        $report = @"
# Rapport de validation des templates Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résultats des tests

| Template | Statut |
|----------|--------|
"@
        
        foreach ($key in $results.Keys) {
            $status = if ($results[$key]) { "✓ Valide" } else { "✗ Invalide" }
            $report += "`n| $key | $status |"
        }
        
        $report += @"

## Résultat global
$(if ($results.Values -notcontains $false) { "✓ Tous les templates testés sont valides" } else { "✗ Certains templates sont invalides" })

## Prochaines étapes
1. Corriger les templates invalides
2. Valider les scripts d'utilitaires
3. Finaliser les tests et la documentation
4. Valider les bénéfices et l'utilité
"@
        
        Set-Content -Path $reportPath -Value $report
        Write-Success "Rapport de validation généré: $reportPath"
    }
    
    # Afficher le résultat global
    Write-Host "`nRésultat de la validation:" -ForegroundColor $infoColor
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "Valide" } else { "Invalide" }
        Write-Host "- Template $key : $status" -ForegroundColor $(if ($results[$key]) { $successColor } else { $errorColor })
    }
    
    if ($results.Values -notcontains $false) {
        Write-Success "`nTous les templates testés sont valides"
        return $true
    } else {
        Write-Error "`nCertains templates sont invalides"
        
        # Afficher les recommandations
        Write-Info "`nRecommandations:"
        foreach ($key in $results.Keys) {
            if (-not $results[$key]) {
                Write-Info "- Corriger le template pour $key"
            }
        }
        
        return $false
    }
}

# Exécuter la validation
Start-TemplateValidation
