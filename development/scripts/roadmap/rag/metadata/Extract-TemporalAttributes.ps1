# Export-TemporalAttributes.ps1
# Script pour extraire les attributs temporels des tâches dans les fichiers markdown de roadmap
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

# Script pour extraire les attributs temporels des tâches dans les fichiers markdown de roadmap

# Fonction pour extraire les attributs temporels
function Get-TemporalAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    Write-Log "Extraction des attributs temporels..." -Level "Debug"

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $analysis = @{
        Tasks              = @{}
        TemporalAttributes = @{
            DueDates   = @{}
            StartDates = @{}
            EndDates   = @{}
            Durations  = @{}
            Deadlines  = @{}
        }
        Stats              = @{
            TotalTasks          = 0
            TasksWithDueDates   = 0
            TasksWithStartDates = 0
            TasksWithEndDates   = 0
            TasksWithDurations  = 0
            TasksWithDeadlines  = 0
        }
    }

    # Patterns pour détecter les tâches et les attributs temporels
    $patterns = @{
        Task          = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        TaskWithoutId = '^\s*[-*+]\s*\[([ xX])\]\s*(.*)'
        DueDate       = '(?:due|échéance|date limite):\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{1,2}\s+(?:jan|fév|mar|avr|mai|juin|juil|août|sep|oct|nov|déc)[a-zéèêë]*\s+\d{4})'
        StartDate     = '(?:start|début|commence):\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{1,2}\s+(?:jan|fév|mar|avr|mai|juin|juil|août|sep|oct|nov|déc)[a-zéèêë]*\s+\d{4})'
        EndDate       = '(?:end|fin|termine):\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{1,2}\s+(?:jan|fév|mar|avr|mai|juin|juil|août|sep|oct|nov|déc)[a-zéèêë]*\s+\d{4})'
        Duration      = '(?:duration|durée):\s*(\d+(?:\.\d+)?)\s*(jour|jours|semaine|semaines|mois|année|années|h|heure|heures|j|s|m|a)'
        Deadline      = '(?:deadline|date butoir):\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{1,2}\s+(?:jan|fév|mar|avr|mai|juin|juil|août|sep|oct|nov|déc)[a-zéèêë]*\s+\d{4})'
    }

    # Analyser chaque ligne
    $lineNumber = 0

    foreach ($line in $lines) {
        $lineNumber++

        # Détecter les tâches avec identifiants
        $taskId = $null
        $taskTitle = $null
        $taskStatus = $null

        if ($line -match $patterns.Task) {
            $taskStatus = $matches[1]
            $taskId = $matches[2]
            $taskTitle = $matches[3]
        } elseif ($line -match $patterns.TaskWithoutId) {
            $taskStatus = $matches[1]
            $taskTitle = $matches[2]
            $taskId = "task_$lineNumber"  # Générer un ID pour les tâches sans ID explicite
        }

        if ($null -ne $taskId) {
            # Créer l'objet tâche s'il n'existe pas déjà
            if (-not $analysis.Tasks.ContainsKey($taskId)) {
                $analysis.Tasks[$taskId] = @{
                    Id                 = $taskId
                    Title              = $taskTitle
                    Status             = if ($taskStatus -match '[xX]') { "Completed" } else { "Pending" }
                    LineNumber         = $lineNumber
                    TemporalAttributes = @{
                        DueDate   = $null
                        StartDate = $null
                        EndDate   = $null
                        Duration  = $null
                        Deadline  = $null
                    }
                }

                $analysis.Stats.TotalTasks++
            }

            # Extraire les attributs temporels
            $taskLine = $line

            # Extraire la date d'échéance
            if ($taskLine -match $patterns.DueDate) {
                $dueDate = $matches[1]
                $analysis.Tasks[$taskId].TemporalAttributes.DueDate = $dueDate
                $analysis.TemporalAttributes.DueDates[$taskId] = $dueDate
                $analysis.Stats.TasksWithDueDates++
            }

            # Extraire la date de début
            if ($taskLine -match $patterns.StartDate) {
                $startDate = $matches[1]
                $analysis.Tasks[$taskId].TemporalAttributes.StartDate = $startDate
                $analysis.TemporalAttributes.StartDates[$taskId] = $startDate
                $analysis.Stats.TasksWithStartDates++
            }

            # Extraire la date de fin
            if ($taskLine -match $patterns.EndDate) {
                $endDate = $matches[1]
                $analysis.Tasks[$taskId].TemporalAttributes.EndDate = $endDate
                $analysis.TemporalAttributes.EndDates[$taskId] = $endDate
                $analysis.Stats.TasksWithEndDates++
            }

            # Extraire la durée
            if ($taskLine -match $patterns.Duration) {
                $durationValue = $matches[1]
                $durationUnit = $matches[2]
                $duration = @{
                    Value = $durationValue
                    Unit  = $durationUnit
                }
                $analysis.Tasks[$taskId].TemporalAttributes.Duration = $duration
                $analysis.TemporalAttributes.Durations[$taskId] = $duration
                $analysis.Stats.TasksWithDurations++
            }

            # Extraire la deadline
            if ($taskLine -match $patterns.Deadline) {
                $deadline = $matches[1]
                $analysis.Tasks[$taskId].TemporalAttributes.Deadline = $deadline
                $analysis.TemporalAttributes.Deadlines[$taskId] = $deadline
                $analysis.Stats.TasksWithDeadlines++
            }
        }
    }

    return $analysis
}

# Fonction pour formater les résultats
function Format-TemporalAttributesOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format
    )

    Write-Log "Formatage des résultats en $Format..." -Level "Debug"

    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des attributs temporels`n`n"

            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec dates d'échéance: $($Analysis.Stats.TasksWithDueDates)`n"
            $markdown += "- Tâches avec dates de début: $($Analysis.Stats.TasksWithStartDates)`n"
            $markdown += "- Tâches avec dates de fin: $($Analysis.Stats.TasksWithEndDates)`n"
            $markdown += "- Tâches avec durées: $($Analysis.Stats.TasksWithDurations)`n"
            $markdown += "- Tâches avec deadlines: $($Analysis.Stats.TasksWithDeadlines)`n`n"

            $markdown += "## Tâches avec attributs temporels`n`n"

            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $temporalAttributes = $task.TemporalAttributes

                if ($temporalAttributes.DueDate -or $temporalAttributes.StartDate -or $temporalAttributes.EndDate -or $temporalAttributes.Duration -or $temporalAttributes.Deadline) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"

                    if ($temporalAttributes.DueDate) {
                        $markdown += "- Date d'échéance: $($temporalAttributes.DueDate)`n"
                    }

                    if ($temporalAttributes.StartDate) {
                        $markdown += "- Date de début: $($temporalAttributes.StartDate)`n"
                    }

                    if ($temporalAttributes.EndDate) {
                        $markdown += "- Date de fin: $($temporalAttributes.EndDate)`n"
                    }

                    if ($temporalAttributes.Duration) {
                        $markdown += "- Durée: $($temporalAttributes.Duration.Value) $($temporalAttributes.Duration.Unit)`n"
                    }

                    if ($temporalAttributes.Deadline) {
                        $markdown += "- Deadline: $($temporalAttributes.Deadline)`n"
                    }

                    $markdown += "`n"
                }
            }

            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,DueDate,StartDate,EndDate,Duration,DurationUnit,Deadline`n"

            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $temporalAttributes = $task.TemporalAttributes

                $dueDate = $temporalAttributes.DueDate ?? ""
                $startDate = $temporalAttributes.StartDate ?? ""
                $endDate = $temporalAttributes.EndDate ?? ""
                $durationValue = $temporalAttributes.Duration.Value ?? ""
                $durationUnit = $temporalAttributes.Duration.Unit ?? ""
                $deadline = $temporalAttributes.Deadline ?? ""

                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'

                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$dueDate`",`"$startDate`",`"$endDate`",`"$durationValue`",`"$durationUnit`",`"$deadline`"`n"
            }

            return $csv
        }
    }
}

# Fonction principale
function Export-TemporalAttributes {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$OutputPath,
        [string]$OutputFormat
    )

    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Log "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -Level "Error"
        return $null
    }

    # Charger le contenu si un chemin de fichier est spécifié
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier spécifié n'existe pas: $FilePath" -Level "Error"
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    # Extraire les attributs temporels
    $analysis = Get-TemporalAttributes -Content $Content

    # Formater les résultats
    $output = Format-TemporalAttributesOutput -Analysis $analysis -Format $OutputFormat

    # Enregistrer les résultats si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $outputDirectory = Split-Path -Path $OutputPath -Parent

        if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -Path $outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }

        Set-Content -Path $OutputPath -Value $output
        Write-Log "Résultats enregistrés dans $OutputPath" -Level "Info"
    }

    return $output
}

# Exécuter la fonction principale avec les paramètres fournis
Export-TemporalAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat

