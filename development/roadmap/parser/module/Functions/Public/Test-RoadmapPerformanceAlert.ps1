<#
.SYNOPSIS
    Teste les alertes de performance en simulant des dÃ©passements de seuil.

.DESCRIPTION
    La fonction Test-RoadmapPerformanceAlert permet de tester les alertes de performance
    configurÃ©es avec Set-RoadmapPerformanceAlert en simulant des dÃ©passements de seuil.
    Elle peut tester une alerte spÃ©cifique ou toutes les alertes configurÃ©es.

.PARAMETER Type
    Le type de mesure de performance. Les valeurs possibles sont : ExecutionTime, MemoryUsage, Operations.
    Si non spÃ©cifiÃ©, toutes les alertes sont testÃ©es.

.PARAMETER Name
    Le nom de la mesure de performance pour laquelle tester les alertes.
    Si non spÃ©cifiÃ©, toutes les alertes du type spÃ©cifiÃ© sont testÃ©es.

.PARAMETER SimulatedValue
    La valeur simulÃ©e Ã  utiliser pour le test. Si non spÃ©cifiÃ©e, une valeur supÃ©rieure au seuil est gÃ©nÃ©rÃ©e automatiquement.

.PARAMETER ExecuteActions
    Indique si les actions configurÃ©es doivent Ãªtre exÃ©cutÃ©es lors du test.
    Par dÃ©faut : $false.

.EXAMPLE
    Test-RoadmapPerformanceAlert
    Teste toutes les alertes de performance configurÃ©es.

.EXAMPLE
    Test-RoadmapPerformanceAlert -Type ExecutionTime -Name "ParseRoadmap"
    Teste l'alerte de performance pour la mesure de temps d'exÃ©cution "ParseRoadmap".

.EXAMPLE
    Test-RoadmapPerformanceAlert -Type MemoryUsage -Name "LoadRoadmap" -SimulatedValue 2GB -ExecuteActions $true
    Teste l'alerte de performance pour la mesure d'utilisation de mÃ©moire "LoadRoadmap" avec une valeur simulÃ©e de 2 Go et exÃ©cute les actions configurÃ©es.

.OUTPUTS
    [PSCustomObject[]] Retourne un tableau d'objets reprÃ©sentant les rÃ©sultats des tests d'alerte.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-24
#>
function Test-RoadmapPerformanceAlert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("ExecutionTime", "MemoryUsage", "Operations")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [long]$SimulatedValue,

        [Parameter(Mandatory = $false)]
        [bool]$ExecuteActions = $false
    )

    # Importer les fonctions de mesure de performance
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance"
    $performanceFunctionsPath = Join-Path -Path $privatePath -ChildPath "PerformanceMeasurementFunctions.ps1"

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Obtenir les alertes Ã  tester
    $alertsToTest = Get-RoadmapPerformanceAlert -Type $Type -Name $Name -IncludeDisabled $false

    if (-not $alertsToTest -or $alertsToTest.Count -eq 0) {
        Write-Log -Message "Aucune alerte trouvÃ©e Ã  tester." -Level "Warning" -Source "PerformanceAlert"
        return @()
    }

    $testResults = @()

    # Tester chaque alerte
    foreach ($alert in $alertsToTest) {
        # GÃ©nÃ©rer une valeur simulÃ©e si non spÃ©cifiÃ©e
        $valueToTest = if ($SimulatedValue) { $SimulatedValue } else { $alert.Threshold * 1.5 }

        # CrÃ©er l'objet d'alerte
        $alertObject = [PSCustomObject]@{
            Type = $alert.Type
            Name = $alert.Name
            Threshold = $alert.Threshold
            CurrentValue = $valueToTest
            Timestamp = Get-Date
            Triggered = $valueToTest -gt $alert.Threshold
        }

        # Journaliser le test
        $logMessage = "Test d'alerte pour $($alert.Type) '$($alert.Name)' : Valeur=$valueToTest, Seuil=$($alert.Threshold), DÃ©clenchÃ©=$($alertObject.Triggered)"
        Write-Log -Message $logMessage -Level "Info" -Source "PerformanceAlert"

        # ExÃ©cuter l'action si configurÃ©e et demandÃ©e
        if ($alertObject.Triggered -and $ExecuteActions -and $alert.Action) {
            try {
                Write-Log -Message "ExÃ©cution de l'action pour l'alerte $($alert.Type) '$($alert.Name)'." -Level "Info" -Source "PerformanceAlert"
                & $alert.Action $alertObject
            } catch {
                Write-Log -Message "Erreur lors de l'exÃ©cution de l'action pour l'alerte $($alert.Type) '$($alert.Name)' : $_" -Level "Error" -Source "PerformanceAlert"
            }
        }

        # Ajouter le rÃ©sultat du test
        $testResults += [PSCustomObject]@{
            Type = $alert.Type
            Name = $alert.Name
            Threshold = $alert.Threshold
            TestedValue = $valueToTest
            Triggered = $alertObject.Triggered
            ActionExecuted = $alertObject.Triggered -and $ExecuteActions -and $alert.Action -ne $null
            Timestamp = Get-Date
        }
    }

    return $testResults
}

# Exporter la fonction
# Export-ModuleMember -Function Test-RoadmapPerformanceAlert
