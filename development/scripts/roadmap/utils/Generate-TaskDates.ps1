﻿# Generate-TaskDates.ps1
# Module pour générer des dates de début et de fin cohérentes pour les tâches
# Version: 1.0
# Date: 2025-05-15

# Fonction pour générer une date aléatoire dans une plage donnée
function Get-RandomDate {
    <#
    .SYNOPSIS
        Génère une date aléatoire dans une plage donnée.

    .DESCRIPTION
        Cette fonction génère une date aléatoire entre une date de début et une date de fin spécifiées.
        Elle peut également respecter des contraintes de jours ouvrables si demandé.

    .PARAMETER StartDate
        La date de début de la plage.

    .PARAMETER EndDate
        La date de fin de la plage.

    .PARAMETER ExcludeWeekends
        Indique si les weekends doivent être exclus de la génération.

    .PARAMETER ExcludeHolidays
        Indique si les jours fériés doivent être exclus de la génération.

    .PARAMETER HolidayDates
        Liste des dates de jours fériés à exclure.

    .EXAMPLE
        Get-RandomDate -StartDate (Get-Date) -EndDate (Get-Date).AddMonths(3)
        Génère une date aléatoire entre aujourd'hui et dans 3 mois.

    .EXAMPLE
        Get-RandomDate -StartDate (Get-Date) -EndDate (Get-Date).AddMonths(1) -ExcludeWeekends
        Génère une date aléatoire entre aujourd'hui et dans 1 mois, en excluant les weekends.

    .OUTPUTS
        System.DateTime
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DateTime]$StartDate,

        [Parameter(Mandatory = $true)]
        [DateTime]$EndDate,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeWeekends,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeHolidays,

        [Parameter(Mandatory = $false)]
        [DateTime[]]$HolidayDates = @()
    )

    # Vérifier que la date de début est antérieure à la date de fin
    if ($StartDate -gt $EndDate) {
        throw "La date de début doit être antérieure à la date de fin."
    }

    # Calculer le nombre de jours entre les deux dates
    $range = ($EndDate - $StartDate).Days

    if ($range -eq 0) {
        return $StartDate
    }

    # Générer une date aléatoire
    $randomDate = $null
    $isValidDate = $false
    $maxAttempts = 100
    $attempts = 0

    while (-not $isValidDate -and $attempts -lt $maxAttempts) {
        $randomDays = Get-Random -Minimum 0 -Maximum ($range + 1)
        $randomDate = $StartDate.AddDays($randomDays)

        $isValidDate = $true

        # Vérifier si la date est un weekend
        if ($ExcludeWeekends -and ($randomDate.DayOfWeek -eq [DayOfWeek]::Saturday -or $randomDate.DayOfWeek -eq [DayOfWeek]::Sunday)) {
            $isValidDate = $false
        }

        # Vérifier si la date est un jour férié
        if ($ExcludeHolidays -and $HolidayDates -contains $randomDate.Date) {
            $isValidDate = $false
        }

        $attempts++
    }

    if ($attempts -ge $maxAttempts) {
        Write-Warning "Impossible de trouver une date valide après $maxAttempts tentatives. Retour de la date de début."
        return $StartDate
    }

    return $randomDate
}

# Fonction pour générer des dates de début et de fin pour une tâche
function New-TaskDates {
    <#
    .SYNOPSIS
        Génère des dates de début et de fin cohérentes pour une tâche.

    .DESCRIPTION
        Cette fonction génère des dates de début et de fin cohérentes pour une tâche,
        en respectant diverses contraintes comme la durée minimale et maximale,
        les dépendances avec d'autres tâches, etc.

    .PARAMETER ProjectStartDate
        La date de début du projet.

    .PARAMETER ProjectEndDate
        La date de fin du projet.

    .PARAMETER MinDuration
        La durée minimale de la tâche en jours.

    .PARAMETER MaxDuration
        La durée maximale de la tâche en jours.

    .PARAMETER DependsOnTasks
        Liste des tâches dont dépend la tâche actuelle.

    .PARAMETER ParentTask
        La tâche parente de la tâche actuelle.

    .PARAMETER ChildTasks
        Liste des tâches enfants de la tâche actuelle.

    .PARAMETER ExcludeWeekends
        Indique si les weekends doivent être exclus des dates générées.

    .PARAMETER ExcludeHolidays
        Indique si les jours fériés doivent être exclus des dates générées.

    .PARAMETER HolidayDates
        Liste des dates de jours fériés à exclure.

    .PARAMETER TaskLevel
        Niveau hiérarchique de la tâche (0 = racine, 1 = premier niveau, etc.).

    .PARAMETER TaskIndex
        Index de la tâche dans son niveau hiérarchique.

    .PARAMETER TotalTasksAtLevel
        Nombre total de tâches au même niveau hiérarchique.

    .EXAMPLE
        New-TaskDates -ProjectStartDate (Get-Date) -ProjectEndDate (Get-Date).AddMonths(6) -MinDuration 3 -MaxDuration 14
        Génère des dates de début et de fin pour une tâche avec une durée entre 3 et 14 jours.

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DateTime]$ProjectStartDate,

        [Parameter(Mandatory = $true)]
        [DateTime]$ProjectEndDate,

        [Parameter(Mandatory = $false)]
        [int]$MinDuration = 1,

        [Parameter(Mandatory = $false)]
        [int]$MaxDuration = 30,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$DependsOnTasks = @(),

        [Parameter(Mandatory = $false)]
        [PSObject]$ParentTask = $null,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$ChildTasks = @(),

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeWeekends,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeHolidays,

        [Parameter(Mandatory = $false)]
        [DateTime[]]$HolidayDates = @(),

        [Parameter(Mandatory = $false)]
        [int]$TaskLevel = 0,

        [Parameter(Mandatory = $false)]
        [int]$TaskIndex = 0,

        [Parameter(Mandatory = $false)]
        [int]$TotalTasksAtLevel = 1
    )

    # Déterminer la date de début la plus tardive des tâches dont dépend celle-ci
    $earliestStartDate = $ProjectStartDate

    if ($DependsOnTasks.Count -gt 0) {
        $dependenciesEndDate = $DependsOnTasks |
            Where-Object { $_.Metadata -and $_.Metadata.ContainsKey("EndDate") } |
            ForEach-Object { [DateTime]::Parse($_.Metadata["EndDate"]) } |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty Maximum

        if ($dependenciesEndDate) {
            $earliestStartDate = $dependenciesEndDate.AddDays(1)
        }
    }

    # Si la tâche a un parent, s'assurer qu'elle commence après le début du parent
    if ($ParentTask -and $ParentTask.Metadata -and $ParentTask.Metadata.ContainsKey("StartDate")) {
        $parentStartDate = [DateTime]::Parse($ParentTask.Metadata["StartDate"])

        if ($parentStartDate -gt $earliestStartDate) {
            $earliestStartDate = $parentStartDate
        }
    }

    # Ajuster la date de début en fonction du niveau hiérarchique et de l'index
    if ($TaskLevel -gt 0 -and $TotalTasksAtLevel -gt 1) {
        # Distribuer les tâches de manière plus ou moins uniforme sur la durée du projet
        $projectDuration = ($ProjectEndDate - $ProjectStartDate).Days
        $segmentSize = $projectDuration / $TotalTasksAtLevel

        # Ajouter un décalage basé sur l'index de la tâche
        $offset = [math]::Floor($segmentSize * $TaskIndex)

        # Ajouter une variation aléatoire pour éviter que toutes les tâches commencent exactement au même moment
        $randomVariation = Get-Random -Minimum (-$segmentSize / 4) -Maximum ($segmentSize / 4)
        $offset += $randomVariation

        # S'assurer que l'offset ne fait pas commencer la tâche avant la date de début la plus tardive des dépendances
        $adjustedStartDate = $ProjectStartDate.AddDays($offset)

        if ($adjustedStartDate -gt $earliestStartDate) {
            $earliestStartDate = $adjustedStartDate
        }
    }

    # S'assurer que la date de début n'est pas après la date de fin du projet
    if ($earliestStartDate -gt $ProjectEndDate) {
        $earliestStartDate = $ProjectEndDate.AddDays(-$MinDuration)
    }

    # Générer une date de début aléatoire
    $latestPossibleStartDate = $ProjectEndDate.AddDays(-$MinDuration)

    if ($earliestStartDate -gt $latestPossibleStartDate) {
        $startDate = $earliestStartDate
    } else {
        $startDate = Get-RandomDate -StartDate $earliestStartDate -EndDate $latestPossibleStartDate -ExcludeWeekends:$ExcludeWeekends -ExcludeHolidays:$ExcludeHolidays -HolidayDates $HolidayDates
    }

    # Générer une durée aléatoire
    $duration = Get-Random -Minimum $MinDuration -Maximum ($MaxDuration + 1)

    # Calculer la date de fin
    $endDate = $startDate.AddDays($duration)

    # S'assurer que la date de fin n'est pas après la date de fin du projet
    if ($endDate -gt $ProjectEndDate) {
        $endDate = $ProjectEndDate
        $duration = ($endDate - $startDate).Days
    }

    # Si la tâche a des enfants, ajuster la date de fin pour englober toutes les tâches enfants
    if ($ChildTasks.Count -gt 0) {
        $childrenEndDate = $ChildTasks |
            Where-Object { $_.Metadata -and $_.Metadata.ContainsKey("EndDate") } |
            ForEach-Object { [DateTime]::Parse($_.Metadata["EndDate"]) } |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty Maximum

        if ($childrenEndDate -and $childrenEndDate -gt $endDate) {
            $endDate = $childrenEndDate
            $duration = ($endDate - $startDate).Days
        }
    }

    # Retourner les dates générées
    return [PSCustomObject]@{
        StartDate = $startDate.ToString("yyyy-MM-dd")
        EndDate   = $endDate.ToString("yyyy-MM-dd")
        Duration  = $duration
    }
}

