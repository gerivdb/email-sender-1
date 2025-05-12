# Extract-ActualDurationValues.ps1
# Script pour extraire les valeurs de durée réelle des tâches dans les fichiers markdown de roadmap
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

# Fonction pour extraire les durées réelles explicites
function Get-ExplicitActualDurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Initialiser les variables
    $tasks = @{}
    $actualDurationAttributes = @{}

    # Pattern pour détecter les tâches
    $taskPattern = '^\s*-\s*\[\s*[xX ]?\s*\]\s*\*\*([0-9.]+(?:\.[0-9]+)*)\*\*\s+(.+)$'

    # Patterns pour détecter les durées réelles explicites
    $actualDurationPatterns = @(
        # Format: durée réelle: X jours/semaines/mois/heures
        '(?:durée\s+réelle|temps\s+réel|durée\s+effective|temps\s+effectif)\s*:\s*([0-9]+(?:[.,][0-9]+)?)\s+(jours?|semaines?|mois|heures?|minutes?)',
        # Format: a pris/duré X jours/semaines/mois/heures
        'a\s+(?:pris|duré)\s+([0-9]+(?:[.,][0-9]+)?)\s+(jours?|semaines?|mois|heures?|minutes?)',
        # Format: terminé/réalisé en X jours/semaines/mois/heures
        '(?:terminé|réalisé|complété|achevé|fini)\s+en\s+([0-9]+(?:[.,][0-9]+)?)\s+(jours?|semaines?|mois|heures?|minutes?)',
        # Format: X jours/semaines/mois/heures effectifs/réels
        '([0-9]+(?:[.,][0-9]+)?)\s+(jours?|semaines?|mois|heures?|minutes?)\s+(?:effectifs?|réels?)'
    )

    # Patterns pour détecter les tags de durée réelle
    $actualDurationTagPatterns = @{
        # Format: #durée-réelle:Xj
        ActualDurationDays   = '#durée-réelle:([0-9]+(?:[.,][0-9]+)?)j'
        # Format: #durée-réelle:Xs
        ActualDurationWeeks  = '#durée-réelle:([0-9]+(?:[.,][0-9]+)?)s'
        # Format: #durée-réelle:Xm
        ActualDurationMonths = '#durée-réelle:([0-9]+(?:[.,][0-9]+)?)m'
        # Format: #durée-réelle:Xh
        ActualDurationHours  = '#durée-réelle:([0-9]+(?:[.,][0-9]+)?)h'
        # Format: #temps-réel:Xj
        ActualTimeDays       = '#temps-réel:([0-9]+(?:[.,][0-9]+)?)j'
        # Format: #temps-réel:Xs
        ActualTimeWeeks      = '#temps-réel:([0-9]+(?:[.,][0-9]+)?)s'
        # Format: #temps-réel:Xm
        ActualTimeMonths     = '#temps-réel:([0-9]+(?:[.,][0-9]+)?)m'
        # Format: #temps-réel:Xh
        ActualTimeHours      = '#temps-réel:([0-9]+(?:[.,][0-9]+)?)h'
    }

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
                    Id              = $taskId
                    Title           = $taskLine
                    ActualDurations = @{
                        Explicit   = @()
                        Tags       = @()
                        Calculated = @()
                    }
                }
            }

            # Extraire les durées réelles explicites
            foreach ($pattern in $actualDurationPatterns) {
                $matchResults = [regex]::Matches($line, $pattern)
                foreach ($match in $matchResults) {
                    $durationValue = $match.Groups[1].Value
                    $durationUnit = $match.Groups[2].Value

                    # Normaliser les valeurs décimales (remplacer la virgule par un point)
                    $normalizedValue = $durationValue -replace ',', '.'

                    # Normaliser les unités
                    $normalizedUnit = switch -Regex ($durationUnit) {
                        '^j(our)?s?$' { "jours" }
                        '^s(emaine)?s?$' { "semaines" }
                        '^m(ois)?$' { "mois" }
                        '^h(eure)?s?$' { "heures" }
                        '^min(ute)?s?$' { "minutes" }
                        default { $durationUnit }
                    }

                    # Créer l'objet de durée réelle
                    $actualDuration = @{
                        Value      = [double]$normalizedValue
                        Unit       = $normalizedUnit
                        Original   = $match.Groups[0].Value
                        Type       = "Explicit"
                        Source     = "Text"
                        Confidence = 0.9  # Confiance élevée pour les mentions explicites
                    }

                    # Ajouter la durée réelle à la tâche
                    $tasks[$taskId].ActualDurations.Explicit += $actualDuration

                    # Ajouter la durée réelle aux attributs de durée
                    if (-not $actualDurationAttributes.ContainsKey($taskId)) {
                        $actualDurationAttributes[$taskId] = @{
                            Explicit   = @()
                            Tags       = @()
                            Calculated = @()
                        }
                    }

                    $actualDurationAttributes[$taskId].Explicit += $actualDuration
                }
            }

            # Extraire les tags de durée réelle
            foreach ($tagType in $actualDurationTagPatterns.Keys) {
                $pattern = $actualDurationTagPatterns[$tagType]
                if ($line -match $pattern) {
                    $durationValue = $matches[1]

                    # Normaliser les valeurs décimales (remplacer la virgule par un point)
                    $normalizedValue = $durationValue -replace ',', '.'

                    # Déterminer l'unité en fonction du type de tag
                    $unit = switch -Regex ($tagType) {
                        'Days$' { "jours" }
                        'Weeks$' { "semaines" }
                        'Months$' { "mois" }
                        'Hours$' { "heures" }
                        default { "jours" }  # Par défaut
                    }

                    # Créer l'objet de durée réelle
                    $actualDuration = @{
                        Value      = [double]$normalizedValue
                        Unit       = $unit
                        Original   = $matches[0]
                        Type       = "Tag"
                        Source     = $tagType
                        Confidence = 0.95  # Confiance très élevée pour les tags
                    }

                    # Ajouter la durée réelle à la tâche
                    $tasks[$taskId].ActualDurations.Tags += $actualDuration

                    # Ajouter la durée réelle aux attributs de durée
                    if (-not $actualDurationAttributes.ContainsKey($taskId)) {
                        $actualDurationAttributes[$taskId] = @{
                            Explicit   = @()
                            Tags       = @()
                            Calculated = @()
                        }
                    }

                    $actualDurationAttributes[$taskId].Tags += $actualDuration
                }
            }
        }
    }

    return @{
        Tasks                    = $tasks
        ActualDurationAttributes = $actualDurationAttributes
    }
}

