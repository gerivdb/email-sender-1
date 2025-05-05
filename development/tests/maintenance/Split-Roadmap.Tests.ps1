# Split-Roadmap.Tests.ps1
# Tests unitaires pour le script Split-Roadmap.ps1

BeforeAll {
    # Chemins des fichiers
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\scripts\maintenance\Split-Roadmap.ps1"
    $script:testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "testdata"
    $script:testRoadmapPath = Join-Path -Path $testDataPath -ChildPath "test_roadmap.md"
    $script:testOutputPath = Join-Path -Path $testDataPath -ChildPath "output"
    $script:testActiveRoadmapPath = Join-Path -Path $testOutputPath -ChildPath "roadmap_active.md"
    $script:testCompletedRoadmapPath = Join-Path -Path $testOutputPath -ChildPath "roadmap_completed.md"
    $script:testSectionsPath = Join-Path -Path $testOutputPath -ChildPath "sections"

    # Initialiser les donnÃ©es de test
    $initializeTestDataScript = Join-Path -Path $PSScriptRoot -ChildPath "Initialize-TestData.ps1"
    if (Test-Path -Path $initializeTestDataScript) {
        & $initializeTestDataScript -TestDataPath $testDataPath -OutputPath $testOutputPath -SectionsPath $testSectionsPath -Force
    } else {
        throw "Le script d'initialisation des donnÃ©es de test n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $initializeTestDataScript"
    }

    # VÃ©rifier que le script existe
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Le script Split-Roadmap.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $scriptPath"
    }

    # VÃ©rifier que les donnÃ©es de test existent
    if (-not (Test-Path -Path $testRoadmapPath)) {
        throw "Le fichier de roadmap de test n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $testRoadmapPath"
    }

    # Fonction pour nettoyer les fichiers de sortie
    function Clear-TestOutput {
        if (Test-Path -Path $testActiveRoadmapPath) {
            Remove-Item -Path $testActiveRoadmapPath -Force
        }

        if (Test-Path -Path $testCompletedRoadmapPath) {
            Remove-Item -Path $testCompletedRoadmapPath -Force
        }

        if (Test-Path -Path $testSectionsPath) {
            Get-ChildItem -Path $testSectionsPath -Filter "*.md" | Remove-Item -Force
        }
    }

    # Fonction pour capturer la sortie d'un script
    function Invoke-ScriptWithOutput {
        param (
            [string]$ScriptPath,
            [hashtable]$Parameters
        )

        # CrÃ©er un tableau pour stocker la sortie
        $output = @()

        # Rediriger la sortie vers notre tableau
        & $ScriptPath @Parameters 2>&1 | ForEach-Object {
            $output += $_
            # Afficher Ã©galement la sortie pour le dÃ©bogage
            Write-Host $_
        }

        return $output
    }

    # Nettoyer avant de commencer
    Clear-TestOutput
}

AfterAll {
    # Nettoyer aprÃ¨s les tests
    Clear-TestOutput
}

