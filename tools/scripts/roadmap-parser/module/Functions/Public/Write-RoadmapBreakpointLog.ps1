<#
.SYNOPSIS
    Journalise un point d'arrêt.

.DESCRIPTION
    La fonction Write-RoadmapBreakpointLog journalise un point d'arrêt dans le système
    de journalisation du module RoadmapParser. Elle utilise Write-RoadmapLog en arrière-plan.

.PARAMETER Breakpoint
    L'objet représentant le point d'arrêt à journaliser.

.PARAMETER AdditionalInfo
    Informations supplémentaires à inclure dans le message de journal.

.PARAMETER PassThru
    Indique si le message doit être retourné après avoir été écrit dans le journal.
    Par défaut : $false.

.EXAMPLE
    $breakpoint = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Message = "Point d'arrêt atteint"
        Category = "Breakpoint"
        LogLevel = "Debug"
        HitCount = 1
    }
    Write-RoadmapBreakpointLog -Breakpoint $breakpoint
    Journalise le point d'arrêt spécifié.

.OUTPUTS
    [string] Le message formaté si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
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

    # Définir une fonction Write-RoadmapLog locale si elle n'est pas déjà disponible
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
        $message += " (Déclenchement #$($Breakpoint.HitCount))"
    }

    # Construire les informations supplémentaires
    $logAdditionalInfo = @{
        "BreakpointId" = $Breakpoint.Id
        "Condition"    = $Breakpoint.Condition
        "Action"       = $Breakpoint.Action
        "HitCount"     = $Breakpoint.HitCount
        "LastHitTime"  = $Breakpoint.LastHitTime
    }

    # Ajouter les informations supplémentaires fournies
    if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
        foreach ($key in $AdditionalInfo.Keys) {
            $logAdditionalInfo[$key] = $AdditionalInfo[$key]
        }
    }

    # Journaliser le point d'arrêt
    $result = Write-RoadmapLog -Message $message -Level $Breakpoint.LogLevel -Category $Breakpoint.Category -AdditionalInfo $logAdditionalInfo -PassThru:$PassThru

    # Retourner le résultat si PassThru est spécifié
    if ($PassThru) {
        return $result
    }
}