# Fonction pour extraire les durées réelles calculées à partir des dates
function Get-CalculatedActualDurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Initialiser les variables
    $tasks = @{}
    $actualDurationAttributes = @{}

    # Pattern pour détecter les tâches
    $taskPattern = '^\s*-\s*\[\s*[xX ]?\s*\]\s*\*\*([0-9.]+(?:\.[0-9]+)*)\*\*\s+(.+)$'

    # Patterns pour détecter les dates de début et fin
    $datePatterns = @(
        # Format ISO: YYYY-MM-DD
        @{
            Start  = '(?:commencé|débuté|début|démarré|start)\s+(?:le|:)\s+(\d{4}-\d{2}-\d{2})'
            End    = '(?:terminé|fini|fin|complété|achevé|end)\s+(?:le|:)\s+(\d{4}-\d{2}-\d{2})'
            Format = 'yyyy-MM-dd'
        },
        # Format français: DD/MM/YYYY
        @{
            Start  = '(?:commencé|débuté|début|démarré|start)\s+(?:le|:)\s+(\d{2}/\d{2}/\d{4})'
            End    = '(?:terminé|fini|fin|complété|achevé|end)\s+(?:le|:)\s+(\d{2}/\d{2}/\d{4})'
            Format = 'dd/MM/yyyy'
        }
    )

    # Patterns pour détecter les dates avec heures
    $dateTimePatterns = @(
        # Format: YYYY-MM-DD à HH:mm
        @{
            Start  = '(?:commencé|débuté|début|démarré|start)\s+(?:le|:)\s+(\d{4}-\d{2}-\d{2})\s+à\s+(\d{1,2})h(?:(\d{2})?)?'
            End    = '(?:terminé|fini|fin|complété|achevé|end)\s+(?:le|:)\s+(\d{4}-\d{2}-\d{2})\s+à\s+(\d{1,2})h(?:(\d{2})?)?'
            Format = 'yyyy-MM-dd HH:mm'
        },
        # Format français: DD/MM/YYYY à HH:mm
        @{
            Start  = '(?:commencé|débuté|début|démarré|start)\s+(?:le|:)\s+(\d{2}/\d{2}/\d{4})\s+à\s+(\d{1,2})h(?:(\d{2})?)?'
            End    = '(?:terminé|fini|fin|complété|achevé|end)\s+(?:le|:)\s+(\d{2}/\d{2}/\d{4})\s+à\s+(\d{1,2})h(?:(\d{2})?)?'
            Format = 'dd/MM/yyyy HH:mm'
        }
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
                    Id              = $taskId
                    Title           = $taskLine
                    ActualDurations = @{
                        Explicit   = @()
                        Tags       = @()
                        Calculated = @()
                    }
                }
            }

            # Extraire les durées calculées à partir des dates
            foreach ($datePattern in $datePatterns) {
                $startMatch = [regex]::Match($line, $datePattern.Start)
                $endMatch = [regex]::Match($line, $datePattern.End)

                if ($startMatch.Success -and $endMatch.Success) {
                    $startDateStr = $startMatch.Groups[1].Value
                    $endDateStr = $endMatch.Groups[1].Value

                    try {
                        # Convertir les dates en objets DateTime
                        $startDate = [DateTime]::ParseExact($startDateStr, $datePattern.Format, [System.Globalization.CultureInfo]::InvariantCulture)
                        $endDate = [DateTime]::ParseExact($endDateStr, $datePattern.Format, [System.Globalization.CultureInfo]::InvariantCulture)

                        # Calculer la durée en jours
                        $duration = ($endDate - $startDate).TotalDays

                        # Créer l'objet de durée réelle calculée
                        $actualDuration = @{
                            Value      = $duration
                            Unit       = "jours"
                            Original   = "Du $startDateStr au $endDateStr"
                            Type       = "Calculated"
                            Source     = "DateDifference"
                            StartDate  = $startDate
                            EndDate    = $endDate
                            Confidence = 0.85  # Confiance élevée pour les calculs de dates
                        }

                        # Ajouter la durée réelle à la tâche
                        $tasks[$taskId].ActualDurations.Calculated += $actualDuration

                        # Ajouter la durée réelle aux attributs de durée
                        if (-not $actualDurationAttributes.ContainsKey($taskId)) {
                            $actualDurationAttributes[$taskId] = @{
                                Explicit   = @()
                                Tags       = @()
                                Calculated = @()
                            }
                        }

                        $actualDurationAttributes[$taskId].Calculated += $actualDuration
                    } catch {
                        Write-Verbose "Erreur lors de la conversion des dates: $_"
                    }
                }
            }

            # Extraire les durées calculées à partir des dates avec heures
            foreach ($dateTimePattern in $dateTimePatterns) {
                $startMatch = [regex]::Match($line, $dateTimePattern.Start)
                $endMatch = [regex]::Match($line, $dateTimePattern.End)

                if ($startMatch.Success -and $endMatch.Success) {
                    $startDateStr = $startMatch.Groups[1].Value
                    $startHour = $startMatch.Groups[2].Value
                    $startMinute = if (($startMatch.Groups.Count > 3) -and ($startMatch.Groups[3].Success)) {
                        $startMatch.Groups[3].Value
                    } else {
                        "00"
                    }

                    $endDateStr = $endMatch.Groups[1].Value
                    $endHour = $endMatch.Groups[2].Value
                    $endMinute = if (($endMatch.Groups.Count > 3) -and ($endMatch.Groups[3].Success)) {
                        $endMatch.Groups[3].Value
                    } else {
                        "00"
                    }

                    try {
                        # Construire les chaînes de date/heure complètes
                        $startDateTimeStr = "$startDateStr $($startHour):$($startMinute)"
                        $endDateTimeStr = "$endDateStr $($endHour):$($endMinute)"

                        # Convertir les dates en objets DateTime
                        $startDateTime = [DateTime]::ParseExact($startDateTimeStr, $dateTimePattern.Format, [System.Globalization.CultureInfo]::InvariantCulture)
                        $endDateTime = [DateTime]::ParseExact($endDateTimeStr, $dateTimePattern.Format, [System.Globalization.CultureInfo]::InvariantCulture)

                        # Calculer la durée en heures
                        $durationHours = ($endDateTime - $startDateTime).TotalHours

                        # Créer l'objet de durée réelle calculée
                        $actualDuration = @{
                            Value         = $durationHours
                            Unit          = "heures"
                            Original      = "Du $startDateTimeStr au $endDateTimeStr"
                            Type          = "Calculated"
                            Source        = "DateTimeDifference"
                            StartDateTime = $startDateTime
                            EndDateTime   = $endDateTime
                            Confidence    = 0.9  # Confiance très élevée pour les calculs précis
                        }

                        # Ajouter la durée réelle à la tâche
                        $tasks[$taskId].ActualDurations.Calculated += $actualDuration

                        # Ajouter la durée réelle aux attributs de durée
                        if (-not $actualDurationAttributes.ContainsKey($taskId)) {
                            $actualDurationAttributes[$taskId] = @{
                                Explicit   = @()
                                Tags       = @()
                                Calculated = @()
                            }
                        }

                        $actualDurationAttributes[$taskId].Calculated += $actualDuration
                    } catch {
                        Write-Verbose "Erreur lors de la conversion des dates avec heures: $_"
                    }
                }
            }
        }
    }

    return @{
        Tasks                    = $tasks
        ActualDurationAttributes = $actualDurationAttributes
    }
}

