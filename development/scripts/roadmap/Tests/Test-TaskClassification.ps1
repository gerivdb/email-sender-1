# Test-TaskClassification.ps1
# Script de test pour les fonctions de classification automatique des tâches
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Classify-TasksAutomatically.ps1"
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
        [string]$Description = "Description de la tâche $Id",
        
        [Parameter(Mandatory = $false)]
        [string]$ParentId = $null,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Children = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @()
    )
    
    return [PSCustomObject]@{
        Id = $Id
        Title = $Title
        Description = $Description
        ParentId = $ParentId
        Children = $Children
        Dependencies = $Dependencies
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de classification automatique des tâches..." -ForegroundColor Cyan
    
    Test-TaskClassification
    Test-TaskClassificationAssignment
    Test-TaskClassificationHierarchy
    
    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction Get-TaskClassification
function Test-TaskClassification {
    Write-Host "`nTest de la fonction Get-TaskClassification:" -ForegroundColor Yellow
    
    # Test 1: Classifier une tâche de développement
    Write-Host "  Test 1: Classifier une tâche de développement" -ForegroundColor Gray
    $task1 = New-TestTask -Id "1" -Title "Développer l'API REST" -Description "Implémenter les endpoints de l'API REST pour l'authentification et la gestion des utilisateurs."
    
    $result1 = Get-TaskClassification -Task $task1
    
    Write-Host "    Classification: $($result1.Category) / $($result1.SubCategory) (Confiance: $($result1.Confidence)%)" -ForegroundColor Gray
    
    $isDevTask = $result1.Category -eq "Développement"
    
    if ($isDevTask) {
        Write-Host "    Succès: La tâche a été correctement classifiée comme une tâche de développement." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche n'a pas été correctement classifiée comme une tâche de développement." -ForegroundColor Red
    }
    
    # Test 2: Classifier une tâche de test
    Write-Host "  Test 2: Classifier une tâche de test" -ForegroundColor Gray
    $task2 = New-TestTask -Id "2" -Title "Tester l'API REST" -Description "Écrire et exécuter des tests unitaires pour l'API REST."
    
    $result2 = Get-TaskClassification -Task $task2
    
    Write-Host "    Classification: $($result2.Category) / $($result2.SubCategory) (Confiance: $($result2.Confidence)%)" -ForegroundColor Gray
    
    $isTestTask = $result2.Category -eq "Test"
    
    if ($isTestTask) {
        Write-Host "    Succès: La tâche a été correctement classifiée comme une tâche de test." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche n'a pas été correctement classifiée comme une tâche de test." -ForegroundColor Red
    }
    
    # Test 3: Classifier une tâche de documentation
    Write-Host "  Test 3: Classifier une tâche de documentation" -ForegroundColor Gray
    $task3 = New-TestTask -Id "3" -Title "Rédiger la documentation de l'API" -Description "Créer la documentation technique pour l'API REST."
    
    $result3 = Get-TaskClassification -Task $task3
    
    Write-Host "    Classification: $($result3.Category) / $($result3.SubCategory) (Confiance: $($result3.Confidence)%)" -ForegroundColor Gray
    
    $isDocTask = $result3.Category -eq "Documentation"
    
    if ($isDocTask) {
        Write-Host "    Succès: La tâche a été correctement classifiée comme une tâche de documentation." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche n'a pas été correctement classifiée comme une tâche de documentation." -ForegroundColor Red
    }
    
    # Test 4: Classifier une tâche avec un ID numérique
    Write-Host "  Test 4: Classifier une tâche avec un ID numérique" -ForegroundColor Gray
    $task4 = New-TestTask -Id "4" -Title "Tâche sans description claire"
    
    $result4 = Get-TaskClassification -Task $task4
    
    Write-Host "    Classification: $($result4.Category) / $($result4.SubCategory) (Confiance: $($result4.Confidence)%)" -ForegroundColor Gray
    
    $hasClassification = $result4.Category -ne "Non classifié"
    
    if ($hasClassification) {
        Write-Host "    Succès: La tâche a été classifiée malgré l'absence de description claire." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche n'a pas été classifiée." -ForegroundColor Red
    }
}

# Test pour la fonction New-TaskClassificationAssignment
function Test-TaskClassificationAssignment {
    Write-Host "`nTest de la fonction New-TaskClassificationAssignment:" -ForegroundColor Yellow
    
    # Créer une hiérarchie de tâches
    $tasks = @(
        (New-TestTask -Id "1" -Title "Développer le système d'authentification" -Description "Implémenter le système d'authentification et d'autorisation."),
        (New-TestTask -Id "1.1" -ParentId "1" -Title "Implémenter l'authentification OAuth" -Description "Développer le support pour OAuth 2.0."),
        (New-TestTask -Id "1.2" -ParentId "1" -Title "Ajouter l'authentification à deux facteurs" -Description "Implémenter l'authentification à deux facteurs (2FA)."),
        (New-TestTask -Id "2" -Title "Tester le système" -Description "Écrire et exécuter des tests pour le système."),
        (New-TestTask -Id "2.1" -ParentId "2" -Title "Écrire des tests unitaires" -Description "Développer des tests unitaires pour les fonctionnalités."),
        (New-TestTask -Id "2.2" -ParentId "2" -Title "Exécuter des tests d'intégration" -Description "Exécuter des tests d'intégration pour le système.")
    )
    
    # Mettre à jour les relations parent-enfant
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[3].Children = @("2.1", "2.2")
    
    # Ajouter des dépendances
    $tasks[3].Dependencies = @("1")  # La tâche 2 dépend de la tâche 1
    $tasks[4].Dependencies = @("1.1")  # La tâche 2.1 dépend de la tâche 1.1
    $tasks[5].Dependencies = @("1.2")  # La tâche 2.2 dépend de la tâche 1.2
    
    # Test 1: Attribuer des classifications à une hiérarchie de tâches
    Write-Host "  Test 1: Attribuer des classifications à une hiérarchie de tâches" -ForegroundColor Gray
    $result1 = New-TaskClassificationAssignment -Tasks $tasks.Clone()
    
    $allHaveClassification = $true
    foreach ($task in $result1) {
        if ($null -eq $task.Classification -or $task.Classification.Category -eq "Non classifié") {
            $allHaveClassification = $false
            break
        }
    }
    
    if ($allHaveClassification) {
        Write-Host "    Succès: Toutes les tâches ont une classification." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Classification.Category) / $($task.Classification.SubCategory) (Confiance: $($task.Classification.Confidence)%)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches n'ont pas de classification." -ForegroundColor Red
    }
    
    # Test 2: Vérifier la cohérence des classifications
    Write-Host "  Test 2: Vérifier la cohérence des classifications" -ForegroundColor Gray
    
    $parentChildConsistency = $true
    foreach ($task in $result1) {
        if ($task.ParentId) {
            $parent = $result1 | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1
            if ($parent -and $parent.Classification.Category -ne $task.Classification.Category -and -not $task.Classification.InheritedFromParent) {
                $parentChildConsistency = $false
                break
            }
        }
    }
    
    if ($parentChildConsistency) {
        Write-Host "    Succès: Les classifications sont cohérentes entre parents et enfants." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les classifications ne sont pas cohérentes entre parents et enfants." -ForegroundColor Red
    }
}

# Test pour la fonction Update-TaskClassificationHierarchy
function Test-TaskClassificationHierarchy {
    Write-Host "`nTest de la fonction Update-TaskClassificationHierarchy:" -ForegroundColor Yellow
    
    # Créer des tâches avec des classifications incohérentes
    $tasks = @(
        [PSCustomObject]@{
            Id = "1"
            Title = "Développer l'API"
            Description = "Implémenter l'API REST."
            ParentId = $null
            Children = @("1.1", "1.2")
            Dependencies = @()
            Classification = @{
                Category = "Développement"
                SubCategory = "API"
                Confidence = 80
            }
        },
        [PSCustomObject]@{
            Id = "1.1"
            Title = "Concevoir les endpoints"
            Description = "Concevoir les endpoints de l'API."
            ParentId = "1"
            Children = @()
            Dependencies = @()
            Classification = @{
                Category = "Planning"  # Incohérent avec le parent
                SubCategory = "Conception"
                Confidence = 40  # Confiance faible
            }
        },
        [PSCustomObject]@{
            Id = "1.2"
            Title = "Implémenter les contrôleurs"
            Description = "Développer les contrôleurs de l'API."
            ParentId = "1"
            Children = @()
            Dependencies = @()
            Classification = @{
                Category = "Développement"
                SubCategory = "Backend"
                Confidence = 75
            }
        },
        [PSCustomObject]@{
            Id = "2"
            Title = "Tester l'API"
            Description = "Écrire des tests pour l'API."
            ParentId = $null
            Children = @()
            Dependencies = @("1")
            Classification = @{
                Category = "Test"
                SubCategory = "Unitaire"
                Confidence = 30  # Confiance faible
            }
        }
    )
    
    # Test 1: Mettre à jour les classifications pour maintenir la cohérence hiérarchique
    Write-Host "  Test 1: Mettre à jour les classifications pour maintenir la cohérence hiérarchique" -ForegroundColor Gray
    
    Write-Host "    Classifications initiales:" -ForegroundColor Gray
    foreach ($task in $tasks) {
        Write-Host "      Tâche $($task.Id): $($task.Classification.Category) / $($task.Classification.SubCategory) (Confiance: $($task.Classification.Confidence)%)" -ForegroundColor Gray
    }
    
    $result1 = Update-TaskClassificationHierarchy -Tasks $tasks.Clone()
    
    Write-Host "    Classifications mises à jour:" -ForegroundColor Gray
    foreach ($task in $result1) {
        Write-Host "      Tâche $($task.Id): $($task.Classification.Category) / $($task.Classification.SubCategory) (Confiance: $($task.Classification.Confidence)%)" -ForegroundColor Gray
    }
    
    # Vérifier que la tâche 1.1 a hérité de la classification de son parent
    $task1_1 = $result1 | Where-Object { $_.Id -eq "1.1" } | Select-Object -First 1
    $inheritedFromParent = $task1_1.Classification.Category -eq "Développement" -and $task1_1.Classification.InheritedFromParent
    
    if ($inheritedFromParent) {
        Write-Host "    Succès: La tâche 1.1 a hérité de la classification de son parent." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche 1.1 n'a pas hérité de la classification de son parent." -ForegroundColor Red
    }
    
    # Vérifier que la tâche 2 a été influencée par sa dépendance
    $task2 = $result1 | Where-Object { $_.Id -eq "2" } | Select-Object -First 1
    $influencedByDependency = $task2.Classification.InheritedFromDependency
    
    if ($influencedByDependency) {
        Write-Host "    Succès: La tâche 2 a été influencée par sa dépendance." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La tâche 2 n'a pas été influencée par sa dépendance." -ForegroundColor Red
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan
