<#
.SYNOPSIS
    Script de calcul des indicateurs clés de performance (KPIs) métier - Partie 3.
.DESCRIPTION
    Calcule les KPIs métier à partir des données collectées.
    Cette partie contient les fonctions d'exportation et de génération de tableaux de bord.
#>

# Fonction pour exporter les résultats
function Export-KpiResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Format = "CSV" # CSV, JSON
    )
    
    Write-Log -Message "Exportation des résultats au format $Format vers $OutputPath" -Level "Info"
    
    try {
        # Vérifier si les résultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun résultat à exporter" -Level "Warning"
            return $false
        }
        
        # Créer le répertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les résultats selon le format spécifié
        switch ($Format) {
            "CSV" {
                $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
            "JSON" {
                $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            default {
                Write-Log -Message "Format d'exportation non pris en charge: $Format" -Level "Error"
                return $false
            }
        }
        
        Write-Log -Message "Exportation réussie vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des résultats: $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer un tableau de bord JSON
function Export-KpiDashboard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "Génération du tableau de bord vers $OutputPath" -Level "Info"
    
    try {
        # Vérifier si les résultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun résultat pour générer le tableau de bord" -Level "Warning"
            return $false
        }
        
        # Créer le répertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Créer la structure du tableau de bord
        $Dashboard = @{
            title = "Tableau de bord des KPIs métier"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            panels = @()
        }
        
        # Regrouper les KPIs par catégorie
        $GroupedResults = $Results | Group-Object -Property Category
        
        # Ajouter une section pour chaque catégorie
        foreach ($Group in $GroupedResults) {
            $CategoryPanels = @()
            
            # Ajouter un panneau pour chaque KPI dans cette catégorie
            foreach ($Kpi in $Group.Group) {
                $Panel = @{
                    id = $Kpi.Id
                    title = $Kpi.Name
                    description = $Kpi.Description
                    type = "gauge"
                    value = $Kpi.Value
                    unit = $Kpi.Unit
                    status = $Kpi.Status
                    thresholds = @{
                        warning = 70
                        critical = 90
                    }
                }
                
                $CategoryPanels += $Panel
            }
            
            # Ajouter la section au tableau de bord
            $Dashboard.panels += @{
                title = $Group.Name
                type = "section"
                panels = $CategoryPanels
            }
        }
        
        # Exporter le tableau de bord au format JSON
        $Dashboard | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Tableau de bord généré avec succès: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la génération du tableau de bord: $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer un rapport PDF
function Export-KpiReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$ReportTitle = "Rapport des KPIs métier",
        
        [Parameter(Mandatory=$false)]
        [string]$Period = "Dernier mois"
    )
    
    Write-Log -Message "Génération du rapport vers $OutputPath" -Level "Info"
    
    try {
        # Vérifier si les résultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun résultat pour générer le rapport" -Level "Warning"
            return $false
        }
        
        # Créer le répertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Créer le contenu du rapport au format HTML
        $HtmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>$ReportTitle</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        h2 { color: #3498db; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .normal { color: green; }
        .warning { color: orange; }
        .critical { color: red; }
        .summary { margin-top: 30px; padding: 15px; background-color: #f8f9fa; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>$ReportTitle</h1>
    <p>Période: $Period</p>
    <p>Date de génération: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de KPIs: $($Results.Count)</p>
        <p>KPIs critiques: $($Results | Where-Object { $_.Status -eq "Critical" } | Measure-Object).Count</p>
        <p>KPIs en avertissement: $($Results | Where-Object { $_.Status -eq "Warning" } | Measure-Object).Count</p>
        <p>KPIs normaux: $($Results | Where-Object { $_.Status -eq "Normal" } | Measure-Object).Count</p>
    </div>
"@
        
        # Regrouper les KPIs par catégorie
        $GroupedResults = $Results | Group-Object -Property Category
        
        # Ajouter une section pour chaque catégorie
        foreach ($Group in $GroupedResults) {
            $HtmlContent += @"
    <h2>$($Group.Name)</h2>
    <table>
        <tr>
            <th>KPI</th>
            <th>Description</th>
            <th>Valeur</th>
            <th>Unité</th>
            <th>Statut</th>
        </tr>
"@
            
            foreach ($Kpi in $Group.Group) {
                $StatusClass = switch ($Kpi.Status) {
                    "Normal" { "normal" }
                    "Warning" { "warning" }
                    "Critical" { "critical" }
                    default { "" }
                }
                
                $HtmlContent += @"
        <tr>
            <td>$($Kpi.Name)</td>
            <td>$($Kpi.Description)</td>
            <td>$([Math]::Round($Kpi.Value, 2))</td>
            <td>$($Kpi.Unit)</td>
            <td class="$StatusClass">$($Kpi.Status)</td>
        </tr>
"@
            }
            
            $HtmlContent += @"
    </table>
"@
        }
        
        $HtmlContent += @"
</body>
</html>
"@
        
        # Sauvegarder le rapport au format HTML
        $HtmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Rapport généré avec succès: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la génération du rapport: $_" -Level "Error"
        return $false
    }
}
