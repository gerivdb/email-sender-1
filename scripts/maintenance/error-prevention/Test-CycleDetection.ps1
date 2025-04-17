#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le système de détection de cycles.
.DESCRIPTION
    Ce script exécute une série de tests pour valider le fonctionnement
    du système de détection de cycles.
.PARAMETER TestsPath
    Chemin du dossier contenant les tests.
.PARAMETER GenerateReport
    Génère un rapport détaillé des tests.
.PARAMETER ReportPath
    Chemin du fichier de rapport.
.EXAMPLE
    .\Test-CycleDetection.ps1 -GenerateReport -ReportPath ".\reports\cycle_detection_tests.html"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestsPath = ".\tests\cycle_detection",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ".\reports\cycle_detection_tests.html"
)

# Importer le module de détection de cycles
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\" -Resolve
$modulePath = Join-Path -Path $modulePath -ChildPath "modules\CycleDetector.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de détection de cycles introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour écrire dans le journal
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

# Fonction pour créer des fichiers de test
function New-TestFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    # Créer le dossier de tests s'il n'existe pas
    if (-not (Test-Path -Path $TestsPath)) {
        New-Item -Path $TestsPath -ItemType Directory -Force | Out-Null
    }
    
    # Créer des fichiers de test pour les scripts PowerShell
    
    # 1. Script sans dépendances
    $script1Path = Join-Path -Path $TestsPath -ChildPath "Script1.ps1"
    @"
# Script sans dépendances
Write-Host "Script 1"
"@ | Out-File -FilePath $script1Path -Encoding utf8
    
    # 2. Script avec une dépendance
    $script2Path = Join-Path -Path $TestsPath -ChildPath "Script2.ps1"
    @"
# Script avec une dépendance
. .\Script1.ps1
Write-Host "Script 2"
"@ | Out-File -FilePath $script2Path -Encoding utf8
    
    # 3. Script avec plusieurs dépendances
    $script3Path = Join-Path -Path $TestsPath -ChildPath "Script3.ps1"
    @"
# Script avec plusieurs dépendances
. .\Script1.ps1
. .\Script2.ps1
Write-Host "Script 3"
"@ | Out-File -FilePath $script3Path -Encoding utf8
    
    # 4. Script avec une dépendance cyclique
    $script4Path = Join-Path -Path $TestsPath -ChildPath "Script4.ps1"
    @"
# Script avec une dépendance cyclique
. .\Script5.ps1
Write-Host "Script 4"
"@ | Out-File -FilePath $script4Path -Encoding utf8
    
    # 5. Script avec une dépendance cyclique (retour à Script4)
    $script5Path = Join-Path -Path $TestsPath -ChildPath "Script5.ps1"
    @"
# Script avec une dépendance cyclique (retour à Script4)
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
    
    # 8. Script avec un appel de script cyclique (retour à Script7)
    $script8Path = Join-Path -Path $TestsPath -ChildPath "Script8.ps1"
    @"
# Script avec un appel de script cyclique (retour à Script7)
& .\Script7.ps1
Write-Host "Script 8"
"@ | Out-File -FilePath $script8Path -Encoding utf8
    
    # Créer un workflow n8n avec un cycle
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
    
    # Créer un workflow n8n sans cycle
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
    
    Write-Log "Fichiers de test créés dans $TestsPath" -Level "SUCCESS"
}

