<#
.SYNOPSIS
    Tests pour le script archi-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script archi-mode.ps1
    qui implémente le mode ARCHI (Architecture).

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
}

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent $modulePath
$archiModePath = Join-Path -Path $projectRoot -ChildPath "archi-mode.ps1"

# Chemin vers les fonctions à tester
$invokeArchiPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapArchitecture.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $archiModePath)) {
    Write-Warning "Le script archi-mode.ps1 est introuvable à l'emplacement : $archiModePath"
}

if (-not (Test-Path -Path $invokeArchiPath)) {
    Write-Warning "Le fichier Invoke-RoadmapArchitecture.ps1 est introuvable à l'emplacement : $invokeArchiPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeArchiPath) {
    . $invokeArchiPath
    Write-Host "Fonction Invoke-RoadmapArchitecture importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Conception de l'architecture du module
  - [ ] **1.1.1** Définir les composants principaux
  - [ ] **1.1.2** Établir les interfaces entre composants
- [ ] **1.2** Implémentation des composants
  - [ ] **1.2.1** Développer le composant A
  - [ ] **1.2.2** Développer le composant B

## Section 2

- [ ] **2.1** Tests d'intégration
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "TestProject_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# Créer la structure du projet de test
New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer quelques fichiers de code fictifs pour le projet
@"
function Get-Component {
    param (
        [string]`$Name
    )

    return "Component `$Name"
}
"@ | Set-Content -Path (Join-Path -Path $testProjectPath -ChildPath "Component.ps1") -Encoding UTF8

@"
function Invoke-ComponentA {
    param (
        [string]`$Input
    )

    return "Processing `$Input with Component A"
}
"@ | Set-Content -Path (Join-Path -Path $testProjectPath -ChildPath "ComponentA.ps1") -Encoding UTF8

@"
function Invoke-ComponentB {
    param (
        [string]`$Input
    )

    return "Processing `$Input with Component B"
}
"@ | Set-Content -Path (Join-Path -Path $testProjectPath -ChildPath "ComponentB.ps1") -Encoding UTF8

Write-Host "Projet de test créé : $testProjectPath" -ForegroundColor Green
Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapArchitecture" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapArchitecture -FilePath $testFilePath -TaskIdentifier "1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapArchitecture -FilePath "FichierInexistant.md" -TaskIdentifier "1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }

    It "Devrait lever une exception si l'identifiant de tâche est invalide" {
        # Appeler la fonction avec un identifiant de tâche invalide
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapArchitecture -FilePath $testFilePath -TaskIdentifier "9.9" -ProjectPath $testProjectPath -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }

    It "Devrait créer les diagrammes d'architecture attendus" {
        # Appeler la fonction et vérifier les fichiers de sortie
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapArchitecture -FilePath $testFilePath -TaskIdentifier "1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4"

            # Vérifier que les fichiers attendus existent
            $expectedDiagram = Join-Path -Path $testOutputPath -ChildPath "architecture_diagram.md"
            Test-Path -Path $expectedDiagram | Should -Be $true

            # Vérifier que le contenu du diagramme contient les composants
            $diagramContent = Get-Content -Path $expectedDiagram -Raw
            $diagramContent | Should -Match "Component A"
            $diagramContent | Should -Match "Component B"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }
}

# Test d'intégration du script archi-mode.ps1
Describe "archi-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $archiModePath) {
            # Exécuter le script
            $output = & $archiModePath -FilePath $testFilePath -TaskIdentifier "1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4"

            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0

            # Vérifier que les fichiers attendus existent
            $expectedDiagram = Join-Path -Path $testOutputPath -ChildPath "architecture_diagram.md"
            Test-Path -Path $expectedDiagram | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script archi-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testProjectPath) {
    Remove-Item -Path $testProjectPath -Recurse -Force
    Write-Host "Projet de test supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
