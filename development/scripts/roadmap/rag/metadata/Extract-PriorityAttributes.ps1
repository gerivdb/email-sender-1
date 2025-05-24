# Export-PriorityAttributes.ps1
# Script pour extraire les attributs de priorité et criticité des tâches dans les fichiers markdown de roadmap
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

# Importer les fonctions communes
$scriptPath = $PSScriptRoot
$commonFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\common\Common-Functions.ps1"

if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
} else {
    # Définir une fonction de journalisation minimale si le fichier commun n'est pas disponible
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [$Level] $Message"
    }
}

# Fonction pour extraire les attributs de priorité et criticité
function Get-PriorityAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Log "Extraction des attributs de priorité et criticité..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        Tasks = @{}
        PriorityAttributes = @{
            Priority = @{}
            Criticality = @{}
            Urgency = @{}
            Importance = @{}
            Impact = @{}
        }
        Stats = @{
            TotalTasks = 0
            TasksWithPriority = 0
            TasksWithCriticality = 0
            TasksWithUrgency = 0
            TasksWithImportance = 0
            TasksWithImpact = 0
            UniquePriorities = @()
            UniqueCriticalities = @()
            UniqueUrgencies = @()
            UniqueImportances = @()
            UniqueImpacts = @()
        }
    }
    
    # Patterns pour détecter les tâches et les attributs de priorité
    $patterns = @{
        Task = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        TaskWithoutId = '^\s*[-*+]\s*\[([ xX])\]\s*(.*)'
        Priority = '(?:priority|priorité):\s*([A-Za-z0-9_\-\.]+)'
        PriorityTag = '#priority:([A-Za-z0-9_\-\.]+)'
        Criticality = '(?:criticality|criticité):\s*([A-Za-z0-9_\-\.]+)'
        CriticalityTag = '#criticality:([A-Za-z0-9_\-\.]+)'
        Urgency = '(?:urgency|urgence):\s*([A-Za-z0-9_\-\.]+)'
        UrgencyTag = '#urgency:([A-Za-z0-9_\-\.]+)'
        Importance = '(?:importance):\s*([A-Za-z0-9_\-\.]+)'
        ImportanceTag = '#importance:([A-Za-z0-9_\-\.]+)'
        Impact = '(?:impact):\s*([A-Za-z0-9_\-\.]+)'
        ImpactTag = '#impact:([A-Za-z0-9_\-\.]+)'
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
                    Id = $taskId
                    Title = $taskTitle
                    Status = if ($taskStatus -match '[xX]') { "Completed" } else { "Pending" }
                    LineNumber = $lineNumber
                    PriorityAttributes = @{
                        Priority = $null
                        Criticality = $null
                        Urgency = $null
                        Importance = $null
                        Impact = $null
                    }
                }
                
                $analysis.Stats.TotalTasks++
            }
            
            # Extraire les attributs de priorité
            $taskLine = $line
            
            # Extraire la priorité (format standard)
            if ($taskLine -match $patterns.Priority) {
                $priority = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Priority = $priority
                $analysis.PriorityAttributes.Priority[$taskId] = $priority
                $analysis.Stats.TasksWithPriority++
                
                if (-not $analysis.Stats.UniquePriorities.Contains($priority)) {
                    $analysis.Stats.UniquePriorities += $priority
                }
            }
            
            # Extraire la priorité (format tag)
            if ($taskLine -match $patterns.PriorityTag) {
                $priority = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Priority = $priority
                $analysis.PriorityAttributes.Priority[$taskId] = $priority
                $analysis.Stats.TasksWithPriority++
                
                if (-not $analysis.Stats.UniquePriorities.Contains($priority)) {
                    $analysis.Stats.UniquePriorities += $priority
                }
            }
            
            # Extraire la criticité (format standard)
            if ($taskLine -match $patterns.Criticality) {
                $criticality = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Criticality = $criticality
                $analysis.PriorityAttributes.Criticality[$taskId] = $criticality
                $analysis.Stats.TasksWithCriticality++
                
                if (-not $analysis.Stats.UniqueCriticalities.Contains($criticality)) {
                    $analysis.Stats.UniqueCriticalities += $criticality
                }
            }
            
            # Extraire la criticité (format tag)
            if ($taskLine -match $patterns.CriticalityTag) {
                $criticality = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Criticality = $criticality
                $analysis.PriorityAttributes.Criticality[$taskId] = $criticality
                $analysis.Stats.TasksWithCriticality++
                
                if (-not $analysis.Stats.UniqueCriticalities.Contains($criticality)) {
                    $analysis.Stats.UniqueCriticalities += $criticality
                }
            }
            
            # Extraire l'urgence (format standard)
            if ($taskLine -match $patterns.Urgency) {
                $urgency = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Urgency = $urgency
                $analysis.PriorityAttributes.Urgency[$taskId] = $urgency
                $analysis.Stats.TasksWithUrgency++
                
                if (-not $analysis.Stats.UniqueUrgencies.Contains($urgency)) {
                    $analysis.Stats.UniqueUrgencies += $urgency
                }
            }
            
            # Extraire l'urgence (format tag)
            if ($taskLine -match $patterns.UrgencyTag) {
                $urgency = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Urgency = $urgency
                $analysis.PriorityAttributes.Urgency[$taskId] = $urgency
                $analysis.Stats.TasksWithUrgency++
                
                if (-not $analysis.Stats.UniqueUrgencies.Contains($urgency)) {
                    $analysis.Stats.UniqueUrgencies += $urgency
                }
            }
            
            # Extraire l'importance (format standard)
            if ($taskLine -match $patterns.Importance) {
                $importance = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Importance = $importance
                $analysis.PriorityAttributes.Importance[$taskId] = $importance
                $analysis.Stats.TasksWithImportance++
                
                if (-not $analysis.Stats.UniqueImportances.Contains($importance)) {
                    $analysis.Stats.UniqueImportances += $importance
                }
            }
            
            # Extraire l'importance (format tag)
            if ($taskLine -match $patterns.ImportanceTag) {
                $importance = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Importance = $importance
                $analysis.PriorityAttributes.Importance[$taskId] = $importance
                $analysis.Stats.TasksWithImportance++
                
                if (-not $analysis.Stats.UniqueImportances.Contains($importance)) {
                    $analysis.Stats.UniqueImportances += $importance
                }
            }
            
            # Extraire l'impact (format standard)
            if ($taskLine -match $patterns.Impact) {
                $impact = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Impact = $impact
                $analysis.PriorityAttributes.Impact[$taskId] = $impact
                $analysis.Stats.TasksWithImpact++
                
                if (-not $analysis.Stats.UniqueImpacts.Contains($impact)) {
                    $analysis.Stats.UniqueImpacts += $impact
                }
            }
            
            # Extraire l'impact (format tag)
            if ($taskLine -match $patterns.ImpactTag) {
                $impact = $matches[1]
                $analysis.Tasks[$taskId].PriorityAttributes.Impact = $impact
                $analysis.PriorityAttributes.Impact[$taskId] = $impact
                $analysis.Stats.TasksWithImpact++
                
                if (-not $analysis.Stats.UniqueImpacts.Contains($impact)) {
                    $analysis.Stats.UniqueImpacts += $impact
                }
            }
        }
    }
    
    return $analysis
}

