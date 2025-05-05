# Tests pour le mode de dÃ©bogage

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"
$debugModePath = Join-Path -Path $modulePath -ChildPath "..\modes\debug\debug-mode.ps1"

# Importer la fonction Ã  tester
$invokeRoadmapDebugPath = Join-Path -Path $publicFunctionsPath -ChildPath "Invoke-RoadmapDebug.ps1"

# VÃ©rifier si le fichier existe
if (Test-Path -Path $invokeRoadmapDebugPath) {
    . $invokeRoadmapDebugPath
    Write-Host "Fonction Invoke-RoadmapDebug importÃ©e." -ForegroundColor Green
}

Describe "Debug Mode" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTests_$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er un fichier de roadmap de test
        $testRoadmapContent = @"
# Roadmap de test

- [ ] 1.1 TÃ¢che de test 1
  - [ ] Sous-tÃ¢che 1.1.1
  - [ ] Sous-tÃ¢che 1.1.2

- [x] 1.2 TÃ¢che de test 2 (complÃ©tÃ©e)
  - [x] Sous-tÃ¢che 1.2.1
  - [x] Sous-tÃ¢che 1.2.2

- [x] 1.3 TÃ¢che de test 3 (incohÃ©rente)
  - [ ] Sous-tÃ¢che 1.3.1
  - [x] Sous-tÃ¢che 1.3.2

- [ ] 1.4 TÃ¢che de test 4 (incohÃ©rente)
  - [x] Sous-tÃ¢che 1.4.1
  - [x] Sous-tÃ¢che 1.4.2

- [ ] 1.5
"@

        $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test_roadmap.md"
        Set-Content -Path $testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
    }

    AfterAll {
        # Nettoyer le rÃ©pertoire temporaire
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    Context "Invoke-RoadmapDebug" {
        It "Should detect a task with incomplete subtasks" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.1" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tÃ¢che a des sous-tÃ¢ches incomplÃ¨tes."
        }

        It "Should detect a completed task with all subtasks completed" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.2" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeTrue
        }

        It "Should detect an inconsistent task (completed with incomplete subtasks)" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.3" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tÃ¢che est marquÃ©e comme complÃ©tÃ©e mais a des sous-tÃ¢ches incomplÃ¨tes."
        }

        It "Should detect an inconsistent task (incomplete with all subtasks completed)" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.4" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tÃ¢che a toutes ses sous-tÃ¢ches complÃ©tÃ©es mais n'est pas marquÃ©e comme complÃ©tÃ©e."
        }

        It "Should detect a task without description" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.5" -RoadmapPath $testRoadmapPath
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain "La tÃ¢che n'a pas de description."
        }

        It "Should generate a patch when requested" {
            $result = Invoke-RoadmapDebug -TaskIdentifier "1.5" -RoadmapPath $testRoadmapPath -GeneratePatch
            $result.Success | Should -BeFalse
            $result.Patch | Should -Not -BeNullOrEmpty
        }
    }

    Context "Debug Mode Script" {
        # Ces tests sont ignorÃ©s car ils nÃ©cessitent l'exÃ©cution du script complet
        # et peuvent avoir des effets secondaires
        It "Should execute the debug mode script" -Skip {
            # Simuler l'exÃ©cution du script
            $output = & $debugModePath -TaskIdentifier "1.1" -RoadmapPath $testRoadmapPath
            $output | Should -Not -BeNullOrEmpty
        }

        It "Should generate a patch when requested" -Skip {
            # Simuler l'exÃ©cution du script avec gÃ©nÃ©ration de patch
            $output = & $debugModePath -TaskIdentifier "1.5" -RoadmapPath $testRoadmapPath -GeneratePatch
            $output | Should -Not -BeNullOrEmpty
        }

        It "Should include stack trace when requested" -Skip {
            # Simuler l'exÃ©cution du script avec trace de pile
            $output = & $debugModePath -TaskIdentifier "invalid" -RoadmapPath $testRoadmapPath -IncludeStackTrace
            $output | Should -Not -BeNullOrEmpty
        }
    }
}
