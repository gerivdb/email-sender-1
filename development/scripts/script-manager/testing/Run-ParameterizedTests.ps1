#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests paramÃ©trÃ©s pour le script manager.
.DESCRIPTION
    Ce script exÃ©cute des tests paramÃ©trÃ©s pour tester plusieurs cas
    avec un minimum de code.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.EXAMPLE
    .\Run-ParameterizedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
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

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "ParameterizedTestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Tests Pester paramÃ©trÃ©s
Describe "Tests paramÃ©trÃ©s pour la fonction Get-ScriptCategory" {
    # DÃ©finir les cas de test
    $testCases = @(
        @{ FileName = "Analyze-Scripts.ps1"; ExpectedCategory = "analysis" }
        @{ FileName = "Organize-Scripts.ps1"; ExpectedCategory = "organization" }
        @{ FileName = "Show-ScriptInventory.ps1"; ExpectedCategory = "inventory" }
        @{ FileName = "Generate-Documentation.ps1"; ExpectedCategory = "documentation" }
        @{ FileName = "Monitor-Scripts.ps1"; ExpectedCategory = "monitoring" }
        @{ FileName = "Optimize-Scripts.ps1"; ExpectedCategory = "optimization" }
        @{ FileName = "Test-Scripts.ps1"; ExpectedCategory = "testing" }
        @{ FileName = "Update-Configuration.ps1"; ExpectedCategory = "configuration" }
        @{ FileName = "Generate-Script.ps1"; ExpectedCategory = "generation" }
        @{ FileName = "Integrate-Tools.ps1"; ExpectedCategory = "integration" }
        @{ FileName = "Update-UI.ps1"; ExpectedCategory = "ui" }
        @{ FileName = "ScriptManager.ps1"; ExpectedCategory = "core" }
        @{ FileName = "Unknown.ps1"; ExpectedCategory = "core" }
    )
    
    It "Devrait retourner la catÃ©gorie '<ExpectedCategory>' pour le fichier '<FileName>'" -TestCases $testCases {
        param ($FileName, $ExpectedCategory)
        Get-ScriptCategory -FileName $FileName | Should -Be $ExpectedCategory
    }
    
    # DÃ©finir les cas de test avec contenu
    $contentTestCases = @(
        @{ FileName = "Unknown.ps1"; Content = "# Script pour analyser les scripts"; ExpectedCategory = "analysis" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour organiser les scripts"; ExpectedCategory = "organization" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour l'inventaire des scripts"; ExpectedCategory = "inventory" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour documenter les scripts"; ExpectedCategory = "documentation" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour surveiller les scripts"; ExpectedCategory = "monitoring" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour optimiser les scripts"; ExpectedCategory = "optimization" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour tester les scripts"; ExpectedCategory = "testing" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour configurer les scripts"; ExpectedCategory = "configuration" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour gÃ©nÃ©rer des scripts"; ExpectedCategory = "generation" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour intÃ©grer des outils"; ExpectedCategory = "integration" }
        @{ FileName = "Unknown.ps1"; Content = "# Script pour l'interface utilisateur"; ExpectedCategory = "ui" }
        @{ FileName = "Unknown.ps1"; Content = "# Script sans mot-clÃ© reconnu"; ExpectedCategory = "core" }
    )
    
    It "Devrait analyser le contenu et retourner la catÃ©gorie '<ExpectedCategory>' pour le contenu '<Content>'" -TestCases $contentTestCases {
        param ($FileName, $Content, $ExpectedCategory)
        Get-ScriptCategory -FileName $FileName -Content $Content | Should -Be $ExpectedCategory
    }
    
    # DÃ©finir les cas de test pour les cas limites
    $edgeCaseTestCases = @(
        @{ FileName = ""; ExpectedCategory = "core" }
        @{ FileName = $null; ExpectedCategory = "core" }
        @{ FileName = "Unknown.ps1"; Content = ""; ExpectedCategory = "core" }
        @{ FileName = "Unknown.ps1"; Content = $null; ExpectedCategory = "core" }
        @{ FileName = "Unknown.ps1"; Content = " "; ExpectedCategory = "core" }
        @{ FileName = "Unknown.ps1"; Content = "`n`n`n"; ExpectedCategory = "core" }
        @{ FileName = "Unknown.ps1"; Content = "# "; ExpectedCategory = "core" }
        @{ FileName = "Unknown.ps1"; Content = "# `n# `n# "; ExpectedCategory = "core" }
    )
    
    It "Devrait gÃ©rer correctement les cas limites pour le fichier '<FileName>' et le contenu '<Content>'" -TestCases $edgeCaseTestCases {
        param ($FileName, $Content, $ExpectedCategory)
        if ($null -eq $FileName) {
            { Get-ScriptCategory -FileName $FileName -Content $Content } | Should -Throw
        }
        else {
            Get-ScriptCategory -FileName $FileName -Content $Content | Should -Be $ExpectedCategory
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
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "ParameterizedTestResults.html"
    
    # CrÃ©er un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests paramÃ©trÃ©s</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
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
    <h1>Rapport de tests paramÃ©trÃ©s</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests exÃ©cutÃ©s: $($testResults.TotalCount)</p>
        <p class="success">Tests rÃ©ussis: $($testResults.PassedCount)</p>
        <p class="error">Tests Ã©chouÃ©s: $($testResults.FailedCount)</p>
        <p class="warning">Tests ignorÃ©s: $($testResults.SkippedCount)</p>
        <p>DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <h2>Avantages des tests paramÃ©trÃ©s</h2>
    <ul>
        <li>RÃ©duction de la duplication de code</li>
        <li>FacilitÃ© d'ajout de nouveaux cas de test</li>
        <li>Meilleure lisibilitÃ© des tests</li>
        <li>Meilleure maintenance des tests</li>
        <li>Couverture de code plus complÃ¨te</li>
    </ul>
    
    <h2>Cas de test</h2>
    <h3>Tests par nom de fichier</h3>
    <table>
        <tr>
            <th>Nom de fichier</th>
            <th>CatÃ©gorie attendue</th>
        </tr>
        <tr><td>Analyze-Scripts.ps1</td><td>analysis</td></tr>
        <tr><td>Organize-Scripts.ps1</td><td>organization</td></tr>
        <tr><td>Show-ScriptInventory.ps1</td><td>inventory</td></tr>
        <tr><td>Generate-Documentation.ps1</td><td>documentation</td></tr>
        <tr><td>Monitor-Scripts.ps1</td><td>monitoring</td></tr>
        <tr><td>Optimize-Scripts.ps1</td><td>optimization</td></tr>
        <tr><td>Test-Scripts.ps1</td><td>testing</td></tr>
        <tr><td>Update-Configuration.ps1</td><td>configuration</td></tr>
        <tr><td>Generate-Script.ps1</td><td>generation</td></tr>
        <tr><td>Integrate-Tools.ps1</td><td>integration</td></tr>
        <tr><td>Update-UI.ps1</td><td>ui</td></tr>
        <tr><td>ScriptManager.ps1</td><td>core</td></tr>
        <tr><td>Unknown.ps1</td><td>core</td></tr>
    </table>
    
    <h3>Tests par contenu</h3>
    <table>
        <tr>
            <th>Contenu</th>
            <th>CatÃ©gorie attendue</th>
        </tr>
        <tr><td># Script pour analyser les scripts</td><td>analysis</td></tr>
        <tr><td># Script pour organiser les scripts</td><td>organization</td></tr>
        <tr><td># Script pour l'inventaire des scripts</td><td>inventory</td></tr>
        <tr><td># Script pour documenter les scripts</td><td>documentation</td></tr>
        <tr><td># Script pour surveiller les scripts</td><td>monitoring</td></tr>
        <tr><td># Script pour optimiser les scripts</td><td>optimization</td></tr>
        <tr><td># Script pour tester les scripts</td><td>testing</td></tr>
        <tr><td># Script pour configurer les scripts</td><td>configuration</td></tr>
        <tr><td># Script pour gÃ©nÃ©rer des scripts</td><td>generation</td></tr>
        <tr><td># Script pour intÃ©grer des outils</td><td>integration</td></tr>
        <tr><td># Script pour l'interface utilisateur</td><td>ui</td></tr>
        <tr><td># Script sans mot-clÃ© reconnu</td><td>core</td></tr>
    </table>
    
    <h3>Cas limites</h3>
    <table>
        <tr>
            <th>Nom de fichier</th>
            <th>Contenu</th>
            <th>CatÃ©gorie attendue</th>
        </tr>
        <tr><td>""</td><td>-</td><td>core</td></tr>
        <tr><td>null</td><td>-</td><td>Exception</td></tr>
        <tr><td>Unknown.ps1</td><td>""</td><td>core</td></tr>
        <tr><td>Unknown.ps1</td><td>null</td><td>core</td></tr>
        <tr><td>Unknown.ps1</td><td>" "</td><td>core</td></tr>
        <tr><td>Unknown.ps1</td><td>"\n\n\n"</td><td>core</td></tr>
        <tr><td>Unknown.ps1</td><td>"# "</td><td>core</td></tr>
        <tr><td>Unknown.ps1</td><td>"# \n# \n# "</td><td>core</td></tr>
    </table>
    
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
