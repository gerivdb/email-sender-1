<#
.SYNOPSIS
    Script de test structurel pour n8n.

.DESCRIPTION
    Ce script vérifie l'intégrité et la structure des composants n8n.
    Il teste la présence des dossiers, fichiers, scripts et workflows nécessaires.

.PARAMETER N8nRootFolder
    Dossier racine de n8n (par défaut: n8n).

.PARAMETER WorkflowFolder
    Dossier contenant les workflows n8n (par défaut: n8n/data/.n8n/workflows).

.PARAMETER ConfigFolder
    Dossier contenant les fichiers de configuration (par défaut: n8n/config).

.PARAMETER LogFolder
    Dossier contenant les fichiers de log (par défaut: n8n/logs).

.PARAMETER LogFile
    Fichier de log pour le test structurel (par défaut: n8n/logs/structure-test.log).

.PARAMETER ReportFile
    Fichier de rapport JSON pour le test structurel (par défaut: n8n/logs/structure-test-report.json).

.PARAMETER HtmlReportFile
    Fichier de rapport HTML pour le test structurel (par défaut: n8n/logs/structure-test-report.html).

.PARAMETER TestLevel
    Niveau de détail du test (1: Basic, 2: Standard, 3: Detailed) (par défaut: 2).

.PARAMETER FixIssues
    Indique si les problèmes détectés doivent être corrigés automatiquement (par défaut: $false).

.PARAMETER NotificationEnabled
    Indique si les notifications doivent être envoyées (par défaut: $true).

.PARAMETER NotificationScript
    Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1).

.PARAMETER NotificationLevel
    Niveau minimum pour envoyer une notification (INFO, WARNING, ERROR) (par défaut: WARNING).

.EXAMPLE
    .\test-structure.ps1 -N8nRootFolder "n8n" -FixIssues $true

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$N8nRootFolder = "n8n",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkflowFolder = "n8n/data/.n8n/workflows",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFolder = "n8n/config",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFolder = "n8n/logs",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n/logs/structure-test.log",
    
    [Parameter(Mandatory=$false)]
    [string]$ReportFile = "n8n/logs/structure-test-report.json",
    
    [Parameter(Mandatory=$false)]
    [string]$HtmlReportFile = "n8n/logs/structure-test-report.html",
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 3)]
    [int]$TestLevel = 2,
    
    [Parameter(Mandatory=$false)]
    [bool]$FixIssues = $false,
    
    [Parameter(Mandatory=$false)]
    [bool]$NotificationEnabled = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationScript = "n8n/automation/notification/send-notification.ps1",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("INFO", "WARNING", "ERROR")]
    [string]$NotificationLevel = "WARNING"
)

# Importer les fonctions des parties précédentes
. "$PSScriptRoot\test-structure-part1.ps1"
. "$PSScriptRoot\test-structure-part2.ps1"
. "$PSScriptRoot\test-structure-part3.ps1"

# Mettre à jour les paramètres communs
$script:CommonParams.N8nRootFolder = $N8nRootFolder
$script:CommonParams.WorkflowFolder = $WorkflowFolder
$script:CommonParams.ConfigFolder = $ConfigFolder
$script:CommonParams.LogFolder = $LogFolder
$script:CommonParams.LogFile = $LogFile
$script:CommonParams.ReportFile = $ReportFile
$script:CommonParams.HtmlReportFile = $HtmlReportFile
$script:CommonParams.TestLevel = $TestLevel
$script:CommonParams.FixIssues = $FixIssues
$script:CommonParams.NotificationEnabled = $NotificationEnabled
$script:CommonParams.NotificationScript = $NotificationScript
$script:CommonParams.NotificationLevel = $NotificationLevel

# Vérifier si le dossier de log existe
$logFolder = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Afficher les informations de démarrage
Write-Log "=== Test structurel n8n ===" -Level "INFO"
Write-Log "Dossier racine: $N8nRootFolder" -Level "INFO"
Write-Log "Dossier des workflows: $WorkflowFolder" -Level "INFO"
Write-Log "Dossier de configuration: $ConfigFolder" -Level "INFO"
Write-Log "Dossier de log: $LogFolder" -Level "INFO"
Write-Log "Niveau de test: $TestLevel" -Level "INFO"
Write-Log "Correction automatique: $FixIssues" -Level "INFO"
Write-Log "Notifications activées: $NotificationEnabled" -Level "INFO"

