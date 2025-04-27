<#
.SYNOPSIS
    Tests pour le script review-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script review-mode.ps1
    qui implÃ©mente le mode REVIEW pour vÃ©rifier la lisibilitÃ©, les standards et la documentation du code.

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
$reviewModePath = Join-Path -Path $projectRoot -ChildPath "review-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeReviewPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapReview.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $reviewModePath)) {
    Write-Warning "Le script review-mode.ps1 est introuvable Ã  l'emplacement : $reviewModePath"
}

if (-not (Test-Path -Path $invokeReviewPath)) {
    Write-Warning "Le fichier Invoke-RoadmapReview.ps1 est introuvable Ã  l'emplacement : $invokeReviewPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeReviewPath) {
    . $invokeReviewPath
    Write-Host "Fonction Invoke-RoadmapReview importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Revue de code
  - [ ] **1.1.1** VÃ©rifier la conformitÃ© aux standards
  - [ ] **1.1.2** Ã‰valuer la qualitÃ© de la documentation
- [ ] **1.2** AmÃ©lioration de la qualitÃ©
  - [ ] **1.2.1** RÃ©duire la complexitÃ©
  - [ ] **1.2.2** AmÃ©liorer la lisibilitÃ©

## Section 2

- [ ] **2.1** Tests de qualitÃ©
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de code avec des problÃ¨mes de qualitÃ© pour les tests
@"
function Process-Data {
    # ProblÃ¨me : Pas de documentation
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Data
    )
    
    # ProblÃ¨me : ComplexitÃ© cyclomatique Ã©levÃ©e
    if (`$Data -is [string]) {
        if (`$Data.Length -gt 10) {
            if (`$Data.StartsWith("A")) {
                return "A" + `$Data.Substring(1)
            } elseif (`$Data.StartsWith("B")) {
                return "B" + `$Data.Substring(1)
            } else {
                if (`$Data.EndsWith("X")) {
                    return `$Data.Substring(0, `$Data.Length - 1) + "X"
                } elseif (`$Data.EndsWith("Y")) {
                    return `$Data.Substring(0, `$Data.Length - 1) + "Y"
                } else {
                    return `$Data
                }
            }
        } else {
            return `$Data
        }
    } elseif (`$Data -is [int]) {
        if (`$Data -gt 100) {
            return `$Data - 100
        } elseif (`$Data -lt 0) {
            return 0
        } else {
            return `$Data
        }
    } else {
        return `$Data
    }
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public\Process-Data.ps1") -Encoding UTF8

@"
function Helper-Function {
    # ProblÃ¨me : Nom de fonction non conforme aux standards PowerShell
    # ProblÃ¨me : Documentation insuffisante
    param (
        [string]`$input # ProblÃ¨me : Nom de paramÃ¨tre rÃ©servÃ©
    )
    
    # ProblÃ¨me : Duplication de code (similaire Ã  Process-Data)
    if (`$input -is [string]) {
        if (`$input.Length -gt 10) {
            if (`$input.StartsWith("A")) {
                return "A" + `$input.Substring(1)
            } elseif (`$input.StartsWith("B")) {
                return "B" + `$input.Substring(1)
            } else {
                return `$input
            }
        } else {
            return `$input
        }
    } else {
        return `$input
    }
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private\Helper-Function.ps1") -Encoding UTF8

Write-Host "Module de test crÃ©Ã© : $testModulePath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# CrÃ©er un fichier de standards de codage
$standardsFilePath = Join-Path -Path $testOutputPath -ChildPath "coding-standards.json"
@"
{
    "NamingConventions": {
        "Functions": {
            "Verb-Noun": true,
            "ApprovedVerbs": true
        },
        "Parameters": {
            "PascalCase": true,
            "AvoidReservedNames": true
        }
    },
    "Documentation": {
        "RequiredSections": ["Synopsis", "Description", "Parameters", "Example"],
        "MinimumDocRatio": 0.2
    },
    "CodeQuality": {
        "MaxComplexity": 10,
        "MaxFunctionLength": 100,
        "MaxParameterCount": 5
    }
}
"@ | Set-Content -Path $standardsFilePath -Encoding UTF8

Write-Host "Fichier de standards de codage crÃ©Ã© : $standardsFilePath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapReview" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckStandards $true
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le module n'existe pas" {
        # Appeler la fonction avec un module inexistant
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapReview -ModulePath "ModuleInexistant" -OutputPath $testOutputPath -CheckStandards $true } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait vÃ©rifier la conformitÃ© aux standards de codage" {
        # Appeler la fonction et vÃ©rifier la vÃ©rification des standards
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckStandards $true -StandardsFile $standardsFilePath
            
            # VÃ©rifier que les problÃ¨mes de standards sont identifiÃ©s
            $result.StandardsViolations | Should -Not -BeNullOrEmpty
            $result.StandardsViolations.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les problÃ¨mes spÃ©cifiques sont identifiÃ©s
            $result.StandardsViolations | Should -Contain "Helper-Function"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait vÃ©rifier la qualitÃ© de la documentation" {
        # Appeler la fonction et vÃ©rifier la vÃ©rification de la documentation
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckDocumentation $true -MinDocRatio 0.2
            
            # VÃ©rifier que les problÃ¨mes de documentation sont identifiÃ©s
            $result.DocumentationIssues | Should -Not -BeNullOrEmpty
            $result.DocumentationIssues.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que le ratio de documentation est calculÃ©
            $result.DocRatio | Should -BeLessThan 0.2
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait vÃ©rifier la complexitÃ© cyclomatique" {
        # Appeler la fonction et vÃ©rifier la vÃ©rification de la complexitÃ©
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckComplexity $true -MaxComplexity 10
            
            # VÃ©rifier que les problÃ¨mes de complexitÃ© sont identifiÃ©s
            $result.ComplexityIssues | Should -Not -BeNullOrEmpty
            $result.ComplexityIssues.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les fonctions complexes sont identifiÃ©es
            $result.ComplexityIssues | Should -Contain "Process-Data"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un rapport de revue" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration du rapport
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckStandards $true -CheckDocumentation $true -CheckComplexity $true
            
            # VÃ©rifier que le rapport est gÃ©nÃ©rÃ©
            $reviewReportPath = Join-Path -Path $testOutputPath -ChildPath "review_report.html"
            Test-Path -Path $reviewReportPath | Should -Be $true
            
            # VÃ©rifier que le contenu du rapport contient les informations attendues
            $reportContent = Get-Content -Path $reviewReportPath -Raw
            $reportContent | Should -Match "Standards de codage"
            $reportContent | Should -Match "Documentation"
            $reportContent | Should -Match "ComplexitÃ© cyclomatique"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script review-mode.ps1
Describe "review-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $reviewModePath) {
            # ExÃ©cuter le script
            $output = & $reviewModePath -ModulePath $testModulePath -OutputPath $testOutputPath -CheckStandards $true -CheckDocumentation $true -CheckComplexity $true
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
            $reviewReportPath = Join-Path -Path $testOutputPath -ChildPath "review_report.html"
            Test-Path -Path $reviewReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script review-mode.ps1 n'est pas disponible"
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
