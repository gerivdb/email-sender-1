# Extract-DurationAttributes.ps1
# Script pour extraire les attributs de durée des tâches dans les fichiers markdown de roadmap
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

# Fonction pour extraire les durées en jours/semaines/mois
function Get-DayWeekMonthDurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des durées en jours/semaines/mois..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $durationAttributes = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les durées en jours/semaines/mois
    $durationPatterns = @(
        # Format: durée: X jours/semaines/mois
        '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(jour|jours|semaine|semaines|mois|an|ans|année|années)',
        
        # Format: #duration:Xj/s/m/a
        '#(?:durée|duration|temps):(\d+(?:\.\d+)?)(j|s|m|a)',
        
        # Format: prend X jours/semaines/mois
        '(?:prend|dure|nécessite)\s+(\d+(?:\.\d+)?)\s*(jour|jours|semaine|semaines|mois|an|ans|année|années)',
        
        # Format: X jours/semaines/mois de travail
        '(\d+(?:\.\d+)?)\s*(jour|jours|semaine|semaines|mois|an|ans|année|années)\s+(?:de travail|de développement|d\'effort)'
    )
    
    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            
            $tasks[$taskId] = @{
                Id = $taskId
                Title = $taskTitle
                Status = $taskStatus
                LineNumber = $lineNumber
                Durations = @{
                    DayWeekMonth = @()
                    HourMinute = @()
                    Composite = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les durées en jours/semaines/mois
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les durées en jours/semaines/mois
            foreach ($pattern in $durationPatterns) {
                $matches = [regex]::Matches($taskLine, $pattern)
                foreach ($match in $matches) {
                    $durationValue = $match.Groups[1].Value
                    $durationUnit = $match.Groups[2].Value
                    
                    # Normaliser les unités
                    $normalizedUnit = switch -Regex ($durationUnit) {
                        '^j(our)?s?$' { "jours" }
                        '^s(emaine)?s?$' { "semaines" }
                        '^m(ois)?$' { "mois" }
                        '^a(n|ns|nnée|nnées)?$' { "années" }
                        default { $durationUnit }
                    }
                    
                    $duration = @{
                        Value = $durationValue
                        Unit = $normalizedUnit
                        Original = "$durationValue $durationUnit"
                        Type = "DayWeekMonth"
                    }
                    
                    # Ajouter la durée à la tâche
                    $tasks[$taskId].Durations.DayWeekMonth += $duration
                    
                    # Ajouter la durée aux attributs de durée
                    if (-not $durationAttributes.ContainsKey($taskId)) {
                        $durationAttributes[$taskId] = @{
                            DayWeekMonth = @()
                            HourMinute = @()
                            Composite = @()
                        }
                    }
                    
                    $durationAttributes[$taskId].DayWeekMonth += $duration
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        DurationAttributes = $durationAttributes
    }
}

# Fonction pour extraire les durées en heures/minutes
function Get-HourMinuteDurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des durées en heures/minutes..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $durationAttributes = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les durées en heures/minutes
    $durationPatterns = @(
        # Format: durée: X heures/minutes
        '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(heure|heures|minute|minutes|h|min)',
        
        # Format: #duration:Xh/min
        '#(?:durée|duration|temps):(\d+(?:\.\d+)?)(h|min)',
        
        # Format: prend X heures/minutes
        '(?:prend|dure|nécessite)\s+(\d+(?:\.\d+)?)\s*(heure|heures|minute|minutes|h|min)',
        
        # Format: X heures/minutes de travail
        '(\d+(?:\.\d+)?)\s*(heure|heures|minute|minutes|h|min)\s+(?:de travail|de développement|d\'effort)'
    )
    
    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    Title = $taskTitle
                    Status = $taskStatus
                    LineNumber = $lineNumber
                    Durations = @{
                        DayWeekMonth = @()
                        HourMinute = @()
                        Composite = @()
                    }
                }
            }
        }
    }
    
    # Deuxième passe : extraire les durées en heures/minutes
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les durées en heures/minutes
            foreach ($pattern in $durationPatterns) {
                $matches = [regex]::Matches($taskLine, $pattern)
                foreach ($match in $matches) {
                    $durationValue = $match.Groups[1].Value
                    $durationUnit = $match.Groups[2].Value
                    
                    # Normaliser les unités
                    $normalizedUnit = switch -Regex ($durationUnit) {
                        '^h(eure)?s?$' { "heures" }
                        '^min(ute)?s?$' { "minutes" }
                        default { $durationUnit }
                    }
                    
                    $duration = @{
                        Value = $durationValue
                        Unit = $normalizedUnit
                        Original = "$durationValue $durationUnit"
                        Type = "HourMinute"
                    }
                    
                    # Ajouter la durée à la tâche
                    $tasks[$taskId].Durations.HourMinute += $duration
                    
                    # Ajouter la durée aux attributs de durée
                    if (-not $durationAttributes.ContainsKey($taskId)) {
                        $durationAttributes[$taskId] = @{
                            DayWeekMonth = @()
                            HourMinute = @()
                            Composite = @()
                        }
                    }
                    
                    $durationAttributes[$taskId].HourMinute += $duration
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        DurationAttributes = $durationAttributes
    }
}

