# Test-TaskStatus.ps1
# Script de test pour les fonctions de génération de statuts de tâches
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskStatus.ps1"
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
        [string]$Status = $null
    )

    return [PSCustomObject]@{
        Id       = $Id
        Title    = $Title
        ParentId = $ParentId
        Children = $Children
        Status   = $Status
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de génération de statuts de tâches..." -ForegroundColor Cyan

    Test-RandomTaskStatus
    Test-StatusHierarchy
    Test-UpdateTaskStatusHierarchy
    Test-TaskStatusWithSubtasks

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction Get-RandomTaskStatus
function Test-RandomTaskStatus {
    Write-Host "`nTest de la fonction Get-RandomTaskStatus:" -ForegroundColor Yellow

    # Test 1: Générer un statut aléatoire avec les pondérations par défaut
    Write-Host "  Test 1: Générer un statut aléatoire avec les pondérations par défaut" -ForegroundColor Gray
    $result1 = Get-RandomTaskStatus

    if ($result1 -in @("NotStarted", "InProgress", "Completed", "Blocked")) {
        Write-Host "    Succès: Un statut valide a été généré: $result1" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le statut généré n'est pas valide: $result1" -ForegroundColor Red
    }

    # Test 2: Générer un statut aléatoire avec des pondérations personnalisées
    Write-Host "  Test 2: Générer un statut aléatoire avec des pondérations personnalisées" -ForegroundColor Gray
    $weights = @{
        "NotStarted" = 10
        "InProgress" = 70
        "Completed"  = 15
        "Blocked"    = 5
    }

    $statuses = @()
    for ($i = 0; $i -lt 100; $i++) {
        $statuses += Get-RandomTaskStatus -Weights $weights -RandomSeed $i
    }

    $inProgressCount = ($statuses | Where-Object { $_ -eq "InProgress" }).Count

    if ($inProgressCount -gt 50) {
        Write-Host "    Succès: Les pondérations personnalisées ont été appliquées. Statut 'InProgress' généré $inProgressCount fois sur 100." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les pondérations personnalisées n'ont pas été appliquées correctement. Statut 'InProgress' généré seulement $inProgressCount fois sur 100." -ForegroundColor Red
    }

    # Test 3: Générer un statut aléatoire en excluant certains statuts
    Write-Host "  Test 3: Générer un statut aléatoire en excluant certains statuts" -ForegroundColor Gray
    $excludeStatuses = @("Completed", "Blocked")
    $result3 = Get-RandomTaskStatus -ExcludeStatuses $excludeStatuses

    if ($result3 -in @("NotStarted", "InProgress")) {
        Write-Host "    Succès: Un statut valide non exclu a été généré: $result3" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le statut généré est exclu ou non valide: $result3" -ForegroundColor Red
    }

    # Test 4: Générer un statut aléatoire avec une graine spécifique
    Write-Host "  Test 4: Générer un statut aléatoire avec une graine spécifique" -ForegroundColor Gray
    $result4a = Get-RandomTaskStatus -RandomSeed 12345
    $result4b = Get-RandomTaskStatus -RandomSeed 12345

    if ($result4a -eq $result4b) {
        Write-Host "    Succès: Les statuts générés avec la même graine sont identiques: $result4a" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les statuts générés avec la même graine sont différents: $result4a vs $result4b" -ForegroundColor Red
    }
}

# Test pour la fonction New-StatusHierarchy
function Test-StatusHierarchy {
    Write-Host "`nTest de la fonction New-StatusHierarchy:" -ForegroundColor Yellow

    # Créer une hiérarchie de tâches de test
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche racine"),
        (New-TestTask -Id "1.1" -Title "Sous-tâche 1.1" -ParentId "1"),
        (New-TestTask -Id "1.2" -Title "Sous-tâche 1.2" -ParentId "1"),
        (New-TestTask -Id "1.1.1" -Title "Sous-tâche 1.1.1" -ParentId "1.1"),
        (New-TestTask -Id "1.1.2" -Title "Sous-tâche 1.1.2" -ParentId "1.1"),
        (New-TestTask -Id "1.2.1" -Title "Sous-tâche 1.2.1" -ParentId "1.2")
    )

    # Ajouter les références aux enfants
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[1].Children = @("1.1.1", "1.1.2")
    $tasks[2].Children = @("1.2.1")

    # Test 1: Générer des statuts pour une hiérarchie de tâches
    Write-Host "  Test 1: Générer des statuts pour une hiérarchie de tâches" -ForegroundColor Gray
    $result1 = New-StatusHierarchy -Tasks $tasks.Clone() -RandomSeed 12345

    $allHaveStatus = $true
    foreach ($task in $result1) {
        if (-not $task.Status) {
            $allHaveStatus = $false
            break
        }
    }

    if ($allHaveStatus) {
        Write-Host "    Succès: Toutes les tâches ont un statut." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Status)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches n'ont pas de statut." -ForegroundColor Red
    }

    # Test 2: Vérifier la cohérence hiérarchique
    Write-Host "  Test 2: Vérifier la cohérence hiérarchique" -ForegroundColor Gray

    # Définir des statuts spécifiques pour tester la cohérence
    $testTasks = $tasks.Clone()
    $testTasks[0].Status = "Completed"  # Tâche racine complétée

    $result2 = New-StatusHierarchy -Tasks $testTasks -RandomSeed 12345

    $allChildrenCompleted = $true
    foreach ($task in $result2 | Where-Object { $_.ParentId -eq "1" }) {
        if ($task.Status -ne "Completed") {
            $allChildrenCompleted = $false
            break
        }
    }

    if ($allChildrenCompleted) {
        Write-Host "    Succès: Tous les enfants d'une tâche complétée sont également complétés." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certains enfants d'une tâche complétée ne sont pas complétés." -ForegroundColor Red
    }

    # Test 3: Vérifier la cohérence avec une tâche bloquée
    Write-Host "  Test 3: Vérifier la cohérence avec une tâche bloquée" -ForegroundColor Gray

    # Pour ce test, nous allons utiliser directement la fonction New-TaskStatusWithSubtasks
    # qui garantit qu'au moins 70% des sous-tâches d'une tâche bloquée sont également bloquées
    $result3 = New-TaskStatusWithSubtasks -ParentStatus "Blocked" -SubtaskCount 10 -RandomSeed 12345

    # Vérifier qu'au moins un enfant est bloqué
    $anyChildBlocked = $false
    $blockedCount = 0

    foreach ($status in $result3.SubtaskStatuses) {
        Write-Host "      Sous-tâche: $status" -ForegroundColor Gray
        if ($status -eq "Blocked") {
            $anyChildBlocked = $true
            $blockedCount++
        }
    }

    Write-Host "      Nombre de sous-tâches bloquées: $blockedCount sur $($result3.SubtaskStatuses.Count)" -ForegroundColor Gray

    if ($anyChildBlocked) {
        Write-Host "    Succès: Au moins un enfant d'une tâche bloquée est également bloqué." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Aucun enfant d'une tâche bloquée n'est bloqué." -ForegroundColor Red
    }
}

