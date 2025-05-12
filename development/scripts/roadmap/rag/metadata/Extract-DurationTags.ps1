# Extract-DurationTags.ps1
# Script pour extraire les tags de durée des tâches dans les fichiers markdown de roadmap
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
    [ValidateSet("JSON", "Markdown", "CSV")]
    [string]$OutputFormat = "JSON"
)

# Fonction pour extraire les tags de type #duration
function Get-DurationTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    Write-Host "Extraction des tags de type #duration..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}
    $durationTags = @{}

    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Patterns pour les tags de type #duration
    $durationTagPatterns = @{
        # Format #duration:Xd (jours)
        "DurationDays"        = '#duration:(\d+(?:\.\d+)?)d\b'

        # Format #duration:Xw (semaines)
        "DurationWeeks"       = '#duration:(\d+(?:\.\d+)?)w\b'

        # Format #duration:Xm (mois)
        "DurationMonths"      = '#duration:(\d+(?:\.\d+)?)m\b'

        # Format #duration(Xd) (jours)
        "DurationParenDays"   = '#duration\((\d+(?:\.\d+)?)d\)'

        # Format #duration(Xw) (semaines)
        "DurationParenWeeks"  = '#duration\((\d+(?:\.\d+)?)w\)'

        # Format #duration(Xm) (mois)
        "DurationParenMonths" = '#duration\((\d+(?:\.\d+)?)m\)'
    }

    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }

            $tasks[$taskId] = @{
                Id           = $taskId
                Title        = $taskTitle
                Status       = $taskStatus
                LineNumber   = $lineNumber
                DurationTags = @{
                    Days   = @()
                    Weeks  = @()
                    Months = @()
                }
            }
        }
    }

    # Deuxième passe : extraire les tags de durée
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line

            # Extraire les tags de durée en jours
            if ($taskLine -match $durationTagPatterns.DurationDays) {
                $durationValue = $matches[1]
                $durationTag = @{
                    Value    = $durationValue
                    Unit     = "jours"
                    Original = "#duration:${durationValue}d"
                    Type     = "DurationDays"
                }

                # Ajouter le tag à la tâche
                $tasks[$taskId].DurationTags.Days += $durationTag

                # Ajouter le tag aux attributs de durée
                if (-not $durationTags.ContainsKey($taskId)) {
                    $durationTags[$taskId] = @{
                        Days   = @()
                        Weeks  = @()
                        Months = @()
                    }
                }

                $durationTags[$taskId].Days += $durationTag
            }

            # Extraire les tags de durée en semaines
            if ($taskLine -match $durationTagPatterns.DurationWeeks) {
                $durationValue = $matches[1]
                $durationTag = @{
                    Value    = $durationValue
                    Unit     = "semaines"
                    Original = "#duration:${durationValue}w"
                    Type     = "DurationWeeks"
                }

                # Ajouter le tag à la tâche
                $tasks[$taskId].DurationTags.Weeks += $durationTag

                # Ajouter le tag aux attributs de durée
                if (-not $durationTags.ContainsKey($taskId)) {
                    $durationTags[$taskId] = @{
                        Days   = @()
                        Weeks  = @()
                        Months = @()
                    }
                }

                $durationTags[$taskId].Weeks += $durationTag
            }

            # Extraire les tags de durée en mois
            if ($taskLine -match $durationTagPatterns.DurationMonths) {
                $durationValue = $matches[1]
                $durationTag = @{
                    Value    = $durationValue
                    Unit     = "mois"
                    Original = "#duration:${durationValue}m"
                    Type     = "DurationMonths"
                }

                # Ajouter le tag à la tâche
                $tasks[$taskId].DurationTags.Months += $durationTag

                # Ajouter le tag aux attributs de durée
                if (-not $durationTags.ContainsKey($taskId)) {
                    $durationTags[$taskId] = @{
                        Days   = @()
                        Weeks  = @()
                        Months = @()
                    }
                }

                $durationTags[$taskId].Months += $durationTag
            }
        }
    }

    return @{
        Tasks        = $tasks
        DurationTags = $durationTags
    }
}

# Fonction principale pour extraire les tags de durée
function Get-DurationTagAttributes {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$OutputPath,
        [string]$OutputFormat
    )

    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Host "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -ForegroundColor Red
        return $null
    }

    # Vérifier si le contenu est vide après avoir été passé
    if (-not [string]::IsNullOrEmpty($Content) -and $Content.Trim().Length -eq 0) {
        Write-Host "Le contenu fourni est vide." -ForegroundColor Red
        return $null
    }

    # Charger le contenu si un chemin de fichier est spécifié
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Host "Le fichier spécifié n'existe pas: $FilePath" -ForegroundColor Red
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    # Extraire les tags de durée
    $durationTags = Get-DurationTags -Content $Content

    # Combiner les résultats
    $analysis = @{
        DurationTags = $durationTags.DurationTags
        Tasks        = @{}
        Stats        = @{
            TotalTasks                  = 0
            TasksWithDurationDaysTags   = 0
            TasksWithDurationWeeksTags  = 0
            TasksWithDurationMonthsTags = 0
        }
    }

    # Fusionner les informations des tâches
    $allTaskIds = @($durationTags.Tasks.Keys) | Select-Object -Unique

    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id                    = $taskId
            Title                 = ""
            Status                = ""
            LineNumber            = 0
            DurationTagAttributes = @{
                Days   = @()
                Weeks  = @()
                Months = @()
            }
        }

        if ($durationTags.Tasks.ContainsKey($taskId)) {
            $task.Title = $durationTags.Tasks[$taskId].Title
            $task.Status = $durationTags.Tasks[$taskId].Status
            $task.LineNumber = $durationTags.Tasks[$taskId].LineNumber
            $task.DurationTagAttributes.Days = $durationTags.Tasks[$taskId].DurationTags.Days
            $task.DurationTagAttributes.Weeks = $durationTags.Tasks[$taskId].DurationTags.Weeks
            $task.DurationTagAttributes.Months = $durationTags.Tasks[$taskId].DurationTags.Months
        }

        $analysis.Tasks[$taskId] = $task
    }

    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithDurationDaysTags = ($analysis.Tasks.Values | Where-Object { $_.DurationTagAttributes.Days.Count -gt 0 }).Count
    $analysis.Stats.TasksWithDurationWeeksTags = ($analysis.Tasks.Values | Where-Object { $_.DurationTagAttributes.Weeks.Count -gt 0 }).Count
    $analysis.Stats.TasksWithDurationMonthsTags = ($analysis.Tasks.Values | Where-Object { $_.DurationTagAttributes.Months.Count -gt 0 }).Count

    # Formater les résultats selon le format demandé
    $output = Format-DurationTagAttributesOutput -Analysis $analysis -Format $OutputFormat

    # Enregistrer les résultats si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $outputDirectory = Split-Path -Path $OutputPath -Parent

        if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -Path $outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }

        Set-Content -Path $OutputPath -Value $output
        Write-Host "Résultats enregistrés dans $OutputPath" -ForegroundColor Green
    }

    return $output
}

# Fonction pour formater les résultats
function Format-DurationTagAttributesOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format
    )

    Write-Host "Formatage des résultats en $Format..." -ForegroundColor Cyan

    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des tags de durée`n`n"

            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec tags de durée en jours: $($Analysis.Stats.TasksWithDurationDaysTags)`n"
            $markdown += "- Tâches avec tags de durée en semaines: $($Analysis.Stats.TasksWithDurationWeeksTags)`n"
            $markdown += "- Tâches avec tags de durée en mois: $($Analysis.Stats.TasksWithDurationMonthsTags)`n`n"

            $markdown += "## Tâches avec tags de durée`n`n"

            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasDurationTagAttributes = $task.DurationTagAttributes.Days.Count -gt 0 -or
                $task.DurationTagAttributes.Weeks.Count -gt 0 -or
                $task.DurationTagAttributes.Months.Count -gt 0

                if ($hasDurationTagAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"

                    if ($task.DurationTagAttributes.Days.Count -gt 0) {
                        $markdown += "- Tags de durée en jours:`n"
                        foreach ($tag in $task.DurationTagAttributes.Days) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }

                    if ($task.DurationTagAttributes.Weeks.Count -gt 0) {
                        $markdown += "- Tags de durée en semaines:`n"
                        foreach ($tag in $task.DurationTagAttributes.Weeks) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }

                    if ($task.DurationTagAttributes.Months.Count -gt 0) {
                        $markdown += "- Tags de durée en mois:`n"
                        foreach ($tag in $task.DurationTagAttributes.Months) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }

                    $markdown += "`n"
                }
            }

            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,DurationDaysTags,DurationWeeksTags,DurationMonthsTags`n"

            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]

                $durationDaysTags = ""
                if ($task.DurationTagAttributes.Days.Count -gt 0) {
                    $durationDaysTags = ($task.DurationTagAttributes.Days | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }

                $durationWeeksTags = ""
                if ($task.DurationTagAttributes.Weeks.Count -gt 0) {
                    $durationWeeksTags = ($task.DurationTagAttributes.Weeks | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }

                $durationMonthsTags = ""
                if ($task.DurationTagAttributes.Months.Count -gt 0) {
                    $durationMonthsTags = ($task.DurationTagAttributes.Months | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }

                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'

                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$durationDaysTags`",`"$durationWeeksTags`",`"$durationMonthsTags`"`n"
            }

            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-DurationTagAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
