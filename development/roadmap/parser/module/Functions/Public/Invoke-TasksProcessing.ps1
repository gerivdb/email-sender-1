<#
.SYNOPSIS
    Traite les tÃ¢ches en commenÃ§ant par les tÃ¢ches enfants.
.DESCRIPTION
    Cette fonction traite les tÃ¢ches en commenÃ§ant par les tÃ¢ches enfants,
    puis remonte vers les tÃ¢ches parentes.
.PARAMETER Tasks
    Les tÃ¢ches Ã  traiter.
.PARAMETER ProcessFunction
    La fonction Ã  appliquer Ã  chaque tÃ¢che.
.PARAMETER ChildrenFirst
    Si spÃ©cifiÃ©, traite les tÃ¢ches enfants avant les tÃ¢ches parentes.
.PARAMETER StepByStep
    Si spÃ©cifiÃ©, traite les tÃ¢ches une par une avec une pause entre chaque tÃ¢che.
.EXAMPLE
    $tasks = Get-TasksFromSelection -Selection "- [ ] 1.1 TÃ¢che parent`n  - [ ] 1.1.1 TÃ¢che enfant" -IdentifyChildren
    Invoke-TasksProcessing -Tasks $tasks -ProcessFunction { param($task) Write-Host $task.Id } -ChildrenFirst
    Traite les tÃ¢ches en commenÃ§ant par les tÃ¢ches enfants.
.OUTPUTS
    System.Collections.ArrayList
#>
function Invoke-TasksProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ProcessFunction,
        
        [Parameter(Mandatory = $false)]
        [switch]$ChildrenFirst,
        
        [Parameter(Mandatory = $false)]
        [switch]$StepByStep
    )
    
    # Initialiser la liste des tÃ¢ches traitÃ©es
    $processedTasks = New-Object System.Collections.ArrayList
    
    # Fonction rÃ©cursive pour traiter les tÃ¢ches
    function Process-TasksRecursively {
        param (
            [Parameter(Mandatory = $true)]
            [array]$TaskList,
            
            [Parameter(Mandatory = $false)]
            [array]$Result = @()
        )
        
        foreach ($task in $TaskList) {
            if ($ChildrenFirst) {
                # Traiter d'abord les enfants
                if ($task.Children.Count -gt 0) {
                    $Result = Process-TasksRecursively -TaskList $task.Children -Result $Result
                }
                
                # Puis traiter la tÃ¢che parente
                & $ProcessFunction $task
                $Result += $task
                
                # Pause entre chaque tÃ¢che si demandÃ©
                if ($StepByStep) {
                    Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Yellow
                    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            else {
                # Traiter d'abord la tÃ¢che parente
                & $ProcessFunction $task
                $Result += $task
                
                # Pause entre chaque tÃ¢che si demandÃ©
                if ($StepByStep) {
                    Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Yellow
                    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                
                # Puis traiter les enfants
                if ($task.Children.Count -gt 0) {
                    $Result = Process-TasksRecursively -TaskList $task.Children -Result $Result
                }
            }
        }
        
        return $Result
    }
    
    # Obtenir les tÃ¢ches racines (sans parent)
    $rootTasks = $Tasks | Where-Object { $_.Parent -eq $null }
    
    # Traiter les tÃ¢ches rÃ©cursivement
    $processedTasks = Process-TasksRecursively -TaskList $rootTasks
    
    return $processedTasks
}
