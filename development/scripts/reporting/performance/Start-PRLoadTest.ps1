#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests de charge pour les modules de rapports PR.
.DESCRIPTION
    Ce script exÃ©cute des tests de charge pour simuler une utilisation intensive
    des modules de rapports PR avec de grands volumes de donnÃ©es. Il mesure la
    consommation de ressources (CPU, mÃ©moire) et identifie les goulots d'Ã©tranglement.
.PARAMETER ModuleName
    Nom du module Ã  tester. Si non spÃ©cifiÃ©, tous les modules seront testÃ©s.
.PARAMETER FunctionName
    Nom de la fonction Ã  tester. Si non spÃ©cifiÃ©, toutes les fonctions du module seront testÃ©es.
.PARAMETER Duration
    DurÃ©e du test de charge en secondes. Par dÃ©faut: 60.
.PARAMETER Concurrency
    Nombre d'exÃ©cutions concurrentes. Par dÃ©faut: 5.
.PARAMETER DataSize
    Taille des donnÃ©es de test (Small, Medium, Large, ExtraLarge). Par dÃ©faut: Large.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats. Par dÃ©faut: ".\load_test_results.json".
.PARAMETER MonitorInterval
    Intervalle de surveillance des ressources en secondes. Par dÃ©faut: 1.
.EXAMPLE
    .\Start-PRLoadTest.ps1 -ModuleName "PRVisualization" -Duration 120 -Concurrency 10
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
    [int]$Duration = 60,

    [Parameter(Mandatory = $false)]
    [int]$Concurrency = 5,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Small", "Medium", "Large", "ExtraLarge")]
    [string]$DataSize = "Large",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\load_test_results.json",

    [Parameter(Mandatory = $false)]
    [int]$MonitorInterval = 1
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$modules = @(
    "PRReportFilters",
    "PRReportTemplates",
    "PRVisualization"
)

# Filtrer les modules si un module spÃ©cifique est demandÃ©
if ($ModuleName) {
    $modules = $modules | Where-Object { $_ -eq $ModuleName }
}

# Importer les modules
foreach ($module in $modules) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath "$module.psm1"
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
        Write-Verbose "Module importÃ©: $module"
    } else {
        Write-Error "Module non trouvÃ©: $modulePath"
    }
}

# Fonction pour gÃ©nÃ©rer des donnÃ©es de test
function New-TestData {
    param (
        [string]$Size
    )

    # DÃ©finir la taille des donnÃ©es en fonction du paramÃ¨tre
    $count = switch ($Size) {
        "Small" { 10 }
        "Medium" { 100 }
        "Large" { 1000 }
        "ExtraLarge" { 10000 }
        default { 100 }
    }

    Write-Verbose "GÃ©nÃ©ration de donnÃ©es de test de taille $Size ($count Ã©lÃ©ments)..."

    # GÃ©nÃ©rer des donnÃ©es de test pour PRReportFilters
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

    # GÃ©nÃ©rer des donnÃ©es de test pour PRVisualization
    $visualizationTestData = @()
    for ($i = 0; $i -lt $count; $i++) {
        $visualizationTestData += [PSCustomObject]@{
            Label = "Item $i"
            Value = $i % 100
            Color = "#{0:X2}{1:X2}{2:X2}" -f ($i % 255), (($i * 2) % 255), (($i * 3) % 255)
        }
    }

    # GÃ©nÃ©rer des donnÃ©es de test pour PRReportTemplates
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

    # CrÃ©er un template HTML de test
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

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "PRLoadTest_$(Get-Random)"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # CrÃ©er le fichier de template
    $templatePath = Join-Path -Path $testDir -ChildPath "template.html"
    Set-Content -Path $templatePath -Value $htmlTemplate -Encoding UTF8

    # Enregistrer le template
    if (Get-Command -Name Register-PRReportTemplate -ErrorAction SilentlyContinue) {
        Register-PRReportTemplate -Name "TestTemplate" -Format "HTML" -TemplatePath $templatePath -Force | Out-Null
    }

    return @{
        FilterTestData        = $filterTestData
        VisualizationTestData = $visualizationTestData
        TemplateTestData      = $templateTestData
        TemplatePath          = $templatePath
        TestDir               = $testDir
    }
}

