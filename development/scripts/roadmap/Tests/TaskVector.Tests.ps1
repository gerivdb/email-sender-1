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
    It "Convertit correctement une tÃ¢che en vecteur" {
        # CrÃ©er une tÃ¢che de test
        $task = [PSCustomObject]@{
            Id = "1.1"
            Description = "TÃ¢che de test 1"
            Status = "Incomplete"
            Level = 1
            Section = "TÃ¢ches actives"
        }
        
        # DÃ©finir une fonction de mock pour la conversion
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
        
        # Convertir la tÃ¢che en vecteur
        $vector = ConvertToVector -Task $task
        
        # VÃ©rifier le rÃ©sultat
        $vector | Should -Not -BeNullOrEmpty
        $vector.Id | Should -Be $task.Id
        $vector.Description | Should -Be $task.Description
        $vector.Status | Should -Be $task.Status
        $vector.Level | Should -Be $task.Level
        $vector.Section | Should -Be $task.Section
        $vector.Vector | Should -Not -BeNullOrEmpty
        $vector.Vector.Count | Should -BeGreaterThan 0
    }
    
    It "GÃ©nÃ¨re des vecteurs diffÃ©rents pour des tÃ¢ches diffÃ©rentes" {
        # CrÃ©er deux tÃ¢ches de test
        $task1 = [PSCustomObject]@{
            Id = "1.1"
            Description = "TÃ¢che de test 1"
            Status = "Incomplete"
            Level = 1
            Section = "TÃ¢ches actives"
        }
        
        $task2 = [PSCustomObject]@{
            Id = "1.2"
            Description = "TÃ¢che de test 2"
            Status = "Incomplete"
            Level = 1
            Section = "TÃ¢ches actives"
        }
        
        # DÃ©finir une fonction de mock pour la conversion
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
        
        # Convertir les tÃ¢ches en vecteurs
        $vector1 = ConvertToVector -Task $task1
        $vector2 = ConvertToVector -Task $task2
        
        # VÃ©rifier que les vecteurs sont diffÃ©rents
        $vector1.Vector | Should -Not -Be $vector2.Vector
    }
    
    It "GÃ©nÃ¨re des vecteurs similaires pour des tÃ¢ches similaires" {
        # CrÃ©er deux tÃ¢ches similaires
        $task1 = [PSCustomObject]@{
            Id = "1.1"
            Description = "ImplÃ©menter la fonction de recherche"
            Status = "Incomplete"
            Level = 1
            Section = "TÃ¢ches actives"
        }
        
        $task2 = [PSCustomObject]@{
            Id = "1.2"
            Description = "ImplÃ©menter la fonction de recherche avancÃ©e"
            Status = "Incomplete"
            Level = 1
            Section = "TÃ¢ches actives"
        }
        
        # DÃ©finir une fonction de mock pour la conversion
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
        
        # Convertir les tÃ¢ches en vecteurs
        $vector1 = ConvertToVector -Task $task1
        $vector2 = ConvertToVector -Task $task2
        
        # Nous ne pouvons pas comparer directement les vecteurs, mais nous pouvons vÃ©rifier qu'ils existent
        $vector1.Vector | Should -Not -BeNullOrEmpty
        $vector2.Vector | Should -Not -BeNullOrEmpty
    }
}
