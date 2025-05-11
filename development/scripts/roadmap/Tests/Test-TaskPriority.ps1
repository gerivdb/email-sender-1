# Test-TaskPriority.ps1
# Script de test pour les fonctions d'attribution de niveaux de priorité
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskPriority.ps1"
Write-Host "Chargement du script: $scriptPath" -ForegroundColor Cyan
if (Test-Path $scriptPath) {
    Write-Host "Le fichier existe." -ForegroundColor Green
    . $scriptPath
    Write-Host "Script chargé avec succès." -ForegroundColor Green
} else {
    Write-Host "Le fichier n'existe pas!" -ForegroundColor Red
    exit
}

# Fonction pour créer des tâches de test
function New-TestTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Tâche $Id",

        [Parameter(Mandatory = $false)]
        [string]$ParentId = $null,

        [Parameter(Mandatory = $false)]
        [string[]]$Children = @(),

        [Parameter(Mandatory = $false)]
        [string]$Status = $null,

        [Parameter(Mandatory = $false)]
        [string]$Priority = $null,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DueDate = $null,

        [Parameter(Mandatory = $false)]
        [string]$Importance = $null,

        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @()
    )

    return [PSCustomObject]@{
        Id           = $Id
        Title        = $Title
        ParentId     = $ParentId
        Children     = $Children
        Status       = $Status
        Priority     = $Priority
        DueDate      = $DueDate
        Importance   = $Importance
        Dependencies = $Dependencies
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions d'attribution de niveaux de priorité..." -ForegroundColor Cyan

    Test-TaskPriorityLevel
    Test-TaskPriorityAssignment
    Test-TaskPriorityHierarchy

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction Get-TaskPriorityLevel
function Test-TaskPriorityLevel {
    Write-Host "`nTest de la fonction Get-TaskPriorityLevel:" -ForegroundColor Yellow

    # Test 1: Déterminer le niveau de priorité en fonction du niveau hiérarchique
    Write-Host "  Test 1: Déterminer le niveau de priorité en fonction du niveau hiérarchique" -ForegroundColor Gray
    $task = New-TestTask -Id "1" -Title "Tâche de niveau 1"

    $result1a = Get-TaskPriorityLevel -Task $task -HierarchyLevel 1 -RandomSeed 12345
    $result1b = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -RandomSeed 12345
    $result1c = Get-TaskPriorityLevel -Task $task -HierarchyLevel 3 -RandomSeed 12345
    $result1d = Get-TaskPriorityLevel -Task $task -HierarchyLevel 4 -RandomSeed 12345

    Write-Host "    Niveau 1: $result1a" -ForegroundColor Gray
    Write-Host "    Niveau 2: $result1b" -ForegroundColor Gray
    Write-Host "    Niveau 3: $result1c" -ForegroundColor Gray
    Write-Host "    Niveau 4: $result1d" -ForegroundColor Gray

    $hierarchyPriorityCorrect = ($result1a -eq "Critical" -or $result1a -eq "High") -and
                               ($result1b -eq "High" -or $result1b -eq "Medium") -and
                               ($result1c -eq "Medium" -or $result1c -eq "Low") -and
                               ($result1d -eq "Low")

    if ($hierarchyPriorityCorrect) {
        Write-Host "    Succès: Les priorités sont correctement attribuées en fonction du niveau hiérarchique." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les priorités ne sont pas correctement attribuées en fonction du niveau hiérarchique." -ForegroundColor Red
    }

    # Test 2: Déterminer le niveau de priorité en fonction de la priorité du parent
    Write-Host "  Test 2: Déterminer le niveau de priorité en fonction de la priorité du parent" -ForegroundColor Gray

    $result2a = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -ParentPriority "Critical" -RandomSeed 12345
    $result2b = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -ParentPriority "High" -RandomSeed 12345
    $result2c = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -ParentPriority "Medium" -RandomSeed 12345
    $result2d = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -ParentPriority "Low" -RandomSeed 12345

    Write-Host "    Parent Critical: $result2a" -ForegroundColor Gray
    Write-Host "    Parent High: $result2b" -ForegroundColor Gray
    Write-Host "    Parent Medium: $result2c" -ForegroundColor Gray
    Write-Host "    Parent Low: $result2d" -ForegroundColor Gray

    $parentPriorityCorrect = ($result2a -eq "Critical" -or $result2a -eq "High") -and
                            ($result2b -eq "High" -or $result2b -eq "Medium") -and
                            ($result2c -eq "Medium" -or $result2c -eq "Low") -and
                            ($result2d -eq "Low")

    if ($parentPriorityCorrect) {
        Write-Host "    Succès: Les priorités sont correctement attribuées en fonction de la priorité du parent." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les priorités ne sont pas correctement attribuées en fonction de la priorité du parent." -ForegroundColor Red
    }

    # Test 3: Déterminer le niveau de priorité en fonction du statut
    Write-Host "  Test 3: Déterminer le niveau de priorité en fonction du statut" -ForegroundColor Gray

    $result3a = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -Status "InProgress" -RandomSeed 12345
    $result3b = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -Status "Blocked" -RandomSeed 12345
    $result3c = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -Status "NotStarted" -RandomSeed 12345
    $result3d = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -Status "Completed" -RandomSeed 12345

    Write-Host "    Statut InProgress: $result3a" -ForegroundColor Gray
    Write-Host "    Statut Blocked: $result3b" -ForegroundColor Gray
    Write-Host "    Statut NotStarted: $result3c" -ForegroundColor Gray
    Write-Host "    Statut Completed: $result3d" -ForegroundColor Gray

    $statusPriorityCorrect = ($result3a -eq "High" -or $result3a -eq "Medium") -and
                            ($result3b -eq "Critical" -or $result3b -eq "High") -and
                            ($result3c -eq "Medium" -or $result3c -eq "Low") -and
                            ($result3d -eq "Low")

    if ($statusPriorityCorrect) {
        Write-Host "    Succès: Les priorités sont correctement attribuées en fonction du statut." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les priorités ne sont pas correctement attribuées en fonction du statut." -ForegroundColor Red
    }

    # Test 4: Déterminer le niveau de priorité en fonction de la date d'échéance
    Write-Host "  Test 4: Déterminer le niveau de priorité en fonction de la date d'échéance" -ForegroundColor Gray

    $result4a = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -DueDate (Get-Date).AddDays(3) -RandomSeed 12345
    $result4b = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -DueDate (Get-Date).AddDays(10) -RandomSeed 12345
    $result4c = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -DueDate (Get-Date).AddDays(20) -RandomSeed 12345
    $result4d = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -DueDate (Get-Date).AddDays(40) -RandomSeed 12345

    Write-Host "    Échéance dans 3 jours: $result4a" -ForegroundColor Gray
    Write-Host "    Échéance dans 10 jours: $result4b" -ForegroundColor Gray
    Write-Host "    Échéance dans 20 jours: $result4c" -ForegroundColor Gray
    Write-Host "    Échéance dans 40 jours: $result4d" -ForegroundColor Gray

    $dueDatePriorityCorrect = ($result4a -eq "Critical" -or $result4a -eq "High") -and
                             ($result4b -eq "High" -or $result4b -eq "Medium") -and
                             ($result4c -eq "Medium" -or $result4c -eq "Low") -and
                             ($result4d -eq "Low")

    if ($dueDatePriorityCorrect) {
        Write-Host "    Succès: Les priorités sont correctement attribuées en fonction de la date d'échéance." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les priorités ne sont pas correctement attribuées en fonction de la date d'échéance." -ForegroundColor Red
    }

    # Test 5: Déterminer le niveau de priorité en fonction de l'importance stratégique
    Write-Host "  Test 5: Déterminer le niveau de priorité en fonction de l'importance stratégique" -ForegroundColor Gray

    $result5a = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -StrategicImportance "Critical" -RandomSeed 12345
    $result5b = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -StrategicImportance "High" -RandomSeed 12345
    $result5c = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -StrategicImportance "Medium" -RandomSeed 12345
    $result5d = Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -StrategicImportance "Low" -RandomSeed 12345

    Write-Host "    Importance Critical: $result5a" -ForegroundColor Gray
    Write-Host "    Importance High: $result5b" -ForegroundColor Gray
    Write-Host "    Importance Medium: $result5c" -ForegroundColor Gray
    Write-Host "    Importance Low: $result5d" -ForegroundColor Gray

    $importancePriorityCorrect = ($result5a -eq "Critical" -or $result5a -eq "High") -and
                                ($result5b -eq "High" -or $result5b -eq "Medium") -and
                                ($result5c -eq "Medium" -or $result5c -eq "Low") -and
                                ($result5d -eq "Low")

    if ($importancePriorityCorrect) {
        Write-Host "    Succès: Les priorités sont correctement attribuées en fonction de l'importance stratégique." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les priorités ne sont pas correctement attribuées en fonction de l'importance stratégique." -ForegroundColor Red
    }
}

# Test pour la fonction New-TaskPriorityAssignment
function Test-TaskPriorityAssignment {
    Write-Host "`nTest de la fonction New-TaskPriorityAssignment:" -ForegroundColor Yellow

    # Créer une hiérarchie de tâches de test
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche racine" -Status "InProgress"),
        (New-TestTask -Id "1.1" -Title "Sous-tâche 1.1" -ParentId "1" -Status "InProgress"),
        (New-TestTask -Id "1.2" -Title "Sous-tâche 1.2" -ParentId "1" -Status "Completed"),
        (New-TestTask -Id "1.1.1" -Title "Sous-tâche 1.1.1" -ParentId "1.1" -Status "NotStarted"),
        (New-TestTask -Id "1.1.2" -Title "Sous-tâche 1.1.2" -ParentId "1.1" -Status "InProgress"),
        (New-TestTask -Id "1.2.1" -Title "Sous-tâche 1.2.1" -ParentId "1.2" -Status "Completed")
    )

    # Ajouter les références aux enfants
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[1].Children = @("1.1.1", "1.1.2")
    $tasks[2].Children = @("1.2.1")

    # Test 1: Attribuer des niveaux de priorité à une hiérarchie de tâches
    Write-Host "  Test 1: Attribuer des niveaux de priorité à une hiérarchie de tâches" -ForegroundColor Gray
    $result1 = New-TaskPriorityAssignment -Tasks $tasks.Clone() -RandomSeed 12345

    $allHavePriority = $true
    foreach ($task in $result1) {
        if ($null -eq $task.Priority) {
            $allHavePriority = $false
            break
        }
    }

    if ($allHavePriority) {
        Write-Host "    Succès: Toutes les tâches ont un niveau de priorité." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Priority)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches n'ont pas de niveau de priorité." -ForegroundColor Red
    }

    # Test 2: Vérifier la cohérence hiérarchique
    Write-Host "  Test 2: Vérifier la cohérence hiérarchique" -ForegroundColor Gray

    $hierarchyConsistent = $true
    $priorityOrder = @("Critical", "High", "Medium", "Low")

    foreach ($task in $result1) {
        if ($task.ParentId) {
            $parent = $result1 | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1

            if ($parent) {
                $parentPriorityIndex = $priorityOrder.IndexOf($parent.Priority)
                $taskPriorityIndex = $priorityOrder.IndexOf($task.Priority)

                if ($taskPriorityIndex -lt $parentPriorityIndex) {
                    $hierarchyConsistent = $false
                    Write-Host "      Incohérence: Tâche $($task.Id) ($($task.Priority)) a une priorité plus élevée que son parent $($parent.Id) ($($parent.Priority))" -ForegroundColor Red
                    break
                }
            }
        }
    }

    if ($hierarchyConsistent) {
        Write-Host "    Succès: La cohérence hiérarchique est maintenue." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La cohérence hiérarchique n'est pas maintenue." -ForegroundColor Red
    }

    # Test 3: Vérifier l'impact du statut sur la priorité
    Write-Host "  Test 3: Vérifier l'impact du statut sur la priorité" -ForegroundColor Gray

    $inProgressTasks = $result1 | Where-Object { $_.Status -eq "InProgress" }
    $completedTasks = $result1 | Where-Object { $_.Status -eq "Completed" }

    $inProgressPriorities = $inProgressTasks | ForEach-Object { $priorityOrder.IndexOf($_.Priority) }
    $completedPriorities = $completedTasks | ForEach-Object { $priorityOrder.IndexOf($_.Priority) }

    $inProgressAvg = if ($inProgressPriorities.Count -gt 0) { ($inProgressPriorities | Measure-Object -Average).Average } else { 0 }
    $completedAvg = if ($completedPriorities.Count -gt 0) { ($completedPriorities | Measure-Object -Average).Average } else { 0 }

    if ($inProgressAvg -lt $completedAvg) {
        Write-Host "    Succès: Les tâches en cours ont généralement une priorité plus élevée que les tâches terminées." -ForegroundColor Green
        Write-Host "      Priorité moyenne des tâches en cours: $($priorityOrder[[Math]::Round($inProgressAvg)])" -ForegroundColor Gray
        Write-Host "      Priorité moyenne des tâches terminées: $($priorityOrder[[Math]::Round($completedAvg)])" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: Les tâches en cours n'ont pas une priorité plus élevée que les tâches terminées." -ForegroundColor Red
        Write-Host "      Priorité moyenne des tâches en cours: $($priorityOrder[[Math]::Round($inProgressAvg)])" -ForegroundColor Gray
        Write-Host "      Priorité moyenne des tâches terminées: $($priorityOrder[[Math]::Round($completedAvg)])" -ForegroundColor Gray
    }
}

# Test pour la fonction Update-TaskPriorityHierarchy
function Test-TaskPriorityHierarchy {
    Write-Host "`nTest de la fonction Update-TaskPriorityHierarchy:" -ForegroundColor Yellow

    # Créer une hiérarchie de tâches de test avec des priorités incohérentes
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche racine" -Priority "Medium"),
        (New-TestTask -Id "1.1" -Title "Sous-tâche 1.1" -ParentId "1" -Priority "High"),
        (New-TestTask -Id "1.2" -Title "Sous-tâche 1.2" -ParentId "1" -Priority "Low"),
        (New-TestTask -Id "1.1.1" -Title "Sous-tâche 1.1.1" -ParentId "1.1" -Priority "Critical"),
        (New-TestTask -Id "1.1.2" -Title "Sous-tâche 1.1.2" -ParentId "1.1" -Priority "Medium"),
        (New-TestTask -Id "1.2.1" -Title "Sous-tâche 1.2.1" -ParentId "1.2" -Priority "High")
    )

    # Ajouter les références aux enfants
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[1].Children = @("1.1.1", "1.1.2")
    $tasks[2].Children = @("1.2.1")

    # Ajouter des dépendances
    $tasks[3].Dependencies = @("1.1.2")
    $tasks[5].Dependencies = @("1.2")

    # Test 1: Mettre à jour les priorités pour maintenir la cohérence
    Write-Host "  Test 1: Mettre à jour les priorités pour maintenir la cohérence" -ForegroundColor Gray
    $result1 = Update-TaskPriorityHierarchy -Tasks $tasks.Clone()

    $hierarchyConsistent = $true
    $dependenciesConsistent = $true
    $priorityOrder = @("Critical", "High", "Medium", "Low")

    # Vérifier la cohérence hiérarchique
    foreach ($task in $result1) {
        if ($task.ParentId) {
            $parent = $result1 | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1

            if ($parent) {
                $parentPriorityIndex = $priorityOrder.IndexOf($parent.Priority)
                $taskPriorityIndex = $priorityOrder.IndexOf($task.Priority)

                if ($taskPriorityIndex -lt $parentPriorityIndex) {
                    $hierarchyConsistent = $false
                    Write-Host "      Incohérence hiérarchique: Tâche $($task.Id) ($($task.Priority)) a une priorité plus élevée que son parent $($parent.Id) ($($parent.Priority))" -ForegroundColor Red
                    break
                }
            }
        }
    }

    # Vérifier la cohérence des dépendances
    foreach ($task in $result1) {
        if ($task.Dependencies -and $task.Dependencies.Count -gt 0) {
            foreach ($depId in $task.Dependencies) {
                $dependency = $result1 | Where-Object { $_.Id -eq $depId } | Select-Object -First 1

                if ($dependency) {
                    $dependencyPriorityIndex = $priorityOrder.IndexOf($dependency.Priority)
                    $taskPriorityIndex = $priorityOrder.IndexOf($task.Priority)

                    if ($taskPriorityIndex -lt $dependencyPriorityIndex) {
                        $dependenciesConsistent = $false
                        Write-Host "      Incohérence de dépendance: Tâche $($task.Id) ($($task.Priority)) a une priorité plus élevée que sa dépendance $($dependency.Id) ($($dependency.Priority))" -ForegroundColor Red
                        break
                    }
                }
            }

            if (-not $dependenciesConsistent) {
                break
            }
        }
    }

    if ($hierarchyConsistent -and $dependenciesConsistent) {
        Write-Host "    Succès: La cohérence hiérarchique et des dépendances est maintenue." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Priority)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: La cohérence hiérarchique ou des dépendances n'est pas maintenue." -ForegroundColor Red
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan
