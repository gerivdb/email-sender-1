<#
.SYNOPSIS
    Journalise un point d'arrÃªt.

.DESCRIPTION
    La fonction Write-RoadmapBreakpointLog journalise un point d'arrÃªt dans le systÃ¨me
    de journalisation du module RoadmapParser. Elle utilise Write-RoadmapLog en arriÃ¨re-plan.

.PARAMETER Breakpoint
    L'objet reprÃ©sentant le point d'arrÃªt Ã  journaliser.

.PARAMETER AdditionalInfo
    Informations supplÃ©mentaires Ã  inclure dans le message de journal.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut : $false.

.EXAMPLE
    $breakpoint = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Message = "Point d'arrÃªt atteint"
        Category = "Breakpoint"
        LogLevel = "Debug"
        HitCount = 1
    }
    Write-RoadmapBreakpointLog -Breakpoint $breakpoint
    Journalise le point d'arrÃªt spÃ©cifiÃ©.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>
function Write-RoadmapBreakpointLog {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Breakpoint,

        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalInfo,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # DÃ©finir une fonction Write-RoadmapLog locale si elle n'est pas dÃ©jÃ  disponible
    if (-not (Get-Command -Name Write-RoadmapLog -ErrorAction SilentlyContinue)) {
        function Write-RoadmapLog {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Message,

                [Parameter(Mandatory = $false)]
                [string]$Level = "Information",

                [Parameter(Mandatory = $false)]
                [string]$Category = "General",

                [Parameter(Mandatory = $false)]
                [hashtable]$AdditionalInfo,

                [Parameter(Mandatory = $false)]
                [switch]$PassThru
            )

            $logMessage = "[$Level] [$Category] $Message"
            Write-Verbose $logMessage

            if ($PassThru) {
                return $logMessage
            }
        }
    }

    # Construire le message de journal
    $message = $Breakpoint.Message
    if ($Breakpoint.HitCount -gt 1) {
        $message += " (DÃ©clenchement #$($Breakpoint.HitCount))"
    }

    # Construire les informations supplÃ©mentaires
    $logAdditionalInfo = @{
        "BreakpointId" = $Breakpoint.Id
        "Condition"    = $Breakpoint.Condition
        "Action"       = $Breakpoint.Action
        "HitCount"     = $Breakpoint.HitCount
        "LastHitTime"  = $Breakpoint.LastHitTime
    }

    # Ajouter les informations supplÃ©mentaires fournies
    if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
        foreach ($key in $AdditionalInfo.Keys) {
            $logAdditionalInfo[$key] = $AdditionalInfo[$key]
        }
    }

    # Journaliser le point d'arrÃªt
    $result = Write-RoadmapLog -Message $message -Level $Breakpoint.LogLevel -Category $Breakpoint.Category -AdditionalInfo $logAdditionalInfo -PassThru:$PassThru

    # Retourner le rÃ©sultat si PassThru est spÃ©cifiÃ©
    if ($PassThru) {
        return $result
    }
}