# Fonction pour extraire les durées avec unités composées
function Get-CompositeDurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des durées avec unités composées..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $durationAttributes = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les durées avec unités composées
    $durationPatterns = @(
        # Format: durée: X jours Y heures
        '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(jour|jours|j)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(heure|heures|h)',
        
        # Format: durée: X heures Y minutes
        '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(heure|heures|h)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(minute|minutes|min)',
        
        # Format: prend X jours Y heures
        '(?:prend|dure|nécessite)\s+(\d+(?:\.\d+)?)\s*(jour|jours|j)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(heure|heures|h)',
        
        # Format: prend X heures Y minutes
        '(?:prend|dure|nécessite)\s+(\d+(?:\.\d+)?)\s*(heure|heures|h)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(minute|minutes|min)',
        
        # Format: X jours Y heures de travail
        '(\d+(?:\.\d+)?)\s*(jour|jours|j)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(heure|heures|h)\s+(?:de travail|de développement|d\'effort)',
        
        # Format: X heures Y minutes de travail
        '(\d+(?:\.\d+)?)\s*(heure|heures|h)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(minute|minutes|min)\s+(?:de travail|de développement|d\'effort)'
    )
    
    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    Title = $taskTitle
                    Status = $taskStatus
                    LineNumber = $lineNumber
                    Durations = @{
                        DayWeekMonth = @()
                        HourMinute = @()
                        Composite = @()
                    }
                }
            }
        }
    }
    
    # Deuxième passe : extraire les durées avec unités composées
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les durées avec unités composées
            foreach ($pattern in $durationPatterns) {
                $matches = [regex]::Matches($taskLine, $pattern)
                foreach ($match in $matches) {
                    $durationValue1 = $match.Groups[1].Value
                    $durationUnit1 = $match.Groups[2].Value
                    $durationValue2 = $match.Groups[3].Value
                    $durationUnit2 = $match.Groups[4].Value
                    
                    # Normaliser les unités
                    $normalizedUnit1 = switch -Regex ($durationUnit1) {
                        '^j(our)?s?$' { "jours" }
                        '^h(eure)?s?$' { "heures" }
                        default { $durationUnit1 }
                    }
                    
                    $normalizedUnit2 = switch -Regex ($durationUnit2) {
                        '^h(eure)?s?$' { "heures" }
                        '^min(ute)?s?$' { "minutes" }
                        default { $durationUnit2 }
                    }
                    
                    $duration = @{
                        Value1 = $durationValue1
                        Unit1 = $normalizedUnit1
                        Value2 = $durationValue2
                        Unit2 = $normalizedUnit2
                        Original = "$durationValue1 $durationUnit1 $durationValue2 $durationUnit2"
                        Type = "Composite"
                    }
                    
                    # Ajouter la durée à la tâche
                    $tasks[$taskId].Durations.Composite += $duration
                    
                    # Ajouter la durée aux attributs de durée
                    if (-not $durationAttributes.ContainsKey($taskId)) {
                        $durationAttributes[$taskId] = @{
                            DayWeekMonth = @()
                            HourMinute = @()
                            Composite = @()
                        }
                    }
                    
                    $durationAttributes[$taskId].Composite += $duration
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        DurationAttributes = $durationAttributes
    }
}