# Fonction pour générer des dates pour un ensemble de tâches
function New-TaskSetDates {
    <#
    .SYNOPSIS
        Génère des dates cohérentes pour un ensemble de tâches.

    .DESCRIPTION
        Cette fonction génère des dates de début et de fin cohérentes pour un ensemble de tâches,
        en respectant les dépendances et la hiérarchie entre les tâches.

    .PARAMETER Tasks
        L'ensemble de tâches pour lesquelles générer des dates.

    .PARAMETER ProjectStartDate
        La date de début du projet.

    .PARAMETER ProjectEndDate
        La date de fin du projet.

    .PARAMETER MinTaskDuration
        La durée minimale d'une tâche en jours.

    .PARAMETER MaxTaskDuration
        La durée maximale d'une tâche en jours.

    .PARAMETER ExcludeWeekends
        Indique si les weekends doivent être exclus des dates générées.

    .PARAMETER ExcludeHolidays
        Indique si les jours fériés doivent être exclus des dates générées.

    .PARAMETER HolidayDates
        Liste des dates de jours fériés à exclure.

    .PARAMETER DurationScalingByLevel
        Facteur d'échelle pour la durée des tâches en fonction de leur niveau hiérarchique.
        Par exemple, [1.0, 0.7, 0.5] signifie que les tâches de niveau 0 ont une durée normale,
        les tâches de niveau 1 ont une durée de 70% de la normale, et les tâches de niveau 2+
        ont une durée de 50% de la normale.

    .EXAMPLE
        $tasks = New-RandomTaskSet -TaskCount 100
        New-TaskSetDates -Tasks $tasks -ProjectStartDate (Get-Date) -ProjectEndDate (Get-Date).AddMonths(6)
        Génère des dates cohérentes pour un ensemble de 100 tâches.

    .OUTPUTS
        System.Array
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [DateTime]$ProjectStartDate = (Get-Date),

        [Parameter(Mandatory = $false)]
        [DateTime]$ProjectEndDate = (Get-Date).AddMonths(6),

        [Parameter(Mandatory = $false)]
        [int]$MinTaskDuration = 1,

        [Parameter(Mandatory = $false)]
        [int]$MaxTaskDuration = 30,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeWeekends,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeHolidays,

        [Parameter(Mandatory = $false)]
        [DateTime[]]$HolidayDates = @(),

        [Parameter(Mandatory = $false)]
        [double[]]$DurationScalingByLevel = @(1.0, 0.7, 0.5, 0.3, 0.2)
    )

    # Créer une copie des tâches pour ne pas modifier l'original
    $tasksCopy = $Tasks | ConvertTo-Json -Depth 10 | ConvertFrom-Json

    # Trier les tâches par niveau hiérarchique (de haut en bas)
    $sortedTasks = $tasksCopy | Sort-Object -Property IndentLevel

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $tasksCopy) {
        $tasksById[$task.Id] = $task

        # Initialiser le dictionnaire de métadonnées s'il n'existe pas
        if (-not $task.PSObject.Properties.Name.Contains("Metadata")) {
            Add-Member -InputObject $task -MemberType NoteProperty -Name "Metadata" -Value @{}
        } elseif ($null -eq $task.Metadata) {
            $task.Metadata = @{}
        }
    }

    # Générer les dates pour chaque tâche, en commençant par les tâches de niveau supérieur
    foreach ($task in $sortedTasks) {
        # Récupérer les tâches dont dépend celle-ci
        $dependsOnTasks = @()
        if ($task.Dependencies -and $task.Dependencies.Count -gt 0) {
            foreach ($depId in $task.Dependencies) {
                if ($tasksById.ContainsKey($depId)) {
                    $dependsOnTasks += $tasksById[$depId]
                }
            }
        }

        # Récupérer la tâche parente
        $parentTask = $null
        if ($task.ParentId -and $tasksById.ContainsKey($task.ParentId)) {
            $parentTask = $tasksById[$task.ParentId]
        }

        # Récupérer les tâches enfants
        $childTasks = @()
        foreach ($childId in $task.Children) {
            if ($tasksById.ContainsKey($childId)) {
                $childTasks += $tasksById[$childId]
            }
        }

        # Calculer les durées min et max en fonction du niveau hiérarchique
        $levelScaling = 1.0
        if ($task.IndentLevel -lt $DurationScalingByLevel.Length) {
            $levelScaling = $DurationScalingByLevel[$task.IndentLevel]
        } else {
            $levelScaling = $DurationScalingByLevel[-1]
        }

        $scaledMinDuration = [math]::Max(1, [math]::Round($MinTaskDuration * $levelScaling))
        $scaledMaxDuration = [math]::Max($scaledMinDuration, [math]::Round($MaxTaskDuration * $levelScaling))

        # Compter le nombre de tâches au même niveau
        $tasksAtSameLevel = $tasksCopy | Where-Object { $_.IndentLevel -eq $task.IndentLevel }
        $taskIndex = $tasksAtSameLevel.IndexOf($task)

        # Générer les dates pour cette tâche
        $dates = New-TaskDates -ProjectStartDate $ProjectStartDate -ProjectEndDate $ProjectEndDate `
            -MinDuration $scaledMinDuration -MaxDuration $scaledMaxDuration `
            -DependsOnTasks $dependsOnTasks -ParentTask $parentTask -ChildTasks $childTasks `
            -ExcludeWeekends:$ExcludeWeekends -ExcludeHolidays:$ExcludeHolidays -HolidayDates $HolidayDates `
            -TaskLevel $task.IndentLevel -TaskIndex $taskIndex -TotalTasksAtLevel $tasksAtSameLevel.Count

        # Ajouter les dates aux métadonnées de la tâche
        $task.Metadata["StartDate"] = $dates.StartDate
        $task.Metadata["EndDate"] = $dates.EndDate
        $task.Metadata["Duration"] = $dates.Duration
    }

    return $tasksCopy
}

# Fonction pour générer des jours fériés pour une année donnée
function Get-HolidayDates {
    <#
    .SYNOPSIS
        Génère une liste de jours fériés pour une année donnée.

    .DESCRIPTION
        Cette fonction génère une liste de jours fériés pour une année donnée,
        en fonction du pays spécifié.

    .PARAMETER Year
        L'année pour laquelle générer les jours fériés.

    .PARAMETER Country
        Le pays pour lequel générer les jours fériés. Les valeurs possibles sont "FR" (France), "US" (États-Unis), "UK" (Royaume-Uni).

    .EXAMPLE
        Get-HolidayDates -Year 2025 -Country "FR"
        Génère la liste des jours fériés français pour l'année 2025.

    .OUTPUTS
        System.DateTime[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Year = (Get-Date).Year,

        [Parameter(Mandatory = $false)]
        [ValidateSet("FR", "US", "UK")]
        [string]$Country = "FR"
    )

    $holidays = @()

    switch ($Country) {
        "FR" {
            # Jours fériés fixes en France
            $holidays += [DateTime]::new($Year, 1, 1)   # Jour de l'an
            $holidays += [DateTime]::new($Year, 5, 1)   # Fête du travail
            $holidays += [DateTime]::new($Year, 5, 8)   # Victoire 1945
            $holidays += [DateTime]::new($Year, 7, 14)  # Fête nationale
            $holidays += [DateTime]::new($Year, 8, 15)  # Assomption
            $holidays += [DateTime]::new($Year, 11, 1)  # Toussaint
            $holidays += [DateTime]::new($Year, 11, 11) # Armistice
            $holidays += [DateTime]::new($Year, 12, 25) # Noël

            # Jours fériés mobiles (Pâques et dérivés)
            # Calcul simplifié de Pâques (algorithme de Gauss)
            $a = $Year % 19
            $b = [math]::Floor($Year / 100)
            $c = $Year % 100
            $d = [math]::Floor($b / 4)
            $e = $b % 4
            $f = [math]::Floor(($b + 8) / 25)
            $g = [math]::Floor(($b - $f + 1) / 3)
            $h = (19 * $a + $b - $d - $g + 15) % 30
            $i = [math]::Floor($c / 4)
            $k = $c % 4
            $l = (32 + 2 * $e + 2 * $i - $h - $k) % 7
            $m = [math]::Floor(($a + 11 * $h + 22 * $l) / 451)
            $month = [math]::Floor(($h + $l - 7 * $m + 114) / 31)
            $day = (($h + $l - 7 * $m + 114) % 31) + 1

            $easter = [DateTime]::new($Year, $month, $day)
            $holidays += $easter                      # Pâques
            $holidays += $easter.AddDays(1)           # Lundi de Pâques
            $holidays += $easter.AddDays(39)          # Ascension
            $holidays += $easter.AddDays(50)          # Pentecôte
        }
        "US" {
            # Jours fériés fixes aux États-Unis
            $holidays += [DateTime]::new($Year, 1, 1)   # New Year's Day
            $holidays += [DateTime]::new($Year, 7, 4)   # Independence Day
            $holidays += [DateTime]::new($Year, 11, 11) # Veterans Day
            $holidays += [DateTime]::new($Year, 12, 25) # Christmas

            # Jours fériés mobiles
            # Martin Luther King Jr. Day (3ème lundi de janvier)
            $mlkDay = [DateTime]::new($Year, 1, 1)
            while ($mlkDay.DayOfWeek -ne [DayOfWeek]::Monday) {
                $mlkDay = $mlkDay.AddDays(1)
            }
            $mlkDay = $mlkDay.AddDays(14)
            $holidays += $mlkDay

            # Presidents' Day (3ème lundi de février)
            $presidentsDay = [DateTime]::new($Year, 2, 1)
            while ($presidentsDay.DayOfWeek -ne [DayOfWeek]::Monday) {
                $presidentsDay = $presidentsDay.AddDays(1)
            }
            $presidentsDay = $presidentsDay.AddDays(14)
            $holidays += $presidentsDay

            # Memorial Day (dernier lundi de mai)
            $memorialDay = [DateTime]::new($Year, 6, 1).AddDays(-1)
            while ($memorialDay.DayOfWeek -ne [DayOfWeek]::Monday) {
                $memorialDay = $memorialDay.AddDays(-1)
            }
            $holidays += $memorialDay

            # Labor Day (1er lundi de septembre)
            $laborDay = [DateTime]::new($Year, 9, 1)
            while ($laborDay.DayOfWeek -ne [DayOfWeek]::Monday) {
                $laborDay = $laborDay.AddDays(1)
            }
            $holidays += $laborDay

            # Columbus Day (2ème lundi d'octobre)
            $columbusDay = [DateTime]::new($Year, 10, 1)
            while ($columbusDay.DayOfWeek -ne [DayOfWeek]::Monday) {
                $columbusDay = $columbusDay.AddDays(1)
            }
            $columbusDay = $columbusDay.AddDays(7)
            $holidays += $columbusDay

            # Thanksgiving (4ème jeudi de novembre)
            $thanksgiving = [DateTime]::new($Year, 11, 1)
            while ($thanksgiving.DayOfWeek -ne [DayOfWeek]::Thursday) {
                $thanksgiving = $thanksgiving.AddDays(1)
            }
            $thanksgiving = $thanksgiving.AddDays(21)
            $holidays += $thanksgiving
        }
        "UK" {
            # Jours fériés fixes au Royaume-Uni
            $holidays += [DateTime]::new($Year, 1, 1)   # New Year's Day
            $holidays += [DateTime]::new($Year, 12, 25) # Christmas Day
            $holidays += [DateTime]::new($Year, 12, 26) # Boxing Day

            # Jours fériés mobiles
            # Early May Bank Holiday (1er lundi de mai)
            $earlyMay = [DateTime]::new($Year, 5, 1)
            while ($earlyMay.DayOfWeek -ne [DayOfWeek]::Monday) {
                $earlyMay = $earlyMay.AddDays(1)
            }
            $holidays += $earlyMay

            # Spring Bank Holiday (dernier lundi de mai)
            $springBank = [DateTime]::new($Year, 6, 1).AddDays(-1)
            while ($springBank.DayOfWeek -ne [DayOfWeek]::Monday) {
                $springBank = $springBank.AddDays(-1)
            }
            $holidays += $springBank

            # Summer Bank Holiday (dernier lundi d'août)
            $summerBank = [DateTime]::new($Year, 9, 1).AddDays(-1)
            while ($summerBank.DayOfWeek -ne [DayOfWeek]::Monday) {
                $summerBank = $summerBank.AddDays(-1)
            }
            $holidays += $summerBank

            # Calcul de Pâques (même algorithme que pour la France)
            $a = $Year % 19
            $b = [math]::Floor($Year / 100)
            $c = $Year % 100
            $d = [math]::Floor($b / 4)
            $e = $b % 4
            $f = [math]::Floor(($b + 8) / 25)
            $g = [math]::Floor(($b - $f + 1) / 3)
            $h = (19 * $a + $b - $d - $g + 15) % 30
            $i = [math]::Floor($c / 4)
            $k = $c % 4
            $l = (32 + 2 * $e + 2 * $i - $h - $k) % 7
            $m = [math]::Floor(($a + 11 * $h + 22 * $l) / 451)
            $month = [math]::Floor(($h + $l - 7 * $m + 114) / 31)
            $day = (($h + $l - 7 * $m + 114) % 31) + 1

            $easter = [DateTime]::new($Year, $month, $day)
            $holidays += $easter.AddDays(-2)  # Good Friday
            $holidays += $easter.AddDays(1)   # Easter Monday
        }
    }

    return $holidays | Sort-Object
}