# Tester la structure des dossiers
Write-Log "`n=== Test de la structure des dossiers ===" -Level "INFO"
$folderResults = Test-FolderStructure -ExpectedFolders $script:ExpectedStructure.Folders -FixIssues $FixIssues

# Tester la structure des fichiers
Write-Log "`n=== Test de la structure des fichiers ===" -Level "INFO"
$fileResults = Test-FileStructure -ExpectedFiles $script:ExpectedStructure.Files -FixIssues $FixIssues

# Tester la structure des scripts
Write-Log "`n=== Test de la structure des scripts ===" -Level "INFO"
$scriptResults = Test-ScriptStructure -ExpectedScripts $script:ExpectedStructure.Scripts -FixIssues $FixIssues

# Tester la structure des workflows
Write-Log "`n=== Test de la structure des workflows ===" -Level "INFO"
$workflowResults = Test-WorkflowStructure -WorkflowFolder $WorkflowFolder -FixIssues $FixIssues

# Tester la structure de configuration
Write-Log "`n=== Test de la structure de configuration ===" -Level "INFO"
$configResults = Test-ConfigStructure -ConfigFolder $ConfigFolder -FixIssues $FixIssues

# Calculer les résultats globaux
$totalTested = $folderResults.Tested + $fileResults.Tested + $scriptResults.Tested + $workflowResults.Tested + $configResults.Tested
$totalPassed = $folderResults.Passed + $fileResults.Passed + $scriptResults.Passed + $workflowResults.Passed + $configResults.Passed
$totalFailed = $folderResults.Failed + $fileResults.Failed + $scriptResults.Failed + $workflowResults.Failed + $configResults.Failed
$totalFixed = $folderResults.Fixed + $fileResults.Fixed + $scriptResults.Fixed + $workflowResults.Fixed + $configResults.Fixed

$successRate = if ($totalTested -gt 0) { [Math]::Round(($totalPassed / $totalTested) * 100, 2) } else { 0 }

# Afficher le résumé
Write-Log "`n=== Résumé du test structurel ===" -Level "INFO"
Write-Log "Éléments testés: $totalTested" -Level "INFO"
Write-Log "Éléments réussis: $totalPassed" -Level "SUCCESS"
Write-Log "Éléments échoués: $totalFailed" -Level $(if ($totalFailed -gt 0) { "WARNING" } else { "INFO" })
Write-Log "Éléments corrigés: $totalFixed" -Level $(if ($totalFixed -gt 0) { "SUCCESS" } else { "INFO" })
Write-Log "Taux de réussite: $successRate%" -Level $(if ($successRate -ge 90) { "SUCCESS" } elseif ($successRate -ge 70) { "WARNING" } else { "ERROR" })

# Préparer les résultats pour le rapport
$results = @{
    FolderStructure = $folderResults
    FileStructure = $fileResults
    ScriptStructure = $scriptResults
    WorkflowStructure = $workflowResults
    ConfigStructure = $configResults
    Summary = @{
        TotalTested = $totalTested
        TotalPassed = $totalPassed
        TotalFailed = $totalFailed
        TotalFixed = $totalFixed
        SuccessRate = $successRate
    }
    TestInfo = @{
        Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        N8nRootFolder = $N8nRootFolder
        WorkflowFolder = $WorkflowFolder
        ConfigFolder = $ConfigFolder
        LogFolder = $LogFolder
        TestLevel = $TestLevel
        FixIssues = $FixIssues
    }
}

# Générer le rapport JSON
Export-TestResultsToJson -Results $results -OutputFile $ReportFile

# Générer le rapport HTML
Export-TestResultsToHtml -Results $results -OutputFile $HtmlReportFile

# Envoyer une notification si nécessaire
if ($NotificationEnabled -and $totalFailed -gt 0) {
    Send-TestResultsNotification -Results $results
}

# Retourner les résultats
return $results
