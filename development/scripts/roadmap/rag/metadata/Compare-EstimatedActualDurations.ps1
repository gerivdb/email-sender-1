# Compare-EstimatedActualDurations.ps1
# Script pour comparer les durées estimées et réelles des tâches
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$Content,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV", "Text")]
    [string]$OutputFormat = "JSON"
)

# Importer les scripts d'extraction des durées
$scriptPath = $PSScriptRoot
$extractDurationScriptPath = Join-Path -Path $scriptPath -ChildPath "Extract-DurationAttributes.ps1"
$extractActualDurationScriptPath = Join-Path -Path $scriptPath -ChildPath "Extract-ActualDurationValues.ps1"

if (-not (Test-Path -Path $extractDurationScriptPath)) {
    Write-Error "Le script d'extraction des durées n'existe pas: $extractDurationScriptPath"
    return $null
}

if (-not (Test-Path -Path $extractActualDurationScriptPath)) {
    Write-Error "Le script d'extraction des durées réelles n'existe pas: $extractActualDurationScriptPath"
    return $null
}

# Fonction pour convertir les durées en heures
function Convert-DurationToHours {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Unit
    )

    switch -Regex ($Unit) {
        '^jours?$' { return $Value * 8 }  # 8 heures par jour
        '^semaines?$' { return $Value * 40 }  # 40 heures par semaine (5 jours * 8 heures)
        '^mois$' { return $Value * 160 }  # 160 heures par mois (4 semaines * 40 heures)
        '^années?$' { return $Value * 1920 }  # 1920 heures par année (12 mois * 160 heures)
        '^heures?$' { return $Value }
        '^minutes?$' { return $Value / 60 }
        default { return $Value }
    }
}

