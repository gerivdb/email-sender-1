<#
.SYNOPSIS
    Script de calcul des indicateurs clés de performance (KPIs) métier.
.DESCRIPTION
    Calcule les KPIs métier à partir des données collectées.
.PARAMETER DataPath
    Chemin vers les données de performance.
.PARAMETER OutputPath
    Chemin où les résultats seront sauvegardés.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration des KPIs.
.PARAMETER LogLevel
    Niveau de journalisation (Verbose, Info, Warning, Error).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath = "data/performance",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "data/kpis",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "config/kpis/business_kpis.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# Définir la variable de niveau de log au niveau du script
$script:LogLevel = $LogLevel

# Importer les différentes parties du script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptPath\business_kpi_calculator_part1.ps1"
. "$ScriptPath\business_kpi_calculator_part2.ps1"
. "$ScriptPath\business_kpi_calculator_part3.ps1"
. "$ScriptPath\business_kpi_calculator_part4.ps1"

# Exécution du script
$Result = Start-BusinessKpiCalculation -DataPath $DataPath -OutputPath $OutputPath -ConfigPath $ConfigPath

if ($Result.Success) {
    Write-Log -Message "Calcul des KPIs métier réussi" -Level "Info"
    return 0
} else {
    Write-Log -Message "Échec du calcul des KPIs métier" -Level "Error"
    return 1
}