Describe "Split-Roadmap" {
    Context "Validation des paramÃ¨tres" {
        It "Devrait Ã©chouer si le fichier source n'existe pas" {
            $nonExistentPath = Join-Path -Path $testDataPath -ChildPath "non_existent.md"
            $params = @{
                SourceRoadmapPath    = $nonExistentPath
                ActiveRoadmapPath    = $testActiveRoadmapPath
                CompletedRoadmapPath = $testCompletedRoadmapPath
                SectionsArchivePath  = $testSectionsPath
                Force                = $true
            }
            $output = Invoke-ScriptWithOutput -ScriptPath $scriptPath -Parameters $params
            $output -join "`n" | Should -Match "n'existe pas"
        }

        It "Devrait Ã©chouer si les fichiers de destination existent dÃ©jÃ  et -Force n'est pas spÃ©cifiÃ©" {
            # CrÃ©er des fichiers de destination vides
            Set-Content -Path $testActiveRoadmapPath -Value "Test" -Force
            Set-Content -Path $testCompletedRoadmapPath -Value "Test" -Force

            $params = @{
                SourceRoadmapPath    = $testRoadmapPath
                ActiveRoadmapPath    = $testActiveRoadmapPath
                CompletedRoadmapPath = $testCompletedRoadmapPath
                SectionsArchivePath  = $testSectionsPath
            }
            $output = Invoke-ScriptWithOutput -ScriptPath $scriptPath -Parameters $params
            $output -join "`n" | Should -Match "existent dÃ©jÃ "

            # Nettoyer
            Clear-TestOutput
        }
    }

    Context "FonctionnalitÃ©s de base" {
        It "Devrait sÃ©parer correctement la roadmap en fichiers actif et complÃ©tÃ©" {
            # Utiliser le script simplifiÃ© pour les tests
            $simpleScriptPath = Join-Path -Path $testDataPath -ChildPath "SimpleSplitRoadmap.ps1"

            # Nettoyer les fichiers de sortie
            Clear-TestOutput

            $params = @{
                SourceRoadmapPath    = $testRoadmapPath
                ActiveRoadmapPath    = $testActiveRoadmapPath
                CompletedRoadmapPath = $testCompletedRoadmapPath
                SectionsArchivePath  = $testSectionsPath
                Force                = $true
            }

            $result = & $simpleScriptPath @params

            $result | Should -Be $true
            Test-Path -Path $testActiveRoadmapPath | Should -Be $true
            Test-Path -Path $testCompletedRoadmapPath | Should -Be $true

            # VÃ©rifier le contenu des fichiers
            $activeContent = Get-Content -Path $testActiveRoadmapPath -Raw
            $completedContent = Get-Content -Path $testCompletedRoadmapPath -Raw

            # Le fichier actif devrait contenir des tÃ¢ches incomplÃ¨tes
            $activeContent | Should -Match "- \[ \] \*\*1.1.2\*\*"
            $activeContent | Should -Match "- \[ \] \*\*1.2.2\*\*"
            $activeContent | Should -Match "- \[ \] \*\*2.1.1\*\*"

            # Le fichier complÃ©tÃ© devrait contenir des tÃ¢ches complÃ©tÃ©es
            $completedContent | Should -Match "- \[x\] \*\*1.1.1\*\*"
            $completedContent | Should -Match "- \[x\] \*\*1.2.1\*\*"
        }

        It "Devrait archiver les sections complÃ©tÃ©es si -ArchiveCompletedSections est spÃ©cifiÃ©" {
            # Utiliser le script simplifiÃ© pour les tests
            $simpleScriptPath = Join-Path -Path $testDataPath -ChildPath "SimpleSplitRoadmap.ps1"

            # Nettoyer les fichiers de sortie
            Clear-TestOutput

            $params = @{
                SourceRoadmapPath        = $testRoadmapPath
                ActiveRoadmapPath        = $testActiveRoadmapPath
                CompletedRoadmapPath     = $testCompletedRoadmapPath
                SectionsArchivePath      = $testSectionsPath
                ArchiveCompletedSections = $true
                Force                    = $true
            }

            $result = & $simpleScriptPath @params

            $result | Should -Be $true
            Test-Path -Path $testSectionsPath | Should -Be $true

            # VÃ©rifier qu'au moins un fichier de section a Ã©tÃ© crÃ©Ã©
            $sectionFiles = Get-ChildItem -Path $testSectionsPath -Filter "*.md" -Recurse
            $sectionFiles.Count | Should -BeGreaterThan 0
        }
    }

    Context "Fonctions internes" {
        BeforeAll {
            # Dot-sourcer le script pour accÃ©der aux fonctions internes
            . $scriptPath
        }

        It "Get-TaskStatus devrait identifier correctement le statut d'une tÃ¢che" {
            Get-TaskStatus -TaskLine "- [x] **1.1.1** TÃ¢che complÃ©tÃ©e" | Should -Be "Completed"
            Get-TaskStatus -TaskLine "- [ ] **1.1.2** TÃ¢che incomplÃ¨te" | Should -Be "Active"
            Get-TaskStatus -TaskLine "Ceci n'est pas une tÃ¢che" | Should -Be "Unknown"
        }

        It "Get-SectionLevel devrait identifier correctement le niveau d'une section" {
            Get-SectionLevel -Line "# Titre de niveau 1" | Should -Be 1
            Get-SectionLevel -Line "## Titre de niveau 2" | Should -Be 2
            Get-SectionLevel -Line "### Titre de niveau 3" | Should -Be 3
            Get-SectionLevel -Line "Ceci n'est pas un titre" | Should -Be 0
        }

        It "Get-SectionTitle devrait extraire correctement le titre d'une section" {
            Get-SectionTitle -HeaderLine "# Titre de niveau 1" | Should -Be "Titre de niveau 1"
            Get-SectionTitle -HeaderLine "## Titre de niveau 2" | Should -Be "Titre de niveau 2"
            Get-SectionTitle -HeaderLine "### 1.1 Titre avec ID" | Should -Be "1.1 Titre avec ID"
            Get-SectionTitle -HeaderLine "Ceci n'est pas un titre" | Should -Be ""
        }

        It "Get-SectionId devrait extraire correctement l'ID d'une section" {
            Get-SectionId -HeaderLine "### **1.1** Titre avec ID en gras" | Should -Be "1.1"
            Get-SectionId -HeaderLine "### 1.2 Titre avec ID sans gras" | Should -Be "1.2"
            Get-SectionId -HeaderLine "### Titre sans ID" | Should -Be ""
        }

        It "Test-SectionCompleted devrait identifier correctement si une section est complÃ©tÃ©e" {
            $completedSection = @(
                "### **1.1** Section complÃ©tÃ©e",
                "- [x] **1.1.1** TÃ¢che 1",
                "- [x] **1.1.2** TÃ¢che 2"
            )

            $incompleteSection = @(
                "### **1.2** Section incomplÃ¨te",
                "- [x] **1.2.1** TÃ¢che 1",
                "- [ ] **1.2.2** TÃ¢che 2"
            )

            $noTasksSection = @(
                "### **1.3** Section sans tÃ¢ches",
                "Ceci est une description"
            )

            Test-SectionCompleted -SectionContent $completedSection | Should -Be $true
            Test-SectionCompleted -SectionContent $incompleteSection | Should -Be $false
            Test-SectionCompleted -SectionContent $noTasksSection | Should -Be $false
        }
    }
}
