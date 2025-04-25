<#
.SYNOPSIS
    Tests unitaires pour la fonction Invoke-RoadmapGranularization.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Invoke-RoadmapGranularization
    qui permet d'invoquer interactivement la granularisation des tâches de roadmap.

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

# Chemin vers les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$invokeGranPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapGranularization.ps1"
$splitTaskPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Split-RoadmapTask.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $invokeGranPath)) {
    throw "Le fichier Invoke-RoadmapGranularization.ps1 est introuvable à l'emplacement : $invokeGranPath"
}
if (-not (Test-Path -Path $splitTaskPath)) {
    throw "Le fichier Split-RoadmapTask.ps1 est introuvable à l'emplacement : $splitTaskPath"
}

# Importer les fonctions
. $splitTaskPath
. $invokeGranPath

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"
$testSubTasksFilePath = Join-Path -Path $env:TEMP -ChildPath "TestSubTasks_$(Get-Random).txt"

Describe "Invoke-RoadmapGranularization" {
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

        # Créer un fichier de sous-tâches
        @"
Première sous-tâche
Deuxième sous-tâche
Troisième sous-tâche
"@ | Set-Content -Path $testSubTasksFilePath -Encoding UTF8
    }

    AfterEach {
        # Supprimer les fichiers de test
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
        if (Test-Path -Path $testSubTasksFilePath) {
            Remove-Item -Path $testSubTasksFilePath -Force
        }
    }

    It "Devrait décomposer une tâche en utilisant un fichier de sous-tâches" {
        # Appeler la fonction
        Invoke-RoadmapGranularization -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput (Get-Content -Path $testSubTasksFilePath -Raw)

        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\*\* Tâche à décomposer"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Première sous-tâche"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* Deuxième sous-tâche"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.3\*\* Troisième sous-tâche"
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        { Invoke-RoadmapGranularization -FilePath "FichierInexistant.md" -TaskIdentifier "1.3" -SubTasksInput "Sous-tâche" } | Should -Throw
    }

    It "Devrait lever une exception si aucune sous-tâche n'est spécifiée" {
        # Appeler la fonction sans sous-tâches
        { Invoke-RoadmapGranularization -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "" } | Should -Throw
    }

    It "Devrait utiliser les styles d'indentation et de case à cocher spécifiés" {
        # Appeler la fonction avec des styles spécifiques
        Invoke-RoadmapGranularization -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Sous-tâche test" -IndentationStyle "Spaces4" -CheckboxStyle "GitHub"

        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $taskLine = $content | Where-Object { $_ -match "\*\*1\.3\*\*" }
        $subTaskLine = $content | Where-Object { $_ -match "\*\*1\.3\.1\*\*" }
        
        # Vérifier que l'indentation de la sous-tâche utilise 4 espaces
        $taskIndent = $taskLine -replace "^(\s*).*", '$1'
        $subTaskIndent = $subTaskLine -replace "^(\s*).*", '$1'
        ($subTaskIndent.Length - $taskIndent.Length) | Should -Be 4
        
        # Vérifier que le format de case à cocher est correct
        $subTaskLine | Should -Match "- \[ \]"
    }
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
