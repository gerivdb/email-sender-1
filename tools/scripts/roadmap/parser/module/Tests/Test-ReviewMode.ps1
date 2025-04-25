<#
.SYNOPSIS
    Tests pour le script review-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script review-mode.ps1
    qui implémente le mode REVIEW pour vérifier la lisibilité, les standards et la documentation du code.

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

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$reviewModePath = Join-Path -Path $projectRoot -ChildPath "review-mode.ps1"

# Chemin vers les fonctions à tester
$invokeReviewPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapReview.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $reviewModePath)) {
    Write-Warning "Le script review-mode.ps1 est introuvable à l'emplacement : $reviewModePath"
}

if (-not (Test-Path -Path $invokeReviewPath)) {
    Write-Warning "Le fichier Invoke-RoadmapReview.ps1 est introuvable à l'emplacement : $invokeReviewPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeReviewPath) {
    . $invokeReviewPath
    Write-Host "Fonction Invoke-RoadmapReview importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Revue de code
  - [ ] **1.1.1** Vérifier la conformité aux standards
  - [ ] **1.1.2** Évaluer la qualité de la documentation
- [ ] **1.2** Amélioration de la qualité
  - [ ] **1.2.1** Réduire la complexité
  - [ ] **1.2.2** Améliorer la lisibilité

## Section 2

- [ ] **2.1** Tests de qualité
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# Créer la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer des fichiers de code avec des problèmes de qualité pour les tests
@"
function Process-Data {
    # Problème : Pas de documentation
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Data
    )
    
    # Problème : Complexité cyclomatique élevée
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
    # Problème : Nom de fonction non conforme aux standards PowerShell
    # Problème : Documentation insuffisante
    param (
        [string]`$input # Problème : Nom de paramètre réservé
    )
    
    # Problème : Duplication de code (similaire à Process-Data)
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

Write-Host "Module de test créé : $testModulePath" -ForegroundColor Green
Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Créer un fichier de standards de codage
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

Write-Host "Fichier de standards de codage créé : $standardsFilePath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapReview" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
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

    It "Devrait vérifier la conformité aux standards de codage" {
        # Appeler la fonction et vérifier la vérification des standards
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckStandards $true -StandardsFile $standardsFilePath
            
            # Vérifier que les problèmes de standards sont identifiés
            $result.StandardsViolations | Should -Not -BeNullOrEmpty
            $result.StandardsViolations.Count | Should -BeGreaterThan 0
            
            # Vérifier que les problèmes spécifiques sont identifiés
            $result.StandardsViolations | Should -Contain "Helper-Function"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait vérifier la qualité de la documentation" {
        # Appeler la fonction et vérifier la vérification de la documentation
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckDocumentation $true -MinDocRatio 0.2
            
            # Vérifier que les problèmes de documentation sont identifiés
            $result.DocumentationIssues | Should -Not -BeNullOrEmpty
            $result.DocumentationIssues.Count | Should -BeGreaterThan 0
            
            # Vérifier que le ratio de documentation est calculé
            $result.DocRatio | Should -BeLessThan 0.2
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait vérifier la complexité cyclomatique" {
        # Appeler la fonction et vérifier la vérification de la complexité
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckComplexity $true -MaxComplexity 10
            
            # Vérifier que les problèmes de complexité sont identifiés
            $result.ComplexityIssues | Should -Not -BeNullOrEmpty
            $result.ComplexityIssues.Count | Should -BeGreaterThan 0
            
            # Vérifier que les fonctions complexes sont identifiées
            $result.ComplexityIssues | Should -Contain "Process-Data"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }

    It "Devrait générer un rapport de revue" {
        # Appeler la fonction et vérifier la génération du rapport
        if (Get-Command -Name Invoke-RoadmapReview -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapReview -ModulePath $testModulePath -OutputPath $testOutputPath -CheckStandards $true -CheckDocumentation $true -CheckComplexity $true
            
            # Vérifier que le rapport est généré
            $reviewReportPath = Join-Path -Path $testOutputPath -ChildPath "review_report.html"
            Test-Path -Path $reviewReportPath | Should -Be $true
            
            # Vérifier que le contenu du rapport contient les informations attendues
            $reportContent = Get-Content -Path $reviewReportPath -Raw
            $reportContent | Should -Match "Standards de codage"
            $reportContent | Should -Match "Documentation"
            $reportContent | Should -Match "Complexité cyclomatique"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapReview n'est pas disponible"
        }
    }
}

# Test d'intégration du script review-mode.ps1
Describe "review-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $reviewModePath) {
            # Exécuter le script
            $output = & $reviewModePath -ModulePath $testModulePath -OutputPath $testOutputPath -CheckStandards $true -CheckDocumentation $true -CheckComplexity $true
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
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
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testModulePath) {
    Remove-Item -Path $testModulePath -Recurse -Force
    Write-Host "Module de test supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
