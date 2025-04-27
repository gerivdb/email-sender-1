<#
.SYNOPSIS
    Exécute le mode de débogage pour une tâche spécifique du roadmap.
.DESCRIPTION
    Cette fonction exécute le mode de débogage pour une tâche spécifique du roadmap,
    permettant d'identifier et de résoudre les problèmes.
.PARAMETER TaskIdentifier
    Identifiant de la tâche à déboguer.
.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap.
.PARAMETER GeneratePatch
    Si spécifié, génère un patch pour corriger les problèmes identifiés.
.PARAMETER IncludeStackTrace
    Si spécifié, inclut la trace de la pile dans les messages d'erreur.
.EXAMPLE
    Invoke-RoadmapDebug -TaskIdentifier "1.1" -RoadmapPath "Roadmap\roadmap.md"
    Exécute le mode de débogage pour la tâche 1.1.
.EXAMPLE
    Invoke-RoadmapDebug -TaskIdentifier "1.1" -RoadmapPath "Roadmap\roadmap.md" -GeneratePatch
    Exécute le mode de débogage pour la tâche 1.1 et génère un patch.
#>
function Invoke-RoadmapDebug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter()]
        [switch]$GeneratePatch,
        
        [Parameter()]
        [switch]$IncludeStackTrace
    )
    
    # Initialiser le résultat
    $result = @{
        Success = $false
        Errors = @()
        Patch = $null
    }
    
    try {
        # Vérifier si le fichier de roadmap existe
        if (-not (Test-Path -Path $RoadmapPath)) {
            throw "Le fichier de roadmap n'existe pas à l'emplacement spécifié : $RoadmapPath"
        }
        
        # Lire le contenu du roadmap
        $roadmapContent = Get-Content -Path $RoadmapPath -Raw
        
        # Rechercher la tâche spécifiée
        $taskPattern = "(?m)^(\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s+.+?)(?=\n\s*[-*]\s*\[[ x]\]|\z)"
        $taskMatch = [regex]::Match($roadmapContent, $taskPattern)
        
        if (-not $taskMatch.Success) {
            throw "La tâche $TaskIdentifier n'a pas été trouvée dans le roadmap."
        }
        
        $taskContent = $taskMatch.Groups[1].Value
        Write-Host "Tâche trouvée : $taskContent" -ForegroundColor Green
        
        # Analyser la tâche pour trouver des problèmes
        $problems = @()
        
        # Vérifier si la tâche a une description
        if ($taskContent -match "^\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s*$") {
            $problems += "La tâche n'a pas de description."
        }
        
        # Vérifier si la tâche a des sous-tâches
        $subTaskPattern = "(?m)^\s+[-*]\s*\[[ x]\]"
        $hasSubTasks = [regex]::IsMatch($taskContent, $subTaskPattern)
        
        if (-not $hasSubTasks) {
            $problems += "La tâche n'a pas de sous-tâches."
        }
        
        # Vérifier si toutes les sous-tâches sont complétées
        $subTaskCompletedPattern = "(?m)^\s+[-*]\s*\[[x]\]"
        $subTaskIncompletePattern = "(?m)^\s+[-*]\s*\[ \]"
        $hasCompletedSubTasks = [regex]::IsMatch($taskContent, $subTaskCompletedPattern)
        $hasIncompleteSubTasks = [regex]::IsMatch($taskContent, $subTaskIncompletePattern)
        
        if ($hasSubTasks -and $hasIncompleteSubTasks) {
            $problems += "La tâche a des sous-tâches incomplètes."
        }
        
        # Vérifier si la tâche est marquée comme complétée
        $isTaskCompleted = $taskContent -match "^\s*[-*]\s*\[x\]"
        
        if ($isTaskCompleted -and $hasIncompleteSubTasks) {
            $problems += "La tâche est marquée comme complétée mais a des sous-tâches incomplètes."
        }
        
        if (-not $isTaskCompleted -and $hasSubTasks -and -not $hasIncompleteSubTasks) {
            $problems += "La tâche a toutes ses sous-tâches complétées mais n'est pas marquée comme complétée."
        }
        
        # Générer un rapport
        if ($problems.Count -eq 0) {
            Write-Host "Aucun problème trouvé pour la tâche $TaskIdentifier." -ForegroundColor Green
            $result.Success = $true
        } else {
            Write-Host "Problèmes trouvés pour la tâche $TaskIdentifier :" -ForegroundColor Yellow
            foreach ($problem in $problems) {
                Write-Host "  - $problem" -ForegroundColor Yellow
                $result.Errors += $problem
            }
            
            # Générer un patch si demandé
            if ($GeneratePatch) {
                $patch = "# Patch pour la tâche $TaskIdentifier`n`n"
                
                # Corriger les problèmes
                $newTaskContent = $taskContent
                
                # Ajouter une description si manquante
                if ($newTaskContent -match "^\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s*$") {
                    $newTaskContent = $newTaskContent -replace "^\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s*$", "`$0 Description de la tâche"
                    $patch += "- Ajout d'une description à la tâche`n"
                }
                
                # Ajouter des sous-tâches si manquantes
                if (-not $hasSubTasks) {
                    $newTaskContent += "`n  - [ ] Sous-tâche 1`n  - [ ] Sous-tâche 2"
                    $patch += "- Ajout de sous-tâches à la tâche`n"
                }
                
                # Mettre à jour le statut de la tâche
                if (-not $isTaskCompleted -and $hasSubTasks -and -not $hasIncompleteSubTasks) {
                    $newTaskContent = $newTaskContent -replace "^\s*[-*]\s*\[ \]", "`$0".Replace("[ ]", "[x]")
                    $patch += "- Marquage de la tâche comme complétée`n"
                }
                
                if ($isTaskCompleted -and $hasIncompleteSubTasks) {
                    $newTaskContent = $newTaskContent -replace "^\s*[-*]\s*\[x\]", "`$0".Replace("[x]", "[ ]")
                    $patch += "- Marquage de la tâche comme incomplète`n"
                }
                
                $patch += "`n## Contenu original`n`n```markdown`n$taskContent`n````n`n## Contenu corrigé`n`n```markdown`n$newTaskContent`n```"
                $result.Patch = $patch
            }
        }
        
        return $result
    } catch {
        $errorMessage = "Erreur lors du débogage de la tâche $TaskIdentifier : $_"
        Write-Error $errorMessage
        
        if ($IncludeStackTrace) {
            Write-Error $_.ScriptStackTrace
        }
        
        $result.Errors += $errorMessage
        return $result
    }
}
