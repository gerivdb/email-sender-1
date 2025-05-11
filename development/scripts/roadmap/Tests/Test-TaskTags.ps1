# Test-TaskTags.ps1
# Script de test pour les fonctions de génération de tags thématiques
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskTags.ps1"
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
        [string]$Category = $null,

        [Parameter(Mandatory = $false)]
        [string]$ParentId = $null,

        [Parameter(Mandatory = $false)]
        [string[]]$Children = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @()
    )

    return [PSCustomObject]@{
        Id           = $Id
        Title        = $Title
        Description  = $Description
        Category     = $Category
        ParentId     = $ParentId
        Children     = $Children
        Dependencies = $Dependencies
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de génération de tags thématiques..." -ForegroundColor Cyan

    Test-TaskThematicTags
    Test-TaskTagAssignment
    Test-TaskTagsHierarchy

    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction Get-TaskThematicTags
function Test-TaskThematicTags {
    Write-Host "`nTest de la fonction Get-TaskThematicTags:" -ForegroundColor Yellow

    # Test 1: Générer des tags thématiques pour une tâche de développement
    Write-Host "  Test 1: Générer des tags thématiques pour une tâche de développement" -ForegroundColor Gray
    $task1 = New-TestTask -Id "1" -Title "Implémenter l'API REST" -Description "Développer les endpoints de l'API REST pour l'authentification et la gestion des utilisateurs." -Category "Développement"

    $result1 = Get-TaskThematicTags -Task $task1 -RandomSeed 12345

    Write-Host "    Tags générés: $($result1 -join ', ')" -ForegroundColor Gray

    $hasDevTags = $result1 -contains "api" -or $result1 -contains "développement" -or $result1 -contains "rest" -or $result1 -contains "authentification"

    if ($hasDevTags) {
        Write-Host "    Succès: Les tags générés sont pertinents pour une tâche de développement." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les tags générés ne sont pas pertinents pour une tâche de développement." -ForegroundColor Red
    }

    # Test 2: Générer des tags thématiques pour une tâche de test
    Write-Host "  Test 2: Générer des tags thématiques pour une tâche de test" -ForegroundColor Gray
    $task2 = New-TestTask -Id "2" -Title "Écrire des tests unitaires" -Description "Développer des tests unitaires pour les fonctionnalités de l'API REST." -Category "Test"

    $result2 = Get-TaskThematicTags -Task $task2 -RandomSeed 12345

    Write-Host "    Tags générés: $($result2 -join ', ')" -ForegroundColor Gray

    $hasTestTags = $result2 -contains "test" -or $result2 -contains "unitaires" -or $result2 -contains "api"

    if ($hasTestTags) {
        Write-Host "    Succès: Les tags générés sont pertinents pour une tâche de test." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les tags générés ne sont pas pertinents pour une tâche de test." -ForegroundColor Red
    }

    # Test 3: Générer des tags thématiques pour une tâche de documentation
    Write-Host "  Test 3: Générer des tags thématiques pour une tâche de documentation" -ForegroundColor Gray
    $task3 = New-TestTask -Id "3" -Title "Rédiger la documentation de l'API" -Description "Créer la documentation technique pour l'API REST." -Category "Documentation"

    $result3 = Get-TaskThematicTags -Task $task3 -RandomSeed 12345

    Write-Host "    Tags générés: $($result3 -join ', ')" -ForegroundColor Gray

    $hasDocTags = $result3 -contains "documentation" -or $result3 -contains "api" -or $result3 -contains "technique"

    if ($hasDocTags) {
        Write-Host "    Succès: Les tags générés sont pertinents pour une tâche de documentation." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les tags générés ne sont pas pertinents pour une tâche de documentation." -ForegroundColor Red
    }

    # Test 4: Vérifier la cohérence des tags générés
    Write-Host "  Test 4: Vérifier la cohérence des tags générés" -ForegroundColor Gray

    $result1a = Get-TaskThematicTags -Task $task1 -RandomSeed 12345
    $result1b = Get-TaskThematicTags -Task $task1 -RandomSeed 12345

    $tagsMatch = $true
    if ($result1a.Count -ne $result1b.Count) {
        $tagsMatch = $false
    } else {
        for ($i = 0; $i -lt $result1a.Count; $i++) {
            if ($result1a[$i] -ne $result1b[$i]) {
                $tagsMatch = $false
                break
            }
        }
    }

    if ($tagsMatch) {
        Write-Host "    Succès: Les tags générés sont cohérents avec la même graine aléatoire." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les tags générés ne sont pas cohérents avec la même graine aléatoire." -ForegroundColor Red
    }
}

# Test pour la fonction New-TaskTagAssignment
function Test-TaskTagAssignment {
    Write-Host "`nTest de la fonction New-TaskTagAssignment:" -ForegroundColor Yellow

    # Créer une hiérarchie de tâches
    $tasks = @(
        (New-TestTask -Id "1" -Title "Développer le système d'authentification" -Description "Implémenter le système d'authentification et d'autorisation." -Category "Développement"),
        (New-TestTask -Id "1.1" -ParentId "1" -Title "Implémenter l'authentification OAuth" -Description "Développer le support pour OAuth 2.0." -Category "Développement"),
        (New-TestTask -Id "1.2" -ParentId "1" -Title "Ajouter l'authentification à deux facteurs" -Description "Implémenter l'authentification à deux facteurs (2FA)." -Category "Sécurité"),
        (New-TestTask -Id "2" -Title "Tester le système" -Description "Écrire et exécuter des tests pour le système." -Category "Test"),
        (New-TestTask -Id "2.1" -ParentId "2" -Title "Écrire des tests unitaires" -Description "Développer des tests unitaires pour les fonctionnalités." -Category "Test"),
        (New-TestTask -Id "2.2" -ParentId "2" -Title "Exécuter des tests d'intégration" -Description "Exécuter des tests d'intégration pour le système." -Category "Test")
    )

    # Mettre à jour les relations parent-enfant
    $tasks[0].Children = @("1.1", "1.2")
    $tasks[3].Children = @("2.1", "2.2")

    # Ajouter des dépendances
    $tasks[3].Dependencies = @("1")  # La tâche 2 dépend de la tâche 1
    $tasks[4].Dependencies = @("1.1")  # La tâche 2.1 dépend de la tâche 1.1
    $tasks[5].Dependencies = @("1.2")  # La tâche 2.2 dépend de la tâche 1.2

    # Test 1: Attribuer des tags thématiques à une hiérarchie de tâches
    Write-Host "  Test 1: Attribuer des tags thématiques à une hiérarchie de tâches" -ForegroundColor Gray
    $result1 = New-TaskTagAssignment -Tasks $tasks.Clone() -RandomSeed 12345

    $allHaveTags = $true
    foreach ($task in $result1) {
        if ($null -eq $task.Tags -or $task.Tags.Count -eq 0) {
            $allHaveTags = $false
            break
        }
    }

    if ($allHaveTags) {
        Write-Host "    Succès: Toutes les tâches ont des tags." -ForegroundColor Green
        foreach ($task in $result1) {
            Write-Host "      Tâche $($task.Id): $($task.Tags -join ', ')" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Échec: Certaines tâches n'ont pas de tags." -ForegroundColor Red
    }

    # Test 2: Vérifier que les tâches enfants héritent des tags de leur parent
    Write-Host "  Test 2: Vérifier que les tâches enfants héritent des tags de leur parent" -ForegroundColor Gray

    $inheritanceCorrect = $true
    foreach ($task in $result1) {
        if ($task.ParentId) {
            $parent = $result1 | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1
            $hasInheritedTags = $false

            foreach ($parentTag in $parent.Tags) {
                if ($task.Tags -contains $parentTag) {
                    $hasInheritedTags = $true
                    break
                }
            }

            if (-not $hasInheritedTags) {
                $inheritanceCorrect = $false
                break
            }
        }
    }

    if ($inheritanceCorrect) {
        Write-Host "    Succès: Les tâches enfants héritent correctement des tags de leur parent." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certaines tâches enfants n'héritent pas des tags de leur parent." -ForegroundColor Red
    }
}

# Test pour la fonction Update-TaskTagsHierarchy
function Test-TaskTagsHierarchy {
    Write-Host "`nTest de la fonction Update-TaskTagsHierarchy:" -ForegroundColor Yellow

    # Créer des tâches avec des dépendances
    $tasks = @(
        [PSCustomObject]@{
            Id           = "1"
            Title        = "Développer l'API"
            Description  = "Implémenter l'API REST."
            Category     = "Développement"
            Dependencies = @()
            Tags         = @("api", "développement", "rest")
        },
        [PSCustomObject]@{
            Id           = "2"
            Title        = "Tester l'API"
            Description  = "Écrire des tests pour l'API."
            Category     = "Test"
            Dependencies = @("1")
            Tags         = @("test", "unitaire")
        },
        [PSCustomObject]@{
            Id           = "3"
            Title        = "Documenter l'API"
            Description  = "Créer la documentation de l'API."
            Category     = "Documentation"
            Dependencies = @("1")
            Tags         = @("documentation")
        }
    )

    # Test 1: Mettre à jour les tags en fonction des dépendances
    Write-Host "  Test 1: Mettre à jour les tags en fonction des dépendances" -ForegroundColor Gray
    $result1 = Update-TaskTagsHierarchy -Tasks $tasks.Clone()

    Write-Host "    Tags initiaux de la tâche 1: $($tasks[0].Tags -join ', ')" -ForegroundColor Gray
    Write-Host "    Tags initiaux de la tâche 2: $($tasks[1].Tags -join ', ')" -ForegroundColor Gray
    Write-Host "    Tags initiaux de la tâche 3: $($tasks[2].Tags -join ', ')" -ForegroundColor Gray

    Write-Host "    Tags mis à jour de la tâche 1: $($result1[0].Tags -join ', ')" -ForegroundColor Gray
    Write-Host "    Tags mis à jour de la tâche 2: $($result1[1].Tags -join ', ')" -ForegroundColor Gray
    Write-Host "    Tags mis à jour de la tâche 3: $($result1[2].Tags -join ', ')" -ForegroundColor Gray

    $dependencyTagsCorrect = $true
    foreach ($task in $result1) {
        if ($task.Dependencies -and $task.Dependencies.Count -gt 0) {
            foreach ($depId in $task.Dependencies) {
                $dependency = $result1 | Where-Object { $_.Id -eq $depId } | Select-Object -First 1
                $hasSharedTags = $false

                foreach ($depTag in $dependency.Tags) {
                    if ($task.Tags -contains $depTag) {
                        $hasSharedTags = $true
                        break
                    }
                }

                if (-not $hasSharedTags) {
                    $dependencyTagsCorrect = $false
                    break
                }
            }
        }
    }

    if ($dependencyTagsCorrect) {
        Write-Host "    Succès: Les tâches partagent correctement des tags avec leurs dépendances." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Certaines tâches ne partagent pas de tags avec leurs dépendances." -ForegroundColor Red
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan
