<#
.SYNOPSIS
    Script de tests d'intégration pour n8n.

.DESCRIPTION
    Ce script exécute des tests d'intégration pour vérifier que tous les composants
    de la remédiation n8n fonctionnent correctement ensemble.

.PARAMETER ScenariosFile
    Fichier JSON contenant les scénarios de test (par défaut: test-scenarios.json).

.PARAMETER LogFile
    Fichier de log pour les tests d'intégration (par défaut: n8n/logs/integration-tests.log).

.PARAMETER ReportFile
    Fichier de rapport JSON pour les tests d'intégration (par défaut: n8n/logs/integration-tests-report.json).

.PARAMETER HtmlReportFile
    Fichier de rapport HTML pour les tests d'intégration (par défaut: n8n/logs/integration-tests-report.html).

.PARAMETER ScenarioFilter
    Filtre pour exécuter uniquement certains scénarios (par défaut: tous les scénarios).

.PARAMETER PriorityFilter
    Filtre pour exécuter uniquement les scénarios avec une certaine priorité (par défaut: toutes les priorités).

.PARAMETER NotificationEnabled
    Indique si les notifications doivent être envoyées (par défaut: $true).

.PARAMETER NotificationScript
    Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1).

.EXAMPLE
    .\integration-tests.ps1
    Exécute tous les scénarios de test.

.EXAMPLE
    .\integration-tests.ps1 -ScenarioFilter "lifecycle-basic"
    Exécute uniquement le scénario "lifecycle-basic".

.EXAMPLE
    .\integration-tests.ps1 -PriorityFilter "high"
    Exécute uniquement les scénarios avec une priorité "high".

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  24/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ScenariosFile = "$PSScriptRoot\test-scenarios.json",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n/logs/integration-tests.log",
    
    [Parameter(Mandatory=$false)]
    [string]$ReportFile = "n8n/logs/integration-tests-report.json",
    
    [Parameter(Mandatory=$false)]
    [string]$HtmlReportFile = "n8n/logs/integration-tests-report.html",
    
    [Parameter(Mandatory=$false)]
    [string]$ScenarioFilter = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("", "high", "medium", "low")]
    [string]$PriorityFilter = "",
    
    [Parameter(Mandatory=$false)]
    [bool]$NotificationEnabled = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationScript = "n8n/automation/notification/send-notification.ps1"
)

#region Fonctions de base

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Écrire dans le fichier de log
    Add-Content -Path $LogFile -Value $logMessage
    
    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour envoyer une notification
function Send-TestNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "WARNING"
    )
    
    # Vérifier si les notifications sont activées
    if (-not $NotificationEnabled) {
        Write-Log "Notifications désactivées. Message non envoyé: $Subject" -Level "INFO"
        return
    }
    
    # Vérifier si le script de notification existe
    if (-not (Test-Path -Path $NotificationScript)) {
        Write-Log "Script de notification non trouvé: $NotificationScript" -Level "ERROR"
        return
    }
    
    # Exécuter le script de notification
    try {
        & $NotificationScript -Subject $Subject -Message $Message -Level $Level
        Write-Log "Notification envoyée: $Subject" -Level "SUCCESS"
    } catch {
        Write-Log "Erreur lors de l'envoi de la notification: $_" -Level "ERROR"
    }
}

# Fonction pour vérifier si un dossier existe et le créer si nécessaire
function Ensure-FolderExists {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )
    
    if (-not (Test-Path -Path $FolderPath)) {
        try {
            New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
            Write-Log "Dossier créé: $FolderPath" -Level "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur lors de la création du dossier $FolderPath : $_" -Level "ERROR"
            return $false
        }
    }
    
    return $true
}

#endregion

#region Fonctions de test

# Fonction pour charger les scénarios de test
function Load-TestScenarios {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScenariosFile,
        
        [Parameter(Mandatory=$false)]
        [string]$ScenarioFilter = "",
        
        [Parameter(Mandatory=$false)]
        [string]$PriorityFilter = ""
    )
    
    try {
        # Vérifier si le fichier de scénarios existe
        if (-not (Test-Path -Path $ScenariosFile)) {
            Write-Log "Fichier de scénarios non trouvé: $ScenariosFile" -Level "ERROR"
            return @()
        }
        
        # Charger les scénarios
        $scenarios = Get-Content -Path $ScenariosFile -Raw | ConvertFrom-Json
        
        # Filtrer les scénarios si nécessaire
        if (-not [string]::IsNullOrEmpty($ScenarioFilter)) {
            $scenarios = $scenarios | Where-Object { $_.id -eq $ScenarioFilter }
        }
        
        if (-not [string]::IsNullOrEmpty($PriorityFilter)) {
            $scenarios = $scenarios | Where-Object { $_.priority -eq $PriorityFilter }
        }
        
        return $scenarios
    } catch {
        Write-Log "Erreur lors du chargement des scénarios: $_" -Level "ERROR"
        return @()
    }
}

