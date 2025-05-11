# Test-NormalizationRules.ps1
# Script de test pour vérifier l'implémentation des règles de normalisation
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'implémentation des règles de normalisation pour les tâches de roadmap.

.DESCRIPTION
    Ce script exécute une série de tests pour vérifier le bon fonctionnement des scripts
    TextNormalizationRules.ps1, StructuralNormalizationRules.ps1 et Normalize-Task.ps1.

.PARAMETER Verbose
    Affiche des informations détaillées sur les tests exécutés.

.EXAMPLE
    .\Test-NormalizationRules.ps1 -Verbose

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding()]
param()

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$textNormalizationRulesPath = Join-Path -Path $scriptPath -ChildPath "TextNormalizationRules.ps1"
$structuralNormalizationRulesPath = Join-Path -Path $scriptPath -ChildPath "StructuralNormalizationRules.ps1"
$normalizeTaskPath = Join-Path -Path $scriptPath -ChildPath "Normalize-Task.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $textNormalizationRulesPath)) {
    Write-Error "Le fichier TextNormalizationRules.ps1 est introuvable."
    exit 1
}

if (-not (Test-Path -Path $structuralNormalizationRulesPath)) {
    Write-Error "Le fichier StructuralNormalizationRules.ps1 est introuvable."
    exit 1
}

if (-not (Test-Path -Path $normalizeTaskPath)) {
    Write-Error "Le fichier Normalize-Task.ps1 est introuvable."
    exit 1
}

# Importer les scripts
. $textNormalizationRulesPath
. $structuralNormalizationRulesPath
. $normalizeTaskPath

# Fonction pour exécuter un test
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )
    
    Write-Verbose "Exécution du test: $Name"
    
    try {
        $result = & $Test
        
        if ($result) {
            Write-Host "[SUCCÈS] $Name" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[ÉCHEC] $Name" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERREUR] $Name : $_" -ForegroundColor Red
        return $false
    }
}

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Vérifier que les fonctions de TextNormalizationRules.ps1 sont disponibles
$totalTests++
$result = Invoke-Test -Name "Vérification des fonctions de TextNormalizationRules.ps1" -Test {
    $functions = @(
        "Normalize-Text",
        "Normalize-TextArray",
        "Normalize-TaskText"
    )
    
    $allFunctionsAvailable = $true
    
    foreach ($function in $functions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Verbose "Fonction non disponible: $function"
            $allFunctionsAvailable = $false
        }
    }
    
    return $allFunctionsAvailable
}
if ($result) { $passedTests++ }

# Test 2: Vérifier que les fonctions de StructuralNormalizationRules.ps1 sont disponibles
$totalTests++
$result = Invoke-Test -Name "Vérification des fonctions de StructuralNormalizationRules.ps1" -Test {
    $functions = @(
        "Normalize-Date",
        "Normalize-Duration",
        "Normalize-Reference",
        "Merge-Tasks",
        "Normalize-TaskStructure"
    )
    
    $allFunctionsAvailable = $true
    
    foreach ($function in $functions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Verbose "Fonction non disponible: $function"
            $allFunctionsAvailable = $false
        }
    }
    
    return $allFunctionsAvailable
}
if ($result) { $passedTests++ }

# Test 3: Vérifier que les fonctions de Normalize-Task.ps1 sont disponibles
$totalTests++
$result = Invoke-Test -Name "Vérification des fonctions de Normalize-Task.ps1" -Test {
    $functions = @(
        "Normalize-Task",
        "Normalize-TaskFile",
        "Normalize-TaskArray"
    )
    
    $allFunctionsAvailable = $true
    
    foreach ($function in $functions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Verbose "Fonction non disponible: $function"
            $allFunctionsAvailable = $false
        }
    }
    
    return $allFunctionsAvailable
}
if ($result) { $passedTests++ }

# Test 4: Vérifier la normalisation textuelle
$totalTests++
$result = Invoke-Test -Name "Normalisation textuelle" -Test {
    $testCases = @(
        @{
            Input = "  test  "
            FieldType = "Title"
            Expected = "Test"
        },
        @{
            Input = "test_title"
            FieldType = "Title"
            Expected = "Test Title"
        },
        @{
            Input = "1.2.3"
            FieldType = "Id"
            Expected = "1.2.3"
        },
        @{
            Input = "in progress"
            FieldType = "Status"
            Expected = "InProgress"
        },
        @{
            Input = "HIGH"
            FieldType = "Tag"
            Expected = "high"
        }
    )
    
    $allTestsPassed = $true
    
    foreach ($testCase in $testCases) {
        $result = Normalize-Text -Text $testCase.Input -FieldType $testCase.FieldType
        
        if ($result -ne $testCase.Expected) {
            Write-Verbose "Échec de la normalisation textuelle: '$($testCase.Input)' -> '$result' (attendu: '$($testCase.Expected)')"
            $allTestsPassed = $false
        }
    }
    
    return $allTestsPassed
}
if ($result) { $passedTests++ }

# Test 5: Vérifier la normalisation des dates
$totalTests++
$result = Invoke-Test -Name "Normalisation des dates" -Test {
    $testCases = @(
        @{
            Input = "2025-05-15"
            Expected = (Get-Date -Year 2025 -Month 5 -Day 15).ToUniversalTime().ToString("o")
        },
        @{
            Input = "2025-05-15T10:00:00"
            Expected = (Get-Date -Year 2025 -Month 5 -Day 15 -Hour 10 -Minute 0 -Second 0).ToUniversalTime().ToString("o")
        },
        @{
            Input = $null
            Expected = $null
        }
    )
    
    $allTestsPassed = $true
    
    foreach ($testCase in $testCases) {
        $result = Normalize-Date -Date $testCase.Input
        
        if ($result -ne $testCase.Expected) {
            Write-Verbose "Échec de la normalisation de date: '$($testCase.Input)' -> '$result' (attendu: '$($testCase.Expected)')"
            $allTestsPassed = $false
        }
    }
    
    return $allTestsPassed
}
if ($result) { $passedTests++ }

# Test 6: Vérifier la normalisation des durées
$totalTests++
$result = Invoke-Test -Name "Normalisation des durées" -Test {
    $testCases = @(
        @{
            Input = "2h"
            Expected = 2.0
        },
        @{
            Input = "1.5d"
            Expected = 12.0
        },
        @{
            Input = "30m"
            Expected = 0.5
        },
        @{
            Input = 2
            Expected = 2.0
        },
        @{
            Input = $null
            Expected = 0
        }
    )
    
    $allTestsPassed = $true
    
    foreach ($testCase in $testCases) {
        $result = Normalize-Duration -Duration $testCase.Input
        
        if ($result -ne $testCase.Expected) {
            Write-Verbose "Échec de la normalisation de durée: '$($testCase.Input)' -> '$result' (attendu: '$($testCase.Expected)')"
            $allTestsPassed = $false
        }
    }
    
    return $allTestsPassed
}
if ($result) { $passedTests++ }

# Test 7: Vérifier la normalisation des références
$totalTests++
$result = Invoke-Test -Name "Normalisation des références" -Test {
    $testCases = @(
        @{
            Input = "1.2.3"
            Type = "TaskId"
            Expected = "1.2.3"
        },
        @{
            Input = "Task 1.2.3"
            Type = "TaskId"
            Expected = "1.2.3"
        },
        @{
            Input = @("1.2.3", "4.5.6")
            Type = "TaskReference"
            Expected = @("1.2.3", "4.5.6")
        },
        @{
            Input = "1.2.3, 4.5.6"
            Type = "TaskReference"
            Expected = @("1.2.3", "4.5.6")
        }
    )
    
    $allTestsPassed = $true
    
    foreach ($testCase in $testCases) {
        $result = Normalize-Reference -Reference $testCase.Input -Type $testCase.Type
        
        if ($testCase.Type -eq "TaskId") {
            if ($result -ne $testCase.Expected) {
                Write-Verbose "Échec de la normalisation de référence: '$($testCase.Input)' -> '$result' (attendu: '$($testCase.Expected)')"
                $allTestsPassed = $false
            }
        }
        else {
            # Pour les tableaux, vérifier que tous les éléments attendus sont présents
            $allElementsPresent = $true
            
            foreach ($expected in $testCase.Expected) {
                if ($result -notcontains $expected) {
                    $allElementsPresent = $false
                    break
                }
            }
            
            # Vérifier que le nombre d'éléments est correct
            $correctCount = $result.Count -eq $testCase.Expected.Count
            
            if (-not $allElementsPresent -or -not $correctCount) {
                Write-Verbose "Échec de la normalisation de référence: '$($testCase.Input)' -> '$result' (attendu: '$($testCase.Expected)')"
                $allTestsPassed = $false
            }
        }
    }
    
    return $allTestsPassed
}
if ($result) { $passedTests++ }

# Test 8: Vérifier la fusion de tâches
$totalTests++
$result = Invoke-Test -Name "Fusion de tâches" -Test {
    $task1 = @{
        id = "1.2.3"
        title = "Tâche 1"
        status = "InProgress"
        tags = @("important", "urgent")
        createdAt = "2025-05-15T10:00:00Z"
        updatedAt = "2025-05-15T10:00:00Z"
    }
    
    $task2 = @{
        id = "1.2.3"
        title = "Tâche 2"
        description = "Description de la tâche"
        tags = @("urgent", "critique")
        createdAt = "2025-05-14T10:00:00Z"
        updatedAt = "2025-05-16T10:00:00Z"
    }
    
    $mergedTask = Merge-Tasks -Task1 $task1 -Task2 $task2 -PreferTask1
    
    $correctMerge = $true
    
    # Vérifier que les propriétés sont correctement fusionnées
    if ($mergedTask.id -ne "1.2.3") {
        Write-Verbose "ID incorrect: '$($mergedTask.id)'"
        $correctMerge = $false
    }
    
    if ($mergedTask.title -ne "Tâche 1") {
        Write-Verbose "Titre incorrect: '$($mergedTask.title)'"
        $correctMerge = $false
    }
    
    if ($mergedTask.description -ne "Description de la tâche") {
        Write-Verbose "Description incorrecte: '$($mergedTask.description)'"
        $correctMerge = $false
    }
    
    if ($mergedTask.status -ne "InProgress") {
        Write-Verbose "Statut incorrect: '$($mergedTask.status)'"
        $correctMerge = $false
    }
    
    # Vérifier que les tableaux sont correctement fusionnés
    $expectedTags = @("important", "urgent", "critique")
    $allTagsPresent = $true
    
    foreach ($tag in $expectedTags) {
        if ($mergedTask.tags -notcontains $tag) {
            Write-Verbose "Tag manquant: '$tag'"
            $allTagsPresent = $false
        }
    }
    
    if (-not $allTagsPresent -or $mergedTask.tags.Count -ne 3) {
        $correctMerge = $false
    }
    
    # Vérifier que les dates sont correctement fusionnées
    if ($mergedTask.createdAt -ne "2025-05-14T10:00:00Z") {
        Write-Verbose "Date de création incorrecte: '$($mergedTask.createdAt)'"
        $correctMerge = $false
    }
    
    if ($mergedTask.updatedAt -ne "2025-05-16T10:00:00Z") {
        Write-Verbose "Date de mise à jour incorrecte: '$($mergedTask.updatedAt)'"
        $correctMerge = $false
    }
    
    return $correctMerge
}
if ($result) { $passedTests++ }

# Test 9: Vérifier la normalisation complète d'une tâche
$totalTests++
$result = Invoke-Test -Name "Normalisation complète d'une tâche" -Test {
    $task = @{
        id = "Task 1.2.3"
        title = "  implémenter la validation de schéma  "
        status = "in progress"
        createdAt = "2025-05-15T10:00:00"
        updatedAt = "2025-05-15T10:00:00"
        estimatedHours = "2h"
        tags = @("important", "URGENT")
        dependencies = "1.1.1, 1.1.2"
    }
    
    $normalizedTask = Normalize-Task -Task $task
    
    $correctNormalization = $true
    
    # Vérifier que les champs sont correctement normalisés
    if ($normalizedTask.id -ne "1.2.3") {
        Write-Verbose "ID incorrect: '$($normalizedTask.id)'"
        $correctNormalization = $false
    }
    
    if ($normalizedTask.title -ne "Implémenter La Validation De Schéma") {
        Write-Verbose "Titre incorrect: '$($normalizedTask.title)'"
        $correctNormalization = $false
    }
    
    if ($normalizedTask.status -ne "InProgress") {
        Write-Verbose "Statut incorrect: '$($normalizedTask.status)'"
        $correctNormalization = $false
    }
    
    if ($normalizedTask.estimatedHours -ne 2.0) {
        Write-Verbose "Heures estimées incorrectes: '$($normalizedTask.estimatedHours)'"
        $correctNormalization = $false
    }
    
    # Vérifier que les tableaux sont correctement normalisés
    $expectedTags = @("important", "urgent")
    $allTagsPresent = $true
    
    foreach ($tag in $expectedTags) {
        if ($normalizedTask.tags -notcontains $tag) {
            Write-Verbose "Tag manquant: '$tag'"
            $allTagsPresent = $false
        }
    }
    
    if (-not $allTagsPresent -or $normalizedTask.tags.Count -ne 2) {
        $correctNormalization = $false
    }
    
    # Vérifier que les références sont correctement normalisées
    $expectedDependencies = @("1.1.1", "1.1.2")
    $allDependenciesPresent = $true
    
    foreach ($dependency in $expectedDependencies) {
        if ($normalizedTask.dependencies -notcontains $dependency) {
            Write-Verbose "Dépendance manquante: '$dependency'"
            $allDependenciesPresent = $false
        }
    }
    
    if (-not $allDependenciesPresent -or $normalizedTask.dependencies.Count -ne 2) {
        $correctNormalization = $false
    }
    
    return $correctNormalization
}
if ($result) { $passedTests++ }

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Tests exécutés: $totalTests" -ForegroundColor Cyan
Write-Host "Tests réussis: $passedTests" -ForegroundColor Cyan
Write-Host "Tests échoués: $($totalTests - $passedTests)" -ForegroundColor Cyan

# Retourner le résultat global
return $passedTests -eq $totalTests
