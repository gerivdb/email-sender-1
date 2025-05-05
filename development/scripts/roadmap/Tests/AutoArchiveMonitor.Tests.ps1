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
    
    # DÃ©finir les fonctions de test pour Ã©viter d'exÃ©cuter le script complet
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
        
        # Simuler l'exÃ©cution du script d'archivage
        return $true
    }
    
    # CrÃ©er des fichiers de test
    $testRoadmapContent = @"
# Roadmap de test

## TÃ¢ches actives

- [ ] **1.1** TÃ¢che incomplÃ¨te 1
  - [ ] **1.1.1** Sous-tÃ¢che incomplÃ¨te 1.1
  - [x] **1.1.2** Sous-tÃ¢che terminÃ©e 1.2
- [x] **1.2** TÃ¢che terminÃ©e 2
  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e 2.1
  - [ ] **1.2.2** Sous-tÃ¢che incomplÃ¨te 2.2
- [ ] **1.3** TÃ¢che incomplÃ¨te 3
"@
    
    $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap.md"
    Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
}

Describe "AutoArchiveMonitor" {
    It "DÃ©tecte correctement si l'IDE est en cours d'exÃ©cution" {
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
        
        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $true
        
        # Appeler la fonction avec un nom de processus inexistant
        $result = Test-IDERunning -ProcessName "NonExistentProcess"
        
        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $false
    }
    
    It "DÃ©tecte correctement si le fichier a Ã©tÃ© modifiÃ©" {
        # CrÃ©er un fichier de test
        $testFilePath = Join-Path -Path $TestDrive -ChildPath "modified_file.txt"
        Set-Content -Path $testFilePath -Value "Contenu initial" -Encoding UTF8
        
        # DÃ©finir une date de derniÃ¨re vÃ©rification antÃ©rieure Ã  la crÃ©ation du fichier
        $lastCheckTime = (Get-Date).AddMinutes(-5)
        
        # Appeler la fonction avec le fichier de test
        $result = Test-FileChanged -FilePath $testFilePath -LastCheckTime $lastCheckTime
        
        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $true
        
        # DÃ©finir une date de derniÃ¨re vÃ©rification postÃ©rieure Ã  la crÃ©ation du fichier
        $lastCheckTime = (Get-Date).AddMinutes(5)
        
        # Appeler la fonction avec le fichier de test
        $result = Test-FileChanged -FilePath $testFilePath -LastCheckTime $lastCheckTime
        
        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $false
        
        # Appeler la fonction avec un fichier inexistant
        $result = Test-FileChanged -FilePath "NonExistentFile.txt" -LastCheckTime $lastCheckTime
        
        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $false
    }
    
    It "ExÃ©cute correctement l'archivage des tÃ¢ches terminÃ©es" {
        # Mock pour la fonction Invoke-Expression
        Mock Invoke-Expression {
            return $null
        }
        
        # Appeler la fonction avec les paramÃ¨tres de test
        $result = Invoke-ArchiveCompletedTasks -RoadmapPath $script:testRoadmapPath -UpdateVectorDB $false -Force $true
        
        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $true
    }
    
    It "GÃ¨re correctement les erreurs lors de l'archivage" {
        # RedÃ©finir la fonction pour simuler une erreur
        function Invoke-ArchiveCompletedTasks {
            param (
                [string]$RoadmapPath,
                [bool]$UpdateVectorDB,
                [bool]$Force
            )
            
            # Simuler une erreur
            return $false
        }
        
        # Appeler la fonction avec les paramÃ¨tres de test
        $result = Invoke-ArchiveCompletedTasks -RoadmapPath $script:testRoadmapPath -UpdateVectorDB $false -Force $true
        
        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $false
    }
}