# Fonction pour extraire les comparaisons entre durées estimées et réelles
function Get-DurationComparisons {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Initialiser les variables
    $tasks = @{}
    $comparisonAttributes = @{}

    # Pattern pour détecter les tâches
    $taskPattern = '^\s*-\s*\[\s*[xX ]?\s*\]\s*\*\*([0-9.]+(?:\.[0-9]+)*)\*\*\s+(.+)$'

    # Patterns pour détecter les comparaisons explicites
    $comparisonPatterns = @(
        # Format: estimé: X jours, réel: Y jours
        '(?:estimé|prévu|planifié)\s*:\s*([0-9]+(?:[.,][0-9]+)?)\s+(jours?|semaines?|mois|heures?|minutes?)(?:.*?)(?:réel|effectif)\s*:\s*([0-9]+(?:[.,][0-9]+)?)\s+(jours?|semaines?|mois|heures?|minutes?)',
        # Format: écart: +/- Z jours
        '(?:écart|différence|delta)\s*:\s*([+-][0-9]+(?:[.,][0-9]+)?)\s+(jours?|semaines?|mois|heures?|minutes?)'
    )

    # Diviser le contenu en lignes
    $lines = $Content -split "`n"

    # Parcourir chaque ligne
    foreach ($line in $lines) {
        # Vérifier si la ligne contient une tâche
        if ($line -match $taskPattern) {
            $taskId = $matches[1]
            $taskLine = $matches[2]

            # Initialiser la tâche si elle n'existe pas
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id          = $taskId
                    Title       = $taskLine
                    Comparisons = @{
                        Explicit   = @()
                        Calculated = @()
                    }
                }
            }

            # Extraire les comparaisons explicites
            $matchResult = [regex]::Match($line, $comparisonPatterns[0])
            if ($matchResult.Success) {
                $estimatedValue = $matchResult.Groups[1].Value -replace ',', '.'
                $estimatedUnit = $matchResult.Groups[2].Value
                $actualValue = $matchResult.Groups[3].Value -replace ',', '.'
                $actualUnit = $matchResult.Groups[4].Value

                # Normaliser les unités
                $normalizedEstimatedUnit = switch -Regex ($estimatedUnit) {
                    '^j(our)?s?$' { "jours" }
                    '^s(emaine)?s?$' { "semaines" }
                    '^m(ois)?$' { "mois" }
                    '^h(eure)?s?$' { "heures" }
                    '^min(ute)?s?$' { "minutes" }
                    default { $estimatedUnit }
                }

                $normalizedActualUnit = switch -Regex ($actualUnit) {
                    '^j(our)?s?$' { "jours" }
                    '^s(emaine)?s?$' { "semaines" }
                    '^m(ois)?$' { "mois" }
                    '^h(eure)?s?$' { "heures" }
                    '^min(ute)?s?$' { "minutes" }
                    default { $actualUnit }
                }

                # Convertir les valeurs en heures pour le calcul de l'écart
                $estimatedHours = Convert-DurationToHours -Value ([double]$estimatedValue) -Unit $normalizedEstimatedUnit
                $actualHours = Convert-DurationToHours -Value ([double]$actualValue) -Unit $normalizedActualUnit
                $diffHours = $actualHours - $estimatedHours

                # Créer l'objet de comparaison
                $comparison = @{
                    Estimated  = @{
                        Value = [double]$estimatedValue
                        Unit  = $normalizedEstimatedUnit
                        Hours = $estimatedHours
                    }
                    Actual     = @{
                        Value = [double]$actualValue
                        Unit  = $normalizedActualUnit
                        Hours = $actualHours
                    }
                    Difference = @{
                        Hours      = $diffHours
                        Percentage = if (($null -ne $estimatedHours) -and ($estimatedHours -ne 0)) { ($diffHours / $estimatedHours) * 100 } else { 0 }
                    }
                    Original   = $matchResult.Groups[0].Value
                    Type       = "Explicit"
                    Source     = "Text"
                    Confidence = 0.95  # Confiance très élevée pour les mentions explicites
                }

                # Ajouter la comparaison à la tâche
                $tasks[$taskId].Comparisons.Explicit += $comparison

                # Ajouter la comparaison aux attributs de comparaison
                if (-not $comparisonAttributes.ContainsKey($taskId)) {
                    $comparisonAttributes[$taskId] = @{
                        Explicit   = @()
                        Calculated = @()
                    }
                }

                $comparisonAttributes[$taskId].Explicit += $comparison
            }

            # Extraire les écarts explicites
            $matchResult2 = [regex]::Match($line, $comparisonPatterns[1])
            if ($matchResult2.Success) {
                $diffValue = $matchResult2.Groups[1].Value -replace ',', '.'
                $diffUnit = $matchResult2.Groups[2].Value

                # Normaliser l'unité
                $normalizedDiffUnit = switch -Regex ($diffUnit) {
                    '^j(our)?s?$' { "jours" }
                    '^s(emaine)?s?$' { "semaines" }
                    '^m(ois)?$' { "mois" }
                    '^h(eure)?s?$' { "heures" }
                    '^min(ute)?s?$' { "minutes" }
                    default { $diffUnit }
                }

                # Convertir la valeur en heures
                $diffHours = Convert-DurationToHours -Value ([double]$diffValue) -Unit $normalizedDiffUnit

                # Créer l'objet de comparaison
                if (-not $comparisonAttributes.ContainsKey($taskId)) {
                    $comparisonAttributes[$taskId] = @{
                        Explicit   = @()
                        Calculated = @()
                    }
                }

                $comparison = @{
                    Difference = @{
                        Value      = [double]$diffValue
                        Unit       = $normalizedDiffUnit
                        Hours      = $diffHours
                        Percentage = 0  # Impossible de calculer sans les valeurs estimées et réelles
                    }
                    Original   = $matchResult2.Groups[0].Value
                    Type       = "ExplicitDifference"
                    Source     = "Text"
                    Confidence = 0.9  # Confiance élevée pour les mentions explicites d'écart
                }

                # Ajouter la comparaison à la tâche
                $tasks[$taskId].Comparisons.Explicit += $comparison

                # Ajouter la comparaison aux attributs de comparaison
                if (-not $comparisonAttributes.ContainsKey($taskId)) {
                    $comparisonAttributes[$taskId] = @{
                        Explicit   = @()
                        Calculated = @()
                    }
                }

                $comparisonAttributes[$taskId].Explicit += $comparison
            }
        }
    }

    return @{
        Tasks                = $tasks
        ComparisonAttributes = $comparisonAttributes
    }
}