# Fonction principale pour extraire les attributs de durée
function Get-DurationAttributes {
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
    
    # Extraire les différents types de durées
    $dayWeekMonthDurations = Get-DayWeekMonthDurations -Content $Content
    $hourMinuteDurations = Get-HourMinuteDurations -Content $Content
    $compositeDurations = Get-CompositeDurations -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        DayWeekMonthDurations = $dayWeekMonthDurations.DurationAttributes
        HourMinuteDurations = $hourMinuteDurations.DurationAttributes
        CompositeDurations = $compositeDurations.DurationAttributes
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithDayWeekMonthDurations = 0
            TasksWithHourMinuteDurations = 0
            TasksWithCompositeDurations = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($dayWeekMonthDurations.Tasks.Keys) + @($hourMinuteDurations.Tasks.Keys) + @($compositeDurations.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            DurationAttributes = @{
                DayWeekMonth = @()
                HourMinute = @()
                Composite = @()
            }
        }
        
        if ($dayWeekMonthDurations.Tasks.ContainsKey($taskId)) {
            $task.Title = $dayWeekMonthDurations.Tasks[$taskId].Title
            $task.Status = $dayWeekMonthDurations.Tasks[$taskId].Status
            $task.LineNumber = $dayWeekMonthDurations.Tasks[$taskId].LineNumber
            $task.DurationAttributes.DayWeekMonth = $dayWeekMonthDurations.Tasks[$taskId].Durations.DayWeekMonth
        }
        
        if ($hourMinuteDurations.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $hourMinuteDurations.Tasks[$taskId].Title
                $task.Status = $hourMinuteDurations.Tasks[$taskId].Status
                $task.LineNumber = $hourMinuteDurations.Tasks[$taskId].LineNumber
            }
            
            $task.DurationAttributes.HourMinute = $hourMinuteDurations.Tasks[$taskId].Durations.HourMinute
        }
        
        if ($compositeDurations.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $compositeDurations.Tasks[$taskId].Title
                $task.Status = $compositeDurations.Tasks[$taskId].Status
                $task.LineNumber = $compositeDurations.Tasks[$taskId].LineNumber
            }
            
            $task.DurationAttributes.Composite = $compositeDurations.Tasks[$taskId].Durations.Composite
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithDayWeekMonthDurations = ($analysis.Tasks.Values | Where-Object { $_.DurationAttributes.DayWeekMonth.Count -gt 0 }).Count
    $analysis.Stats.TasksWithHourMinuteDurations = ($analysis.Tasks.Values | Where-Object { $_.DurationAttributes.HourMinute.Count -gt 0 }).Count
    $analysis.Stats.TasksWithCompositeDurations = ($analysis.Tasks.Values | Where-Object { $_.DurationAttributes.Composite.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-DurationAttributesOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-DurationAttributesOutput {
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
            $markdown = "# Analyse des attributs de durée`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec durées en jours/semaines/mois: $($Analysis.Stats.TasksWithDayWeekMonthDurations)`n"
            $markdown += "- Tâches avec durées en heures/minutes: $($Analysis.Stats.TasksWithHourMinuteDurations)`n"
            $markdown += "- Tâches avec durées composées: $($Analysis.Stats.TasksWithCompositeDurations)`n`n"
            
            $markdown += "## Tâches avec attributs de durée`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasDurationAttributes = $task.DurationAttributes.DayWeekMonth.Count -gt 0 -or 
                                        $task.DurationAttributes.HourMinute.Count -gt 0 -or
                                        $task.DurationAttributes.Composite.Count -gt 0
                
                if ($hasDurationAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.DurationAttributes.DayWeekMonth.Count -gt 0) {
                        $markdown += "- Durées en jours/semaines/mois:`n"
                        foreach ($duration in $task.DurationAttributes.DayWeekMonth) {
                            $markdown += "  - $($duration.Value) $($duration.Unit) (original: $($duration.Original))`n"
                        }
                    }
                    
                    if ($task.DurationAttributes.HourMinute.Count -gt 0) {
                        $markdown += "- Durées en heures/minutes:`n"
                        foreach ($duration in $task.DurationAttributes.HourMinute) {
                            $markdown += "  - $($duration.Value) $($duration.Unit) (original: $($duration.Original))`n"
                        }
                    }
                    
                    if ($task.DurationAttributes.Composite.Count -gt 0) {
                        $markdown += "- Durées composées:`n"
                        foreach ($duration in $task.DurationAttributes.Composite) {
                            $markdown += "  - $($duration.Value1) $($duration.Unit1) et $($duration.Value2) $($duration.Unit2) (original: $($duration.Original))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,DayWeekMonthDurations,HourMinuteDurations,CompositeDurations`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $dayWeekMonthDurations = ""
                if ($task.DurationAttributes.DayWeekMonth.Count -gt 0) {
                    $dayWeekMonthDurations = ($task.DurationAttributes.DayWeekMonth | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                $hourMinuteDurations = ""
                if ($task.DurationAttributes.HourMinute.Count -gt 0) {
                    $hourMinuteDurations = ($task.DurationAttributes.HourMinute | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                $compositeDurations = ""
                if ($task.DurationAttributes.Composite.Count -gt 0) {
                    $compositeDurations = ($task.DurationAttributes.Composite | ForEach-Object { "$($_.Value1) $($_.Unit1) et $($_.Value2) $($_.Unit2)" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$dayWeekMonthDurations`",`"$hourMinuteDurations`",`"$compositeDurations`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-DurationAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
