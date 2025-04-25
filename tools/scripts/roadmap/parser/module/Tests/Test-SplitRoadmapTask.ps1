<#
.SYNOPSIS
    Tests unitaires pour la fonction Split-RoadmapTask.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Split-RoadmapTask
    qui décompose une tâche de roadmap en sous-tâches plus granulaires.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
}

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Split-RoadmapTask.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Split-RoadmapTask.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

Describe "Split-RoadmapTask" {
    BeforeEach {
        # Créer un fichier de test avec une structure de roadmap simple
        @"
# Roadmap de test

## Section 1

- [ ] **1.1** Tâche 1
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2
- [ ] **1.3** Tâche à décomposer

## Section 2

- [ ] **2.1** Autre tâche
"@ | Set-Content -Path $testFilePath -Encoding UTF8
    }

    AfterEach {
        # Supprimer le fichier de test
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
    }

    It "Devrait décomposer une tâche en sous-tâches" {
        # Définir les sous-tâches
        $subTasks = @(
            @{ Title = "Première sous-tâche"; Description = "" },
            @{ Title = "Deuxième sous-tâche"; Description = "" }
        )

        # Appeler la fonction
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasks $subTasks

        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\*\* Tâche à décomposer"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Première sous-tâche"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* Deuxième sous-tâche"
    }

    It "Devrait respecter l'indentation existante" {
        # Définir les sous-tâches
        $subTasks = @(
            @{ Title = "Sous-tâche indentée"; Description = "" }
        )

        # Appeler la fonction
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.2.1" -SubTasks $subTasks

        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $taskLine = $content | Where-Object { $_ -match "\*\*1\.2\.1\*\*" }
        $subTaskLine = $content | Where-Object { $_ -match "\*\*1\.2\.1\.1\*\*" }
        
        # Vérifier que l'indentation de la sous-tâche est correcte
        $taskIndent = $taskLine -replace "^(\s*).*", '$1'
        $subTaskIndent = $subTaskLine -replace "^(\s*).*", '$1'
        $subTaskIndent.Length | Should -BeGreaterThan $taskIndent.Length
    }

    It "Devrait gérer les descriptions des sous-tâches" {
        # Définir les sous-tâches avec descriptions
        $subTasks = @(
            @{ 
                Title = "Sous-tâche avec description"; 
                Description = "Ceci est une description`nSur plusieurs lignes" 
            }
        )

        # Appeler la fonction
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasks $subTasks

        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Sous-tâche avec description"
        $content -join "`n" | Should -Match "Ceci est une description"
        $content -join "`n" | Should -Match "Sur plusieurs lignes"
    }

    It "Devrait lever une exception si la tâche n'existe pas" {
        # Définir les sous-tâches
        $subTasks = @(
            @{ Title = "Sous-tâche"; Description = "" }
        )

        # Appeler la fonction avec un identifiant inexistant
        { Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "9.9.9" -SubTasks $subTasks } | Should -Throw
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # Définir les sous-tâches
        $subTasks = @(
            @{ Title = "Sous-tâche"; Description = "" }
        )

        # Appeler la fonction avec un fichier inexistant
        { Split-RoadmapTask -FilePath "FichierInexistant.md" -TaskIdentifier "1.3" -SubTasks $subTasks } | Should -Throw
    }

    It "Devrait utiliser le style d'indentation spécifié" {
        # Définir les sous-tâches
        $subTasks = @(
            @{ Title = "Sous-tâche indentée"; Description = "" }
        )

        # Appeler la fonction avec un style d'indentation spécifique
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasks $subTasks -IndentationStyle "Spaces4"

        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $taskLine = $content | Where-Object { $_ -match "\*\*1\.3\*\*" }
        $subTaskLine = $content | Where-Object { $_ -match "\*\*1\.3\.1\*\*" }
        
        # Vérifier que l'indentation de la sous-tâche utilise 4 espaces
        $taskIndent = $taskLine -replace "^(\s*).*", '$1'
        $subTaskIndent = $subTaskLine -replace "^(\s*).*", '$1'
        ($subTaskIndent.Length - $taskIndent.Length) | Should -Be 4
    }
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