# Fonction principale pour comparer les durées estimées et réelles
function Compare-EstimatedActualDurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "CSV", "Text")]
        [string]$OutputFormat = "JSON"
    )

    # Charger le contenu si un chemin de fichier est spécifié
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Le fichier spécifié n'existe pas: $FilePath"
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    # Extraire les durées estimées
    $estimatedDurationsJson = & $extractDurationScriptPath -Content $Content -OutputFormat "JSON"
    $estimatedDurations = $estimatedDurationsJson | ConvertFrom-Json

    # Extraire les durées réelles
    $actualDurationsJson = & $extractActualDurationScriptPath -Content $Content -OutputFormat "JSON"
    $actualDurations = $actualDurationsJson | ConvertFrom-Json

    # Extraire les comparaisons explicites
    $explicitComparisons = Get-DurationComparisons -Content $Content

    # Combiner les résultats
    $analysis = @{
        EstimatedDurations    = $estimatedDurations
        ActualDurations       = $actualDurations
        ExplicitComparisons   = $explicitComparisons.ComparisonAttributes
        CalculatedComparisons = @{}
        Tasks                 = @{}
        Stats                 = @{
            TotalTasks                     = 0
            TasksWithEstimatedDurations    = 0
            TasksWithActualDurations       = 0
            TasksWithExplicitComparisons   = 0
            TasksWithCalculatedComparisons = 0
            AverageDeviation               = 0
            MedianDeviation                = 0
            MaxPositiveDeviation           = 0
            MaxNegativeDeviation           = 0
        }
    }

    # Calculer les comparaisons pour les tâches ayant à la fois des durées estimées et réelles
    $allTaskIds = @($estimatedDurations.Tasks.PSObject.Properties.Name) + @($actualDurations.Tasks.PSObject.Properties.Name) | Select-Object -Unique

    $calculatedComparisons = @{}
    $deviations = @()

    foreach ($taskId in $allTaskIds) {
        $hasEstimated = $estimatedDurations.Tasks.PSObject.Properties.Name -contains $taskId
        $hasActual = $actualDurations.Tasks.PSObject.Properties.Name -contains $taskId

        if ($hasEstimated -and $hasActual) {
            # Get the task objects
            $actualTask = $actualDurations.Tasks.$taskId

            # Obtenir la meilleure estimation (priorité: DayWeekMonth, HourMinute, Composite)
            $bestEstimate = $null
            $bestEstimateSource = ""

            if ($estimatedDurations.DayWeekMonthDurations.$taskId -and $estimatedDurations.DayWeekMonthDurations.$taskId.Count -gt 0) {
                $bestEstimate = $estimatedDurations.DayWeekMonthDurations.$taskId[0]
                $bestEstimateSource = "DayWeekMonth"
            } elseif ($estimatedDurations.HourMinuteDurations.$taskId -and $estimatedDurations.HourMinuteDurations.$taskId.Count -gt 0) {
                $bestEstimate = $estimatedDurations.HourMinuteDurations.$taskId[0]
                $bestEstimateSource = "HourMinute"
            } elseif ($estimatedDurations.CompositeDurations.$taskId -and $estimatedDurations.CompositeDurations.$taskId.Count -gt 0) {
                $bestEstimate = $estimatedDurations.CompositeDurations.$taskId[0]
                $bestEstimateSource = "Composite"
            }

            # Obtenir la meilleure durée réelle (priorité: Explicit, Tags, Calculated)
            $bestActual = $null
            $bestActualSource = ""

            if ($actualTask.ActualDurations.Explicit -and $actualTask.ActualDurations.Explicit.Count -gt 0) {
                $bestActual = $actualTask.ActualDurations.Explicit[0]
                $bestActualSource = "Explicit"
            } elseif ($actualTask.ActualDurations.Tags -and $actualTask.ActualDurations.Tags.Count -gt 0) {
                $bestActual = $actualTask.ActualDurations.Tags[0]
                $bestActualSource = "Tags"
            } elseif ($actualTask.ActualDurations.Calculated -and $actualTask.ActualDurations.Calculated.Count -gt 0) {
                $bestActual = $actualTask.ActualDurations.Calculated[0]
                $bestActualSource = "Calculated"
            }

            # Calculer la comparaison si les deux valeurs sont disponibles
            if ($bestEstimate -and $bestActual) {
                # Convertir les valeurs en heures pour le calcul de l'écart
                $estimatedHours = Convert-DurationToHours -Value $bestEstimate.Value -Unit $bestEstimate.Unit
                $actualHours = Convert-DurationToHours -Value $bestActual.Value -Unit $bestActual.Unit
                $diffHours = $actualHours - $estimatedHours
                $percentageDiff = if (($null -ne $estimatedHours) -and ($estimatedHours -ne 0)) { ($diffHours / $estimatedHours) * 100 } else { 0 }

                # Créer l'objet de comparaison
                $comparison = @{
                    Estimated  = @{
                        Value  = $bestEstimate.Value
                        Unit   = $bestEstimate.Unit
                        Hours  = $estimatedHours
                        Source = $bestEstimateSource
                    }
                    Actual     = @{
                        Value  = $bestActual.Value
                        Unit   = $bestActual.Unit
                        Hours  = $actualHours
                        Source = $bestActualSource
                    }
                    Difference = @{
                        Hours      = $diffHours
                        Percentage = $percentageDiff
                    }
                    Type       = "Calculated"
                    Confidence = 0.85  # Confiance élevée pour les calculs automatiques
                }

                # Ajouter la comparaison aux résultats
                $calculatedComparisons[$taskId] = $comparison

                # Ajouter la déviation pour les statistiques
                $deviations += $percentageDiff
            }
        }
    }

    # Ajouter les comparaisons calculées à l'analyse
    $analysis.CalculatedComparisons = $calculatedComparisons

    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithEstimatedDurations = ($estimatedDurations.Tasks.PSObject.Properties.Name).Count
    $analysis.Stats.TasksWithActualDurations = ($actualDurations.Tasks.PSObject.Properties.Name).Count
    $analysis.Stats.TasksWithExplicitComparisons = ($explicitComparisons.ComparisonAttributes.Keys).Count
    $analysis.Stats.TasksWithCalculatedComparisons = $calculatedComparisons.Count

    if ($deviations.Count -gt 0) {
        $analysis.Stats.AverageDeviation = ($deviations | Measure-Object -Average).Average
        $sortedDeviations = $deviations | Sort-Object
        $midpoint = [math]::Floor($sortedDeviations.Count / 2)
        $analysis.Stats.MedianDeviation = if ($sortedDeviations.Count % 2 -eq 0) {
            ($sortedDeviations[$midpoint - 1] + $sortedDeviations[$midpoint]) / 2
        } else {
            $sortedDeviations[$midpoint]
        }
        $analysis.Stats.MaxPositiveDeviation = ($deviations | Where-Object { $_ -gt 0 } | Measure-Object -Maximum).Maximum
        $analysis.Stats.MaxNegativeDeviation = ($deviations | Where-Object { $_ -lt 0 } | Measure-Object -Minimum).Minimum
    }

    # Formater la sortie selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            $output = $analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $output = "# Comparaison des durées estimées et réelles`n`n"
            $output += "## Statistiques`n`n"
            $output += "- Total des tâches: $($analysis.Stats.TotalTasks)`n"
            $output += "- Tâches avec durées estimées: $($analysis.Stats.TasksWithEstimatedDurations)`n"
            $output += "- Tâches avec durées réelles: $($analysis.Stats.TasksWithActualDurations)`n"
            $output += "- Tâches avec comparaisons explicites: $($analysis.Stats.TasksWithExplicitComparisons)`n"
            $output += "- Tâches avec comparaisons calculées: $($analysis.Stats.TasksWithCalculatedComparisons)`n"
            $output += "- Déviation moyenne: $($analysis.Stats.AverageDeviation.ToString('F2'))%`n"
            $output += "- Déviation médiane: $($analysis.Stats.MedianDeviation.ToString('F2'))%`n"
            $output += "- Déviation positive maximale: $($analysis.Stats.MaxPositiveDeviation.ToString('F2'))%`n"
            $output += "- Déviation négative maximale: $($analysis.Stats.MaxNegativeDeviation.ToString('F2'))%`n`n"

            $output += "## Comparaisons par tâche`n`n"
            foreach ($taskId in $calculatedComparisons.Keys) {
                $comparison = $calculatedComparisons[$taskId]
                $output += "### Tâche $taskId`n`n"
                $output += "- Estimé: $($comparison.Estimated.Value) $($comparison.Estimated.Unit) (source: $($comparison.Estimated.Source))`n"
                $output += "- Réel: $($comparison.Actual.Value) $($comparison.Actual.Unit) (source: $($comparison.Actual.Source))`n"
                $output += "- Différence: $($comparison.Difference.Hours.ToString('F2')) heures ($($comparison.Difference.Percentage.ToString('F2'))%)`n`n"
            }
        }
        "CSV" {
            $output = "TaskId,EstimatedValue,EstimatedUnit,EstimatedHours,ActualValue,ActualUnit,ActualHours,DifferenceHours,DifferencePercentage`n"
            foreach ($taskId in $calculatedComparisons.Keys) {
                $comparison = $calculatedComparisons[$taskId]
                $output += "$taskId,$($comparison.Estimated.Value),$($comparison.Estimated.Unit),$($comparison.Estimated.Hours),$($comparison.Actual.Value),$($comparison.Actual.Unit),$($comparison.Actual.Hours),$($comparison.Difference.Hours),$($comparison.Difference.Percentage)`n"
            }
        }
        "Text" {
            $output = "Comparaison des durées estimées et réelles`n`n"
            $output += "Statistiques:`n"
            $output += "  Total des tâches: $($analysis.Stats.TotalTasks)`n"
            $output += "  Tâches avec durées estimées: $($analysis.Stats.TasksWithEstimatedDurations)`n"
            $output += "  Tâches avec durées réelles: $($analysis.Stats.TasksWithActualDurations)`n"
            $output += "  Tâches avec comparaisons explicites: $($analysis.Stats.TasksWithExplicitComparisons)`n"
            $output += "  Tâches avec comparaisons calculées: $($analysis.Stats.TasksWithCalculatedComparisons)`n"
            $output += "  Déviation moyenne: $($analysis.Stats.AverageDeviation.ToString('F2'))%`n"
            $output += "  Déviation médiane: $($analysis.Stats.MedianDeviation.ToString('F2'))%`n"
            $output += "  Déviation positive maximale: $($analysis.Stats.MaxPositiveDeviation.ToString('F2'))%`n"
            $output += "  Déviation négative maximale: $($analysis.Stats.MaxNegativeDeviation.ToString('F2'))%`n`n"

            $output += "Comparaisons par tâche:`n`n"
            foreach ($taskId in $calculatedComparisons.Keys) {
                $comparison = $calculatedComparisons[$taskId]
                $output += "Tâche $($taskId):`n"
                $output += "  Estimé: $($comparison.Estimated.Value) $($comparison.Estimated.Unit) (source: $($comparison.Estimated.Source))`n"
                $output += "  Réel: $($comparison.Actual.Value) $($comparison.Actual.Unit) (source: $($comparison.Actual.Source))`n"
                $output += "  Différence: $($comparison.Difference.Hours.ToString('F2')) heures ($($comparison.Difference.Percentage.ToString('F2'))%)`n`n"
            }
        }
    }

    # Sauvegarder la sortie si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $output | Out-File -FilePath $OutputPath -Encoding utf8
    }

    return $output
}

# Exécuter la fonction principale avec les paramètres fournis
Compare-EstimatedActualDurations -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
