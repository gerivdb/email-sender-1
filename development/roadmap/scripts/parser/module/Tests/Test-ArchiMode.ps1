<#
.SYNOPSIS
    Tests pour le script archi-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script archi-mode.ps1
    qui implÃ©mente le mode ARCHI (Architecture).

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
}

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent $modulePath
$archiModePath = Join-Path -Path $projectRoot -ChildPath "archi-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeArchiPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapArchitecture.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $archiModePath)) {
    Write-Warning "Le script archi-mode.ps1 est introuvable Ã  l'emplacement : $archiModePath"
}

if (-not (Test-Path -Path $invokeArchiPath)) {
    Write-Warning "Le fichier Invoke-RoadmapArchitecture.ps1 est introuvable Ã  l'emplacement : $invokeArchiPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeArchiPath) {
    . $invokeArchiPath
    Write-Host "Fonction Invoke-RoadmapArchitecture importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Conception de l'architecture du module
  - [ ] **1.1.1** DÃ©finir les composants principaux
  - [ ] **1.1.2** Ã‰tablir les interfaces entre composants
- [ ] **1.2** ImplÃ©mentation des composants
  - [ ] **1.2.1** DÃ©velopper le composant A
  - [ ] **1.2.2** DÃ©velopper le composant B

## Section 2

- [ ] **2.1** Tests d'intÃ©gration
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "TestProject_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure du projet de test
New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er quelques fichiers de code fictifs pour le projet
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

Write-Host "Projet de test crÃ©Ã© : $testProjectPath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapArchitecture" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
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

    It "Devrait lever une exception si l'identifiant de tÃ¢che est invalide" {
        # Appeler la fonction avec un identifiant de tÃ¢che invalide
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapArchitecture -FilePath $testFilePath -TaskIdentifier "9.9" -ProjectPath $testProjectPath -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }

    It "Devrait crÃ©er les diagrammes d'architecture attendus" {
        # Appeler la fonction et vÃ©rifier les fichiers de sortie
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapArchitecture -FilePath $testFilePath -TaskIdentifier "1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4"

            # VÃ©rifier que les fichiers attendus existent
            $expectedDiagram = Join-Path -Path $testOutputPath -ChildPath "architecture_diagram.md"
            Test-Path -Path $expectedDiagram | Should -Be $true

            # VÃ©rifier que le contenu du diagramme contient les composants
            $diagramContent = Get-Content -Path $expectedDiagram -Raw
            $diagramContent | Should -Match "Component A"
            $diagramContent | Should -Match "Component B"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script archi-mode.ps1
Describe "archi-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $archiModePath) {
            # ExÃ©cuter le script
            $output = & $archiModePath -FilePath $testFilePath -TaskIdentifier "1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4"

            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0

            # VÃ©rifier que les fichiers attendus existent
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
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testProjectPath) {
    Remove-Item -Path $testProjectPath -Recurse -Force
    Write-Host "Projet de test supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "RÃ©pertoire de sortie supprimÃ©." -ForegroundColor Gray
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}
