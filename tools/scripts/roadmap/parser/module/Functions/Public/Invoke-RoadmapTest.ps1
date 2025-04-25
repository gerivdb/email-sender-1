<#
.SYNOPSIS
    Fonction principale du mode TEST qui permet de tester les fonctionnalités d'un module.

.DESCRIPTION
    Cette fonction exécute des tests unitaires et d'intégration sur un module
    en fonction des tâches spécifiées dans un fichier de roadmap.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à traiter (optionnel). Si non spécifié, toutes les tâches seront traitées.

.PARAMETER ModulePath
    Chemin vers le répertoire du module à tester.

.PARAMETER TestsPath
    Chemin vers le répertoire contenant les tests à exécuter.

.PARAMETER OutputPath
    Chemin où seront générés les fichiers de sortie.

.PARAMETER CoverageThreshold
    Seuil de couverture de code en pourcentage.

.PARAMETER GenerateReport
    Indique si un rapport de test doit être généré.

.PARAMETER IncludeCodeCoverage
    Indique si la couverture de code doit être incluse dans le rapport.

.PARAMETER TestFramework
    Framework de test à utiliser. Les valeurs possibles sont : Pester, NUnit, xUnit.

.PARAMETER ParallelTests
    Indique si les tests doivent être exécutés en parallèle.

.PARAMETER TestCases
    Chemin vers un fichier JSON contenant des cas de test supplémentaires.

.EXAMPLE
    Invoke-RoadmapTest -FilePath "roadmap.md" -TaskIdentifier "1.1" -ModulePath "module" -TestsPath "tests" -OutputPath "output" -CoverageThreshold 80 -GenerateReport $true

.OUTPUTS
    System.Collections.Hashtable
