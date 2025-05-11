# Test-TaskProgress.ps1
# Script de test pour les fonctions de génération de pourcentages d'avancement
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskProgress.ps1"
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
        [int]$Progress = $null
    )

    return [PSCustomObject]@{
        Id       = $Id
        Title    = $Title
        ParentId = $ParentId
        Children = $Children
        Status   = $Status
        Progress = $Progress
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de génération de pourcentages d'avancement..." -ForegroundColor Cyan

    Test-RandomProgress
    Test-TaskProgress
    Test-TaskProgressHierarchy
    Test-WeightedTaskProgress

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction Get-RandomProgress
function Test-RandomProgress {
    Write-Host "`nTest de la fonction Get-RandomProgress:" -ForegroundColor Yellow

    # Test 1: Générer un pourcentage aléatoire avec les pondérations par défaut
    Write-Host "  Test 1: Générer un pourcentage aléatoire avec les pondérations par défaut" -ForegroundColor Gray
    $result1 = Get-RandomProgress

    if ($result1 -ge 0 -and $result1 -le 99) {
        Write-Host "    Succès: Un pourcentage valide a été généré: $result1" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le pourcentage généré n'est pas valide: $result1" -ForegroundColor Red
    }

    # Test 2: Générer un pourcentage aléatoire avec des pondérations personnalisées
    Write-Host "  Test 2: Générer un pourcentage aléatoire avec des pondérations personnalisées" -ForegroundColor Gray
    $weights = @{
        "0-25"  = 10
        "26-50" = 70
        "51-75" = 15
        "76-99" = 5
    }

    $percentages = @()
    for ($i = 0; $i -lt 100; $i++) {
        $percentages += Get-RandomProgress -Weights $weights -RandomSeed $i
    }

    $middleRangeCount = ($percentages | Where-Object { $_ -ge 26 -and $_ -le 50 }).Count

    if ($middleRangeCount -gt 50) {
        Write-Host "    Succès: Les pondérations personnalisées ont été appliquées. Pourcentages entre 26 et 50 générés $middleRangeCount fois sur 100." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les pondérations personnalisées n'ont pas été appliquées correctement. Pourcentages entre 26 et 50 générés seulement $middleRangeCount fois sur 100." -ForegroundColor Red
    }

    # Test 3: Générer un pourcentage aléatoire en excluant certaines plages
    Write-Host "  Test 3: Générer un pourcentage aléatoire en excluant certaines plages" -ForegroundColor Gray
    $excludeRanges = @("0-25", "76-99")
    $result3 = Get-RandomProgress -ExcludeRanges $excludeRanges

    if ($result3 -ge 26 -and $result3 -le 75) {
        Write-Host "    Succès: Un pourcentage valide non exclu a été généré: $result3" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le pourcentage généré est exclu ou non valide: $result3" -ForegroundColor Red
    }

    # Test 4: Générer un pourcentage aléatoire avec une graine spécifique
    Write-Host "  Test 4: Générer un pourcentage aléatoire avec une graine spécifique" -ForegroundColor Gray
    $result4a = Get-RandomProgress -RandomSeed 12345
    $result4b = Get-RandomProgress -RandomSeed 12345

    if ($result4a -eq $result4b) {
        Write-Host "    Succès: Les pourcentages générés avec la même graine sont identiques: $result4a" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les pourcentages générés avec la même graine sont différents: $result4a vs $result4b" -ForegroundColor Red
    }

    # Test 5: Générer un pourcentage aléatoire en fonction du statut
    Write-Host "  Test 5: Générer un pourcentage aléatoire en fonction du statut" -ForegroundColor Gray
    $result5a = Get-RandomProgress -Status "NotStarted"
    $result5b = Get-RandomProgress -Status "InProgress"
    $result5c = Get-RandomProgress -Status "Completed"
    $result5d = Get-RandomProgress -Status "Blocked"

    $success = $true
    if ($result5a -gt 25) {
        Write-Host "    Échec: Le pourcentage généré pour 'NotStarted' est trop élevé: $result5a" -ForegroundColor Red
        $success = $false
    }
    if ($result5c -ne 100) {
        Write-Host "    Échec: Le pourcentage généré pour 'Completed' n'est pas 100: $result5c" -ForegroundColor Red
        $success = $false
    }

    if ($success) {
        Write-Host "    Succès: Les pourcentages générés en fonction du statut sont cohérents:" -ForegroundColor Green
        Write-Host "      NotStarted: $result5a" -ForegroundColor Gray
        Write-Host "      InProgress: $result5b" -ForegroundColor Gray
        Write-Host "      Completed: $result5c" -ForegroundColor Gray
        Write-Host "      Blocked: $result5d" -ForegroundColor Gray
    }
}

# Test pour la fonction New-TaskProgress
function Test-TaskProgress {
    Write-Host "`nTest de la fonction New-TaskProgress:" -ForegroundColor Yellow

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

    # Test 1: Générer des pourcentages d'avancement pour une hiérarchie de tâches
    Write-Host "  Test 1: Générer des pourcentages d'avancement pour une hiérarchie de tâches" -ForegroundColor Gray
    $result1 = New-TaskProgress -Tasks $tasks.Clone() -RandomSeed 12345

    $allHaveProgress = $true
    foreach ($task in $result1) {
        if ($null -eq $task.Progress) {
            $allHaveProgress = $false
            break
        }
    }

    if ($allHaveProgress) {
        Write-Host "    Succès: Toutes les tâches ont un pourcentage d'avancement." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Progress)%" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches n'ont pas de pourcentage d'avancement." -ForegroundColor Red
    }

    # Test 2: Vérifier la cohérence hiérarchique
    Write-Host "  Test 2: Vérifier la cohérence hiérarchique" -ForegroundColor Gray

    # Définir des pourcentages spécifiques pour tester la cohérence
    $testTasks = $tasks.Clone()
    $testTasks[0].Progress = 100  # Tâche racine à 100%

    $result2 = New-TaskProgress -Tasks $testTasks -RandomSeed 12345

    $allChildrenComplete = $true
    foreach ($task in $result2 | Where-Object { $_.ParentId -eq "1" }) {
        if ($task.Progress -ne 100) {
            $allChildrenComplete = $false
            break
        }
    }

    if ($allChildrenComplete) {
        Write-Host "    Succès: Tous les enfants d'une tâche à 100% sont également à 100%." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certains enfants d'une tâche à 100% ne sont pas à 100%." -ForegroundColor Red
    }

    # Test 3: Vérifier la cohérence avec une tâche à 0%
    Write-Host "  Test 3: Vérifier la cohérence avec une tâche à 0%" -ForegroundColor Gray

    $testTasks = $tasks.Clone()
    $testTasks[1].Progress = 0  # Sous-tâche 1.1 à 0%

    $result3 = New-TaskProgress -Tasks $testTasks -RandomSeed 12345

    $allChildrenLow = $true
    foreach ($task in $result3 | Where-Object { $_.ParentId -eq "1.1" }) {
        if ($task.Progress -gt 20) {
            $allChildrenLow = $false
            break
        }
    }

    if ($allChildrenLow) {
        Write-Host "    Succès: Tous les enfants d'une tâche à 0% ont un pourcentage faible." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certains enfants d'une tâche à 0% ont un pourcentage élevé." -ForegroundColor Red
    }
}

# Test pour la fonction Update-TaskProgressHierarchy
function Test-TaskProgressHierarchy {
    Write-Host "`nTest de la fonction Update-TaskProgressHierarchy:" -ForegroundColor Yellow

    # Créer une hiérarchie de tâches de test avec des pourcentages incohérents
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche racine" -Progress 50),
        (New-TestTask -Id "1.1" -Title "Sous-tâche 1.1" -ParentId "1" -Progress 20),
        (New-TestTask -Id "1.2" -Title "Sous-tâche 1.2" -ParentId "1" -Progress 80),
        (New-TestTask -Id "1.1.1" -Title "Sous-tâche 1.1.1" -ParentId "1.1" -Progress 100),
        (New-TestTask -Id "1.1.2" -Title "Sous-tâche 1.1.2" -ParentId "1.1" -Progress 60),
        (New-TestTask -Id "1.2.1" -Title "Sous-tâche 1.2.1" -ParentId "1.2" -Progress 100)
    )

    # Ajouter les références aux enfants
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[1].Children = @("1.1.1", "1.1.2")
    $tasks[2].Children = @("1.2.1")

    # Test 1: Mettre à jour les pourcentages pour maintenir la cohérence
    Write-Host "  Test 1: Mettre à jour les pourcentages pour maintenir la cohérence" -ForegroundColor Gray
    $result1 = Update-TaskProgressHierarchy -Tasks $tasks.Clone()

    # Vérifier que le pourcentage de la tâche racine est cohérent avec la moyenne des enfants
    $childrenAverage = [Math]::Round((20 + 80) / 2)
    if ([Math]::Abs($result1[0].Progress - $childrenAverage) -le 10) {
        Write-Host "    Succès: Le pourcentage de la tâche racine a été ajusté pour être cohérent avec la moyenne des enfants." -ForegroundColor Green
        Write-Host "      Pourcentage ajusté: $($result1[0].Progress)% (moyenne des enfants: $childrenAverage%)" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: Le pourcentage de la tâche racine n'a pas été ajusté correctement. Pourcentage actuel: $($result1[0].Progress)% (moyenne des enfants: $childrenAverage%)" -ForegroundColor Red
    }

    # Test 2: Vérifier la cohérence avec une tâche parent à 100%
    Write-Host "  Test 2: Vérifier la cohérence avec une tâche parent à 100%" -ForegroundColor Gray

    $testTasks = $tasks.Clone()
    $testTasks[0].Progress = 100

    $result2 = Update-TaskProgressHierarchy -Tasks $testTasks

    $allChildrenComplete = $true
    foreach ($task in $result2 | Where-Object { $_.ParentId -eq "1" }) {
        if ($task.Progress -ne 100) {
            $allChildrenComplete = $false
            break
        }
    }

    if ($allChildrenComplete) {
        Write-Host "    Succès: Tous les enfants d'une tâche à 100% ont été mis à jour à 100%." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certains enfants d'une tâche à 100% n'ont pas été mis à jour correctement." -ForegroundColor Red
    }

    # Test 3: Vérifier la cohérence avec tous les enfants à 100%
    Write-Host "  Test 3: Vérifier la cohérence avec tous les enfants à 100%" -ForegroundColor Gray

    $testTasks = $tasks.Clone()
    $testTasks[1].Progress = 50
    $testTasks[3].Progress = 100
    $testTasks[4].Progress = 100

    $result3 = Update-TaskProgressHierarchy -Tasks $testTasks

    if ($result3[1].Progress -eq 100) {
        Write-Host "    Succès: La tâche parent a été mise à jour à 100% car tous ses enfants sont à 100%." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche parent n'a pas été mise à jour correctement. Pourcentage actuel: $($result3[1].Progress)%" -ForegroundColor Red
    }
}

# Test pour la fonction Get-WeightedTaskProgress
function Test-WeightedTaskProgress {
    Write-Host "`nTest de la fonction Get-WeightedTaskProgress:" -ForegroundColor Yellow

    # Créer une hiérarchie de tâches de test
    $tasks = @(
        (New-TestTask -Id "1" -Title "Tâche racine" -Progress 50),
        (New-TestTask -Id "1.1" -Title "Sous-tâche 1.1" -ParentId "1" -Progress 20),
        (New-TestTask -Id "1.2" -Title "Sous-tâche 1.2" -ParentId "1" -Progress 80),
        (New-TestTask -Id "1.1.1" -Title "Sous-tâche 1.1.1" -ParentId "1.1" -Progress 10),
        (New-TestTask -Id "1.1.2" -Title "Sous-tâche 1.1.2" -ParentId "1.1" -Progress 30),
        (New-TestTask -Id "1.2.1" -Title "Sous-tâche 1.2.1" -ParentId "1.2" -Progress 80)
    )

    # Ajouter les références aux enfants
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[1].Children = @("1.1.1", "1.1.2")
    $tasks[2].Children = @("1.2.1")

    # Test 1: Calculer le pourcentage d'avancement pondéré avec des poids égaux
    Write-Host "  Test 1: Calculer le pourcentage d'avancement pondéré avec des poids égaux" -ForegroundColor Gray
    $result1 = Get-WeightedTaskProgress -Tasks $tasks -RootTaskId "1" -WeightingStrategy "Equal"

    # Calculer manuellement le pourcentage attendu
    $expectedProgress = [Math]::Round((20 + 80) / 2)

    if ($result1 -eq $expectedProgress) {
        Write-Host "    Succès: Le pourcentage d'avancement pondéré avec des poids égaux est correct: $result1%" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le pourcentage d'avancement pondéré avec des poids égaux est incorrect: $result1% (attendu: $expectedProgress%)" -ForegroundColor Red
    }

    # Test 2: Calculer le pourcentage d'avancement pondéré par niveau
    Write-Host "  Test 2: Calculer le pourcentage d'avancement pondéré par niveau" -ForegroundColor Gray
    $result2 = Get-WeightedTaskProgress -Tasks $tasks -RootTaskId "1" -WeightingStrategy "ByLevel"

    Write-Host "    Pourcentage d'avancement pondéré par niveau: $result2%" -ForegroundColor Gray

    # Test 3: Calculer le pourcentage d'avancement pondéré par complexité
    Write-Host "  Test 3: Calculer le pourcentage d'avancement pondéré par complexité" -ForegroundColor Gray
    $result3 = Get-WeightedTaskProgress -Tasks $tasks -RootTaskId "1" -WeightingStrategy "ByComplexity"

    Write-Host "    Pourcentage d'avancement pondéré par complexité: $result3%" -ForegroundColor Gray

    # Test 4: Calculer le pourcentage d'avancement pondéré avec des poids personnalisés
    Write-Host "  Test 4: Calculer le pourcentage d'avancement pondéré avec des poids personnalisés" -ForegroundColor Gray
    $customWeights = @{
        "1.1" = 3
        "1.2" = 1
    }

    $result4 = Get-WeightedTaskProgress -Tasks $tasks -RootTaskId "1" -WeightingStrategy "Custom" -CustomWeights $customWeights

    # Calculer manuellement le pourcentage attendu
    $expectedProgress = [Math]::Round((20 * 3 + 80 * 1) / 4)

    if ($result4 -eq $expectedProgress) {
        Write-Host "    Succès: Le pourcentage d'avancement pondéré avec des poids personnalisés est correct: $result4%" -ForegroundColor Green
    } else {
        Write-Host "    Échec: Le pourcentage d'avancement pondéré avec des poids personnalisés est incorrect: $result4% (attendu: $expectedProgress%)" -ForegroundColor Red
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan
