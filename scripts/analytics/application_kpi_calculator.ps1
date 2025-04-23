<#
.SYNOPSIS
    Script de calcul des indicateurs clés de performance (KPIs) applicatifs.
.DESCRIPTION
    Calcule les KPIs applicatifs à partir des données de performance collectées.
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
    [string]$ConfigPath = "config/kpis/application_kpis.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# Définir la variable de niveau de log au niveau du script
$script:LogLevel = $LogLevel

# Importer les différentes parties du script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptPath\application_kpi_calculator_part1.ps1"
. "$ScriptPath\application_kpi_calculator_part2.ps1"
. "$ScriptPath\application_kpi_calculator_part3.ps1"
. "$ScriptPath\application_kpi_calculator_part4.ps1"

# Exécution du script
$Result = Start-ApplicationKpiCalculation -DataPath $DataPath -OutputPath $OutputPath -ConfigPath $ConfigPath

if ($Result.Success) {
    Write-Log -Message "Calcul des KPIs applicatifs réussi" -Level "Info"
    return 0
} else {
    Write-Log -Message "Échec du calcul des KPIs applicatifs" -Level "Error"
    return 1
}
