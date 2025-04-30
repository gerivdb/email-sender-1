<#
.SYNOPSIS
    Tests unitaires pour la fonction Invoke-RoadmapGranularizationWithTimeEstimation.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Invoke-RoadmapGranularizationWithTimeEstimation
    qui permet d'invoquer interactivement la granularisation des tâches de roadmap avec estimations de temps.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
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
$invokeGranPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapGranularizationWithTimeEstimation.ps1"
$splitTaskPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Split-RoadmapTask.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $invokeGranPath)) {
    throw "Le fichier Invoke-RoadmapGranularizationWithTimeEstimation.ps1 est introuvable à l'emplacement : $invokeGranPath"
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

Describe "Invoke-RoadmapGranularizationWithTimeEstimation" {
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

        # Créer un fichier de sous-tâches de test
        @"
Analyser les besoins
Concevoir la solution
Implémenter le code
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
        { Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "FichierInexistant.md" -TaskIdentifier "1.3" -SubTasksInput "Sous-tâche" } | Should -Throw
    }

    It "Devrait lever une exception si aucune sous-tâche n'est spécifiée" {
        # Appeler la fonction sans sous-tâches
        { Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "" } | Should -Throw
    }

    It "Devrait décomposer une tâche en sous-tâches avec estimations de temps" {
        # Créer un mock pour la fonction Get-TaskTimeEstimate
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
        
        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Analyser les besoins \[⏱️ 2 h\]"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* Concevoir la solution \[⏱️ 2 h\]"
    }

    It "Devrait décomposer une tâche en sous-tâches sans estimations de temps si AddTimeEstimation n'est pas spécifié" {
        # Appeler la fonction sans AddTimeEstimation
        Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution"
        
        # Vérifier le résultat
        $content = Get-Content -Path $testFilePath -Encoding UTF8
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.1\*\* Analyser les besoins"
        $content -join "`n" | Should -Match "- \[ \] \*\*1\.3\.2\*\* Concevoir la solution"
        $content -join "`n" | Should -Not -Match "\[⏱️"
    }

    It "Devrait utiliser le niveau de complexité spécifié pour les estimations de temps" {
        # Créer un mock pour la fonction Get-TaskTimeEstimate qui vérifie le niveau de complexité
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
        
        # Appeler la fonction avec un niveau de complexité spécifique
        Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins" -AddTimeEstimation -ComplexityLevel "Complex"
        
        # Vérifier que le niveau de complexité a été utilisé
        $complexityUsed | Should -Be "Complex"
    }

    It "Devrait utiliser le domaine spécifié pour les estimations de temps" {
        # Créer un mock pour la fonction Get-TaskTimeEstimate qui vérifie le domaine
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
        
        # Appeler la fonction avec un domaine spécifique
        Invoke-RoadmapGranularizationWithTimeEstimation -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins" -AddTimeEstimation -Domain "Backend"
        
        # Vérifier que le domaine a été utilisé
        $domainUsed | Should -Be "Backend"
    }
}

# Exécuter les tests si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Script $MyInvocation.MyCommand.Path
}