# Fonction pour exécuter les tests
function Start-CycleDetectionTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    Write-Log "Démarrage des tests de détection de cycles..." -Level "TITLE"
    
    # Créer les fichiers de test
    New-TestFiles -TestsPath $TestsPath
    
    # Initialiser le détecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth 10
    
    # Tableau pour stocker les résultats des tests
    $testResults = @()
    
    # Test 1: Détecter les dépendances d'un script sans dépendances
    $script1Path = Join-Path -Path $TestsPath -ChildPath "Script1.ps1"
    $deps1 = Find-ScriptDependencies -ScriptPath $script1Path
    
    $test1 = [PSCustomObject]@{
        Name = "Test 1: Script sans dépendances"
        Success = ($deps1.Count -eq 0)
        Details = "Nombre de dépendances détectées: $($deps1.Count)"
    }
    
    $testResults += $test1
    
    # Test 2: Détecter les dépendances d'un script avec une dépendance
    $script2Path = Join-Path -Path $TestsPath -ChildPath "Script2.ps1"
    $deps2 = Find-ScriptDependencies -ScriptPath $script2Path
    
    $test2 = [PSCustomObject]@{
        Name = "Test 2: Script avec une dépendance"
        Success = ($deps2.Count -eq 1)
        Details = "Nombre de dépendances détectées: $($deps2.Count)"
    }
    
    $testResults += $test2
    
    # Test 3: Détecter les dépendances d'un script avec plusieurs dépendances
    $script3Path = Join-Path -Path $TestsPath -ChildPath "Script3.ps1"
    $deps3 = Find-ScriptDependencies -ScriptPath $script3Path
    
    $test3 = [PSCustomObject]@{
        Name = "Test 3: Script avec plusieurs dépendances"
        Success = ($deps3.Count -eq 2)
        Details = "Nombre de dépendances détectées: $($deps3.Count)"
    }
    
    $testResults += $test3
    
    # Test 4: Détecter un cycle direct
    $script4Path = Join-Path -Path $TestsPath -ChildPath "Script4.ps1"
    $script5Path = Join-Path -Path $TestsPath -ChildPath "Script5.ps1"
    
    # Ajouter les dépendances
    Add-Dependency -SourceId $script4Path -TargetId $script5Path -Type "DotSource"
    $cycleDetected = Add-Dependency -SourceId $script5Path -TargetId $script4Path -Type "DotSource"
    
    $test4 = [PSCustomObject]@{
        Name = "Test 4: Détection d'un cycle direct"
        Success = (-not $cycleDetected)
        Details = "Cycle détecté: $(-not $cycleDetected)"
    }
    
    $testResults += $test4
    
    # Test 5: Détecter un cycle dans un workflow n8n
    $workflowPath = Join-Path -Path $TestsPath -ChildPath "workflow_with_cycle.json"
    $workflowCycle = Test-N8nWorkflowCycles -WorkflowPath $workflowPath
    
    $test5 = [PSCustomObject]@{
        Name = "Test 5: Détection d'un cycle dans un workflow n8n"
        Success = (-not $workflowCycle)
        Details = "Cycle détecté: $(-not $workflowCycle)"
    }
    
    $testResults += $test5
    
    # Test 6: Vérifier qu'un workflow sans cycle est validé
    $workflowPath2 = Join-Path -Path $TestsPath -ChildPath "workflow_without_cycle.json"
    $workflowCycle2 = Test-N8nWorkflowCycles -WorkflowPath $workflowPath2
    
    $test6 = [PSCustomObject]@{
        Name = "Test 6: Validation d'un workflow n8n sans cycle"
        Success = $workflowCycle2
        Details = "Workflow validé: $workflowCycle2"
    }
    
    $testResults += $test6
    
    # Test 7: Détecter un cycle d'appel de script
    $script7Path = Join-Path -Path $TestsPath -ChildPath "Script7.ps1"
    $script8Path = Join-Path -Path $TestsPath -ChildPath "Script8.ps1"
    
    $callCycle = Test-ScriptCallCycle -CallerPath $script7Path -TargetPath $script8Path -CallStack @()
    $callCycle2 = Test-ScriptCallCycle -CallerPath $script8Path -TargetPath $script7Path -CallStack @($script7Path)
    
    $test7 = [PSCustomObject]@{
        Name = "Test 7: Détection d'un cycle d'appel de script"
        Success = (-not $callCycle) -and $callCycle2
        Details = "Premier appel: $(-not $callCycle), Deuxième appel (avec cycle): $callCycle2"
    }
    
    $testResults += $test7
    
    # Test 8: Détecter un cycle de fonction
    $functionCycle = Test-FunctionCallCycle -CallerFunction "Function1" -TargetFunction "Function2" -CallStack @()
    $functionCycle2 = Test-FunctionCallCycle -CallerFunction "Function2" -TargetFunction "Function1" -CallStack @("Function1")
    
    $test8 = [PSCustomObject]@{
        Name = "Test 8: Détection d'un cycle d'appel de fonction"
        Success = (-not $functionCycle) -and $functionCycle2
        Details = "Premier appel: $(-not $functionCycle), Deuxième appel (avec cycle): $functionCycle2"
    }
    
    $testResults += $test8
    
    # Afficher les résultats
    $successCount = ($testResults | Where-Object { $_.Success }).Count
    $totalCount = $testResults.Count
    
    Write-Log "Résultats des tests: $successCount / $totalCount tests réussis" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARNING" })
    
    foreach ($result in $testResults) {
        $status = if ($result.Success) { "RÉUSSI" } else { "ÉCHOUÉ" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        
        Write-Host "[$status] " -NoNewline -ForegroundColor $color
        Write-Host "$($result.Name): $($result.Details)"
    }
    
    return $testResults
}

# Fonction pour générer un rapport HTML
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
    <title>Rapport des tests de détection de cycles</title>
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
    <h1>Rapport des tests de détection de cycles</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests réussis: <span class="success-rate">$successCount / $totalCount ($successRate%)</span></p>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Résultat</th>
            <th>Détails</th>
        </tr>
"@
    
    foreach ($result in $TestResults) {
        $status = if ($result.Success) { "RÉUSSI" } else { "ÉCHOUÉ" }
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
    
    <p class="timestamp">Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($ReportPath)
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    $html | Out-File -FilePath $ReportPath -Encoding utf8
    
    Write-Log "Rapport généré: $ReportPath" -Level "SUCCESS"
}

# Exécuter les tests
$testResults = Start-CycleDetectionTests -TestsPath $TestsPath

# Générer le rapport si demandé
if ($GenerateReport) {
    New-TestReport -TestResults $testResults -ReportPath $ReportPath
}
