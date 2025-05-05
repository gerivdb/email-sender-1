<#
.SYNOPSIS
    Script de calcul des indicateurs clÃƒÂ©s de performance (KPIs) applicatifs.
.DESCRIPTION
    Calcule les KPIs applicatifs ÃƒÂ  partir des donnÃƒÂ©es de performance collectÃƒÂ©es.
.PARAMETER DataPath
    Chemin vers les donnÃƒÂ©es de performance.
.PARAMETER OutputPath
    Chemin oÃƒÂ¹ les rÃƒÂ©sultats seront sauvegardÃƒÂ©s.
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
    [string]$ConfigPath = "projet/config/kpis/application_kpis.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# DÃƒÂ©finir la variable de niveau de log au niveau du script
$script:LogLevel = $LogLevel

# Importer les diffÃƒÂ©rentes parties du script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptPath\application_kpi_calculator_part1.ps1"
. "$ScriptPath\application_kpi_calculator_part2.ps1"
. "$ScriptPath\application_kpi_calculator_part3.ps1"
. "$ScriptPath\application_kpi_calculator_part4.ps1"

# ExÃƒÂ©cution du script
$Result = Start-ApplicationKpiCalculation -DataPath $DataPath -OutputPath $OutputPath -ConfigPath $ConfigPath

if ($Result.Success) {
    Write-Log -Message "Calcul des KPIs applicatifs rÃƒÂ©ussi" -Level "Info"
    return 0
} else {
    Write-Log -Message "Ãƒâ€°chec du calcul des KPIs applicatifs" -Level "Error"
    return 1
}
