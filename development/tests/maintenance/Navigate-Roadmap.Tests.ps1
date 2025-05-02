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

    # Créer le dossier de sortie pour les tests
    if (-not (Test-Path -Path $testOutputPath)) {
        New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
    }

    # Créer le dossier des sections archivées
    if (-not (Test-Path -Path $testSectionsPath)) {
        New-Item -Path $testSectionsPath -ItemType Directory -Force | Out-Null
    }

    # Vérifier que le script existe
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Le script Navigate-Roadmap.ps1 n'a pas été trouvé à l'emplacement: $scriptPath"
    }

    # Fonction pour créer des fichiers de roadmap de test
    function Initialize-TestRoadmaps {
        # Créer un fichier de roadmap active de test
        $activeContent = @"
# Roadmap Active - EMAIL_SENDER_1

Ce fichier contient les tâches actives et à venir de la roadmap.
Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: Fonctionnalités de base

### 1.1 Implémentation des composants essentiels
- [ ] **1.1.2** Développer les fonctionnalités principales
  - [x] **1.1.2.1** Implémenter la gestion des utilisateurs
  - [ ] **1.1.2.2** Développer le système de notifications
  - [ ] **1.1.2.3** Créer l'interface utilisateur

### 1.2 Tests et validation
- [ ] **1.2.2** Effectuer les tests d'intégration
  - [ ] **1.2.2.1** Tests de bout en bout
  - [ ] **1.2.2.2** Tests de performance

## Phase 2: Fonctionnalités avancées

### 2.1 Développement des modules avancés
- [ ] **2.1.1** Implémenter l'analyse de données
  - [ ] **2.1.1.1** Créer le module de collecte
  - [ ] **2.1.1.2** Développer les algorithmes d'analyse
"@

        # Créer un fichier de roadmap complétée de test
        $completedContent = @"
# Roadmap Complétée - EMAIL_SENDER_1

Ce fichier contient les tâches complétées de la roadmap.
Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: Fonctionnalités de base

### 1.1 Implémentation des composants essentiels
- [x] **1.1.1** Créer la structure de base
  - [x] **1.1.1.1** Définir l'architecture
  - [x] **1.1.1.2** Créer les dossiers principaux
  - [x] **1.1.1.3** Configurer l'environnement

### 1.2 Tests et validation
- [x] **1.2.1** Créer les tests unitaires
  - [x] **1.2.1.1** Tests des composants de base
  - [x] **1.2.1.2** Tests des fonctionnalités principales
"@

        # Créer un fichier de section archivée
        $sectionContent = @"
# Section 1.1.1 : Créer la structure de base

Section archivée le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Contenu

### 1.1.1 Créer la structure de base
- [x] **1.1.1.1** Définir l'architecture
- [x] **1.1.1.2** Créer les dossiers principaux
- [x] **1.1.1.3** Configurer l'environnement
"@

        # Sauvegarder les fichiers
        Set-Content -Path $testActiveRoadmapPath -Value $activeContent -Force
        Set-Content -Path $testCompletedRoadmapPath -Value $completedContent -Force
        Set-Content -Path (Join-Path -Path $testSectionsPath -ChildPath "section_1.1.1_Créer_la_structure_de_base.md") -Value $sectionContent -Force
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
    # Nettoyer après les tests
    Clear-TestOutput
}

Describe "Navigate-Roadmap" {
    Context "Validation des paramètres" {
        It "Devrait échouer si le fichier de roadmap active n'existe pas" {
            # Supprimer le fichier de roadmap active
            Remove-Item -Path $testActiveRoadmapPath -Force

            $output = & $scriptPath -Mode "Active" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1
            $output | Should -Match "n'existe pas"

            # Réinitialiser les fichiers de test
            Initialize-TestRoadmaps
        }

        It "Devrait échouer si le fichier de roadmap complétée n'existe pas" {
            # Supprimer le fichier de roadmap complétée
            Remove-Item -Path $testCompletedRoadmapPath -Force

            $output = & $scriptPath -Mode "Completed" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1
            $output | Should -Match "n'existe pas"

            # Réinitialiser les fichiers de test
            Initialize-TestRoadmaps
        }
    }

    Context "Navigation dans la roadmap active" {
        It "Devrait afficher un résumé de la roadmap active" {
            $output = & $scriptPath -Mode "Active" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Résumé de la Roadmap Active"
            $output | Should -Match "Phase 1: Fonctionnalités de base"
            $output | Should -Match "1.1 Implémentation des composants essentiels"
        }

        It "Devrait afficher une section spécifique de la roadmap active" {
            $output = & $scriptPath -Mode "Active" -SectionId "1.1.2" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "1.1.2 Développer les fonctionnalités principales"
            $output | Should -Match "1.1.2.1 Implémenter la gestion des utilisateurs"
            $output | Should -Match "1.1.2.2 Développer le système de notifications"
        }

        It "Devrait afficher un message d'erreur si la section n'existe pas" {
            $output = & $scriptPath -Mode "Active" -SectionId "9.9.9" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Section 9.9.9 non trouvée"
        }
    }

    Context "Navigation dans la roadmap complétée" {
        It "Devrait afficher un résumé de la roadmap complétée" {
            $output = & $scriptPath -Mode "Completed" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Résumé de la Roadmap Complétée"
            $output | Should -Match "Phase 1: Fonctionnalités de base"
            $output | Should -Match "1.1 Implémentation des composants essentiels"
            $output | Should -Match "1.2 Tests et validation"
        }

        It "Devrait afficher une section spécifique de la roadmap complétée" {
            $output = & $scriptPath -Mode "Completed" -SectionId "1.2.1" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "1.2.1 Créer les tests unitaires"
            $output | Should -Match "1.2.1.1 Tests des composants de base"
            $output | Should -Match "1.2.1.2 Tests des fonctionnalités principales"
        }

        It "Devrait afficher une section archivée si elle n'est pas dans la roadmap complétée" {
            $output = & $scriptPath -Mode "Completed" -SectionId "1.1.1" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Section trouvée dans les archives"
            $output | Should -Match "1.1.1 Créer la structure de base"
        }
    }

    Context "Navigation dans toute la roadmap" {
        It "Devrait afficher un résumé complet de la roadmap" {
            $output = & $scriptPath -Mode "All" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Résumé de la Roadmap Active"
            $output | Should -Match "Résumé de la Roadmap Complétée"
            $output | Should -Match "Phase 1: Fonctionnalités de base"
            $output | Should -Match "Phase 2: Fonctionnalités avancées"
        }
    }

    Context "Recherche dans la roadmap" {
        It "Devrait trouver des résultats correspondant au terme de recherche" {
            $output = & $scriptPath -Mode "Search" -SearchTerm "tests" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Résultats de recherche pour 'tests'"
            $output | Should -Match "Tests et validation"
            $output | Should -Match "Tests des composants de base"
        }

        It "Devrait afficher un message si aucun résultat n'est trouvé" {
            $output = & $scriptPath -Mode "Search" -SearchTerm "introuvable" -ActiveRoadmapPath $testActiveRoadmapPath -CompletedRoadmapPath $testCompletedRoadmapPath -SectionsArchivePath $testSectionsPath 2>&1

            $output | Should -Match "Aucun résultat trouvé pour 'introuvable'"
        }
    }

    Context "Fonctions internes" {
        BeforeAll {
            # Dot-sourcer le script pour accéder aux fonctions internes
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

        It "Show-RoadmapSummary devrait générer un résumé correct" {
            $summary = Show-RoadmapSummary -RoadmapPath $testActiveRoadmapPath -MaxLevel 2

            $summary | Should -Not -BeNullOrEmpty
            $summary.Count | Should -BeGreaterThan 0
            $summary | Should -Contain "- Phase 1: Fonctionnalités de base"
            $summary | Should -Contain "  - [1.1] Implémentation des composants essentiels"
        }

        It "Show-RoadmapSection devrait extraire correctement une section" {
            $section = Show-RoadmapSection -RoadmapPath $testActiveRoadmapPath -SectionId "1.1.2"

            $section | Should -Not -BeNullOrEmpty
            $section.Count | Should -BeGreaterThan 0
            $section[0] | Should -Match "1.1.2 Développer les fonctionnalités principales"
        }

        It "Search-Roadmap devrait trouver correctement les occurrences d'un terme" {
            $results = Search-Roadmap -RoadmapPath $testActiveRoadmapPath -SearchTerm "système"

            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
            $results[0].Line | Should -Match "système de notifications"
        }
    }
}