# Fonction pour générer des dates de début et de fin respectant des contraintes spécifiques
function New-ConstrainedTaskDates {
    <#
    .SYNOPSIS
        Génère des dates de début et de fin pour une tâche en respectant des contraintes spécifiques.

    .DESCRIPTION
        Cette fonction étend New-TaskDates en ajoutant des contraintes supplémentaires comme
        les jours de la semaine autorisés, les plages horaires, les périodes interdites, etc.

    .PARAMETER ProjectStartDate
        La date de début du projet.

    .PARAMETER ProjectEndDate
        La date de fin du projet.

    .PARAMETER MinDuration
        La durée minimale de la tâche en jours.

    .PARAMETER MaxDuration
        La durée maximale de la tâche en jours.

    .PARAMETER AllowedDaysOfWeek
        Les jours de la semaine autorisés pour la tâche (par défaut, tous les jours).
        Exemple: @([DayOfWeek]::Monday, [DayOfWeek]::Wednesday, [DayOfWeek]::Friday)

    .PARAMETER ForbiddenDateRanges
        Les plages de dates interdites pour la tâche.
        Format: tableau de hashtables avec les clés StartDate et EndDate.
        Exemple: @(@{StartDate="2025-06-01"; EndDate="2025-06-15"}, @{StartDate="2025-07-15"; EndDate="2025-07-30"})

    .PARAMETER PreferredDateRanges
        Les plages de dates préférées pour la tâche.
        Format: tableau de hashtables avec les clés StartDate et EndDate.
        Exemple: @(@{StartDate="2025-05-01"; EndDate="2025-05-15"}, @{StartDate="2025-08-01"; EndDate="2025-08-15"})

    .PARAMETER MaxAttempts
        Le nombre maximum de tentatives pour trouver une date valide.

    .PARAMETER DependsOnTasks
        Liste des tâches dont dépend la tâche actuelle.

    .PARAMETER ParentTask
        La tâche parente de la tâche actuelle.

    .PARAMETER ChildTasks
        Liste des tâches enfants de la tâche actuelle.

    .PARAMETER ExcludeWeekends
        Indique si les weekends doivent être exclus des dates générées.

    .PARAMETER ExcludeHolidays
        Indique si les jours fériés doivent être exclus des dates générées.

    .PARAMETER HolidayDates
        Liste des dates de jours fériés à exclure.

    .EXAMPLE
        New-ConstrainedTaskDates -ProjectStartDate (Get-Date) -ProjectEndDate (Get-Date).AddMonths(6) `
            -MinDuration 3 -MaxDuration 14 `
            -AllowedDaysOfWeek @([DayOfWeek]::Monday, [DayOfWeek]::Tuesday, [DayOfWeek]::Wednesday) `
            -ForbiddenDateRanges @(@{StartDate="2025-06-01"; EndDate="2025-06-15"})

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DateTime]$ProjectStartDate,

        [Parameter(Mandatory = $true)]
        [DateTime]$ProjectEndDate,

        [Parameter(Mandatory = $false)]
        [int]$MinDuration = 1,

        [Parameter(Mandatory = $false)]
        [int]$MaxDuration = 30,

        [Parameter(Mandatory = $false)]
        [DayOfWeek[]]$AllowedDaysOfWeek = @([DayOfWeek]::Monday, [DayOfWeek]::Tuesday, [DayOfWeek]::Wednesday,
            [DayOfWeek]::Thursday, [DayOfWeek]::Friday, [DayOfWeek]::Saturday,
            [DayOfWeek]::Sunday),

        [Parameter(Mandatory = $false)]
        [hashtable[]]$ForbiddenDateRanges = @(),

        [Parameter(Mandatory = $false)]
        [hashtable[]]$PreferredDateRanges = @(),

        [Parameter(Mandatory = $false)]
        [int]$MaxAttempts = 200,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$DependsOnTasks = @(),

        [Parameter(Mandatory = $false)]
        [PSObject]$ParentTask = $null,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$ChildTasks = @(),

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeWeekends,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeHolidays,

        [Parameter(Mandatory = $false)]
        [DateTime[]]$HolidayDates = @(),

        [Parameter(Mandatory = $false)]
        [int]$TaskLevel = 0,

        [Parameter(Mandatory = $false)]
        [int]$TaskIndex = 0,

        [Parameter(Mandatory = $false)]
        [int]$TotalTasksAtLevel = 1
    )

    # Déterminer la date de début la plus tardive des tâches dont dépend celle-ci
    $earliestStartDate = $ProjectStartDate

    if ($DependsOnTasks.Count -gt 0) {
        $dependenciesEndDate = $DependsOnTasks |
            Where-Object { $_.Metadata -and $_.Metadata.ContainsKey("EndDate") } |
            ForEach-Object { [DateTime]::Parse($_.Metadata["EndDate"]) } |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty Maximum

        if ($dependenciesEndDate) {
            $earliestStartDate = $dependenciesEndDate.AddDays(1)
        }
    }

    # Si la tâche a un parent, s'assurer qu'elle commence après le début du parent
    if ($ParentTask -and $ParentTask.Metadata -and $ParentTask.Metadata.ContainsKey("StartDate")) {
        $parentStartDate = [DateTime]::Parse($ParentTask.Metadata["StartDate"])

        if ($parentStartDate -gt $earliestStartDate) {
            $earliestStartDate = $parentStartDate
        }
    }

    # Fonction pour vérifier si une date est dans une plage interdite
    function Test-DateInForbiddenRange {
        param (
            [DateTime]$Date,
            [hashtable[]]$ForbiddenRanges
        )

        foreach ($range in $ForbiddenRanges) {
            $rangeStart = [DateTime]::Parse($range.StartDate)
            $rangeEnd = [DateTime]::Parse($range.EndDate)

            if ($Date -ge $rangeStart -and $Date -le $rangeEnd) {
                return $true
            }
        }

        return $false
    }

    # Fonction pour vérifier si une date est dans une plage préférée
    function Test-DateInPreferredRange {
        param (
            [DateTime]$Date,
            [hashtable[]]$PreferredRanges
        )

        foreach ($range in $PreferredRanges) {
            $rangeStart = [DateTime]::Parse($range.StartDate)
            $rangeEnd = [DateTime]::Parse($range.EndDate)

            if ($Date -ge $rangeStart -and $Date -le $rangeEnd) {
                return $true
            }
        }

        return $false
    }

    # Générer une date de début valide
    $startDate = $null
    $isValidStartDate = $false
    $attempts = 0

    while (-not $isValidStartDate -and $attempts -lt $MaxAttempts) {
        # Générer une date candidate
        $latestPossibleStartDate = $ProjectEndDate.AddDays(-$MinDuration)

        if ($earliestStartDate -gt $latestPossibleStartDate) {
            $startDateCandidate = $earliestStartDate
            # Si on ne peut pas respecter la durée minimale, on arrête les tentatives
            break
        } else {
            # Essayer d'abord dans les plages préférées si elles existent
            if ($PreferredDateRanges.Count -gt 0 -and $attempts -lt ($MaxAttempts / 2)) {
                $preferredRangeIndex = $attempts % $PreferredDateRanges.Count
                $preferredRange = $PreferredDateRanges[$preferredRangeIndex]
                $preferredStart = [DateTime]::Parse($preferredRange.StartDate)
                $preferredEnd = [DateTime]::Parse($preferredRange.EndDate)

                # Ajuster les dates préférées en fonction des contraintes du projet
                if ($preferredStart -lt $earliestStartDate) {
                    $preferredStart = $earliestStartDate
                }
                if ($preferredEnd -gt $latestPossibleStartDate) {
                    $preferredEnd = $latestPossibleStartDate
                }

                # Vérifier si la plage préférée ajustée est valide
                if ($preferredStart -le $preferredEnd) {
                    $startDateCandidate = Get-RandomDate -StartDate $preferredStart -EndDate $preferredEnd -ExcludeWeekends:$ExcludeWeekends -ExcludeHolidays:$ExcludeHolidays -HolidayDates $HolidayDates
                } else {
                    # Si la plage préférée n'est pas valide, utiliser la plage complète
                    $startDateCandidate = Get-RandomDate -StartDate $earliestStartDate -EndDate $latestPossibleStartDate -ExcludeWeekends:$ExcludeWeekends -ExcludeHolidays:$ExcludeHolidays -HolidayDates $HolidayDates
                }
            } else {
                # Utiliser la plage complète
                $startDateCandidate = Get-RandomDate -StartDate $earliestStartDate -EndDate $latestPossibleStartDate -ExcludeWeekends:$ExcludeWeekends -ExcludeHolidays:$ExcludeHolidays -HolidayDates $HolidayDates
            }
        }

        # Vérifier si la date est dans un jour de la semaine autorisé
        $isAllowedDayOfWeek = $AllowedDaysOfWeek -contains $startDateCandidate.DayOfWeek

        # Vérifier si la date est dans une plage interdite
        $isInForbiddenRange = Test-DateInForbiddenRange -Date $startDateCandidate -ForbiddenRanges $ForbiddenDateRanges

        # La date est valide si elle est dans un jour autorisé et pas dans une plage interdite
        $isValidStartDate = $isAllowedDayOfWeek -and (-not $isInForbiddenRange)

        if ($isValidStartDate) {
            $startDate = $startDateCandidate
        }

        $attempts++
    }

    # Si on n'a pas trouvé de date valide, utiliser la date de début la plus tardive des dépendances
    if (-not $isValidStartDate) {
        Write-Warning "Impossible de trouver une date de début valide après $MaxAttempts tentatives. Utilisation de la date de début la plus tardive des dépendances."
        $startDate = $earliestStartDate
    }

    # Générer une durée aléatoire
    $duration = Get-Random -Minimum $MinDuration -Maximum ($MaxDuration + 1)

    # Calculer la date de fin
    $endDate = $startDate.AddDays($duration)

    # S'assurer que la date de fin n'est pas après la date de fin du projet
    if ($endDate -gt $ProjectEndDate) {
        $endDate = $ProjectEndDate
        $duration = ($endDate - $startDate).Days
    }

    # Si la tâche a des enfants, ajuster la date de fin pour englober toutes les tâches enfants
    if ($ChildTasks.Count -gt 0) {
        $childrenEndDate = $ChildTasks |
            Where-Object { $_.Metadata -and $_.Metadata.ContainsKey("EndDate") } |
            ForEach-Object { [DateTime]::Parse($_.Metadata["EndDate"]) } |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty Maximum

        if ($childrenEndDate -and $childrenEndDate -gt $endDate) {
            $endDate = $childrenEndDate
            $duration = ($endDate - $startDate).Days
        }
    }

    # Retourner les dates générées
    return [PSCustomObject]@{
        StartDate = $startDate.ToString("yyyy-MM-dd")
        EndDate   = $endDate.ToString("yyyy-MM-dd")
        Duration  = $duration
        IsValid   = $isValidStartDate
    }
}

# Fonction pour calculer automatiquement la durée d'une tâche
function Get-TaskDuration {
    <#
    .SYNOPSIS
        Calcule automatiquement la durée optimale d'une tâche en fonction de divers facteurs.

    .DESCRIPTION
        Cette fonction calcule la durée optimale d'une tâche en fonction de sa complexité,
        des ressources disponibles, de son niveau hiérarchique, etc.

    .PARAMETER Complexity
        La complexité de la tâche (1-10).

    .PARAMETER Resources
        Le nombre de ressources disponibles pour la tâche.

    .PARAMETER TaskLevel
        Le niveau hiérarchique de la tâche (0 = racine, 1 = premier niveau, etc.).

    .PARAMETER TaskType
        Le type de tâche (Développement, Documentation, Test, etc.).

    .PARAMETER BaseDuration
        La durée de base pour une tâche de complexité moyenne (5) avec une ressource.

    .PARAMETER ComplexityFactor
        Le facteur multiplicateur pour la complexité. Par défaut, chaque point de complexité
        augmente la durée de 20% par rapport à la complexité moyenne (5).

    .PARAMETER ResourcesFactor
        Le facteur de réduction pour les ressources. Par défaut, chaque ressource supplémentaire
        réduit la durée de 10%, avec un minimum de 50% de la durée initiale.

    .PARAMETER LevelFactor
        Le facteur de réduction pour le niveau hiérarchique. Par défaut, chaque niveau supplémentaire
        réduit la durée de 20%.

    .PARAMETER TypeFactors
        Les facteurs multiplicateurs pour chaque type de tâche.
        Par défaut: Développement (1.0), Documentation (0.7), Test (0.8), Analyse (0.6), Conception (0.9).

    .PARAMETER MinDuration
        La durée minimale d'une tâche, quelle que soit sa complexité ou ses ressources.

    .PARAMETER MaxDuration
        La durée maximale d'une tâche, quelle que soit sa complexité ou ses ressources.

    .EXAMPLE
        Get-TaskDuration -Complexity 7 -Resources 2 -TaskLevel 1 -TaskType "Développement"
        Calcule la durée optimale pour une tâche de développement de complexité 7, avec 2 ressources, au niveau 1.

    .OUTPUTS
        System.Int32
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 10)]
        [int]$Complexity,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$Resources = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$TaskLevel = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Developpement", "Documentation", "Test", "Analyse", "Conception", "Autre")]
        [string]$TaskType = "Developpement",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 365)]
        [int]$BaseDuration = 10,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 10.0)]
        [double]$ComplexityFactor = 0.2,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 1.0)]
        [double]$ResourcesFactor = 0.1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 1.0)]
        [double]$LevelFactor = 0.2,

        [Parameter(Mandatory = $false)]
        [hashtable]$TypeFactors = @{
            "Developpement" = 1.0
            "Documentation" = 0.7
            "Test"          = 0.8
            "Analyse"       = 0.6
            "Conception"    = 0.9
            "Autre"         = 1.0
        },

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 365)]
        [int]$MinDuration = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 365)]
        [int]$MaxDuration = 60
    )

    # Calculer le facteur de complexité
    $complexityMultiplier = 1.0 + ($Complexity - 5) * $ComplexityFactor

    # Calculer le facteur de ressources
    $resourcesMultiplier = [Math]::Max(0.5, 1.0 - ($Resources - 1) * $ResourcesFactor)

    # Calculer le facteur de niveau hiérarchique
    $levelMultiplier = [Math]::Max(0.2, 1.0 - $TaskLevel * $LevelFactor)

    # Obtenir le facteur de type de tâche
    $typeMultiplier = 1.0
    if ($TypeFactors.ContainsKey($TaskType)) {
        $typeMultiplier = $TypeFactors[$TaskType]
    }

    # Calculer la durée
    $duration = $BaseDuration * $complexityMultiplier * $resourcesMultiplier * $levelMultiplier * $typeMultiplier

    # Arrondir et limiter la durée
    $roundedDuration = [Math]::Round($duration)
    $clampedDuration = [Math]::Max($MinDuration, [Math]::Min($roundedDuration, $MaxDuration))

    return $clampedDuration
}

# Fonction pour convertir une durée entre différentes unités de temps
function Convert-Duration {
    <#
    .SYNOPSIS
        Convertit une durée entre différentes unités de temps.

    .DESCRIPTION
        Cette fonction convertit une durée d'une unité de temps à une autre.
        Les unités supportées sont: Minutes, Heures, Jours, Semaines, Mois.

    .PARAMETER Value
        La valeur de la durée à convertir.

    .PARAMETER FromUnit
        L'unité de temps source.

    .PARAMETER ToUnit
        L'unité de temps cible.

    .PARAMETER WorkHoursPerDay
        Le nombre d'heures de travail par jour. Par défaut: 8.

    .PARAMETER WorkDaysPerWeek
        Le nombre de jours de travail par semaine. Par défaut: 5.

    .PARAMETER WorkDaysPerMonth
        Le nombre de jours de travail par mois. Par défaut: 21.

    .EXAMPLE
        Convert-Duration -Value 16 -FromUnit "Heures" -ToUnit "Jours"
        Convertit 16 heures en jours (2 jours avec 8 heures de travail par jour).

    .OUTPUTS
        System.Double
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Minutes", "Heures", "Jours", "Semaines", "Mois")]
        [string]$FromUnit,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Minutes", "Heures", "Jours", "Semaines", "Mois")]
        [string]$ToUnit,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 24)]
        [int]$WorkHoursPerDay = 8,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 7)]
        [int]$WorkDaysPerWeek = 5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 31)]
        [int]$WorkDaysPerMonth = 21
    )

    # Convertir en minutes (unité de base)
    $minutes = 0

    switch ($FromUnit) {
        "Minutes" { $minutes = $Value }
        "Heures" { $minutes = $Value * 60 }
        "Jours" { $minutes = $Value * $WorkHoursPerDay * 60 }
        "Semaines" { $minutes = $Value * $WorkDaysPerWeek * $WorkHoursPerDay * 60 }
        "Mois" { $minutes = $Value * $WorkDaysPerMonth * $WorkHoursPerDay * 60 }
    }

    # Convertir de minutes vers l'unité cible
    $result = 0

    switch ($ToUnit) {
        "Minutes" { $result = $minutes }
        "Heures" { $result = $minutes / 60 }
        "Jours" { $result = $minutes / (60 * $WorkHoursPerDay) }
        "Semaines" { $result = $minutes / (60 * $WorkHoursPerDay * $WorkDaysPerWeek) }
        "Mois" { $result = $minutes / (60 * $WorkHoursPerDay * $WorkDaysPerMonth) }
    }

    return $result
}

# Fonction pour estimer la durée d'une tâche en fonction de tâches similaires
function Get-EstimatedTaskDuration {
    <#
    .SYNOPSIS
        Estime la durée d'une tâche en fonction de tâches similaires.

    .DESCRIPTION
        Cette fonction estime la durée d'une tâche en analysant les durées de tâches similaires
        (même type, complexité proche, etc.) et en calculant une moyenne pondérée.

    .PARAMETER SimilarTasks
        Un tableau de tâches similaires avec leurs durées.
        Format: @(@{Complexity=5; Duration=10; Weight=1}, @{Complexity=6; Duration=12; Weight=0.8}, ...)

    .PARAMETER Complexity
        La complexité de la tâche à estimer (1-10).

    .PARAMETER TaskType
        Le type de tâche à estimer.

    .PARAMETER DefaultDuration
        La durée par défaut à utiliser si aucune tâche similaire n'est trouvée.

    .PARAMETER ComplexityTolerance
        La tolérance de complexité pour considérer une tâche comme similaire.
        Par exemple, avec une tolérance de 2, une tâche de complexité 5 sera considérée
        comme similaire à des tâches de complexité 3 à 7.

    .PARAMETER MinSimilarTasks
        Le nombre minimum de tâches similaires nécessaires pour faire une estimation fiable.
        Si moins de tâches sont trouvées, la durée par défaut sera utilisée.

    .EXAMPLE
        $similarTasks = @(
            @{Complexity=5; Duration=10; Weight=1},
            @{Complexity=6; Duration=12; Weight=0.8},
            @{Complexity=4; Duration=8; Weight=0.9}
        )
        Get-EstimatedTaskDuration -SimilarTasks $similarTasks -Complexity 5 -TaskType "Développement"
        Estime la durée d'une tâche de développement de complexité 5 en fonction de tâches similaires.

    .OUTPUTS
        System.Int32
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable[]]$SimilarTasks,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 10)]
        [int]$Complexity,

        [Parameter(Mandatory = $false)]
        [string]$TaskType = "Développement",

        [Parameter(Mandatory = $false)]
        [int]$DefaultDuration = 10,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$ComplexityTolerance = 2,

        [Parameter(Mandatory = $false)]
        [int]$MinSimilarTasks = 3
    )

    # Filtrer les tâches similaires par type et complexité
    $filteredTasks = $SimilarTasks | Where-Object {
        ($_.TaskType -eq $TaskType -or [string]::IsNullOrEmpty($_.TaskType)) -and
        [Math]::Abs($_.Complexity - $Complexity) -le $ComplexityTolerance
    }

    # Si pas assez de tâches similaires, utiliser la durée par défaut
    if ($filteredTasks.Count -lt $MinSimilarTasks) {
        Write-Verbose "Pas assez de tâches similaires trouvées ($($filteredTasks.Count) < $MinSimilarTasks). Utilisation de la durée par défaut."
        return $DefaultDuration
    }

    # Calculer la moyenne pondérée des durées
    $totalWeight = 0
    $weightedSum = 0

    foreach ($task in $filteredTasks) {
        $weight = 1.0
        if ($task.ContainsKey("Weight")) {
            $weight = $task.Weight
        } else {
            # Calculer un poids basé sur la similarité de complexité
            $complexityDiff = [Math]::Abs($task.Complexity - $Complexity)
            $weight = 1.0 - ($complexityDiff / ($ComplexityTolerance + 1))
        }

        $totalWeight += $weight
        $weightedSum += $task.Duration * $weight
    }

    # Calculer la moyenne pondérée
    $estimatedDuration = [Math]::Round($weightedSum / $totalWeight)

    return $estimatedDuration
}

# Fonction pour ajouter une dépendance temporelle entre deux tâches
function Add-TaskDependency {
    <#
    .SYNOPSIS
        Ajoute une dépendance temporelle entre deux tâches.

    .DESCRIPTION
        Cette fonction ajoute une dépendance temporelle entre deux tâches, en spécifiant
        le type de dépendance (fin-début, début-début, etc.) et le délai éventuel.

    .PARAMETER SourceTask
        La tâche source de la dépendance.

    .PARAMETER TargetTask
        La tâche cible de la dépendance.

    .PARAMETER DependencyType
        Le type de dépendance:
        - FinishToStart (FS): La tâche cible ne peut commencer qu'après la fin de la tâche source.
        - StartToStart (SS): La tâche cible ne peut commencer qu'après le début de la tâche source.
        - FinishToFinish (FF): La tâche cible ne peut finir qu'après la fin de la tâche source.
        - StartToFinish (SF): La tâche cible ne peut finir qu'après le début de la tâche source.

    .PARAMETER Delay
        Le délai (en jours) à appliquer à la dépendance. Peut être négatif pour un chevauchement.

    .PARAMETER Force
        Indique si la dépendance doit être forcée même si elle crée une dépendance circulaire.
        Attention: cela peut créer des incohérences dans le planning.

    .EXAMPLE
        Add-TaskDependency -SourceTask $task1 -TargetTask $task2 -DependencyType "FinishToStart" -Delay 2
        Ajoute une dépendance fin-début entre $task1 et $task2, avec un délai de 2 jours.

    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$SourceTask,

        [Parameter(Mandatory = $true)]
        [PSObject]$TargetTask,

        [Parameter(Mandatory = $false)]
        [ValidateSet("FinishToStart", "StartToStart", "FinishToFinish", "StartToFinish")]
        [string]$DependencyType = "FinishToStart",

        [Parameter(Mandatory = $false)]
        [int]$Delay = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier que les tâches ne sont pas identiques
    if ($SourceTask.Id -eq $TargetTask.Id) {
        Write-Error "Une tâche ne peut pas dépendre d'elle-même."
        return $false
    }

    # Vérifier si la dépendance crée un cycle (sauf si Force est spécifié)
    if (-not $Force) {
        $visited = @{}
        $stack = @($TargetTask.Id)

        while ($stack.Count -gt 0) {
            $currentId = $stack[-1]
            $stack = $stack[0..($stack.Count - 2)]

            if (-not $visited.ContainsKey($currentId)) {
                $visited[$currentId] = $true

                $currentTask = $null
                if ($currentId -eq $TargetTask.Id) {
                    $currentTask = $TargetTask
                } elseif ($currentId -eq $SourceTask.Id) {
                    $currentTask = $SourceTask
                } else {
                    # Trouver la tâche dans le contexte global (à adapter selon votre structure)
                    # Cette partie dépend de comment vous stockez vos tâches
                    # Par exemple, si vous avez un dictionnaire global $tasksById:
                    # $currentTask = $tasksById[$currentId]

                    # Pour cet exemple, on suppose que la tâche n'est pas trouvée
                    continue
                }

                if ($currentTask -and $currentTask.Dependencies) {
                    foreach ($depId in $currentTask.Dependencies) {
                        if ($depId -eq $SourceTask.Id) {
                            Write-Error "La dépendance créerait un cycle. Utilisez -Force pour forcer l'ajout."
                            return $false
                        }

                        $stack += $depId
                    }
                }
            }
        }
    }

    # Initialiser les collections de dépendances si elles n'existent pas
    if (-not $TargetTask.PSObject.Properties.Name.Contains("Dependencies")) {
        Add-Member -InputObject $TargetTask -MemberType NoteProperty -Name "Dependencies" -Value @()
    }

    if (-not $SourceTask.PSObject.Properties.Name.Contains("DependentTasks")) {
        Add-Member -InputObject $SourceTask -MemberType NoteProperty -Name "DependentTasks" -Value @()
    }

    # Initialiser les métadonnées si elles n'existent pas
    if (-not $TargetTask.PSObject.Properties.Name.Contains("Metadata")) {
        Add-Member -InputObject $TargetTask -MemberType NoteProperty -Name "Metadata" -Value @{}
    }

    if (-not $SourceTask.PSObject.Properties.Name.Contains("Metadata")) {
        Add-Member -InputObject $SourceTask -MemberType NoteProperty -Name "Metadata" -Value @{}
    }

    # Ajouter la dépendance
    if (-not $TargetTask.Dependencies.Contains($SourceTask.Id)) {
        $TargetTask.Dependencies += $SourceTask.Id
    }

    if (-not $SourceTask.DependentTasks.Contains($TargetTask.Id)) {
        $SourceTask.DependentTasks += $TargetTask.Id
    }

    # Stocker les informations de dépendance dans les métadonnées
    if (-not $TargetTask.Metadata.ContainsKey("DependencyDetails")) {
        $TargetTask.Metadata["DependencyDetails"] = @{}
    }

    $TargetTask.Metadata["DependencyDetails"][$SourceTask.Id] = @{
        Type  = $DependencyType
        Delay = $Delay
    }

    # Mettre à jour les dates en fonction du type de dépendance
    if ($SourceTask.Metadata.ContainsKey("StartDate") -and $SourceTask.Metadata.ContainsKey("EndDate") -and
        $TargetTask.Metadata.ContainsKey("StartDate") -and $TargetTask.Metadata.ContainsKey("EndDate")) {

        $sourceStartDate = [DateTime]::Parse($SourceTask.Metadata["StartDate"])
        $sourceEndDate = [DateTime]::Parse($SourceTask.Metadata["EndDate"])
        $targetStartDate = [DateTime]::Parse($TargetTask.Metadata["StartDate"])
        $targetEndDate = [DateTime]::Parse($TargetTask.Metadata["EndDate"])

        $newTargetStartDate = $targetStartDate
        $newTargetEndDate = $targetEndDate
        $duration = ($targetEndDate - $targetStartDate).Days

        switch ($DependencyType) {
            "FinishToStart" {
                $newTargetStartDate = $sourceEndDate.AddDays($Delay)
                $newTargetEndDate = $newTargetStartDate.AddDays($duration)
            }
            "StartToStart" {
                $newTargetStartDate = $sourceStartDate.AddDays($Delay)
                $newTargetEndDate = $newTargetStartDate.AddDays($duration)
            }
            "FinishToFinish" {
                $newTargetEndDate = $sourceEndDate.AddDays($Delay)
                $newTargetStartDate = $newTargetEndDate.AddDays(-$duration)
            }
            "StartToFinish" {
                $newTargetEndDate = $sourceStartDate.AddDays($Delay)
                $newTargetStartDate = $newTargetEndDate.AddDays(-$duration)
            }
        }

        # Mettre à jour les dates de la tâche cible
        $TargetTask.Metadata["StartDate"] = $newTargetStartDate.ToString("yyyy-MM-dd")
        $TargetTask.Metadata["EndDate"] = $newTargetEndDate.ToString("yyyy-MM-dd")
    }

    return $true
}

# Fonction pour valider les dépendances temporelles d'un ensemble de tâches
function Test-TaskDependencies {
    <#
    .SYNOPSIS
        Valide les dépendances temporelles d'un ensemble de tâches.

    .DESCRIPTION
        Cette fonction vérifie la cohérence des dépendances temporelles d'un ensemble de tâches,
        en détectant les cycles, les incohérences de dates, etc.

    .PARAMETER Tasks
        L'ensemble de tâches à valider.

    .PARAMETER FixInconsistencies
        Indique si les incohérences détectées doivent être corrigées automatiquement.

    .PARAMETER ValidateOnly
        Indique si la fonction doit uniquement valider les dépendances sans les corriger.

    .EXAMPLE
        Test-TaskDependencies -Tasks $tasks -FixInconsistencies
        Valide et corrige les dépendances temporelles de l'ensemble de tâches $tasks.

    .OUTPUTS
        System.Collections.Hashtable
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [switch]$FixInconsistencies,

        [Parameter(Mandatory = $false)]
        [switch]$ValidateOnly
    )

    $result = @{
        IsValid             = $true
        Cycles              = @()
        DateInconsistencies = @()
        MissingDependencies = @()
        FixedIssues         = 0
    }

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $tasksById[$task.Id] = $task
    }

    # Fonction récursive pour détecter les cycles
    function Find-Cycles {
        param (
            [string]$TaskId,
            [hashtable]$Visited,
            [hashtable]$RecStack,
            [array]$Path
        )

        # Marquer le nœud comme visité et l'ajouter à la pile de récursion
        $Visited[$TaskId] = $true
        $RecStack[$TaskId] = $true
        $currentPath = $Path + $TaskId

        # Récupérer la tâche
        $task = $tasksById[$TaskId]

        # Parcourir toutes les dépendances
        if ($task.Dependencies) {
            foreach ($depId in $task.Dependencies) {
                # Si la dépendance n'a pas été visitée, l'explorer récursivement
                if (-not $Visited.ContainsKey($depId)) {
                    $cycleFound = Find-Cycles -TaskId $depId -Visited $Visited -RecStack $RecStack -Path $currentPath
                    if ($cycleFound) {
                        return $true
                    }
                }
                # Si la dépendance est dans la pile de récursion, un cycle a été trouvé
                elseif ($RecStack[$depId]) {
                    $cycleIndex = $currentPath.IndexOf($depId)
                    $cycle = $currentPath[$cycleIndex..$currentPath.Count] + $depId
                    $result.Cycles += $cycle
                    return $true
                }
            }
        }

        # Retirer le nœud de la pile de récursion
        $RecStack[$TaskId] = $false
        return $false
    }

    # Détecter les cycles
    $visited = @{}
    $recStack = @{}
    foreach ($task in $Tasks) {
        if (-not $visited.ContainsKey($task.Id)) {
            Find-Cycles -TaskId $task.Id -Visited $visited -RecStack $recStack -Path @()
        }
    }

    # Vérifier les incohérences de dates
    foreach ($task in $Tasks) {
        if ($task.Dependencies -and $task.Metadata -and $task.Metadata.ContainsKey("StartDate") -and $task.Metadata.ContainsKey("EndDate")) {
            $taskStartDate = [DateTime]::Parse($task.Metadata["StartDate"])

            foreach ($depId in $task.Dependencies) {
                if ($tasksById.ContainsKey($depId)) {
                    $depTask = $tasksById[$depId]

                    if ($depTask.Metadata -and $depTask.Metadata.ContainsKey("EndDate")) {
                        $depEndDate = [DateTime]::Parse($depTask.Metadata["EndDate"])

                        # Vérifier le type de dépendance
                        $dependencyType = "FinishToStart" # Type par défaut
                        $delay = 0

                        if ($task.Metadata.ContainsKey("DependencyDetails") -and $task.Metadata["DependencyDetails"].ContainsKey($depId)) {
                            $dependencyDetails = $task.Metadata["DependencyDetails"][$depId]
                            $dependencyType = $dependencyDetails.Type
                            $delay = $dependencyDetails.Delay
                        }

                        $isConsistent = $true
                        $inconsistencyMessage = ""

                        switch ($dependencyType) {
                            "FinishToStart" {
                                if ($taskStartDate -lt $depEndDate.AddDays($delay)) {
                                    $isConsistent = $false
                                    $inconsistencyMessage = "La tâche $($task.Id) commence avant la fin de sa dépendance $depId (+ $delay jours)."

                                    if ($FixInconsistencies -and -not $ValidateOnly) {
                                        $newStartDate = $depEndDate.AddDays($delay)
                                        $duration = ([DateTime]::Parse($task.Metadata["EndDate"]) - $taskStartDate).Days
                                        $task.Metadata["StartDate"] = $newStartDate.ToString("yyyy-MM-dd")
                                        $task.Metadata["EndDate"] = $newStartDate.AddDays($duration).ToString("yyyy-MM-dd")
                                        $result.FixedIssues++
                                    }
                                }
                            }
                            "StartToStart" {
                                $depStartDate = [DateTime]::Parse($depTask.Metadata["StartDate"])
                                if ($taskStartDate -lt $depStartDate.AddDays($delay)) {
                                    $isConsistent = $false
                                    $inconsistencyMessage = "La tâche $($task.Id) commence avant le début de sa dépendance $depId (+ $delay jours)."

                                    if ($FixInconsistencies -and -not $ValidateOnly) {
                                        $newStartDate = $depStartDate.AddDays($delay)
                                        $duration = ([DateTime]::Parse($task.Metadata["EndDate"]) - $taskStartDate).Days
                                        $task.Metadata["StartDate"] = $newStartDate.ToString("yyyy-MM-dd")
                                        $task.Metadata["EndDate"] = $newStartDate.AddDays($duration).ToString("yyyy-MM-dd")
                                        $result.FixedIssues++
                                    }
                                }
                            }
                            "FinishToFinish" {
                                $taskEndDate = [DateTime]::Parse($task.Metadata["EndDate"])
                                if ($taskEndDate -lt $depEndDate.AddDays($delay)) {
                                    $isConsistent = $false
                                    $inconsistencyMessage = "La tâche $($task.Id) se termine avant la fin de sa dépendance $depId (+ $delay jours)."

                                    if ($FixInconsistencies -and -not $ValidateOnly) {
                                        $newEndDate = $depEndDate.AddDays($delay)
                                        $duration = ($taskEndDate - $taskStartDate).Days
                                        $task.Metadata["EndDate"] = $newEndDate.ToString("yyyy-MM-dd")
                                        $task.Metadata["StartDate"] = $newEndDate.AddDays(-$duration).ToString("yyyy-MM-dd")
                                        $result.FixedIssues++
                                    }
                                }
                            }
                            "StartToFinish" {
                                $depStartDate = [DateTime]::Parse($depTask.Metadata["StartDate"])
                                $taskEndDate = [DateTime]::Parse($task.Metadata["EndDate"])
                                if ($taskEndDate -lt $depStartDate.AddDays($delay)) {
                                    $isConsistent = $false
                                    $inconsistencyMessage = "La tâche $($task.Id) se termine avant le début de sa dépendance $depId (+ $delay jours)."

                                    if ($FixInconsistencies -and -not $ValidateOnly) {
                                        $newEndDate = $depStartDate.AddDays($delay)
                                        $duration = ($taskEndDate - $taskStartDate).Days
                                        $task.Metadata["EndDate"] = $newEndDate.ToString("yyyy-MM-dd")
                                        $task.Metadata["StartDate"] = $newEndDate.AddDays(-$duration).ToString("yyyy-MM-dd")
                                        $result.FixedIssues++
                                    }
                                }
                            }
                        }

                        if (-not $isConsistent) {
                            $result.DateInconsistencies += @{
                                TaskId       = $task.Id
                                DependencyId = $depId
                                Type         = $dependencyType
                                Message      = $inconsistencyMessage
                            }
                            $result.IsValid = $false
                        }
                    } else {
                        $result.MissingDependencies += @{
                            TaskId       = $task.Id
                            DependencyId = $depId
                            Message      = "La tâche dépendante $depId n'a pas de date de fin définie."
                        }
                        $result.IsValid = $false
                    }
                } else {
                    $result.MissingDependencies += @{
                        TaskId       = $task.Id
                        DependencyId = $depId
                        Message      = "La tâche dépendante $depId n'existe pas."
                    }
                    $result.IsValid = $false
                }
            }
        }
    }

    return $result
}

# Les fonctions sont disponibles dans le contexte du script qui importe ce fichier
# Pas besoin d'Export-ModuleMember car ce n'est pas un module PowerShell