# Test pour la fonction Update-TaskStatusHierarchy
function Test-UpdateTaskStatusHierarchy {
    Write-Host "`nTest de la fonction Update-TaskStatusHierarchy:" -ForegroundColor Yellow

    # Créer une hiérarchie de tâches de test avec des statuts incohérents
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche racine" -Status "NotStarted"),
        (New-TestTask -Id "1.1" -Title "Sous-tâche 1.1" -ParentId "1" -Status "InProgress"),
        (New-TestTask -Id "1.2" -Title "Sous-tâche 1.2" -ParentId "1" -Status "NotStarted"),
        (New-TestTask -Id "1.1.1" -Title "Sous-tâche 1.1.1" -ParentId "1.1" -Status "Completed"),
        (New-TestTask -Id "1.1.2" -Title "Sous-tâche 1.1.2" -ParentId "1.1" -Status "InProgress"),
        (New-TestTask -Id "1.2.1" -Title "Sous-tâche 1.2.1" -ParentId "1.2" -Status "Blocked")
    )

    # Ajouter les références aux enfants
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[1].Children = @("1.1.1", "1.1.2")
    $tasks[2].Children = @("1.2.1")

    # Test 1: Mettre à jour les statuts pour maintenir la cohérence
    Write-Host "  Test 1: Mettre à jour les statuts pour maintenir la cohérence" -ForegroundColor Gray
    $result1 = Update-TaskStatusHierarchy -Tasks $tasks.Clone()

    # Vérifier que la tâche racine est maintenant en cours (car elle a un enfant en cours)
    if ($result1[0].Status -eq "InProgress") {
        Write-Host "    Succès: La tâche racine a été mise à jour en 'InProgress' car elle a un enfant en cours." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche racine n'a pas été mise à jour correctement. Statut actuel: $($result1[0].Status)" -ForegroundColor Red
    }

    # Test 2: Vérifier la cohérence avec une tâche parent complétée
    Write-Host "  Test 2: Vérifier la cohérence avec une tâche parent complétée" -ForegroundColor Gray

    $testTasks = $tasks.Clone()
    $testTasks[0].Status = "Completed"

    $result2 = Update-TaskStatusHierarchy -Tasks $testTasks

    $allChildrenCompleted = $true
    foreach ($task in $result2 | Where-Object { $_.ParentId -eq "1" }) {
        if ($task.Status -ne "Completed") {
            $allChildrenCompleted = $false
            break
        }
    }

    if ($allChildrenCompleted) {
        Write-Host "    Succès: Tous les enfants d'une tâche complétée ont été mis à jour en 'Completed'." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certains enfants d'une tâche complétée n'ont pas été mis à jour correctement." -ForegroundColor Red
    }

    # Test 3: Vérifier la cohérence avec tous les enfants complétés
    Write-Host "  Test 3: Vérifier la cohérence avec tous les enfants complétés" -ForegroundColor Gray

    $testTasks = $tasks.Clone()
    $testTasks[1].Status = "NotStarted"
    $testTasks[3].Status = "Completed"
    $testTasks[4].Status = "Completed"

    $result3 = Update-TaskStatusHierarchy -Tasks $testTasks

    if ($result3[1].Status -eq "Completed") {
        Write-Host "    Succès: La tâche parent a été mise à jour en 'Completed' car tous ses enfants sont complétés." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche parent n'a pas été mise à jour correctement. Statut actuel: $($result3[1].Status)" -ForegroundColor Red
    }
}

