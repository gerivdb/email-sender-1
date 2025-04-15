#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute des benchmarks de performance pour les modules de rapports PR.
.DESCRIPTION
    Ce script exécute des benchmarks standardisés pour mesurer les performances
    des différentes fonctions des modules de rapports PR. Il génère des résultats
    structurés qui peuvent être utilisés pour analyser les performances et détecter
    les régressions.
.PARAMETER ModuleName
    Nom du module à tester. Si non spécifié, tous les modules seront testés.
.PARAMETER FunctionName
    Nom de la fonction à tester. Si non spécifié, toutes les fonctions du module seront testées.
.PARAMETER Iterations
    Nombre d'itérations pour chaque test. Par défaut: 5.
.PARAMETER DataSize
    Taille des données de test (Small, Medium, Large). Par défaut: Medium.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats. Par défaut: ".\benchmark_results.json".
.PARAMETER IncludeDetails
    Inclut les détails de chaque itération dans les résultats.
.EXAMPLE
    .\Invoke-PRPerformanceBenchmark.ps1 -ModuleName "PRVisualization" -DataSize "Large"
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("PRReportFilters", "PRReportTemplates", "PRVisualization")]
    [string]$ModuleName,
    
    [Parameter(Mandatory = $false)]
    [string]$FunctionName,
    
    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Small", "Medium", "Large")]
    [string]$DataSize = "Medium",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\benchmark_results.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDetails
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$modules = @(
    "PRReportFilters",
    "PRReportTemplates",
    "PRVisualization"
)

# Filtrer les modules si un module spécifique est demandé
if ($ModuleName) {
    $modules = $modules | Where-Object { $_ -eq $ModuleName }
}

# Importer les modules
foreach ($module in $modules) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath "$module.psm1"
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
        Write-Verbose "Module importé: $module"
    }
    else {
        Write-Error "Module non trouvé: $modulePath"
    }
}

# Fonction pour générer des données de test
function New-TestData {
    param (
        [string]$Size
    )
    
    # Définir la taille des données en fonction du paramètre
    $count = switch ($Size) {
        "Small" { 10 }
        "Medium" { 100 }
        "Large" { 1000 }
        default { 100 }
    }
    
    # Générer des données de test pour PRReportFilters
    $filterTestData = @()
    for ($i = 0; $i -lt $count; $i++) {
        $filterTestData += [PSCustomObject]@{
            Type     = @("Error", "Warning", "Info")[$i % 3]
            Severity = @("High", "Medium", "Low")[$i % 3]
            Rule     = "Rule-$($i % 10)"
            Message  = "Message $i"
            File     = "File$($i % 20).ps1"
            Line     = $i % 100
        }
    }
    
    # Générer des données de test pour PRVisualization
    $visualizationTestData = @()
    for ($i = 0; $i -lt $count; $i++) {
        $visualizationTestData += [PSCustomObject]@{
            Label = "Item $i"
            Value = $i % 100
            Color = "#{0:X2}{1:X2}{2:X2}" -f ($i % 255), (($i * 2) % 255), (($i * 3) % 255)
        }
    }
    
    # Générer des données de test pour PRReportTemplates
    $templateTestData = [PSCustomObject]@{
        title       = "Test Report"
        description = "This is a test report with $count items"
        items       = @()
    }
    
    for ($i = 0; $i -lt $count; $i++) {
        $templateTestData.items += [PSCustomObject]@{
            name  = "Item $i"
            value = "Value $i"
        }
    }
    
    # Créer un template HTML de test
    $htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>{{title}}</title>
</head>
<body>
    <h1>{{title}}</h1>
    <p>{{description}}</p>
    <ul>
        {{#each items}}
        <li>{{this.name}}: {{this.value}}</li>
        {{/each}}
    </ul>
</body>
</html>
"@
    
    # Créer un répertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceTest_$(Get-Random)"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # Créer le fichier de template
    $templatePath = Join-Path -Path $testDir -ChildPath "template.html"
    Set-Content -Path $templatePath -Value $htmlTemplate -Encoding UTF8
    
    # Enregistrer le template
    if (Get-Command -Name Register-PRReportTemplate -ErrorAction SilentlyContinue) {
        Register-PRReportTemplate -Name "TestTemplate" -Format "HTML" -TemplatePath $templatePath -Force | Out-Null
    }
    
    return @{
        FilterTestData       = $filterTestData
        VisualizationTestData = $visualizationTestData
        TemplateTestData     = $templateTestData
        TemplatePath         = $templatePath
        TestDir              = $testDir
    }
}

# Fonction pour exécuter un benchmark sur une fonction
function Invoke-FunctionBenchmark {
    param (
        [string]$ModuleName,
        [string]$FunctionName,
        [object]$TestData,
        [int]$Iterations
    )
    
    Write-Host "Exécution du benchmark pour $ModuleName.$FunctionName avec $Iterations itérations..."
    
    $results = @{
        ModuleName   = $ModuleName
        FunctionName = $FunctionName
        Iterations   = $Iterations
        TotalMs      = 0
        AverageMs    = 0
        MinMs        = [double]::MaxValue
        MaxMs        = 0
        Details      = @()
    }
    
    # Préparer les paramètres pour la fonction
    $params = @{}
    
    switch ($ModuleName) {
        "PRReportFilters" {
            switch ($FunctionName) {
                "Add-FilterControls" {
                    $params = @{
                        Issues = $TestData.FilterTestData
                    }
                }
                "Add-SortingCapabilities" {
                    $params = @{
                        TableId = "test-table"
                    }
                }
                "New-CustomReportView" {
                    $params = @{
                        Issues = $TestData.FilterTestData
                        Title  = "Test Report"
                    }
                }
                "New-SearchableReport" {
                    $params = @{
                        Issues = $TestData.FilterTestData
                        Title  = "Test Report"
                    }
                }
                default {
                    Write-Warning "Fonction non prise en charge: $FunctionName"
                    return $null
                }
            }
        }
        "PRReportTemplates" {
            switch ($FunctionName) {
                "New-PRReport" {
                    $outputPath = Join-Path -Path $TestData.TestDir -ChildPath "report.html"
                    $params = @{
                        TemplateName = "TestTemplate"
                        Format       = "HTML"
                        Data         = $TestData.TemplateTestData
                        OutputPath   = $outputPath
                    }
                }
                default {
                    Write-Warning "Fonction non prise en charge: $FunctionName"
                    return $null
                }
            }
        }
        "PRVisualization" {
            switch ($FunctionName) {
                "New-PRBarChart" {
                    $params = @{
                        Data  = $TestData.VisualizationTestData
                        Title = "Test Bar Chart"
                    }
                }
                "New-PRPieChart" {
                    $params = @{
                        Data  = $TestData.VisualizationTestData
                        Title = "Test Pie Chart"
                    }
                }
                "New-PRLineChart" {
                    $params = @{
                        Data  = $TestData.VisualizationTestData
                        Title = "Test Line Chart"
                    }
                }
                "New-PRHeatMap" {
                    $params = @{
                        Data  = $TestData.VisualizationTestData
                        Title = "Test Heat Map"
                    }
                }
                "Get-ColorGradient" {
                    $params = @{
                        StartColor = "#FF0000"
                        EndColor   = "#0000FF"
                        Intensity  = 0.5
                    }
                }
                default {
                    Write-Warning "Fonction non prise en charge: $FunctionName"
                    return $null
                }
            }
        }
        default {
            Write-Warning "Module non pris en charge: $ModuleName"
            return $null
        }
    }
    
    # Exécuter le benchmark
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Exécuter la fonction avec les paramètres préparés
            & $FunctionName @params | Out-Null
            $success = $true
        }
        catch {
            Write-Error "Erreur lors de l'exécution de $FunctionName : $_"
            $success = $false
        }
        
        $sw.Stop()
        $elapsedMs = $sw.ElapsedMilliseconds
        
        # Enregistrer les détails de l'itération
        if ($IncludeDetails) {
            $results.Details += [PSCustomObject]@{
                Iteration = $i + 1
                ElapsedMs = $elapsedMs
                Success   = $success
            }
        }
        
        # Mettre à jour les statistiques
        $results.TotalMs += $elapsedMs
        $results.MinMs = [Math]::Min($results.MinMs, $elapsedMs)
        $results.MaxMs = [Math]::Max($results.MaxMs, $elapsedMs)
    }
    
    # Calculer la moyenne
    $results.AverageMs = $results.TotalMs / $Iterations
    
    return $results
}