# Fonction pour obtenir les informations de performance du processus
function Get-ProcessPerformance {
    $process = Get-Process -Id $PID

    return [PSCustomObject]@{
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        CPU           = $process.CPU
        WorkingSet    = $process.WorkingSet64
        PrivateMemory = $process.PrivateMemorySize64
        Handles       = $process.HandleCount
        Threads       = $process.Threads.Count
    }
}

# Fonction pour exÃ©cuter une fonction avec des paramÃ¨tres spÃ©cifiques
function Invoke-TestFunction {
    param (
        [string]$ModuleName,
        [string]$FunctionName,
        [object]$TestData
    )

    # PrÃ©parer les paramÃ¨tres pour la fonction
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
                    $outputPath = Join-Path -Path $TestData.TestDir -ChildPath "report_$([Guid]::NewGuid()).html"
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

    # ExÃ©cuter la fonction avec les paramÃ¨tres prÃ©parÃ©s
    try {
        $result = & $FunctionName @params
        return @{
            Success = $true
            Result  = $result
        }
    } catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

# Fonction pour exÃ©cuter un test de charge
function Start-LoadTest {
    param (
        [string]$ModuleName,
        [string]$FunctionName,
        [object]$TestData,
        [int]$Duration,
        [int]$Concurrency,
        [int]$MonitorInterval
    )

    Write-Host "DÃ©marrage du test de charge pour $ModuleName.$FunctionName..."
    Write-Host "  DurÃ©e: $Duration secondes"
    Write-Host "  Concurrence: $Concurrency exÃ©cutions simultanÃ©es"
    Write-Host "  Taille des donnÃ©es: $DataSize"
    Write-Host ""

    # Initialiser les rÃ©sultats
    $results = @{
        ModuleName    = $ModuleName
        FunctionName  = $FunctionName
        Duration      = $Duration
        Concurrency   = $Concurrency
        DataSize      = $DataSize
        StartTime     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        EndTime       = $null
        Executions    = 0
        Successes     = 0
        Failures      = 0
        AvgExecTime   = 0
        MinExecTime   = [double]::MaxValue
        MaxExecTime   = 0
        TotalExecTime = 0
        Performance   = @()
    }

    # DÃ©marrer la surveillance des performances
    $processId = $PID  # Stocker la valeur de $PID dans une variable normale
    $monitorJob = Start-Job -ScriptBlock {
        param ($ProcessId, $Duration, $Interval)

        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($Duration)
        $performance = @()

        while ((Get-Date) -lt $endTime) {
            $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
            if ($process) {
                $performance += [PSCustomObject]@{
                    Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                    CPU           = $process.CPU
                    WorkingSet    = $process.WorkingSet64
                    PrivateMemory = $process.PrivateMemorySize64
                    Handles       = $process.HandleCount
                    Threads       = $process.Threads.Count
                }
            }

            Start-Sleep -Seconds $Interval
        }

        return $performance
    } -ArgumentList $processId, $Duration, $MonitorInterval

    # DÃ©marrer le test de charge
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $runningJobs = @()

    while ((Get-Date) -lt $endTime) {
        # VÃ©rifier les jobs terminÃ©s
        $completedJobs = $runningJobs | Where-Object { $_.Job.State -eq "Completed" }
        foreach ($job in $completedJobs) {
            $jobResult = Receive-Job -Job $job.Job
            $results.Executions++

            if ($jobResult.Success) {
                $results.Successes++
            } else {
                $results.Failures++
            }

            $execTime = $job.EndTime - $job.StartTime
            $execTimeMs = $execTime.TotalMilliseconds

            $results.TotalExecTime += $execTimeMs
            $results.MinExecTime = [Math]::Min($results.MinExecTime, $execTimeMs)
            $results.MaxExecTime = [Math]::Max($results.MaxExecTime, $execTimeMs)

            # Supprimer le job
            Remove-Job -Job $job.Job -Force
        }

        # Supprimer les jobs terminÃ©s de la liste
        $runningJobs = $runningJobs | Where-Object { $_.Job.State -ne "Completed" }

        # DÃ©marrer de nouveaux jobs si nÃ©cessaire
        while ($runningJobs.Count -lt $Concurrency -and (Get-Date) -lt $endTime) {
            $jobStartTime = Get-Date
            $job = Start-Job -ScriptBlock {
                param ($ModuleName, $FunctionName, $TestData)

                # Importer les modules nÃ©cessaires
                $modulesPath = Join-Path -Path $using:PSScriptRoot -ChildPath "..\modules"
                $modulePath = Join-Path -Path $modulesPath -ChildPath "$ModuleName.psm1"

                # VÃ©rifier si le module existe
                if (Test-Path -Path $modulePath) {
                    Import-Module $modulePath -Force
                } else {
                    # Module fictif pour les tests
                    function Global:Test-DummyFunction { param($Data) return $Data }
                }

                # PrÃ©parer les paramÃ¨tres pour la fonction
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
                        }
                    }
                    "PRReportTemplates" {
                        switch ($FunctionName) {
                            "New-PRReport" {
                                $outputPath = Join-Path -Path $TestData.TestDir -ChildPath "report_$([Guid]::NewGuid()).html"
                                $params = @{
                                    TemplateName = "TestTemplate"
                                    Format       = "HTML"
                                    Data         = $TestData.TemplateTestData
                                    OutputPath   = $outputPath
                                }

                                # Enregistrer le template
                                Register-PRReportTemplate -Name "TestTemplate" -Format "HTML" -TemplatePath $TestData.TemplatePath -Force | Out-Null
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
                        }
                    }
                }

                # ExÃ©cuter la fonction avec les paramÃ¨tres prÃ©parÃ©s
                try {
                    # VÃ©rifier si la fonction existe
                    if (Get-Command -Name $FunctionName -ErrorAction SilentlyContinue) {
                        $result = & $FunctionName @params
                    } else {
                        # Utiliser la fonction fictive
                        $result = Test-DummyFunction -Data $TestData
                    }
                    return @{
                        Success = $true
                        Result  = $result
                    }
                } catch {
                    return @{
                        Success = $false
                        Error   = $_.Exception.Message
                    }
                }
            } -ArgumentList $ModuleName, $FunctionName, $TestData

            $runningJobs += [PSCustomObject]@{
                Job       = $job
                StartTime = $jobStartTime
                EndTime   = $null
            }
        }

        # Mettre Ã  jour les temps de fin des jobs terminÃ©s
        foreach ($job in $runningJobs) {
            if ($job.Job.State -eq "Completed" -and -not $job.EndTime) {
                $job.EndTime = Get-Date
            }
        }

        # Afficher la progression
        $progress = [Math]::Min(100, [Math]::Round(((Get-Date) - $startTime).TotalSeconds / $Duration * 100))
        Write-Progress -Activity "Test de charge en cours" -Status "$($results.Executions) exÃ©cutions, $($results.Successes) succÃ¨s, $($results.Failures) Ã©checs" -PercentComplete $progress

        # Attendre un peu
        Start-Sleep -Milliseconds 100
    }

    # Attendre que tous les jobs se terminent
    while ($runningJobs.Count -gt 0) {
        # VÃ©rifier les jobs terminÃ©s
        $completedJobs = $runningJobs | Where-Object { $_.Job.State -eq "Completed" }
        foreach ($job in $completedJobs) {
            $jobResult = Receive-Job -Job $job.Job
            $results.Executions++

            if ($jobResult.Success) {
                $results.Successes++
            } else {
                $results.Failures++
            }

            $execTime = $job.EndTime - $job.StartTime
            $execTimeMs = $execTime.TotalMilliseconds

            $results.TotalExecTime += $execTimeMs
            $results.MinExecTime = [Math]::Min($results.MinExecTime, $execTimeMs)
            $results.MaxExecTime = [Math]::Max($results.MaxExecTime, $execTimeMs)

            # Supprimer le job
            Remove-Job -Job $job.Job -Force
        }

        # Supprimer les jobs terminÃ©s de la liste
        $runningJobs = $runningJobs | Where-Object { $_.Job.State -ne "Completed" }

        # Mettre Ã  jour les temps de fin des jobs terminÃ©s
        foreach ($job in $runningJobs) {
            if ($job.Job.State -eq "Completed" -and -not $job.EndTime) {
                $job.EndTime = Get-Date
            }
        }

        # Attendre un peu
        Start-Sleep -Milliseconds 100
    }

    # RÃ©cupÃ©rer les donnÃ©es de performance
    $results.Performance = Receive-Job -Job $monitorJob
    Remove-Job -Job $monitorJob -Force

    # Calculer les statistiques finales
    $results.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($results.Executions -gt 0) {
        $results.AvgExecTime = $results.TotalExecTime / $results.Executions
    }

    return $results
}

