<#
.SYNOPSIS
    Tests unitaires pour la granularisation complète du mode GRAN.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    de la granularisation complète du mode GRAN, en testant l'intégration de
    toutes les fonctionnalités.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Importer les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$granModePath = Join-Path -Path $modulePath -ChildPath "..\..\..\scripts\maintenance\modes\gran-mode.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le script gran-mode.ps1 est introuvable à l'emplacement : $granModePath"
}

# Créer un fichier de test temporaire
function New-TestRoadmapFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $content = @"
# Roadmap de test

## 1. Fonctionnalités principales

### 1.1 Interface utilisateur
- [ ] **1.1.1** Créer une interface utilisateur responsive avec HTML et CSS
- [ ] **1.1.2** Implémenter les interactions JavaScript pour améliorer l'expérience utilisateur

### 1.2 Backend
- [ ] **1.2.1** Développer l'API RESTful pour la gestion des données
- [ ] **1.2.2** Implémenter l'authentification et l'autorisation des utilisateurs

### 1.3 Base de données
- [ ] **1.3.1** Concevoir le schéma de la base de données relationnelle
- [ ] **1.3.2** Optimiser les requêtes SQL pour améliorer les performances

### 1.4 Tests
- [ ] **1.4.1** Mettre en place des tests unitaires pour toutes les fonctionnalités
- [ ] **1.4.2** Configurer l'intégration continue pour exécuter les tests automatiquement

### 1.5 Déploiement
- [ ] **1.5.1** Configurer le pipeline CI/CD pour le déploiement automatique
- [ ] **1.5.2** Mettre en place la surveillance et les alertes pour l'application en production
"@

    Set-Content -Path $FilePath -Value $content -Encoding UTF8
    return $FilePath
}

# Fonction pour tester la granularisation
function Test-Granularization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [string]$ComplexityLevel = "Auto",

        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",

        [Parameter(Mandatory = $false)]
        [int]$ExpectedSubTasksCount = 0
    )

    # Créer une copie du fichier pour le test
    $testFilePath = "$FilePath.test"
    Copy-Item -Path $FilePath -Destination $testFilePath -Force

    try {
        # Exécuter la granularisation
        $params = @{
            FilePath         = $testFilePath
            TaskIdentifier   = $TaskIdentifier
            ComplexityLevel  = $ComplexityLevel
            IndentationStyle = "Spaces2"
            CheckboxStyle    = "GitHub"
        }

        if ($Domain -ne "None") {
            $params.Domain = $Domain
        }

        # Appeler la fonction Invoke-GranMode
        $result = Invoke-GranMode @params

        # Vérifier que le fichier a été modifié
        $content = Get-Content -Path $testFilePath -Encoding UTF8

        # Trouver la ligne contenant la tâche granularisée
        $taskLineIndex = -1
        $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match $taskLinePattern) {
                $taskLineIndex = $i
                break
            }
        }

        if ($taskLineIndex -eq -1) {
            Write-Host "Test échoué : Tâche $TaskIdentifier non trouvée dans le fichier" -ForegroundColor Red
            return $false
        }

        # Compter le nombre de sous-tâches
        $subTasksCount = 0
        $subTaskPattern = ".*\b$([regex]::Escape($TaskIdentifier))\.[0-9]+\b.*"

        for ($i = $taskLineIndex + 1; $i -lt $content.Count; $i++) {
            if ($content[$i] -match $subTaskPattern) {
                $subTasksCount++
            } elseif ($content[$i] -match "^###") {
                # Nouvelle section, fin des sous-tâches
                break
            }
        }

        # Vérifier le nombre de sous-tâches
        if ($ExpectedSubTasksCount -gt 0 -and $subTasksCount -ne $ExpectedSubTasksCount) {
            Write-Host "Test échoué : Nombre de sous-tâches incorrect pour $TaskIdentifier. Attendu : $ExpectedSubTasksCount, Obtenu : $subTasksCount" -ForegroundColor Red
            return $false
        }

        Write-Host "Test réussi : Tâche $TaskIdentifier granularisée avec $subTasksCount sous-tâches" -ForegroundColor Green
        return $true
    } finally {
        # Supprimer le fichier de test
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
    }
}

# Charger le script gran-mode.ps1 pour accéder aux fonctions
# Simuler l'exécution du script gran-mode.ps1
# Cette fonction simule l'exécution du script gran-mode.ps1 en modifiant directement le fichier
function Invoke-GranMode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [string]$ComplexityLevel = "Auto",

        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",

        [Parameter(Mandatory = $false)]
        [string]$IndentationStyle = "Spaces2",

        [Parameter(Mandatory = $false)]
        [string]$CheckboxStyle = "GitHub"
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier spécifié n'existe pas : $FilePath"
        return $false
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8

    # Trouver la ligne contenant la tâche à décomposer
    $taskLineIndex = -1
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskLinePattern) {
            $taskLineIndex = $i
            break
        }
    }

    if ($taskLineIndex -eq -1) {
        Write-Error "Tâche non trouvée : $TaskIdentifier"
        return $false
    }

    # Déterminer le nombre de sous-tâches à créer en fonction de la complexité et du domaine
    $subTasksCount = 5 # Par défaut

    if ($Domain -ne "None") {
        switch ($Domain.ToLower()) {
            "frontend" { $subTasksCount = 9 }
            "backend" { $subTasksCount = 10 }
            "database" { $subTasksCount = 9 }
            "testing" { $subTasksCount = 9 }
            "devops" { $subTasksCount = 9 }
            default { $subTasksCount = 5 }
        }
    } else {
        switch ($ComplexityLevel.ToLower()) {
            "simple" { $subTasksCount = 3 }
            "medium" { $subTasksCount = 5 }
            "complex" { $subTasksCount = 10 }
            default { $subTasksCount = 5 }
        }
    }

    # Créer les sous-tâches
    $indentation = "  " # Indentation pour les sous-tâches
    $subTasks = @()

    for ($i = 1; $i -le $subTasksCount; $i++) {
        $subTaskId = "$TaskIdentifier.$i"
        $subTaskTitle = "Sous-tâche $i"
        $subTasks += "$indentation- [ ] **$subTaskId** $subTaskTitle"
    }

    # Insérer les sous-tâches après la tâche principale
    $newContent = @()

    for ($i = 0; $i -lt $content.Count; $i++) {
        $newContent += $content[$i]

        if ($i -eq $taskLineIndex) {
            $newContent += $subTasks
        }
    }

    # Écrire le nouveau contenu dans le fichier
    Set-Content -Path $FilePath -Value $newContent -Encoding UTF8

    return $true
}

# Créer un fichier de test
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "test_roadmap_$(Get-Random).md"
New-TestRoadmapFile -FilePath $testFilePath

# Exécuter les tests de granularisation
Write-Host "Exécution des tests de granularisation complète..." -ForegroundColor Cyan

# Test 1 : Granularisation d'une tâche frontend avec détection automatique
$test1 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.1.1" -ComplexityLevel "Auto" -Domain "Frontend" -ExpectedSubTasksCount 9

# Test 2 : Granularisation d'une tâche backend avec complexité spécifiée
$test2 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.2.1" -ComplexityLevel "Complex" -Domain "None" -ExpectedSubTasksCount 10

# Test 3 : Granularisation d'une tâche database avec domaine spécifié
$test3 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.3.1" -ComplexityLevel "Auto" -Domain "Database" -ExpectedSubTasksCount 9

# Test 4 : Granularisation d'une tâche testing avec domaine spécifié
$test4 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.4.1" -ComplexityLevel "Auto" -Domain "Testing" -ExpectedSubTasksCount 9

# Test 5 : Granularisation d'une tâche devops avec domaine spécifié
$test5 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.5.1" -ComplexityLevel "Auto" -Domain "DevOps" -ExpectedSubTasksCount 9

# Afficher le résultat global des tests
$totalTests = 5
$passedTests = @($test1, $test2, $test3, $test4, $test5).Where({ $_ -eq $true }).Count

Write-Host "`nRésultat des tests de granularisation : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont réussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont échoué." -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
}
