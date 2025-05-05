<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-TaskTimeEstimate.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-TaskTimeEstimate
    qui permet d'estimer le temps nÃ©cessaire pour une sous-tÃ¢che.

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

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$granModePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "modes\gran-mode.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le fichier gran-mode.ps1 est introuvable Ã  l'emplacement : $granModePath"
}

# Extraire la fonction Get-TaskTimeEstimate du script
$content = Get-Content -Path $granModePath -Raw
$functionMatch = [regex]::Match($content, '(?s)function Get-TaskTimeEstimate\s*\{.*?\n\}')
if (-not $functionMatch.Success) {
    throw "La fonction Get-TaskTimeEstimate n'a pas Ã©tÃ© trouvÃ©e dans le fichier gran-mode.ps1"
}

# Ã‰valuer la fonction pour la rendre disponible dans ce script
$functionCode = $functionMatch.Value
Invoke-Expression $functionCode

# CrÃ©er un fichier temporaire pour les tests
$testConfigPath = Join-Path -Path $env:TEMP -ChildPath "time-estimates_$(Get-Random).json"

# VÃ©rifier que le rÃ©pertoire temporaire existe
if (-not (Test-Path -Path $env:TEMP)) {
    throw "Le rÃ©pertoire temporaire $env:TEMP n'existe pas."
}

# Afficher le chemin du fichier temporaire pour le dÃ©bogage
Write-Host "Fichier de configuration temporaire : $testConfigPath"

Describe "Get-TaskTimeEstimate" {
    BeforeEach {
        # CrÃ©er un fichier de configuration de test
        @"
{
  "complexity_multipliers": {
    "simple": 0.5,
    "medium": 1.0,
    "complex": 2.0
  },
  "domain_multipliers": {
    "frontend": 1.0,
    "backend": 1.2,
    "database": 1.1,
    "testing": 0.9,
    "devops": 1.3,
    "security": 1.4,
    "ai-ml": 1.5,
    "documentation": 0.8
  },
  "base_times": {
    "analysis": {
      "unit": "h",
      "value": 2
    },
    "design": {
      "unit": "h",
      "value": 3
    },
    "implementation": {
      "unit": "h",
      "value": 4
    },
    "testing": {
      "unit": "h",
      "value": 2
    },
    "documentation": {
      "unit": "h",
      "value": 1
    },
    "default": {
      "unit": "h",
      "value": 2
    }
  },
  "task_keywords": {
    "analysis": ["analyser", "analyse", "Ã©tudier", "Ã©valuer", "comprendre", "identifier", "rechercher"],
    "design": ["concevoir", "conception", "architecture", "modÃ©liser", "planifier", "structurer"],
    "implementation": ["implÃ©menter", "dÃ©velopper", "coder", "programmer", "crÃ©er", "mettre en place", "intÃ©grer"],
    "testing": ["tester", "vÃ©rifier", "valider", "contrÃ´ler", "qualitÃ©", "test"],
    "documentation": ["documenter", "documentation", "guide", "manuel", "rÃ©fÃ©rence"]
  }
}
"@ | Set-Content -Path $testConfigPath -Encoding UTF8

        # CrÃ©er un mock pour la fonction Join-Path
        Mock Join-Path {
            param($Path, $ChildPath)
            if ($ChildPath -eq "development\templates\subtasks\time-estimates.json") {
                return $testConfigPath
            } else {
                # Utiliser la fonction originale pour les autres cas
                $originalJoinPath = Get-Command Join-Path -CommandType Cmdlet
                & $originalJoinPath -Path $Path -ChildPath $ChildPath
            }
        }
    }

    AfterEach {
        # Supprimer le fichier temporaire
        if ($testConfigPath -and (Test-Path -Path $testConfigPath)) {
            Remove-Item -Path $testConfigPath -Force
        }
    }

    It "Devrait retourner null si le fichier de configuration n'existe pas" {
        # Supprimer le fichier de configuration
        if ($testConfigPath -and (Test-Path -Path $testConfigPath)) {
            Remove-Item -Path $testConfigPath -Force
        }

        # Appeler la fonction
        $result = Get-TaskTimeEstimate -TaskContent "Analyser les besoins" -ComplexityLevel "Medium" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $null
    }

    It "Devrait dÃ©tecter correctement le type de tÃ¢che d'analyse" {
        # Appeler la fonction avec une tÃ¢che d'analyse
        $result = Get-TaskTimeEstimate -TaskContent "Analyser les besoins du systÃ¨me" -ComplexityLevel "Medium" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "analysis"
        $result.Time | Should -Be 2.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "2 h"
    }

    It "Devrait dÃ©tecter correctement le type de tÃ¢che de conception" {
        # Appeler la fonction avec une tÃ¢che de conception
        $result = Get-TaskTimeEstimate -TaskContent "Concevoir l'architecture du systÃ¨me" -ComplexityLevel "Medium" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "design"
        $result.Time | Should -Be 3.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "3 h"
    }

    It "Devrait dÃ©tecter correctement le type de tÃ¢che d'implÃ©mentation" {
        # Appeler la fonction avec une tÃ¢che d'implÃ©mentation
        $result = Get-TaskTimeEstimate -TaskContent "ImplÃ©menter le module de connexion" -ComplexityLevel "Medium" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "implementation"
        $result.Time | Should -Be 4.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "4 h"
    }

    It "Devrait dÃ©tecter correctement le type de tÃ¢che de test" {
        # Appeler la fonction avec une tÃ¢che de test
        $result = Get-TaskTimeEstimate -TaskContent "Tester le module de connexion" -ComplexityLevel "Medium" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "testing"
        $result.Time | Should -Be 2.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "2 h"
    }

    It "Devrait dÃ©tecter correctement le type de tÃ¢che de documentation" {
        # Appeler la fonction avec une tÃ¢che de documentation
        $result = Get-TaskTimeEstimate -TaskContent "Documenter l'API du systÃ¨me" -ComplexityLevel "Medium" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "documentation"
        $result.Time | Should -Be 1.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "1 h"
    }

    It "Devrait utiliser le type par dÃ©faut si aucun type n'est dÃ©tectÃ©" {
        # Appeler la fonction avec une tÃ¢che sans type spÃ©cifique
        $result = Get-TaskTimeEstimate -TaskContent "Faire quelque chose" -ComplexityLevel "Medium" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "default"
        $result.Time | Should -Be 2.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "2 h"
    }

    It "Devrait appliquer le multiplicateur de complexitÃ© simple" {
        # Appeler la fonction avec une complexitÃ© simple
        $result = Get-TaskTimeEstimate -TaskContent "ImplÃ©menter le module de connexion" -ComplexityLevel "Simple" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "implementation"
        $result.Time | Should -Be 2.0  # 4.0 * 0.5
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "2 h"
    }

    It "Devrait appliquer le multiplicateur de complexitÃ© complexe" {
        # Appeler la fonction avec une complexitÃ© complexe
        $result = Get-TaskTimeEstimate -TaskContent "ImplÃ©menter le module de connexion" -ComplexityLevel "Complex" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "implementation"
        $result.Time | Should -Be 8.0  # 4.0 * 2.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "8 h"
    }

    It "Devrait appliquer le multiplicateur de domaine backend" {
        # Appeler la fonction avec un domaine backend
        $result = Get-TaskTimeEstimate -TaskContent "ImplÃ©menter le module de connexion" -ComplexityLevel "Medium" -Domain "backend" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "implementation"
        $result.Time | Should -Be 4.8  # 4.0 * 1.2
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "4.5 h"  # Arrondi Ã  0.5 prÃ¨s
    }

    It "Devrait appliquer le multiplicateur de domaine documentation" {
        # Appeler la fonction avec un domaine documentation
        $result = Get-TaskTimeEstimate -TaskContent "ImplÃ©menter le module de connexion" -ComplexityLevel "Medium" -Domain "documentation" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "implementation"
        $result.Time | Should -Be 3.0  # 4.0 * 0.8 = 3.2, arrondi Ã  0.5 prÃ¨s = 3.0
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "3 h"
    }

    It "Devrait ignorer le domaine s'il n'est pas reconnu" {
        # Appeler la fonction avec un domaine non reconnu
        $result = Get-TaskTimeEstimate -TaskContent "ImplÃ©menter le module de connexion" -ComplexityLevel "Medium" -Domain "inconnu" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "implementation"
        $result.Time | Should -Be 4.0  # Pas de multiplicateur de domaine
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "4 h"
    }

    It "Devrait combiner les multiplicateurs de complexitÃ© et de domaine" {
        # Appeler la fonction avec une complexitÃ© complexe et un domaine backend
        $result = Get-TaskTimeEstimate -TaskContent "ImplÃ©menter le module de connexion" -ComplexityLevel "Complex" -Domain "backend" -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result.Type | Should -Be "implementation"
        $result.Time | Should -Be 9.5  # 4.0 * 2.0 * 1.2 = 9.6, arrondi Ã  0.5 prÃ¨s = 9.5
        $result.Unit | Should -Be "h"
        $result.Formatted | Should -Be "9.5 h"
    }
}

# ExÃ©cuter les tests si le script est exÃ©cutÃ© directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Script $MyInvocation.MyCommand.Path
}
