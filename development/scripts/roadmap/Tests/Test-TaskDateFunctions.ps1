# Test-TaskDateFunctions.ps1
# Script de test pour les fonctions de gestion des dates de tâches
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskDates.ps1"
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
        [string]$ParentId = $null,

        [Parameter(Mandatory = $false)]
        [string[]]$Children = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )

    return [PSCustomObject]@{
        Id             = $Id
        Title          = $Title
        IndentLevel    = $IndentLevel
        ParentId       = $ParentId
        Children       = $Children
        Dependencies   = $Dependencies
        DependentTasks = @()
        Metadata       = $Metadata
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de gestion des dates de tâches..." -ForegroundColor Cyan

    Test-ConstrainedTaskDates
    Test-TaskDurationCalculation
    Test-DurationConversion
    Test-TaskDependencies

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction New-ConstrainedTaskDates
function Test-ConstrainedTaskDates {
    Write-Host "`nTest de la fonction New-ConstrainedTaskDates:" -ForegroundColor Yellow

    # Créer des tâches de test
    $task1 = New-TestTask -Id "1" -Title "Tâche 1" -IndentLevel 0
    $task2 = New-TestTask -Id "2" -Title "Tâche 2" -IndentLevel 1 -ParentId "1" -Dependencies @("1")

    # Définir les dates de la tâche 1
    $task1.Metadata["StartDate"] = "2025-06-01"
    $task1.Metadata["EndDate"] = "2025-06-10"

    # Test 1: Générer des dates avec des jours de la semaine autorisés
    Write-Host "  Test 1: Générer des dates avec des jours de la semaine autorisés" -ForegroundColor Gray
    $result1 = New-ConstrainedTaskDates -ProjectStartDate ([DateTime]::Parse("2025-06-01")) `
        -ProjectEndDate ([DateTime]::Parse("2025-07-31")) `
        -MinDuration 3 -MaxDuration 7 `
        -AllowedDaysOfWeek @([DayOfWeek]::Monday, [DayOfWeek]::Wednesday, [DayOfWeek]::Friday)

    $startDate1 = [DateTime]::Parse($result1.StartDate)
    $isValidDay1 = $startDate1.DayOfWeek -in @([DayOfWeek]::Monday, [DayOfWeek]::Wednesday, [DayOfWeek]::Friday)

    if ($isValidDay1) {
        Write-Host "    Succès: La date de début ($($result1.StartDate)) est un jour autorisé." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La date de début ($($result1.StartDate)) n'est pas un jour autorisé." -ForegroundColor Red
    }

    # Test 2: Générer des dates avec des plages interdites
    Write-Host "  Test 2: Générer des dates avec des plages interdites" -ForegroundColor Gray
    $forbiddenRanges = @(
        @{StartDate = "2025-06-15"; EndDate = "2025-06-30" }
    )

    $result2 = New-ConstrainedTaskDates -ProjectStartDate ([DateTime]::Parse("2025-06-01")) `
        -ProjectEndDate ([DateTime]::Parse("2025-07-31")) `
        -MinDuration 3 -MaxDuration 7 `
        -ForbiddenDateRanges $forbiddenRanges

    $startDate2 = [DateTime]::Parse($result2.StartDate)
    $isInForbiddenRange = $false

    foreach ($range in $forbiddenRanges) {
        $rangeStart = [DateTime]::Parse($range.StartDate)
        $rangeEnd = [DateTime]::Parse($range.EndDate)

        if ($startDate2 -ge $rangeStart -and $startDate2 -le $rangeEnd) {
            $isInForbiddenRange = $true
            break
        }
    }

    if (-not $isInForbiddenRange) {
        Write-Host "    Succès: La date de début ($($result2.StartDate)) n'est pas dans une plage interdite." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La date de début ($($result2.StartDate)) est dans une plage interdite." -ForegroundColor Red
    }

    # Test 3: Générer des dates avec des dépendances
    Write-Host "  Test 3: Générer des dates avec des dépendances" -ForegroundColor Gray
    $result3 = New-ConstrainedTaskDates -ProjectStartDate ([DateTime]::Parse("2025-06-01")) `
        -ProjectEndDate ([DateTime]::Parse("2025-07-31")) `
        -MinDuration 3 -MaxDuration 7 `
        -DependsOnTasks @($task1)

    $startDate3 = [DateTime]::Parse($result3.StartDate)
    $task1EndDate = [DateTime]::Parse($task1.Metadata["EndDate"])

    if ($startDate3 -ge $task1EndDate) {
        Write-Host "    Succès: La date de début ($($result3.StartDate)) est après la fin de la dépendance ($($task1.Metadata["EndDate"]))." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La date de début ($($result3.StartDate)) est avant la fin de la dépendance ($($task1.Metadata["EndDate"]))." -ForegroundColor Red
    }
}

# Test pour les fonctions de calcul de durée
function Test-TaskDurationCalculation {
    Write-Host "`nTest des fonctions de calcul de durée:" -ForegroundColor Yellow

    # Test 1: Calculer la durée en fonction de la complexité
    Write-Host "  Test 1: Calculer la durée en fonction de la complexité" -ForegroundColor Gray
    $duration1 = Get-TaskDuration -Complexity 3 -Resources 1 -TaskLevel 0 -TaskType "Developpement"
    $duration2 = Get-TaskDuration -Complexity 7 -Resources 1 -TaskLevel 0 -TaskType "Developpement"

    if ($duration2 -gt $duration1) {
        Write-Host "    Succès: La durée pour une complexité de 7 ($duration2 jours) est supérieure à celle pour une complexité de 3 ($duration1 jours)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La durée pour une complexité de 7 ($duration2 jours) n'est pas supérieure à celle pour une complexité de 3 ($duration1 jours)." -ForegroundColor Red
    }

    # Test 2: Calculer la durée en fonction des ressources
    Write-Host "  Test 2: Calculer la durée en fonction des ressources" -ForegroundColor Gray
    $duration3 = Get-TaskDuration -Complexity 5 -Resources 1 -TaskLevel 0 -TaskType "Developpement"
    $duration4 = Get-TaskDuration -Complexity 5 -Resources 3 -TaskLevel 0 -TaskType "Developpement"

    if ($duration4 -lt $duration3) {
        Write-Host "    Succès: La durée avec 3 ressources ($duration4 jours) est inférieure à celle avec 1 ressource ($duration3 jours)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La durée avec 3 ressources ($duration4 jours) n'est pas inférieure à celle avec 1 ressource ($duration3 jours)." -ForegroundColor Red
    }

    # Test 3: Calculer la durée en fonction du type de tâche
    Write-Host "  Test 3: Calculer la durée en fonction du type de tâche" -ForegroundColor Gray
    $duration5 = Get-TaskDuration -Complexity 5 -Resources 1 -TaskLevel 0 -TaskType "Developpement"
    $duration6 = Get-TaskDuration -Complexity 5 -Resources 1 -TaskLevel 0 -TaskType "Documentation"

    if ($duration6 -lt $duration5) {
        Write-Host "    Succès: La durée pour une tâche de documentation ($duration6 jours) est inférieure à celle pour une tâche de développement ($duration5 jours)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La durée pour une tâche de documentation ($duration6 jours) n'est pas inférieure à celle pour une tâche de développement ($duration5 jours)." -ForegroundColor Red
    }

    # Test 4: Estimer la durée en fonction de tâches similaires
    Write-Host "  Test 4: Estimer la durée en fonction de tâches similaires" -ForegroundColor Gray
    $similarTasks = @(
        @{Complexity = 4; Duration = 8; TaskType = "Développement" },
        @{Complexity = 5; Duration = 10; TaskType = "Développement" },
        @{Complexity = 6; Duration = 12; TaskType = "Développement" }
    )

    $estimatedDuration = Get-EstimatedTaskDuration -SimilarTasks $similarTasks -Complexity 5 -TaskType "Développement"

    if ($estimatedDuration -eq 10) {
        Write-Host "    Succès: La durée estimée ($estimatedDuration jours) correspond à la durée attendue (10 jours)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La durée estimée ($estimatedDuration jours) ne correspond pas à la durée attendue (10 jours)." -ForegroundColor Red
    }
}

# Test pour la fonction Convert-Duration
function Test-DurationConversion {
    Write-Host "`nTest de la fonction Convert-Duration:" -ForegroundColor Yellow

    # Test 1: Convertir des heures en jours
    Write-Host "  Test 1: Convertir des heures en jours" -ForegroundColor Gray
    $days = Convert-Duration -Value 16 -FromUnit "Heures" -ToUnit "Jours" -WorkHoursPerDay 8

    if ($days -eq 2) {
        Write-Host "    Succès: 16 heures = 2 jours (avec 8 heures de travail par jour)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: 16 heures = $days jours (attendu: 2 jours)." -ForegroundColor Red
    }

    # Test 2: Convertir des jours en semaines
    Write-Host "  Test 2: Convertir des jours en semaines" -ForegroundColor Gray
    $weeks = Convert-Duration -Value 10 -FromUnit "Jours" -ToUnit "Semaines" -WorkDaysPerWeek 5

    if ($weeks -eq 2) {
        Write-Host "    Succès: 10 jours = 2 semaines (avec 5 jours de travail par semaine)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: 10 jours = $weeks semaines (attendu: 2 semaines)." -ForegroundColor Red
    }

    # Test 3: Convertir des semaines en mois
    Write-Host "  Test 3: Convertir des semaines en mois" -ForegroundColor Gray
    $months = Convert-Duration -Value 4 -FromUnit "Semaines" -ToUnit "Mois" -WorkDaysPerWeek 5 -WorkDaysPerMonth 21

    $expectedMonths = (4 * 5) / 21
    if ([Math]::Abs($months - $expectedMonths) -lt 0.01) {
        Write-Host "    Succès: 4 semaines ≈ $([Math]::Round($expectedMonths, 2)) mois (avec 5 jours par semaine et 21 jours par mois)." -ForegroundColor Green
    } else {
        Write-Host "    Échec: 4 semaines = $months mois (attendu: $expectedMonths mois)." -ForegroundColor Red
    }
}

# Test pour les fonctions de gestion des dépendances
function Test-TaskDependencies {
    Write-Host "`nTest des fonctions de gestion des dépendances:" -ForegroundColor Yellow

    # Créer des tâches de test
    $task1 = New-TestTask -Id "1" -Title "Tâche 1" -IndentLevel 0
    $task2 = New-TestTask -Id "2" -Title "Tâche 2" -IndentLevel 1
    $task3 = New-TestTask -Id "3" -Title "Tâche 3" -IndentLevel 1

    # Définir les dates des tâches
    $task1.Metadata["StartDate"] = "2025-06-01"
    $task1.Metadata["EndDate"] = "2025-06-10"

    $task2.Metadata["StartDate"] = "2025-06-15"
    $task2.Metadata["EndDate"] = "2025-06-20"

    $task3.Metadata["StartDate"] = "2025-06-25"
    $task3.Metadata["EndDate"] = "2025-06-30"

    # Test 1: Ajouter une dépendance FinishToStart
    Write-Host "  Test 1: Ajouter une dépendance FinishToStart" -ForegroundColor Gray
    $result1 = Add-TaskDependency -SourceTask $task1 -TargetTask $task2 -DependencyType "FinishToStart" -Delay 2

    if ($result1) {
        $task2StartDate = [DateTime]::Parse($task2.Metadata["StartDate"])
        $task1EndDate = [DateTime]::Parse($task1.Metadata["EndDate"])
        $expectedStartDate = $task1EndDate.AddDays(2)

        if ($task2StartDate -eq $expectedStartDate) {
            Write-Host "    Succès: La date de début de la tâche 2 ($($task2.Metadata["StartDate"])) est correctement mise à jour (fin de tâche 1 + 2 jours)." -ForegroundColor Green
        } else {
            Write-Host "    Échec: La date de début de la tâche 2 ($($task2.Metadata["StartDate"])) n'est pas correctement mise à jour (attendu: $($expectedStartDate.ToString("yyyy-MM-dd")))." -ForegroundColor Red
        }
    } else {
        Write-Host "    Échec: Impossible d'ajouter la dépendance FinishToStart." -ForegroundColor Red
    }

    # Test 2: Ajouter une dépendance StartToStart
    Write-Host "  Test 2: Ajouter une dépendance StartToStart" -ForegroundColor Gray
    $result2 = Add-TaskDependency -SourceTask $task2 -TargetTask $task3 -DependencyType "StartToStart" -Delay 1

    if ($result2) {
        $task3StartDate = [DateTime]::Parse($task3.Metadata["StartDate"])
        $task2StartDate = [DateTime]::Parse($task2.Metadata["StartDate"])
        $expectedStartDate = $task2StartDate.AddDays(1)

        if ($task3StartDate -eq $expectedStartDate) {
            Write-Host "    Succès: La date de début de la tâche 3 ($($task3.Metadata["StartDate"])) est correctement mise à jour (début de tâche 2 + 1 jour)." -ForegroundColor Green
        } else {
            Write-Host "    Échec: La date de début de la tâche 3 ($($task3.Metadata["StartDate"])) n'est pas correctement mise à jour (attendu: $($expectedStartDate.ToString("yyyy-MM-dd")))." -ForegroundColor Red
        }
    } else {
        Write-Host "    Échec: Impossible d'ajouter la dépendance StartToStart." -ForegroundColor Red
    }

    # Test 3: Détecter les cycles de dépendances
    Write-Host "  Test 3: Détecter les cycles de dépendances" -ForegroundColor Gray
    $result3 = Add-TaskDependency -SourceTask $task3 -TargetTask $task1 -DependencyType "FinishToStart" -Force

    if ($result3) {
        $validationResult = Test-TaskDependencies -Tasks @($task1, $task2, $task3)

        if (-not $validationResult.IsValid -and $validationResult.Cycles.Count -gt 0) {
            Write-Host "    Succès: Le cycle de dépendances a été détecté." -ForegroundColor Green
        } else {
            Write-Host "    Échec: Le cycle de dépendances n'a pas été détecté." -ForegroundColor Red
        }
    } else {
        Write-Host "    Échec: Impossible d'ajouter la dépendance pour créer un cycle." -ForegroundColor Red
    }
}

# Exécuter tous les tests
Invoke-AllTests
