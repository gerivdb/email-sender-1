﻿#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests de cas limites pour le script manager.
.DESCRIPTION
    Ce script exÃ©cute des tests de cas limites (edge cases) pour vÃ©rifier que
    le script manager fonctionne correctement dans des situations extrÃªmes.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.EXAMPLE
    .\Run-EdgeCaseTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\edge-cases",
    
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
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "EdgeCaseTestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# DÃ©finir les fonctions pour les tests
function Get-ScriptCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [string]$Content = ""
    )
    
    # Classification prÃ©dÃ©finie des scripts
    $scriptClassification = @{
        "ScriptManager.ps1" = "core"
        "Reorganize-Scripts.ps1" = "organization"
        "Show-ScriptInventory.ps1" = "inventory"
        "README.md" = "core"
    }
    
    # VÃ©rifier si le script a une classification prÃ©dÃ©finie
    if ($scriptClassification.ContainsKey($FileName)) {
        return $scriptClassification[$FileName]
    }
    
    $lowerName = $FileName.ToLower()
    
    # CatÃ©gorisation basÃ©e sur des mots-clÃ©s dans le nom du fichier
    if ($lowerName -match 'analyze|analysis') { return 'analysis' }
    if ($lowerName -match 'organize|organization') { return 'organization' }
    if ($lowerName -match 'inventory|catalog') { return 'inventory' }
    if ($lowerName -match 'document|doc') { return 'documentation' }
    if ($lowerName -match 'monitor|watch') { return 'monitoring' }
    if ($lowerName -match 'optimize|improve') { return 'optimization' }
    if ($lowerName -match 'test|validate') { return 'testing' }
    if ($lowerName -match 'config|setting') { return 'configuration' }
    if ($lowerName -match 'generate|create') { return 'generation' }
    if ($lowerName -match 'integrate|connect') { return 'integration' }
    if ($lowerName -match 'ui|interface') { return 'ui' }
    
    # Analyse du contenu si disponible
    if ($Content) {
        if ($Content -match 'analyze|analysis') { return 'analysis' }
        if ($Content -match 'organize|organization') { return 'organization' }
        if ($Content -match 'inventory|catalog') { return 'inventory' }
        if ($Content -match 'document|doc') { return 'documentation' }
        if ($Content -match 'monitor|watch') { return 'monitoring' }
        if ($Content -match 'optimize|improve') { return 'optimization' }
        if ($Content -match 'test|validate') { return 'testing' }
        if ($Content -match 'config|setting') { return 'configuration' }
        if ($Content -match 'generate|create') { return 'generation' }
        if ($Content -match 'integrate|connect') { return 'integration' }
        if ($Content -match 'ui|interface') { return 'ui' }
    }
    
    # Par dÃ©faut, retourner 'core'
    return 'core'
}

# Tests Pester pour les cas limites
Describe "Tests de cas limites pour Get-ScriptCategory" {
    Context "Cas limites pour le paramÃ¨tre FileName" {
        It "GÃ¨re correctement une chaÃ®ne vide" {
            { Get-ScriptCategory -FileName "" } | Should -Not -Throw
            Get-ScriptCategory -FileName "" | Should -Be "core"
        }
        
        It "GÃ¨re correctement une chaÃ®ne avec des espaces" {
            Get-ScriptCategory -FileName "   " | Should -Be "core"
        }
        
        It "GÃ¨re correctement une chaÃ®ne avec des caractÃ¨res spÃ©ciaux" {
            Get-ScriptCategory -FileName "!@#$%^&*().ps1" | Should -Be "core"
        }
        
        It "GÃ¨re correctement une chaÃ®ne trÃ¨s longue" {
            $longFileName = "a" * 1000 + ".ps1"
            Get-ScriptCategory -FileName $longFileName | Should -Be "core"
        }
        
        It "GÃ¨re correctement un nom de fichier avec plusieurs mots-clÃ©s" {
            Get-ScriptCategory -FileName "Analyze-Organize-Test.ps1" | Should -Be "analysis"
        }
        
        It "GÃ¨re correctement un nom de fichier avec des majuscules et minuscules mÃ©langÃ©es" {
            Get-ScriptCategory -FileName "AnAlYzE-ScRiPtS.ps1" | Should -Be "analysis"
        }
        
        It "GÃ¨re correctement un nom de fichier sans extension" {
            Get-ScriptCategory -FileName "Analyze-Scripts" | Should -Be "analysis"
        }
        
        It "GÃ¨re correctement un nom de fichier avec une extension diffÃ©rente" {
            Get-ScriptCategory -FileName "Analyze-Scripts.txt" | Should -Be "analysis"
        }
    }
    
    Context "Cas limites pour le paramÃ¨tre Content" {
        It "GÃ¨re correctement un contenu vide" {
            Get-ScriptCategory -FileName "Unknown.ps1" -Content "" | Should -Be "core"
        }
        
        It "GÃ¨re correctement un contenu avec des espaces" {
            Get-ScriptCategory -FileName "Unknown.ps1" -Content "   " | Should -Be "core"
        }
        
        It "GÃ¨re correctement un contenu avec des caractÃ¨res spÃ©ciaux" {
            Get-ScriptCategory -FileName "Unknown.ps1" -Content "!@#$%^&*()" | Should -Be "core"
        }
        
        It "GÃ¨re correctement un contenu trÃ¨s long" {
            $longContent = "a" * 10000
            Get-ScriptCategory -FileName "Unknown.ps1" -Content $longContent | Should -Be "core"
        }
        
        It "GÃ¨re correctement un contenu avec plusieurs mots-clÃ©s" {
            Get-ScriptCategory -FileName "Unknown.ps1" -Content "Ce script permet d'analyser, d'organiser et de tester des scripts" | Should -Be "analysis"
        }
        
        It "GÃ¨re correctement un contenu avec des majuscules et minuscules mÃ©langÃ©es" {
            Get-ScriptCategory -FileName "Unknown.ps1" -Content "Ce script permet d'AnAlYsEr des scripts" | Should -Be "analysis"
        }
        
        It "GÃ¨re correctement un contenu avec des sauts de ligne" {
            $contentWithLineBreaks = "Ligne 1`nLigne 2`nCe script permet d'analyser des scripts`nLigne 4"
            Get-ScriptCategory -FileName "Unknown.ps1" -Content $contentWithLineBreaks | Should -Be "analysis"
        }
        
        It "GÃ¨re correctement un contenu avec des tabulations" {
            $contentWithTabs = "Colonne 1`tColonne 2`tCe script permet d'analyser des scripts`tColonne 4"
            Get-ScriptCategory -FileName "Unknown.ps1" -Content $contentWithTabs | Should -Be "analysis"
        }
    }
    
    Context "Cas limites pour les deux paramÃ¨tres" {
        It "PrioritÃ© du nom de fichier sur le contenu" {
            Get-ScriptCategory -FileName "Analyze-Scripts.ps1" -Content "Ce script permet d'organiser des scripts" | Should -Be "analysis"
        }
        
        It "Utilisation du contenu si le nom de fichier ne contient pas de mot-clÃ©" {
            Get-ScriptCategory -FileName "Unknown.ps1" -Content "Ce script permet d'analyser des scripts" | Should -Be "analysis"
        }
        
        It "Retourne 'core' si ni le nom de fichier ni le contenu ne contiennent de mot-clÃ©" {
            Get-ScriptCategory -FileName "Unknown.ps1" -Content "Ce script fait quelque chose" | Should -Be "core"
        }
    }
    
    Context "Cas d'erreur" {
        It "Lance une exception si FileName est null" {
            { Get-ScriptCategory -FileName $null } | Should -Throw
        }
        
        It "Ne lance pas d'exception si Content est null" {
            { Get-ScriptCategory -FileName "Unknown.ps1" -Content $null } | Should -Not -Throw
            Get-ScriptCategory -FileName "Unknown.ps1" -Content $null | Should -Be "core"
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
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "EdgeCaseTestResults.html"
    
    # CrÃ©er un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests de cas limites</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        .summary { margin-bottom: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de tests de cas limites</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests exÃ©cutÃ©s: $($testResults.TotalCount)</p>
        <p class="success">Tests rÃ©ussis: $($testResults.PassedCount)</p>
        <p class="error">Tests Ã©chouÃ©s: $($testResults.FailedCount)</p>
        <p class="warning">Tests ignorÃ©s: $($testResults.SkippedCount)</p>
        <p>DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <h2>Qu'est-ce que les tests de cas limites?</h2>
    <p>Les tests de cas limites (edge cases) sont des tests qui vÃ©rifient le comportement d'une fonction dans des situations extrÃªmes ou inhabituelles. Ces tests sont importants pour s'assurer que le code fonctionne correctement dans toutes les situations, mÃªme les plus rares.</p>
    
    <h3>Exemples de cas limites</h3>
    <ul>
        <li>Valeurs vides ou nulles</li>
        <li>Valeurs trÃ¨s grandes ou trÃ¨s petites</li>
        <li>ChaÃ®nes de caractÃ¨res trÃ¨s longues</li>
        <li>CaractÃ¨res spÃ©ciaux</li>
        <li>Combinaisons de paramÃ¨tres inhabituelles</li>
    </ul>
    
    <h2>CatÃ©gories de tests</h2>
    <h3>Cas limites pour le paramÃ¨tre FileName</h3>
    <ul>
        <li>ChaÃ®ne vide</li>
        <li>ChaÃ®ne avec des espaces</li>
        <li>ChaÃ®ne avec des caractÃ¨res spÃ©ciaux</li>
        <li>ChaÃ®ne trÃ¨s longue</li>
        <li>Nom de fichier avec plusieurs mots-clÃ©s</li>
        <li>Nom de fichier avec des majuscules et minuscules mÃ©langÃ©es</li>
        <li>Nom de fichier sans extension</li>
        <li>Nom de fichier avec une extension diffÃ©rente</li>
    </ul>
    
    <h3>Cas limites pour le paramÃ¨tre Content</h3>
    <ul>
        <li>Contenu vide</li>
        <li>Contenu avec des espaces</li>
        <li>Contenu avec des caractÃ¨res spÃ©ciaux</li>
        <li>Contenu trÃ¨s long</li>
        <li>Contenu avec plusieurs mots-clÃ©s</li>
        <li>Contenu avec des majuscules et minuscules mÃ©langÃ©es</li>
        <li>Contenu avec des sauts de ligne</li>
        <li>Contenu avec des tabulations</li>
    </ul>
    
    <h3>Cas limites pour les deux paramÃ¨tres</h3>
    <ul>
        <li>PrioritÃ© du nom de fichier sur le contenu</li>
        <li>Utilisation du contenu si le nom de fichier ne contient pas de mot-clÃ©</li>
        <li>Retour Ã  la valeur par dÃ©faut si ni le nom de fichier ni le contenu ne contiennent de mot-clÃ©</li>
    </ul>
    
    <h3>Cas d'erreur</h3>
    <ul>
        <li>FileName null</li>
        <li>Content null</li>
    </ul>
    
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
