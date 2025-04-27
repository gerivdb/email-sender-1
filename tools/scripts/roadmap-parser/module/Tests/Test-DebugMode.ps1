# Tests pour le mode de débogage

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"
$debugModePath = Join-Path -Path $modulePath -ChildPath "..\modes\debug\debug-mode.ps1"

# Importer la fonction à tester
$invokeRoadmapDebugPath = Join-Path -Path $publicFunctionsPath -ChildPath "Invoke-RoadmapDebug.ps1"

# Vérifier si le fichier existe
if (Test-Path -Path $invokeRoadmapDebugPath) {
    . $invokeRoadmapDebugPath
    Write-Host "Fonction Invoke-RoadmapDebug importée." -ForegroundColor Green
}

Describe "Debug Mode" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTests_$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Créer un fichier de roadmap de test
        $testRoadmapContent = @"
# Roadmap de test

- [ ] 1.1 Tâche de test 1
  - [ ] Sous-tâche 1.1.1
  - [ ] Sous-tâche 1.1.2

- [x] 1.2 Tâche de test 2 (complétée)
  - [x] Sous-tâche 1.2.1
  - [x] Sous-tâche 1.2.2

- [x] 1.3 Tâche de test 3 (incohérente)
  - [ ] Sous-tâche 1.3.1
  - [x] Sous-tâche 1.3.2

- [ ] 1.4 Tâche de test 4 (incohérente)
  - [x] Sous-tâche 1.4.1
  - [x] Sous-tâche 1.4.2

- [ ] 1.5
"@

        $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test_roadmap.md"
        Set-Content -Path $testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
    }

    AfterAll {
        # Nettoyer le répertoire temporaire
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    Context "Invoke-RoadmapDebug" {
        It "Should detect a task with incomplete subtasks" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.1" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tâche a des sous-tâches incomplètes."
        }

        It "Should detect a completed task with all subtasks completed" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.2" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeTrue
        }

        It "Should detect an inconsistent task (completed with incomplete subtasks)" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.3" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tâche est marquée comme complétée mais a des sous-tâches incomplètes."
        }

        It "Should detect an inconsistent task (incomplete with all subtasks completed)" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.4" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tâche a toutes ses sous-tâches complétées mais n'est pas marquée comme complétée."
        }

        It "Should detect a task without description" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.5" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tâche n'a pas de description."
        }

        It "Should generate a patch when requested" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.5" -RoadmapPath $testRoadmapPath -GeneratePatch
            $result.Success | Should -BeFalse
            $result.Patch | Should -Not -BeNullOrEmpty
        }
    }

    Context "Debug Mode Script" {
        # Ces tests sont ignorés car ils nécessitent l'exécution du script complet
        # et peuvent avoir des effets secondaires
        It "Should execute the debug mode script" -Skip {
            # Simuler l'exécution du script
            $output = & $debugModePath -TaskIdentifier "1.1" -RoadmapPath $testRoadmapPath
            $output | Should -Not -BeNullOrEmpty
        }

        It "Should generate a patch when requested" -Skip {
            # Simuler l'exécution du script avec génération de patch
            $output = & $debugModePath -TaskIdentifier "1.5" -RoadmapPath $testRoadmapPath -GeneratePatch
            $output | Should -Not -BeNullOrEmpty
        }

        It "Should include stack trace when requested" -Skip {
            # Simuler l'exécution du script avec trace de pile
            $output = & $debugModePath -TaskIdentifier "invalid" -RoadmapPath $testRoadmapPath -IncludeStackTrace
            $output | Should -Not -BeNullOrEmpty
        }
    }
}
