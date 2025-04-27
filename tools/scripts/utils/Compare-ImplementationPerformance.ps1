#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les performances entre diffÃ©rentes implÃ©mentations.
.DESCRIPTION
    Ce script compare les performances entre l'implÃ©mentation originale basÃ©e sur des classes
    et l'implÃ©mentation simplifiÃ©e basÃ©e sur des objets personnalisÃ©s.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport de performance.
.PARAMETER TestFiles
    Nombre de fichiers de test Ã  gÃ©nÃ©rer.
.PARAMETER TestIterations
    Nombre d'itÃ©rations pour chaque test.
.EXAMPLE
    .\Compare-ImplementationPerformance.ps1 -TestFiles 10 -TestIterations 5
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "$env:TEMP\PerformanceComparisonReport.html",

    [Parameter()]
    [int]$NumberOfTestFiles = 10,

    [Parameter()]
    [int]$TestIterations = 3
)

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PerformanceComparisonTest_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test
function New-TestFile {
    param(
        [string]$Path,
        [string]$Content,
        [int]$Size = 1  # Taille relative du fichier (1 = normal, 2 = double, etc.)
    )

    $fullPath = Join-Path -Path $testDir -ChildPath $Path
    $directory = Split-Path -Path $fullPath -Parent

    if (-not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    # RÃ©pÃ©ter le contenu pour augmenter la taille du fichier
    $repeatedContent = ""
    for ($i = 0; $i -lt $Size; $i++) {
        $repeatedContent += $Content
    }

    Set-Content -Path $fullPath -Value $repeatedContent -Encoding UTF8
    return $fullPath
}

# Fonction pour gÃ©nÃ©rer un contenu de fichier alÃ©atoire
function New-RandomFileContent {
    param(
        [string]$Type,
        [int]$FunctionCount = 5,
        [int]$ClassCount = 2,
        [int]$VariableCount = 10
    )

    $content = "# Test $Type File`n"

    # GÃ©nÃ©rer des fonctions
    for ($i = 1; $i -le $FunctionCount; $i++) {
        switch ($Type) {
            "PowerShell" {
                $content += "function Test-Function$i {`n"
                $content += "    param(`n"
                $content += "        [string]`$param1,`n"
                $content += "        [int]`$param2 = 0`n"
                $content += "    )`n`n"

                # Ajouter des variables
                for ($j = 1; $j -le $VariableCount; $j++) {
                    $content += "    `$testVariable$j = `"Test value $j`"`n"
                }

                $content += "    Write-Output `$testVariable1`n"
                $content += "}`n`n"
            }
            "Python" {
                $content += "def test_function$i(param1, param2=0):`n"

                # Ajouter des variables
                for ($j = 1; $j -le $VariableCount; $j++) {
                    $content += "    test_variable$j = `"Test value $j`"`n"
                }

                $content += "    print(test_variable1)`n`n"
            }
            "JavaScript" {
                $content += "function testFunction$i(param1, param2 = 0) {`n"

                # Ajouter des variables
                for ($j = 1; $j -le $VariableCount; $j++) {
                    $content += "    const testVariable$j = `"Test value $j`";`n"
                }

                $content += "    console.log(testVariable1);`n"
                $content += "}`n`n"
            }
        }
    }

    # GÃ©nÃ©rer des classes
    for ($i = 1; $i -le $ClassCount; $i++) {
        switch ($Type) {
            "PowerShell" {
                $content += "class TestClass$i {`n"
                $content += "    [string]`$Name`n`n"

                $content += "    TestClass$i([string]`$name) {`n"
                $content += "        `$this.Name = `$name`n"
                $content += "    }`n`n"

                $content += "    [string] ToString() {`n"
                $content += "        return `$this.Name`n"
                $content += "    }`n"
                $content += "}`n`n"
            }
            "Python" {
                $content += "class TestClass${i}:`n"
                $content += "    def __init__(self, name):`n"
                $content += "        self.name = name`n`n"

                $content += "    def __str__(self):`n"
                $content += "        return self.name`n`n"
            }
            "JavaScript" {
                $content += "class TestClass$i {`n"
                $content += "    constructor(name) {`n"
                $content += "        this.name = name;`n"
                $content += "    }`n`n"

                $content += "    toString() {`n"
                $content += "        return this.name;`n"
                $content += "    }`n"
                $content += "}`n`n"
            }
        }
    }

    # Ajouter du code d'utilisation
    switch ($Type) {
        "PowerShell" {
            $content += "# Utilisation`n"
            $content += "`$obj = [TestClass1]::new(`"Test`")`n"
            $content += "Test-Function1 -param1 `"Test`" -param2 42`n"
        }
        "Python" {
            $content += "# Utilisation`n"
            $content += "if __name__ == `"__main__`":`n"
            $content += "    obj = TestClass1(`"Test`")`n"
            $content += "    test_function1(`"Test`", 42)`n"
        }
        "JavaScript" {
            $content += "// Utilisation`n"
            $content += "const obj = new TestClass1(`"Test`");`n"
            $content += "testFunction1(`"Test`", 42);`n"
        }
    }

    return $content
}

# Fonction pour mesurer les performances
function Measure-Performance {
    param(
        [string]$ModulePath,
        [string[]]$FilePaths,
        [int]$Iterations = 3
    )

    # Importer le module
    Import-Module $ModulePath -Force

    $results = @{
        SingleFileIndexing   = @()
        MultipleFileIndexing = @()
        IncrementalIndexing  = @()
    }

    # Test 1: Indexation d'un seul fichier
    for ($i = 0; $i -lt $Iterations; $i++) {
        $filePath = $FilePaths[0]

        # CrÃ©er un indexeur
        $indexer = New-FileContentIndexer -IndexPath $testDir

        # Mesurer le temps d'indexation
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        New-FileIndex -Indexer $indexer -FilePath $filePath | Out-Null
        $stopwatch.Stop()

        $results.SingleFileIndexing += $stopwatch.ElapsedMilliseconds
    }

    # Test 2: Indexation de plusieurs fichiers
    for ($i = 0; $i -lt $Iterations; $i++) {
        # CrÃ©er un indexeur
        $indexer = New-FileContentIndexer -IndexPath $testDir

        # Mesurer le temps d'indexation
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        New-ParallelFileIndices -Indexer $indexer -FilePaths $FilePaths | Out-Null
        $stopwatch.Stop()

        $results.MultipleFileIndexing += $stopwatch.ElapsedMilliseconds
    }

    # Test 3: Indexation incrÃ©mentale
    for ($i = 0; $i -lt $Iterations; $i++) {
        $filePath = $FilePaths[0]
        $content = Get-Content -Path $filePath -Raw
        $modifiedContent = $content.Replace("Test value 1", "Modified value 1")

        # CrÃ©er un indexeur
        $indexer = New-FileContentIndexer -IndexPath $testDir

        # Indexer le fichier original
        New-FileIndex -Indexer $indexer -FilePath $filePath | Out-Null

        # Mesurer le temps d'indexation incrÃ©mentale
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        New-IncrementalFileIndex -Indexer $indexer -FilePath $filePath -OldContent $content -NewContent $modifiedContent | Out-Null
        $stopwatch.Stop()

        $results.IncrementalIndexing += $stopwatch.ElapsedMilliseconds
    }

    # Calculer les moyennes
    $averages = @{
        SingleFileIndexing   = ($results.SingleFileIndexing | Measure-Object -Average).Average
        MultipleFileIndexing = ($results.MultipleFileIndexing | Measure-Object -Average).Average
        IncrementalIndexing  = ($results.IncrementalIndexing | Measure-Object -Average).Average
    }

    return @{
        Results  = $results
        Averages = $averages
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-PerformanceReport {
    param(
        [hashtable]$SimpleResults,
        [hashtable]$OriginalResults,
        [string]$OutputPath
    )

    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME
    $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de comparaison de performance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .better { color: green; font-weight: bold; }
        .worse { color: red; }
        .info-box { background-color: #f0f0f0; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
        .chart-container { width: 100%; height: 400px; margin-bottom: 20px; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de comparaison de performance</h1>
    <div class="info-box">
        <p><strong>Date du rapport:</strong> $reportDate</p>
        <p><strong>Ordinateur:</strong> $computerName</p>
        <p><strong>SystÃ¨me d'exploitation:</strong> $($osInfo.Caption) $($osInfo.Version) $($osInfo.OSArchitecture)</p>
        <p><strong>PowerShell Version:</strong> $($PSVersionTable.PSVersion)</p>
        <p><strong>Edition:</strong> $($PSVersionTable.PSEdition)</p>
    </div>

    <h2>RÃ©sumÃ© des performances</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>ImplÃ©mentation simplifiÃ©e (ms)</th>
            <th>ImplÃ©mentation originale (ms)</th>
            <th>DiffÃ©rence (ms)</th>
            <th>DiffÃ©rence (%)</th>
        </tr>
"@

    # Ajouter les rÃ©sultats au tableau
    $tests = @("SingleFileIndexing", "MultipleFileIndexing", "IncrementalIndexing")
    $testNames = @{
        "SingleFileIndexing"   = "Indexation d'un seul fichier"
        "MultipleFileIndexing" = "Indexation de plusieurs fichiers"
        "IncrementalIndexing"  = "Indexation incrÃ©mentale"
    }

    foreach ($test in $tests) {
        $simpleAvg = $SimpleResults.Averages[$test]
        $originalAvg = $OriginalResults.Averages[$test]
        $diff = $simpleAvg - $originalAvg
        $diffPercent = if ($originalAvg -ne 0) { ($diff / $originalAvg) * 100 } else { 0 }

        $diffClass = if ($diff -lt 0) { "better" } else { "worse" }
        $diffSign = if ($diff -lt 0) { "-" } else { "+" }
        $diffAbs = [Math]::Abs($diff)
        $diffPercentAbs = [Math]::Abs($diffPercent)

        $html += @"
        <tr>
            <td>$($testNames[$test])</td>
            <td>$([Math]::Round($simpleAvg, 2))</td>
            <td>$([Math]::Round($originalAvg, 2))</td>
            <td class="$diffClass">$diffSign$([Math]::Round($diffAbs, 2))</td>
            <td class="$diffClass">$diffSign$([Math]::Round($diffPercentAbs, 2))%</td>
        </tr>
"@
    }

    $html += @"
    </table>

    <h2>Graphique de comparaison</h2>
    <div class="chart-container">
        <canvas id="performanceChart"></canvas>
    </div>

    <h2>DÃ©tails des tests</h2>
    <h3>Indexation d'un seul fichier</h3>
    <table>
        <tr>
            <th>ItÃ©ration</th>
            <th>ImplÃ©mentation simplifiÃ©e (ms)</th>
            <th>ImplÃ©mentation originale (ms)</th>
        </tr>
"@

    # Ajouter les dÃ©tails pour l'indexation d'un seul fichier
    for ($i = 0; $i -lt $SimpleResults.Results.SingleFileIndexing.Count; $i++) {
        $simpleTime = $SimpleResults.Results.SingleFileIndexing[$i]
        $originalTime = $OriginalResults.Results.SingleFileIndexing[$i]

        $html += @"
        <tr>
            <td>$($i + 1)</td>
            <td>$([Math]::Round($simpleTime, 2))</td>
            <td>$([Math]::Round($originalTime, 2))</td>
        </tr>
"@
    }

    $html += @"
    </table>

    <h3>Indexation de plusieurs fichiers</h3>
    <table>
        <tr>
            <th>ItÃ©ration</th>
            <th>ImplÃ©mentation simplifiÃ©e (ms)</th>
            <th>ImplÃ©mentation originale (ms)</th>
        </tr>
"@

    # Ajouter les dÃ©tails pour l'indexation de plusieurs fichiers
    for ($i = 0; $i -lt $SimpleResults.Results.MultipleFileIndexing.Count; $i++) {
        $simpleTime = $SimpleResults.Results.MultipleFileIndexing[$i]
        $originalTime = $OriginalResults.Results.MultipleFileIndexing[$i]

        $html += @"
        <tr>
            <td>$($i + 1)</td>
            <td>$([Math]::Round($simpleTime, 2))</td>
            <td>$([Math]::Round($originalTime, 2))</td>
        </tr>
"@
    }

    $html += @"
    </table>

    <h3>Indexation incrÃ©mentale</h3>
    <table>
        <tr>
            <th>ItÃ©ration</th>
            <th>ImplÃ©mentation simplifiÃ©e (ms)</th>
            <th>ImplÃ©mentation originale (ms)</th>
        </tr>
"@

    # Ajouter les dÃ©tails pour l'indexation incrÃ©mentale
    for ($i = 0; $i -lt $SimpleResults.Results.IncrementalIndexing.Count; $i++) {
        $simpleTime = $SimpleResults.Results.IncrementalIndexing[$i]
        $originalTime = $OriginalResults.Results.IncrementalIndexing[$i]

        $html += @"
        <tr>
            <td>$($i + 1)</td>
            <td>$([Math]::Round($simpleTime, 2))</td>
            <td>$([Math]::Round($originalTime, 2))</td>
        </tr>
"@
    }

    $html += @"
    </table>

    <script>
        // CrÃ©er le graphique
        const ctx = document.getElementById('performanceChart').getContext('2d');
        const chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['Indexation d\'un seul fichier', 'Indexation de plusieurs fichiers', 'Indexation incrÃ©mentale'],
                datasets: [
                    {
                        label: 'ImplÃ©mentation simplifiÃ©e',
                        data: [
                            $([Math]::Round($SimpleResults.Averages.SingleFileIndexing, 2)),
                            $([Math]::Round($SimpleResults.Averages.MultipleFileIndexing, 2)),
                            $([Math]::Round($SimpleResults.Averages.IncrementalIndexing, 2))
                        ],
                        backgroundColor: 'rgba(54, 162, 235, 0.5)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'ImplÃ©mentation originale',
                        data: [
                            $([Math]::Round($OriginalResults.Averages.SingleFileIndexing, 2)),
                            $([Math]::Round($OriginalResults.Averages.MultipleFileIndexing, 2)),
                            $([Math]::Round($OriginalResults.Averages.IncrementalIndexing, 2))
                        ],
                        backgroundColor: 'rgba(255, 99, 132, 0.5)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Temps (ms)'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

# CrÃ©er des fichiers de test
Write-Host "CrÃ©ation de fichiers de test..." -ForegroundColor Cyan
$testFilePaths = @()

for ($i = 1; $i -le $NumberOfTestFiles; $i++) {
    $type = switch ($i % 3) {
        0 { "PowerShell" }
        1 { "Python" }
        2 { "JavaScript" }
    }

    $size = [Math]::Max(1, $i % 5)  # Taille relative du fichier (1-4)
    $content = New-RandomFileContent -Type $type -FunctionCount (5 * $size) -ClassCount (2 * $size) -VariableCount (10 * $size)
    $extension = switch ($type) {
        "PowerShell" { ".ps1" }
        "Python" { ".py" }
        "JavaScript" { ".js" }
    }

    $filePath = New-TestFile -Path "test_$i$extension" -Content $content -Size $size
    $testFilePaths += $filePath
}

Write-Host "  $($testFilePaths.Count) fichiers de test crÃ©Ã©s" -ForegroundColor Green
Write-Host ""

# Mesurer les performances de l'implÃ©mentation simplifiÃ©e
Write-Host "Mesure des performances de l'implÃ©mentation simplifiÃ©e..." -ForegroundColor Cyan
$simpleModulePath = Join-Path -Path $PSScriptRoot -ChildPath "SimpleFileContentIndexer.psm1"
$simpleResults = Measure-Performance -ModulePath $simpleModulePath -FilePaths $testFilePaths -Iterations $TestIterations
Write-Host "  Mesures terminÃ©es" -ForegroundColor Green
Write-Host ""

# Mesurer les performances de l'implÃ©mentation originale
Write-Host "Mesure des performances de l'implÃ©mentation originale..." -ForegroundColor Cyan
$originalModulePath = Join-Path -Path $PSScriptRoot -ChildPath "CompatibleCode\FileContentIndexer.psm1"
$originalResults = Measure-Performance -ModulePath $originalModulePath -FilePaths $testFilePaths -Iterations $TestIterations
Write-Host "  Mesures terminÃ©es" -ForegroundColor Green
Write-Host ""

# GÃ©nÃ©rer le rapport
Write-Host "GÃ©nÃ©ration du rapport..." -ForegroundColor Cyan
$reportPath = New-PerformanceReport -SimpleResults $simpleResults -OriginalResults $originalResults -OutputPath $OutputPath
Write-Host "  Rapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
Write-Host ""

# Afficher un rÃ©sumÃ©
Write-Host "RÃ©sumÃ© des performances:" -ForegroundColor Cyan
Write-Host "  Indexation d'un seul fichier:" -ForegroundColor Yellow
Write-Host "    ImplÃ©mentation simplifiÃ©e: $([Math]::Round($simpleResults.Averages.SingleFileIndexing, 2)) ms" -ForegroundColor White
Write-Host "    ImplÃ©mentation originale: $([Math]::Round($originalResults.Averages.SingleFileIndexing, 2)) ms" -ForegroundColor White
Write-Host "  Indexation de plusieurs fichiers:" -ForegroundColor Yellow
Write-Host "    ImplÃ©mentation simplifiÃ©e: $([Math]::Round($simpleResults.Averages.MultipleFileIndexing, 2)) ms" -ForegroundColor White
Write-Host "    ImplÃ©mentation originale: $([Math]::Round($originalResults.Averages.MultipleFileIndexing, 2)) ms" -ForegroundColor White
Write-Host "  Indexation incrÃ©mentale:" -ForegroundColor Yellow
Write-Host "    ImplÃ©mentation simplifiÃ©e: $([Math]::Round($simpleResults.Averages.IncrementalIndexing, 2)) ms" -ForegroundColor White
Write-Host "    ImplÃ©mentation originale: $([Math]::Round($originalResults.Averages.IncrementalIndexing, 2)) ms" -ForegroundColor White
Write-Host ""

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  RÃ©pertoire de test supprimÃ©" -ForegroundColor Green
Write-Host ""

Write-Host "Ouvrez le rapport pour voir les rÃ©sultats dÃ©taillÃ©s: $reportPath" -ForegroundColor Green

# Retourner un objet avec les rÃ©sultats
return @{
    SimpleResults   = $simpleResults
    OriginalResults = $originalResults
    ReportPath      = $reportPath
}
