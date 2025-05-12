# Extract-TempsTags.ps1
# Script pour extraire les tags de type #temps des tâches dans les fichiers markdown de roadmap
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

# Fonction pour extraire les tags de type #temps
function Get-TempsTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #temps..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $tempsTags = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #temps
    $tempsTagPatterns = @{
        # Format #temps:Xj (jours)
        "TempsDays" = '#temps:(\d+(?:\.\d+)?)j\b'
        
        # Format #temps:Xs (semaines)
        "TempsWeeks" = '#temps:(\d+(?:\.\d+)?)s\b'
        
        # Format #temps:Xm (mois)
        "TempsMonths" = '#temps:(\d+(?:\.\d+)?)m\b'
        
        # Format #temps(Xj) (jours)
        "TempsParenDays" = '#temps\((\d+(?:\.\d+)?)j\)'
        
        # Format #temps(Xs) (semaines)
        "TempsParenWeeks" = '#temps\((\d+(?:\.\d+)?)s\)'
        
        # Format #temps(Xm) (mois)
        "TempsParenMonths" = '#temps\((\d+(?:\.\d+)?)m\)'
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
                TempsTags = @{
                    Days = @()
                    Weeks = @()
                    Months = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les tags de temps
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les tags de temps en jours
            if ($taskLine -match $tempsTagPatterns.TempsDays) {
                $tempsValue = $matches[1]
                $tempsTag = @{
                    Value = $tempsValue
                    Unit = "jours"
                    Original = "#temps:${tempsValue}j"
                    Type = "TempsDays"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].TempsTags.Days += $tempsTag
                
                # Ajouter le tag aux attributs de temps
                if (-not $tempsTags.ContainsKey($taskId)) {
                    $tempsTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $tempsTags[$taskId].Days += $tempsTag
            }
            
            # Extraire les tags de temps en semaines
            if ($taskLine -match $tempsTagPatterns.TempsWeeks) {
                $tempsValue = $matches[1]
                $tempsTag = @{
                    Value = $tempsValue
                    Unit = "semaines"
                    Original = "#temps:${tempsValue}s"
                    Type = "TempsWeeks"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].TempsTags.Weeks += $tempsTag
                
                # Ajouter le tag aux attributs de temps
                if (-not $tempsTags.ContainsKey($taskId)) {
                    $tempsTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $tempsTags[$taskId].Weeks += $tempsTag
            }
            
            # Extraire les tags de temps en mois
            if ($taskLine -match $tempsTagPatterns.TempsMonths) {
                $tempsValue = $matches[1]
                $tempsTag = @{
                    Value = $tempsValue
                    Unit = "mois"
                    Original = "#temps:${tempsValue}m"
                    Type = "TempsMonths"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].TempsTags.Months += $tempsTag
                
                # Ajouter le tag aux attributs de temps
                if (-not $tempsTags.ContainsKey($taskId)) {
                    $tempsTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $tempsTags[$taskId].Months += $tempsTag
            }
            
            # Extraire les tags de temps en jours (format parenthèses)
            if ($taskLine -match $tempsTagPatterns.TempsParenDays) {
                $tempsValue = $matches[1]
                $tempsTag = @{
                    Value = $tempsValue
                    Unit = "jours"
                    Original = "#temps(${tempsValue}j)"
                    Type = "TempsParenDays"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].TempsTags.Days += $tempsTag
                
                # Ajouter le tag aux attributs de temps
                if (-not $tempsTags.ContainsKey($taskId)) {
                    $tempsTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $tempsTags[$taskId].Days += $tempsTag
            }
            
            # Extraire les tags de temps en semaines (format parenthèses)
            if ($taskLine -match $tempsTagPatterns.TempsParenWeeks) {
                $tempsValue = $matches[1]
                $tempsTag = @{
                    Value = $tempsValue
                    Unit = "semaines"
                    Original = "#temps(${tempsValue}s)"
                    Type = "TempsParenWeeks"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].TempsTags.Weeks += $tempsTag
                
                # Ajouter le tag aux attributs de temps
                if (-not $tempsTags.ContainsKey($taskId)) {
                    $tempsTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $tempsTags[$taskId].Weeks += $tempsTag
            }
            
            # Extraire les tags de temps en mois (format parenthèses)
            if ($taskLine -match $tempsTagPatterns.TempsParenMonths) {
                $tempsValue = $matches[1]
                $tempsTag = @{
                    Value = $tempsValue
                    Unit = "mois"
                    Original = "#temps(${tempsValue}m)"
                    Type = "TempsParenMonths"
                }
                
                # Ajouter le tag à la tâche
                $tasks[$taskId].TempsTags.Months += $tempsTag
                
                # Ajouter le tag aux attributs de temps
                if (-not $tempsTags.ContainsKey($taskId)) {
                    $tempsTags[$taskId] = @{
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
                
                $tempsTags[$taskId].Months += $tempsTag
            }
        }
    }
    
    return @{
        Tasks = $tasks
        TempsTags = $tempsTags
    }
}

# Fonction principale pour extraire les tags de temps
function Get-TempsTagAttributes {
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
    
    # Extraire les tags de temps
    $tempsTags = Get-TempsTags -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        TempsTags = $tempsTags.TempsTags
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithTempsDaysTags = 0
            TasksWithTempsWeeksTags = 0
            TasksWithTempsMonthsTags = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($tempsTags.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            TempsTagAttributes = @{
                Days = @()
                Weeks = @()
                Months = @()
            }
        }
        
        if ($tempsTags.Tasks.ContainsKey($taskId)) {
            $task.Title = $tempsTags.Tasks[$taskId].Title
            $task.Status = $tempsTags.Tasks[$taskId].Status
            $task.LineNumber = $tempsTags.Tasks[$taskId].LineNumber
            $task.TempsTagAttributes.Days = $tempsTags.Tasks[$taskId].TempsTags.Days
            $task.TempsTagAttributes.Weeks = $tempsTags.Tasks[$taskId].TempsTags.Weeks
            $task.TempsTagAttributes.Months = $tempsTags.Tasks[$taskId].TempsTags.Months
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithTempsDaysTags = ($analysis.Tasks.Values | Where-Object { $_.TempsTagAttributes.Days.Count -gt 0 }).Count
    $analysis.Stats.TasksWithTempsWeeksTags = ($analysis.Tasks.Values | Where-Object { $_.TempsTagAttributes.Weeks.Count -gt 0 }).Count
    $analysis.Stats.TasksWithTempsMonthsTags = ($analysis.Tasks.Values | Where-Object { $_.TempsTagAttributes.Months.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-TempsTagAttributesOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-TempsTagAttributesOutput {
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
            $markdown = "# Analyse des tags de temps`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec tags de temps en jours: $($Analysis.Stats.TasksWithTempsDaysTags)`n"
            $markdown += "- Tâches avec tags de temps en semaines: $($Analysis.Stats.TasksWithTempsWeeksTags)`n"
            $markdown += "- Tâches avec tags de temps en mois: $($Analysis.Stats.TasksWithTempsMonthsTags)`n`n"
            
            $markdown += "## Tâches avec tags de temps`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasTempsTagAttributes = $task.TempsTagAttributes.Days.Count -gt 0 -or 
                                        $task.TempsTagAttributes.Weeks.Count -gt 0 -or
                                        $task.TempsTagAttributes.Months.Count -gt 0
                
                if ($hasTempsTagAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.TempsTagAttributes.Days.Count -gt 0) {
                        $markdown += "- Tags de temps en jours:`n"
                        foreach ($tag in $task.TempsTagAttributes.Days) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.TempsTagAttributes.Weeks.Count -gt 0) {
                        $markdown += "- Tags de temps en semaines:`n"
                        foreach ($tag in $task.TempsTagAttributes.Weeks) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.TempsTagAttributes.Months.Count -gt 0) {
                        $markdown += "- Tags de temps en mois:`n"
                        foreach ($tag in $task.TempsTagAttributes.Months) {
                            $markdown += "  - $($tag.Value) $($tag.Unit) (original: $($tag.Original))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,TempsDaysTags,TempsWeeksTags,TempsMonthsTags`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $tempsDaysTags = ""
                if ($task.TempsTagAttributes.Days.Count -gt 0) {
                    $tempsDaysTags = ($task.TempsTagAttributes.Days | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                $tempsWeeksTags = ""
                if ($task.TempsTagAttributes.Weeks.Count -gt 0) {
                    $tempsWeeksTags = ($task.TempsTagAttributes.Weeks | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                $tempsMonthsTags = ""
                if ($task.TempsTagAttributes.Months.Count -gt 0) {
                    $tempsMonthsTags = ($task.TempsTagAttributes.Months | ForEach-Object { "$($_.Value) $($_.Unit)" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$tempsDaysTags`",`"$tempsWeeksTags`",`"$tempsMonthsTags`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-TempsTagAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
