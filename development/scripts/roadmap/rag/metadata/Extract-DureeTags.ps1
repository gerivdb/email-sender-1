# Extract-DureeTags.ps1
# Script pour extraire les tags de type #durée des tâches dans les fichiers markdown de roadmap
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

# Fonction pour extraire les tags de type #durée
function Get-DureeTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #durée..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $dureeTags = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #durée
    $dureeTagPatterns = @{
        # Format #durée:Xj (jours)
        "DureeDays" = '#durée:(\d+(?:\.\d+)?)j\b'
        
        # Format #durée:Xs (semaines)
        "DureeWeeks" = '#durée:(\d+(?:\.\d+)?)s\b'
        
        # Format #durée:Xm (mois)
        "DureeMonths" = '#durée:(\d+(?:\.\d+)?)m\b'
        
        # Format #durée(Xj) (jours)
        "DureeParenDays" = '#durée\((\d+(?:\.\d+)?)j\)'
        
        # Format #durée(Xs) (semaines)
        "DureeParenWeeks" = '#durée\((\d+(?:\.\d+)?)s\)'
        
        # Format #durée(Xm) (mois)
        "DureeParenMonths" = '#durée\((\d+(?:\.\d+)?)m\)'
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
                Id = $taskId
                Title = $taskTitle
                Status = $taskStatus
                LineNumber = $lineNumber
                DureeTags = @{
                    Days = @()
                    Weeks = @()
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
            if ($taskLine -match $dureeTagPatterns.DureeDays) {
                $dureeValue = $matches[1]
                $dureeTag = @{
                    Value = $dureeValue
                    Unit = "jours"
                    Original = "#durée:${dureeValue}j"
                    Type = "DureeDays"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].DureeTags.Days += $dureeTag
                
                # Ajouter le tag aux attributs de durée
                if (-not $dureeTags.ContainsKey($taskId)) {
                    $dureeTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $dureeTags[$taskId].Days += $dureeTag
            }
            
            # Extraire les tags de durée en semaines
            if ($taskLine -match $dureeTagPatterns.DureeWeeks) {
                $dureeValue = $matches[1]
                $dureeTag = @{
                    Value = $dureeValue
                    Unit = "semaines"
                    Original = "#durée:${dureeValue}s"
                    Type = "DureeWeeks"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].DureeTags.Weeks += $dureeTag
                
                # Ajouter le tag aux attributs de durée
                if (-not $dureeTags.ContainsKey($taskId)) {
                    $dureeTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $dureeTags[$taskId].Weeks += $dureeTag
            }
            
            # Extraire les tags de durée en mois
            if ($taskLine -match $dureeTagPatterns.DureeMonths) {
                $dureeValue = $matches[1]
                $dureeTag = @{
                    Value = $dureeValue
                    Unit = "mois"
                    Original = "#durée:${dureeValue}m"
                    Type = "DureeMonths"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].DureeTags.Months += $dureeTag
                
                # Ajouter le tag aux attributs de durée
                if (-not $dureeTags.ContainsKey($taskId)) {
                    $dureeTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $dureeTags[$taskId].Months += $dureeTag
            }
            
            # Extraire les tags de durée en jours (format parenthèses)
            if ($taskLine -match $dureeTagPatterns.DureeParenDays) {
                $dureeValue = $matches[1]
                $dureeTag = @{
                    Value = $dureeValue
                    Unit = "jours"
                    Original = "#durée(${dureeValue}j)"
                    Type = "DureeParenDays"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].DureeTags.Days += $dureeTag
                
                # Ajouter le tag aux attributs de durée
                if (-not $dureeTags.ContainsKey($taskId)) {
                    $dureeTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $dureeTags[$taskId].Days += $dureeTag
            }
            
            # Extraire les tags de durée en semaines (format parenthèses)
            if ($taskLine -match $dureeTagPatterns.DureeParenWeeks) {
                $dureeValue = $matches[1]
                $dureeTag = @{
                    Value = $dureeValue
                    Unit = "semaines"
                    Original = "#durée(${dureeValue}s)"
                    Type = "DureeParenWeeks"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].DureeTags.Weeks += $dureeTag
                
                # Ajouter le tag aux attributs de durée
                if (-not $dureeTags.ContainsKey($taskId)) {
                    $dureeTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $dureeTags[$taskId].Weeks += $dureeTag
            }
            
            # Extraire les tags de durée en mois (format parenthèses)
            if ($taskLine -match $dureeTagPatterns.DureeParenMonths) {
                $dureeValue = $matches[1]
                $dureeTag = @{
                    Value = $dureeValue
                    Unit = "mois"
                    Original = "#durée(${dureeValue}m)"
                    Type = "DureeParenMonths"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].DureeTags.Months += $dureeTag
                
                # Ajouter le tag aux attributs de durée
                if (-not $dureeTags.ContainsKey($taskId)) {
                    $dureeTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $dureeTags[$taskId].Months += $dureeTag
            }
        }
    }
    
    return @{
        Tasks = $tasks
        DureeTags = $dureeTags
    }
}

# Fonction principale pour extraire les tags de durée
function Get-DureeTagAttributes {
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
    $dureeTags = Get-DureeTags -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        DureeTags = $dureeTags.DureeTags
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithDureeDaysTags = 0
            TasksWithDureeWeeksTags = 0
            TasksWithDureeMonthsTags = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($dureeTags.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            DureeTagAttributes = @{
                Days = @()
                Weeks = @()
                Months = @()
            }
        }
        
        if ($dureeTags.Tasks.ContainsKey($taskId)) {
            $task.Title = $dureeTags.Tasks[$taskId].Title
            $task.Status = $dureeTags.Tasks[$taskId].Status
            $task.LineNumber = $dureeTags.Tasks[$taskId].LineNumber
            $task.DureeTagAttributes.Days = $dureeTags.Tasks[$taskId].DureeTags.Days
            $task.DureeTagAttributes.Weeks = $dureeTags.Tasks[$taskId].DureeTags.Weeks
            $task.DureeTagAttributes.Months = $dureeTags.Tasks[$taskId].DureeTags.Months
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithDureeDaysTags = ($analysis.Tasks.Values | Where-Object { $_.DureeTagAttributes.Days.Count -gt 0 }).Count
    $analysis.Stats.TasksWithDureeWeeksTags = ($analysis.Tasks.Values | Where-Object { $_.DureeTagAttributes.Weeks.Count -gt 0 }).Count
    $analysis.Stats.TasksWithDureeMonthsTags = ($analysis.Tasks.Values | Where-Object { $_.DureeTagAttributes.Months.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-DureeTagAttributesOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-DureeTagAttributesOutput {
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
            $markdown += "- Tâches avec tags de durée en jours: $($Analysis.Stats.TasksWithDureeDaysTags)`n"
            $markdown += "- Tâches avec tags de durée en semaines: $($Analysis.Stats.TasksWithDureeWeeksTags)`n"
            $markdown += "- Tâches avec tags de durée en mois: $($Analysis.Stats.TasksWithDureeMonthsTags)`n`n"
            
            $markdown += "## Tâches avec tags de durée`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasDureeTagAttributes = $task.DureeTagAttributes.Days.Count -gt 0 -or 
                                        $task.DureeTagAttributes.Weeks.Count -gt 0 -or
                                        $task.DureeTagAttributes.Months.Count -gt 0
                
                if ($hasDureeTagAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.DureeTagAttributes.Days.Count -gt 0) {
                        $markdown += "- Tags de durée en jours:`n"
                        foreach ($tag in $task.DureeTagAttributes.Days) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.DureeTagAttributes.Weeks.Count -gt 0) {
                        $markdown += "- Tags de durée en semaines:`n"
                        foreach ($tag in $task.DureeTagAttributes.Weeks) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.DureeTagAttributes.Months.Count -gt 0) {
                        $markdown += "- Tags de durée en mois:`n"
                        foreach ($tag in $task.DureeTagAttributes.Months) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,DureeDaysTags,DureeWeeksTags,DureeMonthsTags`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $dureeDaysTags = ""
                if ($task.DureeTagAttributes.Days.Count -gt 0) {
                    $dureeDaysTags = ($task.DureeTagAttributes.Days | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                $dureeWeeksTags = ""
                if ($task.DureeTagAttributes.Weeks.Count -gt 0) {
                    $dureeWeeksTags = ($task.DureeTagAttributes.Weeks | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                $dureeMonthsTags = ""
                if ($task.DureeTagAttributes.Months.Count -gt 0) {
                    $dureeMonthsTags = ($task.DureeTagAttributes.Months | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$dureeDaysTags`",`"$dureeWeeksTags`",`"$dureeMonthsTags`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-DureeTagAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
