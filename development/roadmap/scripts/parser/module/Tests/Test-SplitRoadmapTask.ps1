<#
.SYNOPSIS
    Tests unitaires pour la fonction Split-RoadmapTask.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Split-RoadmapTask
    qui dÃ©compose une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires.

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

# Chemin vers la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Split-RoadmapTask.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Split-RoadmapTask.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

Describe "Split-RoadmapTask" {
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
    }

    AfterEach {
        # Supprimer le fichier de test
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches" {
        # DÃ©finir les sous-tÃ¢ches
        $subTasks = @(
            @{ Title = "PremiÃ¨re sous-tÃ¢che"; Description = "" },
            @{ Title = "DeuxiÃ¨me sous-tÃ¢che"; Description = "" }
        )

        # Appeler la fonction
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasks $subTasks

        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\*\* TÃ¢che Ã  dÃ©composer"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* PremiÃ¨re sous-tÃ¢che"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* DeuxiÃ¨me sous-tÃ¢che"
    }

    It "Devrait respecter l'indentation existante" {
        # DÃ©finir les sous-tÃ¢ches
        $subTasks = @(
            @{ Title = "Sous-tÃ¢che indentÃ©e"; Description = "" }
        )

        # Appeler la fonction
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.2.1" -SubTasks $subTasks

        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $taskLine = $content | Where-Object { $_ -match "\*\*1\.2\.1\*\*" }
        $subTaskLine = $content | Where-Object { $_ -match "\*\*1\.2\.1\.1\*\*" }
        
        # VÃ©rifier que l'indentation de la sous-tÃ¢che est correcte
        $taskIndent = $taskLine -replace "^(\s*).*", '$1'
        $subTaskIndent = $subTaskLine -replace "^(\s*).*", '$1'
        $subTaskIndent.Length | Should -BeGreaterThan $taskIndent.Length
    }

    It "Devrait gÃ©rer les descriptions des sous-tÃ¢ches" {
        # DÃ©finir les sous-tÃ¢ches avec descriptions
        $subTasks = @(
            @{ 
                Title = "Sous-tÃ¢che avec description"; 
                Description = "Ceci est une description`nSur plusieurs lignes" 
            }
        )

        # Appeler la fonction
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasks $subTasks

        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Sous-tÃ¢che avec description"
        $content -join "`n" | Should -Match "Ceci est une description"
        $content -join "`n" | Should -Match "Sur plusieurs lignes"
    }

    It "Devrait lever une exception si la tÃ¢che n'existe pas" {
        # DÃ©finir les sous-tÃ¢ches
        $subTasks = @(
            @{ Title = "Sous-tÃ¢che"; Description = "" }
        )

        # Appeler la fonction avec un identifiant inexistant
        { Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "9.9.9" -SubTasks $subTasks } | Should -Throw
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # DÃ©finir les sous-tÃ¢ches
        $subTasks = @(
            @{ Title = "Sous-tÃ¢che"; Description = "" }
        )

        # Appeler la fonction avec un fichier inexistant
        { Split-RoadmapTask -FilePath "FichierInexistant.md" -TaskIdentifier "1.3" -SubTasks $subTasks } | Should -Throw
    }

    It "Devrait utiliser le style d'indentation spÃ©cifiÃ©" {
        # DÃ©finir les sous-tÃ¢ches
        $subTasks = @(
            @{ Title = "Sous-tÃ¢che indentÃ©e"; Description = "" }
        )

        # Appeler la fonction avec un style d'indentation spÃ©cifique
        Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasks $subTasks -IndentationStyle "Spaces4"

        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $taskLine = $content | Where-Object { $_ -match "\*\*1\.3\*\*" }
        $subTaskLine = $content | Where-Object { $_ -match "\*\*1\.3\.1\*\*" }
        
        # VÃ©rifier que l'indentation de la sous-tÃ¢che utilise 4 espaces
        $taskIndent = $taskLine -replace "^(\s*).*", '$1'
        $subTaskIndent = $subTaskLine -replace "^(\s*).*", '$1'
        ($subTaskIndent.Length - $taskIndent.Length) | Should -Be 4
    }
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}
