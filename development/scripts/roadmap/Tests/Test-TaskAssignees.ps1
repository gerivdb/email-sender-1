# Test-TaskAssignees.ps1
# Script de test pour les fonctions de génération d'assignés de tâches
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskAssignees.ps1"
. $scriptPath

# Fonction pour créer des tâches de test
function New-TestTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Tâche $Id",

        [Parameter(Mandatory = $false)]
        [int]$IndentLevel = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$Skills = @()
    )

    return [PSCustomObject]@{
        Id          = $Id
        Title       = $Title
        IndentLevel = $IndentLevel
        Skills      = $Skills
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de génération d'assignés de tâches..." -ForegroundColor Cyan

    Test-RandomAssignee
    Test-AssigneeList
    Test-TaskAssignees

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction Get-RandomAssignee
function Test-RandomAssignee {
    Write-Host "`nTest de la fonction Get-RandomAssignee:" -ForegroundColor Yellow

    # Test 1: Générer un prénom aléatoire
    Write-Host "  Test 1: Générer un prénom aléatoire" -ForegroundColor Gray
    $result1 = Get-RandomAssignee -UseFullName $false

    if ($result1) {
        Write-Host "    Succès: Un prénom a été généré: $result1" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Aucun prénom n'a été généré." -ForegroundColor Red
    }

    # Test 2: Générer un nom complet aléatoire
    Write-Host "  Test 2: Générer un nom complet aléatoire" -ForegroundColor Gray
    $result2 = Get-RandomAssignee -UseFullName $true

    if ($result2 -and $result2.Contains(" ")) {
        Write-Host "    Succès: Un nom complet a été généré: $result2" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Un nom complet n'a pas été généré correctement: $result2" -ForegroundColor Red
    }

    # Test 3: Générer un nom avec une culture spécifique
    Write-Host "  Test 3: Générer un nom avec une culture spécifique" -ForegroundColor Gray
    $result3 = Get-RandomAssignee -UseFullName $true -Culture "en-US"

    if ($result3 -and $result3.Contains(" ")) {
        Write-Host "    Succès: Un nom anglais a été généré: $result3" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Un nom anglais n'a pas été généré correctement: $result3" -ForegroundColor Red
    }

    # Test 4: Générer un nom à partir d'une liste prédéfinie
    Write-Host "  Test 4: Générer un nom à partir d'une liste prédéfinie" -ForegroundColor Gray
    $predefinedList = @("Jean Dupont", "Marie Martin", "Pierre Durand")
    $result4 = Get-RandomAssignee -PredefinedList $predefinedList

    if ($predefinedList -contains $result4) {
        Write-Host "    Succès: Un nom a été sélectionné dans la liste prédéfinie: $result4" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le nom généré n'est pas dans la liste prédéfinie: $result4" -ForegroundColor Red
    }

    # Test 5: Générer un nom avec une graine aléatoire spécifique
    Write-Host "  Test 5: Générer un nom avec une graine aléatoire spécifique" -ForegroundColor Gray
    $result5a = Get-RandomAssignee -RandomSeed 12345
    $result5b = Get-RandomAssignee -RandomSeed 12345

    if ($result5a -eq $result5b) {
        Write-Host "    Succès: Les noms générés avec la même graine sont identiques: $result5a" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les noms générés avec la même graine sont différents: $result5a vs $result5b" -ForegroundColor Red
    }
}

# Test pour la fonction New-AssigneeList
function Test-AssigneeList {
    Write-Host "`nTest de la fonction New-AssigneeList:" -ForegroundColor Yellow

    # Test 1: Générer une liste de prénoms
    Write-Host "  Test 1: Générer une liste de prénoms" -ForegroundColor Gray
    $result1 = New-AssigneeList -Count 5 -UseFullName $false

    if ($result1 -and $result1.Count -eq 5) {
        Write-Host "    Succès: Une liste de 5 prénoms a été générée: $($result1 -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "    Échec: La liste de prénoms n'a pas été générée correctement." -ForegroundColor Red
    }

    # Test 2: Générer une liste de noms complets
    Write-Host "  Test 2: Générer une liste de noms complets" -ForegroundColor Gray
    $result2 = New-AssigneeList -Count 3 -UseFullName $true

    $allFullNames = $true
    foreach ($name in $result2) {
        if (-not $name.Contains(" ")) {
            $allFullNames = $false
            break
        }
    }

    if ($result2 -and $result2.Count -eq 3 -and $allFullNames) {
        Write-Host "    Succès: Une liste de 3 noms complets a été générée: $($result2 -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "    Échec: La liste de noms complets n'a pas été générée correctement." -ForegroundColor Red
    }

    # Test 3: Générer une liste sans doublons
    Write-Host "  Test 3: Générer une liste sans doublons" -ForegroundColor Gray
    $result3 = New-AssigneeList -Count 10 -AllowDuplicates $false
    $uniqueCount = ($result3 | Select-Object -Unique).Count

    if ($result3 -and $result3.Count -eq 10 -and $uniqueCount -eq 10) {
        Write-Host "    Succès: Une liste de 10 noms uniques a été générée." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La liste contient des doublons ou n'a pas la bonne taille." -ForegroundColor Red
    }

    # Test 4: Générer une liste à partir d'une liste prédéfinie
    Write-Host "  Test 4: Générer une liste à partir d'une liste prédéfinie" -ForegroundColor Gray
    $predefinedList = @("Jean Dupont", "Marie Martin", "Pierre Durand")
    $result4 = New-AssigneeList -Count 5 -PredefinedList $predefinedList -AllowDuplicates $true

    $allFromPredefined = $true
    foreach ($name in $result4) {
        if (-not $predefinedList.Contains($name)) {
            $allFromPredefined = $false
            break
        }
    }

    if ($result4 -and $result4.Count -eq 5 -and $allFromPredefined) {
        Write-Host "    Succès: Une liste de 5 noms a été générée à partir de la liste prédéfinie." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La liste n'a pas été générée correctement à partir de la liste prédéfinie." -ForegroundColor Red
    }
}

# Test pour la fonction Add-TaskAssignees
function Test-TaskAssignees {
    Write-Host "`nTest de la fonction Add-TaskAssignees:" -ForegroundColor Yellow

    # Créer des tâches de test
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche 1" -IndentLevel 0),
        (New-TestTask -Id "2" -Title "Tâche 2" -IndentLevel 1),
        (New-TestTask -Id "3" -Title "Tâche 3" -IndentLevel 1),
        (New-TestTask -Id "4" -Title "Tâche 4" -IndentLevel 2 -Skills @("Développement", "Backend")),
        (New-TestTask -Id "5" -Title "Tâche 5" -IndentLevel 2 -Skills @("Design", "Frontend"))
    )

    # Créer une liste d'assignés
    $assignees = @("Jean", "Marie", "Pierre", "Sophie", "Thomas")

    # Test 1: Attribution aléatoire
    Write-Host "  Test 1: Attribution aléatoire" -ForegroundColor Gray
    $result1 = Add-TaskAssignees -Tasks $tasks.Clone() -Assignees $assignees -Strategy "Random"

    $allAssigned = $true
    foreach ($task in $result1) {
        if (-not $task.PSObject.Properties.Name.Contains("Assignee") -or -not $assignees.Contains($task.Assignee)) {
            $allAssigned = $false
            break
        }
    }

    if ($allAssigned) {
        Write-Host "    Succès: Toutes les tâches ont été assignées aléatoirement." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Assignee)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches n'ont pas été assignées correctement." -ForegroundColor Red
    }

    # Test 2: Attribution en alternance (round-robin)
    Write-Host "  Test 2: Attribution en alternance (round-robin)" -ForegroundColor Gray
    $result2 = Add-TaskAssignees -Tasks $tasks.Clone() -Assignees $assignees -Strategy "RoundRobin"

    $expectedAssignees = @(
        $assignees[0], # Tâche 1
        $assignees[1], # Tâche 2
        $assignees[2], # Tâche 3
        $assignees[3], # Tâche 4
        $assignees[4]   # Tâche 5
    )

    $correctAssignment = $true
    for ($i = 0; $i -lt $result2.Count; $i++) {
        if ($result2[$i].Assignee -ne $expectedAssignees[$i]) {
            $correctAssignment = $false
            break
        }
    }

    if ($correctAssignment) {
        Write-Host "    Succès: Les tâches ont été assignées en alternance." -ForegroundColor Green
        foreach ($task in $result2) {
            Write-Host "      Tâche $($task.Id): $($task.Assignee)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Les tâches n'ont pas été assignées correctement en alternance." -ForegroundColor Red
    }

    # Test 3: Attribution équilibrée
    Write-Host "  Test 3: Attribution équilibrée" -ForegroundColor Gray
    $result3 = Add-TaskAssignees -Tasks $tasks.Clone() -Assignees $assignees -Strategy "Balanced"

    $assigneeCounts = @{}
    foreach ($assignee in $assignees) {
        $assigneeCounts[$assignee] = 0
    }

    foreach ($task in $result3) {
        $assigneeCounts[$task.Assignee]++
    }

    $maxCount = ($assigneeCounts.Values | Measure-Object -Maximum).Maximum
    $minCount = ($assigneeCounts.Values | Measure-Object -Minimum).Minimum
    $balanced = ($maxCount - $minCount) -le 1

    if ($balanced) {
        Write-Host "    Succès: Les tâches ont été assignées de manière équilibrée." -ForegroundColor Green
        foreach ($assignee in $assignees) {
            Write-Host "      ${assignee}: $($assigneeCounts[$assignee]) tâche(s)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Les tâches n'ont pas été assignées de manière équilibrée." -ForegroundColor Red
        foreach ($assignee in $assignees) {
            Write-Host "      ${assignee}: $($assigneeCounts[$assignee]) tâche(s)" -ForegroundColor Gray
        }
    }

    # Test 4: Attribution spécialisée
    Write-Host "  Test 4: Attribution spécialisée" -ForegroundColor Gray
    $skillsMapping = @{
        "Jean"   = @("Développement", "Backend")
        "Marie"  = @("Design", "Frontend")
        "Pierre" = @("Développement", "Testing")
        "Sophie" = @("Documentation", "Frontend")
        "Thomas" = @("Backend", "DevOps")
    }

    $result4 = Add-TaskAssignees -Tasks $tasks.Clone() -Assignees $assignees -Strategy "Specialized" -SkillsMapping $skillsMapping

    $correctSpecialization = $true
    foreach ($task in $result4) {
        if ($task.PSObject.Properties.Name.Contains("Skills") -and $task.Skills.Count -gt 0) {
            $assignee = $task.Assignee
            $hasAllSkills = $true

            foreach ($skill in $task.Skills) {
                if (-not $skillsMapping[$assignee].Contains($skill)) {
                    $hasAllSkills = $false
                    break
                }
            }

            if (-not $hasAllSkills) {
                $correctSpecialization = $false
                break
            }
        }
    }

    if ($correctSpecialization) {
        Write-Host "    Succès: Les tâches ont été assignées en fonction des compétences." -ForegroundColor Green
        foreach ($task in $result4) {
            if ($task.PSObject.Properties.Name.Contains("Skills") -and $task.Skills.Count -gt 0) {
                Write-Host "      Tâche $($task.Id) ($($task.Skills -join ', ')): $($task.Assignee)" -ForegroundColor Gray
            } else {
                Write-Host "      Tâche $($task.Id): $($task.Assignee)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "    Échec: Les tâches n'ont pas été assignées correctement en fonction des compétences." -ForegroundColor Red
    }

    # Test 5: Attribution hiérarchique
    Write-Host "  Test 5: Attribution hiérarchique" -ForegroundColor Gray
    $result5 = Add-TaskAssignees -Tasks $tasks.Clone() -Assignees $assignees -Strategy "Hierarchical"

    $levelAssignees = @{}
    foreach ($task in $result5) {
        $level = $task.IndentLevel
        if (-not $levelAssignees.ContainsKey($level)) {
            $levelAssignees[$level] = @()
        }

        if (-not $levelAssignees[$level].Contains($task.Assignee)) {
            $levelAssignees[$level] += $task.Assignee
        }
    }

    Write-Host "    Résultat de l'attribution hiérarchique:" -ForegroundColor Green
    foreach ($level in $levelAssignees.Keys | Sort-Object) {
        Write-Host "      Niveau ${level}: $($levelAssignees[$level] -join ', ')" -ForegroundColor Gray
    }

    foreach ($task in $result5) {
        Write-Host "      Tâche $($task.Id) (Niveau $($task.IndentLevel)): $($task.Assignee)" -ForegroundColor Gray
    }
}

# Exécuter tous les tests
Invoke-AllTests