# Fonction principale pour extraire les durées réelles
function Get-ActualDurationValues {
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
            Write-Host "Le fichier spécifié n'existe pas: $FilePath" -ForegroundColor Red
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    # Extraire les différents types de durées réelles
    $explicitActualDurations = Get-ExplicitActualDurations -Content $Content
    $calculatedActualDurations = Get-CalculatedActualDurations -Content $Content

    # Combiner les résultats
    $analysis = @{
        ExplicitActualDurations   = $explicitActualDurations.ActualDurationAttributes
        CalculatedActualDurations = $calculatedActualDurations.ActualDurationAttributes
        Tasks                     = @{}
        Stats                     = @{
            TotalTasks                         = 0
            TasksWithExplicitActualDurations   = 0
            TasksWithCalculatedActualDurations = 0
            TasksWithEstimateActualComparison  = 0
        }
    }

    # Fusionner les informations des tâches
    $allTaskIds = @($explicitActualDurations.Tasks.Keys) + @($calculatedActualDurations.Tasks.Keys) | Select-Object -Unique

    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id              = $taskId
            Title           = ""
            ActualDurations = @{
                Explicit   = @()
                Tags       = @()
                Calculated = @()
            }
        }

        # Ajouter les informations de la tâche depuis les durées explicites
        if ($explicitActualDurations.Tasks.ContainsKey($taskId)) {
            $task.Title = $explicitActualDurations.Tasks[$taskId].Title
            $task.ActualDurations.Explicit = $explicitActualDurations.Tasks[$taskId].ActualDurations.Explicit
            $task.ActualDurations.Tags = $explicitActualDurations.Tasks[$taskId].ActualDurations.Tags
        }

        # Ajouter les informations de la tâche depuis les durées calculées
        if ($calculatedActualDurations.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $calculatedActualDurations.Tasks[$taskId].Title
            }
            $task.ActualDurations.Calculated = $calculatedActualDurations.Tasks[$taskId].ActualDurations.Calculated
        }

        # Ajouter la tâche à l'analyse
        $analysis.Tasks[$taskId] = $task
    }

    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithExplicitActualDurations = ($analysis.Tasks.Values | Where-Object { $_.ActualDurations.Explicit.Count -gt 0 -or $_.ActualDurations.Tags.Count -gt 0 }).Count
    $analysis.Stats.TasksWithCalculatedActualDurations = ($analysis.Tasks.Values | Where-Object { $_.ActualDurations.Calculated.Count -gt 0 }).Count

    # Formater la sortie selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            $output = $analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $output = "# Analyse des durées réelles`n`n"
            $output += "## Statistiques`n`n"
            $output += "- Total des tâches: $($analysis.Stats.TotalTasks)`n"
            $output += "- Tâches avec durées réelles explicites: $($analysis.Stats.TasksWithExplicitActualDurations)`n"
            $output += "- Tâches avec durées réelles calculées: $($analysis.Stats.TasksWithCalculatedActualDurations)`n"
            $output += "- Tâches avec comparaison estimé/réel: $($analysis.Stats.TasksWithEstimateActualComparison)`n`n"

            $output += "## Tâches avec durées réelles`n`n"
            foreach ($taskId in $allTaskIds) {
                $task = $analysis.Tasks[$taskId]
                $output += "### Tâche $($taskId): $($task.Title)`n`n"

                if ($task.ActualDurations.Explicit.Count -gt 0) {
                    $output += "#### Durées réelles explicites`n`n"
                    foreach ($duration in $task.ActualDurations.Explicit) {
                        $output += "- $($duration.Value) $($duration.Unit) (source: $($duration.Original))`n"
                    }
                    $output += "`n"
                }

                if ($task.ActualDurations.Tags.Count -gt 0) {
                    $output += "#### Tags de durée réelle`n`n"
                    foreach ($duration in $task.ActualDurations.Tags) {
                        $output += "- $($duration.Value) $($duration.Unit) (tag: $($duration.Original))`n"
                    }
                    $output += "`n"
                }

                if ($task.ActualDurations.Calculated.Count -gt 0) {
                    $output += "#### Durées réelles calculées`n`n"
                    foreach ($duration in $task.ActualDurations.Calculated) {
                        $output += "- $($duration.Value) $($duration.Unit) (calculé: $($duration.Original))`n"
                    }
                    $output += "`n"
                }
            }
        }
        "CSV" {
            $output = "TaskId,Title,ExplicitDurations,TagDurations,CalculatedDurations`n"
            foreach ($taskId in $allTaskIds) {
                $task = $analysis.Tasks[$taskId]

                $explicitDurations = ($task.ActualDurations.Explicit | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join "; "
                $tagDurations = ($task.ActualDurations.Tags | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join "; "
                $calculatedDurations = ($task.ActualDurations.Calculated | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join "; "

                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'

                $output += "$taskId,`"$escapedTitle`",`"$explicitDurations`",`"$tagDurations`",`"$calculatedDurations`"`n"
            }
        }
        "Text" {
            $output = "Analyse des durées réelles`n`n"
            $output += "Statistiques:`n"
            $output += "  Total des tâches: $($analysis.Stats.TotalTasks)`n"
            $output += "  Tâches avec durées réelles explicites: $($analysis.Stats.TasksWithExplicitActualDurations)`n"
            $output += "  Tâches avec durées réelles calculées: $($analysis.Stats.TasksWithCalculatedActualDurations)`n"
            $output += "  Tâches avec comparaison estimé/réel: $($analysis.Stats.TasksWithEstimateActualComparison)`n`n"

            $output += "Tâches avec durées réelles:`n`n"
            foreach ($taskId in $allTaskIds) {
                $task = $analysis.Tasks[$taskId]
                $output += "Tâche $($taskId): $($task.Title)`n"

                if ($task.ActualDurations.Explicit.Count -gt 0) {
                    $output += "  Durées réelles explicites:`n"
                    foreach ($duration in $task.ActualDurations.Explicit) {
                        $output += "    - $($duration.Value) $($duration.Unit) (source: $($duration.Original))`n"
                    }
                }

                if ($task.ActualDurations.Tags.Count -gt 0) {
                    $output += "  Tags de durée réelle:`n"
                    foreach ($duration in $task.ActualDurations.Tags) {
                        $output += "    - $($duration.Value) $($duration.Unit) (tag: $($duration.Original))`n"
                    }
                }

                if ($task.ActualDurations.Calculated.Count -gt 0) {
                    $output += "  Durées réelles calculées:`n"
                    foreach ($duration in $task.ActualDurations.Calculated) {
                        $output += "    - $($duration.Value) $($duration.Unit) (calculé: $($duration.Original))`n"
                    }
                }

                $output += "`n"
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
Get-ActualDurationValues -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