# Fonction principale pour exécuter tous les benchmarks
function Invoke-AllBenchmarks {
    param (
        [string[]]$Modules,
        [string]$FunctionFilter,
        [int]$Iterations,
        [string]$DataSize
    )
    
    $allResults = @()
    $testData = New-TestData -Size $DataSize
    
    foreach ($module in $Modules) {
        # Obtenir toutes les fonctions exportées du module
        $functions = Get-Command -Module $module | Where-Object { $_.CommandType -eq "Function" }
        
        # Filtrer les fonctions si un filtre est spécifié
        if ($FunctionFilter) {
            $functions = $functions | Where-Object { $_.Name -like "*$FunctionFilter*" }
        }
        
        foreach ($function in $functions) {
            $functionName = $function.Name
            
            # Exécuter le benchmark pour cette fonction
            $result = Invoke-FunctionBenchmark -ModuleName $module -FunctionName $functionName -TestData $testData -Iterations $Iterations
            
            if ($result) {
                $allResults += $result
            }
        }
    }
    
    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $testData.TestDir) {
        Remove-Item -Path $testData.TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    return $allResults
}

# Exécuter les benchmarks
$benchmarkResults = Invoke-AllBenchmarks -Modules $modules -FunctionFilter $FunctionName -Iterations $Iterations -DataSize $DataSize

# Ajouter des métadonnées aux résultats
$results = @{
    Timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    DataSize   = $DataSize
    Iterations = $Iterations
    System     = @{
        PSVersion    = $PSVersionTable.PSVersion.ToString()
        OS           = [System.Environment]::OSVersion.VersionString
        ProcessorCount = [System.Environment]::ProcessorCount
    }
    Results    = $benchmarkResults
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des benchmarks:"
Write-Host "======================"
Write-Host "Date: $($results.Timestamp)"
Write-Host "Taille des données: $DataSize"
Write-Host "Itérations: $Iterations"
Write-Host "Système: PowerShell $($results.System.PSVersion) sur $($results.System.OS)"
Write-Host ""

$benchmarkResults | ForEach-Object {
    Write-Host "$($_.ModuleName).$($_.FunctionName):"
    Write-Host "  Moyenne: $([Math]::Round($_.AverageMs, 2)) ms"
    Write-Host "  Min: $([Math]::Round($_.MinMs, 2)) ms"
    Write-Host "  Max: $([Math]::Round($_.MaxMs, 2)) ms"
    Write-Host ""
}

# Enregistrer les résultats dans un fichier JSON
$results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Résultats enregistrés dans: $OutputPath"
