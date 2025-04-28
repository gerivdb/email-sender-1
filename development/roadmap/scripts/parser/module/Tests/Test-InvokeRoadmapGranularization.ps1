<#
.SYNOPSIS
    Tests unitaires pour la fonction Invoke-RoadmapGranularization.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Invoke-RoadmapGranularization
    qui permet d'invoquer interactivement la granularisation des tÃ¢ches de roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
}

# Chemin vers les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$invokeGranPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapGranularization.ps1"
$splitTaskPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Split-RoadmapTask.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $invokeGranPath)) {
    throw "Le fichier Invoke-RoadmapGranularization.ps1 est introuvable Ã  l'emplacement : $invokeGranPath"
}
if (-not (Test-Path -Path $splitTaskPath)) {
    throw "Le fichier Split-RoadmapTask.ps1 est introuvable Ã  l'emplacement : $splitTaskPath"
}

# Importer les fonctions
. $splitTaskPath
. $invokeGranPath

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"
$testSubTasksFilePath = Join-Path -Path $env:TEMP -ChildPath "TestSubTasks_$(Get-Random).txt"

Describe "Invoke-RoadmapGranularization" {
    BeforeEach {
        # CrÃ©er un fichier de test avec une structure de roadmap simple
        @"
# Roadmap de test

## Section 1

- [ ] **1.1** TÃ¢che 1
- [ ] **1.2** TÃ¢che 2
  - [ ] **1.2.1** Sous-tÃ¢che 1
  - [ ] **1.2.2** Sous-tÃ¢che 2
- [ ] **1.3** TÃ¢che Ã  dÃ©composer

## Section 2

- [ ] **2.1** Autre tÃ¢che
"@ | Set-Content -Path $testFilePath -Encoding UTF8

        # CrÃ©er un fichier de sous-tÃ¢ches
        @"
PremiÃ¨re sous-tÃ¢che
DeuxiÃ¨me sous-tÃ¢che
TroisiÃ¨me sous-tÃ¢che
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

    It "Devrait dÃ©composer une tÃ¢che en utilisant un fichier de sous-tÃ¢ches" {
        # Appeler la fonction
        Invoke-RoadmapGranularization -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput (Get-Content -Path $testSubTasksFilePath -Raw)

        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\*\* TÃ¢che Ã  dÃ©composer"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* PremiÃ¨re sous-tÃ¢che"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* DeuxiÃ¨me sous-tÃ¢che"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.3\*\* TroisiÃ¨me sous-tÃ¢che"
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        { Invoke-RoadmapGranularization -FilePath "FichierInexistant.md" -TaskIdentifier "1.3" -SubTasksInput "Sous-tÃ¢che" } | Should -Throw
    }

    It "Devrait lever une exception si aucune sous-tÃ¢che n'est spÃ©cifiÃ©e" {
        # Appeler la fonction sans sous-tÃ¢ches
        { Invoke-RoadmapGranularization -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "" } | Should -Throw
    }

    It "Devrait utiliser les styles d'indentation et de case Ã  cocher spÃ©cifiÃ©s" {
        # Appeler la fonction avec des styles spÃ©cifiques
        Invoke-RoadmapGranularization -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Sous-tÃ¢che test" -IndentationStyle "Spaces4" -CheckboxStyle "GitHub"

        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $taskLine = $content | Where-Object { $_ -match "\*\*1\.3\*\*" }
        $subTaskLine = $content | Where-Object { $_ -match "\*\*1\.3\.1\*\*" }
        
        # VÃ©rifier que l'indentation de la sous-tÃ¢che utilise 4 espaces
        $taskIndent = $taskLine -replace "^(\s*).*", '$1'
        $subTaskIndent = $subTaskLine -replace "^(\s*).*", '$1'
        ($subTaskIndent.Length - $taskIndent.Length) | Should -Be 4
        
        # VÃ©rifier que le format de case Ã  cocher est correct
        $subTaskLine | Should -Match "- \[ \]"
    }
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}
