# Tests pour le mode ARCHI

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

# CrÃ©er un projet de test
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "TestProject_$(Get-Random)"
New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null

# CrÃ©er un rÃ©pertoire de sortie pour les tests
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

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
"@ | Out-File -FilePath $testFilePath -Encoding UTF8

# Tests unitaires avec Pester
Describe "Invoke-RoadmapArchitecture" {
    BeforeAll {
        # PrÃ©paration avant tous les tests
    }

    AfterAll {
        # Nettoyage aprÃ¨s tous les tests
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
        if (Test-Path -Path $testProjectPath) {
            Remove-Item -Path $testProjectPath -Recurse -Force
        }
        if (Test-Path -Path $testOutputPath) {
            Remove-Item -Path $testOutputPath -Recurse -Force
        }
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapArchitecture -FilePath $testFilePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer des diagrammes au format spÃ©cifiÃ©" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapArchitecture -FilePath $testFilePath -OutputPath $testOutputPath -DiagramFormat "PlantUML"
            $result | Should -Not -BeNullOrEmpty
            $result.DiagramPaths | Should -Not -BeNullOrEmpty
            $result.DiagramPaths.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les fichiers existent
            foreach ($diagramPath in $result.DiagramPaths) {
                Test-Path -Path $diagramPath | Should -Be $true
            }
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }

    It "Devrait inclure les dÃ©pendances si spÃ©cifiÃ©" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapArchitecture -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapArchitecture -FilePath $testFilePath -OutputPath $testOutputPath -IncludeDependencies
            $result | Should -Not -BeNullOrEmpty
            $result.DependencyCount | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapArchitecture n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script archi-mode.ps1
Describe "archi-mode.ps1 Integration" {
    BeforeAll {
        # PrÃ©paration avant tous les tests
    }

    AfterAll {
        # Nettoyage aprÃ¨s tous les tests
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
        if (Test-Path -Path $testProjectPath) {
            Remove-Item -Path $testProjectPath -Recurse -Force
        }
        if (Test-Path -Path $testOutputPath) {
            Remove-Item -Path $testOutputPath -Recurse -Force
        }
    }

    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" -Skip {
        if (Test-Path -Path $archiModePath) {
            # ExÃ©cuter le script
            $output = & $archiModePath -FilePath $testFilePath -OutputPath $testOutputPath -DiagramFormat "PlantUML"

            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
        } else {
            Set-ItResult -Skipped -Because "Le script archi-mode.ps1 n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer des diagrammes au format spÃ©cifiÃ©" -Skip {
        if (Test-Path -Path $archiModePath) {
            # ExÃ©cuter le script
            $output = & $archiModePath -FilePath $testFilePath -OutputPath $testOutputPath -DiagramFormat "PlantUML"

            # VÃ©rifier que les fichiers attendus existent
            $componentDiagramPath = Join-Path -Path $testOutputPath -ChildPath "component-diagram.plantuml"
            $dependencyDiagramPath = Join-Path -Path $testOutputPath -ChildPath "dependency-diagram.plantuml"
            
            Test-Path -Path $componentDiagramPath | Should -Be $true
            Test-Path -Path $dependencyDiagramPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script archi-mode.ps1 n'est pas disponible"
        }
    }
}
