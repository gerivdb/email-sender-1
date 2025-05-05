<#
.SYNOPSIS
    Tests unitaires pour la fonction Invoke-RoadmapGranularizationWithTimeEstimation.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Invoke-RoadmapGranularizationWithTimeEstimation
    qui permet d'invoquer interactivement la granularisation des tÃ¢ches de roadmap avec estimations de temps.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
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
$invokeGranPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapGranularizationWithTimeEstimation.ps1"
$splitTaskPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Split-RoadmapTask.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $invokeGranPath)) {
    throw "Le fichier Invoke-RoadmapGranularizationWithTimeEstimation.ps1 est introuvable Ã  l'emplacement : $invokeGranPath"
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

Describe "Invoke-RoadmapGranularizationWithTimeEstimation" {
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

        # CrÃ©er un fichier de sous-tÃ¢ches de test
        @"
Analyser les besoins
Concevoir la solution
ImplÃ©menter le code
Tester la solution
"@ | Set-Content -Path $testSubTasksFilePath -Encoding UTF8
    }

    AfterEach {
        # Supprimer les fichiers temporaires
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
        if (Test-Path -Path $testSubTasksFilePath) {
            Remove-Item -Path $testSubTasksFilePath -Force
        }
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        { Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "FichierInexistant.md" -TaskIdentifier "1.3" -SubTasksInput "Sous-tÃ¢che" } | Should -Throw
    }

    It "Devrait lever une exception si aucune sous-tÃ¢che n'est spÃ©cifiÃ©e" {
        # Appeler la fonction sans sous-tÃ¢ches
        { Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "" } | Should -Throw
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches avec estimations de temps" {
        # CrÃ©er un mock pour la fonction Get-TaskTimeEstimate
        function Get-TaskTimeEstimate {
            param (
                [string]$TaskContent,
                [string]$ComplexityLevel,
                [string]$Domain,
                [string]$ProjectRoot
            )
            
            return @{
                Time = 2
                Unit = "h"
                Type = "default"
                Formatted = "2 h"
            }
        }
        
        # Appeler la fonction
        Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution" -AddTimeEstimation
        
        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Analyser les besoins \[â±ï¸ 2 h\]"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* Concevoir la solution \[â±ï¸ 2 h\]"
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches sans estimations de temps si AddTimeEstimation n'est pas spÃ©cifiÃ©" {
        # Appeler la fonction sans AddTimeEstimation
        Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution"
        
        # VÃ©rifier le rÃ©sultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Analyser les besoins"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* Concevoir la solution"
        $content -join "`n" | Should -Not -Match "\[â±ï¸"
    }

    It "Devrait utiliser le niveau de complexitÃ© spÃ©cifiÃ© pour les estimations de temps" {
        # CrÃ©er un mock pour la fonction Get-TaskTimeEstimate qui vÃ©rifie le niveau de complexitÃ©
        $complexityUsed = $null
        function Get-TaskTimeEstimate {
            param (
                [string]$TaskContent,
                [string]$ComplexityLevel,
                [string]$Domain,
                [string]$ProjectRoot
            )
            
            $script:complexityUsed = $ComplexityLevel
            
            return @{
                Time = 2
                Unit = "h"
                Type = "default"
                Formatted = "2 h"
            }
        }
        
        # Appeler la fonction avec un niveau de complexitÃ© spÃ©cifique
        Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins" -AddTimeEstimation -ComplexityLevel "Complex"
        
        # VÃ©rifier que le niveau de complexitÃ© a Ã©tÃ© utilisÃ©
        $complexityUsed | Should -Be "Complex"
    }

    It "Devrait utiliser le domaine spÃ©cifiÃ© pour les estimations de temps" {
        # CrÃ©er un mock pour la fonction Get-TaskTimeEstimate qui vÃ©rifie le domaine
        $domainUsed = $null
        function Get-TaskTimeEstimate {
            param (
                [string]$TaskContent,
                [string]$ComplexityLevel,
                [string]$Domain,
                [string]$ProjectRoot
            )
            
            $script:domainUsed = $Domain
            
            return @{
                Time = 2
                Unit = "h"
                Type = "default"
                Formatted = "2 h"
            }
        }
        
        # Appeler la fonction avec un domaine spÃ©cifique
        Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins" -AddTimeEstimation -Domain "Backend"
        
        # VÃ©rifier que le domaine a Ã©tÃ© utilisÃ©
        $domainUsed | Should -Be "Backend"
    }
}

# ExÃ©cuter les tests si le script est exÃ©cutÃ© directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Script $MyInvocation.MyCommand.Path
}
