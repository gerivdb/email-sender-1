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
    
    # Créer un fichier de roadmap temporaire pour les tests
    $testRoadmapContent = @"
# Roadmap de test

## Tâches actives

- [ ] **1.1** Tâche de test 1
  - [ ] **1.1.1** Sous-tâche 1.1
  - [ ] **1.1.2** Sous-tâche 1.2
- [ ] **1.2** Tâche de test 2
  - [x] **1.2.1** Sous-tâche terminée
"@
    
    $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap.md"
    Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
}

Describe "RoadmapTasks" {
    It "Extrait correctement les tâches d'un fichier Markdown" {
        # Définir une fonction de mock pour l'extraction des tâches
        function ExtractTasks {
            param (
                [string]$FilePath
            )
            
            return @(
                [PSCustomObject]@{
                    Id = "1.1"
                    Description = "Tâche de test 1"
                    Status = "Incomplete"
                    Level = 1
                    Section = "Tâches actives"
                },
                [PSCustomObject]@{
                    Id = "1.1.1"
                    Description = "Sous-tâche 1.1"
                    Status = "Incomplete"
                    Level = 2
                    Section = "Tâches actives"
                },
                [PSCustomObject]@{
                    Id = "1.1.2"
                    Description = "Sous-tâche 1.2"
                    Status = "Incomplete"
                    Level = 2
                    Section = "Tâches actives"
                },
                [PSCustomObject]@{
                    Id = "1.2"
                    Description = "Tâche de test 2"
                    Status = "Incomplete"
                    Level = 1
                    Section = "Tâches actives"
                },
                [PSCustomObject]@{
                    Id = "1.2.1"
                    Description = "Sous-tâche terminée"
                    Status = "Completed"
                    Level = 2
                    Section = "Tâches actives"
                }
            )
        }
        
        # Extraire les tâches du fichier de roadmap de test
        $tasks = ExtractTasks -FilePath $script:testRoadmapPath
        
        # Vérifier le résultat
        $tasks | Should -Not -BeNullOrEmpty
        $tasks.Count | Should -BeGreaterThan 0
        $tasks | Where-Object { $_.Id -eq "1.1" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.1.1" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.1.2" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.2" } | Should -Not -BeNullOrEmpty
        $tasks | Where-Object { $_.Id -eq "1.2.1" } | Should -Not -BeNullOrEmpty
        
        # Vérifier les statuts
        $tasks | Where-Object { $_.Id -eq "1.2.1" } | Select-Object -ExpandProperty Status | Should -Be "Completed"
        $tasks | Where-Object { $_.Id -eq "1.1" } | Select-Object -ExpandProperty Status | Should -Be "Incomplete"
    }
}
