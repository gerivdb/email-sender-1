# Navigate-Roadmap.Tests.ps1
# Tests unitaires pour le script Navigate-Roadmap.ps1

BeforeAll {
    # Chemins des fichiers
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\scripts\maintenance\Navigate-Roadmap.ps1"
    $script:testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "testdata"
    $script:testOutputPath = Join-Path -Path $testDataPath -ChildPath "output"
    $script:testActiveRoadmapPath = Join-Path -Path $testOutputPath -ChildPath "roadmap_active.md"
    $script:testCompletedRoadmapPath = Join-Path -Path $testOutputPath -ChildPath "roadmap_completed.md"
    $script:testSectionsPath = Join-Path -Path $testOutputPath -ChildPath "sections"

    # CrÃ©er le dossier de sortie pour les tests
    if (-not (Test-Path -Path $testOutputPath)) {
        New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er le dossier des sections archivÃ©es
    if (-not (Test-Path -Path $testSectionsPath)) {
        New-Item -Path $testSectionsPath -ItemType Directory -Force | Out-Null
    }

    # VÃ©rifier que le script existe
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Le script Navigate-Roadmap.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $scriptPath"
    }

    # Fonction pour crÃ©er des fichiers de roadmap de test
    function Initialize-TestRoadmaps {
        # CrÃ©er un fichier de roadmap active de test
        $activeContent = @"
# Roadmap Active - EMAIL_SENDER_1

Ce fichier contient les tÃ¢ches actives et Ã  venir de la roadmap.
GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: FonctionnalitÃ©s de base

### 1.1 ImplÃ©mentation des composants essentiels
- [ ] **1.1.2** DÃ©velopper les fonctionnalitÃ©s principales
  - [x] **1.1.2.1** ImplÃ©menter la gestion des utilisateurs
  - [ ] **1.1.2.2** DÃ©velopper le systÃ¨me de notifications
  - [ ] **1.1.2.3** CrÃ©er l'interface utilisateur

### 1.2 Tests et validation
- [ ] **1.2.2** Effectuer les tests d'intÃ©gration
  - [ ] **1.2.2.1** Tests de bout en bout
  - [ ] **1.2.2.2** Tests de performance

## Phase 2: FonctionnalitÃ©s avancÃ©es

### 2.1 DÃ©veloppement des modules avancÃ©s
- [ ] **2.1.1** ImplÃ©menter l'analyse de donnÃ©es
  - [ ] **2.1.1.1** CrÃ©er le module de collecte
  - [ ] **2.1.1.2** DÃ©velopper les algorithmes d'analyse
"@

        # CrÃ©er un fichier de roadmap complÃ©tÃ©e de test
        $completedContent = @"
# Roadmap ComplÃ©tÃ©e - EMAIL_SENDER_1

Ce fichier contient les tÃ¢ches complÃ©tÃ©es de la roadmap.
GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: FonctionnalitÃ©s de base

### 1.1 ImplÃ©mentation des composants essentiels
- [x] **1.1.1** CrÃ©er la structure de base
  - [x] **1.1.1.1** DÃ©finir l'architecture
  - [x] **1.1.1.2** CrÃ©er les dossiers principaux
  - [x] **1.1.1.3** Configurer l'environnement

### 1.2 Tests et validation
- [x] **1.2.1** CrÃ©er les tests unitaires
  - [x] **1.2.1.1** Tests des composants de base
  - [x] **1.2.1.2** Tests des fonctionnalitÃ©s principales
"@

        # CrÃ©er un fichier de section archivÃ©e
        $sectionContent = @"
# Section 1.1.1 : CrÃ©er la structure de base

Section archivÃ©e le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Contenu

### 1.1.1 CrÃ©er la structure de base
- [x] **1.1.1.1** DÃ©finir l'architecture
- [x] **1.1.1.2** CrÃ©er les dossiers principaux
- [x] **1.1.1.3** Configurer l'environnement
"@

        # Sauvegarder les fichiers
        Set-Content -Path $testActiveRoadmapPath -Value $activeContent -Force
        Set-Content -Path $testCompletedRoadmapPath -Value $completedContent -Force
        Set-Content -Path (Join-Path -Path $testSectionsPath -ChildPath "section_1.1.1_CrÃ©er_la_structure_de_base.md") -Value $sectionContent -Force
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

    # Initialiser les fichiers de test
    Initialize-TestRoadmaps

    # Mock pour la fonction Open-InEditor
    function global:Open-InEditor {
        param($FilePath, $LineNumber = 1)
        return $true
    }
}

AfterAll {
    # Nettoyer aprÃ¨s les tests
    Clear-TestOutput
}

Describe "Navigate-Roadmap" {
    Context "Validation des paramÃ¨tres" {
        It "Devrait Ã©chouer si le fichier de roadmap active n'existe pas" {
            # Supprimer le fichier de roadmap active
            Remove-Item -Path $testActiveRoadmapPath -Force

            $output = & $scriptPath -Mode "Active" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1
            $output | Should -Match "n'existe pas"

            # RÃ©initialiser les fichiers de test
            Initialize-TestRoadmaps
        }

        It "Devrait Ã©chouer si le fichier de roadmap complÃ©tÃ©e n'existe pas" {
            # Supprimer le fichier de roadmap complÃ©tÃ©e
            Remove-Item -Path $testCompletedRoadmapPath -Force

            $output = & $scriptPath -Mode "Completed" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1
            $output | Should -Match "n'existe pas"

            # RÃ©initialiser les fichiers de test
            Initialize-TestRoadmaps
        }
    }

    Context "Navigation dans la roadmap active" {
        It "Devrait afficher un rÃ©sumÃ© de la roadmap active" {
            $output = & $scriptPath -Mode "Active" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "RÃ©sumÃ© de la Roadmap Active"
            $output | Should -Match "Phase 1: FonctionnalitÃ©s de base"
            $output | Should -Match "1.1 ImplÃ©mentation des composants essentiels"
        }

        It "Devrait afficher une section spÃ©cifique de la roadmap active" {
            $output = & $scriptPath -Mode "Active" -SectionId "1.1.2" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "1.1.2 DÃ©velopper les fonctionnalitÃ©s principales"
            $output | Should -Match "1.1.2.1 ImplÃ©menter la gestion des utilisateurs"
            $output | Should -Match "1.1.2.2 DÃ©velopper le systÃ¨me de notifications"
        }

        It "Devrait afficher un message d'erreur si la section n'existe pas" {
            $output = & $scriptPath -Mode "Active" -SectionId "9.9.9" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Section 9.9.9 non trouvÃ©e"
        }
    }

    Context "Navigation dans la roadmap complÃ©tÃ©e" {
        It "Devrait afficher un rÃ©sumÃ© de la roadmap complÃ©tÃ©e" {
            $output = & $scriptPath -Mode "Completed" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "RÃ©sumÃ© de la Roadmap ComplÃ©tÃ©e"
            $output | Should -Match "Phase 1: FonctionnalitÃ©s de base"
            $output | Should -Match "1.1 ImplÃ©mentation des composants essentiels"
            $output | Should -Match "1.2 Tests et validation"
        }

        It "Devrait afficher une section spÃ©cifique de la roadmap complÃ©tÃ©e" {
            $output = & $scriptPath -Mode "Completed" -SectionId "1.2.1" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "1.2.1 CrÃ©er les tests unitaires"
            $output | Should -Match "1.2.1.1 Tests des composants de base"
            $output | Should -Match "1.2.1.2 Tests des fonctionnalitÃ©s principales"
        }

        It "Devrait afficher une section archivÃ©e si elle n'est pas dans la roadmap complÃ©tÃ©e" {
            $output = & $scriptPath -Mode "Completed" -SectionId "1.1.1" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Section trouvÃ©e dans les archives"
            $output | Should -Match "1.1.1 CrÃ©er la structure de base"
        }
    }

    Context "Navigation dans toute la roadmap" {
        It "Devrait afficher un rÃ©sumÃ© complet de la roadmap" {
            $output = & $scriptPath -Mode "All" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "RÃ©sumÃ© de la Roadmap Active"
            $output | Should -Match "RÃ©sumÃ© de la Roadmap ComplÃ©tÃ©e"
            $output | Should -Match "Phase 1: FonctionnalitÃ©s de base"
            $output | Should -Match "Phase 2: FonctionnalitÃ©s avancÃ©es"
        }
    }

    Context "Recherche dans la roadmap" {
        It "Devrait trouver des rÃ©sultats correspondant au terme de recherche" {
            $output = & $scriptPath -Mode "Search" -SearchTerm "tests" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "RÃ©sultats de recherche pour 'tests'"
            $output | Should -Match "Tests et validation"
            $output | Should -Match "Tests des composants de base"
        }

        It "Devrait afficher un message si aucun rÃ©sultat n'est trouvÃ©" {
            $output = & $scriptPath -Mode "Search" -SearchTerm "introuvable" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Aucun rÃ©sultat trouvÃ© pour 'introuvable'"
        }
    }

    Context "Fonctions internes" {
        BeforeAll {
            # Dot-sourcer le script pour accÃ©der aux fonctions internes
            . $scriptPath
        }

        It "Get-SectionLevel devrait identifier correctement le niveau d'une section" {
            Get-SectionLevel -Line "# Titre de niveau 1" | Should -Be 1
            Get-SectionLevel -Line "## Titre de niveau 2" | Should -Be 2
            Get-SectionLevel -Line "### Titre de niveau 3" | Should -Be 3
            Get-SectionLevel -Line "Ceci n'est pas un titre" | Should -Be 0
        }

        It "Get-SectionId devrait extraire correctement l'ID d'une section" {
            Get-SectionId -HeaderLine "### **1.1** Titre avec ID en gras" | Should -Be "1.1"
            Get-SectionId -HeaderLine "### 1.2 Titre avec ID sans gras" | Should -Be "1.2"
            Get-SectionId -HeaderLine "### Titre sans ID" | Should -Be ""
        }

        It "Show-RoadmapSummary devrait gÃ©nÃ©rer un rÃ©sumÃ© correct" {
            $summary = Show-RoadmapSummary -RoadmapPath $testActiveRoadmapPath -MaxLevel 2

            $summary | Should -Not -BeNullOrEmpty
            $summary.Count | Should -BeGreaterThan 0
            $summary | Should -Contain "- Phase 1: FonctionnalitÃ©s de base"
            $summary | Should -Contain "  - [1.1] ImplÃ©mentation des composants essentiels"
        }

        It "Show-RoadmapSection devrait extraire correctement une section" {
            $section = Show-RoadmapSection -RoadmapPath $testActiveRoadmapPath -SectionId "1.1.2"

            $section | Should -Not -BeNullOrEmpty
            $section.Count | Should -BeGreaterThan 0
            $section[0] | Should -Match "1.1.2 DÃ©velopper les fonctionnalitÃ©s principales"
        }

        It "Search-Roadmap devrait trouver correctement les occurrences d'un terme" {
            $results = Search-Roadmap -RoadmapPath $testActiveRoadmapPath -SearchTerm "systÃ¨me"

            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
            $results[0].Line | Should -Match "systÃ¨me de notifications"
        }
    }
}
