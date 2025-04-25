<#
.SYNOPSIS
    Script de test structurel pour n8n (Partie 3 : Fonctions de rapport).

.DESCRIPTION
    Ce script contient les fonctions de rapport pour le test structurel de n8n.
    Il est conçu pour être utilisé avec les autres parties du script de test structurel.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables des parties précédentes
. "$PSScriptRoot\test-structure-part1.ps1"
. "$PSScriptRoot\test-structure-part2.ps1"

# Fonction pour générer un rapport JSON
function Export-TestResultsToJson {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile
    )
    
    try {
        # Créer le dossier parent s'il n'existe pas
        $parentFolder = Split-Path -Path $OutputFile -Parent
        if (-not (Test-Path -Path $parentFolder)) {
            New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
        }
        
        # Convertir les résultats en JSON
        $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8
        
        Write-Log "Rapport JSON généré: $OutputFile" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la génération du rapport JSON: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour générer un rapport HTML
function Export-TestResultsToHtml {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile
    )
    
    try {
        # Créer le dossier parent s'il n'existe pas
        $parentFolder = Split-Path -Path $OutputFile -Parent
        if (-not (Test-Path -Path $parentFolder)) {
            New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
        }
        
        # Calculer le taux de réussite
        $totalTested = $Results.Summary.TotalTested
        $totalPassed = $Results.Summary.TotalPassed
        $successRate = if ($totalTested -gt 0) { [Math]::Round(($totalPassed / $totalTested) * 100, 2) } else { 0 }
        
        # Déterminer la couleur en fonction du taux de réussite
        $statusColor = if ($successRate -ge 90) { "green" } elseif ($successRate -ge 70) { "orange" } else { "red" }
        
        # Générer le contenu HTML
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de test structurel n8n</title>
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
        .warning {
            color: orange;
        }
        .error {
            color: red;
        }
        .fixed {
            color: blue;
        }
        .details {
            margin-top: 10px;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de test structurel n8n</h1>
        <p>Date du test: $([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))</p>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p>Éléments testés: $($Results.Summary.TotalTested)</p>
            <p>Éléments réussis: $($Results.Summary.TotalPassed)</p>
            <p>Éléments échoués: $($Results.Summary.TotalFailed)</p>
            <p>Éléments corrigés: $($Results.Summary.TotalFixed)</p>
            <p>Taux de réussite: <span class="status">$successRate%</span></p>
        </div>
        
        <h2>Résultats détaillés</h2>
"@
        
        # Ajouter les résultats des dossiers
        $html += @"
        <h3>Structure des dossiers</h3>
        <table>
            <tr>
                <th>Testés</th>
                <th>Réussis</th>
                <th>Échoués</th>
                <th>Corrigés</th>
            </tr>
            <tr>
                <td>$($Results.FolderStructure.Tested)</td>
                <td class="success">$($Results.FolderStructure.Passed)</td>
                <td class="error">$($Results.FolderStructure.Failed)</td>
                <td class="fixed">$($Results.FolderStructure.Fixed)</td>
            </tr>
        </table>
"@
        
        # Ajouter les problèmes de dossiers
        if ($Results.FolderStructure.Issues.Count -gt 0) {
            $html += @"
        <div class="details">
            <h4>Problèmes détectés</h4>
            <ul>
"@
            
            foreach ($issue in $Results.FolderStructure.Issues) {
                $statusClass = if ($issue.Fixed) { "fixed" } else { "error" }
                $statusText = if ($issue.Fixed) { " (Corrigé)" } else { "" }
                $html += "                <li class=`"$statusClass`">$($issue.Message)$statusText</li>`n"
            }
            
            $html += @"
            </ul>
        </div>
"@
        }
        
        # Ajouter les résultats des fichiers
        $html += @"
        <h3>Structure des fichiers</h3>
        <table>
            <tr>
                <th>Testés</th>
                <th>Réussis</th>
                <th>Échoués</th>
                <th>Corrigés</th>
            </tr>
            <tr>
                <td>$($Results.FileStructure.Tested)</td>
                <td class="success">$($Results.FileStructure.Passed)</td>
                <td class="error">$($Results.FileStructure.Failed)</td>
                <td class="fixed">$($Results.FileStructure.Fixed)</td>
            </tr>
        </table>
"@
        
        # Ajouter les problèmes de fichiers
        if ($Results.FileStructure.Issues.Count -gt 0) {
            $html += @"
        <div class="details">
            <h4>Problèmes détectés</h4>
            <ul>
"@
            
            foreach ($issue in $Results.FileStructure.Issues) {
                $statusClass = if ($issue.Fixed) { "fixed" } else { "error" }
                $statusText = if ($issue.Fixed) { " (Corrigé)" } else { "" }
                $html += "                <li class=`"$statusClass`">$($issue.Message)$statusText</li>`n"
            }
            
            $html += @"
            </ul>
        </div>
"@
        }
        
        # Ajouter les résultats des scripts
        $html += @"
        <h3>Structure des scripts</h3>
        <table>
            <tr>
                <th>Testés</th>
                <th>Réussis</th>
                <th>Échoués</th>
                <th>Corrigés</th>
            </tr>
            <tr>
                <td>$($Results.ScriptStructure.Tested)</td>
                <td class="success">$($Results.ScriptStructure.Passed)</td>
                <td class="error">$($Results.ScriptStructure.Failed)</td>
                <td class="fixed">$($Results.ScriptStructure.Fixed)</td>
            </tr>
        </table>
"@
        
        # Ajouter les problèmes de scripts
        if ($Results.ScriptStructure.Issues.Count -gt 0) {
            $html += @"
        <div class="details">
            <h4>Problèmes détectés</h4>
            <ul>
"@
            
            foreach ($issue in $Results.ScriptStructure.Issues) {
                $statusClass = if ($issue.Fixed) { "fixed" } else { "error" }
                $statusText = if ($issue.Fixed) { " (Corrigé)" } else { "" }
                $html += "                <li class=`"$statusClass`">$($issue.Message)$statusText</li>`n"
            }
            
            $html += @"
            </ul>
        </div>
"@
        }
        
        # Ajouter les résultats des workflows
        $html += @"
        <h3>Structure des workflows</h3>
        <table>
            <tr>
                <th>Testés</th>
                <th>Réussis</th>
                <th>Échoués</th>
                <th>Corrigés</th>
            </tr>
            <tr>
                <td>$($Results.WorkflowStructure.Tested)</td>
                <td class="success">$($Results.WorkflowStructure.Passed)</td>
                <td class="error">$($Results.WorkflowStructure.Failed)</td>
                <td class="fixed">$($Results.WorkflowStructure.Fixed)</td>
            </tr>
        </table>
"@
        
        # Ajouter les problèmes de workflows
        if ($Results.WorkflowStructure.Issues.Count -gt 0) {
            $html += @"
        <div class="details">
            <h4>Problèmes détectés</h4>
            <ul>
"@
            
            foreach ($issue in $Results.WorkflowStructure.Issues) {
                $statusClass = if ($issue.Fixed) { "fixed" } else { "error" }
                $statusText = if ($issue.Fixed) { " (Corrigé)" } else { "" }
                $html += "                <li class=`"$statusClass`">$($issue.Message)$statusText</li>`n"
            }
            
            $html += @"
            </ul>
        </div>
"@
        }
        
        # Ajouter les résultats de la configuration
        $html += @"
        <h3>Structure de configuration</h3>
        <table>
            <tr>
                <th>Testés</th>
                <th>Réussis</th>
                <th>Échoués</th>
                <th>Corrigés</th>
            </tr>
            <tr>
                <td>$($Results.ConfigStructure.Tested)</td>
                <td class="success">$($Results.ConfigStructure.Passed)</td>
                <td class="error">$($Results.ConfigStructure.Failed)</td>
                <td class="fixed">$($Results.ConfigStructure.Fixed)</td>
            </tr>
        </table>
"@
        
        # Ajouter les problèmes de configuration
        if ($Results.ConfigStructure.Issues.Count -gt 0) {
            $html += @"
        <div class="details">
            <h4>Problèmes détectés</h4>
            <ul>
"@
            
            foreach ($issue in $Results.ConfigStructure.Issues) {
                $statusClass = if ($issue.Fixed) { "fixed" } else { "error" }
                $statusText = if ($issue.Fixed) { " (Corrigé)" } else { "" }
                $html += "                <li class=`"$statusClass`">$($issue.Message)$statusText</li>`n"
            }
            
            $html += @"
            </ul>
        </div>
"@
        }
        
        # Fermer le HTML
        $html += @"
    </div>
</body>
</html>
"@
        
        # Écrire le HTML dans le fichier
        Set-Content -Path $OutputFile -Value $html -Encoding UTF8
        
        Write-Log "Rapport HTML généré: $OutputFile" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la génération du rapport HTML: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour envoyer une notification avec les résultats
function Send-TestResultsNotification {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results
    )
    
    # Calculer le taux de réussite
    $totalTested = $Results.Summary.TotalTested
    $totalPassed = $Results.Summary.TotalPassed
    $totalFailed = $Results.Summary.TotalFailed
    $totalFixed = $Results.Summary.TotalFixed
    $successRate = if ($totalTested -gt 0) { [Math]::Round(($totalPassed / $totalTested) * 100, 2) } else { 0 }
    
    # Déterminer le niveau de notification
    $level = if ($successRate -ge 90) { "INFO" } elseif ($successRate -ge 70) { "WARNING" } else { "ERROR" }
    
    # Construire le sujet
    $subject = "Test structurel n8n: $successRate% de réussite"
    
    # Construire le message
    $message = "Résultats du test structurel n8n:`n`n"
    $message += "Éléments testés: $totalTested`n"
    $message += "Éléments réussis: $totalPassed`n"
    $message += "Éléments échoués: $totalFailed`n"
    $message += "Éléments corrigés: $totalFixed`n"
    $message += "Taux de réussite: $successRate%`n`n"
    
    # Ajouter les problèmes non corrigés
    $unfixedIssues = @()
    $unfixedIssues += $Results.FolderStructure.Issues | Where-Object { -not $_.Fixed }
    $unfixedIssues += $Results.FileStructure.Issues | Where-Object { -not $_.Fixed }
    $unfixedIssues += $Results.ScriptStructure.Issues | Where-Object { -not $_.Fixed }
    $unfixedIssues += $Results.WorkflowStructure.Issues | Where-Object { -not $_.Fixed }
    $unfixedIssues += $Results.ConfigStructure.Issues | Where-Object { -not $_.Fixed }
    
    if ($unfixedIssues.Count -gt 0) {
        $message += "Problèmes non corrigés ($($unfixedIssues.Count)):`n"
        
        foreach ($issue in $unfixedIssues) {
            $message += "- $($issue.Message)`n"
        }
    }
    
    # Envoyer la notification
    Send-TestNotification -Subject $subject -Message $message -Level $level
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Export-TestResultsToJson, Export-TestResultsToHtml, Send-TestResultsNotification