# Fonction pour exécuter un scénario de test
function Execute-TestScenario {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Scenario
    )
    
    $scenarioResult = @{
        Id = $Scenario.id
        Name = $Scenario.name
        Description = $Scenario.description
        Priority = $Scenario.priority
        StartTime = Get-Date
        EndTime = $null
        Duration = 0
        Success = $true
        StepResults = @()
    }
    
    Write-Log "=== Exécution du scénario: $($Scenario.name) ===" -Level "INFO"
    Write-Log "Description: $($Scenario.description)" -Level "INFO"
    Write-Log "Priorité: $($Scenario.priority)" -Level "INFO"
    
    # Exécuter chaque étape du scénario
    foreach ($step in $Scenario.steps) {
        $stepResult = Execute-TestStep -Step $step
        $scenarioResult.StepResults += $stepResult
        
        # Si l'étape a échoué et que continueOnFailure est false, arrêter le scénario
        if (-not $stepResult.Success -and -not $step.continueOnFailure) {
            $scenarioResult.Success = $false
            Write-Log "Scénario arrêté suite à l'échec de l'étape: $($step.id)" -Level "ERROR"
            break
        }
    }
    
    $scenarioResult.EndTime = Get-Date
    $scenarioResult.Duration = ($scenarioResult.EndTime - $scenarioResult.StartTime).TotalSeconds
    
    # Afficher le résultat du scénario
    $statusLevel = if ($scenarioResult.Success) { "SUCCESS" } else { "ERROR" }
    Write-Log "Résultat du scénario: $($scenarioResult.Success ? "Succès" : "Échec")" -Level $statusLevel
    Write-Log "Durée: $($scenarioResult.Duration) secondes" -Level "INFO"
    
    return $scenarioResult
}

# Fonction pour exécuter une étape de test
function Execute-TestStep {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Step
    )
    
    $stepResult = @{
        Id = $Step.id
        Description = $Step.description
        Command = $Step.command
        ExpectedResult = $Step.expectedResult
        StartTime = Get-Date
        EndTime = $null
        Duration = 0
        ActualResult = $null
        Success = $false
        Error = $null
    }
    
    Write-Log "  Étape: $($Step.description)" -Level "INFO"
    
    try {
        # Exécuter la commande
        $result = Invoke-Expression -Command $Step.command
        $stepResult.ActualResult = $result
        
        # Vérifier le résultat
        if ($null -eq $Step.expectedResult) {
            # Si expectedResult est null, considérer l'étape comme réussie
            $stepResult.Success = $true
        } else {
            # Sinon, comparer le résultat avec expectedResult
            $stepResult.Success = ($result -eq $Step.expectedResult)
        }
        
        $statusLevel = if ($stepResult.Success) { "SUCCESS" } else { "ERROR" }
        Write-Log "    Résultat: $($stepResult.Success ? "Succès" : "Échec")" -Level $statusLevel
        
        if (-not $stepResult.Success) {
            Write-Log "    Résultat attendu: $($Step.expectedResult)" -Level "ERROR"
            Write-Log "    Résultat obtenu: $result" -Level "ERROR"
        }
    } catch {
        $stepResult.Success = $false
        $stepResult.Error = $_.Exception.Message
        Write-Log "    Erreur: $($stepResult.Error)" -Level "ERROR"
    }
    
    $stepResult.EndTime = Get-Date
    $stepResult.Duration = ($stepResult.EndTime - $stepResult.StartTime).TotalSeconds
    
    return $stepResult
}

#endregion

#region Fonctions de rapport

