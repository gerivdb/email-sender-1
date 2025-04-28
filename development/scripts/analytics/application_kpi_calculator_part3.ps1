<#
.SYNOPSIS
    Script de calcul des indicateurs clÃ©s de performance (KPIs) applicatifs - Partie 3.
.DESCRIPTION
    Calcule les KPIs applicatifs Ã  partir des donnÃ©es de performance collectÃ©es.
    Cette partie contient les fonctions d'exportation et de gÃ©nÃ©ration de tableaux de bord.
#>

# Fonction pour exporter les rÃ©sultats
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
    
    Write-Log -Message "Exportation des rÃ©sultats au format $Format vers $OutputPath" -Level "Info"
    
    try {
        # VÃ©rifier si les rÃ©sultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun rÃ©sultat Ã  exporter" -Level "Warning"
            return $false
        }
        
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les rÃ©sultats selon le format spÃ©cifiÃ©
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
        
        Write-Log -Message "Exportation rÃ©ussie vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des rÃ©sultats: $_" -Level "Error"
        return $false
    }
}

# Fonction pour gÃ©nÃ©rer un tableau de bord JSON
function Export-KpiDashboard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "GÃ©nÃ©ration du tableau de bord vers $OutputPath" -Level "Info"
    
    try {
        # VÃ©rifier si les rÃ©sultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun rÃ©sultat pour gÃ©nÃ©rer le tableau de bord" -Level "Warning"
            return $false
        }
        
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er la structure du tableau de bord
        $Dashboard = @{
            title = "Tableau de bord des KPIs applicatifs"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            panels = @()
        }
        
        # Regrouper les KPIs par catÃ©gorie
        $GroupedResults = $Results | Group-Object -Property Category
        
        # Ajouter une section pour chaque catÃ©gorie
        foreach ($Group in $GroupedResults) {
            $CategoryPanels = @()
            
            # Ajouter un panneau pour chaque KPI dans cette catÃ©gorie
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
        
        Write-Log -Message "Tableau de bord gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration du tableau de bord: $_" -Level "Error"
        return $false
    }
}
