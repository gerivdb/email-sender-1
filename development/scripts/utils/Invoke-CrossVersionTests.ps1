#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests de compatibilitÃ© croisÃ©e entre PowerShell 5.1 et 7.
.DESCRIPTION
    Ce script exÃ©cute des tests sur PowerShell 5.1 et 7 pour vÃ©rifier la compatibilitÃ©
    des scripts et modules, et gÃ©nÃ¨re un rapport dÃ©taillÃ© des rÃ©sultats.
.PARAMETER TestScripts
    Chemins des scripts Ã  tester.
.PARAMETER TestModules
    Noms des modules Ã  tester.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport de compatibilitÃ©.
.EXAMPLE
    .\Invoke-CrossVersionTests.ps1 -TestScripts @(".\MyScript.ps1") -TestModules @("MyModule")
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$TestScripts = @(),

    [Parameter()]
    [string[]]$TestModules = @("FileContentIndexer"),

    [Parameter()]
    [string]$OutputPath = "$env:TEMP\CrossVersionTestReport.html",

    [Parameter()]
    [switch]$GenerateTestScripts = $true
)

# Fonction pour vÃ©rifier si PowerShell 7 est installÃ©
function Test-PowerShell7Installed {
    $ps7Paths = @(
        "${env:ProgramFiles}\PowerShell\7\pwsh.exe",
        "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
        "$env:LocalAppData\Microsoft\PowerShell\7\pwsh.exe"
    )

    foreach ($path in $ps7Paths) {
        if (Test-Path -Path $path) {
            return @{
                Installed = $true
                Path      = $path
                Version   = (Get-Item $path).VersionInfo.ProductVersion
            }
        }
    }

    # VÃ©rifier si pwsh est dans le PATH
    try {
        $pwshInPath = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($pwshInPath) {
            return @{
                Installed = $true
                Path      = $pwshInPath.Source
                Version   = (Get-Item $pwshInPath.Source).VersionInfo.ProductVersion
            }
        }
    } catch {
        # Ignorer les erreurs
    }

    return @{
        Installed = $false
        Path      = $null
        Version   = $null
    }
}

# Fonction pour gÃ©nÃ©rer un script de test
function New-TestScript {
    param(
        [string]$ModuleName,
        [string]$OutputPath
    )

    $testScriptPath = Join-Path -Path $OutputPath -ChildPath "Test-$ModuleName.ps1"

    $testScriptContent = @"
#
# Script de test pour le module $ModuleName
# Compatible avec PowerShell 5.1 et PowerShell 7
#

# Afficher les informations de version
Write-Host "Test du module $ModuleName" -ForegroundColor Cyan
Write-Host "PowerShell Version: `$(`$PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "Edition: `$(`$PSVersionTable.PSEdition)" -ForegroundColor Cyan
Write-Host ""

# Essayer d'importer le module
try {
    Import-Module .\$ModuleName.psm1 -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module: `$_" -ForegroundColor Red
    exit 1
}

# Tester les fonctionnalitÃ©s de base
try {
    # Obtenir les informations de version
    `$versionInfo = Get-PSVersionInfo
    Write-Host "Informations de version obtenues avec succÃ¨s" -ForegroundColor Green

    # VÃ©rifier la disponibilitÃ© des fonctionnalitÃ©s
    `$features = @('Classes', 'AdvancedClasses', 'Ternary', 'PipelineChain', 'NullCoalescing', 'ForEachParallel')
    foreach (`$feature in `$features) {
        `$available = Test-FeatureAvailability -FeatureName `$feature
        Write-Host "  `$feature : `$available"
    }

    # CrÃ©er une instance
    `$instance = New-$ModuleName -Name "TestInstance"
    Write-Host "Instance crÃ©Ã©e avec succÃ¨s" -ForegroundColor Green

    # Tester la mÃ©thode Process
    `$result1 = `$instance.Process("Test")
    `$result2 = `$instance.Process(`$null)
    Write-Host "MÃ©thode Process testÃ©e avec succÃ¨s" -ForegroundColor Green

    # Tester la parallÃ©lisation
    `$items = 1..3
    `$results = Invoke-Parallel -ScriptBlock {
        param(`$item)
        return [PSCustomObject]@{
            Item = `$item
            ProcessId = `$PID
        }
    } -InputObject `$items -ThrottleLimit 2

    Write-Host "ParallÃ©lisation testÃ©e avec succÃ¨s" -ForegroundColor Green

    # Tous les tests ont rÃ©ussi
    Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "Erreur lors des tests: `$_" -ForegroundColor Red
    exit 1
}
"@

    $testScriptContent | Out-File -FilePath $testScriptPath -Encoding UTF8
    return $testScriptPath
}