# Fonction pour formater les résultats
function Format-PriorityAttributesOutput {
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
            $markdown = "# Analyse des attributs de priorité et criticité`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec priorité: $($Analysis.Stats.TasksWithPriority)`n"
            $markdown += "- Tâches avec criticité: $($Analysis.Stats.TasksWithCriticality)`n"
            $markdown += "- Tâches avec urgence: $($Analysis.Stats.TasksWithUrgency)`n"
            $markdown += "- Tâches avec importance: $($Analysis.Stats.TasksWithImportance)`n"
            $markdown += "- Tâches avec impact: $($Analysis.Stats.TasksWithImpact)`n`n"
            
            $markdown += "## Priorités uniques`n`n"
            foreach ($priority in $Analysis.Stats.UniquePriorities) {
                $markdown += "- $priority`n"
            }
            $markdown += "`n"
            
            $markdown += "## Criticités uniques`n`n"
            foreach ($criticality in $Analysis.Stats.UniqueCriticalities) {
                $markdown += "- $criticality`n"
            }
            $markdown += "`n"
            
            $markdown += "## Urgences uniques`n`n"
            foreach ($urgency in $Analysis.Stats.UniqueUrgencies) {
                $markdown += "- $urgency`n"
            }
            $markdown += "`n"
            
            $markdown += "## Importances uniques`n`n"
            foreach ($importance in $Analysis.Stats.UniqueImportances) {
                $markdown += "- $importance`n"
            }
            $markdown += "`n"
            
            $markdown += "## Impacts uniques`n`n"
            foreach ($impact in $Analysis.Stats.UniqueImpacts) {
                $markdown += "- $impact`n"
            }
            $markdown += "`n"
            
            $markdown += "## Tâches avec attributs de priorité`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $priorityAttributes = $task.PriorityAttributes
                
                if ($priorityAttributes.Priority -or $priorityAttributes.Criticality -or $priorityAttributes.Urgency -or $priorityAttributes.Importance -or $priorityAttributes.Impact) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($priorityAttributes.Priority) {
                        $markdown += "- Priorité: $($priorityAttributes.Priority)`n"
                    }
                    
                    if ($priorityAttributes.Criticality) {
                        $markdown += "- Criticité: $($priorityAttributes.Criticality)`n"
                    }
                    
                    if ($priorityAttributes.Urgency) {
                        $markdown += "- Urgence: $($priorityAttributes.Urgency)`n"
                    }
                    
                    if ($priorityAttributes.Importance) {
                        $markdown += "- Importance: $($priorityAttributes.Importance)`n"
                    }
                    
                    if ($priorityAttributes.Impact) {
                        $markdown += "- Impact: $($priorityAttributes.Impact)`n"
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,Priority,Criticality,Urgency,Importance,Impact`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $priorityAttributes = $task.PriorityAttributes
                
                $priority = $priorityAttributes.Priority ?? ""
                $criticality = $priorityAttributes.Criticality ?? ""
                $urgency = $priorityAttributes.Urgency ?? ""
                $importance = $priorityAttributes.Importance ?? ""
                $impact = $priorityAttributes.Impact ?? ""
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$priority`",`"$criticality`",`"$urgency`",`"$importance`",`"$impact`"`n"
            }
            
            return $csv
        }
    }
}

# Fonction principale
function Export-PriorityAttributes {
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
    
    # Extraire les attributs de priorité
    $analysis = Get-PriorityAttributes -Content $Content
    
    # Formater les résultats
    $output = Format-PriorityAttributesOutput -Analysis $analysis -Format $OutputFormat
    
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
Export-PriorityAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat

