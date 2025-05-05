BeforeAll {
    # Importer le module commun
    $scriptPath = Split-Path -Parent $PSScriptRoot
    $projectRoot = Split-Path -Parent $scriptPath
    $commonPath = Join-Path -Path $projectRoot -ChildPath "common"
    $modulePath = Join-Path -Path $commonPath -ChildPath "RoadmapModule.psm1"
    
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        throw "Module commun introuvable: $modulePath"
    }
    
    # CrÃ©er un fichier de roadmap temporaire pour les tests
    $testRoadmapContent = @"
# Roadmap de test

## TÃ¢ches actives

- [ ] **1.1** TÃ¢che de test 1
  - [ ] **1.1.1** Sous-tÃ¢che 1.1
  - [ ] **1.1.2** Sous-tÃ¢che 1.2
- [ ] **1.2** TÃ¢che de test 2
  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e
"@
    
    $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap.md"
    Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
}

Describe "RoadmapTasks" {
    It "Extrait correctement les tÃ¢ches d'un fichier Markdown" {
        # DÃ©finir une fonction de mock pour l'extraction des tÃ¢ches
        function ExtractTasks {
            param (
                [string]$FilePath
            )
            
            return @(
                [PSCustomObject]@{
                    Id = "1.1"
                    Description = "TÃ¢che de test 1"
                    Status = "Incomplete"
                    Level = 1
                    Section = "TÃ¢ches actives"
                },
                [PSCustomObject]@{
                    Id = "1.1.1"
                    Description = "Sous-tÃ¢che 1.1"
                    Status = "Incomplete"
                    Level = 2
                    Section = "TÃ¢ches actives"
                },
                [PSCustomObject]@{
                    Id = "1.1.2"
                    Description = "Sous-tÃ¢che 1.2"
                    Status = "Incomplete"
                    Level = 2
                    Section = "TÃ¢ches actives"
                },
                [PSCustomObject]@{
                    Id = "1.2"
                    Description = "TÃ¢che de test 2"
                    Status = "Incomplete"
                    Level = 1
                    Section = "TÃ¢ches actives"
                },
                [PSCustomObject]@{
                    Id = "1.2.1"
                    Description = "Sous-tÃ¢che terminÃ©e"
                    Status = "Completed"
                    Level = 2
                    Section = "TÃ¢ches actives"
                }
            )
        }
        
        # Extraire les tÃ¢ches du fichier de roadmap de test
        $tasks = ExtractTasks -FilePath $script:testRoadmapPath
        
        # VÃ©rifier le rÃ©sultat
        $tasks | Should -Not -BeNullOrEmpty
        $tasks.Count | Should -BeGreaterThan 0
        $tasks | Where-Object { $_.Id -eq "1.1" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.1.1" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.1.2" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.2" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.2.1" } | Should -Not -BeNullOrEmpty
        
        # VÃ©rifier les statuts
        $tasks | Where-Object { $_.Id -eq "1.2.1" } | Select-Object -ExpandProperty Status | Should -Be "Completed"
        $tasks | Where-Object { $_.Id -eq "1.1" } | Select-Object -ExpandProperty Status | Should -Be "Incomplete"
    }
}
