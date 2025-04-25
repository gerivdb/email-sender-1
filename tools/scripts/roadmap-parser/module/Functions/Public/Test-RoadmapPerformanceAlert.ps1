<#
.SYNOPSIS
    Teste les alertes de performance en simulant des dépassements de seuil.

.DESCRIPTION
    La fonction Test-RoadmapPerformanceAlert permet de tester les alertes de performance
    configurées avec Set-RoadmapPerformanceAlert en simulant des dépassements de seuil.
    Elle peut tester une alerte spécifique ou toutes les alertes configurées.

.PARAMETER Type
    Le type de mesure de performance. Les valeurs possibles sont : ExecutionTime, MemoryUsage, Operations.
    Si non spécifié, toutes les alertes sont testées.

.PARAMETER Name
    Le nom de la mesure de performance pour laquelle tester les alertes.
    Si non spécifié, toutes les alertes du type spécifié sont testées.

.PARAMETER SimulatedValue
    La valeur simulée à utiliser pour le test. Si non spécifiée, une valeur supérieure au seuil est générée automatiquement.

.PARAMETER ExecuteActions
    Indique si les actions configurées doivent être exécutées lors du test.
    Par défaut : $false.

.EXAMPLE
    Test-RoadmapPerformanceAlert
    Teste toutes les alertes de performance configurées.

.EXAMPLE
    Test-RoadmapPerformanceAlert -Type ExecutionTime -Name "ParseRoadmap"
    Teste l'alerte de performance pour la mesure de temps d'exécution "ParseRoadmap".

.EXAMPLE
    Test-RoadmapPerformanceAlert -Type MemoryUsage -Name "LoadRoadmap" -SimulatedValue 2GB -ExecuteActions $true
    Teste l'alerte de performance pour la mesure d'utilisation de mémoire "LoadRoadmap" avec une valeur simulée de 2 Go et exécute les actions configurées.

.OUTPUTS
    [PSCustomObject[]] Retourne un tableau d'objets représentant les résultats des tests d'alerte.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-24
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

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Obtenir les alertes à tester
    $alertsToTest = Get-RoadmapPerformanceAlert -Type $Type -Name $Name -IncludeDisabled $false

    if (-not $alertsToTest -or $alertsToTest.Count -eq 0) {
        Write-Log -Message "Aucune alerte trouvée à tester." -Level "Warning" -Source "PerformanceAlert"
        return @()
    }

    $testResults = @()

    # Tester chaque alerte
    foreach ($alert in $alertsToTest) {
        # Générer une valeur simulée si non spécifiée
        $valueToTest = if ($SimulatedValue) { $SimulatedValue } else { $alert.Threshold * 1.5 }

        # Créer l'objet d'alerte
        $alertObject = [PSCustomObject]@{
            Type = $alert.Type
            Name = $alert.Name
            Threshold = $alert.Threshold
            CurrentValue = $valueToTest
            Timestamp = Get-Date
            Triggered = $valueToTest -gt $alert.Threshold
        }

        # Journaliser le test
        $logMessage = "Test d'alerte pour $($alert.Type) '$($alert.Name)' : Valeur=$valueToTest, Seuil=$($alert.Threshold), Déclenché=$($alertObject.Triggered)"
        Write-Log -Message $logMessage -Level "Info" -Source "PerformanceAlert"

        # Exécuter l'action si configurée et demandée
        if ($alertObject.Triggered -and $ExecuteActions -and $alert.Action) {
            try {
                Write-Log -Message "Exécution de l'action pour l'alerte $($alert.Type) '$($alert.Name)'." -Level "Info" -Source "PerformanceAlert"
                & $alert.Action $alertObject
            } catch {
                Write-Log -Message "Erreur lors de l'exécution de l'action pour l'alerte $($alert.Type) '$($alert.Name)' : $_" -Level "Error" -Source "PerformanceAlert"
            }
        }

        # Ajouter le résultat du test
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
