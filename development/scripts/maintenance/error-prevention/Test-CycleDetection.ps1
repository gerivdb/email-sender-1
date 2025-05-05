#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le systÃƒÂ¨me de dÃƒÂ©tection de cycles.
.DESCRIPTION
    Ce script exÃƒÂ©cute une sÃƒÂ©rie de tests pour valider le fonctionnement
    du systÃƒÂ¨me de dÃƒÂ©tection de cycles.
.PARAMETER TestsPath
    Chemin du dossier contenant les tests.
.PARAMETER GenerateReport
    GÃƒÂ©nÃƒÂ¨re un rapport dÃƒÂ©taillÃƒÂ© des tests.
.PARAMETER ReportPath
    Chemin du fichier de rapport.
.EXAMPLE
    .\Test-CycleDetection.ps1 -GenerateReport -ReportPath ".\reports\cycle_detection_tests.html"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃƒÂ©ation: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestsPath = ".\development\testing\tests\cycle_detection",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ".\reports\cycle_detection_tests.html"
)

# Importer le module de dÃƒÂ©tection de cycles
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\" -Resolve
$modulePath = Join-Path -Path $modulePath -ChildPath "modules\CycleDetector.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de dÃƒÂ©tection de cycles introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour ÃƒÂ©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour crÃƒÂ©er des fichiers de test
function New-TestFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    # CrÃƒÂ©er le dossier de tests s'il n'existe pas
    if (-not (Test-Path -Path $TestsPath)) {
        New-Item -Path $TestsPath -ItemType Directory -Force | Out-Null
    }
    
    # CrÃƒÂ©er des fichiers de test pour les scripts PowerShell
    
    # 1. Script sans dÃƒÂ©pendances
    $script1Path = Join-Path -Path $TestsPath -ChildPath "Script1.ps1"
    @"
# Script sans dÃƒÂ©pendances
Write-Host "Script 1"
"@ | Out-File -FilePath $script1Path -Encoding utf8
    
    # 2. Script avec une dÃƒÂ©pendance
    $script2Path = Join-Path -Path $TestsPath -ChildPath "Script2.ps1"
    @"
# Script avec une dÃƒÂ©pendance
. .\Script1.ps1
Write-Host "Script 2"
"@ | Out-File -FilePath $script2Path -Encoding utf8
    
    # 3. Script avec plusieurs dÃƒÂ©pendances
    $script3Path = Join-Path -Path $TestsPath -ChildPath "Script3.ps1"
    @"
# Script avec plusieurs dÃƒÂ©pendances
. .\Script1.ps1
. .\Script2.ps1
Write-Host "Script 3"
"@ | Out-File -FilePath $script3Path -Encoding utf8
    
    # 4. Script avec une dÃƒÂ©pendance cyclique
    $script4Path = Join-Path -Path $TestsPath -ChildPath "Script4.ps1"
    @"
# Script avec une dÃƒÂ©pendance cyclique
. .\Script5.ps1
Write-Host "Script 4"
"@ | Out-File -FilePath $script4Path -Encoding utf8
    
    # 5. Script avec une dÃƒÂ©pendance cyclique (retour ÃƒÂ  Script4)
    $script5Path = Join-Path -Path $TestsPath -ChildPath "Script5.ps1"
    @"
# Script avec une dÃƒÂ©pendance cyclique (retour ÃƒÂ  Script4)
. .\Script4.ps1
Write-Host "Script 5"
"@ | Out-File -FilePath $script5Path -Encoding utf8
    
    # 6. Script avec un appel de script
    $script6Path = Join-Path -Path $TestsPath -ChildPath "Script6.ps1"
    @"
# Script avec un appel de script
& .\Script1.ps1
Write-Host "Script 6"
"@ | Out-File -FilePath $script6Path -Encoding utf8
    
    # 7. Script avec un appel de script cyclique
    $script7Path = Join-Path -Path $TestsPath -ChildPath "Script7.ps1"
    @"
# Script avec un appel de script cyclique
& .\Script8.ps1
Write-Host "Script 7"
"@ | Out-File -FilePath $script7Path -Encoding utf8
    
    # 8. Script avec un appel de script cyclique (retour ÃƒÂ  Script7)
    $script8Path = Join-Path -Path $TestsPath -ChildPath "Script8.ps1"
    @"
# Script avec un appel de script cyclique (retour ÃƒÂ  Script7)
& .\Script7.ps1
Write-Host "Script 8"
"@ | Out-File -FilePath $script8Path -Encoding utf8
    
    # CrÃƒÂ©er un workflow n8n avec un cycle
    $workflowPath = Join-Path -Path $TestsPath -ChildPath "workflow_with_cycle.json"
    @"
{
  "nodes": [
    {
      "id": "node1",
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "position": [100, 100]
    },
    {
      "id": "node2",
      "name": "Process",
      "type": "n8n-nodes-base.function",
      "position": [300, 100]
    },
    {
      "id": "node3",
      "name": "Decision",
      "type": "n8n-nodes-base.if",
      "position": [500, 100]
    },
    {
      "id": "node4",
      "name": "Loop",
      "type": "n8n-nodes-base.function",
      "position": [700, 100]
    }
  ],
  "connections": {
    "node1": {
      "main": [
        [
          {
            "node": "node2",
            "index": 0
          }
        ]
      ]
    },
    "node2": {
      "main": [
        [
          {
            "node": "node3",
            "index": 0
          }
        ]
      ]
    },
    "node3": {
      "main": [
        [
          {
            "node": "node4",
            "index": 0
          }
        ]
      ]
    },
    "node4": {
      "main": [
        [
          {
            "node": "node2",
            "index": 0
          }
        ]
      ]
    }
  }
}
"@ | Out-File -FilePath $workflowPath -Encoding utf8
    
    # CrÃƒÂ©er un workflow n8n sans cycle
    $workflowPath2 = Join-Path -Path $TestsPath -ChildPath "workflow_without_cycle.json"
    @"
{
  "nodes": [
    {
      "id": "node1",
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "position": [100, 100]
    },
    {
      "id": "node2",
      "name": "Process",
      "type": "n8n-nodes-base.function",
      "position": [300, 100]
    },
    {
      "id": "node3",
      "name": "Decision",
      "type": "n8n-nodes-base.if",
      "position": [500, 100]
    },
    {
      "id": "node4",
      "name": "End",
      "type": "n8n-nodes-base.function",
      "position": [700, 100]
    }
  ],
  "connections": {
    "node1": {
      "main": [
        [
          {
            "node": "node2",
            "index": 0
          }
        ]
      ]
    },
    "node2": {
      "main": [
        [
          {
            "node": "node3",
            "index": 0
          }
        ]
      ]
    },
    "node3": {
      "main": [
        [
          {
            "node": "node4",
            "index": 0
          }
        ]
      ]
    }
  }
}
"@ | Out-File -FilePath $workflowPath2 -Encoding utf8
    
    Write-Log "Fichiers de test crÃƒÂ©ÃƒÂ©s dans $TestsPath" -Level "SUCCESS"
}

# Fonction pour exÃƒÂ©cuter les tests
function Start-CycleDetectionTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    Write-Log "DÃƒÂ©marrage des tests de dÃƒÂ©tection de cycles..." -Level "TITLE"
    
    # CrÃƒÂ©er les fichiers de test
    New-TestFiles -TestsPath $TestsPath
    
    # Initialiser le dÃƒÂ©tecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth 10
    
    # Tableau pour stocker les rÃƒÂ©sultats des tests
    $testResults = @()
    
    # Test 1: DÃƒÂ©tecter les dÃƒÂ©pendances d'un script sans dÃƒÂ©pendances
    $script1Path = Join-Path -Path $TestsPath -ChildPath "Script1.ps1"
    $deps1 = Find-ScriptDependencies -ScriptPath $script1Path
    
    $test1 = [PSCustomObject]@{
        Name = "Test 1: Script sans dÃƒÂ©pendances"
        Success = ($deps1.Count -eq 0)
        Details = "Nombre de dÃƒÂ©pendances dÃƒÂ©tectÃƒÂ©es: $($deps1.Count)"
    }
    
    $testResults += $test1
    
    # Test 2: DÃƒÂ©tecter les dÃƒÂ©pendances d'un script avec une dÃƒÂ©pendance
    $script2Path = Join-Path -Path $TestsPath -ChildPath "Script2.ps1"
    $deps2 = Find-ScriptDependencies -ScriptPath $script2Path
    
    $test2 = [PSCustomObject]@{
        Name = "Test 2: Script avec une dÃƒÂ©pendance"
        Success = ($deps2.Count -eq 1)
        Details = "Nombre de dÃƒÂ©pendances dÃƒÂ©tectÃƒÂ©es: $($deps2.Count)"
    }
    
    $testResults += $test2
    
    # Test 3: DÃƒÂ©tecter les dÃƒÂ©pendances d'un script avec plusieurs dÃƒÂ©pendances
    $script3Path = Join-Path -Path $TestsPath -ChildPath "Script3.ps1"
    $deps3 = Find-ScriptDependencies -ScriptPath $script3Path
    
    $test3 = [PSCustomObject]@{
        Name = "Test 3: Script avec plusieurs dÃƒÂ©pendances"
        Success = ($deps3.Count -eq 2)
        Details = "Nombre de dÃƒÂ©pendances dÃƒÂ©tectÃƒÂ©es: $($deps3.Count)"
    }
    
    $testResults += $test3
    
    # Test 4: DÃƒÂ©tecter un cycle direct
    $script4Path = Join-Path -Path $TestsPath -ChildPath "Script4.ps1"
    $script5Path = Join-Path -Path $TestsPath -ChildPath "Script5.ps1"
    
    # Ajouter les dÃƒÂ©pendances
    Add-Dependency -SourceId $script4Path -TargetId $script5Path -Type "DotSource"
    $cycleDetected = Add-Dependency -SourceId $script5Path -TargetId $script4Path -Type "DotSource"
    
    $test4 = [PSCustomObject]@{
        Name = "Test 4: DÃƒÂ©tection d'un cycle direct"
        Success = (-not $cycleDetected)
        Details = "Cycle dÃƒÂ©tectÃƒÂ©: $(-not $cycleDetected)"
    }
    
    $testResults += $test4
    
    # Test 5: DÃƒÂ©tecter un cycle dans un workflow n8n
    $workflowPath = Join-Path -Path $TestsPath -ChildPath "workflow_with_cycle.json"
    $workflowCycle = Test-N8nWorkflowCycles -WorkflowPath $workflowPath
    
    $test5 = [PSCustomObject]@{
        Name = "Test 5: DÃƒÂ©tection d'un cycle dans un workflow n8n"
        Success = (-not $workflowCycle)
        Details = "Cycle dÃƒÂ©tectÃƒÂ©: $(-not $workflowCycle)"
    }
    
    $testResults += $test5
    
    # Test 6: VÃƒÂ©rifier qu'un workflow sans cycle est validÃƒÂ©
    $workflowPath2 = Join-Path -Path $TestsPath -ChildPath "workflow_without_cycle.json"
    $workflowCycle2 = Test-N8nWorkflowCycles -WorkflowPath $workflowPath2
    
    $test6 = [PSCustomObject]@{
        Name = "Test 6: Validation d'un workflow n8n sans cycle"
        Success = $workflowCycle2
        Details = "Workflow validÃƒÂ©: $workflowCycle2"
    }
    
    $testResults += $test6
    
    # Test 7: DÃƒÂ©tecter un cycle d'appel de script
    $script7Path = Join-Path -Path $TestsPath -ChildPath "Script7.ps1"
    $script8Path = Join-Path -Path $TestsPath -ChildPath "Script8.ps1"
    
    $callCycle = Test-ScriptCallCycle -CallerPath $script7Path -TargetPath $script8Path -CallStack @()
    $callCycle2 = Test-ScriptCallCycle -CallerPath $script8Path -TargetPath $script7Path -CallStack @($script7Path)
    
    $test7 = [PSCustomObject]@{
        Name = "Test 7: DÃƒÂ©tection d'un cycle d'appel de script"
        Success = (-not $callCycle) -and $callCycle2
        Details = "Premier appel: $(-not $callCycle), DeuxiÃƒÂ¨me appel (avec cycle): $callCycle2"
    }
    
    $testResults += $test7
    
    # Test 8: DÃƒÂ©tecter un cycle de fonction
    $functionCycle = Test-FunctionCallCycle -CallerFunction "Function1" -TargetFunction "Function2" -CallStack @()
    $functionCycle2 = Test-FunctionCallCycle -CallerFunction "Function2" -TargetFunction "Function1" -CallStack @("Function1")
    
    $test8 = [PSCustomObject]@{
        Name = "Test 8: DÃƒÂ©tection d'un cycle d'appel de fonction"
        Success = (-not $functionCycle) -and $functionCycle2
        Details = "Premier appel: $(-not $functionCycle), DeuxiÃƒÂ¨me appel (avec cycle): $functionCycle2"
    }
    
    $testResults += $test8
    
    # Afficher les rÃƒÂ©sultats
    $successCount = ($testResults | Where-Object { $_.Success }).Count
    $totalCount = $testResults.Count
    
    Write-Log "RÃƒÂ©sultats des tests: $successCount / $totalCount tests rÃƒÂ©ussis" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARNING" })
    
    foreach ($result in $testResults) {
        $status = if ($result.Success) { "RÃƒâ€°USSI" } else { "Ãƒâ€°CHOUÃƒâ€°" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        
        Write-Host "[$status] " -NoNewline -ForegroundColor $color
        Write-Host "$($result.Name): $($result.Details)"
    }
    
    return $testResults
}

# Fonction pour gÃƒÂ©nÃƒÂ©rer un rapport HTML
function New-TestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$TestResults,
        
        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )
    
    $successCount = ($TestResults | Where-Object { $_.Success }).Count
    $totalCount = $TestResults.Count
    $successRate = [math]::Round(($successCount / $totalCount) * 100, 2)
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport des tests de dÃƒÂ©tection de cycles</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2 {
            color: #0066cc;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .success-rate {
            font-size: 24px;
            font-weight: bold;
            color: $(if ($successRate -eq 100) { "#2ecc71" } else { "#e74c3c" });
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #0066cc;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .success {
            color: #2ecc71;
            font-weight: bold;
        }
        .failure {
            color: #e74c3c;
            font-weight: bold;
        }
        .timestamp {
            color: #666;
            font-style: italic;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Rapport des tests de dÃƒÂ©tection de cycles</h1>
    
    <div class="summary">
        <h2>RÃƒÂ©sumÃƒÂ©</h2>
        <p>Tests rÃƒÂ©ussis: <span class="success-rate">$successCount / $totalCount ($successRate%)</span></p>
    </div>
    
    <h2>DÃƒÂ©tails des tests</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>RÃƒÂ©sultat</th>
            <th>DÃƒÂ©tails</th>
        </tr>
"@
    
    foreach ($result in $TestResults) {
        $status = if ($result.Success) { "RÃƒâ€°USSI" } else { "Ãƒâ€°CHOUÃƒâ€°" }
        $statusClass = if ($result.Success) { "success" } else { "failure" }
        
        $html += @"
        <tr>
            <td>$($result.Name)</td>
            <td class="$statusClass">$status</td>
            <td>$($result.Details)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <p class="timestamp">Rapport gÃƒÂ©nÃƒÂ©rÃƒÂ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@
    
    # CrÃƒÂ©er le dossier de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($ReportPath)
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    $html | Out-File -FilePath $ReportPath -Encoding utf8
    
    Write-Log "Rapport gÃƒÂ©nÃƒÂ©rÃƒÂ©: $ReportPath" -Level "SUCCESS"
}

# ExÃƒÂ©cuter les tests
$testResults = Start-CycleDetectionTests -TestsPath $TestsPath

# GÃƒÂ©nÃƒÂ©rer le rapport si demandÃƒÂ©
if ($GenerateReport) {
    New-TestReport -TestResults $testResults -ReportPath $ReportPath
}
