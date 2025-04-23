<#
.SYNOPSIS
    Script de calcul des indicateurs clés de performance (KPIs) applicatifs - Partie 3.
.DESCRIPTION
    Calcule les KPIs applicatifs à partir des données de performance collectées.
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
            title = "Tableau de bord des KPIs applicatifs"
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