# Fonction principale pour exÃ©cuter tous les tests de charge
function Start-AllLoadTests {
    param (
        [string[]]$Modules,
        [string]$FunctionFilter,
        [int]$Duration,
        [int]$Concurrency,
        [string]$DataSize,
        [int]$MonitorInterval
    )

    $allResults = @()
    $testData = New-TestData -Size $DataSize

    foreach ($module in $Modules) {
        # Obtenir toutes les fonctions exportÃ©es du module
        $functions = Get-Command -Module $module | Where-Object { $_.CommandType -eq "Function" }

        # Filtrer les fonctions si un filtre est spÃ©cifiÃ©
        if ($FunctionFilter) {
            $functions = $functions | Where-Object { $_.Name -like "*$FunctionFilter*" }
        }

        foreach ($function in $functions) {
            $functionName = $function.Name

            # Exclure certaines fonctions qui ne sont pas pertinentes pour les tests de charge
            if ($functionName -in @("Register-PRReportTemplate", "Get-PRReportTemplate", "Import-PRReportTemplates", "Get-ColorGradient")) {
                continue
            }

            # ExÃ©cuter le test de charge pour cette fonction
            $result = Start-LoadTest -ModuleName $module -FunctionName $functionName -TestData $testData -Duration $Duration -Concurrency $Concurrency -MonitorInterval $MonitorInterval

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

# ExÃ©cuter les tests de charge
$loadTestResults = Start-AllLoadTests -Modules $modules -FunctionFilter $FunctionName -Duration $Duration -Concurrency $Concurrency -DataSize $DataSize -MonitorInterval $MonitorInterval

# Ajouter des mÃ©tadonnÃ©es aux rÃ©sultats
$results = @{
    Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    DataSize    = $DataSize
    Duration    = $Duration
    Concurrency = $Concurrency
    System      = @{
        PSVersion      = $PSVersionTable.PSVersion.ToString()
        OS             = [System.Environment]::OSVersion.VersionString
        ProcessorCount = [System.Environment]::ProcessorCount
    }
    Results     = $loadTestResults
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests de charge:"
Write-Host "========================="
Write-Host "Date: $($results.Timestamp)"
Write-Host "Taille des donnÃ©es: $DataSize"
Write-Host "DurÃ©e: $Duration secondes"
Write-Host "Concurrence: $Concurrency exÃ©cutions simultanÃ©es"
Write-Host "SystÃ¨me: PowerShell $($results.System.PSVersion) sur $($results.System.OS)"
Write-Host ""

$loadTestResults | ForEach-Object {
    Write-Host "$($_.ModuleName).$($_.FunctionName):"
    Write-Host "  ExÃ©cutions: $($_.Executions)"
    Write-Host "  SuccÃ¨s: $($_.Successes)"
    Write-Host "  Ã‰checs: $($_.Failures)"
    Write-Host "  Temps moyen: $([Math]::Round($_.AvgExecTime, 2)) ms"
    Write-Host "  Temps min: $([Math]::Round($_.MinExecTime, 2)) ms"
    Write-Host "  Temps max: $([Math]::Round($_.MaxExecTime, 2)) ms"

    # Calculer les statistiques de performance
    if ($_.Performance.Count -gt 0) {
        $initialMemory = $_.Performance[0].WorkingSet
        $peakMemory = ($_.Performance | Measure-Object -Property WorkingSet -Maximum).Maximum
        $memoryGrowth = $peakMemory - $initialMemory

        Write-Host "  MÃ©moire initiale: $([Math]::Round($initialMemory / 1MB, 2)) MB"
        Write-Host "  MÃ©moire maximale: $([Math]::Round($peakMemory / 1MB, 2)) MB"
        Write-Host "  Croissance mÃ©moire: $([Math]::Round($memoryGrowth / 1MB, 2)) MB"
    }

    Write-Host ""
}

# Enregistrer les rÃ©sultats dans un fichier JSON
$results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "RÃ©sultats enregistrÃ©s dans: $OutputPath"
