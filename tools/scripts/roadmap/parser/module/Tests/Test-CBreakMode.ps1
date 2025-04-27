<#
.SYNOPSIS
    Tests pour le script c-break-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script c-break-mode.ps1
    qui implÃ©mente le mode C-BREAK (Cycle Breaker) pour dÃ©tecter et rÃ©soudre les dÃ©pendances
    circulaires dans le code.

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

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$cBreakModePath = Join-Path -Path $projectRoot -ChildPath "c-break-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeCBreakPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapCycleBreaker.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $cBreakModePath)) {
    Write-Warning "Le script c-break-mode.ps1 est introuvable Ã  l'emplacement : $cBreakModePath"
}

if (-not (Test-Path -Path $invokeCBreakPath)) {
    Write-Warning "Le fichier Invoke-RoadmapCycleBreaker.ps1 est introuvable Ã  l'emplacement : $invokeCBreakPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeCBreakPath) {
    . $invokeCBreakPath
    Write-Host "Fonction Invoke-RoadmapCycleBreaker importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** DÃ©tection de cycles
  - [ ] **1.1.1** DÃ©velopper les mÃ©canismes de dÃ©tection de dÃ©pendances circulaires
  - [ ] **1.1.2** ImplÃ©menter la validation des workflows
- [ ] **1.2** RÃ©solution de cycles
  - [ ] **1.2.1** DÃ©velopper les mÃ©canismes de correction automatique
  - [ ] **1.2.2** ImplÃ©menter les suggestions de refactorisation

## Section 2

- [ ] **2.1** Tests de dÃ©tection de cycles
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "ModuleA") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "ModuleB") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "ModuleC") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers avec des dÃ©pendances circulaires pour les tests
@"
# ModuleA.ps1
. "`$PSScriptRoot\..\ModuleB\ModuleB.ps1"

function Get-ModuleAData {
    param (
        [string]`$Input
    )
    
    `$processedData = Get-ModuleBData -Input `$Input
    return "ModuleA: `$processedData"
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "ModuleA\ModuleA.ps1") -Encoding UTF8

@"
# ModuleB.ps1
. "`$PSScriptRoot\..\ModuleC\ModuleC.ps1"

function Get-ModuleBData {
    param (
        [string]`$Input
    )
    
    `$processedData = Get-ModuleCData -Input `$Input
    return "ModuleB: `$processedData"
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "ModuleB\ModuleB.ps1") -Encoding UTF8

@"
# ModuleC.ps1
. "`$PSScriptRoot\..\ModuleA\ModuleA.ps1"

function Get-ModuleCData {
    param (
        [string]`$Input
    )
    
    `$processedData = Get-ModuleAData -Input `$Input
    return "ModuleC: `$processedData"
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "ModuleC\ModuleC.ps1") -Encoding UTF8

Write-Host "Module de test avec dÃ©pendances circulaires crÃ©Ã© : $testModulePath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapCycleBreaker" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -ModulePath $testModulePath -OutputPath $testOutputPath -AutoFix $false
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le module n'existe pas" {
        # Appeler la fonction avec un module inexistant
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapCycleBreaker -ModulePath "ModuleInexistant" -OutputPath $testOutputPath -AutoFix $false } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait dÃ©tecter les dÃ©pendances circulaires" {
        # Appeler la fonction et vÃ©rifier la dÃ©tection des dÃ©pendances circulaires
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -ModulePath $testModulePath -OutputPath $testOutputPath -AutoFix $false
            
            # VÃ©rifier que les cycles sont dÃ©tectÃ©s
            $result.Cycles | Should -Not -BeNullOrEmpty
            $result.Cycles.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que le cycle A -> B -> C -> A est dÃ©tectÃ©
            $result.Cycles | Should -Contain "ModuleA -> ModuleB -> ModuleC -> ModuleA"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer des suggestions de refactorisation" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration de suggestions
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -ModulePath $testModulePath -OutputPath $testOutputPath -AutoFix $false
            
            # VÃ©rifier que des suggestions sont gÃ©nÃ©rÃ©es
            $result.Suggestions | Should -Not -BeNullOrEmpty
            $result.Suggestions.Count | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un graphe de dÃ©pendances" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration du graphe
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -ModulePath $testModulePath -OutputPath $testOutputPath -AutoFix $false -GenerateGraph $true
            
            # VÃ©rifier que le graphe est gÃ©nÃ©rÃ©
            $graphPath = Join-Path -Path $testOutputPath -ChildPath "dependency_graph.html"
            Test-Path -Path $graphPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait appliquer des corrections automatiques" {
        # Appeler la fonction et vÃ©rifier l'application des corrections
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            # CrÃ©er une copie du module pour le test
            $testModuleCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestModuleCopy_$(Get-Random)"
            Copy-Item -Path $testModulePath -Destination $testModuleCopyPath -Recurse
            
            $result = Invoke-RoadmapCycleBreaker -ModulePath $testModuleCopyPath -OutputPath $testOutputPath -AutoFix $true -BackupPath (Join-Path -Path $testOutputPath -ChildPath "backup")
            
            # VÃ©rifier que des corrections sont appliquÃ©es
            $result.FixedCycles | Should -Not -BeNullOrEmpty
            $result.FixedCycles.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les fichiers sont modifiÃ©s
            $moduleAPath = Join-Path -Path $testModuleCopyPath -ChildPath "ModuleA\ModuleA.ps1"
            $moduleBPath = Join-Path -Path $testModuleCopyPath -ChildPath "ModuleB\ModuleB.ps1"
            $moduleCPath = Join-Path -Path $testModuleCopyPath -ChildPath "ModuleC\ModuleC.ps1"
            
            $moduleAContent = Get-Content -Path $moduleAPath -Raw
            $moduleBContent = Get-Content -Path $moduleBPath -Raw
            $moduleCContent = Get-Content -Path $moduleCPath -Raw
            
            # Au moins un des fichiers devrait Ãªtre modifiÃ©
            ($moduleAContent -notmatch "ModuleB\.ps1" -or $moduleBContent -notmatch "ModuleC\.ps1" -or $moduleCContent -notmatch "ModuleA\.ps1") | Should -Be $true
            
            # Supprimer la copie du module
            Remove-Item -Path $testModuleCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script c-break-mode.ps1
Describe "c-break-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $cBreakModePath) {
            # ExÃ©cuter le script
            $output = & $cBreakModePath -ModulePath $testModulePath -OutputPath $testOutputPath -AutoFix $false -GenerateGraph $true
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
            $graphPath = Join-Path -Path $testOutputPath -ChildPath "dependency_graph.html"
            Test-Path -Path $graphPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script c-break-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testModulePath) {
    Remove-Item -Path $testModulePath -Recurse -Force
    Write-Host "Module de test supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "RÃ©pertoire de sortie supprimÃ©." -ForegroundColor Gray
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}
