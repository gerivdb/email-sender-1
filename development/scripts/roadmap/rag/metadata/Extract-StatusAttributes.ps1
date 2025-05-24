# Export-StatusAttributes.ps1
# Script pour extraire les attributs de statut et progression des tâches dans les fichiers markdown de roadmap
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

# Fonction pour extraire les attributs de statut et progression
function Get-StatusAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Log "Extraction des attributs de statut et progression..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        Tasks = @{}
        StatusAttributes = @{
            DetailedStatus = @{}
            Progress = @{}
            Phase = @{}
            Stage = @{}
            State = @{}
        }
        Stats = @{
            TotalTasks = 0
            CompletedTasks = 0
            PendingTasks = 0
            TasksWithDetailedStatus = 0
            TasksWithProgress = 0
            TasksWithPhase = 0
            TasksWithStage = 0
            TasksWithState = 0
            UniqueDetailedStatuses = @()
            UniquePhases = @()
            UniqueStages = @()
            UniqueStates = @()
        }
    }
    
    # Patterns pour détecter les tâches et les attributs de statut
    $patterns = @{
        Task = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        TaskWithoutId = '^\s*[-*+]\s*\[([ xX])\]\s*(.*)'
        DetailedStatus = '(?:status|statut):\s*([A-Za-z0-9_\-\.]+)'
        Progress = '(?:progress|progression|avancement):\s*(\d+(?:\.\d+)?)\s*%?'
        Phase = '(?:phase|étape):\s*([A-Za-z0-9_\-\. ]+)'
        Stage = '(?:stage|stade):\s*([A-Za-z0-9_\-\. ]+)'
        State = '(?:state|état):\s*([A-Za-z0-9_\-\. ]+)'
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
                $basicStatus = if ($taskStatus -match '[xX]') { "Completed" } else { "Pending" }
                
                $analysis.Tasks[$taskId] = @{
                    Id = $taskId
                    Title = $taskTitle
                    Status = $basicStatus
                    LineNumber = $lineNumber
                    StatusAttributes = @{
                        DetailedStatus = $null
                        Progress = $null
                        Phase = $null
                        Stage = $null
                        State = $null
                    }
                }
                
                $analysis.Stats.TotalTasks++
                
                if ($basicStatus -eq "Completed") {
                    $analysis.Stats.CompletedTasks++
                } else {
                    $analysis.Stats.PendingTasks++
                }
            }
            
            # Extraire les attributs de statut
            $taskLine = $line
            
            # Extraire le statut détaillé
            if ($taskLine -match $patterns.DetailedStatus) {
                $detailedStatus = $matches[1]
                $analysis.Tasks[$taskId].StatusAttributes.DetailedStatus = $detailedStatus
                $analysis.StatusAttributes.DetailedStatus[$taskId] = $detailedStatus
                $analysis.Stats.TasksWithDetailedStatus++
                
                if (-not $analysis.Stats.UniqueDetailedStatuses.Contains($detailedStatus)) {
                    $analysis.Stats.UniqueDetailedStatuses += $detailedStatus
                }
            }
            
            # Extraire la progression
            if ($taskLine -match $patterns.Progress) {
                $progress = [double]$matches[1]
                $analysis.Tasks[$taskId].StatusAttributes.Progress = $progress
                $analysis.StatusAttributes.Progress[$taskId] = $progress
                $analysis.Stats.TasksWithProgress++
            }
            
            # Extraire la phase
            if ($taskLine -match $patterns.Phase) {
                $phase = $matches[1]
                $analysis.Tasks[$taskId].StatusAttributes.Phase = $phase
                $analysis.StatusAttributes.Phase[$taskId] = $phase
                $analysis.Stats.TasksWithPhase++
                
                if (-not $analysis.Stats.UniquePhases.Contains($phase)) {
                    $analysis.Stats.UniquePhases += $phase
                }
            }
            
            # Extraire le stade
            if ($taskLine -match $patterns.Stage) {
                $stage = $matches[1]
                $analysis.Tasks[$taskId].StatusAttributes.Stage = $stage
                $analysis.StatusAttributes.Stage[$taskId] = $stage
                $analysis.Stats.TasksWithStage++
                
                if (-not $analysis.Stats.UniqueStages.Contains($stage)) {
                    $analysis.Stats.UniqueStages += $stage
                }
            }
            
            # Extraire l'état
            if ($taskLine -match $patterns.State) {
                $state = $matches[1]
                $analysis.Tasks[$taskId].StatusAttributes.State = $state
                $analysis.StatusAttributes.State[$taskId] = $state
                $analysis.Stats.TasksWithState++
                
                if (-not $analysis.Stats.UniqueStates.Contains($state)) {
                    $analysis.Stats.UniqueStates += $state
                }
            }
        }
    }
    
    return $analysis
}

