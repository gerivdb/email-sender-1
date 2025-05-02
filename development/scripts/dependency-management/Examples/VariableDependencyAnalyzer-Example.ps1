# Exemple d'utilisation du module VariableDependencyAnalyzer

# Importer le module
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "VariableDependencyAnalyzer.psm1"
Import-Module -Name $modulePath -Force

# Définir le chemin du script à analyser
# Remplacer par le chemin d'un script réel
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SampleVariableScript.ps1"

# Créer un script d'exemple si le fichier n'existe pas
if (-not (Test-Path -Path $scriptPath)) {
    $sampleScript = @'
# Configuration
$config = @{
    MaxItems = 100
    DefaultColor = "Blue"
    EnableLogging = $true
    LogPath = "C:\Logs\app.log"
}

# Variables dérivées
$maxItems = $config.MaxItems
$defaultColor = $config.DefaultColor
$logFile = $config.LogPath

# Fonction de traitement
function Process-Items {
    param (
        [int]$count = $maxItems,
        [string]$color = $defaultColor
    )
    
    $processedItems = 0
    $results = @()
    
    for ($i = 0; $i -lt $count; $i++) {
        $item = [PSCustomObject]@{
            Id = $i
            Name = "Item-$i"
            Color = $color
            ProcessedOn = Get-Date
        }
        
        $results += $item
        $processedItems++
        
        # Variable non définie
        if ($showProgress) {
            Write-Progress -Activity "Traitement" -Status "Traitement de l'élément $i" -PercentComplete (($i / $count) * 100)
        }
    }
    
    # Variable définie mais non utilisée
    $endTime = Get-Date
    
    return [PSCustomObject]@{
        ProcessedCount = $processedItems
        Items = $results
    }
}

# Utilisation de la fonction
$result = Process-Items -count 10
Write-Output "Nombre d'éléments traités: $($result.ProcessedCount)"

# Écriture du log
if ($config.EnableLogging) {
    $logMessage = "Traitement terminé à $(Get-Date) - $($result.ProcessedCount) éléments traités"
    Add-Content -Path $logFile -Value $logMessage
}
'@
    
    Set-Content -Path $scriptPath -Value $sampleScript
    Write-Host "Script d'exemple créé: $scriptPath"
}

# 1. Analyser les utilisations de variables
Write-Host "`n=== Analyse des utilisations de variables ===" -ForegroundColor Cyan
$variableUsages = Get-VariableUsageAnalysis -ScriptPath $scriptPath
Write-Host "Variables détectées: $($variableUsages.Count)"

# Afficher les variables définies
Write-Host "`nVariables définies:" -ForegroundColor Yellow
$variableUsages | Where-Object { $_.Type -eq "Assignment" } | Format-Table -Property Name, Line, Value

# Afficher les variables utilisées
Write-Host "`nVariables utilisées:" -ForegroundColor Yellow
$variableUsages | Where-Object { $_.Type -eq "Usage" } | Format-Table -Property Name, Line

# 2. Comparer les définitions et les utilisations
Write-Host "`n=== Comparaison des définitions et des utilisations ===" -ForegroundColor Cyan
$comparison = Compare-VariableDefinitionsAndUsages -ScriptPath $scriptPath

# Afficher les variables définies mais non utilisées
Write-Host "`nVariables définies mais non utilisées: $($comparison.DefinedButNotUsed.Count)" -ForegroundColor Yellow
$comparison.DefinedButNotUsed | Format-Table -Property Name, Line, Value

# Afficher les variables utilisées mais non définies
Write-Host "`nVariables utilisées mais non définies: $($comparison.UsedButNotDefined.Count)" -ForegroundColor Yellow
$comparison.UsedButNotDefined | Format-Table -Property Name, Line

# 3. Créer un graphe de dépendances
Write-Host "`n=== Graphe de dépendances de variables ===" -ForegroundColor Cyan
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "Output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Exporter le graphe dans différents formats
$textOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.txt"
$jsonOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.json"
$dotOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.dot"
$htmlOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.html"

$graph = New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $textOutputPath -OutputFormat "Text"
New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $jsonOutputPath -OutputFormat "JSON"
New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $dotOutputPath -OutputFormat "DOT"
New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $htmlOutputPath -OutputFormat "HTML"

Write-Host "Graphe de dépendances exporté dans les formats suivants:"
Write-Host "- Texte: $textOutputPath"
Write-Host "- JSON: $jsonOutputPath"
Write-Host "- DOT: $dotOutputPath"
Write-Host "- HTML: $htmlOutputPath"

# Afficher le graphe de dépendances
Write-Host "`nGraphe de dépendances:" -ForegroundColor Yellow
foreach ($variable in $graph.Graph.Keys | Sort-Object) {
    Write-Host "$variable dépend de: $($graph.Graph[$variable] -join ', ')"
}
