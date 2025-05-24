<#
.SYNOPSIS
    Script de surveillance du port et de l'API n8n (Partie 3 : Fonctions de rapport et d'historique).

.DESCRIPTION
    Ce script contient les fonctions de rapport et d'historique pour la surveillance du port et de l'API n8n.
    Il est conçu pour être utilisé avec les autres parties du script de surveillance.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables des parties précédentes
. "$PSScriptRoot\check-n8n-status-part1.ps1"
. "$PSScriptRoot\check-n8n-status-part2.ps1"

# Fonction pour sauvegarder les résultats dans un fichier JSON
function Save-ResultsToJson {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    try {
        # Créer le dossier parent s'il n'existe pas
        $parentFolder = Split-Path -Path $FilePath -Parent
        Ensure-FolderExists -FolderPath $parentFolder | Out-Null
        
        # Convertir les résultats en JSON et les enregistrer
        $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8
        
        Write-Log "Résultats enregistrés dans le fichier: $FilePath" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'enregistrement des résultats dans le fichier $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour générer un rapport HTML
function New-HtmlReport {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$false)]
        [array]$History = @()
    )
    
    try {
        # Créer le dossier parent s'il n'existe pas
        $parentFolder = Split-Path -Path $FilePath -Parent
        Ensure-FolderExists -FolderPath $parentFolder | Out-Null
        
        # Déterminer le statut global
        $statusClass = if ($Results.OverallSuccess) { "success" } else { "error" }
        $statusText = if ($Results.OverallSuccess) { "Opérationnel" } else { "Non opérationnel" }
        
        # Générer le contenu HTML
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de statut n8n</title>
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
        .status-card {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
            border-left: 5px solid #ccc;
        }
        .status-card.success {
            border-left-color: #28a745;
        }
        .status-card.error {
            border-left-color: #dc3545;
        }
        .status-card.warning {
            border-left-color: #ffc107;
        }
        .status-text {
            font-size: 24px;
            font-weight: bold;
        }
        .status-text.success {
            color: #28a745;
        }
        .status-text.error {
            color: #dc3545;
        }
        .status-text.warning {
            color: #ffc107;
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
            color: #28a745;
        }
        .error {
            color: #dc3545;
        }
        .warning {
            color: #ffc107;
        }
        .chart-container {
            margin-top: 30px;
            margin-bottom: 30px;
        }
        .endpoint-details {
            margin-top: 10px;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de statut n8n</h1>
        <p>Date du test: $($Results.StartTime.ToString("yyyy-MM-dd HH:mm:ss"))</p>
        
        <div class="status-card $statusClass">
            <h2>Statut actuel</h2>
            <p class="status-text $statusClass">$statusText</p>
            <p>Temps total du test: $($Results.TotalTime) ms</p>
        </div>
        
        <h2>Test du port</h2>
        <table>
            <tr>
                <th>Statut</th>
                <th>Temps de réponse</th>
                <th>Tentatives</th>
                <th>Erreur</th>
            </tr>
            <tr>
                <td class="$($Results.PortTest.Success ? "success" : "error")">$($Results.PortTest.Success ? "Succès" : "Échec")</td>
                <td>$($Results.PortTest.ResponseTime) ms</td>
                <td>$($Results.PortTest.Attempts)</td>
                <td>$($Results.PortTest.Error)</td>
            </tr>
        </table>
        
        <h2>Tests des endpoints</h2>
        <table>
            <tr>
                <th>Endpoint</th>
                <th>Statut</th>
                <th>Code HTTP</th>
                <th>Temps de réponse</th>
                <th>Tentatives</th>
            </tr>
"@
        
        # Ajouter les résultats des endpoints
        foreach ($endpoint in $Results.EndpointTests.Keys) {
            $endpointResult = $Results.EndpointTests[$endpoint]
            $statusClass = if ($endpointResult.Success) { "success" } else { "error" }
            $statusText = if ($endpointResult.Success) { "Succès" } else { "Échec" }
            
            $html += @"
            <tr>
                <td>$endpoint</td>
                <td class="$statusClass">$statusText</td>
                <td>$($endpointResult.StatusCode)</td>
                <td>$($endpointResult.ResponseTime) ms</td>
                <td>$($endpointResult.Attempts)</td>
            </tr>
"@
        }
        
        $html += @"
        </table>
"@
        
        # Ajouter les détails des endpoints si disponibles
        foreach ($endpoint in $Results.EndpointTests.Keys) {
            $endpointResult = $Results.EndpointTests[$endpoint]
            
            if (-not [string]::IsNullOrEmpty($endpointResult.Response)) {
                $html += @"
        <div class="endpoint-details">
            <h3>Détails de l'endpoint: $endpoint</h3>
            <pre>$($endpointResult.Response)</pre>
        </div>
"@
            }
        }
        
        # Ajouter l'historique si disponible
        if ($History.Count -gt 0) {
            $html += @"
        <h2>Historique des tests</h2>
        <div class="chart-container">
            <table>
                <tr>
                    <th>Date</th>
                    <th>Statut</th>
                    <th>Temps de réponse (port)</th>
                    <th>Temps total</th>
                </tr>
"@
            
            foreach ($historyItem in $History) {
                $statusClass = if ($historyItem.OverallSuccess) { "success" } else { "error" }
                $statusText = if ($historyItem.OverallSuccess) { "Opérationnel" } else { "Non opérationnel" }
                
                $html += @"
                <tr>
                    <td>$($historyItem.StartTime.ToString("yyyy-MM-dd HH:mm:ss"))</td>
                    <td class="$statusClass">$statusText</td>
                    <td>$($historyItem.PortTest.ResponseTime) ms</td>
                    <td>$($historyItem.TotalTime) ms</td>
                </tr>
"@
            }
            
            $html += @"
            </table>
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
        Set-Content -Path $FilePath -Value $html -Encoding UTF8
        
        Write-Log "Rapport HTML généré: $FilePath" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la génération du rapport HTML: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour sauvegarder les résultats dans l'historique
function Save-ResultsToHistory {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$HistoryFolder,
        
        [Parameter(Mandatory=$false)]
        [int]$HistoryLength = 10
    )
    
    try {
        # Créer le dossier d'historique s'il n'existe pas
        Ensure-FolderExists -FolderPath $HistoryFolder | Out-Null
        
        # Générer un nom de fichier unique pour l'historique
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $historyFileName = "n8n-status-$timestamp.json"
        $historyFilePath = Join-Path -Path $HistoryFolder -ChildPath $historyFileName
        
        # Sauvegarder les résultats dans le fichier d'historique
        $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $historyFilePath -Encoding UTF8
        
        Write-Log "Résultats sauvegardés dans l'historique: $historyFilePath" -Level "INFO"
        
        # Nettoyer les anciens fichiers d'historique si nécessaire
        $historyFiles = Get-ChildItem -Path $HistoryFolder -Filter "n8n-status-*.json" | Sort-Object LastWriteTime -Descending
        
        if ($historyFiles.Count -gt $HistoryLength) {
            $filesToRemove = $historyFiles | Select-Object -Skip $HistoryLength
            
            foreach ($file in $filesToRemove) {
                Remove-Item -Path $file.FullName -Force
                Write-Log "Ancien fichier d'historique supprimé: $($file.Name)" -Level "INFO"
            }
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde des résultats dans l'historique: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour charger l'historique des résultats
function Get-ResultsHistory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoryFolder,
        
        [Parameter(Mandatory=$false)]
        [int]$HistoryLength = 10
    )
    
    try {
        # Vérifier si le dossier d'historique existe
        if (-not (Test-Path -Path $HistoryFolder)) {
            Write-Log "Dossier d'historique non trouvé: $HistoryFolder" -Level "WARNING"
            return @()
        }
        
        # Obtenir les fichiers d'historique
        $historyFiles = Get-ChildItem -Path $HistoryFolder -Filter "n8n-status-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First $HistoryLength
        
        if ($historyFiles.Count -eq 0) {
            Write-Log "Aucun fichier d'historique trouvé dans le dossier: $HistoryFolder" -Level "INFO"
            return @()
        }
        
        # Charger les résultats de chaque fichier
        $history = @()
        
        foreach ($file in $historyFiles) {
            try {
                $historyItem = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $history += $historyItem
            } catch {
                Write-Log "Erreur lors du chargement du fichier d'historique $($file.Name): $_" -Level "WARNING"
            }
        }
        
        return $history
    } catch {
        Write-Log "Erreur lors du chargement de l'historique des résultats: $_" -Level "ERROR"
        return @()
    }
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Save-ResultsToJson, New-HtmlReport, Save-ResultsToHistory, Get-ResultsHistory

