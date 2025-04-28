#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport de couverture de code pour les fonctionnalitÃ©s de dÃ©tection de format.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un rapport de couverture de code pour les fonctionnalitÃ©s de dÃ©tection
    de format dÃ©veloppÃ©es dans le cadre de la section 2.1.2 de la roadmap.

.PARAMETER OutputPath
    Le chemin oÃ¹ le rapport de couverture sera enregistrÃ©. Par dÃ©faut, 'CodeCoverage.xml'.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ© en plus du rapport XML.

.EXAMPLE
    .\Get-CodeCoverage.ps1 -GenerateHtmlReport

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\CodeCoverage.xml",

    [Parameter()]
    [switch]$GenerateHtmlReport
)

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }
    catch {
        Write-Error "Impossible d'installer le module Pester. Le rapport de couverture ne peut pas Ãªtre gÃ©nÃ©rÃ©."
        return
    }
}

# Importer le module Pester
Import-Module Pester

# Chemins vers les scripts Ã  tester
$scriptsToTest = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "..\analysis\Detect-FileEncoding.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "..\analysis\Improved-FormatDetection.ps1")
)

# VÃ©rifier si les scripts existent
$validScripts = @()
foreach ($script in $scriptsToTest) {
    if (Test-Path -Path $script -PathType Leaf) {
        $validScripts += $script
    }
    else {
        Write-Warning "Le script $script n'existe pas et ne sera pas inclus dans le rapport de couverture."
    }
}

if ($validScripts.Count -eq 0) {
    Write-Error "Aucun script valide Ã  tester. Le rapport de couverture ne peut pas Ãªtre gÃ©nÃ©rÃ©."
    return
}

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $validScripts
$pesterConfig.CodeCoverage.OutputPath = $OutputPath
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'

# ExÃ©cuter les tests avec couverture de code
Write-Host "GÃ©nÃ©ration du rapport de couverture de code..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© de la couverture
$coverage = $testResults.CodeCoverage
$totalCommands = $coverage.NumberOfCommandsAnalyzed
$coveredCommands = $coverage.NumberOfCommandsExecuted
$missedCommands = $totalCommands - $coveredCommands
$coveragePercent = if ($totalCommands -gt 0) { [Math]::Round(($coveredCommands / $totalCommands) * 100, 2) } else { 0 }

Write-Host "`nRÃ©sumÃ© de la couverture de code :" -ForegroundColor Cyan
Write-Host "  Commandes analysÃ©es : $totalCommands" -ForegroundColor White
Write-Host "  Commandes couvertes : $coveredCommands" -ForegroundColor Green
Write-Host "  Commandes non couvertes : $missedCommands" -ForegroundColor $(if ($missedCommands -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Pourcentage de couverture : $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { "Green" } elseif ($coveragePercent -ge 50) { "Yellow" } else { "Red" })

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHtmlReport) {
    $htmlOutputPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")

    # GÃ©nÃ©rer un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
            color: #0078D4;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .progress-bar {
            width: 100%;
            background-color: #e0e0e0;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress {
            height: 20px;
            border-radius: 5px;
            background-color: #4CAF50;
            text-align: center;
            line-height: 20px;
            color: white;
        }
        .high {
            background-color: #4CAF50;
        }
        .medium {
            background-color: #FFC107;
        }
        .low {
            background-color: #F44336;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .covered {
            color: green;
        }
        .not-covered {
            color: red;
        }
    </style>
</head>
<body>
    <h1>Rapport de couverture de code</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>

    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Commandes analysÃ©es : $totalCommands</p>
        <p>Commandes couvertes : $coveredCommands</p>
        <p>Commandes non couvertes : $missedCommands</p>

        <div class="progress-bar">
            <div class="progress $([string]$(if ($coveragePercent -ge 80) { "high" } elseif ($coveragePercent -ge 50) { "medium" } else { "low" }))" style="width: $coveragePercent%">
                $coveragePercent%
            </div>
        </div>
    </div>

    <h2>DÃ©tails par fichier</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Commandes analysÃ©es</th>
            <th>Commandes couvertes</th>
            <th>Pourcentage</th>
        </tr>
"@

    foreach ($file in $coverage.CommandCoverage | Group-Object -Property File) {
        $filePath = $file.Name
        $fileName = Split-Path -Path $filePath -Leaf
        $fileCommands = $file.Group.Count
        $fileCovered = ($file.Group | Where-Object { $_.Executed -eq $true }).Count
        $filePercent = if ($fileCommands -gt 0) { [Math]::Round(($fileCovered / $fileCommands) * 100, 2) } else { 0 }
        $percentClass = if ($filePercent -ge 80) { "high" } elseif ($filePercent -ge 50) { "medium" } else { "low" }

        $htmlContent += @"
        <tr>
            <td>$fileName</td>
            <td>$fileCommands</td>
            <td>$fileCovered</td>
            <td>
                <div class="progress-bar">
                    <div class="progress $percentClass" style="width: $filePercent%">
                        $filePercent%
                    </div>
                </div>
            </td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>

    <h2>Lignes non couvertes</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Commande</th>
        </tr>
"@

    foreach ($command in $coverage.CommandCoverage | Where-Object { $_.Executed -eq $false }) {
        $filePath = $command.File
        $fileName = Split-Path -Path $filePath -Leaf
        $line = $command.Line
        $commandText = $command.Command

        $htmlContent += @"
        <tr>
            <td>$fileName</td>
            <td>$line</td>
            <td><code>$commandText</code></td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $htmlOutputPath -Encoding utf8

    Write-Host "`nRapport HTML gÃ©nÃ©rÃ© : $htmlOutputPath" -ForegroundColor Green
}

# Retourner les rÃ©sultats de la couverture
return $coverage
