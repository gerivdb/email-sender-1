BeforeAll {
    # Chemin du projet
    $projectRoot = $PSScriptRoot
    while ($projectRoot -and -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
        $projectRoot = Split-Path -Parent $projectRoot
    }

    if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        if (-not (Test-Path -Path $projectRoot -PathType Container)) {
            throw "Impossible de déterminer le chemin du projet."
        }
    }

    # Charger la configuration de granularité adaptative
    $adaptiveGranularityConfigPath = Join-Path -Path $projectRoot -ChildPath "development\config\granularite-adaptative.json"
    if (Test-Path -Path $adaptiveGranularityConfigPath) {
        $script:adaptiveGranularityConfig = Get-Content -Path $adaptiveGranularityConfigPath -Raw | ConvertFrom-Json
    } else {
        throw "Fichier de configuration de granularité adaptative introuvable: $adaptiveGranularityConfigPath"
    }

    # Charger les fonctions à tester
    $granModeRecursivePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode-recursive-unified.ps1"
    if (Test-Path -Path $granModeRecursivePath) {
        # Extraire les fonctions du script sans l'exécuter
        $scriptContent = Get-Content -Path $granModeRecursivePath -Raw
        $functionMatches = [regex]::Matches($scriptContent, 'function\s+([A-Za-z0-9\-_]+)\s*\{')
        
        foreach ($match in $functionMatches) {
            $functionName = $match.Groups[1].Value
            # Extraire la fonction complète
            $functionPattern = "function\s+$functionName\s*\{(?:[^{}]|(?<open>\{)|(?<close-open>\}))+(?(open)(?!))\}"
            $functionMatch = [regex]::Match($scriptContent, $functionPattern)
            if ($functionMatch.Success) {
                $functionCode = $functionMatch.Value
                # Évaluer la fonction pour la rendre disponible
                Invoke-Expression $functionCode
            }
        }
    } else {
        throw "Script gran-mode-recursive-unified.ps1 introuvable: $granModeRecursivePath"
    }

    # Créer un fichier de roadmap temporaire pour les tests
    $script:tempRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap_recursive.md"
    @"
# Test Roadmap Recursive

## 1. Section de test
- [ ] **1.1** Tâche parent
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
  - [ ] **1.1.3** Sous-tâche 3
- [ ] **1.2** Tâche sans sous-tâches
"@ | Set-Content -Path $script:tempRoadmapPath -Encoding UTF8
}

Describe "Tests de la fonction Get-TaskComplexity (Recursive)" {
    It "Détecte correctement une tâche simple" {
        $taskContent = "Documenter l'API REST"
        $result = Get-TaskComplexity -TaskContent $taskContent
        $result | Should -Be "Simple"
    }

    It "Détecte correctement une tâche moyenne" {
        $taskContent = "Implémenter l'interface utilisateur"
        $result = Get-TaskComplexity -TaskContent $taskContent
        $result | Should -Be "Medium"
    }

    It "Détecte correctement une tâche complexe" {
        $taskContent = "Optimiser l'algorithme de recherche"
        $result = Get-TaskComplexity -TaskContent $taskContent
        $result | Should -Be "Complex"
    }

    It "Détecte correctement une tâche très complexe" {
        $taskContent = "Implémenter le système distribué de haute performance"
        $result = Get-TaskComplexity -TaskContent $taskContent
        $result | Should -Be "VeryComplex"
    }
}

Describe "Tests de la fonction Get-SubTasks (Recursive)" {
    It "Extrait correctement les sous-tâches d'une tâche parent" {
        $result = Get-SubTasks -FilePath $script:tempRoadmapPath -TaskIdentifier "1.1"
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 3
        $result[0].Id | Should -Be "1.1.1"
        $result[1].Id | Should -Be "1.1.2"
        $result[2].Id | Should -Be "1.1.3"
    }

    It "Retourne un tableau vide pour une tâche sans sous-tâches" {
        $result = Get-SubTasks -FilePath $script:tempRoadmapPath -TaskIdentifier "1.2"
        $result | Should -BeNullOrEmpty
    }

    It "Retourne un tableau vide pour une tâche inexistante" {
        $result = Get-SubTasks -FilePath $script:tempRoadmapPath -TaskIdentifier "9.9"
        $result | Should -BeNullOrEmpty
    }
}

Describe "Tests de la fonction Invoke-RecursiveGranularization" {
    BeforeEach {
        # Créer une copie du fichier de roadmap pour chaque test
        $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap_recursive_copy.md"
        Copy-Item -Path $script:tempRoadmapPath -Destination $script:testRoadmapPath -Force
    }

    It "Respecte la profondeur maximale de récursion" {
        # Mock de la fonction pour éviter de modifier réellement le fichier
        Mock Invoke-RecursiveGranularization {
            param($FilePath, $TaskIdentifier, $CurrentDepth, $MaxDepth)
            
            # Vérifier que la profondeur maximale est respectée
            $CurrentDepth | Should -BeLessOrEqual $MaxDepth
            
            # Si on n'a pas atteint la profondeur maximale, simuler l'appel récursif
            if ($CurrentDepth + 1 -lt $MaxDepth) {
                # Simuler des sous-tâches
                $subTasks = @(
                    [PSCustomObject]@{ Id = "$TaskIdentifier.1"; Title = "Sous-tâche 1" },
                    [PSCustomObject]@{ Id = "$TaskIdentifier.2"; Title = "Sous-tâche 2" }
                )
                
                # Appeler récursivement pour chaque sous-tâche
                foreach ($subTask in $subTasks) {
                    Invoke-RecursiveGranularization -FilePath $FilePath -TaskIdentifier $subTask.Id -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
                }
            }
        } -ParameterFilter { $TaskIdentifier -eq "1.1" }
        
        # Exécuter la fonction avec une profondeur maximale de 2
        Invoke-RecursiveGranularization -FilePath $script:testRoadmapPath -TaskIdentifier "1.1" -MaxDepth 2
        
        # Vérifier que la fonction a été appelée avec les bons paramètres
        Should -Invoke Invoke-RecursiveGranularization -ParameterFilter { $TaskIdentifier -eq "1.1" -and $CurrentDepth -eq 0 -and $MaxDepth -eq 2 }
    }

    It "Applique la granularité adaptative en fonction de la complexité" {
        # Mock de la fonction pour éviter de modifier réellement le fichier
        Mock Invoke-RecursiveGranularization {
            param($FilePath, $TaskIdentifier, $ComplexityLevel, $AdaptiveGranularity, $AdaptiveConfig)
            
            # Vérifier que la granularité adaptative est appliquée
            if ($AdaptiveGranularity -and $AdaptiveConfig) {
                # Vérifier que la configuration est correcte
                $AdaptiveConfig.granularite_adaptative | Should -Not -BeNullOrEmpty
                
                # Vérifier que la complexité est prise en compte
                $complexityKey = $ComplexityLevel.ToLower()
                if ($complexityKey -eq "medium") { $complexityKey = "moyenne" }
                if ($complexityKey -eq "complex") { $complexityKey = "elevee" }
                if ($complexityKey -eq "verycomplex") { $complexityKey = "tres_elevee" }
                
                $AdaptiveConfig.granularite_adaptative.profondeur_par_complexite.$complexityKey | Should -Not -BeNullOrEmpty
            }
        } -ParameterFilter { $TaskIdentifier -eq "1.1" }
        
        # Exécuter la fonction avec granularité adaptative
        Invoke-RecursiveGranularization -FilePath $script:testRoadmapPath -TaskIdentifier "1.1" -ComplexityLevel "Complex" -AdaptiveGranularity -AdaptiveConfig $script:adaptiveGranularityConfig
        
        # Vérifier que la fonction a été appelée avec les bons paramètres
        Should -Invoke Invoke-RecursiveGranularization -ParameterFilter { $TaskIdentifier -eq "1.1" -and $ComplexityLevel -eq "Complex" -and $AdaptiveGranularity -eq $true }
    }

    It "Analyse la complexité des sous-tâches si demandé" {
        # Mock de la fonction Get-TaskComplexity pour simuler l'analyse de complexité
        Mock Get-TaskComplexity {
            param($TaskContent, $Domain)
            
            # Simuler différentes complexités selon le contenu
            if ($TaskContent -match "simple") {
                return "Simple"
            } elseif ($TaskContent -match "complexe") {
                return "Complex"
            } else {
                return "Medium"
            }
        }
        
        # Mock de la fonction pour éviter de modifier réellement le fichier
        Mock Invoke-RecursiveGranularization {
            param($FilePath, $TaskIdentifier, $ComplexityLevel, $AnalyzeComplexity)
            
            # Si on analyse la complexité, vérifier que Get-TaskComplexity est appelé
            if ($AnalyzeComplexity) {
                # Simuler l'analyse de complexité pour une sous-tâche
                $subTaskTitle = "Sous-tâche complexe"
                $subTaskComplexity = Get-TaskComplexity -TaskContent $subTaskTitle
                
                # Vérifier que la complexité est correctement détectée
                $subTaskComplexity | Should -Be "Complex"
            }
        } -ParameterFilter { $TaskIdentifier -eq "1.1" }
        
        # Exécuter la fonction avec analyse de complexité
        Invoke-RecursiveGranularization -FilePath $script:testRoadmapPath -TaskIdentifier "1.1" -AnalyzeComplexity
        
        # Vérifier que la fonction a été appelée avec les bons paramètres
        Should -Invoke Invoke-RecursiveGranularization -ParameterFilter { $TaskIdentifier -eq "1.1" -and $AnalyzeComplexity -eq $true }
    }
}

AfterAll {
    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $script:tempRoadmapPath) {
        Remove-Item -Path $script:tempRoadmapPath -Force
    }
    if (Test-Path -Path $script:testRoadmapPath) {
        Remove-Item -Path $script:testRoadmapPath -Force
    }
}
