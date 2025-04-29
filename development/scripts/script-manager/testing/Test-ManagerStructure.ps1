#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de la structure du dossier manager.
.DESCRIPTION
    Ce script contient des tests pour vÃ©rifier la structure du dossier manager,
    en utilisant le framework Pester.
.EXAMPLE
    .\Test-ManagerStructure.ps1
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\tests",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
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

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installÃ©. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "StructureTestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Tests Pester
Describe "Tests de la structure du dossier manager" {
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

        It "Le dossier script-manager.ps1 devrait exister" {
            Test-Path -Path "$script:managerDir/script-manager.ps1" | Should -Be $true
        }

        It "Le dossier _templates devrait exister" {
            Test-Path -Path "$script:managerDir/_templates" | Should -Be $true
        }

        It "Le dossier testing devrait exister" {
            Test-Path -Path "$script:managerDir/testing" | Should -Be $true
        }
    }

    Context "Tests des fichiers principaux" {
        BeforeAll {
            $script:managerDir = "$PSScriptRoot/.."
        }

        It "Le fichier ScriptManager.ps1 devrait exister" {
            Test-Path -Path "$script:managerDir/ScriptManager.ps1" | Should -Be $true
        }

        It "Le fichier Reorganize-Scripts.ps1 devrait exister" {
            Test-Path -Path "$script:managerDir/Reorganize-Scripts.ps1" | Should -Be $true
        }

        It "Le fichier Show-ScriptInventory.ps1 devrait exister" {
            Test-Path -Path "$script:managerDir/Show-ScriptInventory.ps1" | Should -Be $true
        }
    }

    Context "Tests des templates Hygen" {
        BeforeAll {
            $script:templatesDir = "$PSScriptRoot/../_templates"
        }

        It "Le dossier _templates devrait exister" {
            Test-Path -Path $script:templatesDir | Should -Be $true
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
}

# ExÃ©cuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Log "`nRÃ©sumÃ© des tests:" -Level "INFO"
Write-Log "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -Level "INFO"
Write-Log "  Tests rÃ©ussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests ignorÃ©s: $($testResults.SkippedCount)" -Level "WARNING"
Write-Log "  DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "StructureTestResults.html"
    
    # CrÃ©er un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests de structure</title>
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
    <h1>Rapport de tests de structure</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests exÃ©cutÃ©s: $($testResults.TotalCount)</p>
        <p class="success">Tests rÃ©ussis: $($testResults.PassedCount)</p>
        <p class="error">Tests Ã©chouÃ©s: $($testResults.FailedCount)</p>
        <p class="warning">Tests ignorÃ©s: $($testResults.SkippedCount)</p>
        <p>DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <p>Pour plus de dÃ©tails, consultez le rapport XML.</p>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -Level "SUCCESS"
}

# Afficher le chemin du rapport XML
Write-Log "Rapport XML gÃ©nÃ©rÃ©: $($pesterConfig.TestResult.OutputPath)" -Level "SUCCESS"

# Retourner le code de sortie en fonction des rÃ©sultats
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests ont Ã©chouÃ©. Veuillez consulter les rapports pour plus de dÃ©tails." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Tous les tests ont rÃ©ussi!" -Level "SUCCESS"
    exit 0
}

