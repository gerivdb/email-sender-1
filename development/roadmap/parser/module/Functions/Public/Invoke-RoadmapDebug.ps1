<#
.SYNOPSIS
    ExÃ©cute le mode de dÃ©bogage pour une tÃ¢che spÃ©cifique du roadmap.
.DESCRIPTION
    Cette fonction exÃ©cute le mode de dÃ©bogage pour une tÃ¢che spÃ©cifique du roadmap,
    permettant d'identifier et de rÃ©soudre les problÃ¨mes.
.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  dÃ©boguer.
.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap.
.PARAMETER GeneratePatch
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un patch pour corriger les problÃ¨mes identifiÃ©s.
.PARAMETER IncludeStackTrace
    Si spÃ©cifiÃ©, inclut la trace de la pile dans les messages d'erreur.
.EXAMPLE
    Invoke-RoadmapDebug -TaskIdentifier "1.1" -RoadmapPath "Roadmap\roadmap.md"
    ExÃ©cute le mode de dÃ©bogage pour la tÃ¢che 1.1.
.EXAMPLE
    Invoke-RoadmapDebug -TaskIdentifier "1.1" -RoadmapPath "Roadmap\roadmap.md" -GeneratePatch
    ExÃ©cute le mode de dÃ©bogage pour la tÃ¢che 1.1 et gÃ©nÃ¨re un patch.
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
    
    # Initialiser le rÃ©sultat
    $result = @{
        Success = $false
        Errors = @()
        Patch = $null
    }
    
    try {
        # VÃ©rifier si le fichier de roadmap existe
        if (-not (Test-Path -Path $RoadmapPath)) {
            throw "Le fichier de roadmap n'existe pas Ã  l'emplacement spÃ©cifiÃ© : $RoadmapPath"
        }
        
        # Lire le contenu du roadmap
        $roadmapContent = Get-Content -Path $RoadmapPath -Raw
        
        # Rechercher la tÃ¢che spÃ©cifiÃ©e
        $taskPattern = "(?m)^(\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s+.+?)(?=\n\s*[-*]\s*\[[ x]\]|\z)"
        $taskMatch = [regex]::Match($roadmapContent, $taskPattern)
        
        if (-not $taskMatch.Success) {
            throw "La tÃ¢che $TaskIdentifier n'a pas Ã©tÃ© trouvÃ©e dans le roadmap."
        }
        
        $taskContent = $taskMatch.Groups[1].Value
        Write-Host "TÃ¢che trouvÃ©e : $taskContent" -ForegroundColor Green
        
        # Analyser la tÃ¢che pour trouver des problÃ¨mes
        $problems = @()
        
        # VÃ©rifier si la tÃ¢che a une description
        if ($taskContent -match "^\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s*$") {
            $problems += "La tÃ¢che n'a pas de description."
        }
        
        # VÃ©rifier si la tÃ¢che a des sous-tÃ¢ches
        $subTaskPattern = "(?m)^\s+[-*]\s*\[[ x]\]"
        $hasSubTasks = [regex]::IsMatch($taskContent, $subTaskPattern)
        
        if (-not $hasSubTasks) {
            $problems += "La tÃ¢che n'a pas de sous-tÃ¢ches."
        }
        
        # VÃ©rifier si toutes les sous-tÃ¢ches sont complÃ©tÃ©es
        $subTaskCompletedPattern = "(?m)^\s+[-*]\s*\[[x]\]"
        $subTaskIncompletePattern = "(?m)^\s+[-*]\s*\[ \]"
        $hasCompletedSubTasks = [regex]::IsMatch($taskContent, $subTaskCompletedPattern)
        $hasIncompleteSubTasks = [regex]::IsMatch($taskContent, $subTaskIncompletePattern)
        
        if ($hasSubTasks -and $hasIncompleteSubTasks) {
            $problems += "La tÃ¢che a des sous-tÃ¢ches incomplÃ¨tes."
        }
        
        # VÃ©rifier si la tÃ¢che est marquÃ©e comme complÃ©tÃ©e
        $isTaskCompleted = $taskContent -match "^\s*[-*]\s*\[x\]"
        
        if ($isTaskCompleted -and $hasIncompleteSubTasks) {
            $problems += "La tÃ¢che est marquÃ©e comme complÃ©tÃ©e mais a des sous-tÃ¢ches incomplÃ¨tes."
        }
        
        if (-not $isTaskCompleted -and $hasSubTasks -and -not $hasIncompleteSubTasks) {
            $problems += "La tÃ¢che a toutes ses sous-tÃ¢ches complÃ©tÃ©es mais n'est pas marquÃ©e comme complÃ©tÃ©e."
        }
        
        # GÃ©nÃ©rer un rapport
        if ($problems.Count -eq 0) {
            Write-Host "Aucun problÃ¨me trouvÃ© pour la tÃ¢che $TaskIdentifier." -ForegroundColor Green
            $result.Success = $true
        } else {
            Write-Host "ProblÃ¨mes trouvÃ©s pour la tÃ¢che $TaskIdentifier :" -ForegroundColor Yellow
            foreach ($problem in $problems) {
                Write-Host "  - $problem" -ForegroundColor Yellow
                $result.Errors += $problem
            }
            
            # GÃ©nÃ©rer un patch si demandÃ©
            if ($GeneratePatch) {
                $patch = "# Patch pour la tÃ¢che $TaskIdentifier`n`n"
                
                # Corriger les problÃ¨mes
                $newTaskContent = $taskContent
                
                # Ajouter une description si manquante
                if ($newTaskContent -match "^\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s*$") {
                    $newTaskContent = $newTaskContent -replace "^\s*[-*]\s*\[[ x]\]\s*$TaskIdentifier\s*$", "`$0 Description de la tÃ¢che"
                    $patch += "- Ajout d'une description Ã  la tÃ¢che`n"
                }
                
                # Ajouter des sous-tÃ¢ches si manquantes
                if (-not $hasSubTasks) {
                    $newTaskContent += "`n  - [ ] Sous-tÃ¢che 1`n  - [ ] Sous-tÃ¢che 2"
                    $patch += "- Ajout de sous-tÃ¢ches Ã  la tÃ¢che`n"
                }
                
                # Mettre Ã  jour le statut de la tÃ¢che
                if (-not $isTaskCompleted -and $hasSubTasks -and -not $hasIncompleteSubTasks) {
                    $newTaskContent = $newTaskContent -replace "^\s*[-*]\s*\[ \]", "`$0".Replace("[ ]", "[x]")
                    $patch += "- Marquage de la tÃ¢che comme complÃ©tÃ©e`n"
                }
                
                if ($isTaskCompleted -and $hasIncompleteSubTasks) {
                    $newTaskContent = $newTaskContent -replace "^\s*[-*]\s*\[x\]", "`$0".Replace("[x]", "[ ]")
                    $patch += "- Marquage de la tÃ¢che comme incomplÃ¨te`n"
                }
                
                $patch += "`n## Contenu original`n`n```markdown`n$taskContent`n````n`n## Contenu corrigÃ©`n`n```markdown`n$newTaskContent`n```"
                $result.Patch = $patch
            }
        }
        
        return $result
    } catch {
        $errorMessage = "Erreur lors du dÃ©bogage de la tÃ¢che $TaskIdentifier : $_"
        Write-Error $errorMessage
        
        if ($IncludeStackTrace) {
            Write-Error $_.ScriptStackTrace
        }
        
        $result.Errors += $errorMessage
        return $result
    }
}
