#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés de la structure du dossier manager.
.DESCRIPTION
    Ce script contient des tests simplifiés pour vérifier la structure du dossier manager,
    en utilisant le framework Pester.
.EXAMPLE
    .\Test-ManagerStructureSimple.ps1
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\tests",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
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

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installé. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "SimpleStructureTestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Tests Pester
Describe "Tests simplifiés de la structure du dossier manager" {
    Context "Tests de la structure des dossiers" {
        BeforeAll {
            $script:managerDir = "$PSScriptRoot/.."
        }

        It "Le dossier manager devrait exister" {
            Test-Path -Path $script:managerDir | Should -Be $true
        }

        It "Le dossier README.md devrait exister" {
            Test-Path -Path "$script:managerDir/README.md" | Should -Be $true
        }

        It "Le dossier testing devrait exister" {
            Test-Path -Path "$script:managerDir/testing" | Should -Be $true
        }

        It "Le dossier _templates devrait exister" {
            Test-Path -Path "$script:managerDir/_templates" | Should -Be $true
        }
    }

    Context "Tests des templates Hygen" {
        BeforeAll {
            $script:templatesDir = "$PSScriptRoot/../_templates"
        }

        It "Le fichier .hygen.js devrait exister" {
            Test-Path -Path "$script:templatesDir/.hygen.js" | Should -Be $true
        }

        It "Le dossier script/new devrait exister" {
            Test-Path -Path "$script:templatesDir/script/new" | Should -Be $true
        }

        It "Le dossier module/new devrait exister" {
            Test-Path -Path "$script:templatesDir/module/new" | Should -Be $true
        }
    }

    Context "Tests des fonctions exportées" {
        BeforeAll {
            # Charger les fonctions à tester
            . "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1"
        }

        It "La fonction Get-ScriptCategory devrait être définie" {
            Get-Command -Name Get-ScriptCategory -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "La fonction Backup-File devrait être définie" {
            Get-Command -Name Backup-File -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "La fonction Move-ScriptToCategory devrait être définie" {
            Get-Command -Name Move-ScriptToCategory -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

# Exécuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Log "`nRésumé des tests:" -Level "INFO"
Write-Log "  Tests exécutés: $($testResults.TotalCount)" -Level "INFO"
Write-Log "  Tests réussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "  Tests échoués: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests ignorés: $($testResults.SkippedCount)" -Level "WARNING"
Write-Log "  Durée totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# Générer un rapport HTML si demandé
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "SimpleStructureTestResults.html"
    
    # Créer un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests de structure simplifiés</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .summary { margin-bottom: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Rapport de tests de structure simplifiés</h1>
    <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés: $($testResults.TotalCount)</p>
        <p class="success">Tests réussis: $($testResults.PassedCount)</p>
        <p class="error">Tests échoués: $($testResults.FailedCount)</p>
        <p class="warning">Tests ignorés: $($testResults.SkippedCount)</p>
        <p>Durée totale: $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <p>Pour plus de détails, consultez le rapport XML.</p>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML généré: $htmlPath" -Level "SUCCESS"
}

# Afficher le chemin du rapport XML
Write-Log "Rapport XML généré: $($pesterConfig.TestResult.OutputPath)" -Level "SUCCESS"

# Retourner le code de sortie en fonction des résultats
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests ont échoué. Veuillez consulter les rapports pour plus de détails." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Tous les tests ont réussi!" -Level "SUCCESS"
    exit 0
}