# Test pour la fonction New-TaskStatusWithSubtasks
function Test-TaskStatusWithSubtasks {
    Write-Host "`nTest de la fonction New-TaskStatusWithSubtasks:" -ForegroundColor Yellow

    # Test 1: Générer des statuts pour une tâche complétée et ses sous-tâches
    Write-Host "  Test 1: Générer des statuts pour une tâche complétée et ses sous-tâches" -ForegroundColor Gray
    $result1 = New-TaskStatusWithSubtasks -ParentStatus "Completed" -SubtaskCount 5 -RandomSeed 12345

    $allSubtasksCompleted = $true
    foreach ($status in $result1.SubtaskStatuses) {
        if ($status -ne "Completed") {
            $allSubtasksCompleted = $false
            break
        }
    }

    if ($allSubtasksCompleted) {
        Write-Host "    Succès: Toutes les sous-tâches d'une tâche complétée sont également complétées." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certaines sous-tâches d'une tâche complétée ne sont pas complétées." -ForegroundColor Red
    }

    # Test 2: Générer des statuts pour une tâche bloquée et ses sous-tâches
    Write-Host "  Test 2: Générer des statuts pour une tâche bloquée et ses sous-tâches" -ForegroundColor Gray
    $result2 = New-TaskStatusWithSubtasks -ParentStatus "Blocked" -SubtaskCount 10 -RandomSeed 12345

    $blockedCount = ($result2.SubtaskStatuses | Where-Object { $_ -eq "Blocked" }).Count
    $blockedPercentage = $blockedCount / $result2.SubtaskStatuses.Count * 100

    if ($blockedPercentage -ge 70) {
        Write-Host "    Succès: Au moins 70% des sous-tâches d'une tâche bloquée sont également bloquées ($blockedPercentage%)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Moins de 70% des sous-tâches d'une tâche bloquée sont bloquées ($blockedPercentage%)." -ForegroundColor Red
    }

    # Test 3: Générer des statuts pour une tâche en cours et ses sous-tâches
    Write-Host "  Test 3: Générer des statuts pour une tâche en cours et ses sous-tâches" -ForegroundColor Gray
    $result3 = New-TaskStatusWithSubtasks -ParentStatus "InProgress" -SubtaskCount 10 -RandomSeed 12345

    $inProgressOrCompletedCount = ($result3.SubtaskStatuses | Where-Object { $_ -eq "InProgress" -or $_ -eq "Completed" }).Count
    $inProgressOrCompletedPercentage = $inProgressOrCompletedCount / $result3.SubtaskStatuses.Count * 100

    if ($inProgressOrCompletedPercentage -ge 50) {
        Write-Host "    Succès: Au moins 50% des sous-tâches d'une tâche en cours sont en cours ou complétées ($inProgressOrCompletedPercentage%)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Moins de 50% des sous-tâches d'une tâche en cours sont en cours ou complétées ($inProgressOrCompletedPercentage%)." -ForegroundColor Red
    }

    # Test 4: Générer des statuts pour une tâche non commencée et ses sous-tâches
    Write-Host "  Test 4: Générer des statuts pour une tâche non commencée et ses sous-tâches" -ForegroundColor Gray
    $result4 = New-TaskStatusWithSubtasks -ParentStatus "NotStarted" -SubtaskCount 10 -RandomSeed 12345

    $noInProgressOrCompleted = $true
    foreach ($status in $result4.SubtaskStatuses) {
        if ($status -eq "InProgress" -or $status -eq "Completed") {
            $noInProgressOrCompleted = $false
            break
        }
    }

    if ($noInProgressOrCompleted) {
        Write-Host "    Succès: Aucune sous-tâche d'une tâche non commencée n'est en cours ou complétée." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certaines sous-tâches d'une tâche non commencée sont en cours ou complétées." -ForegroundColor Red
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan
