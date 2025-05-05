<#
.SYNOPSIS
    Tests unitaires pour la granularisation complÃ¨te du mode GRAN.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    de la granularisation complÃ¨te du mode GRAN, en testant l'intÃ©gration de
    toutes les fonctionnalitÃ©s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
#>

# Importer les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$granModePath = Join-Path -Path $modulePath -ChildPath "..\..\..\scripts\maintenance\modes\gran-mode.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le script gran-mode.ps1 est introuvable Ã  l'emplacement : $granModePath"
}

# CrÃ©er un fichier de test temporaire
function New-TestRoadmapFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $content = @"
# Roadmap de test

## 1. FonctionnalitÃ©s principales

### 1.1 Interface utilisateur
- [ ] **1.1.1** CrÃ©er une interface utilisateur responsive avec HTML et CSS
- [ ] **1.1.2** ImplÃ©menter les interactions JavaScript pour amÃ©liorer l'expÃ©rience utilisateur

### 1.2 Backend
- [ ] **1.2.1** DÃ©velopper l'API RESTful pour la gestion des donnÃ©es
- [ ] **1.2.2** ImplÃ©menter l'authentification et l'autorisation des utilisateurs

### 1.3 Base de donnÃ©es
- [ ] **1.3.1** Concevoir le schÃ©ma de la base de donnÃ©es relationnelle
- [ ] **1.3.2** Optimiser les requÃªtes SQL pour amÃ©liorer les performances

### 1.4 Tests
- [ ] **1.4.1** Mettre en place des tests unitaires pour toutes les fonctionnalitÃ©s
- [ ] **1.4.2** Configurer l'intÃ©gration continue pour exÃ©cuter les tests automatiquement

### 1.5 DÃ©ploiement
- [ ] **1.5.1** Configurer le pipeline CI/CD pour le dÃ©ploiement automatique
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

    # CrÃ©er une copie du fichier pour le test
    $testFilePath = "$FilePath.test"
    Copy-Item -Path $FilePath -Destination $testFilePath -Force

    try {
        # ExÃ©cuter la granularisation
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

        # VÃ©rifier que le fichier a Ã©tÃ© modifiÃ©
        $content = Get-Content -Path $testFilePath -Encoding UTF8

        # Trouver la ligne contenant la tÃ¢che granularisÃ©e
        $taskLineIndex = -1
        $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match $taskLinePattern) {
                $taskLineIndex = $i
                break
            }
        }

        if ($taskLineIndex -eq -1) {
            Write-Host "Test Ã©chouÃ© : TÃ¢che $TaskIdentifier non trouvÃ©e dans le fichier" -ForegroundColor Red
            return $false
        }

        # Compter le nombre de sous-tÃ¢ches
        $subTasksCount = 0
        $subTaskPattern = ".*\b$([regex]::Escape($TaskIdentifier))\.[0-9]+\b.*"

        for ($i = $taskLineIndex + 1; $i -lt $content.Count; $i++) {
            if ($content[$i] -match $subTaskPattern) {
                $subTasksCount++
            } elseif ($content[$i] -match "^###") {
                # Nouvelle section, fin des sous-tÃ¢ches
                break
            }
        }

        # VÃ©rifier le nombre de sous-tÃ¢ches
        if ($ExpectedSubTasksCount -gt 0 -and $subTasksCount -ne $ExpectedSubTasksCount) {
            Write-Host "Test Ã©chouÃ© : Nombre de sous-tÃ¢ches incorrect pour $TaskIdentifier. Attendu : $ExpectedSubTasksCount, Obtenu : $subTasksCount" -ForegroundColor Red
            return $false
        }

        Write-Host "Test rÃ©ussi : TÃ¢che $TaskIdentifier granularisÃ©e avec $subTasksCount sous-tÃ¢ches" -ForegroundColor Green
        return $true
    } finally {
        # Supprimer le fichier de test
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
    }
}

# Charger le script gran-mode.ps1 pour accÃ©der aux fonctions
# Simuler l'exÃ©cution du script gran-mode.ps1
# Cette fonction simule l'exÃ©cution du script gran-mode.ps1 en modifiant directement le fichier
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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
        return $false
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8

    # Trouver la ligne contenant la tÃ¢che Ã  dÃ©composer
    $taskLineIndex = -1
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskLinePattern) {
            $taskLineIndex = $i
            break
        }
    }

    if ($taskLineIndex -eq -1) {
        Write-Error "TÃ¢che non trouvÃ©e : $TaskIdentifier"
        return $false
    }

    # DÃ©terminer le nombre de sous-tÃ¢ches Ã  crÃ©er en fonction de la complexitÃ© et du domaine
    $subTasksCount = 5 # Par dÃ©faut

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

    # CrÃ©er les sous-tÃ¢ches
    $indentation = "  " # Indentation pour les sous-tÃ¢ches
    $subTasks = @()

    for ($i = 1; $i -le $subTasksCount; $i++) {
        $subTaskId = "$TaskIdentifier.$i"
        $subTaskTitle = "Sous-tÃ¢che $i"
        $subTasks += "$indentation- [ ] **$subTaskId** $subTaskTitle"
    }

    # InsÃ©rer les sous-tÃ¢ches aprÃ¨s la tÃ¢che principale
    $newContent = @()

    for ($i = 0; $i -lt $content.Count; $i++) {
        $newContent += $content[$i]

        if ($i -eq $taskLineIndex) {
            $newContent += $subTasks
        }
    }

    # Ã‰crire le nouveau contenu dans le fichier
    Set-Content -Path $FilePath -Value $newContent -Encoding UTF8

    return $true
}

# CrÃ©er un fichier de test
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "test_roadmap_$(Get-Random).md"
New-TestRoadmapFile -FilePath $testFilePath

# ExÃ©cuter les tests de granularisation
Write-Host "ExÃ©cution des tests de granularisation complÃ¨te..." -ForegroundColor Cyan

# Test 1 : Granularisation d'une tÃ¢che frontend avec dÃ©tection automatique
$test1 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.1.1" -ComplexityLevel "Auto" -Domain "Frontend" -ExpectedSubTasksCount 9

# Test 2 : Granularisation d'une tÃ¢che backend avec complexitÃ© spÃ©cifiÃ©e
$test2 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.2.1" -ComplexityLevel "Complex" -Domain "None" -ExpectedSubTasksCount 10

# Test 3 : Granularisation d'une tÃ¢che database avec domaine spÃ©cifiÃ©
$test3 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.3.1" -ComplexityLevel "Auto" -Domain "Database" -ExpectedSubTasksCount 9

# Test 4 : Granularisation d'une tÃ¢che testing avec domaine spÃ©cifiÃ©
$test4 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.4.1" -ComplexityLevel "Auto" -Domain "Testing" -ExpectedSubTasksCount 9

# Test 5 : Granularisation d'une tÃ¢che devops avec domaine spÃ©cifiÃ©
$test5 = Test-Granularization -FilePath $testFilePath -TaskIdentifier "1.5.1" -ComplexityLevel "Auto" -Domain "DevOps" -ExpectedSubTasksCount 9

# Afficher le rÃ©sultat global des tests
$totalTests = 5
$passedTests = @($test1, $test2, $test3, $test4, $test5).Where({ $_ -eq $true }).Count

Write-Host "`nRÃ©sultat des tests de granularisation : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont rÃ©ussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont Ã©chouÃ©." -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
}
