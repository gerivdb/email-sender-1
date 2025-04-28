<#
.SYNOPSIS
    Tests unitaires pour les paramÃ¨tres du script c-break-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les paramÃ¨tres du script c-break-mode.ps1.
    Il utilise le framework Pester pour exÃ©cuter les tests.

.EXAMPLE
    Invoke-Pester -Path ".\Test-CBreakModeParameters.ps1"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin vers le script Ã  tester
$scriptPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "c-break-mode.ps1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "CBreakModeTests"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "CBreakModeTestsOutput"
$testRoadmapPath = Join-Path -Path $testProjectPath -ChildPath "test-roadmap.md"

# Variables pour les chemins de test

# ExÃ©cuter les tests
Describe "Tests des paramÃ¨tres du script c-break-mode.ps1" {
    BeforeAll {
        # CrÃ©er les rÃ©pertoires de test
        if (-not (Test-Path -Path $testProjectPath)) {
            New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null
        }

        if (-not (Test-Path -Path $testOutputPath)) {
            New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
        }

        # CrÃ©er un fichier roadmap de test
        @"
# Test Roadmap

## 1. Test Task
- [ ] **1.1** Test Subtask 1
- [ ] **1.2** Test Subtask 2
"@ | Out-File -FilePath $testRoadmapPath -Encoding UTF8

        # CrÃ©er quelques fichiers de test dans le rÃ©pertoire du projet
        $testFiles = @(
            "file1.ps1",
            "file2.ps1",
            "file3.py",
            "file4.js",
            "test/test1.ps1",
            "test/test2.py"
        )

        foreach ($file in $testFiles) {
            $filePath = Join-Path -Path $testProjectPath -ChildPath $file
            $fileDir = Split-Path -Parent $filePath

            if (-not (Test-Path -Path $fileDir)) {
                New-Item -Path $fileDir -ItemType Directory -Force | Out-Null
            }

            "# Test file: $file" | Out-File -FilePath $filePath -Encoding UTF8
        }
    }

    AfterAll {
        # Nettoyer l'environnement de test
        if (Test-Path -Path $testProjectPath) {
            Remove-Item -Path $testProjectPath -Recurse -Force
        }

        if (Test-Path -Path $testOutputPath) {
            Remove-Item -Path $testOutputPath -Recurse -Force
        }
    }

    Context "Validation des paramÃ¨tres obligatoires" {
        It "Devrait Ã©chouer si FilePath n'est pas spÃ©cifiÃ©" {
            $scriptBlock = {
                & $scriptPath -ProjectPath $testProjectPath -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait Ã©chouer si ProjectPath n'est pas spÃ©cifiÃ©" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait Ã©chouer si FilePath n'existe pas" {
            $scriptBlock = {
                & $scriptPath -FilePath "chemin/inexistant.md" -ProjectPath $testProjectPath -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait Ã©chouer si ProjectPath n'existe pas" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath "chemin/inexistant" -WhatIf
            }
            $scriptBlock | Should -Throw
        }
    }

    Context "Validation des paramÃ¨tres optionnels" {
        It "Devrait accepter les paramÃ¨tres par dÃ©faut" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait accepter un OutputPath personnalisÃ©" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait accepter des IncludePatterns personnalisÃ©s" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -IncludePatterns "*.ps1" -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait accepter des ExcludePatterns personnalisÃ©s" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -ExcludePatterns "*test*" -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait accepter un StartPath valide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -StartPath "test" -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait Ã©chouer avec un StartPath invalide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -StartPath "dossier/inexistant" -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait accepter un DetectionAlgorithm valide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -DetectionAlgorithm "DFS" -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait Ã©chouer avec un DetectionAlgorithm invalide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -DetectionAlgorithm "INVALID" -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait accepter un MaxDepth valide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -MaxDepth 20 -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait Ã©chouer avec un MaxDepth invalide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -MaxDepth 0 -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait accepter un MinimumCycleSeverity valide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -MinimumCycleSeverity 3 -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait Ã©chouer avec un MinimumCycleSeverity invalide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -MinimumCycleSeverity 6 -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait accepter AutoFix Ã  true" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -AutoFix $true -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait accepter un FixStrategy valide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -AutoFix $true -FixStrategy "INTERFACE_EXTRACTION" -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait Ã©chouer avec un FixStrategy invalide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -AutoFix $true -FixStrategy "INVALID" -WhatIf
            }
            $scriptBlock | Should -Throw
        }

        It "Devrait accepter GenerateGraph Ã  true" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -GenerateGraph $true -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait accepter un GraphFormat valide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -GenerateGraph $true -GraphFormat "MERMAID" -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }

        It "Devrait Ã©chouer avec un GraphFormat invalide" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -GenerateGraph $true -GraphFormat "INVALID" -WhatIf
            }
            $scriptBlock | Should -Throw
        }
    }

    Context "Combinaisons de paramÃ¨tres" {
        It "Devrait accepter une combinaison complÃ¨te de paramÃ¨tres valides" {
            $scriptBlock = {
                & $scriptPath -FilePath $testRoadmapPath `
                    -ProjectPath $testProjectPath `
                    -OutputPath $testOutputPath `
                    -IncludePatterns "*.ps1", "*.py" `
                    -ExcludePatterns "*test*" `
                    -StartPath "test" `
                    -DetectionAlgorithm "TARJAN" `
                    -MaxDepth 15 `
                    -MinimumCycleSeverity 2 `
                    -AutoFix $true `
                    -FixStrategy "DEPENDENCY_INVERSION" `
                    -GenerateGraph $true `
                    -GraphFormat "DOT" `
                    -WhatIf
            }
            $scriptBlock | Should -Not -Throw
        }
    }
}