# Fonction pour exÃ©cuter un script avec PowerShell 5.1
function Invoke-PS5Test {
    param(
        [string]$ScriptPath
    )

    $startTime = Get-Date
    $result = @{
        ScriptPath = $ScriptPath
        Success    = $false
        Output     = ""
        Error      = ""
        Duration   = $null
    }

    try {
        # ExÃ©cuter le script avec PowerShell 5.1 (actuel si c'est 5.1)
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $output = & $ScriptPath 2>&1
            $exitCode = $LASTEXITCODE
            $result.Output = $output | Out-String
            $result.Success = $exitCode -eq 0
        } else {
            # Nous sommes dans PowerShell 7, donc nous devons appeler PowerShell 5.1
            $ps5Path = "powershell.exe"
            $output = & $ps5Path -NoProfile -ExecutionPolicy Bypass -File $ScriptPath 2>&1
            $exitCode = $LASTEXITCODE
            $result.Output = $output | Out-String
            $result.Success = $exitCode -eq 0
        }
    } catch {
        $result.Error = $_.Exception.Message
    }

    $endTime = Get-Date
    $result.Duration = $endTime - $startTime

    return $result
}

# Fonction pour exÃ©cuter un script avec PowerShell 7
function Invoke-PS7Test {
    param(
        [string]$ScriptPath,
        [string]$PS7Path
    )

    $startTime = Get-Date
    $result = @{
        ScriptPath = $ScriptPath
        Success    = $false
        Output     = ""
        Error      = ""
        Duration   = $null
    }

    try {
        # ExÃ©cuter le script avec PowerShell 7
        $output = & $PS7Path -NoProfile -ExecutionPolicy Bypass -File $ScriptPath 2>&1
        $exitCode = $LASTEXITCODE
        $result.Output = $output | Out-String
        $result.Success = $exitCode -eq 0
    } catch {
        $result.Error = $_.Exception.Message
    }

    $endTime = Get-Date
    $result.Duration = $endTime - $startTime

    return $result
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-CrossVersionTestReport {
    param(
        [array]$TestResults,
        [hashtable]$PS5Info,
        [hashtable]$PS7Info,
        [string]$OutputPath
    )

    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME
    $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests de compatibilitÃ© croisÃ©e PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        .info-box { background-color: #f0f0f0; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
        .output-box { background-color: #f8f8f8; padding: 10px; border: 1px solid #ddd; border-radius: 5px; margin-top: 5px; white-space: pre-wrap; font-family: Consolas, monospace; max-height: 200px; overflow-y: auto; }
    </style>
</head>
<body>
    <h1>Rapport de tests de compatibilitÃ© croisÃ©e PowerShell</h1>
    <div class="info-box">
        <p><strong>Date du rapport:</strong> $reportDate</p>
        <p><strong>Ordinateur:</strong> $computerName</p>
        <p><strong>SystÃ¨me d'exploitation:</strong> $($osInfo.Caption) $($osInfo.Version) $($osInfo.OSArchitecture)</p>
    </div>

    <h2>Informations PowerShell</h2>
    <table>
        <tr>
            <th>Version</th>
            <th>Disponible</th>
            <th>Chemin</th>
        </tr>
        <tr>
            <td>PowerShell 5.1</td>
            <td>$($PS5Info.Installed)</td>
            <td>$($PS5Info.Path)</td>
        </tr>
        <tr>
            <td>PowerShell 7</td>
            <td>$($PS7Info.Installed)</td>
            <td>$($PS7Info.Path)</td>
        </tr>
    </table>

    <h2>RÃ©sultats des tests</h2>
    <table>
        <tr>
            <th>Script</th>
            <th>PS 5.1</th>
            <th>PS 7</th>
            <th>Compatible</th>
            <th>DurÃ©e PS 5.1</th>
            <th>DurÃ©e PS 7</th>
            <th>DiffÃ©rence</th>
        </tr>
"@

    foreach ($result in $TestResults) {
        $ps5Class = if ($result.PS5Result.Success) { "success" } else { "error" }
        $ps7Class = if ($result.PS7Result.Success) { "success" } else { "error" }
        $compatibleClass = if ($result.PS5Result.Success -and $result.PS7Result.Success) { "success" } else { "error" }

        $ps5Duration = if ($result.PS5Result.Duration) { [math]::Round($result.PS5Result.Duration.TotalMilliseconds, 2) } else { "N/A" }
        $ps7Duration = if ($result.PS7Result.Duration) { [math]::Round($result.PS7Result.Duration.TotalMilliseconds, 2) } else { "N/A" }

        $durationDiff = "N/A"
        if ($result.PS5Result.Duration -and $result.PS7Result.Duration) {
            $diff = $result.PS7Result.Duration.TotalMilliseconds - $result.PS5Result.Duration.TotalMilliseconds
            $durationDiff = [math]::Round($diff, 2)
            if ([int]$durationDiff -lt 0) {
                $durationDiff = "$durationDiff ms (PS7 plus rapide)"
            } else {
                $durationDiff = "+$durationDiff ms (PS5 plus rapide)"
            }
        }

        $scriptName = Split-Path -Path $result.ScriptPath -Leaf

        $html += @"
        <tr>
            <td>$scriptName</td>
            <td class="$ps5Class">$($result.PS5Result.Success)</td>
            <td class="$ps7Class">$($result.PS7Result.Success)</td>
            <td class="$compatibleClass">$($result.PS5Result.Success -and $result.PS7Result.Success)</td>
            <td>$ps5Duration ms</td>
            <td>$ps7Duration ms</td>
            <td>$durationDiff</td>
        </tr>
"@
    }

    $html += @"
    </table>

    <h2>DÃ©tails des tests</h2>
"@

    foreach ($result in $TestResults) {
        $scriptName = Split-Path -Path $result.ScriptPath -Leaf

        $html += @"
    <h3>$scriptName</h3>
    <h4>PowerShell 5.1</h4>
    <p class="$($result.PS5Result.Success ? "success" : "error")">RÃ©sultat: $($result.PS5Result.Success ? "SuccÃ¨s" : "Ã‰chec")</p>
    <div class="output-box">$($result.PS5Result.Output)</div>

    <h4>PowerShell 7</h4>
    <p class="$($result.PS7Result.Success ? "success" : "error")">RÃ©sultat: $($result.PS7Result.Success ? "SuccÃ¨s" : "Ã‰chec")</p>
    <div class="output-box">$($result.PS7Result.Output)</div>
"@
    }

    $html += @"

    <h2>Recommandations</h2>
    <ul>
"@

    $incompatibleScripts = $TestResults | Where-Object { -not ($_.PS5Result.Success -and $_.PS7Result.Success) }
    if ($incompatibleScripts) {
        $html += @"
        <li class="warning">Certains scripts ne sont pas compatibles avec les deux versions de PowerShell. Consultez les dÃ©tails ci-dessus pour plus d'informations.</li>
"@
    } else {
        $html += @"
        <li class="success">Tous les scripts sont compatibles avec PowerShell 5.1 et PowerShell 7.</li>
"@
    }

    $html += @"
    </ul>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

# VÃ©rifier si PowerShell 7 est installÃ©
$ps7Info = Test-PowerShell7Installed
if (-not $ps7Info.Installed) {
    Write-Error "PowerShell 7 n'est pas installÃ©. Impossible d'exÃ©cuter les tests de compatibilitÃ© croisÃ©e."
    exit 1
}

# Obtenir les informations sur PowerShell 5.1
$ps5Info = @{
    Installed = $true
    Path      = "powershell.exe"
    Version   = "5.1"
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests si nÃ©cessaire
$testDir = Join-Path -Path $env:TEMP -ChildPath "CrossVersionTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# GÃ©nÃ©rer des scripts de test si demandÃ©
if ($GenerateTestScripts) {
    $generatedScripts = @()
    foreach ($module in $TestModules) {
        # Copier le module dans le rÃ©pertoire de test
        $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "CompatibleCode\$module.psm1"
        if (Test-Path -Path $modulePath) {
            $destModulePath = Join-Path -Path $testDir -ChildPath "$module.psm1"
            Copy-Item -Path $modulePath -Destination $destModulePath -Force

            # GÃ©nÃ©rer un script de test pour ce module
            $testScriptPath = New-TestScript -ModuleName $module -OutputPath $testDir
            $generatedScripts += $testScriptPath
        } else {
            Write-Warning "Module non trouvÃ©: $modulePath"
        }
    }

    $TestScripts += $generatedScripts
}

# ExÃ©cuter les tests
$testResults = @()
foreach ($script in $TestScripts) {
    # Obtenir le chemin complet du script
    if (-not [System.IO.Path]::IsPathRooted($script)) {
        if (Test-Path -Path $script) {
            $script = Resolve-Path -Path $script
        } elseif (Test-Path -Path (Join-Path -Path $testDir -ChildPath $script)) {
            $script = Join-Path -Path $testDir -ChildPath $script
        }
    }

    if (Test-Path -Path $script) {
        Write-Host "ExÃ©cution des tests pour $script" -ForegroundColor Cyan

        # ExÃ©cuter avec PowerShell 5.1
        Write-Host "  ExÃ©cution avec PowerShell 5.1..." -ForegroundColor Yellow
        $ps5Result = Invoke-PS5Test -ScriptPath $script

        # ExÃ©cuter avec PowerShell 7
        Write-Host "  ExÃ©cution avec PowerShell 7..." -ForegroundColor Yellow
        $ps7Result = Invoke-PS7Test -ScriptPath $script -PS7Path $ps7Info.Path

        # Ajouter les rÃ©sultats
        $testResults += [PSCustomObject]@{
            ScriptPath = $script
            PS5Result  = $ps5Result
            PS7Result  = $ps7Result
        }

        # Afficher un rÃ©sumÃ©
        if ($ps5Result.Success -and $ps7Result.Success) {
            Write-Host "  RÃ©sultat: Compatible avec les deux versions" -ForegroundColor Green
        } else {
            Write-Host "  RÃ©sultat: Non compatible" -ForegroundColor Red
            Write-Host "    PS5: $($ps5Result.Success)" -ForegroundColor ($ps5Result.Success ? "Green" : "Red")
            Write-Host "    PS7: $($ps7Result.Success)" -ForegroundColor ($ps7Result.Success ? "Green" : "Red")
        }
    } else {
        Write-Warning "Script non trouvÃ©: $script"
    }
}

# GÃ©nÃ©rer le rapport
$reportPath = New-CrossVersionTestReport -TestResults $testResults -PS5Info $ps5Info -PS7Info $ps7Info -OutputPath $OutputPath

# Afficher un rÃ©sumÃ©
Write-Host ""
Write-Host "Tests de compatibilitÃ© croisÃ©e terminÃ©s!" -ForegroundColor Green
Write-Host "  Scripts testÃ©s: $($testResults.Count)"
Write-Host "  Compatible avec PS5.1: $($testResults | Where-Object { $_.PS5Result.Success } | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "  Compatible avec PS7: $($testResults | Where-Object { $_.PS7Result.Success } | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "  Compatible avec les deux: $($testResults | Where-Object { $_.PS5Result.Success -and $_.PS7Result.Success } | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host ""
Write-Host "Rapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
Write-Host "Ouvrez ce fichier dans un navigateur pour voir le rapport complet."

# Nettoyer les fichiers temporaires
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue

# Retourner un objet avec les rÃ©sultats
return @{
    TestResults = $testResults
    PS5Info     = $ps5Info
    PS7Info     = $ps7Info
    ReportPath  = $reportPath
}