# Fonction pour générer un rapport JSON
function Generate-JsonReport {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$ReportFile
    )
    
    try {
        # Créer le dossier parent s'il n'existe pas
        $reportFolder = Split-Path -Path $ReportFile -Parent
        Ensure-FolderExists -FolderPath $reportFolder | Out-Null
        
        # Créer le rapport
        $report = @{
            TestDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            TotalScenarios = $Results.Count
            SuccessfulScenarios = ($Results | Where-Object { $_.Success }).Count
            FailedScenarios = ($Results | Where-Object { -not $_.Success }).Count
            TotalDuration = ($Results | Measure-Object -Property Duration -Sum).Sum
            ScenarioResults = $Results
        }
        
        # Enregistrer le rapport
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $ReportFile -Encoding UTF8
        
        Write-Log "Rapport JSON généré: $ReportFile" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la génération du rapport JSON: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour générer un rapport HTML
function Generate-HtmlReport {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$HtmlReportFile
    )
    
    try {
        # Créer le dossier parent s'il n'existe pas
        $reportFolder = Split-Path -Path $HtmlReportFile -Parent
        Ensure-FolderExists -FolderPath $reportFolder | Out-Null
        
        # Calculer les statistiques
        $totalScenarios = $Results.Count
        $successfulScenarios = ($Results | Where-Object { $_.Success }).Count
        $failedScenarios = ($Results | Where-Object { -not $_.Success }).Count
        $totalDuration = ($Results | Measure-Object -Property Duration -Sum).Sum
        $successRate = if ($totalScenarios -gt 0) { [Math]::Round(($successfulScenarios / $totalScenarios) * 100, 2) } else { 0 }
        
        # Déterminer la couleur en fonction du taux de réussite
        $statusColor = if ($successRate -ge 90) { "green" } elseif ($successRate -ge 70) { "orange" } else { "red" }
        
        # Générer le contenu HTML
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests d'intégration n8n</title>
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
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .status {
            font-weight: bold;
            color: $statusColor;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .success {
            color: green;
        }
        .error {
            color: red;
        }
        .warning {
            color: orange;
        }
        .details {
            margin-top: 10px;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 5px;
        }
        .step {
            margin-left: 20px;
        }
        .collapsible {
            background-color: #f2f2f2;
            color: #444;
            cursor: pointer;
            padding: 18px;
            width: 100%;
            border: none;
            text-align: left;
            outline: none;
            font-size: 15px;
            border-radius: 5px;
            margin-bottom: 5px;
        }
        .active, .collapsible:hover {
            background-color: #e6e6e6;
        }
        .content {
            padding: 0 18px;
            display: none;
            overflow: hidden;
            background-color: #f8f9fa;
            border-radius: 5px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de tests d'intégration n8n</h1>
        <p>Date des tests: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p>Scénarios testés: $totalScenarios</p>
            <p>Scénarios réussis: $successfulScenarios</p>
            <p>Scénarios échoués: $failedScenarios</p>
            <p>Durée totale: $totalDuration secondes</p>
            <p>Taux de réussite: <span class="status">$successRate%</span></p>
        </div>
        
        <h2>Résultats détaillés</h2>
"@
        
        # Ajouter les résultats des scénarios
        foreach ($scenario in $Results) {
            $statusClass = if ($scenario.Success) { "success" } else { "error" }
            $statusText = if ($scenario.Success) { "Succès" } else { "Échec" }
            
            $html += @"
        <button class="collapsible">$($scenario.Name) - <span class="$statusClass">$statusText</span> (Priorité: $($scenario.Priority), Durée: $($scenario.Duration) secondes)</button>
        <div class="content">
            <p><strong>Description:</strong> $($scenario.Description)</p>
            <p><strong>ID:</strong> $($scenario.Id)</p>
            <p><strong>Priorité:</strong> $($scenario.Priority)</p>
            <p><strong>Heure de début:</strong> $($scenario.StartTime)</p>
            <p><strong>Heure de fin:</strong> $($scenario.EndTime)</p>
            <p><strong>Durée:</strong> $($scenario.Duration) secondes</p>
            <p><strong>Résultat:</strong> <span class="$statusClass">$statusText</span></p>
            
            <h3>Étapes</h3>
            <table>
                <tr>
                    <th>ID</th>
                    <th>Description</th>
                    <th>Résultat</th>
                    <th>Durée (s)</th>
                </tr>
"@
            
            foreach ($step in $scenario.StepResults) {
                $stepStatusClass = if ($step.Success) { "success" } else { "error" }
                $stepStatusText = if ($step.Success) { "Succès" } else { "Échec" }
                
                $html += @"
                <tr>
                    <td>$($step.Id)</td>
                    <td>$($step.Description)</td>
                    <td class="$stepStatusClass">$stepStatusText</td>
                    <td>$($step.Duration)</td>
                </tr>
"@
            }
            
            $html += @"
            </table>
            
            <h3>Détails des étapes</h3>
"@
            
            foreach ($step in $scenario.StepResults) {
                $stepStatusClass = if ($step.Success) { "success" } else { "error" }
                $stepStatusText = if ($step.Success) { "Succès" } else { "Échec" }
                
                $html += @"
            <div class="step">
                <h4>$($step.Description)</h4>
                <p><strong>ID:</strong> $($step.Id)</p>
                <p><strong>Commande:</strong> <code>$($step.Command)</code></p>
                <p><strong>Résultat attendu:</strong> $($step.ExpectedResult)</p>
                <p><strong>Résultat obtenu:</strong> $($step.ActualResult)</p>
                <p><strong>Résultat:</strong> <span class="$stepStatusClass">$stepStatusText</span></p>
"@
                
                if (-not $step.Success -and $step.Error) {
                    $html += @"
                <p><strong>Erreur:</strong> <span class="error">$($step.Error)</span></p>
"@
                }
                
                $html += @"
                <p><strong>Durée:</strong> $($step.Duration) secondes</p>
            </div>
"@
            }
            
            $html += @"
        </div>
"@
        }
        
        # Fermer le HTML
        $html += @"
        
        <script>
            var coll = document.getElementsByClassName("collapsible");
            var i;
            
            for (i = 0; i < coll.length; i++) {
                coll[i].addEventListener("click", function() {
                    this.classList.toggle("active");
                    var content = this.nextElementSibling;
                    if (content.style.display === "block") {
                        content.style.display = "none";
                    } else {
                        content.style.display = "block";
                    }
                });
            }
        </script>
    </div>
</body>
</html>
"@
        
        # Écrire le HTML dans le fichier
        Set-Content -Path $HtmlReportFile -Value $html -Encoding UTF8
        
        Write-Log "Rapport HTML généré: $HtmlReportFile" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la génération du rapport HTML: $_" -Level "ERROR"
        return $false
    }
}

#endregion

#region Fonction principale

# Fonction principale
function Main {
    # Vérifier si le dossier de log existe
    $logFolder = Split-Path -Path $LogFile -Parent
    Ensure-FolderExists -FolderPath $logFolder | Out-Null
    
    # Afficher les informations de démarrage
    Write-Log "=== Tests d'intégration n8n ===" -Level "INFO"
    Write-Log "Fichier de scénarios: $ScenariosFile" -Level "INFO"
    Write-Log "Filtre de scénario: $($ScenarioFilter ? $ScenarioFilter : "Aucun")" -Level "INFO"
    Write-Log "Filtre de priorité: $($PriorityFilter ? $PriorityFilter : "Aucun")" -Level "INFO"
    
    # Charger les scénarios de test
    $scenarios = Load-TestScenarios -ScenariosFile $ScenariosFile -ScenarioFilter $ScenarioFilter -PriorityFilter $PriorityFilter
    
    if ($scenarios.Count -eq 0) {
        Write-Log "Aucun scénario de test trouvé." -Level "WARNING"
        return
    }
    
    Write-Log "Nombre de scénarios: $($scenarios.Count)" -Level "INFO"
    
    # Exécuter les scénarios de test
    $results = @()
    
    foreach ($scenario in $scenarios) {
        $result = Execute-TestScenario -Scenario $scenario
        $results += $result
    }
    
    # Générer les rapports
    Generate-JsonReport -Results $results -ReportFile $ReportFile
    Generate-HtmlReport -Results $results -HtmlReportFile $HtmlReportFile
    
    # Calculer les statistiques
    $totalScenarios = $results.Count
    $successfulScenarios = ($results | Where-Object { $_.Success }).Count
    $failedScenarios = ($results | Where-Object { -not $_.Success }).Count
    $successRate = if ($totalScenarios -gt 0) { [Math]::Round(($successfulScenarios / $totalScenarios) * 100, 2) } else { 0 }
    
    # Afficher le résumé
    Write-Log "`n=== Résumé des tests d'intégration ===" -Level "INFO"
    Write-Log "Scénarios testés: $totalScenarios" -Level "INFO"
    Write-Log "Scénarios réussis: $successfulScenarios" -Level "SUCCESS"
    Write-Log "Scénarios échoués: $failedScenarios" -Level $(if ($failedScenarios -gt 0) { "ERROR" } else { "INFO" })
    Write-Log "Taux de réussite: $successRate%" -Level $(if ($successRate -ge 90) { "SUCCESS" } elseif ($successRate -ge 70) { "WARNING" } else { "ERROR" })
    
    # Envoyer une notification si nécessaire
    if ($NotificationEnabled) {
        $subject = "Tests d'intégration n8n: $successRate% de réussite"
        $message = "Résultats des tests d'intégration n8n:`n`n"
        $message += "Scénarios testés: $totalScenarios`n"
        $message += "Scénarios réussis: $successfulScenarios`n"
        $message += "Scénarios échoués: $failedScenarios`n"
        $message += "Taux de réussite: $successRate%`n`n"
        
        if ($failedScenarios -gt 0) {
            $message += "Scénarios échoués:`n"
            
            foreach ($result in $results | Where-Object { -not $_.Success }) {
                $message += "- $($result.Name)`n"
            }
        }
        
        $level = if ($successRate -ge 90) { "INFO" } elseif ($successRate -ge 70) { "WARNING" } else { "ERROR" }
        Send-TestNotification -Subject $subject -Message $message -Level $level
    }
    
    # Retourner les résultats
    return @{
        TotalScenarios = $totalScenarios
        SuccessfulScenarios = $successfulScenarios
        FailedScenarios = $failedScenarios
        SuccessRate = $successRate
        Results = $results
    }
}

#endregion

# Exécuter la fonction principale
Main