# Fonction pour formater les résultats
function Format-StatusAttributesOutput {
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
            $markdown = "# Analyse des attributs de statut et progression`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches complétées: $($Analysis.Stats.CompletedTasks)`n"
            $markdown += "- Tâches en attente: $($Analysis.Stats.PendingTasks)`n"
            $markdown += "- Tâches avec statut détaillé: $($Analysis.Stats.TasksWithDetailedStatus)`n"
            $markdown += "- Tâches avec progression: $($Analysis.Stats.TasksWithProgress)`n"
            $markdown += "- Tâches avec phase: $($Analysis.Stats.TasksWithPhase)`n"
            $markdown += "- Tâches avec stade: $($Analysis.Stats.TasksWithStage)`n"
            $markdown += "- Tâches avec état: $($Analysis.Stats.TasksWithState)`n`n"
            
            $markdown += "## Statuts détaillés uniques`n`n"
            foreach ($status in $Analysis.Stats.UniqueDetailedStatuses) {
                $markdown += "- $status`n"
            }
            $markdown += "`n"
            
            $markdown += "## Phases uniques`n`n"
            foreach ($phase in $Analysis.Stats.UniquePhases) {
                $markdown += "- $phase`n"
            }
            $markdown += "`n"
            
            $markdown += "## Stades uniques`n`n"
            foreach ($stage in $Analysis.Stats.UniqueStages) {
                $markdown += "- $stage`n"
            }
            $markdown += "`n"
            
            $markdown += "## États uniques`n`n"
            foreach ($state in $Analysis.Stats.UniqueStates) {
                $markdown += "- $state`n"
            }
            $markdown += "`n"
            
            $markdown += "## Tâches avec attributs de statut`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $statusAttributes = $task.StatusAttributes
                
                if ($statusAttributes.DetailedStatus -or $statusAttributes.Progress -or $statusAttributes.Phase -or $statusAttributes.Stage -or $statusAttributes.State) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    $markdown += "- Statut de base: $($task.Status)`n"
                    
                    if ($statusAttributes.DetailedStatus) {
                        $markdown += "- Statut détaillé: $($statusAttributes.DetailedStatus)`n"
                    }
                    
                    if ($statusAttributes.Progress) {
                        $markdown += "- Progression: $($statusAttributes.Progress)%`n"
                    }
                    
                    if ($statusAttributes.Phase) {
                        $markdown += "- Phase: $($statusAttributes.Phase)`n"
                    }
                    
                    if ($statusAttributes.Stage) {
                        $markdown += "- Stade: $($statusAttributes.Stage)`n"
                    }
                    
                    if ($statusAttributes.State) {
                        $markdown += "- État: $($statusAttributes.State)`n"
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,BasicStatus,DetailedStatus,Progress,Phase,Stage,State`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $statusAttributes = $task.StatusAttributes
                
                $detailedStatus = $statusAttributes.DetailedStatus ?? ""
                $progress = $statusAttributes.Progress ?? ""
                $phase = $statusAttributes.Phase ?? ""
                $stage = $statusAttributes.Stage ?? ""
                $state = $statusAttributes.State ?? ""
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$detailedStatus`",`"$progress`",`"$phase`",`"$stage`",`"$state`"`n"
            }
            
            return $csv
        }
    }
}

# Fonction principale
function Export-StatusAttributes {
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
    
    # Extraire les attributs de statut
    $analysis = Get-StatusAttributes -Content $Content
    
    # Formater les résultats
    $output = Format-StatusAttributesOutput -Analysis $analysis -Format $OutputFormat
    
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
Export-StatusAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat

