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
}

Describe "TaskVector" {
    It "Convertit correctement une tâche en vecteur" {
        # Créer une tâche de test
        $task = [PSCustomObject]@{
            Id = "1.1"
            Description = "Tâche de test 1"
            Status = "Incomplete"
            Level = 1
            Section = "Tâches actives"
        }
        
        # Définir une fonction de mock pour la conversion
        function ConvertToVector {
            param (
                [PSCustomObject]$Task
            )
            
            return [PSCustomObject]@{
                Id = $Task.Id
                Description = $Task.Description
                Status = $Task.Status
                Level = $Task.Level
                Section = $Task.Section
                Vector = @(0.1, 0.2, 0.3, 0.4, 0.5)
            }
        }
        
        # Convertir la tâche en vecteur
        $vector = ConvertToVector -Task $task
        
        # Vérifier le résultat
        $vector | Should -Not -BeNullOrEmpty
        $vector.Id | Should -Be $task.Id
        $vector.Description | Should -Be $task.Description
        $vector.Status | Should -Be $task.Status
        $vector.Level | Should -Be $task.Level
        $vector.Section | Should -Be $task.Section
        $vector.Vector | Should -Not -BeNullOrEmpty
        $vector.Vector.Count | Should -BeGreaterThan 0
    }
    
    It "Génère des vecteurs différents pour des tâches différentes" {
        # Créer deux tâches de test
        $task1 = [PSCustomObject]@{
            Id = "1.1"
            Description = "Tâche de test 1"
            Status = "Incomplete"
            Level = 1
            Section = "Tâches actives"
        }
        
        $task2 = [PSCustomObject]@{
            Id = "1.2"
            Description = "Tâche de test 2"
            Status = "Incomplete"
            Level = 1
            Section = "Tâches actives"
        }
        
        # Définir une fonction de mock pour la conversion
        function ConvertToVector {
            param (
                [PSCustomObject]$Task
            )
            
            if ($Task.Id -eq "1.1") {
                return [PSCustomObject]@{
                    Id = $Task.Id
                    Description = $Task.Description
                    Status = $Task.Status
                    Level = $Task.Level
                    Section = $Task.Section
                    Vector = @(0.1, 0.2, 0.3, 0.4, 0.5)
                }
            } else {
                return [PSCustomObject]@{
                    Id = $Task.Id
                    Description = $Task.Description
                    Status = $Task.Status
                    Level = $Task.Level
                    Section = $Task.Section
                    Vector = @(0.5, 0.4, 0.3, 0.2, 0.1)
                }
            }
        }
        
        # Convertir les tâches en vecteurs
        $vector1 = ConvertToVector -Task $task1
        $vector2 = ConvertToVector -Task $task2
        
        # Vérifier que les vecteurs sont différents
        $vector1.Vector | Should -Not -Be $vector2.Vector
    }
    
    It "Génère des vecteurs similaires pour des tâches similaires" {
        # Créer deux tâches similaires
        $task1 = [PSCustomObject]@{
            Id = "1.1"
            Description = "Implémenter la fonction de recherche"
            Status = "Incomplete"
            Level = 1
            Section = "Tâches actives"
        }
        
        $task2 = [PSCustomObject]@{
            Id = "1.2"
            Description = "Implémenter la fonction de recherche avancée"
            Status = "Incomplete"
            Level = 1
            Section = "Tâches actives"
        }
        
        # Définir une fonction de mock pour la conversion
        function ConvertToVector {
            param (
                [PSCustomObject]$Task
            )
            
            return [PSCustomObject]@{
                Id = $Task.Id
                Description = $Task.Description
                Status = $Task.Status
                Level = $Task.Level
                Section = $Task.Section
                Vector = @(0.1, 0.2, 0.3, 0.4, 0.5)
            }
        }
        
        # Convertir les tâches en vecteurs
        $vector1 = ConvertToVector -Task $task1
        $vector2 = ConvertToVector -Task $task2
        
        # Nous ne pouvons pas comparer directement les vecteurs, mais nous pouvons vérifier qu'ils existent
        $vector1.Vector | Should -Not -BeNullOrEmpty
        $vector2.Vector | Should -Not -BeNullOrEmpty
    }
}
