# Exemple d'utilisation du module VariableDependencyAnalyzer

# Importer le module
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "VariableDependencyAnalyzer.psm1"
Import-Module -Name $modulePath -Force

# DÃ©finir le chemin du script Ã  analyser
# Remplacer par le chemin d'un script rÃ©el
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SampleVariableScript.ps1"

# CrÃ©er un script d'exemple si le fichier n'existe pas
if (-not (Test-Path -Path $scriptPath)) {
    $sampleScript = @'
# Configuration
$config = @{
    MaxItems = 100
    DefaultColor = "Blue"
    EnableLogging = $true
    LogPath = "C:\Logs\app.log"
}

# Variables dÃ©rivÃ©es
$maxItems = $config.MaxItems
$defaultColor = $config.DefaultColor
$logFile = $config.LogPath

# Fonction de traitement
function Invoke-Items {
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
        
        # Variable non dÃ©finie
        if ($showProgress) {
            Write-Progress -Activity "Traitement" -Status "Traitement de l'Ã©lÃ©ment $i" -PercentComplete (($i / $count) * 100)
        }
    }
    
    # Variable dÃ©finie mais non utilisÃ©e
    $endTime = Get-Date
    
    return [PSCustomObject]@{
        ProcessedCount = $processedItems
        Items = $results
    }
}

# Utilisation de la fonction
$result = Invoke-Items -count 10
Write-Output "Nombre d'Ã©lÃ©ments traitÃ©s: $($result.ProcessedCount)"

# Ã‰criture du log
if ($config.EnableLogging) {
    $logMessage = "Traitement terminÃ© Ã  $(Get-Date) - $($result.ProcessedCount) Ã©lÃ©ments traitÃ©s"
    Add-Content -Path $logFile -Value $logMessage
}
'@
    
    Set-Content -Path $scriptPath -Value $sampleScript
    Write-Host "Script d'exemple crÃ©Ã©: $scriptPath"
}

# 1. Analyser les utilisations de variables
Write-Host "`n=== Analyse des utilisations de variables ===" -ForegroundColor Cyan
$variableUsages = Get-VariableUsageAnalysis -ScriptPath $scriptPath
Write-Host "Variables dÃ©tectÃ©es: $($variableUsages.Count)"

# Afficher les variables dÃ©finies
Write-Host "`nVariables dÃ©finies:" -ForegroundColor Yellow
$variableUsages | Where-Object { $_.Type -eq "Assignment" } | Format-Table -Property Name, Line, Value

# Afficher les variables utilisÃ©es
Write-Host "`nVariables utilisÃ©es:" -ForegroundColor Yellow
$variableUsages | Where-Object { $_.Type -eq "Usage" } | Format-Table -Property Name, Line

# 2. Comparer les dÃ©finitions et les utilisations
Write-Host "`n=== Comparaison des dÃ©finitions et des utilisations ===" -ForegroundColor Cyan
$comparison = Compare-VariableDefinitionsAndUsages -ScriptPath $scriptPath

# Afficher les variables dÃ©finies mais non utilisÃ©es
Write-Host "`nVariables dÃ©finies mais non utilisÃ©es: $($comparison.DefinedButNotUsed.Count)" -ForegroundColor Yellow
$comparison.DefinedButNotUsed | Format-Table -Property Name, Line, Value

# Afficher les variables utilisÃ©es mais non dÃ©finies
Write-Host "`nVariables utilisÃ©es mais non dÃ©finies: $($comparison.UsedButNotDefined.Count)" -ForegroundColor Yellow
$comparison.UsedButNotDefined | Format-Table -Property Name, Line

# 3. CrÃ©er un graphe de dÃ©pendances
Write-Host "`n=== Graphe de dÃ©pendances de variables ===" -ForegroundColor Cyan
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "Output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Exporter le graphe dans diffÃ©rents formats
$textOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.txt"
$jsonOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.json"
$dotOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.dot"
$htmlOutputPath = Join-Path -Path $outputDir -ChildPath "VariableDependencies.html"

$graph = New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $textOutputPath -OutputFormat "Text"
New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $jsonOutputPath -OutputFormat "JSON"
New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $dotOutputPath -OutputFormat "DOT"
New-VariableDependencyGraph -ScriptPath $scriptPath -OutputPath $htmlOutputPath -OutputFormat "HTML"

Write-Host "Graphe de dÃ©pendances exportÃ© dans les formats suivants:"
Write-Host "- Texte: $textOutputPath"
Write-Host "- JSON: $jsonOutputPath"
Write-Host "- DOT: $dotOutputPath"
Write-Host "- HTML: $htmlOutputPath"

# Afficher le graphe de dÃ©pendances
Write-Host "`nGraphe de dÃ©pendances:" -ForegroundColor Yellow
foreach ($variable in $graph.Graph.Keys | Sort-Object) {
    Write-Host "$variable dÃ©pend de: $($graph.Graph[$variable] -join ', ')"
}

