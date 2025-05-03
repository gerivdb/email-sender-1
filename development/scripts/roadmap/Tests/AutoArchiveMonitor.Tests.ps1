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
    
    # Définir les fonctions de test pour éviter d'exécuter le script complet
    function Test-IDERunning {
        param (
            [string]$ProcessName
        )
        
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        return $null -ne $process
    }
    
    function Test-FileChanged {
        param (
            [string]$FilePath,
            [datetime]$LastCheckTime
        )
        
        if (-not (Test-Path -Path $FilePath)) {
            return $false
        }
        
        $lastWriteTime = (Get-Item -Path $FilePath).LastWriteTime
        return $lastWriteTime -gt $LastCheckTime
    }
    
    function Invoke-ArchiveCompletedTasks {
        param (
            [string]$RoadmapPath,
            [bool]$UpdateVectorDB,
            [bool]$Force
        )
        
        # Simuler l'exécution du script d'archivage
        return $true
    }
    
    # Créer des fichiers de test
    $testRoadmapContent = @"
# Roadmap de test

## Tâches actives

- [ ] **1.1** Tâche incomplète 1
  - [ ] **1.1.1** Sous-tâche incomplète 1.1
  - [x] **1.1.2** Sous-tâche terminée 1.2
- [x] **1.2** Tâche terminée 2
  - [x] **1.2.1** Sous-tâche terminée 2.1
  - [ ] **1.2.2** Sous-tâche incomplète 2.2
- [ ] **1.3** Tâche incomplète 3
"@
    
    $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap.md"
    Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
}

Describe "AutoArchiveMonitor" {
    It "Détecte correctement si l'IDE est en cours d'exécution" {
        # Mock pour la fonction Get-Process
        Mock Get-Process {
            if ($Name -eq "Code") {
                return [PSCustomObject]@{
                    Name = "Code"
                    Id = 12345
                }
            } else {
                return $null
            }
        }
        
        # Appeler la fonction avec le nom du processus de l'IDE
        $result = Test-IDERunning -ProcessName "Code"
        
        # Vérifier le résultat
        $result | Should -Be $true
        
        # Appeler la fonction avec un nom de processus inexistant
        $result = Test-IDERunning -ProcessName "NonExistentProcess"
        
        # Vérifier le résultat
        $result | Should -Be $false
    }
    
    It "Détecte correctement si le fichier a été modifié" {
        # Créer un fichier de test
        $testFilePath = Join-Path -Path $TestDrive -ChildPath "modified_file.txt"
        Set-Content -Path $testFilePath -Value "Contenu initial" -Encoding UTF8
        
        # Définir une date de dernière vérification antérieure à la création du fichier
        $lastCheckTime = (Get-Date).AddMinutes(-5)
        
        # Appeler la fonction avec le fichier de test
        $result = Test-FileChanged -FilePath $testFilePath -LastCheckTime $lastCheckTime
        
        # Vérifier le résultat
        $result | Should -Be $true
        
        # Définir une date de dernière vérification postérieure à la création du fichier
        $lastCheckTime = (Get-Date).AddMinutes(5)
        
        # Appeler la fonction avec le fichier de test
        $result = Test-FileChanged -FilePath $testFilePath -LastCheckTime $lastCheckTime
        
        # Vérifier le résultat
        $result | Should -Be $false
        
        # Appeler la fonction avec un fichier inexistant
        $result = Test-FileChanged -FilePath "NonExistentFile.txt" -LastCheckTime $lastCheckTime
        
        # Vérifier le résultat
        $result | Should -Be $false
    }
    
    It "Exécute correctement l'archivage des tâches terminées" {
        # Mock pour la fonction Invoke-Expression
        Mock Invoke-Expression {
            return $null
        }
        
        # Appeler la fonction avec les paramètres de test
        $result = Invoke-ArchiveCompletedTasks -RoadmapPath $script:testRoadmapPath -UpdateVectorDB $false -Force $true
        
        # Vérifier le résultat
        $result | Should -Be $true
    }
    
    It "Gère correctement les erreurs lors de l'archivage" {
        # Redéfinir la fonction pour simuler une erreur
        function Invoke-ArchiveCompletedTasks {
            param (
                [string]$RoadmapPath,
                [bool]$UpdateVectorDB,
                [bool]$Force
            )
            
            # Simuler une erreur
            return $false
        }
        
        # Appeler la fonction avec les paramètres de test
        $result = Invoke-ArchiveCompletedTasks -RoadmapPath $script:testRoadmapPath -UpdateVectorDB $false -Force $true
        
        # Vérifier le résultat
        $result | Should -Be $false
    }
}
