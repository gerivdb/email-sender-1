#Requires -Version 5.1
<#
.SYNOPSIS
    Test simple de la structure de documentation Augment.

.DESCRIPTION
    Ce script vÃ©rifie que la structure de documentation Augment est correctement
    implÃ©mentÃ©e, sans dÃ©pendre de Pester.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param()

# DÃ©finir le chemin racine du projet
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testsPassed = 0
$testsFailed = 0
$testsTotal = 0

function Test-Condition {
    param (
        [string]$Name,
        [scriptblock]$Condition,
        [string]$FailureMessage
    )
    
    $testsTotal++
    Write-Host "Test: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Condition
        if ($result) {
            Write-Host "  RÃ©sultat: RÃ©ussi" -ForegroundColor Green
            $script:testsPassed++
            return $true
        } else {
            Write-Host "  RÃ©sultat: Ã‰chouÃ©" -ForegroundColor Red
            Write-Host "  $FailureMessage" -ForegroundColor Yellow
            $script:testsFailed++
            return $false
        }
    } catch {
        Write-Host "  RÃ©sultat: Erreur" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Yellow
        $script:testsFailed++
        return $false
    }
}

# Tests de structure des dossiers
Test-Condition -Name "Le dossier .augment existe" -Condition {
    Test-Path -Path "$projectRoot\.augment" -PathType Container
} -FailureMessage "Le dossier .augment n'existe pas"

Test-Condition -Name "Le dossier .augment/guidelines existe" -Condition {
    Test-Path -Path "$projectRoot\.augment\guidelines" -PathType Container
} -FailureMessage "Le dossier .augment/guidelines n'existe pas"

Test-Condition -Name "Le dossier .augment/context existe" -Condition {
    Test-Path -Path "$projectRoot\.augment\context" -PathType Container
} -FailureMessage "Le dossier .augment/context n'existe pas"

# Tests des fichiers de configuration
Test-Condition -Name "Le fichier config.json existe" -Condition {
    Test-Path -Path "$projectRoot\.augment\config.json" -PathType Leaf
} -FailureMessage "Le fichier config.json n'existe pas"

Test-Condition -Name "Le fichier README.md existe" -Condition {
    Test-Path -Path "$projectRoot\.augment\README.md" -PathType Leaf
} -FailureMessage "Le fichier README.md n'existe pas"

# Tests des fichiers de guidelines
$guidelinesFiles = @(
    "frontend_rules.md",
    "backend_rules.md",
    "project_standards.md",
    "implementation_steps.md"
)

foreach ($file in $guidelinesFiles) {
    Test-Condition -Name "Le fichier guidelines/$file existe" -Condition {
        Test-Path -Path "$projectRoot\.augment\guidelines\$file" -PathType Leaf
    } -FailureMessage "Le fichier guidelines/$file n'existe pas"
}

# Tests des fichiers de contexte
$contextFiles = @(
    "app_flow.md",
    "tech_stack.md",
    "design_system.md"
)

foreach ($file in $contextFiles) {
    Test-Condition -Name "Le fichier context/$file existe" -Condition {
        Test-Path -Path "$projectRoot\.augment\context\$file" -PathType Leaf
    } -FailureMessage "Le fichier context/$file n'existe pas"
}

# Test du contenu des fichiers
Test-Condition -Name "Les fichiers de guidelines contiennent du contenu" -Condition {
    $allValid = $true
    foreach ($file in $guidelinesFiles) {
        $content = Get-Content -Path "$projectRoot\.augment\guidelines\$file" -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Host "  Le fichier guidelines/$file est vide" -ForegroundColor Yellow
            $allValid = $false
        }
    }
    $allValid
} -FailureMessage "Un ou plusieurs fichiers de guidelines sont vides"

Test-Condition -Name "Les fichiers de contexte contiennent du contenu" -Condition {
    $allValid = $true
    foreach ($file in $contextFiles) {
        $content = Get-Content -Path "$projectRoot\.augment\context\$file" -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Host "  Le fichier context/$file est vide" -ForegroundColor Yellow
            $allValid = $false
        }
    }
    $allValid
} -FailureMessage "Un ou plusieurs fichiers de contexte sont vides"

# Test de la configuration
Test-Condition -Name "Le fichier config.json contient les fournisseurs de contexte" -Condition {
    $configContent = Get-Content -Path "$projectRoot\.augment\config.json" -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($configContent)) {
        return $false
    }
    
    try {
        $config = $configContent | ConvertFrom-Json
        $hasGuidelines = $false
        $hasContext = $false
        
        foreach ($provider in $config.context_providers) {
            if ($provider.name -eq "guidelines") {
                $hasGuidelines = $true
            }
            if ($provider.name -eq "context") {
                $hasContext = $true
            }
        }
        
        return $hasGuidelines -and $hasContext
    } catch {
        Write-Host "  Erreur lors de l'analyse du fichier config.json: $_" -ForegroundColor Yellow
        return $false
    }
} -FailureMessage "Le fichier config.json ne contient pas les fournisseurs de contexte guidelines et context"

# Test de l'intÃ©gration Ã  la roadmap
Test-Condition -Name "Le fichier de tÃ¢che dans la roadmap existe" -Condition {
    Test-Path -Path "$projectRoot\Roadmap\tasks\augment_documentation_structure.md" -PathType Leaf
} -FailureMessage "Le fichier de tÃ¢che dans la roadmap n'existe pas"

# Afficher le rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s: $testsTotal" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $testsPassed" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $testsFailed" -ForegroundColor Red

# GÃ©nÃ©rer un rapport simple
$reportPath = "$projectRoot\tests\augment\reports"
if (-not (Test-Path -Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
}

$reportFile = "$reportPath\AugmentStructure-Results.txt"
Set-Content -Path $reportFile -Value "Rapport des tests de structure Augment - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
Add-Content -Path $reportFile -Value "Tests exÃ©cutÃ©s: $testsTotal"
Add-Content -Path $reportFile -Value "Tests rÃ©ussis: $testsPassed"
Add-Content -Path $reportFile -Value "Tests Ã©chouÃ©s: $testsFailed"

Write-Host "`nRapport gÃ©nÃ©rÃ©: $reportFile" -ForegroundColor Green

# Retourner un code de sortie basÃ© sur les rÃ©sultats
if ($testsFailed -gt 0) {
    Write-Host "`nDes tests ont Ã©chouÃ©. Veuillez consulter le rapport pour plus de dÃ©tails." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
}