#>
function Invoke-RoadmapTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TestsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [int]$CoverageThreshold = 80,
        
        [Parameter(Mandatory = $false)]
        [bool]$GenerateReport = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeCodeCoverage = $true,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Pester", "NUnit", "xUnit")]
        [string]$TestFramework = "Pester",
        
        [Parameter(Mandatory = $false)]
        [bool]$ParallelTests = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$TestCases
    )
    
    # Initialiser les résultats
    $result = @{
        Success = $false
        TestCount = 0
        PassedCount = 0
        FailedCount = 0
        SkippedCount = 0
        Coverage = 0
        FailedTests = @()
        OutputFiles = @()
    }
    
    # Extraire les tâches de la roadmap
    $tasks = Get-RoadmapTasks -FilePath $FilePath -TaskIdentifier $TaskIdentifier
    
    if ($tasks.Count -eq 0) {
        Write-LogWarning "Aucune tâche trouvée dans le fichier de roadmap pour l'identifiant : $TaskIdentifier"
        return $result
    }
    
    Write-LogInfo "Nombre de tâches trouvées : $($tasks.Count)"
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-LogInfo "Répertoire de sortie créé : $OutputPath"
    }
    
    # Vérifier si le framework de test est installé
    switch ($TestFramework) {
        "Pester" {
            if (-not (Get-Module -ListAvailable -Name Pester)) {
                Write-LogWarning "Le module Pester n'est pas installé. Installation en cours..."
                try {
                    Install-Module -Name Pester -Force -SkipPublisherCheck
                    Import-Module Pester
                    Write-LogInfo "Module Pester installé avec succès."
                } catch {
                    Write-LogError "Impossible d'installer le module Pester : $_"
                    return $result
                }
            } else {
                Import-Module Pester
                Write-LogInfo "Module Pester importé."
            }
        }
        "NUnit" {
            Write-LogWarning "Le framework NUnit n'est pas pris en charge pour le moment."
            return $result
        }
        "xUnit" {
            Write-LogWarning "Le framework xUnit n'est pas pris en charge pour le moment."
            return $result
        }
    }
    
    # Trouver les fichiers de test
    $testFiles = Get-ChildItem -Path $TestsPath -Recurse -File -Filter "*.Tests.ps1"
    
    if ($testFiles.Count -eq 0) {
        $testFiles = Get-ChildItem -Path $TestsPath -Recurse -File -Filter "Test-*.ps1"
    }
    
    if ($testFiles.Count -eq 0) {
        Write-LogWarning "Aucun fichier de test trouvé dans le répertoire : $TestsPath"
        return $result
    }
    
    Write-LogInfo "Nombre de fichiers de test trouvés : $($testFiles.Count)"
    
    # Charger les cas de test supplémentaires si spécifiés
    $additionalTestCases = @()
    
    if ($TestCases -and (Test-Path -Path $TestCases)) {
        try {
            $additionalTestCases = Get-Content -Path $TestCases -Raw | ConvertFrom-Json
            Write-LogInfo "Nombre de cas de test supplémentaires chargés : $($additionalTestCases.Count)"
        } catch {
            Write-LogWarning "Impossible de charger les cas de test supplémentaires : $_"
        }
    }
    
    # Exécuter les tests
    Write-LogInfo "Exécution des tests avec le framework : $TestFramework"
    
    switch ($TestFramework) {
        "Pester" {
            # Créer la configuration Pester
            $pesterConfig = New-PesterConfiguration
            $pesterConfig.Run.Path = $testFiles.FullName
            $pesterConfig.Run.PassThru = $true
            $pesterConfig.Output.Verbosity = 'Detailed'
            
            if ($IncludeCodeCoverage) {
                $pesterConfig.CodeCoverage.Enabled = $true
                $pesterConfig.CodeCoverage.Path = Get-ChildItem -Path $ModulePath -Recurse -File -Filter "*.ps1" | Select-Object -ExpandProperty FullName
                $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "coverage.xml"
                $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
            }
            
            if ($ParallelTests) {
                $pesterConfig.Run.EnableExit = $false
                $pesterConfig.Run.Exit = $false
                $pesterConfig.Run.Container = @{
                    Parallel = $true
                    Jobs = 4
                    ThrottleLimit = 4
                }
            }
            
            # Exécuter les tests
            $testResults = Invoke-Pester -Configuration $pesterConfig
            
            # Traiter les résultats
            $result.TestCount = $testResults.TotalCount
            $result.PassedCount = $testResults.PassedCount
            $result.FailedCount = $testResults.FailedCount
            $result.SkippedCount = $testResults.SkippedCount
            
            # Calculer la couverture de code
            if ($IncludeCodeCoverage -and $testResults.CodeCoverage) {
                $totalCommands = $testResults.CodeCoverage.CommandsAnalyzedCount
                $coveredCommands = $testResults.CodeCoverage.CommandsExecutedCount
                
                if ($totalCommands -gt 0) {
                    $result.Coverage = [Math]::Round(($coveredCommands / $totalCommands) * 100, 2)
                }
            }
            
            # Collecter les tests échoués
            if ($testResults.Failed) {
                foreach ($failedTest in $testResults.Failed) {
                    $result.FailedTests += @{
                        Name = $failedTest.Name
                        Message = $failedTest.ErrorRecord.Exception.Message
                        File = $failedTest.Path
                        Line = $failedTest.ErrorRecord.InvocationInfo.ScriptLineNumber
                    }
                }
            }
            
            # Générer un rapport de test
            if ($GenerateReport) {
                $reportPath = Join-Path -Path $OutputPath -ChildPath "test_report.html"
                
                $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .success {
            color: #28a745;
        }
        .warning {
            color: #ffc107;
        }
        .danger {
            color: #dc3545;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .progress-bar {
            width: 100%;
            background-color: #f1f1f1;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 5px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Rapport de test</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p><strong>Date du rapport :</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Module testé :</strong> $ModulePath</p>
        <p><strong>Nombre de tests exécutés :</strong> $($result.TestCount)</p>
        <p><strong>Tests réussis :</strong> <span class="success">$($result.PassedCount)</span></p>
        <p><strong>Tests échoués :</strong> <span class="danger">$($result.FailedCount)</span></p>
        <p><strong>Tests ignorés :</strong> <span class="warning">$($result.SkippedCount)</span></p>
        <p><strong>Couverture de code :</strong> <span class="$(if ($result.Coverage -ge $CoverageThreshold) { "success" } else { "danger" })">$($result.Coverage)%</span></p>
        <p><strong>Seuil de couverture :</strong> $CoverageThreshold%</p>
        
        <div class="progress-bar">
            <div class="progress" style="width: $($result.Coverage)%">$($result.Coverage)%</div>
        </div>
    </div>
"@
                
                # Ajouter les tests échoués
                if ($result.FailedTests.Count -gt 0) {
                    $htmlReport += @"
    
    <h2>Tests échoués</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Message</th>
            <th>Fichier</th>
            <th>Ligne</th>
        </tr>
"@
                    
                    foreach ($failedTest in $result.FailedTests) {
                        $htmlReport += @"
        <tr>
            <td>$($failedTest.Name)</td>
            <td>$($failedTest.Message)</td>
            <td>$($failedTest.File)</td>
            <td>$($failedTest.Line)</td>
        </tr>
"@
                    }
                    
                    $htmlReport += @"
    </table>
"@
                }
                
                # Ajouter les détails de couverture de code
                if ($IncludeCodeCoverage -and $testResults.CodeCoverage) {
                    $htmlReport += @"
    
    <h2>Couverture de code</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Lignes analysées</th>
            <th>Lignes couvertes</th>
            <th>Couverture</th>
        </tr>
"@
                    
                    $filesCoverage = $testResults.CodeCoverage.CommandsAnalyzedPerFile.Keys | ForEach-Object {
                        $file = $_
                        $analyzed = $testResults.CodeCoverage.CommandsAnalyzedPerFile[$file]
                        $executed = $testResults.CodeCoverage.CommandsExecutedPerFile[$file]
                        $coverage = if ($analyzed -gt 0) { [Math]::Round(($executed / $analyzed) * 100, 2) } else { 0 }
                        
                        [PSCustomObject]@{
                            File = $file
                            Analyzed = $analyzed
                            Executed = $executed
                            Coverage = $coverage
                        }
                    }
                    
                    foreach ($fileCoverage in $filesCoverage) {
                        $htmlReport += @"
        <tr>
            <td>$($fileCoverage.File)</td>
            <td>$($fileCoverage.Analyzed)</td>
            <td>$($fileCoverage.Executed)</td>
            <td class="$(if ($fileCoverage.Coverage -ge $CoverageThreshold) { "success" } else { "danger" })">$($fileCoverage.Coverage)%</td>
        </tr>
"@
                    }
                    
                    $htmlReport += @"
    </table>
"@
                }
                
                $htmlReport += @"
</body>
</html>
"@
                
                # Écrire le rapport dans un fichier
                Set-Content -Path $reportPath -Value $htmlReport -Encoding UTF8
                $result.OutputFiles += $reportPath
                
                # Générer un rapport de couverture HTML
                if ($IncludeCodeCoverage) {
                    $coverageReportPath = Join-Path -Path $OutputPath -ChildPath "coverage_report.html"
                    
                    $coverageReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de couverture de code</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .success {
            color: #28a745;
        }
        .warning {
            color: #ffc107;
        }
        .danger {
            color: #dc3545;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .progress-bar {
            width: 100%;
            background-color: #f1f1f1;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 5px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
        .code {
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .line {
            display: block;
            position: relative;
            padding-left: 40px;
        }
        .line:before {
            content: attr(data-line);
            position: absolute;
            left: 0;
            width: 30px;
            text-align: right;
            color: #999;
        }
        .covered {
            background-color: #dff0d8;
        }
        .not-covered {
            background-color: #f2dede;
        }
    </style>
</head>
<body>
    <h1>Rapport de couverture de code</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p><strong>Date du rapport :</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Module testé :</strong> $ModulePath</p>
        <p><strong>Couverture de code :</strong> <span class="$(if ($result.Coverage -ge $CoverageThreshold) { "success" } else { "danger" })">$($result.Coverage)%</span></p>
        <p><strong>Seuil de couverture :</strong> $CoverageThreshold%</p>
        
        <div class="progress-bar">
            <div class="progress" style="width: $($result.Coverage)%">$($result.Coverage)%</div>
        </div>
    </div>
    
    <h2>Détails de couverture par fichier</h2>
"@
                    
                    foreach ($fileCoverage in $filesCoverage) {
                        $coverageReport += @"
    
    <h3>$($fileCoverage.File)</h3>
    <p><strong>Couverture :</strong> <span class="$(if ($fileCoverage.Coverage -ge $CoverageThreshold) { "success" } else { "danger" })">$($fileCoverage.Coverage)%</span></p>
    
    <div class="progress-bar">
        <div class="progress" style="width: $($fileCoverage.Coverage)%">$($fileCoverage.Coverage)%</div>
    </div>
"@
                        
                        # Ajouter le code source avec la couverture
                        if (Test-Path -Path $fileCoverage.File) {
                            $fileContent = Get-Content -Path $fileCoverage.File
                            $missedCommands = $testResults.CodeCoverage.MissedCommands | Where-Object { $_.File -eq $fileCoverage.File }
                            
                            $coverageReport += @"
    
    <div class="code">
"@
                            
                            for ($i = 0; $i -lt $fileContent.Count; $i++) {
                                $lineNumber = $i + 1
                                $isCovered = $true
                                
                                foreach ($missedCommand in $missedCommands) {
                                    if ($missedCommand.Line -eq $lineNumber) {
                                        $isCovered = $false
                                        break
                                    }
                                }
                                
                                $lineClass = if ($isCovered) { "covered" } else { "not-covered" }
                                
                                $coverageReport += @"
        <span class="line $lineClass" data-line="$lineNumber">$([System.Web.HttpUtility]::HtmlEncode($fileContent[$i]))</span>
"@
                            }
                            
                            $coverageReport += @"
    </div>
"@
                        }
                    }
                    
                    $coverageReport += @"
</body>
</html>
"@
                    
                    # Écrire le rapport dans un fichier
                    Set-Content -Path $coverageReportPath -Value $coverageReport -Encoding UTF8
                    $result.OutputFiles += $coverageReportPath
                }
            }
        }
        "NUnit" {
            Write-LogWarning "Le framework NUnit n'est pas pris en charge pour le moment."
        }
        "xUnit" {
            Write-LogWarning "Le framework xUnit n'est pas pris en charge pour le moment."
        }
    }
    
    # Vérifier si les tests ont réussi
    $result.Success = ($result.FailedCount -eq 0 -and $result.Coverage -ge $CoverageThreshold)
    
    return $result
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-RoadmapTest
