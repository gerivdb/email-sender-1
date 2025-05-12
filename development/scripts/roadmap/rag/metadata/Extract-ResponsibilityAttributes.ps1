# Extract-ResponsibilityAttributes.ps1
# Script pour extraire les attributs de responsabilité des tâches dans les fichiers markdown de roadmap
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

# Fonction pour extraire les attributs de responsabilité
function Get-ResponsibilityAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Log "Extraction des attributs de responsabilité..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        Tasks = @{}
        ResponsibilityAttributes = @{
            Assignees = @{}
            Teams = @{}
            Departments = @{}
            Contacts = @{}
            Stakeholders = @{}
        }
        Stats = @{
            TotalTasks = 0
            TasksWithAssignees = 0
            TasksWithTeams = 0
            TasksWithDepartments = 0
            TasksWithContacts = 0
            TasksWithStakeholders = 0
            UniqueAssignees = @()
            UniqueTeams = @()
            UniqueDepartments = @()
        }
    }
    
    # Patterns pour détecter les tâches et les attributs de responsabilité
    $patterns = @{
        Task = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        TaskWithoutId = '^\s*[-*+]\s*\[([ xX])\]\s*(.*)'
        Assignee = '(?:assignee|assigné|responsable|assigned to):\s*(@?[A-Za-z0-9_\-\.]+)'
        Team = '(?:team|équipe):\s*([A-Za-z0-9_\-\.]+)'
        Department = '(?:department|département|service):\s*([A-Za-z0-9_\-\. ]+)'
        Contact = '(?:contact|référent):\s*([A-Za-z0-9_\-\. @]+)'
        Stakeholder = '(?:stakeholder|partie prenante):\s*([A-Za-z0-9_\-\. @]+)'
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
                    ResponsibilityAttributes = @{
                        Assignee = $null
                        Team = $null
                        Department = $null
                        Contact = $null
                        Stakeholder = $null
                    }
                }
                
                $analysis.Stats.TotalTasks++
            }
            
            # Extraire les attributs de responsabilité
            $taskLine = $line
            
            # Extraire l'assigné
            if ($taskLine -match $patterns.Assignee) {
                $assignee = $matches[1]
                $analysis.Tasks[$taskId].ResponsibilityAttributes.Assignee = $assignee
                $analysis.ResponsibilityAttributes.Assignees[$taskId] = $assignee
                $analysis.Stats.TasksWithAssignees++
                
                if (-not $analysis.Stats.UniqueAssignees.Contains($assignee)) {
                    $analysis.Stats.UniqueAssignees += $assignee
                }
            }
            
            # Extraire l'équipe
            if ($taskLine -match $patterns.Team) {
                $team = $matches[1]
                $analysis.Tasks[$taskId].ResponsibilityAttributes.Team = $team
                $analysis.ResponsibilityAttributes.Teams[$taskId] = $team
                $analysis.Stats.TasksWithTeams++
                
                if (-not $analysis.Stats.UniqueTeams.Contains($team)) {
                    $analysis.Stats.UniqueTeams += $team
                }
            }
            
            # Extraire le département
            if ($taskLine -match $patterns.Department) {
                $department = $matches[1]
                $analysis.Tasks[$taskId].ResponsibilityAttributes.Department = $department
                $analysis.ResponsibilityAttributes.Departments[$taskId] = $department
                $analysis.Stats.TasksWithDepartments++
                
                if (-not $analysis.Stats.UniqueDepartments.Contains($department)) {
                    $analysis.Stats.UniqueDepartments += $department
                }
            }
            
            # Extraire le contact
            if ($taskLine -match $patterns.Contact) {
                $contact = $matches[1]
                $analysis.Tasks[$taskId].ResponsibilityAttributes.Contact = $contact
                $analysis.ResponsibilityAttributes.Contacts[$taskId] = $contact
                $analysis.Stats.TasksWithContacts++
            }
            
            # Extraire la partie prenante
            if ($taskLine -match $patterns.Stakeholder) {
                $stakeholder = $matches[1]
                $analysis.Tasks[$taskId].ResponsibilityAttributes.Stakeholder = $stakeholder
                $analysis.ResponsibilityAttributes.Stakeholders[$taskId] = $stakeholder
                $analysis.Stats.TasksWithStakeholders++
            }
        }
    }
    
    return $analysis
}

# Fonction pour formater les résultats
function Format-ResponsibilityAttributesOutput {
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
            $markdown = "# Analyse des attributs de responsabilité`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec assignés: $($Analysis.Stats.TasksWithAssignees)`n"
            $markdown += "- Tâches avec équipes: $($Analysis.Stats.TasksWithTeams)`n"
            $markdown += "- Tâches avec départements: $($Analysis.Stats.TasksWithDepartments)`n"
            $markdown += "- Tâches avec contacts: $($Analysis.Stats.TasksWithContacts)`n"
            $markdown += "- Tâches avec parties prenantes: $($Analysis.Stats.TasksWithStakeholders)`n`n"
            
            $markdown += "## Assignés uniques`n`n"
            foreach ($assignee in $Analysis.Stats.UniqueAssignees) {
                $markdown += "- $assignee`n"
            }
            $markdown += "`n"
            
            $markdown += "## Équipes uniques`n`n"
            foreach ($team in $Analysis.Stats.UniqueTeams) {
                $markdown += "- $team`n"
            }
            $markdown += "`n"
            
            $markdown += "## Départements uniques`n`n"
            foreach ($department in $Analysis.Stats.UniqueDepartments) {
                $markdown += "- $department`n"
            }
            $markdown += "`n"
            
            $markdown += "## Tâches avec attributs de responsabilité`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $responsibilityAttributes = $task.ResponsibilityAttributes
                
                if ($responsibilityAttributes.Assignee -or $responsibilityAttributes.Team -or $responsibilityAttributes.Department -or $responsibilityAttributes.Contact -or $responsibilityAttributes.Stakeholder) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($responsibilityAttributes.Assignee) {
                        $markdown += "- Assigné: $($responsibilityAttributes.Assignee)`n"
                    }
                    
                    if ($responsibilityAttributes.Team) {
                        $markdown += "- Équipe: $($responsibilityAttributes.Team)`n"
                    }
                    
                    if ($responsibilityAttributes.Department) {
                        $markdown += "- Département: $($responsibilityAttributes.Department)`n"
                    }
                    
                    if ($responsibilityAttributes.Contact) {
                        $markdown += "- Contact: $($responsibilityAttributes.Contact)`n"
                    }
                    
                    if ($responsibilityAttributes.Stakeholder) {
                        $markdown += "- Partie prenante: $($responsibilityAttributes.Stakeholder)`n"
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,Assignee,Team,Department,Contact,Stakeholder`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                $responsibilityAttributes = $task.ResponsibilityAttributes
                
                $assignee = $responsibilityAttributes.Assignee ?? ""
                $team = $responsibilityAttributes.Team ?? ""
                $department = $responsibilityAttributes.Department ?? ""
                $contact = $responsibilityAttributes.Contact ?? ""
                $stakeholder = $responsibilityAttributes.Stakeholder ?? ""
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$assignee`",`"$team`",`"$department`",`"$contact`",`"$stakeholder`"`n"
            }
            
            return $csv
        }
    }
}

# Fonction principale
function Extract-ResponsibilityAttributes {
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
    
    # Extraire les attributs de responsabilité
    $analysis = Get-ResponsibilityAttributes -Content $Content
    
    # Formater les résultats
    $output = Format-ResponsibilityAttributesOutput -Analysis $analysis -Format $OutputFormat
    
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
Extract-ResponsibilityAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
