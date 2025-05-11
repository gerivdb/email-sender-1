# Test-TaskCriticality.ps1
# Script de test pour les fonctions de calcul de criticité
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskCriticality.ps1"
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
        [string[]]$Dependencies = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$Dependents = @(),

        [Parameter(Mandatory = $false)]
        [string]$Priority = $null,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DueDate = $null,

        [Parameter(Mandatory = $false)]
        [int]$Duration = 1
    )

    return [PSCustomObject]@{
        Id           = $Id
        Title        = $Title
        Dependencies = $Dependencies
        Dependents   = $Dependents
        Priority     = $Priority
        DueDate      = $DueDate
        Duration     = $Duration
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de calcul de criticité..." -ForegroundColor Cyan

    Test-TaskCriticalityLevel
    Test-TaskCriticalityAssignment
    Test-CriticalPath

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction Get-TaskCriticalityLevel
function Test-TaskCriticalityLevel {
    Write-Host "`nTest de la fonction Get-TaskCriticalityLevel:" -ForegroundColor Yellow

    # Test 1: Déterminer le niveau de criticité en fonction du nombre de tâches dépendantes
    Write-Host "  Test 1: Déterminer le niveau de criticité en fonction du nombre de tâches dépendantes" -ForegroundColor Gray
    $task = New-TestTask -Id "1" -Title "Tâche de test"

    $result1a = Get-TaskCriticalityLevel -Task $task -DependentTasksCount 0 -RandomSeed 12345
    $result1b = Get-TaskCriticalityLevel -Task $task -DependentTasksCount 3 -RandomSeed 12345
    $result1c = Get-TaskCriticalityLevel -Task $task -DependentTasksCount 7 -RandomSeed 12345
    $result1d = Get-TaskCriticalityLevel -Task $task -DependentTasksCount 12 -RandomSeed 12345

    Write-Host "    0 tâches dépendantes: $result1a" -ForegroundColor Gray
    Write-Host "    3 tâches dépendantes: $result1b" -ForegroundColor Gray
    Write-Host "    7 tâches dépendantes: $result1c" -ForegroundColor Gray
    Write-Host "    12 tâches dépendantes: $result1d" -ForegroundColor Gray

    $dependentTasksCorrect = ($result1a -eq "Low") -and
                            ($result1b -eq "Medium") -and
                            ($result1c -eq "High") -and
                            ($result1d -eq "Critical")

    if ($dependentTasksCorrect) {
        Write-Host "    Succès: Les niveaux de criticité sont correctement attribués en fonction du nombre de tâches dépendantes." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les niveaux de criticité ne sont pas correctement attribués en fonction du nombre de tâches dépendantes." -ForegroundColor Red
    }

    # Test 2: Déterminer le niveau de criticité en fonction de la position sur le chemin critique
    Write-Host "  Test 2: Déterminer le niveau de criticité en fonction de la position sur le chemin critique" -ForegroundColor Gray

    $result2a = Get-TaskCriticalityLevel -Task $task -IsOnCriticalPath $false -RandomSeed 12345
    $result2b = Get-TaskCriticalityLevel -Task $task -IsOnCriticalPath $true -RandomSeed 12345

    Write-Host "    Hors du chemin critique: $result2a" -ForegroundColor Gray
    Write-Host "    Sur le chemin critique: $result2b" -ForegroundColor Gray

    $criticalPathCorrect = ($result2a -eq "Low") -and
                          ($result2b -eq "Critical" -or $result2b -eq "High")

    if ($criticalPathCorrect) {
        Write-Host "    Succès: Les niveaux de criticité sont correctement attribués en fonction de la position sur le chemin critique." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les niveaux de criticité ne sont pas correctement attribués en fonction de la position sur le chemin critique." -ForegroundColor Red
    }

    # Test 3: Déterminer le niveau de criticité en fonction de la date d'échéance
    Write-Host "  Test 3: Déterminer le niveau de criticité en fonction de la date d'échéance" -ForegroundColor Gray

    $result3a = Get-TaskCriticalityLevel -Task $task -DueDate (Get-Date).AddDays(3) -RandomSeed 12345
    $result3b = Get-TaskCriticalityLevel -Task $task -DueDate (Get-Date).AddDays(10) -RandomSeed 12345
    $result3c = Get-TaskCriticalityLevel -Task $task -DueDate (Get-Date).AddDays(20) -RandomSeed 12345
    $result3d = Get-TaskCriticalityLevel -Task $task -DueDate (Get-Date).AddDays(40) -RandomSeed 12345

    Write-Host "    Échéance dans 3 jours: $result3a" -ForegroundColor Gray
    Write-Host "    Échéance dans 10 jours: $result3b" -ForegroundColor Gray
    Write-Host "    Échéance dans 20 jours: $result3c" -ForegroundColor Gray
    Write-Host "    Échéance dans 40 jours: $result3d" -ForegroundColor Gray

    $dueDateCorrect = ($result3a -eq "Critical" -or $result3a -eq "High") -and
                     ($result3b -eq "High" -or $result3b -eq "Medium") -and
                     ($result3c -eq "Medium" -or $result3c -eq "Low") -and
                     ($result3d -eq "Low")

    if ($dueDateCorrect) {
        Write-Host "    Succès: Les niveaux de criticité sont correctement attribués en fonction de la date d'échéance." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les niveaux de criticité ne sont pas correctement attribués en fonction de la date d'échéance." -ForegroundColor Red
    }

    # Test 4: Déterminer le niveau de criticité en fonction de la priorité
    Write-Host "  Test 4: Déterminer le niveau de criticité en fonction de la priorité" -ForegroundColor Gray

    $result4a = Get-TaskCriticalityLevel -Task $task -Priority "Critical" -RandomSeed 12345
    $result4b = Get-TaskCriticalityLevel -Task $task -Priority "High" -RandomSeed 12345
    $result4c = Get-TaskCriticalityLevel -Task $task -Priority "Medium" -RandomSeed 12345
    $result4d = Get-TaskCriticalityLevel -Task $task -Priority "Low" -RandomSeed 12345

    Write-Host "    Priorité Critical: $result4a" -ForegroundColor Gray
    Write-Host "    Priorité High: $result4b" -ForegroundColor Gray
    Write-Host "    Priorité Medium: $result4c" -ForegroundColor Gray
    Write-Host "    Priorité Low: $result4d" -ForegroundColor Gray

    $priorityCorrect = ($result4a -eq "Critical") -and
                      ($result4b -eq "High") -and
                      ($result4c -eq "Medium") -and
                      ($result4d -eq "Low")

    if ($priorityCorrect) {
        Write-Host "    Succès: Les niveaux de criticité sont correctement attribués en fonction de la priorité." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les niveaux de criticité ne sont pas correctement attribués en fonction de la priorité." -ForegroundColor Red
    }

    # Test 5: Déterminer le niveau de criticité en fonction du nombre de tâches bloquées
    Write-Host "  Test 5: Déterminer le niveau de criticité en fonction du nombre de tâches bloquées" -ForegroundColor Gray

    $result5a = Get-TaskCriticalityLevel -Task $task -BlockerCount 0 -RandomSeed 12345
    $result5b = Get-TaskCriticalityLevel -Task $task -BlockerCount 1 -RandomSeed 12345
    $result5c = Get-TaskCriticalityLevel -Task $task -BlockerCount 3 -RandomSeed 12345
    $result5d = Get-TaskCriticalityLevel -Task $task -BlockerCount 6 -RandomSeed 12345

    Write-Host "    0 tâches bloquées: $result5a" -ForegroundColor Gray
    Write-Host "    1 tâche bloquée: $result5b" -ForegroundColor Gray
    Write-Host "    3 tâches bloquées: $result5c" -ForegroundColor Gray
    Write-Host "    6 tâches bloquées: $result5d" -ForegroundColor Gray

    $blockerCountCorrect = ($result5a -eq "Low") -and
                          ($result5b -eq "Medium") -and
                          ($result5c -eq "High") -and
                          ($result5d -eq "Critical")

    if ($blockerCountCorrect) {
        Write-Host "    Succès: Les niveaux de criticité sont correctement attribués en fonction du nombre de tâches bloquées." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les niveaux de criticité ne sont pas correctement attribués en fonction du nombre de tâches bloquées." -ForegroundColor Red
    }
}

# Test pour la fonction New-TaskCriticalityAssignment
function Test-TaskCriticalityAssignment {
    Write-Host "`nTest de la fonction New-TaskCriticalityAssignment:" -ForegroundColor Yellow

    # Créer un ensemble de tâches avec des dépendances
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche 1" -Dependencies @() -Priority "High" -DueDate (Get-Date).AddDays(30)),
        (New-TestTask -Id "2" -Title "Tâche 2" -Dependencies @("1") -Priority "Medium" -DueDate (Get-Date).AddDays(40)),
        (New-TestTask -Id "3" -Title "Tâche 3" -Dependencies @("1") -Priority "High" -DueDate (Get-Date).AddDays(20)),
        (New-TestTask -Id "4" -Title "Tâche 4" -Dependencies @("2", "3") -Priority "Medium" -DueDate (Get-Date).AddDays(50)),
        (New-TestTask -Id "5" -Title "Tâche 5" -Dependencies @("3") -Priority "Low" -DueDate (Get-Date).AddDays(60))
    )

    # Test 1: Attribuer des niveaux de criticité à un ensemble de tâches
    Write-Host "  Test 1: Attribuer des niveaux de criticité à un ensemble de tâches" -ForegroundColor Gray
    $result1 = New-TaskCriticalityAssignment -Tasks $tasks.Clone() -RandomSeed 12345

    $allHaveCriticality = $true
    foreach ($task in $result1) {
        if ($null -eq $task.Criticality) {
            $allHaveCriticality = $false
            break
        }
    }

    if ($allHaveCriticality) {
        Write-Host "    Succès: Toutes les tâches ont un niveau de criticité." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Criticality)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches n'ont pas de niveau de criticité." -ForegroundColor Red
    }

    # Test 2: Vérifier que les tâches sur le chemin critique ont une criticité élevée
    Write-Host "  Test 2: Vérifier que les tâches sur le chemin critique ont une criticité élevée" -ForegroundColor Gray

    # Trouver les tâches sur le chemin critique
    $dependencyGraph = @{}
    $tasksById = @{}
    foreach ($task in $tasks) {
        $dependencyGraph[$task.Id] = $task.Dependencies
        $tasksById[$task.Id] = $task
    }
    $criticalPath = Find-CriticalPath -DependencyGraph $dependencyGraph -Tasks $tasksById

    $criticalPathTasks = $result1 | Where-Object { $criticalPath -contains $_.Id }
    $nonCriticalPathTasks = $result1 | Where-Object { $criticalPath -notcontains $_.Id }

    $criticalPathTasksHighCriticality = $true
    foreach ($task in $criticalPathTasks) {
        if ($task.Criticality -ne "Critical" -and $task.Criticality -ne "High") {
            $criticalPathTasksHighCriticality = $false
            break
        }
    }

    if ($criticalPathTasksHighCriticality) {
        Write-Host "    Succès: Les tâches sur le chemin critique ont une criticité élevée." -ForegroundColor Green
        Write-Host "      Chemin critique: $($criticalPath -join ', ')" -ForegroundColor Gray
        foreach ($task in $criticalPathTasks) {
            Write-Host "      Tâche $($task.Id): $($task.Criticality)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches sur le chemin critique n'ont pas une criticité élevée." -ForegroundColor Red
        Write-Host "      Chemin critique: $($criticalPath -join ', ')" -ForegroundColor Gray
        foreach ($task in $criticalPathTasks) {
            Write-Host "      Tâche $($task.Id): $($task.Criticality)" -ForegroundColor Gray
        }
    }
}

# Test pour la fonction Find-CriticalPath
function Test-CriticalPath {
    Write-Host "`nTest de la fonction Find-CriticalPath:" -ForegroundColor Yellow

    # Test 1: Identifier le chemin critique dans un graphe simple
    Write-Host "  Test 1: Identifier le chemin critique dans un graphe simple" -ForegroundColor Gray

    $dependencyGraph = @{
        "1" = @()
        "2" = @("1")
        "3" = @("1")
        "4" = @("2", "3")
        "5" = @("3")
    }

    $tasks = @{
        "1" = (New-TestTask -Id "1" -Duration 2)
        "2" = (New-TestTask -Id "2" -Duration 3)
        "3" = (New-TestTask -Id "3" -Duration 4)
        "4" = (New-TestTask -Id "4" -Duration 2)
        "5" = (New-TestTask -Id "5" -Duration 1)
    }

    $criticalPath = Find-CriticalPath -DependencyGraph $dependencyGraph -Tasks $tasks

    Write-Host "    Chemin critique: $($criticalPath -join ' -> ')" -ForegroundColor Gray

    # Le chemin critique devrait être 1 -> 3 -> 4
    $expectedPath = @("1", "3", "4")
    $pathCorrect = $true
    foreach ($taskId in $expectedPath) {
        if ($criticalPath -notcontains $taskId) {
            $pathCorrect = $false
            break
        }
    }

    if ($pathCorrect) {
        Write-Host "    Succès: Le chemin critique est correctement identifié." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le chemin critique n'est pas correctement identifié." -ForegroundColor Red
        Write-Host "      Chemin attendu: $($expectedPath -join ' -> ')" -ForegroundColor Gray
    }

    # Test 2: Identifier le chemin critique dans un graphe plus complexe
    Write-Host "  Test 2: Identifier le chemin critique dans un graphe plus complexe" -ForegroundColor Gray

    $dependencyGraph2 = @{
        "A" = @()
        "B" = @("A")
        "C" = @("A")
        "D" = @("B")
        "E" = @("B", "C")
        "F" = @("C")
        "G" = @("D", "E")
        "H" = @("E", "F")
        "I" = @("G", "H")
    }

    $tasks2 = @{
        "A" = (New-TestTask -Id "A" -Duration 3)
        "B" = (New-TestTask -Id "B" -Duration 2)
        "C" = (New-TestTask -Id "C" -Duration 4)
        "D" = (New-TestTask -Id "D" -Duration 1)
        "E" = (New-TestTask -Id "E" -Duration 3)
        "F" = (New-TestTask -Id "F" -Duration 2)
        "G" = (New-TestTask -Id "G" -Duration 2)
        "H" = (New-TestTask -Id "H" -Duration 3)
        "I" = (New-TestTask -Id "I" -Duration 1)
    }

    $criticalPath2 = Find-CriticalPath -DependencyGraph $dependencyGraph2 -Tasks $tasks2

    Write-Host "    Chemin critique: $($criticalPath2 -join ' -> ')" -ForegroundColor Gray

    # Le chemin critique devrait être A -> C -> E -> H -> I
    $expectedPath2 = @("A", "C", "E", "H", "I")
    $pathCorrect2 = $true
    foreach ($taskId in $expectedPath2) {
        if ($criticalPath2 -notcontains $taskId) {
            $pathCorrect2 = $false
            break
        }
    }

    if ($pathCorrect2) {
        Write-Host "    Succès: Le chemin critique est correctement identifié." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le chemin critique n'est pas correctement identifié." -ForegroundColor Red
        Write-Host "      Chemin attendu: $($expectedPath2 -join ' -> ')" -ForegroundColor Gray
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan
