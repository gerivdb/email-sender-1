# Exemple d'utilisation du module ModuleDependencyAnalyzer

# Importer le module
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyAnalyzer.psm1"
Import-Module -Name $modulePath -Force

# Définir le chemin du script à analyser
# Remplacer par le chemin d'un script réel
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SampleModuleScript.ps1"

# Créer un script d'exemple si le fichier n'existe pas
if (-not (Test-Path -Path $scriptPath)) {
    $sampleScript = @'
#Requires -Version 5.1
#Requires -Modules @{ModuleName="PSReadLine"; ModuleVersion="2.0.0"}

# Configuration
$VerbosePreference = "Continue"

# Importer des modules
Import-Module -Name PSScriptAnalyzer
Import-Module -Name Pester -RequiredVersion 5.0.0
Import-Module -Name Microsoft.PowerShell.Utility

# Fonction d'analyse de code
function Invoke-CodeAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeRule,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeRule,
        
        [Parameter(Mandatory = $false)]
        [switch]$Fix
    )
    
    Write-Verbose "Analyse du code dans: $Path"
    
    # Utiliser PSScriptAnalyzer pour analyser le code
    $analyzerParams = @{
        Path = $Path
    }
    
    if ($IncludeRule) {
        $analyzerParams.IncludeRule = $IncludeRule
    }
    
    if ($ExcludeRule) {
        $analyzerParams.ExcludeRule = $ExcludeRule
    }
    
    $results = Invoke-ScriptAnalyzer @analyzerParams
    
    # Corriger les problèmes si demandé
    if ($Fix) {
        Write-Verbose "Correction des problèmes détectés"
        Invoke-ScriptAnalyzer -Path $Path -Fix
    }
    
    # Générer un rapport
    $report = [PSCustomObject]@{
        Path = $Path
        TotalIssues = $results.Count
        Severity = @{
            Error = ($results | Where-Object { $_.Severity -eq 'Error' }).Count
            Warning = ($results | Where-Object { $_.Severity -eq 'Warning' }).Count
            Information = ($results | Where-Object { $_.Severity -eq 'Information' }).Count
        }
        Rules = $results | Group-Object -Property RuleName | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Count = $_.Count
            }
        }
        Results = $results
    }
    
    # Convertir le rapport en JSON
    $jsonReport = ConvertTo-Json -InputObject $report -Depth 5
    
    # Exécuter des tests si le fichier de tests existe
    $testPath = [System.IO.Path]::ChangeExtension($Path, "Tests.ps1")
    if (Test-Path -Path $testPath) {
        Write-Verbose "Exécution des tests: $testPath"
        Invoke-Pester -Path $testPath -PassThru
    }
    
    return $report
}

# Fonction de génération de rapport HTML
function New-AnalysisReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AnalysisResult,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-Verbose "Génération du rapport HTML: $OutputPath"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse de code</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: #d9534f; }
        .warning { color: #f0ad4e; }
        .info { color: #5bc0de; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse de code</h1>
    <p><strong>Fichier analysé:</strong> $($AnalysisResult.Path)</p>
    <p><strong>Total des problèmes:</strong> $($AnalysisResult.TotalIssues)</p>
    
    <h2>Résumé par sévérité</h2>
    <table>
        <tr>
            <th>Sévérité</th>
            <th>Nombre</th>
        </tr>
        <tr>
            <td class="error">Erreur</td>
            <td>$($AnalysisResult.Severity.Error)</td>
        </tr>
        <tr>
            <td class="warning">Avertissement</td>
            <td>$($AnalysisResult.Severity.Warning)</td>
        </tr>
        <tr>
            <td class="info">Information</td>
            <td>$($AnalysisResult.Severity.Information)</td>
        </tr>
    </table>
    
    <h2>Résumé par règle</h2>
    <table>
        <tr>
            <th>Règle</th>
            <th>Nombre</th>
        </tr>
"@
    
    foreach ($rule in $AnalysisResult.Rules) {
        $html += @"
        <tr>
            <td>$($rule.Name)</td>
            <td>$($rule.Count)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <h2>Détails des problèmes</h2>
    <table>
        <tr>
            <th>Ligne</th>
            <th>Sévérité</th>
            <th>Règle</th>
            <th>Message</th>
        </tr>
"@
    
    foreach ($issue in $AnalysisResult.Results) {
        $severityClass = switch ($issue.Severity) {
            'Error' { 'error' }
            'Warning' { 'warning' }
            'Information' { 'info' }
            default { '' }
        }
        
        $html += @"
        <tr>
            <td>$($issue.Line)</td>
            <td class="$severityClass">$($issue.Severity)</td>
            <td>$($issue.RuleName)</td>
            <td>$($issue.Message)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Verbose "Rapport HTML généré: $OutputPath"
}

# Exécuter l'analyse sur un script
$scriptToAnalyze = ".\script.ps1"
if (Test-Path -Path $scriptToAnalyze) {
    $analysisResult = Invoke-CodeAnalysis -Path $scriptToAnalyze -Verbose
    $reportPath = ".\report.html"
    New-AnalysisReport -AnalysisResult $analysisResult -OutputPath $reportPath
    Write-Host "Rapport généré: $reportPath"
} else {
    Write-Warning "Le script à analyser n'existe pas: $scriptToAnalyze"
}
'@
    
    Set-Content -Path $scriptPath -Value $sampleScript
    Write-Host "Script d'exemple créé: $scriptPath"
}

# 1. Analyser les imports de modules
Write-Host "`n=== Analyse des imports de modules ===" -ForegroundColor Cyan
$moduleImports = Get-ModuleImportAnalysis -ScriptPath $scriptPath -IncludeRequires -IncludeUsingModule
Write-Host "Modules importés: $($moduleImports.Count)"
$moduleImports | Format-Table -Property Type, ModuleName, ModuleVersion, Line

# 2. Analyser les utilisations de commandes de modules
Write-Host "`n=== Analyse des utilisations de commandes de modules ===" -ForegroundColor Cyan
$commandUsages = Get-ModuleCommandUsage -ScriptPath $scriptPath -IncludeAllCommands
Write-Host "Commandes utilisées: $($commandUsages.Count)"
$commandUsages | Format-Table -Property CommandName, ModuleName, Line

# 3. Comparer les imports et les utilisations
Write-Host "`n=== Comparaison des imports et des utilisations ===" -ForegroundColor Cyan
$comparison = Compare-ModuleImportsAndUsage -ScriptPath $scriptPath -IncludeRequires -IncludeUsingModule

# Afficher les modules importés mais non utilisés
Write-Host "`nModules importés mais non utilisés: $($comparison.ImportedButNotUsed.Count)" -ForegroundColor Yellow
$comparison.ImportedButNotUsed | Format-Table -Property ModuleName, Type, Line

# Afficher les commandes potentiellement manquantes
Write-Host "`nCommandes potentiellement manquantes: $($comparison.PotentiallyMissingImports.Count)" -ForegroundColor Yellow
$comparison.PotentiallyMissingImports | Format-Table -Property CommandName, Line

# 4. Créer un graphe de dépendances
Write-Host "`n=== Graphe de dépendances de modules ===" -ForegroundColor Cyan
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "Output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Exporter le graphe dans différents formats
$textOutputPath = Join-Path -Path $outputDir -ChildPath "ModuleDependencies.txt"
$jsonOutputPath = Join-Path -Path $outputDir -ChildPath "ModuleDependencies.json"
$dotOutputPath = Join-Path -Path $outputDir -ChildPath "ModuleDependencies.dot"
$htmlOutputPath = Join-Path -Path $outputDir -ChildPath "ModuleDependencies.html"

$graph = New-ModuleDependencyGraph -ScriptPath $scriptPath -OutputPath $textOutputPath -OutputFormat "Text" -IncludeRequires -IncludeUsingModule
New-ModuleDependencyGraph -ScriptPath $scriptPath -OutputPath $jsonOutputPath -OutputFormat "JSON" -IncludeRequires -IncludeUsingModule
New-ModuleDependencyGraph -ScriptPath $scriptPath -OutputPath $dotOutputPath -OutputFormat "DOT" -IncludeRequires -IncludeUsingModule
New-ModuleDependencyGraph -ScriptPath $scriptPath -OutputPath $htmlOutputPath -OutputFormat "HTML" -IncludeRequires -IncludeUsingModule

Write-Host "Graphe de dépendances exporté dans les formats suivants:"
Write-Host "- Texte: $textOutputPath"
Write-Host "- JSON: $jsonOutputPath"
Write-Host "- DOT: $dotOutputPath"
Write-Host "- HTML: $htmlOutputPath"

# Afficher le graphe de dépendances
Write-Host "`nGraphe de dépendances:" -ForegroundColor Yellow
foreach ($node in $graph.Graph.Keys | Sort-Object) {
    Write-Host "$node dépend de: $($graph.Graph[$node] -join ', ')"
}
