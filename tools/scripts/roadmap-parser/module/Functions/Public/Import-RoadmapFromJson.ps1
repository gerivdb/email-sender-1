<#
.SYNOPSIS
    Importe une roadmap à partir d'un fichier JSON.

.DESCRIPTION
    La fonction Import-RoadmapFromJson importe une roadmap à partir d'un fichier JSON.
    Elle peut reconstruire la structure complète de la roadmap, y compris les métadonnées et les dépendances.

.PARAMETER FilePath
    Chemin du fichier JSON à importer.

.PARAMETER DetectDependencies
    Indique si les dépendances doivent être détectées et reconstruites.

.EXAMPLE
    $roadmap = Import-RoadmapFromJson -FilePath ".\roadmap.json" -DetectDependencies
    Importe une roadmap à partir d'un fichier JSON et reconstruit les dépendances.

.OUTPUTS
    [PSCustomObject] Représentant la roadmap importée.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Import-RoadmapFromJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$DetectDependencies
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Lire le contenu du fichier
    $jsonContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $jsonObject = $jsonContent | ConvertFrom-Json

    # Créer l'objet roadmap
    $roadmap = [PSCustomObject]@{
        Title = $jsonObject.Title
        Description = $jsonObject.Description
        Sections = [System.Collections.ArrayList]::new()
        AllTasks = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
    }

    # Fonction récursive pour convertir un objet JSON en tâche
    function ConvertFrom-JsonTask {
        param (
            [PSCustomObject]$JsonTask,
            [int]$Level = 0
        )
        
        $task = [PSCustomObject]@{
            Id = $JsonTask.Id
            Title = $JsonTask.Title
            Status = $JsonTask.Status
            Level = $Level
            SubTasks = [System.Collections.ArrayList]::new()
            Dependencies = [System.Collections.ArrayList]::new()
            DependentTasks = [System.Collections.ArrayList]::new()
            Metadata = [System.Collections.Generic.Dictionary[string, object]]::new()
        }
        
        # Ajouter les métadonnées si présentes
        if ($JsonTask.PSObject.Properties.Name -contains "Metadata") {
            foreach ($key in $JsonTask.Metadata.PSObject.Properties.Name) {
                $task.Metadata[$key] = $JsonTask.Metadata.$key
            }
        }
        
        # Ajouter les dépendances si présentes (on les traitera plus tard)
        if ($JsonTask.PSObject.Properties.Name -contains "DependsOn") {
            $task | Add-Member -MemberType NoteProperty -Name "_DependsOn" -Value $JsonTask.DependsOn
        }
        
        # Ajouter les sous-tâches
        foreach ($jsonSubTask in $JsonTask.SubTasks) {
            $subTask = ConvertFrom-JsonTask -JsonTask $jsonSubTask -Level ($Level + 1)
            $task.SubTasks.Add($subTask) | Out-Null
        }
        
        return $task
    }

    # Importer les sections et les tâches
    foreach ($jsonSection in $jsonObject.Sections) {
        $section = [PSCustomObject]@{
            Title = $jsonSection.Title
            Tasks = [System.Collections.ArrayList]::new()
        }
        
        # Importer les tâches
        foreach ($jsonTask in $jsonSection.Tasks) {
            $task = ConvertFrom-JsonTask -JsonTask $jsonTask
            $section.Tasks.Add($task) | Out-Null
            
            # Ajouter la tâche au dictionnaire global
            if (-not [string]::IsNullOrEmpty($task.Id)) {
                $roadmap.AllTasks[$task.Id] = $task
            }
            
            # Ajouter récursivement les sous-tâches au dictionnaire global
            function Add-SubTasksToDict {
                param (
                    [PSCustomObject]$Task
                )
                
                foreach ($subTask in $Task.SubTasks) {
                    if (-not [string]::IsNullOrEmpty($subTask.Id)) {
                        $roadmap.AllTasks[$subTask.Id] = $subTask
                    }
                    
                    Add-SubTasksToDict -Task $subTask
                }
            }
            
            Add-SubTasksToDict -Task $task
        }
        
        $roadmap.Sections.Add($section) | Out-Null
    }

    # Reconstruire les dépendances si demandé
    if ($DetectDependencies) {
        # Traiter les dépendances explicites
        foreach ($id in $roadmap.AllTasks.Keys) {
            $task = $roadmap.AllTasks[$id]
            if ($task.PSObject.Properties.Name -contains "_DependsOn") {
                foreach ($dependencyId in $task._DependsOn) {
                    if ($roadmap.AllTasks.ContainsKey($dependencyId)) {
                        $dependency = $roadmap.AllTasks[$dependencyId]
                        $task.Dependencies.Add($dependency) | Out-Null
                        $dependency.DependentTasks.Add($task) | Out-Null
                    }
                }
                
                # Supprimer la propriété temporaire
                $task.PSObject.Properties.Remove("_DependsOn")
            }
        }
    }

    return $roadmap
}
